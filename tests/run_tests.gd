extends SceneTree

func _initialize() -> void:
	var passed = 0
	var failed = 0

	var dir = DirAccess.open("res://tests/")
	if dir == null:
		print("Failed to open tests directory")
		quit(1)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_case.gd":
			var path = "res://tests/" + file_name
			var test_class = load(path)
			if test_class:
				var t = test_class.new()

				# Get all methods that start with "test_"
				var methods = t.get_method_list()
				for method_dict in methods:
					var method_name = method_dict["name"]
					if method_name.begins_with("test_"):
						t.failures.clear()
						t.call(method_name)

						if t.failures.is_empty():
							print("PASS %s::%s" % [file_name, method_name])
							passed += 1
						else:
							print("FAIL %s::%s" % [file_name, method_name])
							for error in t.failures:
								print("  " + error)
							failed += 1

		file_name = dir.get_next()

	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
