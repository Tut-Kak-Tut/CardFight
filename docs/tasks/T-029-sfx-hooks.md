# T-029 Звукові хуки, вібро і кнопка «Назад» у сценах
Залежить від: T-026, T-027
Модель: sonnet

## Мета
Підключити нові SFX з T-027 до подій гри; вібро — лише через `AudioManager.vibrate()` (поважає налаштування); апаратна «Назад» (Android) не закриває гру і поводиться логічно на всіх екранах.

SFX id (є в `assets/audio/`): `hit`, `block`, `card_play`, `ui_click`, `campfire`, `enemy_attack`, `heal`, `gold`, `card_draw`, `upgrade`, `victory`, `defeat`, `shard`, `poison`, `buff`. Виклик: `AudioManager.play("id")`.

## Файли
Змінити: `scenes/combat/combat_screen.gd`, `scenes/rewards/rewards_screen.gd`, `scenes/merchant/merchant_screen.gd`, `scenes/rest/rest_screen.gd`, `scenes/run_result/run_result_screen.gd`, `scenes/sanctuary/sanctuary.gd`.

## Кроки
- [ ] 1. `combat_screen.gd` `_on_event`:
  - `damage`: якщо ціль — гравець і amount > 0 → `enemy_attack` (замість `hit`); якщо ворог → `hit`. Якщо amount == 0 і blocked > 0 → `block`.
  - `heal` → `heal`.
  - `status`: `poison` → `poison`; `strength`, `strength_per_turn`, `bastion` → `buff`; `weak`/`vulnerable` → `poison` не треба, грай `hit` тихіше не потрібно — просто `buff` лише для баффів, дебафи без звуку.
  - `draw` (count > 0) → `card_draw` (один раз на подію).
  - Кінець бою (де показується `result_overlay`): перемога → `victory`, поразка → `defeat`.
  - Рядок ~386 `Input.vibrate_handheld(40)` → `AudioManager.vibrate()`.
- [ ] 2. `rewards_screen.gd`: забрати золото → `gold`; взяти карту → `card_play`; взяти реліквію → `upgrade`.
- [ ] 3. `merchant_screen.gd`: успішна покупка (карта/реліквія) → `gold`; видалення карти → `card_play`; лікування → `heal`. Рядок ~189 `Input.vibrate_handheld(40)` → `AudioManager.vibrate()`.
- [ ] 4. `rest_screen.gd`: відпочинок (лікування) → `heal`; покращення карти → `upgrade`. `campfire` при вході лишається.
- [ ] 5. `run_result_screen.gd`: при показі — `victory` або `defeat` за результатом; якщо нараховано shards > 0 — `shard` із затримкою ~0.6 с (`get_tree().create_timer`).
- [ ] 6. `sanctuary.gd`: успішне відкриття карти/персонажа → `shard`.
- [ ] 7. «Назад» (`_notification` + `NOTIFICATION_WM_GO_BACK_REQUEST`, як у `sanctuary.gd`): `merchant` → та сама дія, що кнопка виходу/Leave; `rest`, `rewards`, `run_result` → ігнорувати (нічого не робити, щоб не пропустити вибір). Map/combat/menu/character_select/sanctuary уже мають обробку — не чіпай.
- [ ] 8. Не дублюй `ui_click`: кнопки клацають автоматично (AudioManager підписується на всі BaseButton).

## Готово, коли
Усі події з кроків звучать; вібро вимикається тумблером Settings; тести проходять; немає помилок у консолі при проходженні бою, нагород, торговця, вогнища, результату.

## Як перевірити
Тести (docs/plan.md «Запуск»), запуск гри і прохід одного бою → нагороди → торговець/вогнище.
