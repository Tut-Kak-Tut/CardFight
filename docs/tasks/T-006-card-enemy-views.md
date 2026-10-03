# T-006 UI-компоненти: CardView, EnemyView, StatusRow
Залежить від: T-003, D-001 (SVG у `assets/art/placeholder/`). Від бойового ядра НЕ залежить — працює з Dictionary і об'єктами з полями (duck typing).
Модель: sonnet

## Мета
Перевикористовувані вузли для відображення карти, ворога і статусів. Логіки бою тут немає — лише показ і сигнали.

## Файли
Створити: `scenes/ui/card_view.tscn` + `card_view.gd`, `scenes/ui/enemy_view.tscn` + `enemy_view.gd`, `scenes/ui/status_row.gd`
Правило: `.tscn` мінімальні (кореневий вузол + скрипт), дочірні вузли будуються в коді в `_ready()` — менше шансів зламати сцену.

## Кроки
- [x] 1. `status_row.gd` — `class_name StatusRow extends HBoxContainer`; `func set_statuses(st: Dictionary)`: перебудувати дітей: для кожного статусу `TextureRect` 40x40 з `res://assets/art/placeholder/status_<name>.svg` + `Label` з числом (шрифт 22, обведення 4 px чорне). Порядок: strength, vulnerable, weak, poison, bastion, strength_per_turn.
- [x] 2. `card_view.gd` — `class_name CardView extends Control`, розмір 240x340, `pivot_offset` у центрі низу.
  - `var card: Dictionary`; `func set_card(c: Dictionary)`: фон `TextureRect` — `card_frame_<type>.svg`; Label вартості (центр 36,36, розмір 34, білий з обведенням); назва (y 70-110, по центру, 26; якщо `c.upgraded` — колір #7ed957); тип (`Attack`/`Skill`/`Power`, 18, сірий, y 120); текст опису (`Label` autowrap, по центру, 20, область y 200-320, x 16-224).
  - `func set_playable(ok: bool)` — `modulate = Color(1,1,1)` або `Color(0.5,0.5,0.5)`.
  - `func set_selected(on: bool)` — підсвітка (жовта рамка `Panel`/`ReferenceRect` 4 px #c9a24b).
  - `func shake()` — Tween: x ±12 px 3 рази за 0.25 c.
  - Ввід (`_gui_input`, працює і з мишею, і з тачем, бо emulate_touch увімкнено — обробляй `InputEventMouseButton` та `InputEventMouseMotion`):
    - signals: `tapped(view)`, `long_pressed(view)` (утримання >= 0.5 c без руху > 20 px), `drag_moved(view, global_pos)`, `drag_released(view, global_pos)`.
    - рух > 20 px після натискання → режим drag: емітити drag_moved на кожен рух, на відпускання — drag_released; tapped у цьому разі не емітити.
  - `mouse_filter = STOP`.
- [x] 3. `enemy_view.gd` — `class_name EnemyView extends Control`, розмір 300x420.
  - `var enemy` (Combatant або будь-що з полями `id, name, hp, max_hp, block, statuses`).
  - Будова (зверху вниз): рядок наміру (іконка 64 `intent_<kind>.svg` + Label числа 30), спрайт 256x256 (`enemy_<id>.svg`; для `lich_lord` 300x300; fallback — сірий ColorRect), назва (20), HP-бар (`ProgressBar` 260x24, червоний #a8322d, текст `"hp/max"` поверх), блок-бейдж (іконка `icon_block.svg` 40 + число, видимий лише якщо block > 0), StatusRow.
  - `func set_enemy(e)`; `func refresh(preview: Dictionary)`: preview як у T-005 — `{"intent","damage","times","block"}`. Іконка: `attack`/`attack_debuff` → intent_attack, `attack_defend` → intent_attack, `defend` → intent_defend, `buff` → intent_buff, `debuff` → intent_debuff. Текст: якщо damage >= 0 → `"16"` або `"8x2"`; інакше порожньо. Якщо ворог мертвий — `visible = false` (без зсуву сусідів: використовуй `modulate.a = 0` і `mouse_filter = IGNORE`).
  - `func set_targetable(on: bool)` — пульсуюча червона рамка (Tween modulate).
  - `func flash_hit()` — спрайт червоніє на 0.15 c.
  - signal `tapped(view)`.
- [x] 4. Перевірка без бою: тимчасова сцена НЕ потрібна; перевір, що проєкт імпортується без помилок і `test_*` зелені. Якщо є змога — `"$GODOT" --headless --path . --check-only -s scenes/ui/card_view.gd`.

## Готово, коли
Імпорт без помилок/попереджень про ці файли; наявні тести зелені.

## Як перевірити
`"$GODOT" --headless --path . --import` і `"$GODOT" --headless --path . -s tests/run_tests.gd` (`$GODOT` — у docs/plan.md)
