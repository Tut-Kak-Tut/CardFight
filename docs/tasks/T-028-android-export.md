# T-028 Android: оточення і збірка APK
Залежить від: —
Модель: sonnet

## Мета
Зібрати debug-APK гри з командного рядка. Зараз: Android SDK НЕМАЄ, export templates Godot НЕМАЄ, `export_presets.cfg` НЕМАЄ; є JDK 21 (`C:/Program Files/Microsoft/jdk-21.0.11.10-hotspot`). Godot 4.7.2 (шлях у docs/plan.md «Запуск»). Замовник дозволив встановлення (~1-2 ГБ).

## Файли
Створити: `export_presets.cfg`, `docs/android.md` (коротко: що куди встановлено, як зібрати, як поставити на телефон).
Змінити: `project.godot` (лише якщо потрібно для мобільного експорту, напр. ETC2/ASTC), `.gitignore` (`build/`, `*.apk`, `*.keystore`), `docs/plan.md` (рядок команди експорту в «Запуск»).
Поза репо: Android SDK у `C:/Android/Sdk`, export templates у `%APPDATA%/Godot/export_templates/4.7.2.stable/`, debug keystore `C:/Android/debug.keystore`, editor settings Godot.

## Кроки
- [ ] 1. З'ясуй вимоги Godot 4.7 до Android (JDK 17 чи 21; build-tools/platform версії). Gradle-збірку і NDK НЕ використовуємо — готовий шаблон. Якщо JDK 21 не підходить — `winget install Microsoft.OpenJDK.17`.
- [ ] 2. Android cmdline-tools з dl.google.com (commandlinetools-win-*_latest.zip) → `C:/Android/Sdk/cmdline-tools/latest`; `sdkmanager --licenses` (yes); встанови `platform-tools`, `build-tools;<версія>`, `platforms;android-<версія>`.
- [ ] 3. `Godot_v4.7.2-stable_export_templates.tpz` з GitHub releases godotengine/godot → вміст `templates/` у `%APPDATA%/Godot/export_templates/4.7.2.stable/`.
- [ ] 4. `keytool -genkeypair -v -keystore C:/Android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -validity 10000 -dname "CN=Android Debug,O=Android,C=US"`.
- [ ] 5. Editor settings (`%APPDATA%/Godot/editor_settings-4.7.tres`; якщо нема — створи запуском редактора headless з `--quit`): `export/android/android_sdk_path`, `export/android/java_sdk_path`, `export/android/debug_keystore`, `debug_keystore_user`, `debug_keystore_pass`.
- [ ] 6. `export_presets.cfg`: пресет "Android", runnable, без gradle, arm64-v8a (+ armeabi-v7a), min SDK 24, package `com.cardfight.game`, назва "CardFight", портрет, іконка з проєкту, permission VIBRATE, export_path `build/CardFight.apk`.
- [ ] 7. `"$GODOT" --headless --path . --export-debug "Android" build/CardFight.apk`. Помилки → виправ оточення/пресет. APK існує, розмір адекватний.
- [ ] 8. На телефон НЕ встановлюй; у `docs/android.md` — `adb install -r build/CardFight.apk` і варіант «скопіювати APK на телефон і відкрити (дозволити невідомі джерела)».

## Готово, коли
`build/CardFight.apk` збирається однією командою; `docs/android.md` описує процес; APK/keystore не в git.

## Як перевірити
Команда кроку 7: exit code 0, файл існує.
