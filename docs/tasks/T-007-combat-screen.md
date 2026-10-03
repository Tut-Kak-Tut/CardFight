# T-007 Екран бою
Залежить від: T-005, T-006
Модель: sonnet

## Мета
Граючий бій на телефоні: Knight проти випадкового бою з `encounters.json`, тач-керування, End Turn, перемога/поразка, перезапуск. Сцена стає main scene.

## Файли
Створити: `scenes/combat/combat_screen.tscn` (корінь Control + скрипт), `scenes/combat/combat_screen.gd`, `scenes/combat/floating_text.gd`
Змінити: `project.godot` (`run/main_scene="res://scenes/combat/combat_screen.tscn"`)

## Розмітка (1080x1920, будувати в коді в `_ready`, усе в Control з anchors full rect)
- Фон: `TextureRect` `bg_combat.svg`, stretch cover.
- Вороги: `HBoxContainer` по центру, y 180-600, відступ 20; EnemyView на кожного (якщо 3 ворогів — `scale 0.85`).
- Гравець: по центру y 700-1150: спрайт `player_<character>.svg` 256, під ним HP-бар 400x28 з `"hp/max"`, блок-бейдж, StatusRow.
- Енергія: коло 120x120 зліва, y ~1250: `icon_energy.svg` + Label `"2/3"` (40).
- Draw/Discard: зліва знизу Label `"Draw 5"`, праворуч від руки `"Discard 3"` (24), y ~1260.
- End Turn: `Button` 240x110, правий нижній кут вище руки (x 800, y 1230), текст `"End Turn"` 32.
- Рука: внизу, центр y ~1650. Карти CardView, масштаб 0.9, віялом: зсув по x = min(170, 900 / count), поворот ±4° на карту від центру, крайні нижче на 10 px. Перебудовувати при змінах.
- Банер (верх, y 100, прихований): Label 30 на темній смузі — для `"Choose a card to discard"`.
- Оверлей результату: напівпрозорий чорний, Label `"Victory"`/`"Defeat"` 72, кнопка `"Restart"` 300x120 → `get_tree().reload_current_scene()`.

## Логіка
- [x] 1. `_ready`: `character_id := "knight"` (export var), `encounter: Array = []` (export; якщо порожній — випадковий з `GameData.encounters.normal_late`). Створити: player Combatant з `GameData.get_character`; колода — `GameData.get_card(id)` для кожного id з deck; вороги — `EnemyAI.create(GameData.get_enemy(id))`; `state.setup(..., GameData.balance, randi())`; `state.event.connect(_on_event)`; `state.start_combat()`; `refresh()`.
- [x] 2. `refresh()`: HP/блок/статуси гравця, енергія, лічильники, кожен EnemyView `refresh(EnemyAI.preview(e, state))`, рука (CardView `set_playable(card.cost <= state.energy)`), банер при `pending_discard > 0`, оверлей при `state.result != ""`.
- [x] 3. Вибір і розіграш:
  - tap по карті: якщо `pending_discard > 0` → `state.choose_discard(i)`; інакше якщо карта не грається за енергією → `shake()` + `Input.vibrate_handheld(40)`; інакше: target `"enemy"` → виділити (set_selected, піднята на 40 px), вороги `set_targetable(true)`; target `"none"` — перший tap виділяє, повторний tap по тій же карті грає.
  - tap по ворогу при виділеній target-карті → `state.play_card(i, enemy_index)`.
  - drag: карта йде за пальцем (тимчасово поверх усього); на відпусканні: target `"enemy"` → якщо точка над EnemyView живого ворога — грати по ньому; target `"none"` → якщо y < 1350 — грати; інакше повернути в руку.
  - tap по порожньому місцю — зняти виділення.
- [x] 4. End Turn: вимкнути кнопку й ввід, `state.end_player_turn()`, `await get_tree().create_timer(0.4).timeout`, `refresh()`, увімкнути.
- [x] 5. `_on_event(kind, data)`: `damage` → `floating_text` червоне `"-N"` над ціллю (якщо blocked > 0 — синє `"-B"` поруч), EnemyView `flash_hit()`; якщо ціль — гравець і amount > 0 → `Input.vibrate_handheld(60)`; `block` → синє `"+N"`; `heal` → зелене `"+N"`.
- [x] 6. `floating_text.gd` — `class_name FloatingText extends Label`; статичний `spawn(parent, text, color, global_pos)`: шрифт 44, обведення 6, Tween вгору на 80 px і alpha → 0 за 0.8 c, потім `queue_free`.
- [x] 7. Довгий tap по карті: показати велику копію CardView (scale 1.6) по центру екрана, закрити тапом.
- [x] 8. `project.godot`: задати main scene.

## Готово, коли
`"$GODOT" --path .` відкриває бій; можна виграти й програти; Restart працює; тести зелені; у консолі немає помилок під час бою.

## Як перевірити
`"$GODOT" --headless --path . -s tests/run_tests.gd` і `"$GODOT" --path . --quit-after 300` (без помилок у виводі). Ручна перевірка — тестер.
