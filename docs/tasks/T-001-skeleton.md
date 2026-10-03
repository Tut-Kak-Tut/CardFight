# T-001 Каркас проєкту + тест-раннер
Залежить від: —
Модель: haiku

## Мета
Порожній Godot 4.7 проєкт у корені `D:\MyGames\CardFight` з налаштуваннями під портретний телефон і мінімальний headless тест-раннер.

## Файли
Створити:
- `project.godot`
- `icon.svg` (просте 128x128: темне коло #14161f з білою літерою "C")
- `scripts/autoload/game_data.gd` (заглушка, наповнюється в T-003)
- `tests/test_case.gd`, `tests/run_tests.gd`, `tests/test_smoke.gd`
- порожні теки з `.gitkeep`: `data/`, `scripts/core/combat/`, `scenes/ui/`, `scenes/combat/`, `assets/art/placeholder/`, `assets/audio/`

## Кроки
- [x] 1. `project.godot` (config_version=5):
  - `[application]` `config/name="CardFight"`, `config/features=PackedStringArray("4.7", "Mobile")`, `config/icon="res://icon.svg"`. Main scene НЕ задавати.
  - `[autoload]` `GameData="*res://scripts/autoload/game_data.gd"`
  - `[display]` `window/size/viewport_width=1080`, `window/size/viewport_height=1920`, `window/size/window_width_override=540`, `window/size/window_height_override=960`, `window/stretch/mode="canvas_items"`, `window/stretch/aspect="expand"`, `window/handheld/orientation=1` (portrait).
  - `[input_devices]` `pointing/emulate_touch_from_mouse=true`
  - `[rendering]` `renderer/rendering_method="mobile"`, `textures/vram_compression/import_etc2_astc=true`
- [x] 2. `scripts/autoload/game_data.gd`: `extends Node` + коментар `# Filled in T-003`.
- [x] 3. `tests/test_case.gd`: `class_name TestCase extends RefCounted`; поле `var failures: Array[String] = []`; методи `assert_true(cond: bool, msg := "")`, `assert_eq(a, b, msg := "")` (при невдачі додає в `failures` рядок `"expected %s, got %s. %s"`).
- [x] 4. `tests/run_tests.gd`: `extends SceneTree`. У `_initialize()`: пройти `DirAccess` по `res://tests/`, взяти файли `test_*.gd` (окрім `test_case.gd`), для кожного: `var t = load(path).new()`; для кожного методу з `t.get_method_list()`, ім'я якого починається з `test_`: очистити `t.failures`, викликати `t.call(name)`, надрукувати `PASS file::name` або `FAIL file::name` + кожну помилку. В кінці надрукувати `N passed, M failed` і `quit(1 if M > 0 else 0)`.
- [x] 5. `tests/test_smoke.gd`: `extends TestCase`, `func test_math(): assert_eq(1 + 1, 2)`.
- [x] 6. Виконати імпорт і тести (див. нижче).

## Готово, коли
Команда тестів друкує `1 passed, 0 failed` і повертає exit code 0; імпорт без помилок.

## Як перевірити
```
GODOT="C:/Users/Vova/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s tests/run_tests.gd; echo exit=$?
```
