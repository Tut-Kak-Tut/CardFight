# GDD — CardFight (робоча назва)

Мова: документ — українською; усі ігрові тексти (назви карт, описи, UI, імена ворогів, реліквій, статусів) — англійською і дані в конфігу теж англійською. Інтерфейс гри — лише англійська (без локалізації в MVP).

## 1. Концепт
Мобільна 2D карткова roguelike-гра (deckbuilder) у дусі Slay the Spire, темне фентезі. Для гравців, які люблять тактичні сесії (20-30 хв на забіг) однією рукою в портретній орієнтації. Кайф: збирати колоду з нагород, читати наміри ворогів, вирішувати на вогнищі між лікуванням і покращенням карти та відкривати нові карти й персонажів після кожного забігу.

## 2. Платформа і стек
- Рушій: Godot 4 (GDScript). Платформа: Android, мінімум API 24 (Android 7); iOS пізніше.
- Орієнтація: портрет, базова роздільність 1080x1920, stretch mode `canvas_items`, aspect `expand`. Враховувати безпечні зони (виріз, жести).
- Керування (одна рука, тач): перетягнути карту вгору на ціль/у зону розіграшу АБО тап по карті (підсвітка) + тап по цілі. Карти без цілі — тап двічі або перетягнути вище ліній руки. «End Turn» — правий нижній кут. Довгий тап по карті/ворогу/реліквії — опис. Усі інтерактивні елементи >= 48 dp.
- Дані: усі числа й тексти в JSON/Resource (`cards`, `enemies`, `characters`, `shop`, `map`, `meta`, `relics`), не в коді.
- Збереження: автозбереження після кожного вузла (поточний забіг) і мета-прогресії.
- Туторіалу і монетизації в MVP немає.

## 3. Core loop
- 30 секунд: хід у бою — добрати 5 карт, зіграти карти за енергію, прочитати наміри ворогів, закінчити хід, отримати удар.
- 5 хвилин: 1-2 вузли мапи (бій, вогнище або торговець) + вибір 1 з 3 карт нагороди.
- Сесія (20-30 хв): вибір персонажа з його стартовою колодою → мапа з 10 шарів (бої, еліта, торговець, вогнище) → бос → екран результату, Soul Shards → повернення до вибору персонажа.

## 4. Механіки

### 4.1 Бій
- Гравець: HP, Block, Energy. Старт бою: Block 0, Energy 3, колода тасується в Draw pile.
- Початок ходу гравця: Block скидається в 0 (крім статусу Bastion), Energy відновлюється до 3, добирається 5 карт. Якщо Draw pile порожній — Discard pile тасується в нього.
- Розіграш: карта коштує Energy; якщо не вистачає — карта сіра, розіграш відхиляється (вібро + shake).
- Макс. рука 10: зайві карти йдуть у Discard.
- Кінець ходу: усі карти руки йдуть у Discard. Далі ходять вороги зліва направо, виконуючи показаний намір.
- Перемога: усі вороги мертві. Поразка: HP гравця 0 → забіг закінчено.
- Урон спершу знімає Block, залишок — HP. Блок ворога працює так само.
- Крайні випадки: Exhaust — карта до кінця бою йде в Exhaust pile; ціль померла — карта по цілі не розігрується, багатоцільова б'є решту; Block ворога скидається на початку його ходу.

### 4.2 Типи карт
- Attack (червона рамка), Skill (синя), Power (золота; після розіграшу діє до кінця бою і не повертається в колоду).

### 4.3 Статуси
| Статус | Ефект | Тривалість |
|---|---|---|
| Vulnerable | отримує на 50% більше урону | N ходів, -1 в кінці ходу носія |
| Weak | завдає на 25% менше урону | N ходів, -1 в кінці ходу носія |
| Strength | +X урону кожної атаки | до кінця бою |
| Poison | на початку ходу носія втрачає HP = стаку, стак -1 | поки стак > 0 |
| Bastion | Block не скидається на початку ходу | до кінця бою |
Округлення вниз, мінімум 0 урону.

### 4.4 Наміри ворогів
Над кожним ворогом іконка + число: Attack X, Defend Y, Buff, Debuff. Намір фіксується на початку ходу гравця; число оновлюється при зміні Strength/Weak/Vulnerable. Патерни циклічні (5.4), у боса — за фазами.

