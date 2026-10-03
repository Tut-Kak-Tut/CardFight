# T-011 Генератори нагород і торговця
Залежить від: — (дані з `data/*.json`)
Модель: sonnet

## Мета
Чисті функції: золото за бій, 3 карти на вибір, реліквії на вибір, асортимент торговця. Правила — GDD 4.7, 4.8.

## Файли
Створити: `scripts/core/rewards/reward_generator.gd`, `scripts/core/rewards/shop_generator.gd`, `tests/test_rewards.gd`

## Пул карт
`pool(data, class_id, unlocked) -> Array` = id з `unlocked`, у яких `class` == class_id або `"neutral"`, і `rarity != "starter"`. Увага: на старті в пулі Knight є лише common — потрібен fallback рідкості.

## Кроки
- [x] 1. `reward_generator.gd` — `class_name RewardGenerator extends RefCounted`, статичні:
  - `pool(data, class_id: String, unlocked: Array) -> Array`
  - `combat_gold(kind: String, balance: Dictionary, rng) -> int` — battle: `rng.randi_range(gold_battle[0], gold_battle[1])`; elite: `gold_elite`; boss: 0.
  - `roll_rarity(kind, balance, rng) -> String` — за `rarity_weights[kind == "elite" ? "elite" : "normal"]`.
  - `card_choices(data, class_id, unlocked, kind, rng, n := 3) -> Array` — n унікальних id: для кожного слота roll_rarity; якщо в пулі немає невибраних карт цієї рідкості — fallback rare → uncommon → common → будь-яка; якщо пул менший за n — повернути скільки є.
  - `relic_choices(data, owned: Array, rng, n := 3) -> Array` — унікальні id реліквій, яких немає в owned.
- [x] 2. `shop_generator.gd` — `class_name ShopGenerator extends RefCounted`:
  `static func generate(data, class_id: String, unlocked: Array, owned_relics: Array, removes_done: int, rng) -> Dictionary`:
  ```
  {"cards": [{"id", "price", "sold": false}] — balance.shop.cards: 2 common, 2 uncommon, 1 rare (той самий fallback рідкості; унікальні),
   "relics": [{"id", "price": shop.relic_price, "sold": false}] — shop.relics штук (relic_choices),
   "remove_price": shop.remove_price + shop.remove_price_step * removes_done, "remove_used": false,
   "heal_price": shop.heal_price, "heal_pct": shop.heal_pct, "heal_used": false}
  ```
  Ціна карти = `card_price[rarity] + rng.randi_range(-jitter, jitter)` (jitter — `card_price_jitter[rarity]`), де rarity — справжня рідкість обраної карти (після fallback).
- [x] 3. `tests/test_rewards.gd` (GameData через `.new()` + `load_all()`, `free()` наприкінці):
  - pool knight зі стартовим unlocked (усі карти з `unlock_cost == 0` і не starter) не містить mage-карт і starter-карт;
  - card_choices 200 разів: завжди 3 унікальних id з пулу; elite з повним пулом (усі не-starter карти) дає rare частіше, ніж normal;
  - combat_gold в межах діапазонів з balance;
  - relic_choices не повертає owned; з 5 owned → 1 реліквія;
  - shop: 5 унікальних карт, ціни в межах `price ± jitter` для своєї рідкості, 2 реліквії, remove_price з removes_done=2 = 75+50 (з даних).

## Готово, коли
Тести зелені.

## Як перевірити
`"$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd`
