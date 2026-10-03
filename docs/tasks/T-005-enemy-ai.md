# T-005 Вороги: наміри, патерни, фази, цикл ходів
Залежить від: T-004
Модель: sonnet

## Мета
Вороги виконують циклічні патерни з `data/enemies.json`, показують намір з правильним числом, бос перемикає фазу; повний цикл «хід гравця → хід ворогів → новий хід».

## Файли
Створити: `scripts/core/combat/enemy_ai.gd`, `tests/test_enemy_ai.gd`
Змінити: `scripts/core/combat/combat_state.gd`

## Формат ворога
`{"id","name","max_hp","tier","phases":[{"pattern":[{"intent","effects":[...]}]}, {"hp_threshold_pct":50,"on_enter":[...],"pattern":[...]}]}`.

## Кроки
- [ ] 1. `enemy_ai.gd` — `class_name EnemyAI extends RefCounted`, статичні методи:
  - `create(data: Dictionary) -> Combatant` — id, name, max_hp, hp = max_hp, `data = data.duplicate(true)`, is_player false, intent = поточний крок.
  - `current_step(e) -> Dictionary` — `e.data.phases[e.phase_index].pattern[e.pattern_index]`.
  - `advance(e)` — `pattern_index = (pattern_index + 1) % pattern.size()`; оновити `e.intent = current_step(e)`.
  - `check_phase(e, state) -> bool` — якщо є наступна фаза з `hp_threshold_pct` і `e.hp * 100 <= e.max_hp * pct` і ворог живий → `phase_index += 1`, `pattern_index = 0`, `EffectResolver.resolve(on_enter, e, e, state)`, оновити intent, повернути true. Перевіряти циклом (на випадок кількох порогів).
  - `preview(e, state) -> Dictionary` — для UI: `{"intent": e.intent.intent, "damage": int (EffectResolver.calc_damage для першого damage-ефекту на state.player, -1 якщо немає), "times": int, "block": int (сума block-ефектів, 0 якщо немає)}`.
- [ ] 2. `combat_state.gd`:
  - `setup` приймає `foes` як Array[Combatant] (вже створені через EnemyAI.create) — без змін, якщо так і було.
  - Підписатись усередині стану: після кожного `damage`-ефекту по ворогу викликати `EnemyAI.check_phase` — найпростіше: у `EffectResolver` після урону по не-гравцю `if not tgt.is_player: EnemyAI.check_phase(tgt, state)`; при перемиканні — event `phase {target}`.
  - Реалізувати `_enemy_phase()`: для кожного ворога зліва направо, якщо живий і result == "": `block = 0` (якщо немає bastion), `_tick_poison(e)`; якщо живий — `EffectResolver.resolve(e.intent.effects, e, state.player, self)`; `_end_of_turn_statuses(e)`; `EnemyAI.advance(e)`; `_check_end()`. Після всіх, якщо result == "" → `start_player_turn()`.
  - `func start_combat()` — перший `start_player_turn()` (намірів вже виставлено в create).
- [ ] 3. `tests/test_enemy_ai.gd` — дані ворогів брати з `data/enemies.json` через `load("res://scripts/autoload/game_data.gd").new()` + `load_all()` + `get_enemy(id)`; balance — `gd.balance`; колода гравця — 10 Dictionary-карт `Defend` (block 5) або вбудовані. Тести:
  - патерн Skeleton Warrior: intent attack, attack, defend, attack (4 виклики advance дають цикл);
  - хід ворога: гравець без блоку, end_player_turn → hp гравця -7, новий хід (turn 2, energy 3, 5 карт у руці);
  - блок гравця гасить урон: зіграти Defend (5) → після ходу ворога hp -2;
  - preview з strength: Dark Cultist після свого першого ходу (+3 strength) → preview damage 8; якщо гравець vulnerable → 12;
  - weak на ворогу зменшує його удар (7 → 5);
  - Lich Lord: нанести урон до 70 HP → phase_index 1, strength 3, intent = перший крок фази 2; preview damage 19;
  - Lich phase-2 «Attack 8 x2» з strength 3 → гравець втрачає 22 (без блоку);
  - отрута вбиває ворога на початку його ходу → він не атакує, `result == "win"`, якщо був один;
  - поразка: гравець з 5 HP, удар 7 → `result == "lose"`, новий хід не починається.

## Готово, коли
Усі тести зелені.

## Як перевірити
`"$GODOT" --headless --path . -s tests/run_tests.gd; echo exit=$?`
