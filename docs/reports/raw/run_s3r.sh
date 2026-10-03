GODOT="C:/Users/Vova/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
cd /d/MyGames/CardFight
timeout ${2:-250} "$GODOT" --path . res://docs/reports/raw/drive_s3r.tscn -- $1 > docs/reports/raw/s3r_$1.log 2>&1
echo exit $?
grep -v "^ERROR: BUG\|Unreferenced\|leaked\|PagedAllocator\|^Godot Engine\|^Vulkan\|^$" docs/reports/raw/s3r_$1.log | cut -c1-600 | head -${3:-120}
