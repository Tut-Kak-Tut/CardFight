# T-027 Генератор звуку (SFX + музичні лупи)
Залежить від: —
Модель: sonnet

## Мета
Headless-скрипт Godot синтезує всі звуки гри у WAV (`AudioStreamWAV` + `save_to_wav`), без зовнішніх файлів. AudioManager уже вантажить `res://assets/audio/<id>.wav`.

## Файли
Створити: `tools/gen_audio.gd` (`extends SceneTree`), `assets/audio/*.wav` (результат).
Змінити: `scripts/autoload/audio_manager.gd` (лише список SFX і луп музики).

## Кроки
- [ ] 1. `gen_audio.gd`: 22050 Hz, 16-bit, mono. Генератори: sine/square/saw/noise, ADSR, pitch slide, one-pole low-pass, мікс. Фіксований seed. Нормалізація до -3 dB, без кліпінгу.
- [ ] 2. SFX (0.05–0.8 с, якщо не вказано): `hit` (шум + низький thump), `block` (металевий дзвін), `card_play` (свіст/шурхіт), `ui_click` (короткий тихий клік), `campfire` (тріск ~0.8 с), `enemy_attack` (грубіший і нижчий за hit), `heal` (висхідне арпеджіо), `gold` (2 високі дзвінкі тони), `card_draw` (тихий шурхіт), `upgrade` (висхідний блиск), `victory` (мажорне арпеджіо ~1.2 с), `defeat` (низхідний мінор ~1.5 с), `shard` (кришталевий дзвін), `poison` (булькання), `buff` (висхідний whoosh).
- [ ] 3. Музика (безшовні лупи 16–24 с, тихіше за SFX, ~-12 dB): `ambient_menu` (повільний темний пад + рідкі ноти, мінор), `ambient_combat` (пульсуючий бас + ритм ~100 BPM), `boss` (напруженіше, ~120 BPM, низькі ноти). Довжина кратна такту — луп без клацання (плавні фейди нот, нуль на краях).
- [ ] 4. Лупінг: якщо `save_to_wav` не зберігає loop — у `audio_manager.gd` при завантаженні музики для `AudioStreamWAV` став `loop_mode = LOOP_FORWARD`, `loop_begin = 0`, `loop_end = data.size() / 2`. Або через `.import` (`edit/loop_mode`). Переконайся, що петля реально працює.
- [ ] 5. Запусти: `"$GODOT" --headless --path . -s tools/gen_audio.gd`, потім `"$GODOT" --path . --import --headless`.
- [ ] 6. `audio_manager.gd`: онови const SFX під новий список. Хуки в сценах НЕ додавай (це T-029).
- [ ] 7. Сумарний розмір WAV ≤ 8 МБ (інакше скороти лупи).

## Готово, коли
У `assets/audio/` 15 SFX + 3 музичні WAV; у меню грає `ambient_menu` в петлі, кліки кнопок чути; тести проходять.

## Як перевірити
Крок 5, тести (docs/plan.md «Запуск»), запуск гри.
