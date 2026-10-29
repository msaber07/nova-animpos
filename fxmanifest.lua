fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nova-animpos'
author 'Nova'
description 'Standalone animation position adjuster (/ap) for seated/animation alignment'
version '1.1.0'

shared_scripts {
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

-- nova-ui, ox_lib and rpemotes are OPTIONAL (used automatically if available).
