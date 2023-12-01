return {
    ticker = {
        enabled = false,         -- Decide whether the real life price ticker should be enabled or not :)
        coin = 'BTC',            --- The coin, please make sure you find the actual name, for example: Bitcoin vs BTC, BTC would be correct
        currency = 'USD',        -- For example USD, NOK, SEK, EUR, CAD and more here https://www.countries-ofthe-world.com/world-currencies.html
        tickTime = 2,            --- Minutes (Minimum is 2 minutes) 20,160 Requests a month, Its recommended to get the free API key so the crypto script doesnt switch on and off if ratelimit is encountered
        apiKey = 'put_api_key_here', -- If you decide to get an api key for the API (https://min-api.cryptocompare.com/pricing) The free plan should be more than enough for 1 Fivem server
        --- Error handle stuff, for more user friendly and readable errors, Don't touch.
        errorHandle = {
            ['fsym is a required param.'] = 'Config error: Invalid / Missing coin name',
            ['tsyms is a required param.'] = 'Config error: Invalid / Missing currency',
            ['cccagg_or_exchange'] = 'Config error: Invalid currency / coin combination', -- For some reason api throws this error if either coin or currency is invalid
        },
    }
}
