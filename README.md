# nova-animpos

> Standalone `/ap` animation position adjuster — nudge your character while seated or
> in an emote so it lines up perfectly (chairs, beds, leaning, etc.). TR/EN built in.

---

## English

### What it does
A lightweight tool to fine-tune your character's position and heading while playing an animation/emote, so you can align to props (chairs, benches, beds...) cleanly.
- Toggle with **`/ap`**.
- While active the character turns semi-transparent so you can see placement.
- On save your position/heading is applied; on cancel everything reverts to where you started.
- **Live sync** — other players see your character move in real time while you adjust (not just teleport at the end). Optional, toggle with `Config.NetworkSync`.
- **Version check** — on start, `version.json` is compared with `main` on `github.com/msaber07/nova-animpos`.
- **Limits** — `Config.LimitMovement` keeps the edit within `Config.MaxDistance` (5 m) and `Config.MaxHeight` (3.5 m) of the start. The server drops sync packets outside that box.
- **Collision** — `Config.CollisionCheck` blocks a move through a wall or solid object. Turn either check off for an HRP server.
- If you use **rpemotes**, the current emote is detected and replayed after adjusting (optional, auto-detected).

### Controls
| Key | Action |
| --- | --- |
| `W / A / S / D` | Move forward / left / back / right |
| `Q / E` | Rotate heading |
| `PageUp / PageDown` | Move up / down |
| `Shift` | Move faster |
| `Ctrl` | Fine (slow) move |
| `Enter` | Save & close |
| `Backspace` / `Esc` | Revert & close |

### Dependencies
- **qb-core** (for the default notification; only if `Config.Notify = 'qb'`)
- **nova-ui** (optional — nicer notifications if running)
- **ox_lib** (optional — only if `Config.Notify = 'ox'`)
- **rpemotes** (optional — re-plays your emote after adjusting)

> Fully standalone otherwise. The client moves your ped. The server only relays that position to other players and drops a packet outside the limit.

### Installation
1. Drop `nova-animpos` into `resources` (e.g. `resources/[standalone]/`).
2. `ensure nova-animpos` in your `server.cfg`.
3. Restart.

### Configuration — `shared/config.lua`
| Option | Description |
| --- | --- |
| `Config.Locale` | `'en'` or `'tr'`. |
| `Config.UseNovaUI` | Use `nova-ui` for notifications if it's running. |
| `Config.Notify` | Fallback provider: `'qb'` or `'ox'`. |
| `Config.Command` | The command name (default `ap`). |
| `Config.MoveStep` / `HeightStep` / `RotateStep` | Base move / height / rotate increments. |
| `Config.FastMultiplier` / `SlowMultiplier` | Shift (fast) and Ctrl (fine) multipliers. |
| `Config.DrawHelp` / `HelpPosition` | Show on-screen help text and its position. |
| `Config.FreezeWhileEditing` | Freeze the ped while adjusting. |
| `Config.ReplayRpEmote` | Re-play the rpemotes emote after saving. |
| `Config.EditAlpha` | Ped transparency while editing (0-255). |
| `Config.NetworkSync` | Show your live movement to other players while adjusting (otherwise they only see the final position). |
| `Config.SyncInterval` | Live-sync send rate in ms (lower = smoother, more traffic). |
| `Config.LimitMovement` | Keep the edit within `MaxDistance` and `MaxHeight` of the start. |
| `Config.MaxDistance` | Horizontal limit in metres. Default `5.0`. |
| `Config.MaxHeight` | Up or down limit in metres. Default `3.5`. |
| `Config.CollisionCheck` | Block a move through a wall or solid object. |
| `Config.Locales` | All messages + help text per language. |

---

## Türkçe

