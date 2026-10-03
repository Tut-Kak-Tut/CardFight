# T-021 Main Menu
Залежить від: T-019, T-020, D-003
Модель: sonnet

## Мета
Стартовий екран гри.

## Файли
Створити: `scenes/main_menu/main_menu.tscn` (корінь Control + скрипт), `scenes/main_menu/main_menu.gd`

## Кроки
- [x] 1. UI кодом (стиль як `scenes/run_result/run_result_screen.gd`): фон `bg_menu.svg`, `logo.svg` угорі (y≈250), під ним рядок shards: `icon_shard.svg` + число `MetaState.meta.shards` (оновлювати по `MetaState.changed`).
- [x] 2. Кнопки по центру-низу (ширина 640, висота 130, шрифт 52, відступ 30): "Continue" (лише якщо `RunState.has_saved_run()`) → `RunState.continue_run()`; "New Run" → якщо є збережений забіг — `confirm_dialog` (див. `scenes/ui/confirm_dialog.gd`) "Abandon current run?" → `RunState.abandon()` не викликати (без нарахування й без Run Result): просто `SaveManager.delete(SaveManager.RUN)`; далі `SceneRouter.goto("character_select")`; "Sanctuary" → `goto("sanctuary")`; "Settings" → `SettingsOverlay.open(self)`.
- [x] 3. `_ready`: `AudioManager.play_music("ambient_menu")`.
- [x] 4. Android back (`NOTIFICATION_WM_GO_BACK_REQUEST`) у меню → `get_tree().quit()`.

## Готово, коли
F5 відкриває Main Menu; усі кнопки ведуть куди треба; Continue є лише за наявності збереження.

## Як перевірити
`"$GODOT" --path .`; тести (docs/plan.md «Запуск»).
