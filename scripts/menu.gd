extends Control
## Menu principal: fachada real da Color Tintas ao fundo, modos, opções e créditos.

var main_box: VBoxContainer
var modes_box: VBoxContainer
var opts_box: VBoxContainer
var cred_box: VBoxContainer
var lbl_stats: Label
var btn_quality: Button
var btn_fps: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Game.apply_quality(get_viewport())
	var bg = TextureRect.new()
	bg.texture = load("res://tex/storefront.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var dim = ColorRect.new()
	dim.color = Color(0.0, 0.04, 0.14, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var logo = TextureRect.new()
	logo.texture = load("res://tex/logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(440, 129)
	add_child(logo)
	UIKit.place(logo, 0.0, 0.0, 40, 28, 1, 1)
	var sub = UIKit.label("Entregas em Passo Fundo - RS", 24, UIKit.YELLOW)
	add_child(sub)
	UIKit.place(sub, 0.0, 0.0, 44, 168, 1, 1)
	lbl_stats = UIKit.label("", 22)
	add_child(lbl_stats)
	UIKit.place(lbl_stats, 1.0, 0.0, -24, 20, 0, 1)
	main_box = _column(0.0, 0.34)
	modes_box = _column(0.0, 0.34)
	opts_box = _column(0.0, 0.34)
	cred_box = _column(0.0, 0.2)
	# principal
	var b = UIKit.button("CONTINUAR")
	b.pressed.connect(func(): Game.go(Game.last_mode))
	main_box.add_child(b)
	b = UIKit.button("NOVO JOGO")
	b.pressed.connect(func():
		Game.new_game()
		Game.go("delivery"))
	main_box.add_child(b)
	b = UIKit.button("MODOS")
	b.pressed.connect(func(): _show(modes_box))
	main_box.add_child(b)
	b = UIKit.button("OPÇÕES")
	b.pressed.connect(func(): _show(opts_box))
	main_box.add_child(b)
	b = UIKit.button("CRÉDITOS")
	b.pressed.connect(func(): _show(cred_box))
	main_box.add_child(b)
	b = UIKit.button("SAIR")
	b.pressed.connect(func(): get_tree().quit())
	main_box.add_child(b)
	# modos
	_mode_btn("ENTREGA DE TINTAS  (3ª pessoa)", "delivery", Color(0.1, 0.4, 0.2))
	_mode_btn("LOJA - OVERCOOKED  (isométrica)", "overcooked", Color(0.12, 0.22, 0.5))
	_mode_btn("SOBREVIVÊNCIA  (zumbis, 1ª pessoa)", "zombie", Color(0.5, 0.12, 0.12))
	b = UIKit.button("VOLTAR")
	b.pressed.connect(func(): _show(main_box))
	modes_box.add_child(b)
	# opções
	btn_quality = UIKit.button("")
	btn_quality.pressed.connect(func():
		Game.quality = (Game.quality + 1) % 3
		Game.save_game()
		Game.apply_quality(get_viewport())
		_refresh())
	opts_box.add_child(btn_quality)
	btn_fps = UIKit.button("")
	btn_fps.pressed.connect(func():
		Game.show_fps = not Game.show_fps
		Game.save_game()
		_refresh())
	opts_box.add_child(btn_fps)
	b = UIKit.button("VOLTAR")
	b.pressed.connect(func(): _show(main_box))
	opts_box.add_child(b)
	# créditos
	var txt = UIKit.label("Mapa: dados do OpenStreetMap (c) colaboradores do OpenStreetMap,\nlicença ODbL - openstreetmap.org/copyright\n\nJogo offline feito na Godot 4.\nModelos 3D gerados por código.\nTexturas (asfalto, calçada, grama) e céu HDRI: Poly Haven (CC0).\nFachada: fotos da Color Tintas, Passo Fundo.", 22)
	cred_box.add_child(txt)
	b = UIKit.button("VOLTAR")
	b.pressed.connect(func(): _show(main_box))
	cred_box.add_child(b)
	_show(main_box)
	_refresh()

func _column(ax: float, ay: float) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	UIKit.place(v, ax, ay, 40, 0, 1, 1)
	return v

func _mode_btn(text: String, mode: String, col: Color) -> void:
	var b = UIKit.button(text, 24, col)
	b.custom_minimum_size = Vector2(520, 66)
	b.pressed.connect(func(): Game.go(mode))
	modes_box.add_child(b)

func _show(box: Control) -> void:
	main_box.visible = box == main_box
	modes_box.visible = box == modes_box
	opts_box.visible = box == opts_box
	cred_box.visible = box == cred_box

func _refresh() -> void:
	btn_quality.text = "QUALIDADE GRÁFICA: " + Game.quality_name().to_upper()
	btn_fps.text = "MOSTRAR FPS: " + ("SIM" if Game.show_fps else "NÃO")
	lbl_stats.text = U.fmt_money(Game.money) + "\nEntregas: " + str(Game.deliveries) + "   Melhor onda: " + str(Game.best_wave)
