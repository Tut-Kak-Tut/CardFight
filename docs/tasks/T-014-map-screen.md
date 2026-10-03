# T-014 Екран мапи
Залежить від: T-012, T-013, D-002
Модель: sonnet

## Мета
Вертикальна мапа підземелля: старт знизу, бос зверху; тап по доступному вузлу — вхід у нього. Стає main scene.

## Файли
Створити: `scenes/map/map_screen.tscn` (корінь Control + скрипт), `scenes/map/map_screen.gd`, `scenes/map/map_lines.gd`
Змінити: `project.godot` (`run/main_scene="res://scenes/map/map_screen.tscn"`)

## Кроки
- [x] 1. `_ready`: `RunState.ensure_run()`; `run = RunState.run`. Фон `bg_map.svg` (cover). TopBar зверху (y 0..120), `deck_pressed` → DeckOverlay `open(run.deck_cards(), "Deck")`.
- [x] 2. Під TopBar — `ScrollContainer` (y 120..1920, лише вертикальний скрол) з контентом висотою `layers * 240 + 300`. Шар `L` (0 = низ) на y = `content_h - 200 - L*240`. Позиція вузла по x: `90 + (index + 0.5) / count * 900`, плюс стабільний зсув ±40 px (`hash(node.id) % 81 - 40`); бос — по центру, y на 60 px вище.
- [x] 3. `map_lines.gd` — `extends Control` на весь контент, `_draw()`: для кожного ребра `draw_line` 6 px; колір `#3a3f52`; ребра з поточного вузла (або всі ребра шару 0 на старті) до доступних — `#c9a24b`; пройдений шлях (між послідовними visited) — `#e8e2d0`. Пунктир не потрібен.
- [x] 4. Вузол — `TextureButton` 120x120 (бос 160x160), текстура `node_<type>.svg`, `ignore_texture_size`, `stretch_mode KEEP_ASPECT_CENTERED`, pivot у центрі. Стан:
  - доступний (`run.available_nodes()`) — пульсація scale 1.0↔1.12 (Tween loop 0.8 c), кликабельний;
  - пройдений (`visited`) — `modulate #8a8f9c` + `icon_check.svg` 48 у правому верхньому куті;
  - поточний — кільце (draw_arc у map_lines, r 75, #c9a24b, 5 px);
  - інші — `modulate Color(1,1,1,0.45)`, не клікаються.
  Підпис типу під вузлом не потрібен.
- [x] 5. Тап по доступному: коротка анімація (scale 1.25, 0.12 c), потім `RunState.enter_node(id)`. Захист від подвійного тапу.
- [x] 6. Скрол на старті: так, щоб поточний шар (або шар 0) був на ~70% висоти екрана. Перетягування пальцем скролить (ScrollContainer з тачем працює; кнопки не повинні спрацьовувати після свайпу > 20 px — використай `scroll_deadzone = 20`).
- [x] 7. Якщо `run.result != ""` (наприклад, повернулись після поразки) — `SceneRouter.goto("run_result")`.
- [x] 8. project.godot: main scene → map. Запуск без помилок.

## Готово, коли
F5 → мапа нового забігу; доступні вузли пульсують; тап по бою відкриває бій, після Continue (поки екрана нагород може не бути) — без падінь, крім відсутньої сцени rewards (тоді push_error від SceneRouter — ок до T-015).

## Як перевірити
`"$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd; "$GODOT" --path . --quit-after 300`
