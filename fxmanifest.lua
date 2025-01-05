fx_version 'cerulean'
game 'gta5'

author 'paris RP'
description 'Job de collecte des déchets pour ESX'
version '1.0.0'

shared_script '@es_extended/locale.lua'

client_scripts {
    'client.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua',
}

dependencies {
    'es_extended'
}
