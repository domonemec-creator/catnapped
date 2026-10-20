extends Node

# Autoload „Sfx“: krátké zvuky efektů a smyčka hudby. Zvuky jsou CC0 (Kenney), hudba CC0 (RandomMind),
# viz assets/audio/LICENSES_SOURCE.md. Headless běh (verifiery) nic nepřehrává.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_TRACKS: Array[String] = [
	"res://assets/audio/music/loop_the_old_tower_inn.ogg",
	"res://assets/audio/music/loop_the_bards_tale.ogg",
]
# Logické jméno -> varianty souborů (náhodný výběr, ať se zvuk neopakuje stejně).
const SOUNDS := {
	&"card_place": ["card_place_1", "card_place_2"],
	&"card_draw": ["card_draw_1", "card_draw_2"],
	&"card_select": ["card_select"],
	&"shuffle": ["card_shuffle"],
	&"tuna": ["tuna"],
	&"attack": ["attack_swish"],
	&"hit": ["hit_1", "hit_2"],
	&"hit_heavy": ["hit_heavy"],
	&"guard": ["guard_block"],
	&"direct_hit": ["direct_hit"],
	&"ko": ["ko"],
	&"ui_click": ["ui_click"],
	&"ui_hover": ["ui_hover"],
	&"end_turn": ["end_turn"],
	&"victory": ["victory"],
	&"defeat": ["defeat"],
}
const PLAYER_POOL_SIZE := 8

var sfx_volume_db: float = -4.0
var music_volume_db: float = -16.0
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music_player: AudioStreamPlayer
var _stream_cache: Dictionary = {}
var _enabled := true


func _ready() -> void:
	_enabled = DisplayServer.get_name() != "headless"
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(PLAYER_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	if _enabled:
		# Každé tlačítko ve hře cvakne, bez nutnosti zapojovat zvuk v jednotlivých scénách.
		get_tree().node_added.connect(_on_node_added)
		play_music.call_deferred()


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		if not button.pressed.is_connected(_on_any_button_pressed):
			button.pressed.connect(_on_any_button_pressed)


func _on_any_button_pressed() -> void:
	play(&"ui_click", 0.04, -3.0)


func play(sound_id: StringName, pitch_jitter: float = 0.06, volume_offset_db: float = 0.0) -> void:
	if not _enabled or not SOUNDS.has(sound_id):
		return
	var variants: Array = SOUNDS[sound_id]
	var stream := _load_stream(SFX_DIR + str(variants[randi() % variants.size()]) + ".ogg")
	if stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.volume_db = sfx_volume_db + volume_offset_db
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()


# Spustí hudbu (pokud už nehraje). track_index -1 = náhodná skladba.
func play_music(track_index: int = -1) -> void:
	if not _enabled or MUSIC_TRACKS.is_empty():
		return
	if _music_player.playing:
		return
	var index := track_index if track_index >= 0 else randi() % MUSIC_TRACKS.size()
	var stream := _load_stream(MUSIC_TRACKS[index % MUSIC_TRACKS.size()])
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music_player.stream = stream
	_music_player.volume_db = music_volume_db
	_music_player.play()


func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()


func _load_stream(path: String) -> AudioStream:
	if not _stream_cache.has(path):
		_stream_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _stream_cache[path]
