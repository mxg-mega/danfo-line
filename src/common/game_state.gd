extends Node

## Autoload: holds cross-scene state for Danfo Line.
## The chosen driver (persisted) and user settings (master volume).
## Accessed as `GameState` from any script.

const CONFIG_PATH: String = "user://settings.cfg"

var driver_id: String = "tunde"
var master_volume: float = 1.0

func _ready() -> void:
	_load_settings()
	apply_master_volume(master_volume)

func driver() -> Dictionary:
	return Drivers.by_id(driver_id)

## The 3 roster drivers other than the chosen one (used for rival bot identities).
func roster_without_driver() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: Dictionary in Drivers.ROSTER:
		if d.id == driver_id:
			continue
		out.append(d)
	return out

func set_driver(id: String) -> void:
	if Drivers.by_id(id).is_empty():
		return
	driver_id = id
	_save_settings()

## Settings — Master bus volume (0.0 to 1.0). Audio plays on the Master bus
## via the pooled AudioStreamPlayers in AudioManager.
func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_master_volume(master_volume)
	_save_settings()

func apply_master_volume(value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, value <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))

func _save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("player", "driver_id", driver_id)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.save(CONFIG_PATH)

func _load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	var saved_id: String = str(cfg.get_value("player", "driver_id", driver_id))
	if not Drivers.by_id(saved_id).is_empty():
		driver_id = saved_id
	master_volume = clampf(float(cfg.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)