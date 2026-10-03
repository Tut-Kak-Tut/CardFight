# T-004 Бойове ядро: колода, енергія, ефекти, статуси
Залежить від: T-001, T-002 (лише формат даних; GameData НЕ використовувати)
Модель: sonnet

## Мета
Чиста логіка бою без нод: гравець грає карти, ефекти й статуси рахуються за правилами. Хід ворогів — у T-005.

## Файли
Створити: `scripts/core/combat/combatant.gd`, `scripts/core/combat/effect_resolver.gd`, `scripts/core/combat/combat_state.gd`, `tests/test_combat_core.gd`

## Формати
Карта — Dictionary як у `data/cards.json` після злиття апгрейду: `id, name, type, cost, target ("enemy"/"none"), exhaust, effects, upgraded`. Ефекти — схема з `docs/plan.md`. `balance` — Dictionary з `data/balance.json` (потрібні `energy_per_turn, hand_draw, hand_max, vulnerable_mult, weak_mult`).

## Кроки
- [x] 1. `combatant.gd` — `class_name Combatant extends RefCounted`:
  поля `id: String, name: String, max_hp: int, hp: int, block: int, statuses: Dictionary` (status → int), `is_player: bool`;
  поля для ворогів (заповнює T-005): `data: Dictionary, phase_index := 0, pattern_index := 0, intent: Dictionary = {}`;
  методи: `is_dead() -> bool` (hp <= 0), `get_status(s) -> int`, `add_status(s, n)` (видаляє ключ, якщо стало <= 0), `add_block(n)`, `heal(n) -> int` (не вище max_hp, повертає скільки), `take_damage(n) -> int` (спершу block, залишок — hp, hp не нижче 0; повертає втрату HP), `lose_hp(n)` (ігнорує block; для отрути).
- [x] 2. `combat_state.gd` — `class_name CombatState extends RefCounted`:
  - `signal event(kind: String, data: Dictionary)` — kinds: `damage {target, amount, blocked}`, `block {target, amount}`, `status {target, status, amount}`, `heal {target, amount}`, `draw {count}`, `card_played {card}`, `death {target}`, `shuffle {}`. `target` — сам Combatant.
  - поля: `player: Combatant, enemies: Array[Combatant], draw_pile, hand, discard_pile, exhaust_pile, powers` (Array[Dictionary]), `energy: int, max_energy: int, turn := 0, rng := RandomNumberGenerator.new(), balance: Dictionary, pending_discard := 0, result := ""` ("" / "win" / "lose").
  - `func setup(p: Combatant, deck: Array, foes: Array, bal: Dictionary, seed_value: int)` — кожну карту `duplicate(true)` + додати `uid` (int, послідовний); тасувати в draw_pile (`_shuffle` власний Фішер-Йейтс через `rng`, не `Array.shuffle()`), `max_energy = bal.energy_per_turn`.
  - `func start_player_turn()`: `turn += 1`; якщо немає `bastion` — `player.block = 0`; отрута гравця (`_tick_poison(player)`); `strength_per_turn` → додати стільки `strength`; `energy = max_energy`; `draw(balance.hand_draw)`; `_check_end()`.
  - `func draw(n)`: по одній; якщо draw_pile порожній — discard тасується в draw (event `shuffle`); якщо обидва порожні — стоп; якщо рука вже `hand_max` — карта йде в discard.
  - `func can_play(hand_index, target_index := -1) -> bool`: result == "", pending_discard == 0, індекс валідний, `cost <= energy`, для `target == "enemy"` — ворог з таким індексом живий.
  - `func play_card(hand_index, target_index := -1) -> bool`: якщо не can_play → false. Зняти energy, вийняти з руки, `EffectResolver.resolve(card.effects, player, target_enemy_or_null, self)`, потім карта: power → `powers`; exhaust → `exhaust_pile`; інакше → `discard_pile`. Event `card_played`. `_check_end()`. true.
  - `func choose_discard(hand_index) -> bool`: якщо pending_discard > 0 — карта з руки в discard, `pending_discard -= 1`; якщо рука порожня — pending_discard = 0.
  - `func end_player_turn()`: якщо result != "" → return; вся рука → discard; `pending_discard = 0`; `_end_of_turn_statuses(player)`; далі `_enemy_phase()` — у цій задачі порожній метод з коментарем `# T-005`.
  - `func _end_of_turn_statuses(c)`: `vulnerable` і `weak` -1.
  - `func _tick_poison(c)`: якщо poison > 0 → `c.lose_hp(poison)`, event damage, poison -1; якщо помер — event death.
  - `func alive_enemies() -> Array[Combatant]`.
  - `func _check_end()`: player dead → "lose"; усі вороги мертві → "win".
- [x] 3. `effect_resolver.gd` — `class_name EffectResolver extends RefCounted`, статичний `resolve(effects: Array, source: Combatant, target: Combatant, state: CombatState)`; для кожного ефекту:
  - цілі: `enemy` → [target]; `all_enemies` → `state.alive_enemies()`; `self` → [source]; `player` → [state.player]; без target → [source].
  - `damage`: `calc_damage(base, source, tgt, state)` = (value + strength джерела + (`floor(source.block/2)` якщо `bonus == "half_block"`)); якщо source має weak → `* weak_mult`; якщо ціль має vulnerable → `* vulnerable_mult`; `floori`, мін 0. Повторити `times` (за замовч. 1); пропускати вже мертві цілі. Event damage / death.
  - `block` → source.add_block; `apply` → add_status на цілі; `draw` → state.draw; `discard` → `state.pending_discard += value` (якщо рука не порожня); `energy` → state.energy += value; `heal` → source.heal; `max_hp`, `gold` — ігнорувати в бою (обробить RunState пізніше).
  - Зробити `calc_damage` публічним static — його використає показ намірів.
- [x] 4. `tests/test_combat_core.gd` (`extends TestCase`), дані — вбудовані Dictionary (helper `_card(id, type, cost, effects, target := "none", exhaust := false)` і `_state(deck, enemy_hp := [30])` з balance `{energy_per_turn:3, hand_draw:5, hand_max:10, vulnerable_mult:1.5, weak_mult:0.75}`, seed 1). Тести:
  - block поглинає урон (block 5, удар 8 → hp -3, block 0);
  - strength 2 + vulnerable: удар 6 → 12; weak у джерела: 6 → 4;
  - Double Strike times 2 по ворогу з 6 HP: друга атака не йде по мертвому, `death` один раз;
  - енергія: карта cost 3 при energy 2 → play_card false, рука без змін;
  - exhaust-карта йде в exhaust_pile, power — в powers, звичайна — в discard;
  - добір: колода 3 карти, discard 4 → draw(5) дає 5 у руці, сталося shuffle;
  - ліміт руки: 10 у руці, draw(1) → карта в discard;
  - poison 3 на гравці: start_player_turn → hp -3, poison 2;
  - bastion: block зберігається між ходами; без нього — 0;
  - strength_per_turn 1: після двох start_player_turn strength 2;
  - discard: Focus (draw 2, discard 1) → pending_discard 1, play_card відмовляє, choose_discard(0) → 0;
  - half_block: block 10, Vengeance 6 → урон 11;
  - `result == "win"` після смерті єдиного ворога.

## Готово, коли
Усі тести зелені (`test_smoke`, `test_game_data`, якщо вже є, теж).

## Як перевірити
`"$GODOT" --headless --path . -s tests/run_tests.gd; echo exit=$?` (`$GODOT` — у docs/plan.md)
