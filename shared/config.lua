Config = Config or {}

-- Language: 'tr' or 'en'
Config.Locale = 'en'

-- Notice: if nova-ui is installed, use it; otherwise 'qb' (QBCore:Notify) or 'ox' (ox_lib)
Config.UseNovaUI = true
Config.Notify = 'qb'

Config.Command = 'ap'

-- Steps are the per-frame amount at 60 fps. Frame time scales them after that.
Config.MoveStep = 0.025
Config.FastMultiplier = 4.0
Config.SlowMultiplier = 0.35
Config.HeightStep = 0.015
Config.RotateStep = 1.5

Config.DrawHelp = true
Config.HelpPosition = { x = 0.025, y = 0.64 }
Config.FreezeWhileEditing = false
Config.ReplayRpEmote = true        -- rpemotes kuruluysa, pozisyon bitince emote'u tekrar oynat
Config.EditAlpha = 150 -- character translucent in edit mode

-- Mirror the location live to other players while editing.
-- If this is off, other players see the move only when editing ends.
Config.NetworkSync = true
Config.SyncInterval = 90 -- ms (low = smoother, slightly more network traffic)

-- Keep the edit near the start point. HRP servers can turn this off.
Config.LimitMovement = true
Config.MaxDistance = 5.0
Config.MaxHeight = 3.5

-- Block moves through walls and solid objects. HRP servers can turn this off.
Config.CollisionCheck = true

Config.Locales = {
    en = {
        started    = 'Animation position mode enabled.',
        saved      = 'Position saved.',
        cancelled  = 'Position reverted.',
        vehicle    = 'You can\'t use this while in a vehicle.',
        noAnim     = 'No active animation found, position mode opened anyway.',
        help       = 'AP: W/A/S/D move | Q/E rotate | PgUp/PgDn height | Shift fast | Ctrl fine | Enter save | Backspace/Esc cancel',
        suggestion = 'Fine-tune your animation position.',
    },
    tr = {
        started    = 'Animasyon pozisyon modu acildi.',
        saved      = 'Pozisyon kaydedildi.',
        cancelled  = 'Pozisyon geri alindi.',
        vehicle    = 'Aractayken kullanamazsin.',
        noAnim     = 'Aktif animasyon bulunamadi, yine de pozisyon modu acildi.',
        help       = 'AP: W/A/S/D hareket | Q/E cevir | PgUp/PgDn yukseklik | Shift hizli | Ctrl ince | Enter kaydet | Backspace/Esc iptal',
        suggestion = 'Animasyon pozisyonunu ince ayarla.',
    },
}
