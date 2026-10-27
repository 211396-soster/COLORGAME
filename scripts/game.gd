extends Node
## Autoload "Game": salvamento, dinheiro, qualidade gráfica e troca de cenas.

const SAVE_PATH = "user://save.json"
const SCENES = {
	"menu": "res://scenes/menu.tscn",
	"overcooked": "res://scenes/overcooked.tscn",
	"delivery": "res://scenes/delivery.tscn",
	"zombie": "res://scenes/zombie.tscn",
}

var money: int = 0
var deliveries: int = 0
var shifts: int = 0
var best_wave: int = 0
var quality: int = 1          # 0 baixa, 1 média, 2 alta; padrão adaptado ao dispositivo
var show_fps: bool = false
var last_mode: String = "delivery"

var _fps_label: Label

func _ready() -> void:
	# Média em celulares e Alta em PCs na primeira execução; respeita o valor salvo depois.
	quality = 1 if DisplayServer.is_touchscreen_available() else 2
	load_game()
	DisplayServer.screen_set_keep_on(true)
	var cl = CanvasLayer.new()
	cl.layer = 100
	add_child(cl)
	_fps_label = Label.new()
	_fps_label.position = Vector2(10, 4)
	_fps_label.add_theme_font_size_override("font_size", 18)
	_fps_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	_fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps_label.add_theme_constant_override("outline_size", 4)
	cl.add_child(_fps_label)

func _process(_d: float) -> void:
	_fps_label.visible = show_fps
	if show_fps:
		_fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

func apply_quality(vp: Viewport) -> void:
	if quality == 0:
		vp.scaling_3d_scale = 0.66
		vp.msaa_3d = Viewport.MSAA_DISABLED
	elif quality == 1:
		vp.scaling_3d_scale = 0.85
		vp.msaa_3d = Viewport.MSAA_DISABLED
	else:
		vp.scaling_3d_scale = 1.0
		vp.msaa_3d = Viewport.MSAA_2X

func shadows_on() -> bool:
	return quality >= 1

func chunk_radius() -> int:
	if quality == 0:
		return 2
	return 3

func quality_name() -> String:
	return ["Baixa", "Média", "Alta"][quality]

func add_money(n: int) -> void:
	money += n
	save_game()

func go(mode: String) -> void:
	if mode != "menu":
		last_mode = mode
	save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENES[mode])

func new_game() -> void:
	money = 0
	deliveries = 0
	shifts = 0
	best_wave = 0
	save_game()

func save_game() -> void:
	var d = {"money": money, "deliveries": deliveries, "shifts": shifts, "best_wave": best_wave,
		"quality": quality, "show_fps": show_fps, "last_mode": last_mode}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	money = int(d.get("money", 0))
	deliveries = int(d.get("deliveries", 0))
	shifts = int(d.get("shifts", 0))
	best_wave = int(d.get("best_wave", 0))
	quality = clampi(int(d.get("quality", quality)), 0, 2)
	show_fps = bool(d.get("show_fps", false))
	last_mode = str(d.get("last_mode", "delivery"))
