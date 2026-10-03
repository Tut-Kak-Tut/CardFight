# T-025 Фікси Етапу 3 (за звітом тестера)
Залежить від: —
Модель: sonnet

## Мета
Виправити баги з `docs/reports/test-2026-10-03-stage3.md`: спрайт Mage у бою, читабельність Settings/Pause/меню, Sanctuary.

## Файли
Змінити: `scenes/combat/combat_screen.gd`, `scenes/ui/settings_overlay.gd`, `scenes/ui/pause_overlay.gd`, `scenes/main_menu/main_menu.gd`, `scenes/sanctuary/sanctuary.gd`

## Кроки
- [x] 1. `combat_screen.gd` `_ready`: спрайт гравця малюється `player_knight` для Mage, бо `_build_ui()` (рядок ~38) викликається ДО `character_id = RunState.run.character_id` (рядок ~42). Перенеси визначення `character_id` (блок `in_run`) перед `_build_ui()` або онови текстуру `player_sprite` після. Перевір, що інші частини `_build_ui` не залежать від порядку.
- [x] 2. Settings і Pause: затемнення фону 0.85; панель — суцільна (StyleBoxFlat bg #14161f, рамка 3px #c9a24b, радіус 16), щоб меню під нею не просвічувало. Тумблери Settings: замість дрібного CheckButton — кнопка-перемикач на всю ширину панелі (висота 120): текст "Sound: ON" / "Sound: OFF", ON — фон #3b5a8a + текст #e8e2d0, OFF — фон #2a2a2a + текст сірий #888. Те саме для Vibration.
- [x] 3. Контраст кнопок у Main Menu і Pause: StyleBoxFlat normal bg #2b2f40 (непрозорий), рамка 2px #c9a24b, hover/pressed — світліший #3b4258; текст #e8e2d0. Винеси стиль у статичну функцію, наприклад `static func style_button(b: Button)` у `settings_overlay.gd`, і використай у трьох файлах.
- [x] 4. Pause у бою: кнопка "Main Menu" не повинна лягати на End Turn — панель паузи повністю непрозора (крок 2) і по центру; переконайся, що всі 4 кнопки в межах панелі.
- [x] 5. Sanctuary: (а) під кожною карткою/персонажем — підкладка ColorRect #14161f alpha 0.85 з відступом 8px, щоб фон не просвічував; (б) шапка (заголовок + shards + Back) — окрема непрозора смуга зверху (#14161f, висота ~200), ScrollContainer починається під нею (не заходить під шапку); (в) червона ціна "не вистачає" → #e05a4f (світліший) для читабельності.

## Готово, коли
Mage у бою — спрайт мага; Settings ON/OFF розрізняються з першого погляду; меню і пауза читаються; Sanctuary без просвічування і наїзду скролу на шапку. Тести проходять.

## Як перевірити
Тести (docs/plan.md «Запуск»); вручну або драйвером `docs/reports/raw/drive_s3.tscn` + скріни.
