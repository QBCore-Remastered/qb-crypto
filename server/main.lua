-- Variables
local config = require 'config.server'
local sharedConfig = require 'config.shared'
local coin = sharedConfig.crypto.coin
local bannedCharacters = {'%', '$', ';'}

-- Functions

local function RefreshCrypto()
    local result = MySQL.query.await('SELECT * FROM crypto WHERE crypto = ?', {coin})
    if result and result[1] then
        sharedConfig.crypto.worth[coin] = result[1].worth
        if result[1].history then
            sharedConfig.crypto.history[coin] = json.decode(result[1].history)
            TriggerClientEvent('qb-crypto:client:UpdateCryptoWorth', -1, coin, result[1].worth, json.decode(result[1].history))
        else
            TriggerClientEvent('qb-crypto:client:UpdateCryptoWorth', -1, coin, result[1].worth, nil)
        end
    end
end

local function ErrorHandle(error)
    for k, v in pairs(config.ticker.errorHandle) do
        if string.match(error, k) then
            return v
        end
    end
    return false
end

local function GetTickerPrice() -- Touch = no help
    local ticker_promise = promise.new()
    PerformHttpRequest("https://min-api.cryptocompare.com/data/price?fsym=" .. config.ticker.coin .. "&tsyms=" .. config.ticker.currency .. '&api_key=' .. config.ticker.apiKey, function(error, result)
        local result_obj = json.decode(result)
        if not result_obj.Response then
            ticker_promise:resolve({
                error = error,
                response_data = result_obj[string.upper(config.ticker.currency)]
            }) --- Could resolve Error aswell for more accurate Error messages? Solved in else
        else
            ticker_promise:resolve({
                error = result_obj.Message
            })
        end
    end, 'GET')

    Citizen.Await(ticker_promise)

    if type(ticker_promise.value.error) ~= 'number' then
        local get_user_friendly_error = ErrorHandle(ticker_promise.value.error)
        if get_user_friendly_error then
            return get_user_friendly_error
        else
            return '\27[31m Unexpected error \27[0m' --- Raised an error which we did not expect, script should be capable of sticking with last recorded price and shutting down the sync logic
        end
    else
        return ticker_promise.value.response_data
    end
end

local function HandlePriceChance()
    local currentValue = sharedConfig.crypto.worth[coin]
    local prevValue = sharedConfig.crypto.worth[coin]
    local trend = math.random(0, 100)
    local event = math.random(0, 100)
    local chance = event - sharedConfig.crypto.chanceOfCrashOrLuck

    if event > chance then
        if trend <= sharedConfig.crypto.chanceOfDown then
            currentValue -= math.random(sharedConfig.crypto.casualDown[1], sharedConfig.crypto.casualDown[2])
        elseif trend >= sharedConfig.crypto.chanceOfUp then
            currentValue += math.random(sharedConfig.crypto.casualUp[1], sharedConfig.crypto.casualUp[2])
        end
    else
        if math.random(0, 1) == 1 then
            currentValue += math.random(sharedConfig.crypto.luck[1], sharedConfig.crypto.luck[2])
        else
            currentValue -= math.random(sharedConfig.crypto.crash[1], sharedConfig.crypto.crash[2])
        end
    end

    if currentValue <= sharedConfig.crypto.lower then
        currentValue = sharedConfig.crypto.lower
    elseif currentValue >= sharedConfig.crypto.upper then
        currentValue = sharedConfig.crypto.upper
    end

    if sharedConfig.crypto.history[coin][4] then
        -- Shift array index 1 to 3
        for k = 3, 1, -1 do
            sharedConfig.crypto.history[coin][k] = sharedConfig.crypto.history[coin][k + 1]
        end
        -- Assign array index 4 to the latest result
        sharedConfig.crypto.history[coin][4] = {
            PreviousWorth = prevValue,
            NewWorth = currentValue
        }
    else
        sharedConfig.crypto.history[coin][#sharedConfig.crypto.history[coin] + 1] = {
            PreviousWorth = prevValue,
            NewWorth = currentValue
        }
    end

    sharedConfig.crypto.worth[coin] = currentValue

    local history = json.encode(sharedConfig.crypto.history[coin])
    local props = {
        worth = currentValue,
        history = history,
        crypto = coin
    }
    MySQL.update('UPDATE crypto set worth = :worth, history = :history where crypto = :crypto', props, function(affectedRows)
        if affectedRows < 1 then
            print("Crypto not found, inserting new record for " .. coin)
            MySQL.insert('INSERT INTO crypto (crypto, worth, history) VALUES (:crypto, :worth, :history)', props)
        end
        RefreshCrypto()
    end)
