# T-019 AudioManager (заглушки) + SettingsOverlay
Залежить від: T-018
Модель: sonnet

## Мета
Єдина точка відтворення звуків і вібро з урахуванням налаштувань; оверлей налаштувань Sound/Vibration, який відкривають Main Menu і Pause.

## Файли
Створити: `scripts/autoload/audio_manager.gd`, `scenes/ui/settings_overlay.gd`, `assets/audio/README.md`
Змінити: `project.godot` (autoload `AudioManager` після MetaState)

## Кроки
- [x] 1. `audio_manager.gd` (`extends Node`):
  ```
  const SFX := ["hit", "block", "card_play", "ui_click", "campfire"]
  const MUSIC := ["ambient_menu", "ambient_combat", "boss"]
  func play(id: String) -> void        # якщо MetaState.meta.settings.sound == false → нічого
  func play_music(id: String) -> void  # той самий трек уже грає → нічого; "" → стоп
  func vibrate(ms := 40) -> void       # settings.vibration і OS.has_feature("mobile") → Input.vibrate_handheld(ms)
  ```
  Файл шукати як `res://assets/audio/<id>.ogg`, потім `.wav`; якщо немає жодного — тихо нічого (без push_error: це заглушки). 4 `AudioStreamPlayer` для SFX (round-robin) + 1 для музики. Вимкнення Sound під час музики → стоп; увімкнення → не відновлювати автоматично (наступний `play_music` запустить).
- [x] 2. Автоклік UI: у `_ready` підписатися на `get_tree().node_added`; якщо нода `BaseButton` → `pressed.connect(play.bind("ui_click"))`.
- [x] 3. `assets/audio/README.md` — список id із кроку 1 і правило «кинь `<id>.ogg` сюди — заграє».
- [x] 4. `scenes/ui/settings_overlay.gd` — `class_name SettingsOverlay extends Control`, будується кодом (стиль як `scenes/ui/deck_overlay.gd`): full-rect затемнення (0,0,0,0.7), панель по центру, заголовок "Settings", два `CheckButton` "Sound" і "Vibration" (шрифт ≥ 44, висота ≥ 110), кнопка "Back". Перемикачі → `MetaState.set_setting(...)`. `signal closed`; Back → `closed.emit()` + `queue_free()`. Статичний хелпер `static func open(parent: Node) -> SettingsOverlay` (додає себе в parent).

## Готово, коли
Гра і тести запускаються без помилок; налаштування переживають перезапуск (meta.json).

## Як перевірити
Тести (docs/plan.md «Запуск») + `"$GODOT" --path .` без помилок у консолі.
