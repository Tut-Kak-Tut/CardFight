extends Node

const SFX := ["hit", "block", "card_play", "ui_click", "campfire", "enemy_attack", "heal", "gold",
	"card_draw", "upgrade", "victory", "defeat", "shard", "poison", "buff"]
const MUSIC := ["ambient_menu", "ambient_combat", "boss"]

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _next := 0
var _music_id := ""


func _ready() -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		n.pressed.connect(play.bind("ui_click"))


func _setting(key: String) -> bool:
	var m = MetaState.meta
	if m == null:
		return true
	return bool(m.settings.get(key, true))


func _load(id: String) -> AudioStream:
	for ext in ["ogg", "wav"]:
		var path := "res://assets/audio/%s.%s" % [id, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null


func play(id: String) -> void:
	if not _setting("sound"):
		return
	var s := _load(id)
	if s == null:
		return
	var p := _sfx_players[_next]
	_next = (_next + 1) % _sfx_players.size()
	p.stream = s
	p.play()


func play_music(id: String) -> void:
	if id == "":
		_music_id = ""
		_music_player.stop()
		return
	if id == _music_id and _music_player.playing:
		return
	if not _setting("sound"):
		_music_id = ""
		_music_player.stop()
		return
	_music_id = id
	var s := _load(id)
	if s == null:
		_music_player.stop()
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	elif s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2
	_music_player.stream = s
	_music_player.play()


func vibrate(ms := 40) -> void:
	if _setting("vibration") and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func _process(_d: float) -> void:
	if _music_player.playing and not _setting("sound"):
		_music_player.stop()
		_music_id = ""
