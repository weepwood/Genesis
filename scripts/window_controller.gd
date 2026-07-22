extends Node

const DESIGN_SIZE := Vector2(1280.0, 720.0)

@onready var interface_root: Control = $UILayer/Genesis

var settle_frames := 8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_configure_window")

func _process(_delta: float) -> void:
	if settle_frames <= 0:
		return
	settle_frames -= 1
	_apply_layout()

func _configure_window() -> void:
	var window := get_window()
	window.unresizable = false

	if DisplayServer.get_name() != "headless":
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

	_apply_layout()

func _apply_layout() -> void:
	if not is_instance_valid(interface_root):
		return

	interface_root.custom_minimum_size = Vector2.ZERO
	interface_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	interface_root.offset_left = 0.0
	interface_root.offset_top = 0.0
	interface_root.offset_right = 0.0
	interface_root.offset_bottom = 0.0
	interface_root.position = Vector2.ZERO
	interface_root.scale = Vector2.ONE

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x > 1.0 and viewport_size.y > 1.0:
		print("GENESIS_LAYOUT_READY viewport=", viewport_size, " design=", DESIGN_SIZE)

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_F11:
		return

	var current_mode := DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	get_viewport().set_input_as_handled()
