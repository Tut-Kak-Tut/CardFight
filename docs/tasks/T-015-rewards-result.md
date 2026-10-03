# T-015 Екрани Rewards і Run Result
Залежить від: T-012, T-013, D-002
Модель: sonnet

## Мета
Після перемоги — нагороди (золото, 1 з 3 карт або Skip, реліквія після еліти). Наприкінці забігу — підсумок і новий забіг.

## Файли
Створити: `scenes/rewards/rewards_screen.tscn` + `.gd`, `scenes/run_result/run_result_screen.tscn` + `.gd`

## Rewards (`RunState.reward`: `{kind, gold, gold_taken, cards: [ids], card_done, relics: [ids], relic_done}`)
- [x] 1. Фон `bg_combat.svg` + затемнення 0.6. TopBar зверху (deck_pressed → DeckOverlay). Заголовок `"Rewards"` (56, y 180).
- [x] 2. Кнопка золота (y 300, 700x110): `icon_gold.svg` + `"15 Gold"`; tap → `run.gold += gold`, `gold_taken = true`, кнопка зникає, TopBar.refresh.
- [x] 3. Блок карт (y 470..900): підпис `"Choose a card"` (32); 3 CardView масштаб 0.95 в ряд (крок 330); tap → виділення (set_selected); кнопка `"Take"` (y 940, 300x100, активна лише при виділенні) → `run.add_card(id)`, `card_done = true`; кнопка `"Skip (+10 Gold)"` (поруч; число з `balance.skip_reward_gold`) → gold += …, `card_done = true`. Після вибору блок ховається, показується `"Card added: <name>"` або `"Skipped"`. Long-press на карті — збільшена копія (як у бою; можна просто scale 1.6 оверлей).
- [x] 4. Реліквії (лише якщо `relics` не порожній; y 1100..1450): підпис `"Choose a relic"`; 3 рядки-кнопки 900x100: іконка `relic_<id>.svg` 80 + назва (28, золото) + текст (22); tap → `run.add_relic(id)`, `relic_done = true`, блок ховається.
- [x] 5. Кнопка `"Continue"` (y 1700, 400x120) → `RunState.leave_node()`. Якщо карта або реліквія ще не обрані — показати підтвердження `"Leave without taking rewards?"` (Yes/No); неотримане золото зараховується автоматично.
- [x] 6. Стан з `RunState.reward` зберігається (повторне відкриття сцени не дає нагороду двічі).

## Run Result
- [x] 7. Фон `bg_combat.svg` + затемнення. Заголовок `"Victory"` (#c9a24b) або `"Defeat"` (#a8322d), 88 px, y 400.
- [x] 8. Статистика (32 px, y 600..900): `"Floors cleared: N"`, `"Battles won: N"`, `"Elites defeated: N"`, `"Boss defeated"` / нічого; `"Soul Shards earned: N"` (40, золото, y 1000) — `run.soul_shards()`.
- [x] 9. Кнопка `"Continue"` (y 1600, 400x120) → `RunState.new_run(run.character_id)`, `SceneRouter.goto("map")`. (Етап 3 змінить на вибір персонажа і збереже Shards.)

## Готово, коли
Обидва екрани компілюються; тести зелені; з бою після перемоги потрапляєш на Rewards, Continue → мапа; після поразки/боса → Run Result → новий забіг.

## Як перевірити
`"$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd; "$GODOT" --path . --quit-after 300`
