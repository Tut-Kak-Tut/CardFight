# T-016 Екрани Merchant і Rest
Залежить від: T-012, T-013, D-002
Модель: sonnet

## Мета
Торговець (карти, реліквії, видалення карти, лікування) і вогнище (Rest або Upgrade). Правила — GDD 4.6, 4.8.

## Файли
Створити: `scenes/merchant/merchant_screen.tscn` + `.gd`, `scenes/rest/rest_screen.tscn` + `.gd`, `scenes/ui/confirm_dialog.gd`

## ConfirmDialog
- [ ] 1. `class_name ConfirmDialog extends Control` — на весь екран, затемнення 0.6, панель 800x420 по центру (#1c1f2b, рамка #c9a24b): текст (32, autowrap), кнопки `Yes` / `No` 260x100. `static func ask(parent: Node, text: String) -> ConfirmDialog`; `signal answered(yes: bool)`; після відповіді `queue_free()`.

## Merchant (`RunState.shop`: `{cards: [{id, price, sold}], relics: [{id, price, sold}], remove_price, remove_used, heal_price, heal_pct, heal_used}`)
- [ ] 2. Фон `bg_merchant.svg`. TopBar (deck_pressed → DeckOverlay).
- [ ] 3. Карти (y 600..1250): 2 ряди (3 + 2), CardView масштаб 0.8, під кожною ціна: `icon_gold.svg` 40 + число (30). Колір ціни червоний #ff6b6b, якщо `run.gold < price`. Продана — CardView прихована, на її місці `"SOLD"` (30, сірий).
- [ ] 4. Реліквії (y 1300..1480): 2 картки 480x160: іконка 96 + назва + текст (22) + ціна.
- [ ] 5. Послуги (y 1520..1640): кнопка `"Remove a card — 75"` (ціна з shop) і `"Heal +20% — 60"`. Remove: неактивна, якщо `remove_used`, не вистачає золота або `not run.can_remove()`; tap → DeckOverlay pick_mode (усі індекси) → вибрана карта → ConfirmDialog `"Remove <name> for 75 gold?"` → `run.spend`, `run.remove_card(i)`, `remove_used = true`. Heal: неактивна, якщо `heal_used` або не вистачає; → `run.spend`, `run.heal_pct(heal_pct)`, `heal_used = true`.
- [ ] 6. Купівля карти/реліквії: tap → якщо не вистачає золота — shake + вібро; інакше ConfirmDialog `"Buy <name> for N gold?"` → `run.spend(price)`, `add_card` / `add_relic`, `sold = true`, оновити TopBar і ціни.
- [ ] 7. Кнопка `"Leave"` (y 1760, 360x110) → `RunState.leave_node()`.

## Rest
- [ ] 8. Фон `bg_rest.svg`. TopBar. Заголовок `"Rest Site"` (56, y 250).
- [ ] 9. Дві великі кнопки (y 1250 і 1400, 700x120): `"Rest (+30% HP)"` (відсоток із `balance.rest_heal_pct`, у дужках фактичне `+24`) і `"Upgrade a card"`.
  - Rest: якщо `run.hp == run.max_hp` → ConfirmDialog `"HP is full. Rest anyway?"`; → `run.heal_pct(rest_heal_pct)`, зелене `"+24"` спливає, перехід у стан «done».
  - Upgrade: неактивна, якщо `run.upgradeable_indices()` порожній. Tap → DeckOverlay pick_mode з `allowed = upgradeable_indices()` → вибрана карта → панель порівняння: дві CardView (до: `GameData.get_card(id, false)`, після: `get_card(id, true)`) зі стрілкою `→` між ними + кнопки `Confirm` / `Cancel`. Confirm → `run.upgrade_card(deck_index)`, стан «done».
- [ ] 10. Стан «done»: обидві кнопки сховані, текст `"You feel rested."` або `"<name> upgraded."`, кнопка `"Leave"` (y 1700) → `RunState.leave_node()`. До дії кнопки Leave немає.

## Готово, коли
Обидва екрани компілюються; тести зелені; запуск без помилок.

## Як перевірити
`"$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd; "$GODOT" --path . --quit-after 300`
