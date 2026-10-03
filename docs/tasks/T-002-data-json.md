# T-002 Дані гри у JSON
Залежить від: —
Модель: haiku

## Мета
Перенести всі сутності й числа з GDD у JSON-файли за точною схемою нижче. Код не писати.

## Файли
Створити: `data/cards.json`, `data/characters.json`, `data/enemies.json`, `data/encounters.json`, `data/relics.json`, `data/balance.json`.
Джерела чисел: `docs/gdd.md` розділи 5.1-5.6 (читати лише їх).

## Схема ефекту
`{"op": "...", ...}`, op ∈ `damage` (`value`, `target`, опц. `times`, опц. `bonus":"half_block"`), `block` (`value`), `apply` (`status`, `value`, `target`), `draw` (`value`), `discard` (`value`), `energy` (`value`), `heal` (`value`), `max_hp` (`value`), `gold` (`value`).
target ∈ `enemy`, `all_enemies`, `self`, `player`. status ∈ `vulnerable`, `weak`, `strength`, `poison`, `bastion`, `strength_per_turn`.

## Кроки
- [x] 1. `data/cards.json` — `{"cards": [ ... ]}`, рівно 30 карт з GDD 5.3. Поля кожної:
  ```json
  {"id":"strike","name":"Strike","class":"knight","type":"attack","rarity":"starter","cost":1,
   "target":"enemy","exhaust":false,"text":"Deal 6 damage.",
   "effects":[{"op":"damage","value":6,"target":"enemy"}],
   "upgraded":{"text":"Deal 9 damage.","effects":[{"op":"damage","value":9,"target":"enemy"}]},
   "unlock_cost":0}
  ```
  - `id` = назва в snake_case без апострофів (`titans_wrath`, `strength_potion`). `class` ∈ knight/mage/neutral. `type` ∈ attack/skill/power. `rarity` ∈ starter/common/uncommon/rare.
  - `target`: `"enemy"`, якщо карта б'є/накладає статус на ОДНОГО ворога, інакше `"none"`.
  - `exhaust`: true, якщо в описі є "Exhaust". У `upgraded` пиши лише змінені поля (`cost` / `text` / `effects`); для "Cost 0" → `{"cost":0}`.
  - `text` — опис з колонки Effect, закінчити крапкою.
  - Особливі мапінги: Double Strike → `{"op":"damage","value":5,"target":"enemy","times":2}`; Vengeance → `{"op":"damage","value":6,"target":"enemy","bonus":"half_block"}`; Battle Cry / Strength Potion → `apply strength target self`; Bastion → `apply bastion value 1 target self`; Arcane Charge → `apply strength_per_turn value 1 target self`; Poison Cloud/Plague → `apply poison target enemy`; Focus → `draw 2`, потім `discard 1`; Dark Pact → `energy 1`, `draw 2`; Ancestral Spirit → `heal 6`; Whirlwind/Chain Lightning/Meteor → target `all_enemies`; Punch → damage 5 + block 2.
  - `unlock_cost`: з таблиці 5.6 для закритих карт, інакше 0.
- [x] 2. `data/characters.json` — `{"characters":[...]}`:
  `{"id":"knight","name":"Knight","max_hp":80,"energy":3,"description":"Heavy armor and crushing blows.","deck":["strike","strike","strike","strike","strike","defend","defend","defend","defend","battle_cry"],"unlock_cost":0}`; Mage: 60 HP, `"description":"Fire, poison and arcane tricks."`, колода 4 spark, 4 barrier, poison_cloud, focus, `unlock_cost":150`.
