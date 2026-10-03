# T-012 UI-компоненти забігу: DeckOverlay, RelicBar, TopBar
Залежить від: T-006 (CardView). Арт D-002 може ще малюватись — для відсутніх іконок fallback (сірий квадрат + перша літера).
Модель: sonnet

## Мета
Перевикористовувані компоненти для мапи, торговця, вогнища, нагород.

## Файли
Створити: `scenes/ui/deck_overlay.gd` + `.tscn`, `scenes/ui/relic_bar.gd`, `scenes/ui/top_bar.gd` + `.tscn`
Правило як у T-006: `.tscn` мінімальні, вузли — в коді.

## Кроки
- [x] 1. `deck_overlay.gd` — `class_name DeckOverlay extends Control`, на весь екран (anchors full rect), `mouse_filter STOP`, фон `Color(0,0,0,0.85)`.
  - `signal picked(card: Dictionary)`, `signal closed`.
  - `func open(cards: Array, title: String, pick_mode := false, allowed: Array = [])`: заголовок (40 px, зверху y 60); `ScrollContainer` (y 140..1700) з `GridContainer` 3 колонки, CardView масштаб 0.95 (обгортка Control 240x340 з відступами 20); якщо `pick_mode` — картки, `deck_index` яких не в `allowed`, сірі (`set_playable(false)`) і не клікаються; tap по дозволеній → `picked.emit(card)` і `hide()`. Кнопка «Close» 300x110 унизу по центру (y 1760) → `closed.emit()`, `hide()`.
  - Скрол пальцем: tap по картці не має спрацьовувати, якщо палець зсунувся > 20 px (CardView вже розрізняє tap і drag; drag просто ігноруй).
- [x] 2. `relic_bar.gd` — `class_name RelicBar extends HBoxContainer`, separation 8.
  - `func set_relics(ids: Array, data)`: для кожного — `TextureRect` 64x64 з `res://assets/art/placeholder/relic_<id>.svg` (якщо файлу немає — `ColorRect` #555 64x64 з літерою).
  - tap по іконці → спливаюча панель (PanelContainer, темна, рамка #c9a24b) під іконкою: назва (26, золото) + текст (22), зникає через 2.5 c або при наступному tap.
- [x] 3. `top_bar.gd` — `class_name TopBar extends Control`, ширина 1080, висота 120, фон `#0d0f15` з нижньою лінією #c9a24b 2 px.
  - Зліва: `icon_hp.svg` 56 + Label `"62/80"` (34); далі `icon_gold.svg` 56 + Label золота (34, #c9a24b); RelicBar; праворуч кнопка «Deck» 160x90 з числом карт (`"Deck 12"`).
  - `signal deck_pressed`.
  - `func refresh(run)` — бере `run.hp, run.max_hp, run.gold, run.relics, run.deck.size()` і `run.data` для RelicBar.
- [x] 4. Імпорт без помилок, наявні тести зелені, `--check-only` для трьох скриптів.

## Готово, коли
Компоненти компілюються без помилок; тести зелені.

## Як перевірити
`"$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd`
