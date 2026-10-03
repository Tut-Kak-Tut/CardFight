# Android

## Оточення (поза репо)
- JDK 21: `C:/Program Files/Microsoft/jdk-21.0.11.10-hotspot`
- Android SDK: `C:/Android/Sdk` (cmdline-tools/latest, platform-tools, build-tools 35.0.1, platforms android-35)
- Export templates 4.7.2: `%APPDATA%/Godot/export_templates/4.7.2.stable/`
- Debug keystore: `C:/Android/debug.keystore` (alias `androiddebugkey`, pass `android`)
- Шляхи прописані в `%APPDATA%/Godot/editor_settings-4.7.tres` (`export/android/*`).
- Gradle/NDK не використовуються (готовий шаблон); пресет — `export_presets.cfg` ("Android", arm64-v8a + armeabi-v7a, `com.cardfight.game`).

## Збірка
```
GODOT="C:/Users/Vova/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
mkdir -p build
"$GODOT" --headless --path . --export-debug "Android" build/CardFight.apk
```
Результат: `build/CardFight.apk` (~65 МБ, не в git).

## Встановлення на телефон
- USB-налагодження: `C:/Android/Sdk/platform-tools/adb.exe install -r build/CardFight.apk`
- Або скопіювати APK на телефон, відкрити файл і дозволити встановлення з невідомих джерел.
