class_name RealAssets
extends RefCounted
## Carrega modelos glTF CC0 baixados pelo pipeline de build. Se ausentes, o jogo usa os modelos locais.

static var _manifest: Dictionary = {}
static var _scenes: Dictionary = {}
static var _manifest_loaded: bool = false

static func _load_manifest() -> void:
	if _manifest_loaded:
		return
	_manifest_loaded = true
	var path = "res://assets/realism/manifest.json"
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_manifest = parsed

static func has_model(asset_id: String) -> bool:
	_load_manifest()
	return _manifest.has(asset_id) and ResourceLoader.exists(str(_manifest[asset_id].get("path", "")))

static func instantiate(asset_id: String) -> Node3D:
	_load_manifest()
	if not _manifest.has(asset_id):
		return null
	if not _scenes.has(asset_id):
		var path = str(_manifest[asset_id].get("path", ""))
		if path == "" or not ResourceLoader.exists(path):
			return null
		var packed = load(path) as PackedScene
		if packed == null:
			return null
		_scenes[asset_id] = packed
	var instance = (_scenes[asset_id] as PackedScene).instantiate()
	return instance as Node3D
