# T-022 Character Select
Залежить від: T-019, T-020, D-003
Модель: sonnet

## Мета
Вибір персонажа (= стартової колоди) перед забігом (GDD 4.9, §7 п.2).

## Файли
Створити: `scenes/character_select/character_select.tscn`, `scenes/character_select/character_select.gd`

## Кроки
- [x] 1. Сторінки персонажів з `GameData.characters` (порядок як у JSON). Перемикання: свайп вліво/вправо (поріг 120 px) + стрілки "<" ">" по боках (160x160) + крапки-індикатори.
- [x] 2. Сторінка: портрет `player_<id>.svg` (закритий → `player_<id>_locked.svg`, якщо файлу нема — портрет з modulate 0.1), ім'я (шрифт 64), "HP N  ·  Energy N" (energy з `GameData.balance`, подивись ключ), кнопка "View Deck" → `DeckOverlay` зі стартовою колодою (подивись API `scenes/ui/deck_overlay.gd`; якщо приймає лише Run — передай масив карт, додавши мінімальний метод у DeckOverlay).
- [x] 3. Нижня кнопка (640x130, y≈1650): відкритий → "Begin" → `RunState.new_run(id)` → `SceneRouter.goto("map")`. Закритий → `icon_lock.svg` + "Unlock in Sanctuary · 150" (ціна з `MetaState.meta.cost("char", id)`, іконка shard), кнопка неактивна.
- [x] 4. "Back" угорі зліва → `goto("main_menu")`; Android back — те саме.

## Готово, коли
Knight стартує забіг; Mage показаний закритим до відкриття і стартує після відкриття в Sanctuary.

## Як перевірити
`"$GODOT" --path .`; тести.