### 4.5 Мапа підземелля
- 10 шарів, 2-3 вузли в шарі (крім шарів 1 і 10); шлях лише вперед по лініях до сусідніх вузлів наступного шару; вся мапа видна.
- Шар 1: 2 вузли Battle. Шар 10: один вузол Boss.
- Частка вузлів у шарах 2-9 (приблизно, ~20 вузлів): Battle ~46%, Rest ~22%, Merchant ~15%, Elite ~12%; решта допускає відхилення на ±1 вузол.
- Правила генерації (по seed): Elite — лише шари 4-9, 1-2 на мапу; Merchant — 2-3 на мапу (шар 8 містить хоча б одного); Rest — 4-5 на мапу, лише шари 3-9, шар 9 завжди містить Rest (вогнище перед босом); шари 2-3 без Elite; два Rest/Merchant підряд на одному шляху недопустимі; без мертвих кінців.
- Тап по вузлу, доступному з поточної позиції, відкриває його; решта приглушені.
- Типи вузлів (UI-підписи): Battle, Elite, Merchant, Rest, Boss. Подій у MVP немає.

### 4.6 Вогнище (Rest)
- Гравець обирає ОДНУ дію:
  - «Rest» — лікує 35% макс. HP (Knight +28, Mage +21), не вище максимуму;
  - «Upgrade» — відкривається колода, гравець обирає 1 карту; вона замінюється на покращену версію (позначка «+» у назві) до кінця забігу.
- Обмеження: карту можна покращити лише раз (карти з «+» недоступні); якщо покращуваних карт немає — доступний лише Rest; Rest при повному HP дозволений (нічого не дає), але попереджає. Вибір підтверджується; після дії кнопка «Leave».
- Покращені версії всіх карт — таблиця 5.3.

### 4.7 Нагорода після бою
- Gold (за типом бою), вибір 1 з 3 карт або «Skip» (+10 Gold). Після Elite додатково 1 реліквія з 3. Після Boss — екран Victory.
- Рідкість карт у нагороді: Common 65%, Uncommon 30%, Rare 5% (Elite: 45/40/15). Пул: карти персонажа + нейтральні, лише відкриті в Sanctuary. Карти в нагородах і в торговця — базові (не покращені).
- Реліквії пасивні до кінця забігу.

### 4.8 Торговець (Merchant)
- Продає: 5 карт (2 Common, 2 Uncommon, 1 Rare), 2 реліквії, «Remove a card», «Heal».
- Купівля: тап по товару → підтвердження → Gold списується. Недостатньо Gold — ціна червона, купівля неможлива.
- Heal: +20% макс. HP за 60 Gold, раз на торговця.
- Колода мінімум 5 карт; асортимент не оновлюється.

### 4.9 Вибір персонажа
- Вибір персонажа = вибір його фіксованої стартової колоди (10 карт). Закриті персонажі — силует + ціна. Відкриті карти з'являються лише в нагородах і в торговця.

### 4.10 Мета-прогресія
- Після забігу (перемога/поразка) Soul Shards: 5 за кожен пройдений шар + 15 за кожного Elite + 30 за Boss.
- У Sanctuary за Soul Shards відкриваються 12 карт (ціни — таблиця 5.6) і персонаж Mage (150). Knight відкритий спочатку.
- Мета-прогрес зберігається назавжди; статових бонусів немає, лише ширший пул.

## 5. Сутності і числа

### 5.1 Баланс (числа для конфігу)
| Параметр | Значення |
|---|---|
| Energy за хід | 3 |
| Карт у руці на початку ходу | 5 |
| Макс. карт у руці | 10 |
| Стартова колода | 10 карт |
| Мін. колода | 5 |
| Vulnerable / Weak | +50% / -25% |
| HP Knight / Mage | 80 / 60 |
| Rest: лікування | 35% макс. HP |
| Покращень на вогнищі | 1 карта за вузол |
| Gold за Battle / Elite | 12-22 / 30-40 |
| Стартовий Gold | 50 |
| Skip нагороди | +10 Gold |
| Ціна Common / Uncommon / Rare карти | 50 / 80 / 140 (±10, Rare ±15) |
| Ціна реліквії | 150 |
| Remove a card | 75, +25 за кожне наступне в забігу |
| Heal у торговця | +20% макс. HP за 60 Gold |
| Soul Shards: шар / Elite / Boss | 5 / 15 / 30 |
| Ціна Mage | 150 Soul Shards |

