# T-010 Run — стан забігу
Залежить від: T-009 (лише виклик `MapGenerator.generate`; якщо файлу ще немає — він з'явиться паралельно, сигнатуру див. нижче)
Модель: sonnet

## Мета
Чиста логіка забігу без нод: персонаж, HP, золото, колода, реліквії, мапа, пересування, підрахунок Soul Shards. Цей API використовують усі екрани етапу 2 — сигнатури НЕ змінювати.

## Файли
Створити: `scripts/core/run/run.gd`, `tests/test_run.gd`

## API (точно так)
`class_name Run extends RefCounted`
```
var data                         # GameData-подібний об'єкт: get_card(id, upgraded), get_character(id), get_relic(id), balance, encounters, relics
var character_id: String
var max_hp: int
var hp: int
var gold: int
var deck: Array = []             # [{"id": String, "upgraded": bool}]
var relics: Array[String] = []
var unlocked: Array = []         # id карт, доступних у нагородах/торговця
var map: Dictionary = {}         # формат MapGenerator: {"nodes": [...], "layers": [[...]]}
var current_node := -1           # -1 = ще не зайшли на шар 1
var visited: Array[int] = []
var removes_done := 0
var result := ""                 # "" | "victory" | "defeat"
var stats := {"layers": 0, "battles": 0, "elites": 0, "boss": false}
var rng := RandomNumberGenerator.new()
var seed_value := 0

func start(p_data, char_id: String, p_unlocked: Array, p_seed: int) -> void
func deck_cards() -> Array                 # data.get_card(id, upgraded) для кожного; у кожну додати "deck_index": int
func add_card(id: String) -> void
func can_remove() -> bool                  # deck.size() > balance.deck_min
func remove_card(index: int) -> bool       # removes_done += 1
func upgradeable_indices() -> Array[int]   # карти з upgraded == false
func upgrade_card(index: int) -> bool
func add_relic(id: String) -> void         # on_pickup: max_hp (+max_hp і +hp), gold
func relic_effects(hook: String) -> Array  # усі ефекти з relics[*].hooks[hook] підряд
func heal(n: int) -> int                   # не вище max_hp, повертає скільки
func heal_pct(pct: int) -> int             # floori(max_hp * pct / 100.0)
func spend(amount: int) -> bool            # false, якщо не вистачає
func node(id: int) -> Dictionary
func available_nodes() -> Array[int]       # -1 → layers[0]; інакше node(current_node).next; [] якщо result != ""
func move_to(id: int) -> bool              # лише з available_nodes; current_node = id; visited.append(id)
func encounter_for(id: int) -> Array       # список id ворогів (див. крок 4)
func finish_combat(won: bool, hp_left: int) -> void
func mark_node_done() -> void              # stats.layers += 1
func soul_shards() -> int
func to_dict() -> Dictionary
static func from_dict(d: Dictionary, p_data) -> Run
```

## Кроки
- [x] 1. `start`: персонаж з `data.get_character`; `max_hp = hp = character.max_hp`; `gold = balance.start_gold`; колода з `character.deck` (upgraded false); `rng.seed = p_seed`; `map = MapGenerator.generate(data.balance.map, rng)`.
- [x] 2. Колода/реліквії/золото/HP — як у API. `add_relic` ігнорує дублікат.
- [x] 3. `finish_combat(won, hp_left)`: `hp = clamp(hp_left, 0, max_hp)`. Якщо не won → `result = "defeat"`. Якщо won: тип поточного вузла: battle → stats.battles += 1; elite → stats.elites += 1; boss → stats.boss = true, stats.layers += 1, `result = "victory"`. Далі ефекти `relic_effects("combat_end")`: `heal` → heal(value), `gold` → gold += value.
- [x] 4. `encounter_for(id)`: тип вузла → ключ: battle і (layer+1) <= `encounters.early_max_layer` → `normal_early`; battle інакше → `normal_late`; elite → `elite`; boss → `boss`. Випадковий елемент через `rng`, повернути копію.
- [x] 5. `soul_shards()` = `stats.layers * shards.per_layer + stats.elites * shards.elite + (shards.boss якщо stats.boss)`.
- [x] 6. `to_dict/from_dict`: усі поля вище + `rng.state`; `from_dict` відновлює стан повністю (для збереження на етапі 3).
- [x] 7. `tests/test_run.gd` (`gd = load("res://scripts/autoload/game_data.gd").new(); gd.load_all()`, наприкінці кожного тесту `gd.free()`):
  - start knight: hp 80 (з даних), gold = start_gold, 10 карт, мапа має 10 шарів;
  - available_nodes на старті = layers[0]; move_to недоступного → false; move_to доступного → true і далі available = його next;
  - upgrade_card → deck_cards()[i].name закінчується на "+", повторний upgrade → false; upgradeable_indices не містить його;
  - remove_card до deck_min: після цього can_remove false; removes_done рахується;
  - add_relic knights_heart → max_hp і hp +10 (числа з даних); gold_pouch → gold +30; finish_combat(true, …) з gold_pouch → +5 gold; healing_flask → heal 6, не вище max;
  - finish_combat(false, 0) → result "defeat";
  - soul_shards: stats {layers 5, elites 1, boss false} → 5*5+15 = за даними;
  - encounter_for: вузол шару 1 → склад із normal_early; boss → ["lich_lord"];
  - to_dict → from_dict → однакові hp/gold/deck/relics/map/current_node.

## Готово, коли
Тести зелені.

## Як перевірити
`"$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd`