end

-- Commands
lib.addCommand('setcryptoworth', {
    help = 'Set crypto worth',
    restricted = 'admin',
    params = {{
        name = 'crypto',
        help = 'Name of the crypto currency',
        type = 'string'
    }, {
        name = 'value',
        help = 'New value of the crypto currency',
        type = 'number'
    }}
}, function(source, args)
    local src = source
    local crypto = args.crypto
    if not crypto then
        exports.qbx_core:Notify(src, Lang:t('text.you_have_not_provided_crypto_available_qbit'))
        return
    end

    if not sharedConfig.crypto.worth[crypto] then
        exports.qbx_core:Notify(src, Lang:t('text.this_crypto_does_not_exist'))
        return
    end

    local NewWorth = math.ceil(tonumber(args.value) --[[@as number]])

    if not NewWorth then
        exports.qbx_core:Notify(src, Lang:t('text.you_have_not_given_a_new_value', {
            crypto = sharedConfig.crypto.worth[crypto]
        }))
        return
    end

    local PercentageChange = math.ceil(((NewWorth - sharedConfig.crypto.worth[crypto]) / sharedConfig.crypto.worth[crypto]) * 100)
    local ChangeLabel = "+"

    if PercentageChange < 0 then
        ChangeLabel = "-"
        PercentageChange = (PercentageChange * -1)
    end

    if sharedConfig.crypto.worth[crypto] == 0 then
        PercentageChange = 0
        ChangeLabel = ""
    end

    sharedConfig.crypto.history[crypto][#sharedConfig.crypto.history[crypto] + 1] = {
        PreviousWorth = sharedConfig.crypto.worth[crypto],
        NewWorth = NewWorth
    }

    exports.qbx_core:Notify(src, "You have changed the value of " .. sharedConfig.crypto.labels[crypto] .. " from: $" .. sharedConfig.crypto.worth[crypto] .. " to: $" .. NewWorth .. " (" .. ChangeLabel .. " " .. PercentageChange .. "%)")
    sharedConfig.crypto.worth[crypto] = NewWorth
    TriggerClientEvent('qb-crypto:client:UpdateCryptoWorth', -1, crypto, NewWorth)
    MySQL.insert('INSERT INTO crypto (worth, history) VALUES (:worth, :history) ON DUPLICATE KEY UPDATE worth = :worth, history = :history', {
        worth = NewWorth,
        history = json.encode(sharedConfig.crypto.history[crypto])
    })
end)

lib.addCommand('checkcryptoworth', nil, function(source)
    exports.qbx_core:Notify(source, Lang:t('text.the_qbit_has_a_value_of', {
        crypto = sharedConfig.crypto.worth[coin]
    }))
end)

lib.addCommand('crypto', nil, function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    local MyPocket = math.ceil(Player.PlayerData.money.crypto * sharedConfig.crypto.worth[coin])

    exports.qbx_core:Notify(source, Lang:t('text.you_have_with_a_value_of', {
        playerPlayerDataMoneyCrypto = Player.PlayerData.money.crypto,
        mypocket = MyPocket
    }))
end)

-- Events