### 5.2 Персонажі
| Персонаж | HP | Energy | Стиль | Стартова колода (10) |
|---|---|---|---|---|
| Knight | 80 | 3 | Block, сильні удари | 5x Strike, 4x Defend, 1x Battle Cry |
| Mage | 60 | 3 | урон по всіх, Poison, добір | 4x Spark, 4x Barrier, 1x Poison Cloud, 1x Focus |

### 5.3 Карти (30) і їх покращення
Скорочення: R — рідкість (Starter/Common/Uncommon/Rare); Cost — вартість; «+» — покращена версія (назва + "+"). Покращення змінює лише вказане. 0 = безкоштовна.

Knight (12):
| Card | Type | R | Cost | Effect | Upgraded (+) |
|---|---|---|---|---|---|
| Strike | Attack | Starter | 1 | Deal 6 damage | Deal 9 damage |
| Defend | Skill | Starter | 1 | Gain 5 Block | Gain 8 Block |
| Battle Cry | Skill | Starter | 1 | Gain 2 Strength. Exhaust | Cost 0 |
| Slash | Attack | Common | 1 | Deal 9 damage. Apply 1 Vulnerable | Deal 12 damage. Apply 2 Vulnerable |
| Double Strike | Attack | Common | 1 | Deal 5 damage twice | Deal 7 damage twice |
| Iron Skin | Skill | Common | 2 | Gain 12 Block | Gain 16 Block |
| Quick Guard | Skill | Common | 0 | Gain 4 Block. Draw 1 | Gain 6 Block. Draw 1 |
| Stun Blow | Attack | Uncommon | 2 | Deal 14 damage. Apply 2 Weak | Deal 18 damage. Apply 3 Weak |
| Whirlwind | Attack | Uncommon | 2 | Deal 8 damage to ALL enemies | Deal 11 damage to ALL enemies |
| Bastion | Power | Uncommon | 2 | Block is not removed at the start of your turn | Cost 1 |
| Vengeance | Attack | Uncommon | 1 | Deal 6 damage + half of your Block | Deal 9 damage + half of your Block |
| Titan's Wrath | Attack | Rare | 3 | Deal 30 damage. Exhaust | Deal 40 damage. Exhaust |

Mage (12):
| Card | Type | R | Cost | Effect | Upgraded (+) |
|---|---|---|---|---|---|
| Spark | Attack | Starter | 1 | Deal 6 damage | Deal 9 damage |
| Barrier | Skill | Starter | 1 | Gain 5 Block | Gain 8 Block |
| Poison Cloud | Skill | Starter | 1 | Apply 4 Poison | Apply 7 Poison |
| Focus | Skill | Starter | 0 | Draw 2 cards. Discard 1 | Draw 3 cards. Discard 1 |
| Fireball | Attack | Common | 2 | Deal 12 damage | Deal 16 damage |
| Frost Lance | Attack | Common | 1 | Deal 7 damage. Apply 1 Weak | Deal 10 damage. Apply 2 Weak |
| Arcane Shield | Skill | Common | 1 | Gain 7 Block | Gain 10 Block |
| Plague | Skill | Uncommon | 1 | Apply 6 Poison. Exhaust | Apply 9 Poison. Exhaust |
| Chain Lightning | Attack | Uncommon | 2 | Deal 7 damage to ALL enemies | Deal 10 damage to ALL enemies |
| Insight | Skill | Uncommon | 1 | Draw 3 cards. Exhaust | Draw 4 cards. Exhaust |
| Arcane Charge | Power | Uncommon | 1 | At the start of your turn gain 1 Strength | Cost 0 |
| Meteor | Attack | Rare | 3 | Deal 25 damage to ALL enemies. Exhaust | Deal 35 damage to ALL enemies. Exhaust |

Neutral (6; доступні обом):
| Card | Type | R | Cost | Effect | Upgraded (+) |
|---|---|---|---|---|---|
| Punch | Attack | Common | 1 | Deal 5 damage. Gain 2 Block | Deal 7 damage. Gain 3 Block |
| Dodge | Skill | Common | 1 | Gain 6 Block | Gain 9 Block |
| Strength Potion | Skill | Common | 0 | Gain 1 Strength. Exhaust | Gain 2 Strength. Exhaust |
| Shadow Strike | Attack | Uncommon | 1 | Deal 8 damage. Apply 1 Vulnerable | Deal 11 damage. Apply 2 Vulnerable |
| Ancestral Spirit | Skill | Uncommon | 1 | Heal 6 HP. Exhaust | Heal 9 HP. Exhaust |
| Dark Pact | Skill | Rare | 0 | Gain 1 Energy. Draw 2 cards. Exhaust | Gain 1 Energy. Draw 3 cards. Exhaust |

