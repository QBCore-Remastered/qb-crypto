return {
    crypto = {
        lower = 500,
        upper = 5000,
        history = {
            qbit = {}
        },

        worth = {
            qbit = 1000
        },

        labels = {
            qbit = "Qbit"
        },

        exchange = {
            coords = vec3(1276.21, -1709.88, 54.57),
            rebootInfo = {
                state = false,
                percentage = 0
            },
        },

        -- For auto updating the value of qbit
        coin = 'qbit',
        refreshTimer = 10, -- In minutes, so every 10 minutes.

        -- Crashes or luck
        chanceOfCrashOrLuck = 2, -- This is in % (1-100)
        crash = { 20, 80 },  -- Min / Max
        luck = { 20, 45 },   -- Min / Max

        -- If not not Chance of crash or luck, then this shit
        chanceOfDown = 30, -- If out of 100 hits less or equal to
        chanceOfUp = 60,  -- If out of 100 is greater or equal to
        casualDown = { 1, 10 }, -- Min / Max (If it goes down)
        casualUp = { 1, 10 }, -- Min / Max (If it goes up)
    }
}
