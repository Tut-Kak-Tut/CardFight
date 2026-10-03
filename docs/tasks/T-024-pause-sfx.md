# T-024 Pause overlay + звукові хуки
Залежить від: T-019, T-020, D-003
Модель: sonnet

## Мета
Пауза з Map і Combat (GDD §7 п.9) і виклики звуків/вібро в ключових місцях.

## Файли
Створити: `scenes/ui/pause_overlay.gd`
Змінити: `scenes/map/map_screen.gd`, `scenes/combat/combat_screen.gd`, `scenes/rest/rest_screen.gd`, `scenes/rewards/rewards_screen.gd`, `scenes/merchant/merchant_screen.gd`

## Кроки
- [x] 1. `pause_overlay.gd` — `class_name PauseOverlay extends Control`, кодом, стиль як `settings_overlay.gd`: затемнення, "Paused", кнопки (640x130): "Resume" (закрити), "Settings" (`SettingsOverlay.open(self)`), "Abandon Run" → `confirm_dialog` "Abandon run? You keep Soul Shards earned so far." → `RunState.abandon()`, "Main Menu" → `RunState.save()` → `SceneRouter.goto("main_menu")`. `static func open(parent) -> PauseOverlay`. Поки відкрито — `get_tree().paused = true`, `process_mode = PROCESS_MODE_ALWAYS`; при закритті — false.
- [x] 2. Кнопка паузи `icon_pause.svg` (100x100) у правому верхньому куті Map (не перекриваючи TopBar — за потреби зсунь) і Combat. Android back на цих екранах → відкрити паузу.
- [x] 3. Хуки в `combat_screen.gd` (`_on_event` / `_play`): розіграш карти → `AudioManager.play("card_play")`; урон по ворогу або гравцю → `"hit"`; гравець отримав урон → додатково `AudioManager.vibrate()`; отримання Block → `"block"`. `_ready` → `play_music("boss" if pending.kind == "boss" else "ambient_combat")`.
- [x] 4. `map_screen.gd` `_ready` → `play_music("ambient_menu")`; `rest_screen.gd` `_ready` → `play("campfire")`.
- [x] 5. Автозбереження дій (TODO з T-020): після кожної зміни стану забігу на екранах Rewards (взяти gold / карту / реліквію / Skip), Merchant (покупка, Remove, Heal) і Rest (Rest, Upgrade) — `RunState.mark_dirty()`. Переконайся, що `RunState.screen` на цих екранах відповідає екрану (див. `run_state.gd`), інакше Continue поверне не туди.

## Готово, коли
Пауза відкривається/закривається на Map і Combat, бій під паузою не йде; Abandon веде на Run Result з shards; Main Menu → Continue повертає в забіг. Помилок у консолі немає (звукових файлів ще нема — тиша).

## Як перевірити
`"$GODOT" --path .`; тести.
