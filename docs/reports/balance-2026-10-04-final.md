# Баланс 2026-10-04 (на основі sim-2026-10-04.md, test-2026-10-04-final.md)

Ціль: Mage на сильному боті 16.3% -> 50-60% (Knight 58.7%). Knight, вороги, склад колоди і unlock_cost не змінюються.

## v1 — ВІДКОЧЕНО
unlock_cost Plague/Insight/Arcane Charge/Meteor -> 0, колода 3 Barrier + 2 Poison Cloud, HP 75. Симуляція: Mage 13.3% (гірше), boss_reached 59% (було 82%), смерті в мультиворожих боях L6-L9; -1 Barrier послабив захист; unlock_cost=0 ламає мета-прогресію (test_meta::test_pool_start). Урок: проблема в захисті/AoE проти 2-3 ворогів і HP, а не в пулі.

## v2 — лише числа Mage-карт і max_hp
| Параметр | Файл | Було -> Стало | Чому | Очікуваний ефект |
|---|---|---|---|---|
| barrier block (upg) | data/cards.json | 5 (8) -> 7 (10) | 4 Barrier у колоді: +2 блоку = +8 блоку/цикл колоди (~+40%); Knight Defend 5 (за 1 енергію, але 4 Defend + Bastion/Iron Skin), рівняємо з Arcane Shield | менше урону в мультиворожих боях, вищий HP на вході в бос |
| arcane_shield block (upg) | data/cards.json | 7 (10) -> 9 (12) | Common-захист на 1 енергію має бути помітно вище стартового Barrier (7) | захист у пізніх шарах |
| chain_lightning dmg AoE (upg) | data/cards.json | 7 (10) -> 9 (12) | Проти 2-3 ворогів 2 енергії за 7 = слабше за 2x Spark; 9x2-3 = 18-27 сумарно | швидше вбиває групи L6-L9, менше ударів по гравцю |
| Mage max_hp | data/characters.json | 70 -> 78 (+11%) | Бос приходить на ~48% HP; +8 HP ≈ +10 п.п. на вході | більший запас на Lich Lord |

## v3 — корекція після v2 (Mage 66.0%, boss_reached 98.7%, hp_at_boss 58%, смерті boss 96%; ціль 55-60%)
| Параметр | Файл | v2 -> v3 | Чому |
|---|---|---|---|
| Mage max_hp | data/characters.json | 78 -> 74 | -4 HP ≈ -5 п.п. HP на вході в бос |
| chain_lightning dmg AoE (upg) | data/cards.json | 9 (12) -> 8 (11) | AoE трохи переборщили; 8 все ще > 7 початкових |
Очікування: Mage ~56-60%. Якщо ще >62%: Arcane Shield 9->8.

## Не змінено / потрібна задача програмісту
- Knight, вороги, balance.json, склад стартової колоди, unlock_cost — не чіпав.
- Poison Cloud/Spark/Focus/Fireball/Frost Lance не чіпав (крок обмежений 3-4 параметрами); резерв наступних кроків: Poison Cloud 5->6 (upg 8->9), Frost Lance 7->8, Fireball 12->13.

## Що перевірити тестеру в наступному прогоні
- tools/sim.gd (300 забігів): Mage win-rate (ціль 50-60%), boss_reached (було 82%), HP на вході в бос (було ~48%), смерті battle/boss/elite, частка смертей від мультиворожих боїв L6-L9.
- Якщо Mage > 65%: відкотити max_hp до 74 або chain_lightning до 8. Якщо < 35%: застосувати резерв (Poison Cloud, Frost Lance).
- Knight без змін (58.7%); test_meta проходить.
