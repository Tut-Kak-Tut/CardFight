# T-020 Інтеграція: RunState ↔ MetaState/SaveManager, автозбереження, маршрути
Залежить від: T-018
Модель: sonnet

## Мета
Забіг бере пул карт із мети, після завершення нараховує Soul Shards один раз, автоматично зберігається і відновлюється; SceneRouter знає нові екрани; старт гри — Main Menu.

## Файли
Змінити: `scripts/autoload/run_state.gd`, `scripts/autoload/scene_router.gd`, `project.godot`, `scenes/run_result/run_result_screen.gd`, `scenes/map/map_screen.gd`

## Кроки
- [ ] 1. `scene_router.gd`: додати в SCENES `"main_menu": "res://scenes/main_menu/main_menu.tscn"`, `"character_select": "res://scenes/character_select/character_select.tscn"`, `"sanctuary": "res://scenes/sanctuary/sanctuary.tscn"`. Сцени створять T-021..T-023 — поки їх немає, `goto` дає push_error, це ок.
- [ ] 2. `project.godot`: `run/main_scene="res://scenes/main_menu/main_menu.tscn"`.
- [ ] 3. `run_state.gd`:
  - `new_run(char_id, seed)` бере `MetaState.meta.card_pool()` замість `default_unlocked()`; `default_unlocked()` видалити (перевір grep, що більше ніде не викликається).
  - `func save() -> void` — `SaveManager.save_json(SaveManager.RUN, {"run": run.to_dict(), "pending": pending, "reward": reward, "shop": shop, "screen": <поточний екран: "map"|"combat"|"rewards"|"merchant"|"rest">})`.
  - `func has_saved_run() -> bool` — файл є і `run.result == ""`.
  - `func continue_run() -> void` — завантажити, `Run.from_dict`, відновити pending/reward/shop; `screen == "combat"` → бій починається заново з HP на момент входу у вузол (pending.enemies ті самі); інші → `SceneRouter.goto(screen)`.
  - Викликати `save()` після: `new_run`, `enter_node` (перед goto), `combat_won` (після формування reward), `leave_node`, і додати публічний `func mark_dirty() -> void: save()` для екранів (Rewards/Merchant/Rest викликають після покупки/вибору — допиши виклики в ці екрани ЛИШЕ якщо це 1 рядок на дію; інакше лиши TODO в звіті).
  - `func finish_run() -> void` — якщо `run.result != ""`: `MetaState.award(run.seed_value, run.soul_shards())`, `SaveManager.delete(SaveManager.RUN)`. Викликати в `combat_lost`, у `combat_won` при victory і в новому `func abandon() -> void` (`run.result = "defeat"`, finish_run, goto run_result).
  - `ensure_run()`: якщо run == null і `has_saved_run()` → завантажити; інакше як було.
- [ ] 4. `run_result_screen.gd`: показати під shards рядок "Total Soul Shards: N" (`MetaState.meta.shards`). Кнопки: "Continue" → `RunState.run = null; SceneRouter.goto("character_select")`, "Sanctuary" → `RunState.run = null; SceneRouter.goto("sanctuary")`. Обидві в зоні y 1450-1750, ширина ≥ 600, висота ≥ 120 (баг тестера: кнопка надто низько, порожній екран). Гілку `RunState.run == null` змінити на `goto("main_menu")`.
- [ ] 5. `map_screen.gd`: якщо `RunState.run == null` → спробувати `ensure_run()`; якщо run все ще null → `goto("main_menu")`.
- [ ] 6. Тести: у `tests/test_run.gd` нічого не ламається; додай тест, що `Run.to_dict()` після `JSON.stringify/parse_string` → `from_dict` дає те саме hp/gold/deck/map/current_node (якщо такого ще немає — є `test_roundtrip`, перевір, що він йде через JSON; якщо ні — доповни).

## Готово, коли
Тести проходять. Ручна перевірка: почати забіг (через тимчасовий виклик або `map` сцену), пройти 1 бій, закрити гру, запустити — `has_saved_run()` true і `continue_run()` повертає на мапу з тим самим HP/Gold/колодою. Shards за забіг нараховуються рівно один раз.

## Як перевірити
Тести (docs/plan.md «Запуск»).
