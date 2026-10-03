# T-003 GameData autoload + валідація даних
Залежить від: T-001, T-002
Модель: sonnet

## Мета
Синглтон `GameData` завантажує `data/*.json` і дає доступ до сутностей по id; валідатор ловить помилки в даних (щоб балансер не зламав гру опискою).

## Файли
Змінити: `scripts/autoload/game_data.gd`
Створити: `tests/test_game_data.gd`

## Кроки
- [x] 1. `game_data.gd` (`extends Node`, без `class_name` — це autoload). Поля: `cards`, `characters`, `enemies`, `relics` (Dictionary id → Dictionary), `encounters: Dictionary`, `balance: Dictionary`.
- [x] 2. `func load_all(dir := "res://data/") -> void` — читає 6 файлів через `FileAccess.get_file_as_string` + `JSON.parse_string`; масиви `cards/characters/enemies/relics` індексує по `id`. `_ready()` викликає `load_all()`. При помилці парсингу — `push_error` з іменем файлу.
- [x] 3. Числа з JSON приходять як float. Додай `func _ints(v)` рекурсивно: float без дробової частини → int (для Dictionary/Array — рекурсія). Застосуй до всіх завантажених даних, крім `vulnerable_mult`/`weak_mult` (вони стануть 1.5/0.75 і так лишаться float, бо мають дробову частину).
- [x] 4. `func get_card(id: String, upgraded := false) -> Dictionary` — повертає `duplicate(true)`; якщо `upgraded`: накласти поля з `card.upgraded` поверх, `name += "+"`, `upgraded = true`; інакше `upgraded = false`. Поле `upgraded` (Dictionary) у результаті видалити, зберегти `can_upgrade: bool` = not upgraded.
- [x] 5. `get_character(id)`, `get_enemy(id)`, `get_relic(id)` — `duplicate(true)` або `{}`.
- [x] 6. `func validate() -> Array[String]` — список помилок:
  - кожен ефект (у cards.effects, cards.upgraded.effects, enemies.phases[].pattern[].effects, phases[].on_enter, relics.hooks.*) має `op` з набору `damage, block, apply, draw, discard, energy, heal, max_hp, gold`; для `apply` — `status` з `vulnerable, weak, strength, poison, bastion, strength_per_turn`; `target` (якщо є) з `enemy, all_enemies, self, player`;
  - кожна карта має `upgraded`, `type` ∈ attack/skill/power, `rarity` ∈ starter/common/uncommon/rare, `cost` >= 0;
  - id у `characters[].deck` існують у cards; id в усіх списках `encounters` існують у enemies;
  - `intent` ворога ∈ attack, defend, buff, debuff, attack_defend, attack_debuff.
  Повідомлення — `"<file>: <id>: <що не так>"`.
- [x] 7. `tests/test_game_data.gd` (`extends TestCase`). Створюй екземпляр так: `var gd = load("res://scripts/autoload/game_data.gd").new(); gd.load_all()` (autoload у тестах недоступний). Тести:
  - `test_counts`: 30 карт, 2 персонажі, 7 ворогів, 6 реліквій;
  - `test_validate_clean`: `validate()` порожній (при невдачі — вивести помилки в msg);
  - `test_upgrade`: `get_card("strike", true)` → name `"Strike+"`, `effects[0].value == 9`, `upgraded == true`; `get_card("bastion", true).cost == 0`;
  - `test_ints`: `typeof(get_card("strike").cost) == TYPE_INT`;
  - `test_validate_catches`: підмінити `gd.cards["strike"].effects[0].op = "bogus"` → `validate()` не порожній.

## Готово, коли
Усі тести зелені.

## Як перевірити
`"$GODOT" --headless --path . -s tests/run_tests.gd; echo exit=$?` (шлях `$GODOT` — у docs/plan.md, розділ «Запуск»)
