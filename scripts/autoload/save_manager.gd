extends Node

const META := "meta.json"
const RUN := "run.json"

var dir := "user://"


func save_json(name: String, d: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir + name
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write " + path)
		return
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(path + ".tmp", path)


func load_json(name: String) -> Dictionary:
	if not has(name):
		return {}
	var f := FileAccess.open(dir + name, FileAccess.READ)
	if f == null:
		return {}
	var v = JSON.parse_string(f.get_as_text())
	return v if v is Dictionary else {}


func delete(name: String) -> void:
	if has(name):
		DirAccess.remove_absolute(dir + name)


func has(name: String) -> bool:
	return FileAccess.file_exists(dir + name)
