# T-023 Sanctuary
Залежить від: T-019, T-020, D-003
Модель: sonnet

## Мета
Витрата Soul Shards на відкриття 12 карт і Mage (GDD 4.10, 5.6, §7 п.11).

## Файли
Створити: `scenes/sanctuary/sanctuary.tscn`, `scenes/sanctuary/sanctuary.gd`

## Кроки
- [x] 1. Фон `bg_sanctuary.svg`; угорі "Sanctuary" + баланс shards (`icon_shard.svg` + число, оновлювати по `MetaState.changed`); "Back" зліва → `goto("main_menu")` (Android back — те саме).
- [x] 2. Вертикальний ScrollContainer: секція "Characters" (персонажі з unlock_cost > 0) — портрет 220px + ім'я + ціна; секція "Cards" — усі карти з unlock_cost > 0, відсортовані за ціною, сітка 3 колонки з `CardView` (масштаб, щоб 3 влазили в 1080 з відступами). Під кожним — ціна (shard-іконка + число) або "Unlocked" зеленим.
- [x] 3. Стан: відкрито — без затемнення, позначка `icon_check.svg`; закрито і вистачає — ціна золотом; не вистачає — ціна червоним #a8322d, елемент modulate 0.6.
- [x] 4. Тап по закритому, на який вистачає → `confirm_dialog` "Unlock <Name> for N Soul Shards?" → `MetaState.unlock(kind, id)` → оновити екран, `AudioManager.play("card_play")`. Не вистачає → короткий текст "Not enough Soul Shards".
- [x] 5. Довге натискання на карту → збільшений перегляд (як у бою/DeckOverlay, якщо є готовий механізм; інакше пропусти).

## Готово, коли
Покупка списує shards, зберігається після перезапуску, відкрита карта з'являється в нагородах/торговця (через `card_pool()`).

## Як перевірити
`"$GODOT" --path .`; тести. Для перевірки можна тимчасово дати shards через `MetaState.meta.shards = 999` у дебаг-консолі — НЕ комітити.
