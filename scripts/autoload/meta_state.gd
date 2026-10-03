extends Node

signal changed

var meta: Meta


func _ready() -> void:
	meta = Meta.from_dict(SaveManager.load_json(SaveManager.META), GameData)


func save() -> void:
	SaveManager.save_json(SaveManager.META, meta.to_dict())
	changed.emit()


func unlock(kind: String, id: String) -> bool:
	var ok := meta.unlock(kind, id)
	if ok:
		save()
	return ok


func award(run_seed: int, amount: int) -> bool:
	var ok := meta.award(run_seed, amount)
	if ok:
		save()
	return ok


func set_setting(key: String, value) -> void:
	meta.settings[key] = value
	save()
