# T-030 Safe-area і мобільні налаштування
Залежить від: T-028
Модель: sonnet

## Мета
На телефонах з вирізом/закругленнями UI не ховається під камеру і системні панелі; «Назад» не вбиває гру; фон поза safe-area — колір гри, а не чорний/сірий.

## Файли
Змінити: `scripts/autoload/scene_router.gd`, `project.godot`.

## Кроки
- [x] 1. `project.godot`: `application/config/quit_on_go_back=false` (вихід лише з Main Menu, там уже є обробка); `rendering/environment/defaults/default_clear_color` = #14161f. Перевір, що `display/window/handheld/orientation` — портрет (вже 1).
- [x] 2. `scene_router.gd`: функція `_apply_safe_area()` — бере `DisplayServer.get_display_safe_area()` і `DisplayServer.screen_get_size()`, переводить відступи (top/bottom/left/right) у координати viewport (базовий 1080x1920, stretch `canvas_items`/`expand` — враховуй `get_viewport().get_visible_rect().size`), і застосовує до кореневого Control поточної сцени як `offset_top/bottom/left/right` (корені мають anchors full rect — перевір; якщо ні, задай). На десктопі safe area = весь екран → відступи 0 (нічого не змінюється).
- [x] 3. Викликай `_apply_safe_area()` після `change_scene_to_file` (сцена з'являється наступним кадром — `await get_tree().process_frame`) і при першому запуску для стартової сцени; також на `get_viewport().size_changed`.
- [x] 4. Фони сцен, що мають розтягуватися на весь екран (TextureRect `bg_*`), мають лишитися на весь екран: якщо фон — дочірній кореня, після відступу він зсувається. Рішення: у `_apply_safe_area()` для дочірнього TextureRect з іменем, що починається на `Bg`/`bg` або першого дочірнього TextureRect на весь корінь — встанови від'ємні offsets, що компенсують відступ. Подивись, як фони названі у сценах (`grep -rn "bg_" scenes --include=*.gd`), і обери простий надійний спосіб; опиши його в коментарі.
- [x] 5. Тестовий режим: якщо в `OS.get_cmdline_user_args()` є `--fake-safe-area`, симулюй відступи top=120, bottom=80 (px viewport) — для перевірки на десктопі.

## Готово, коли
На десктопі вигляд не змінився; з `-- --fake-safe-area` усі екрани мають відступ зверху/знизу, фон усе одно на весь екран; тести проходять.

## Як перевірити
`"$GODOT" --path . -- --fake-safe-area` — меню, мапа, бій; тести (docs/plan.md «Запуск»).
