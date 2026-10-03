# План — CardFight

## Структура проєкту
```
project.godot              ← Godot 4.7, портрет 1080x1920, stretch canvas_items/expand
data/                      ← УСІ числа і тексти гри (JSON). Балансер правит лише тут
  balance.json             ← таблиця 5.1 GDD: енергія, рука, ціни, gold, shards, рідкості, генерація мапи
  cards.json               ← 30 карт + upgraded + unlock_cost
  characters.json          ← персонажі, HP, стартові колоди, unlock_cost
  enemies.json             ← вороги, HP, патерни намірів, фази боса
  encounters.json          ← склади боїв за шарами / elite / boss
  relics.json              ← 6 реліквій
scripts/
  autoload/                ← синглтони (Project Settings → Autoload)
    game_data.gd           ← GameData: завантажує data/*.json, дає доступ по id
    run_state.gd           ← RunState: поточний забіг (персонаж, HP, gold, колода, реліквії, мапа, позиція)
    meta_state.gd          ← MetaState: Soul Shards, відкриті карти/персонажі
    save_manager.gd        ← SaveManager: user://run.json, user://meta.json
    scene_router.gd        ← SceneRouter: переходи між екранами
  core/                    ← ЧИСТА ЛОГІКА без нод (тестується headless)
    combat/                ← combatant.gd, effect_resolver.gd, combat_state.gd, enemy_ai.gd
    map/map_generator.gd
    rewards/reward_generator.gd, shop_generator.gd
scenes/                    ← екрани (tscn + однойменний gd поруч)
  main_menu/ character_select/ map/ combat/ rewards/ merchant/ rest/ run_result/ sanctuary/
  ui/                      ← перевикористовувані: card_view, enemy_view, deck_overlay, pause_overlay
assets/
  art/placeholder/         ← SVG-плейсхолдери від designer
  art/final/               ← фінальний арт (пізніше)
  audio/
tests/
  run_tests.gd             ← власний мінімальний раннер (без аддонів)
  test_*.gd                ← тести логіки core/
docs/ brief.md gdd.md plan.md tasks/ reports/
```

### Правила
- Числа балансу — тільки в `data/*.json`. У коді — лише ключі (`GameData.balance.energy_per_turn`).
- `scripts/core/` не знає про ноди і сцени: приймає/повертає Dictionary та об'єкти core. UI лише відображає стан і викликає методи core.
- Іменування: файли `snake_case.gd/.tscn`, класи `PascalCase` (`class_name`), id в даних `snake_case` (`strike`, `skeleton_warrior`). Ігрові тексти англійською.
- Відступи в GDScript — табуляція; статична типізація де можливо.

### Схема ефектів (спільна для карт, ворогів, реліквій)
Ефект — `{"op": ..., ...}`:
| op | поля | приклад |
|---|---|---|
| `damage` | `value`, `target` (`enemy`/`all_enemies`/`player`), `times`=1, `bonus` (`half_block`) | `{"op":"damage","value":5,"target":"enemy","times":2}` |
| `block` | `value` | `{"op":"block","value":5}` |
| `apply` | `status`, `value`, `target` (`enemy`/`all_enemies`/`self`/`player`) | `{"op":"apply","status":"vulnerable","value":1,"target":"enemy"}` |
| `draw` | `value` | |
| `discard` | `value` (гравець обирає) | |
| `energy` | `value` | |
| `heal` | `value` | |
| `max_hp` | `value` (реліквії) | |
| `gold` | `value` (реліквії) | |
Статуси: `vulnerable`, `weak`, `strength`, `poison`, `bastion`, `strength_per_turn`.

## Запуск
```
GODOT="C:/Users/Vova/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
"$GODOT" --path . --import --headless          # імпорт ресурсів
"$GODOT" --headless --path . -s tests/run_tests.gd   # тести (exit code 0 = ок)
"$GODOT" --path .                               # запуск гри (вікно 540x960)
"$GODOT" -e --path .                            # редактор
```

## Етапи

### Етап 1 — Бій (вертикальний зріз)
Мета: з F5 запускається бій Knight проти 1-2 ворогів, з плейсхолдерами, повністю за правилами GDD 4.1-4.4.
- T-001 Каркас проєкту + тест-раннер (haiku)
- T-002 Дані: cards / characters / enemies / encounters / relics / balance JSON (haiku)
- D-001 Плейсхолдер-арт для бою (designer) — паралельно з T-001/T-002
- T-003 GameData autoload + тест валідації даних (sonnet) ← T-001, T-002
- T-004 Бойове ядро: колода, енергія, ефекти, статуси (sonnet) ← T-001, T-002
- T-005 Вороги: наміри, патерни, фази боса, цикл ходів, перемога/поразка (sonnet) ← T-004
- T-006 UI: CardView + EnemyView (sonnet) ← T-003, D-001
- T-007 Екран бою: рука, drag/tap, End Turn, лічильники (sonnet) ← T-005, T-006
→ tester (бій) → balancer (числа бою)

### Етап 2 — Забіг
Мапа (генератор + екран), Rewards, Merchant, Rest/Upgrade, реліквії, Elite/Boss, Run Result, RunState, Deck overlay.
→ tester → balancer (економіка, складність)

### Етап 3 — Мета і оболонка
Main Menu, Character Select, Sanctuary + MetaState, SaveManager (автозбереження), Pause/Settings, звук-заглушки.
→ tester

### Етап 4 — Арт, звук, Android
Промпти/арт від designer, інтеграція, звук, Android-експорт (API 24+), тест на телефоні, safe-area.
→ tester → фінальний баланс
