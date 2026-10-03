# T-026 Art-лоадер: final PNG з фолбеком на SVG-плейсхолдер
Залежить від: —
Модель: sonnet

## Мета
Уся гра бере текстури через одну функцію: якщо є `res://assets/art/final/<name>.png` — її, інакше `res://assets/art/placeholder/<name>.svg`. Замовник просто кладе PNG у `final/` — і арт з'являється.

## Файли
Створити: `scripts/core/art.gd` (`class_name Art`, лише static; `ResourceLoader` дозволено), `tests/test_art.gd`.
Змінити (прибрати хардкод `res://assets/art/placeholder/`): `scenes/character_select/character_select.gd`, `scenes/combat/combat_screen.gd`, `scenes/main_menu/main_menu.gd`, `scenes/map/map_screen.gd`, `scenes/merchant/merchant_screen.gd`, `scenes/rest/rest_screen.gd`, `scenes/rewards/rewards_screen.gd`, `scenes/run_result/run_result_screen.gd`, `scenes/sanctuary/sanctuary.gd`, `scenes/ui/card_view.gd`, `scenes/ui/enemy_view.gd`, `scenes/ui/pause_overlay.gd`, `scenes/ui/relic_bar.gd`, `scenes/ui/status_row.gd`, `scenes/ui/top_bar.gd`, `tests/run_tests.gd`. Перевір і `.tscn` (`grep -rn "art/placeholder" scenes`).

## Кроки
- [ ] 1. `art.gd`: `static func path(name: String) -> String` (final png → placeholder svg → ""), `static func tex(name: String) -> Texture2D` (null, якщо нема), кеш у static Dictionary.
- [ ] 2. `player_mage_locked`: final `player_mage_locked.png` → інакше final `player_mage.png` (тоді UI робить силует `modulate = Color(0,0,0,0.85)` — додай `static func is_final(name) -> bool` і використай у character_select/sanctuary) → інакше placeholder `player_mage_locked.svg`.
- [ ] 3. У всіх файлах заміни `load(ART + "x.svg")` / `"res://assets/art/placeholder/%s.svg" % id` на `Art.tex("x")`. Прибери непотрібні константи `ART`/`ICON`.
- [ ] 4. PNG можуть бути іншого розміру, ніж SVG. TextureRect-и фонів: `expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_COVERED`. Персонажі/вороги/рамки/лого: `EXPAND_IGNORE_SIZE` + `STRETCH_KEEP_ASPECT_CENTERED` з фіксованим розміром, який зараз займає SVG (PNG 1024 не має роздувати верстку). Sprite2D (якщо є) — масштаб під цільовий розмір.
- [ ] 5. `tests/test_art.gd` (підключи в `run_tests.gd` за зразком): `Art.path("bg_combat")` закінчується на `.svg` (final нема); `Art.path("nonexistent") == ""`.
- [ ] 6. Ручна перевірка: тимчасово згенеруй PNG у `assets/art/final/bg_menu.png` (headless-скрипт `Image.create(...)` + `save_png`, потім `--import`), переконайся, що `Art.path("bg_menu")` її бере і меню показує її на весь екран. Потім ВИДАЛИ тимчасовий PNG і його `.import`.

## Готово, коли
`grep -rn "art/placeholder" scenes scripts` знаходить лише `scripts/core/art.gd`; гра виглядає як раніше; тести проходять.

## Як перевірити
Тести (docs/plan.md «Запуск»), запуск гри — меню, мапа, бій, святилище без порожніх текстур.