### 5.4 Вороги (патерн циклічний)
| Enemy | HP | Pattern |
|---|---|---|
| Skeleton Warrior | 30 | Attack 8 → Attack 8 → Defend 8 |
| Skeleton Archer | 22 | Attack 7 → Attack 11 → Debuff: 1 Weak on player |
| Bone Minion | 10 | Attack 4 → Attack 4 → Defend 4 (лише у 3-ворожому складі) |
| Ghoul | 32 | Attack 6 → Debuff: 1 Vulnerable on player → Attack 10 |
| Dark Cultist | 26 | Buff: +4 Strength to self → Attack 6 → Attack 6 |
| Wraith | 28 | Defend 10 → Attack 12 → Attack 6 |
| Bone Golem (Elite) | 92 | Attack 16 → Defend 15 → Attack 10 + 1 Weak → Buff: +3 Strength |
| Lich Lord (Boss) | 128 | Phase 1 (HP > 50%): Attack 12 → Debuff: 3 Poison on player → Defend 14 + Attack 6. Phase 2 (HP <= 50%, миттєво раз): +3 Strength, далі Attack 16 → Attack 8 x2 → Debuff: 2 Vulnerable on player |

Склад боїв: шари 1-3 — 1-2 слабких ворогів (Skeleton Warrior, Skeleton Archer, Dark Cultist); шари 4-9 — 2-3 ворога з усього пулу (3-ворожий склад один: Bone Minion + Dark Cultist + Skeleton Archer; важкі 3-ворожі зі Skeleton Warrior прибрано, див. balance-2026-10-03); Elite — Bone Golem сам; Boss — Lich Lord сам.

### 5.5 Реліквії (6)
| Relic | Effect | Ціна |
|---|---|---|
| Knight's Heart | +10 max HP | 150 |
| Energy Crystal | +1 Energy on the first turn of each combat | 150 |
| Old Shield | Start each combat with 4 Block | 150 |
| Gold Pouch | Gain 30 Gold now. +5 Gold after each combat | 150 |
| Healing Flask | Heal 6 HP after each combat | 150 |
| Demon Skull | Start each combat with 1 Strength | 150 |

### 5.6 Sanctuary: відкриття (12 карт + персонаж)
Відкрито на старті (11 карт у пулі нагород): Knight — Slash, Double Strike, Iron Skin, Quick Guard; Mage — Fireball, Frost Lance, Arcane Shield, Chain Lightning; Neutral — Punch, Dodge, Strength Potion. Starter-карти завжди доступні лише у стартових колодах.

Закрито — відкриваються за Soul Shards:
| Item | Тип | Ціна (Soul Shards) |
|---|---|---|
| Shadow Strike | Neutral, Uncommon | 40 |
| Stun Blow | Knight, Uncommon | 50 |
| Vengeance | Knight, Uncommon | 50 |
| Plague | Mage, Uncommon | 50 |
| Ancestral Spirit | Neutral, Uncommon | 50 |
| Whirlwind | Knight, Uncommon | 60 |
| Insight | Mage, Uncommon | 60 |
| Bastion | Knight, Uncommon | 70 |
| Arcane Charge | Mage, Uncommon | 70 |
| Dark Pact | Neutral, Rare | 100 |
| Titan's Wrath | Knight, Rare | 120 |
| Meteor | Mage, Rare | 120 |
| Mage (character) | Персонаж | 150 |
Сума: 840 за карти + 150 за Mage = 990.

