fx_version 'cerulean'
game 'gta5'

description 'QB-Crypto'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_script 'client/main.lua'

dependency 'mhacking'

provide 'qb-crypto'
lua54 'yes'
use_experimental_fxv2_oal 'yes'
