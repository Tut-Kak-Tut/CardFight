# T-013 RunState + SceneRouter, бій у складі забігу
Залежить від: T-009, T-010, T-011
Модель: sonnet

## Мета
Глобальний стан забігу і переходи між екранами; бій бере ворогів, колоду, HP і реліквії із забігу та повертає результат.

## Файли
Створити: `scripts/autoload/run_state.gd`, `scripts/autoload/scene_router.gd`
Змінити: `project.godot` (autoload), `scenes/combat/combat_screen.gd`

## Кроки
- [x] 1. `scene_router.gd` (`extends Node`, autoload `SceneRouter`):
  ```
  const SCENES := {"map": "res://scenes/map/map_screen.tscn", "combat": "res://scenes/combat/combat_screen.tscn",
    "rewards": "res://scenes/rewards/rewards_screen.tscn", "merchant": "res://scenes/merchant/merchant_screen.tscn",
    "rest": "res://scenes/rest/rest_screen.tscn", "run_result": "res://scenes/run_result/run_result_screen.tscn"}
  func goto(name: String) -> void
  ```
  Перехід: чорний `ColorRect` на CanvasLayer (layer 100) fade-in 0.15 c → `get_tree().change_scene_to_file` → fade-out 0.15 c. Якщо сцени немає (`ResourceLoader.exists` false) — `push_error` і нічого не робити.
- [x] 2. `run_state.gd` (`extends Node`, autoload `RunState`; порядок autoload: GameData, RunState, SceneRouter):
  ```
  var run: Run = null
  var pending: Dictionary = {}   # {"node_id", "kind": "battle"|"elite"|"boss", "enemies": [ids]}
  var reward: Dictionary = {}    # див. крок 3
  var shop: Dictionary = {}      # ShopGenerator.generate(...)
  func default_unlocked() -> Array        # id карт з unlock_cost == 0 і rarity != "starter" (етап 3 замінить на MetaState)
  func new_run(char_id := "knight", seed_value := -1) -> void   # seed -1 → randi()
  func ensure_run() -> void               # якщо run == null або run.result != "" → new_run()
  func enter_node(id: int) -> void
  func combat_won(hp_left: int) -> void
  func combat_lost() -> void
  func leave_node() -> void
  ```
  - `enter_node`: `run.move_to(id)`; за типом: battle/elite/boss → `pending = {node_id, kind: type, enemies: run.encounter_for(id)}`, `goto("combat")`; merchant → `shop = ShopGenerator.generate(GameData, run.character_id, run.unlocked, run.relics, run.removes_done, run.rng)`, `goto("merchant")`; rest → `goto("rest")`.
  - `combat_won(hp_left)`: `run.finish_combat(true, hp_left)`; якщо `run.result == "victory"` → `goto("run_result")`; інакше:
    `reward = {"kind": kind, "gold": RewardGenerator.combat_gold(kind, GameData.balance, run.rng), "gold_taken": false, "cards": RewardGenerator.card_choices(GameData, run.character_id, run.unlocked, kind, run.rng), "card_done": false, "relics": (kind == "elite" ? RewardGenerator.relic_choices(GameData, run.relics, run.rng) : []), "relic_done": kind != "elite"}`, `goto("rewards")`.
  - `combat_lost()`: `run.finish_combat(false, 0)`, `goto("run_result")`.
  - `leave_node()`: `run.mark_node_done()`, `pending = {}`, `goto("map")`.
- [x] 3. `combat_screen.gd`:
  - у `_ready`: якщо `RunState.run != null and not RunState.pending.is_empty()` → режим забігу: `character_id = run.character_id`; гравець: `max_hp = run.max_hp`, `hp = run.hp`; колода — `run.deck_cards()`; `encounter = pending.enemies`; seed — `run.rng.randi()`. Інакше — як зараз (дебаг-бій).
  - після `state.start_combat()` у режимі забігу: `EffectResolver.resolve(run.relic_effects("combat_start"), state.player, null, state)`, потім `refresh()`.
  - оверлей результату в режимі забігу: перемога → кнопка `Continue` → `RunState.combat_won(state.player.hp)`; поразка → `Continue` → `RunState.combat_lost()`. У дебаг-режимі — як зараз (reload).
  - Для боса назва оверлею `Victory` лишається, Continue веде на run_result (це робить RunState).
- [x] 4. Тест `tests/test_run_state.gd` не потрібен (autoload з переходами сцен). Перевір: імпорт, тести зелені, `--quit-after 300` (дебаг-бій як main scene) без помилок.

## Готово, коли
Компілюється, тести зелені, дебаг-бій працює як раніше.

## Як перевірити
`"$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd; "$GODOT" --path . --quit-after 300`
