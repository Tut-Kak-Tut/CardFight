# T-018 Meta (core) + MetaState + SaveManager
Залежить від: —
Модель: sonnet

## Мета
Постійний мета-прогрес (Soul Shards, відкриті карти/персонажі, налаштування) і збереження на диск: мета і поточний забіг.

## Файли
Створити: `scripts/core/meta/meta.gd`, `scripts/autoload/meta_state.gd`, `scripts/autoload/save_manager.gd`, `tests/test_meta.gd`
Змінити: `project.godot` (autoload)

## Кроки
- [x] 1. `scripts/core/meta/meta.gd` — `class_name Meta extends RefCounted`, без нод і без autoload (тестується headless; `data` — об'єкт GameData, як у `Run`):
  ```
  var data
  var shards := 0
  var unlocked_cards: Array[String] = []       # куплені в Sanctuary
  var unlocked_chars: Array[String] = []       # куплені персонажі
  var settings := {"sound": true, "vibration": true}
  var awarded_runs: Array[int] = []            # seed_value забігів, за які вже нараховано shards (захист від подвійного нарахування)
  func setup(p_data) -> void
  func card_pool() -> Array          # id карт: (unlock_cost == 0 і rarity != "starter") + unlocked_cards
  func is_char_unlocked(id: String) -> bool    # unlock_cost == 0 або в unlocked_chars
  func is_card_unlocked(id: String) -> bool
  func cost(kind: String, id: String) -> int   # kind "card"|"char"; unlock_cost з даних
  func can_unlock(kind: String, id: String) -> bool   # ще не відкрито і shards >= cost
  func unlock(kind: String, id: String) -> bool       # списує shards, додає в список
  func award(run_seed: int, amount: int) -> bool      # якщо seed уже в awarded_runs → false; інакше shards += amount
  func to_dict() -> Dictionary
  static func from_dict(d: Dictionary, p_data) -> Meta   # відсутні ключі → дефолти
  ```
  Логіку пулу перенести з `RunState.default_unlocked()` (сам `run_state.gd` НЕ змінювати — це T-020). Персонажі: `GameData.characters` / `get_character(id)` — подивись API в `game_data.gd`.
- [x] 2. `scripts/autoload/save_manager.gd` (`extends Node`, autoload `SaveManager`):
  ```
  var dir := "user://"                     # тести підміняють на "user://test_saves/"
  func save_json(name: String, d: Dictionary) -> void   # атомарно: пише name+".tmp", потім rename у name
  func load_json(name: String) -> Dictionary            # нема файлу / битий JSON → {}
  func delete(name: String) -> void
  func has(name: String) -> bool
  const META := "meta.json"
  const RUN := "run.json"
  ```
  Числа з JSON повертаються float — конвертацію робить `from_dict` (у `Run.from_dict` уже є `int(...)`).
- [x] 3. `scripts/autoload/meta_state.gd` (`extends Node`, autoload `MetaState`):
  ```
  signal changed
  var meta: Meta
  func _ready(): meta = Meta.from_dict(SaveManager.load_json(SaveManager.META), GameData)
  func save() -> void            # SaveManager.save_json(META, meta.to_dict()); emit changed
  func unlock(kind, id) -> bool  # meta.unlock + save
  func award(run_seed, amount) -> bool   # meta.award + save
  func set_setting(key: String, value) -> void   # + save
  ```
- [x] 4. `project.godot` [autoload] порядок: GameData, SaveManager, MetaState, RunState, SceneRouter.
- [x] 5. `tests/test_meta.gd` (стиль як `tests/test_run.gd`, `gd.free()` у кінці): пул на старті = 11 карт; unlock карти зі списаннням shards; unlock без shards → false; повторний unlock → false; Mage закритий → після unlock відкритий; award двічі з тим самим seed → нараховано один раз; to_dict→JSON.stringify→JSON.parse_string→from_dict зберігає все (числа після JSON — float!); from_dict({}) → дефолти. SaveManager у тестах не використовувати (немає autoload) — лише Meta.

## Числа/дані
Ціни — `unlock_cost` у `data/cards.json` і `data/characters.json` (Knight 0, Mage 150). Не хардкодити.

## Готово, коли
Тести проходять, гра запускається без помилок у консолі, `user://meta.json` створюється при першому `MetaState.save()`.

## Як перевірити
`"$GODOT" --path . --import --headless; "$GODOT" --headless --path . -s tests/run_tests.gd` (див. docs/plan.md «Запуск»)
