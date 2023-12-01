local sharedConfig = require 'config.shared'

-- Functions
local function ExchangeSuccess()
	TriggerServerEvent('qb-crypto:server:ExchangeSuccess', math.random(1, 10))
end

local function ExchangeFail()
	local Odd = 5
	local RemoveChance = math.random(1, Odd)
	local LosingNumber = math.random(1, Odd)
	if RemoveChance == LosingNumber then
		TriggerServerEvent('qb-crypto:server:ExchangeFail')
		TriggerServerEvent('qb-crypto:server:SyncReboot')
	end
end

local function SystemCrashCooldown()
	CreateThread(function()
		while sharedConfig.crypto.exchange.rebootInfo.state do
			if (sharedConfig.crypto.exchange.rebootInfo.percentage + 1) <= 100 then
				sharedConfig.crypto.exchange.rebootInfo.percentage = sharedConfig.crypto.exchange.rebootInfo.percentage + 1
				TriggerServerEvent('qb-crypto:server:Rebooting', true, sharedConfig.crypto.exchange.rebootInfo.percentage)
			else
				sharedConfig.crypto.exchange.rebootInfo.percentage = 0
				sharedConfig.crypto.exchange.rebootInfo.state = false
				TriggerServerEvent('qb-crypto:server:Rebooting', false, 0)
			end
			Wait(1200)
		end
	end)
end

local function HackingSuccess(success)
    if success then
		TriggerEvent('mhacking:hide')
        ExchangeSuccess()
    else
		TriggerEvent('mhacking:hide')
		ExchangeFail()
	end
end

local point = lib.points.new({
	coords = sharedConfig.crypto.exchange.coords,
	distance = 1.5
})

function point:nearby()
	if not sharedConfig.crypto.exchange.rebootInfo.state then
		DrawText3D(Lang:t('text.enter_usb'), sharedConfig.crypto.exchange.coords)

		if IsControlJustPressed(0, 38) then
			local HasItem = exports.ox_inventory:Search('count', 'cryptostick') >= 1
			if HasItem then
				TriggerEvent("mhacking:show")
				TriggerEvent("mhacking:start", math.random(4, 6), 45, HackingSuccess)
			else
				exports.qbx_core:Notify(Lang:t('error.you_dont_have_a_cryptostick'), 'error')
			end
		end
	else
		DrawText3D(Lang:t('text.system_is_rebooting', {rebootInfoPercentage = sharedConfig.crypto.exchange.rebootInfo.percentage}), sharedConfig.crypto.exchange.coords)
	end
end

-- Events

RegisterNetEvent('qb-crypto:client:SyncReboot', function()
	sharedConfig.crypto.exchange.rebootInfo.state = true
	SystemCrashCooldown()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	TriggerServerEvent('qb-crypto:server:FetchWorth')
	TriggerServerEvent('qb-crypto:server:GetRebootState')
end)

RegisterNetEvent('qb-crypto:client:UpdateCryptoWorth', function(crypto, amount, history)
	sharedConfig.crypto.worth[crypto] = amount
	if history then
		sharedConfig.crypto.history[crypto] = history
	end
end)

RegisterNetEvent('qb-crypto:client:GetRebootState', function(RebootInfo)
	if RebootInfo.state then
		sharedConfig.crypto.exchange.rebootInfo.state = RebootInfo.state
		sharedConfig.crypto.exchange.rebootInfo.percentage = RebootInfo.percentage
		SystemCrashCooldown()
	end
end)
