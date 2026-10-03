# T-008 Виправлення бою після тесту етапу 1
Залежить від: T-007
Модель: sonnet
Джерело: `docs/reports/test-2026-10-03.md`

## Мета
Закрити баги 1-4 і UX-зауваження зі звіту тестера.

## Файли
Змінити: `scripts/core/combat/effect_resolver.gd`, `scripts/core/combat/combat_state.gd`, `scenes/combat/combat_screen.gd`, `scenes/ui/card_view.gd`, `scenes/ui/enemy_view.gd`, `tests/test_enemy_ai.gd`

## Кроки
- [x] 1. Фаза боса від будь-якої втрати HP: викликати `EnemyAI.check_phase` після будь-якої втрати HP ворогом — після урону і після `_tick_poison` у `combat_state.gd`. Тест у `test_enemy_ai.gd`: Lich з 72 HP і poison 3 → після його старту ходу phase_index 1, strength 3.
- [x] 2. Послідовний хід ворогів у UI: у `CombatState` додати `func end_player_turn_stepwise() -> void` — або простіше: розбити `_enemy_phase()` на `begin_enemy_phase()`, `enemy_act(i)`, `finish_enemy_phase()`; `end_player_turn()` лишається і викликає їх підряд (тести не ламаються). `combat_screen.gd` на End Turn: `begin_enemy_phase()`, далі для кожного ворога `enemy_act(i)` → `refresh()` → маленький «стрибок» EnemyView вниз на 30 px і назад (0.2 c) → пауза 0.45 c; потім `finish_enemy_phase()` і `refresh()`.
- [x] 3. Оверлей результату: Label `Victory`/`Defeat` на y 600, кнопка на y 1300 (не перекриває HP-бар). Текст кнопки: `Continue` при перемозі, `Restart` при поразці (обидві поки що перезапускають сцену).
- [x] 4. Енергія: Label `"3/3"` розмір 48, білий, обведення 8 px чорне, по центру кристала; при 0 енергії — колір #ff6b6b.
- [x] 5. Наміри з числом для всіх типів (`enemy_view.gd`): `defend` → значення block (`"10"`); `buff` → `"+3"` (сума `apply` на self); `debuff` → `"2"` (value apply на player); `attack_defend` → `"6 / 14"` ; `attack_debuff` → `"10"`. Для цього розшир `EnemyAI.preview` полями `buff: int`, `debuff: int` (0, якщо немає) і використай їх.
- [x] 6. Читабельність (`enemy_view.gd`): HP-текст 28 px, назва 26 px, HP-бар висотою 34.
- [x] 7. Карти (`card_view.gd`): прибрати порожній блок арту: опис займає y 130-325, шрифт 26, по центру по вертикалі; тип — 18 під назвою. Якщо текст > 3 рядків — шрифт 22.
- [x] 8. End Turn: непрозорий фон #a8322d, текст білий 34, рамка 3 px #e8e2d0; вимкнений стан — сірий #555.
- [x] 9. Прогнати тести і `--quit-after 300`.

## Готово, коли
Тести зелені (+1 новий), запуск без помилок.

## Як перевірити
`"$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd; "$GODOT" --path . --quit-after 300` (`$GODOT` — у docs/plan.md)