RegisterServerEvent('qb-crypto:server:FetchWorth', function()
    for name in pairs(sharedConfig.crypto.worth) do
        local result = MySQL.query.await('SELECT * FROM crypto WHERE crypto = ?', {name})
        if result[1] then
            sharedConfig.crypto.worth[name] = result[1].worth
            if result[1].history then
                sharedConfig.crypto.history[name] = json.decode(result[1].history)
                TriggerClientEvent('qb-crypto:client:UpdateCryptoWorth', -1, name, result[1].worth, json.decode(result[1].history))
            else
                TriggerClientEvent('qb-crypto:client:UpdateCryptoWorth', -1, name, result[1].worth, nil)
            end
        end
    end
end)

RegisterServerEvent('qb-crypto:server:ExchangeFail', function()
    local src = source
    local amount = exports.ox_inventory:Search(src, 'count', 'cryptostick')
    if amount > 0 then
        exports.ox_inventory:RemoveItem(src, 'cryptostick', 1)
        exports.qbx_core:Notify(src, Lang:t('error.cryptostick_malfunctioned'), 'error')
    end
end)

RegisterServerEvent('qb-crypto:server:Rebooting', function(state, percentage)
    sharedConfig.crypto.exchange.rebootInfo.state = state
    sharedConfig.crypto.exchange.rebootInfo.percentage = percentage
end)

RegisterServerEvent('qb-crypto:server:GetRebootState', function()
    TriggerClientEvent('qb-crypto:client:GetRebootState', source, sharedConfig.crypto.exchange.rebootInfo)
end)

RegisterServerEvent('qb-crypto:server:SyncReboot', function()
    TriggerClientEvent('qb-crypto:client:SyncReboot', -1)
end)

RegisterServerEvent('qb-crypto:server:ExchangeSuccess', function(LuckChance)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    local amount = exports.ox_inventory:Search(src, 'count', 'cryptostick')

    if amount < 0 then
        return
    end -- > Only give crypto if they have a cryptostick

    local LuckyNumber = math.random(1, 10)
    local Divider = 1000000
    local Amount = math.random(LuckChance == LuckyNumber and 1599999 or 611111, LuckChance == LuckyNumber and 2599999 or 1599999) / Divider

    exports.ox_inventory:RemoveItem(src, 'cryptostick', 1)
    Player.Functions.AddMoney('crypto', Amount)
    exports.qbx_core:Notify(src, Lang:t('success.you_have_exchanged_your_cryptostick_for', { amount = Amount }), "success", 3500)
    TriggerClientEvent('qb-phone:client:AddTransaction', src, Player, {}, Lang:t('credit.there_are_amount_credited', { amount = Amount }), "Credit")
end)

-- Callbacks

lib.callback.register('qb-crypto:server:HasSticky', function(source)
    local amount = exports.ox_inventory:Search(source, 'count', 'cryptostick')
    return amount > 0
end)

lib.callback.register('qb-crypto:server:GetCryptoData', function(source, name)
    name = name or 'qbit'
    local Player = exports.qbx_core:GetPlayer(source)
    return {
        History = sharedConfig.crypto.history[name],
        Worth = sharedConfig.crypto.worth[name],
        Portfolio = Player.PlayerData.money.crypto,
        WalletId = Player.PlayerData.metadata.walletid
    }
end)

lib.callback.register('qb-crypto:server:BuyCrypto', function(source, data)
    local Player = exports.qbx_core:GetPlayer(source)
    local total_price = math.floor(tonumber(data.Coins) * tonumber(sharedConfig.crypto.worth[coin]))
    if Player and Player.PlayerData.money.bank >= total_price then
        Player.Functions.RemoveMoney('bank', total_price)
        TriggerClientEvent('qb-phone:client:AddTransaction', source, Player, data, Lang:t('credit.you_have_qbit_purchased', { dataCoins = tonumber(data.Coins) }), "Credit")
        Player.Functions.AddMoney('crypto', tonumber(data.Coins))
        return {
            History = sharedConfig.crypto.history[coin],
            Worth = sharedConfig.crypto.worth[coin],
            Portfolio = Player.PlayerData.money.crypto + tonumber(data.Coins),
            WalletId = Player.PlayerData.metadata.walletid
        }
    end

    return false
end)

