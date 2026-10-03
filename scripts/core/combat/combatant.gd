class_name Combatant extends RefCounted

var id: String = ""
var name: String = ""
var max_hp: int = 0
var hp: int = 0
var block: int = 0
var statuses: Dictionary = {}
var is_player: bool = false

# Для ворогів (заповнює T-005)
var data: Dictionary = {}
var phase_index := 0
var pattern_index := 0
var intent: Dictionary = {}

func is_dead() -> bool:
	return hp <= 0

func get_status(s: String) -> int:
	return int(statuses.get(s, 0))

func add_status(s: String, n: int) -> void:
	var v: int = get_status(s) + n
	if v <= 0:
		statuses.erase(s)
	else:
		statuses[s] = v

func add_block(n: int) -> void:
	block += n

func heal(n: int) -> int:
	var before := hp
	hp = mini(max_hp, hp + n)
	return hp - before

func take_damage(n: int) -> int:
	var absorbed := mini(block, n)
	block -= absorbed
	var lost := mini(hp, n - absorbed)
	hp -= lost
	return lost

func lose_hp(n: int) -> void:
	hp = maxi(0, hp - n)
