class_name CombatState extends RefCounted

signal event(kind: String, data: Dictionary)

var player: Combatant
var enemies: Array[Combatant] = []
var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []
var powers: Array[Dictionary] = []
var energy: int = 0
var max_energy: int = 0
var turn := 0
var rng := RandomNumberGenerator.new()
var balance: Dictionary = {}
var pending_discard := 0
var result := ""

func setup(p: Combatant, deck: Array, foes: Array, bal: Dictionary, seed_value: int) -> void:
	player = p
	enemies.assign(foes)
	balance = bal
	rng.seed = seed_value
	var uid := 0
	for c in deck:
		var card: Dictionary = c.duplicate(true)
		card["uid"] = uid
		uid += 1
		draw_pile.append(card)
	_shuffle(draw_pile)
	max_energy = int(bal.energy_per_turn)

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func start_player_turn() -> void:
	turn += 1
	if player.get_status("bastion") <= 0:
		player.block = 0
	_tick_poison(player)
	var spt := player.get_status("strength_per_turn")
	if spt > 0:
		player.add_status("strength", spt)
	energy = max_energy
	draw(int(balance.hand_draw))
	_check_end()

func draw(n: int) -> void:
	var drawn := 0
	for i in n:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile = discard_pile
			discard_pile = []
			_shuffle(draw_pile)
			event.emit("shuffle", {})
		var card = draw_pile.pop_back()
		if hand.size() >= int(balance.hand_max):
			discard_pile.append(card)
		else:
			hand.append(card)
			drawn += 1
	event.emit("draw", {"count": drawn})

func can_play(hand_index: int, target_index := -1) -> bool:
	if result != "" or pending_discard != 0:
		return false
	if hand_index < 0 or hand_index >= hand.size():
		return false
	var card: Dictionary = hand[hand_index]
	if int(card.cost) > energy:
		return false
	if card.get("target", "none") == "enemy":
		if target_index < 0 or target_index >= enemies.size() or enemies[target_index].is_dead():
			return false
	return true

func play_card(hand_index: int, target_index := -1) -> bool:
	if not can_play(hand_index, target_index):
		return false
	var card: Dictionary = hand[hand_index]
	energy -= int(card.cost)
	hand.remove_at(hand_index)
	var tgt: Combatant = null
	if card.get("target", "none") == "enemy":
		tgt = enemies[target_index]
	EffectResolver.resolve(card.get("effects", []), player, tgt, self)
	if card.get("type", "") == "power":
		powers.append(card)
	elif card.get("exhaust", false):
		exhaust_pile.append(card)
	else:
		discard_pile.append(card)
	event.emit("card_played", {"card": card})
	_check_end()
	return true

func choose_discard(hand_index: int) -> bool:
	if pending_discard <= 0 or hand_index < 0 or hand_index >= hand.size():
		return false
	discard_pile.append(hand[hand_index])
	hand.remove_at(hand_index)
	pending_discard -= 1
	if hand.is_empty():
		pending_discard = 0
	return true

func end_player_turn() -> void:
	if result != "":
		return
	begin_enemy_phase()
	for i in enemies.size():
		enemy_act(i)
	finish_enemy_phase()

func start_combat() -> void:
	start_player_turn()

func begin_enemy_phase() -> void:
	discard_pile.append_array(hand)
	hand.clear()
	pending_discard = 0
	_end_of_turn_statuses(player)

func enemy_act(i: int) -> void:
	var e := enemies[i]
	if e.is_dead() or result != "":
		return
	if e.get_status("bastion") <= 0:
		e.block = 0
	_tick_poison(e)
	if not e.is_dead():
		EffectResolver.resolve(e.intent.get("effects", []), e, player, self)
	_end_of_turn_statuses(e)
	EnemyAI.advance(e)
	_check_end()

func finish_enemy_phase() -> void:
	if result == "":
		start_player_turn()

func _end_of_turn_statuses(c: Combatant) -> void:
	c.add_status("vulnerable", -1)
	c.add_status("weak", -1)

func _tick_poison(c: Combatant) -> void:
	var p := c.get_status("poison")
	if p > 0:
		c.lose_hp(p)
		event.emit("damage", {"target": c, "amount": p, "blocked": 0})
		c.add_status("poison", -1)
		if c.is_dead():
			event.emit("death", {"target": c})
		elif not c.is_player and EnemyAI.check_phase(c, self):
			event.emit("phase", {"target": c})

func alive_enemies() -> Array[Combatant]:
	var res: Array[Combatant] = []
	for e in enemies:
		if not e.is_dead():
			res.append(e)
	return res

func _check_end() -> void:
	if player.is_dead():
		result = "lose"
	elif alive_enemies().is_empty():
		result = "win"