- [x] 3. `data/enemies.json` — `{"enemies":[...]}`, 7 ворогів з GDD 5.4:
  ```json
  {"id":"skeleton_warrior","name":"Skeleton Warrior","max_hp":24,"tier":"normal",
   "phases":[{"pattern":[
     {"intent":"attack","effects":[{"op":"damage","value":7,"target":"player"}]},
     {"intent":"attack","effects":[{"op":"damage","value":7,"target":"player"}]},
     {"intent":"defend","effects":[{"op":"block","value":8}]}]}]}
  ```
  - `tier` ∈ normal/elite/boss. `intent` ∈ attack, defend, buff, debuff, attack_defend, attack_debuff.
  - Buff +N Strength → `apply strength N target self`; Debuff на гравця → `apply <status> N target player`.
  - Bone Golem «Attack 10 + 1 Weak» → intent `attack_debuff`, два ефекти.
  - Lich Lord: дві фази. Фаза 1 `{"pattern":[Attack 12, Debuff poison 4 player, attack_defend (block 14 + damage 6)]}`. Фаза 2 `{"hp_threshold_pct":50,"on_enter":[{"op":"apply","status":"strength","value":3,"target":"self"}],"pattern":[Attack 16, Attack 8 з "times":2, Debuff vulnerable 2 player]}`.
- [x] 4. `data/encounters.json`:
  ```json
  {"early_max_layer":3,
   "normal_early":[["skeleton_warrior"],["skeleton_archer"],["dark_cultist"],["skeleton_warrior","skeleton_archer"],["dark_cultist","skeleton_archer"]],
   "normal_late":[["ghoul","skeleton_archer"],["wraith","dark_cultist"],["skeleton_warrior","skeleton_warrior","skeleton_archer"],["ghoul","dark_cultist"],["wraith","skeleton_archer"],["ghoul","wraith"],["skeleton_warrior","dark_cultist","skeleton_archer"]],
   "elite":[["bone_golem"],["bone_golem","skeleton_archer"]],
   "boss":[["lich_lord"]]}
  ```
- [x] 5. `data/relics.json` — `{"relics":[...]}`, 6 реліквій з 5.5:
  `{"id":"gold_pouch","name":"Gold Pouch","text":"Gain 30 Gold now. +5 Gold after each combat.","hooks":{"on_pickup":[{"op":"gold","value":30}],"combat_end":[{"op":"gold","value":5}]}}`.
  Хуки: Knight's Heart → on_pickup max_hp 10; Energy Crystal → combat_start energy 1; Old Shield → combat_start block 4; Healing Flask → combat_end heal 6; Demon Skull → combat_start apply strength 1 self.
- [x] 6. `data/balance.json` — рівно:
  ```json
  {"energy_per_turn":3,"hand_draw":5,"hand_max":10,"deck_min":5,
   "vulnerable_mult":1.5,"weak_mult":0.75,
   "start_gold":50,"skip_reward_gold":10,"gold_battle":[10,20],"gold_elite":[25,35],
   "reward_card_choices":3,
   "rarity_weights":{"normal":{"common":65,"uncommon":30,"rare":5},"elite":{"common":45,"uncommon":40,"rare":15}},
   "shop":{"cards":{"common":2,"uncommon":2,"rare":1},"relics":2,
     "card_price":{"common":50,"uncommon":80,"rare":140},"card_price_jitter":{"common":10,"uncommon":10,"rare":15},
     "relic_price":150,"remove_price":75,"remove_price_step":25,"heal_pct":20,"heal_price":60},
   "rest_heal_pct":30,
   "shards":{"per_layer":5,"elite":15,"boss":30},
   "map":{"layers":10,"min_nodes":2,"max_nodes":3,"first_layer_nodes":2,
     "weights":{"battle":50,"rest":18,"merchant":15,"elite":12},
     "elite_layers":[4,9],"elite_count":[1,2],"merchant_min":2,"merchant_required_layer":8,
     "rest_layers":[3,9],"rest_count":[3,4],"rest_required_layer":9}}
  ```
- [x] 7. Перевірити, що всі файли — валідний JSON.

## Готово, коли
6 валідних JSON, 30 карт (12 knight, 12 mage, 6 neutral), кожна має `upgraded`; 7 ворогів; 6 реліквій.

## Як перевірити
`for f in data/*.json; do python -c "import json,sys;json.load(open('$f',encoding='utf-8'))" && echo "$f ok"; done`
`python -c "import json;c=json.load(open('data/cards.json'))['cards'];print(len(c),all('upgraded' in x for x in c))"` → `30 True`