## 6. Прогресія і економіка
- Сила в забігу росте через колоду (1 карта за бій або Skip), покращення на вогнищах (2-4 за забіг), реліквії, видалення слабких карт.
- HP не відновлюється між боями (крім реліквії Healing Flask, карти Ancestral Spirit, вогнища Rest і торговця): ключовий стримуючий ресурс. На вогнищі вибір: ~+28/+21 HP проти постійного покращення карти.
- Gold: ~5-6 Battle x 17 + 1-2 Elite x 35 + 50 старт ≈ 170-200 за забіг (ціль враховує стартові 50; заробіток без старту ≈ 120-150): вистачає на 1-2 карти або реліквію + видалення. Джерела: бої, Elite, Skip, Gold Pouch. Стоки: карти, реліквії, Remove, Heal.
- Тривалість забігу: 10 вузлів на шлях, бій ~2-3 хв, решта вузлів ~1 хв; цільово 20-30 хв.
- Soul Shards: повний забіг ≈ 50 + 15-30 + 30 = 95-110; поразка посередині ≈ 25-45. Все відкривається за ~9-12 забігів.
- Складність: один рівень; цільовий win-rate новачка 30-40% (налаштовується HP ворогів і патернами в даних).

## 7. Екрани і UI (портрет 1080x1920; усі тексти англійською)
1. Main Menu: Play, Sanctuary, Settings (Sound, Vibration).
2. Character Select: свайп між персонажами, HP/Energy, перегляд стартової колоди, кнопка «Begin».
3. Map: вертикальна, старт знизу, Boss зверху, свайп-прокрутка; верхня панель — HP, Gold, кнопка Deck. Іконки вузлів: меч (Battle), череп (Elite), мішок (Merchant), вогнище (Rest), корона (Boss).
4. Combat: вороги у верхній третині (наміри, HP-бар), гравець посередині (HP, Block, Energy), рука віялом унизу, лічильники Draw/Discard по боках, «End Turn» справа внизу.
5. Rewards: Gold, 3 карти (тап + Confirm), реліквія (після Elite), «Skip».
6. Merchant: сітка товарів із цінами, Remove a card, Heal, «Leave».
7. Rest Site: вогнище, дві кнопки «Rest (+30% HP)» і «Upgrade»; для Upgrade — вибір карти з колоди з порівнянням «було → стане»; «Leave».
8. Deck (оверлей): список карт колоди, прокрутка.
9. Pause (оверлей): Resume, Settings, Abandon Run.
10. Run Result: Victory/Defeat, Soul Shards, статистика, «Continue».
11. Sanctuary: сітка карт/персонажів, ціни, «Unlock».

Переходи: Main Menu → Character Select → Map ⇄ (Battle/Elite → Rewards | Merchant | Rest Site) → … → Boss → Run Result → Character Select / Main Menu. Sanctuary — з Main Menu і Run Result. Deck/Pause — оверлеї з Map і Combat.

## 8. Арт і звук
- Стиль: темне фентезі, плейсхолдери — прості SVG/геометричні фігури, силуети; рамки карт за типом. Палітра: фон #14161f, кістка #e8e2d0, кривавий червоний #a8322d, приглушений синій #3b5a8a, золото #c9a24b. Деталі і промпти — агент `designer`.
- Референси: Slay the Spire (UI бою), Darkest Dungeon (настрій).
- Звук (мінімум): удар, Block, розіграш карти, клік UI, вогнище, ambient (меню/бій) і трек боса; вібро на урон.

## 9. MVP
В MVP:
- 2 персонажі (Knight, Mage), 30 карт із покращеннями, 6 реліквій.
- 1 підземелля, 10 шарів, 5 звичайних ворогів, 1 Elite, 1 Boss.
- Вузли Battle, Elite, Merchant, Rest, Boss; нагороди; мета-прогресія (Soul Shards, Sanctuary).
- Тач-керування, автозбереження, 11 екранів розділу 7, англійський інтерфейс.
Потім:
- iOS, кастомні колоди з відкритих карт, вузли Event, кілька підземель, рівні складності, досягнення, локалізація, хмарне збереження, туторіал, монетизація.

## 10. Відкриті питання
Вирішено замовником: вибір колоди = персонаж із фіксованою колодою; вузол Rest додано, подій немає; мова — англійська; туторіал і монетизація відсутні; назви робочі; цільовий забіг 20-30 хв і win-rate новачка 30-40%; Android API 24+.

Залишилось:
1. Усі числа — стартові припущення, потрібен плейтест (особливо для win-rate 30-40%).
2. Шлях встановлення Godot не знайдено в PATH — уточнити перед етапом коду.
3. Чи потрібні підтримка планшетів і ландшафту в майбутньому (зараз лише телефон, портрет)?
