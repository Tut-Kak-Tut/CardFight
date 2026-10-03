# T-031 Art: підтримка фінальних SVG
Залежить від: T-026
Модель: haiku

## Мета
Фінальний арт тепер малює designer як детальні SVG у `assets/art/final/`. `Art` має брати: final PNG → final SVG → placeholder SVG.

## Файли
Змінити: `scripts/core/art.gd`, `tests/test_art.gd`.

## Кроки
- [x] 1. `art.gd` `_resolve`: у загальній гілці між `FINAL + name + ".png"` і `PLACEHOLDER + name + ".svg"` додай перевірку `FINAL + name + ".svg"`. У гілці `_locked` порядок: final `<name>.png`, final `<name>.svg`, final `<base>.png`, final `<base>.svg`, placeholder `<name>.svg`, placeholder `<base>.svg`.
- [x] 2. `is_final` / `needs_silhouette` мають працювати й для final SVG (вони спираються на префікс `FINAL` — перевір; для `_locked` силует потрібен, коли взято final-текстуру base, а не locked).
- [x] 3. `tests/test_art.gd`: тест `bg_combat` не повинен вимагати `.svg` саме з placeholder — перевіряй, що шлях не порожній і закінчується на `.svg` або `.png`. Додай тест: `Art.path("player_mage_locked") != ""`.

## Готово, коли
Тести проходять (docs/plan.md «Запуск»).