lib.callback.register('qb-crypto:server:SellCrypto', function(source, data)
    local Player = exports.qbx_core:GetPlayer(source)
    if Player and Player.PlayerData.money.crypto >= tonumber(data.Coins) then
        Player.Functions.RemoveMoney('crypto', tonumber(data.Coins))
        local amount = math.floor(tonumber(data.Coins) * tonumber(sharedConfig.crypto.worth[coin]))
        TriggerClientEvent('qb-phone:client:AddTransaction', source, Player, data, Lang:t('depreciation.you_have_sold', { dataCoins = tonumber(data.Coins) }), "Depreciation")
        Player.Functions.AddMoney('bank', amount)
        return {
            History = sharedConfig.crypto.history[coin],
            Worth = sharedConfig.crypto.worth[coin],
            Portfolio = Player.PlayerData.money.crypto - tonumber(data.Coins),
            WalletId = Player.PlayerData.metadata.walletid
        }
    end

    return false
end)

lib.callback.register('qb-crypto:server:TransferCrypto', function(source, data)
    local newCoin = tostring(data.Coins)
    local newWalletId = tostring(data.WalletId)
    for _, v in pairs(bannedCharacters) do
        newCoin = string.gsub(newCoin, '%' .. v, '')
        newWalletId = string.gsub(newWalletId, '%' .. v, '')
    end
    data.WalletId = newWalletId
    data.Coins = tonumber(newCoin)
    local Player = exports.qbx_core:GetPlayer(source)
    if Player and Player.PlayerData.money.crypto >= tonumber(data.Coins) then
        local query = '%"walletid":"' .. data.WalletId .. '"%'
        local result = MySQL.query.await('SELECT * FROM `players` WHERE `metadata` LIKE ?', {query})
        if not result[1] then return "notvalid" end

        Player.Functions.RemoveMoney('crypto', tonumber(data.Coins))
        TriggerClientEvent('qb-phone:client:AddTransaction', source, Player, data, "You have " .. tonumber(data.Coins) .. " Qbit('s) transferred!", "Depreciation")
        local Target = exports.qbx_core:GetPlayerByCitizenId(result[1].citizenid)

        if Target then
            Target.Functions.AddMoney('crypto', tonumber(data.Coins))
            TriggerClientEvent('qb-phone:client:AddTransaction', Target.PlayerData.source, Player, data, "There are " .. tonumber(data.Coins) .. " Qbit('s) credited!", "Credit")
        else
            local MoneyData = json.decode(result[1].money)
            MoneyData.crypto = MoneyData.crypto + tonumber(data.Coins)
            MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(MoneyData), result[1].citizenid})
        end
        return {
            History = sharedConfig.crypto.history[coin],
            Worth = sharedConfig.crypto.worth[coin],
            Portfolio = Player.PlayerData.money.crypto - tonumber(data.Coins),
            WalletId = Player.PlayerData.metadata.walletid
        }
    end

    return "notenough"
end)

-- Threads

CreateThread(function()
    while true do
        Wait(sharedConfig.crypto.refreshTimer * 60000)
        HandlePriceChance()
    end
end)

-- You touch = you break
if config.ticker.enable then
    CreateThread(function()
        local interval = config.ticker.tickTime * 60000
        if config.ticker.tickTime < 2 then
            interval = 120000
        end
        while true do
            local coinPrice = GetTickerPrice()
            if type(coinPrice) == 'number' then
                sharedConfig.crypto.worth[sharedConfig.crypto.coin] = coinPrice
            else
                print('\27[31m' .. coinPrice .. '\27[0m')
                config.ticker.enable = false
                break
            end
            Wait(interval)
        end
    end)
end
