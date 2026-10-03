class_name TestCase extends RefCounted

var failures: Array[String] = []

func assert_true(cond: bool, msg := "") -> void:
	if not cond:
		var error_msg = "expected true, got false"
		if msg:
			error_msg += ". " + msg
		failures.append(error_msg)

func assert_eq(a, b, msg := "") -> void:
	if a != b:
		var error_msg = "expected %s, got %s" % [b, a]
		if msg:
			error_msg += ". " + msg
		failures.append(error_msg)
