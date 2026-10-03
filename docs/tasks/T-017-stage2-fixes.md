# T-017 Виправлення етапу 2
Залежить від: T-013..T-016
Модель: sonnet
Джерело: `docs/reports/test-2026-10-03-stage2.md` (баги 1-7, UX)

## Файли
Змінити: `scenes/run_result/run_result_screen.gd`, `scenes/combat/combat_screen.tscn`, `scenes/combat/combat_screen.gd`, `scenes/rewards/rewards_screen.gd`, `scenes/merchant/merchant_screen.gd`, `scenes/rest/rest_screen.gd`, `scenes/ui/deck_overlay.gd`, `scenes/map/map_screen.gd`, `scripts/core/map/map_generator.gd`, `tests/test_map_generator.gd`
НЕ чіпати `data/` (там паралельно працює балансер).

## Кроки
- [x] 1. (блокер) `run_result_screen.gd`: НЕ викликати `ensure_run()`. Показувати `RunState.run` як є. Якщо `RunState.run == null` → `RunState.new_run()` і `SceneRouter.goto("map")`.
- [x] 2. `combat_screen.tscn`: корінь — anchors full rect, усі offset = 0 (зараз 25/-92).
- [x] 3. `rewards_screen.gd`, `run_result_screen.gd`: на початку `_ready` — `set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)` (корінь зараз 0x0, фон не малюється). Перевір те саме для merchant/rest/map — у всіх коренях має бути full rect.
- [x] 4. Merchant Heal: кнопка неактивна, якщо `run.hp >= run.max_hp` (додатково до heal_used / нестачі золота).
- [x] 5. Бій у режимі забігу: кнопка оверлею після поразки — `Continue` (не `Restart`).
- [x] 6. `merchant_screen.gd`, `rest_screen.gd`: якщо `RunState.run == null` → `RunState.ensure_run()` перед використанням (запуск сцени напряму не падає).
- [x] 7. `deck_overlay.gd`: у `open()` — `move_to_front()` і `z_index = 50`; заголовок на y 150 (нижче TopBar), Close — над усім (оверлей модальний, кнопка Leave під ним не має бути видна: фон оверлея непрозорий на 0.92).
- [x] 8. `map_screen.gd`: вузли 140x140, бос 180x180; кільце поточного r 85.
- [x] 9. Run Result: блок статистики y 650..1050, Shards y 1150, кнопка Continue y 1450 (зона пальця).
- [x] 10. `map_generator.gd`: підтримати ключ `cfg.merchant_max` (fallback 99): при призначенні типів і у `validate` — кількість merchant <= merchant_max. Тест: cfg з `merchant_max = 3` → 500 мап валідні, merchant ≤ 3. (Сам ключ у balance.json додасть балансер.)
- [x] 11. Тести + `--quit-after 300` без помилок.

## Готово, коли
Тести зелені; після перемоги над босом Run Result показує Victory і реальні Shards.

## Як перевірити
`"$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd; "$GODOT" --path . --quit-after 300`