### Ne işe yarar?
Bir animasyon/emote oynatırken karakterin konumunu ve yönünü ince ayarlamak için hafif bir araç — sandalye, bank, yatak gibi prop'lara düzgün hizalanmanı sağlar.
- **`/ap`** ile aç/kapat.
- Mod açıkken karakter yarı saydam olur, yerleşimi rahat görürsün.
- Kaydedince konum/yön uygulanır; iptal edince başladığın yere döner.
- **Canlı senkron** — sen ayar yaparken diğer oyuncular karakterinin hareketini gerçek zamanlı görür (sadece bitişte ışınlanma değil). Opsiyonel, `Config.NetworkSync` ile.
- **Sürüm kontrolü** — açılışta `version.json`, `github.com/msaber07/nova-animpos` üzerindeki `main` ile karşılaştırılır.
- **rpemotes** kullanıyorsan, mevcut emote algılanır ve ayar sonrası tekrar oynatılır (opsiyonel, otomatik).
- **Sınırlar** — `Config.LimitMovement` düzenlemeyi başlangıca `Config.MaxDistance` (5 m) ve `Config.MaxHeight` (3.5 m) içinde tutar. Sunucu bu kutunun dışındaki senkron paketini atar.
- **Çarpışma** — `Config.CollisionCheck` duvar ve katı objenin içinden geçmeyi keser. HRP sunucu iki kontrolü de kapatabilir.

### Kontroller
| Tuş | İşlev |
| --- | --- |
| `W / A / S / D` | İleri / sol / geri / sağ |
| `Q / E` | Yönü çevir |
| `PageUp / PageDown` | Yukarı / aşağı |
| `Shift` | Hızlı hareket |
| `Ctrl` | İnce (yavaş) hareket |
| `Enter` | Kaydet & kapat |
| `Backspace` / `Esc` | Geri al & kapat |

### Bağımlılıklar
- **qb-core** (varsayılan bildirim için; sadece `Config.Notify = 'qb'` ise)
- **nova-ui** (opsiyonel — çalışıyorsa daha şık bildirim)
- **ox_lib** (opsiyonel — sadece `Config.Notify = 'ox'` ise)
- **rpemotes** (opsiyonel — ayar sonrası emote'u tekrar oynatır)

> Aksi halde tamamen standalone. Karakter client tarafında hareket eder. Sunucu bu konumu diğer oyunculara iletir ve sınırın dışındaki paketi atar.

### Kurulum
1. `nova-animpos`'u `resources` içine at (örn. `resources/[standalone]/`).
2. `server.cfg`'ye `ensure nova-animpos` ekle.
3. Yeniden başlat.

### Ayarlar — `shared/config.lua`
| Ayar | Açıklama |
| --- | --- |
| `Config.Locale` | `'en'` veya `'tr'`. |
| `Config.UseNovaUI` | Çalışıyorsa bildirim için `nova-ui` kullan. |
| `Config.Notify` | Yedek sağlayıcı: `'qb'` veya `'ox'`. |
| `Config.Command` | Komut adı (varsayılan `ap`). |
| `Config.MoveStep` / `HeightStep` / `RotateStep` | Temel hareket / yükseklik / dönüş adımı. |
| `Config.FastMultiplier` / `SlowMultiplier` | Shift (hızlı) ve Ctrl (ince) çarpanları. |
| `Config.DrawHelp` / `HelpPosition` | Ekran yardım metnini göster ve konumu. |
| `Config.FreezeWhileEditing` | Ayar sırasında ped'i dondur. |
| `Config.ReplayRpEmote` | Kaydedince rpemotes emote'unu tekrar oynat. |
| `Config.EditAlpha` | Düzenleme sırasında ped saydamlığı (0-255). |
| `Config.NetworkSync` | Ayar yaparken canlı hareketi diğer oyunculara göster (yoksa sadece son konumu görürler). |
| `Config.SyncInterval` | Canlı senkron gönderim aralığı (ms; düşük = daha akıcı, daha çok trafik). |
| `Config.LimitMovement` | Düzenlemeyi başlangıca `MaxDistance` ve `MaxHeight` içinde tut. |
| `Config.MaxDistance` | Yatay sınır, metre. Varsayılan `5.0`. |
| `Config.MaxHeight` | Yukarı veya aşağı sınır, metre. Varsayılan `3.5`. |
| `Config.CollisionCheck` | Duvar ve katı objenin içinden geçmeyi kes. |
| `Config.Locales` | Dile göre tüm mesajlar + yardım metni. |

---

**Author:** Nova · **Version:** 1.1.0 · **Type:** Standalone
