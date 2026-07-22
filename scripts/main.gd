extends Control

const WorldViewScript = preload("res://scripts/world_view.gd")

const TECH_NAMES := [
	"石器部落", "火与工具", "农业定居", "文字城邦",
	"冶炼王国", "机械文明", "电气时代", "计算文明"
]
const TECH_THRESHOLDS := [0.0, 45.0, 150.0, 380.0, 820.0, 1500.0, 2600.0, 4200.0]

enum Phase { SETUP, RUNNING, RESULT }

var initialized := false
var phase := Phase.SETUP
var paused := true
var speed := 1.0
var accumulator := 0.0

var setup_screen: Control
var dashboard: Control
var result_overlay: Control
var planet_name: LineEdit
var climate_option: OptionButton
var water_option: OptionButton
var mineral_option: OptionButton
var human_count: SpinBox
var year_label: Label
var population_label: Label
var technology_label: Label
var stability_label: Label
var environment_label: Label
var timeline: RichTextLabel
var progress: ProgressBar
var pause_button: Button
var speed_label: Label
var world_view: Control
var result_text: RichTextLabel

var year := 0
var population := 120.0
var knowledge := 0.0
var stability := 75.0
var food := 65.0
var capacity := 12000.0
var tech_index := 0
var history: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_initialize_ui")

func _initialize_ui() -> void:
	if initialized:
		return
	initialized = true
	custom_minimum_size = Vector2(1280, 720)
	_build_interface()
	_show_setup()
	_remove_fallback()
	_write_startup_log("GENESIS_UI_READY viewport=%s root=%s children=%d" % [get_viewport_rect().size, size, get_child_count()])
	print("GENESIS_UI_READY viewport=", get_viewport_rect().size, " root=", size, " children=", get_child_count())

func _process(delta: float) -> void:
	if not initialized or phase != Phase.RUNNING or paused:
		return
	accumulator += delta * speed
	while accumulator >= 0.12:
		accumulator -= 0.12
		_simulate_step()
		if phase != Phase.RUNNING:
			break

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#08111d")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_full_rect(self, background)

	var margin := MarginContainer.new()
	_add_full_rect(self, margin)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)

	var shell := VBoxContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_theme_constant_override("separation", 14)
	margin.add_child(shell)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	shell.add_child(header)
	var header_words := VBoxContainer.new()
	header_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_words)
	header_words.add_child(_label("GENESIS", 30, Color("#f4f7fb")))
	header_words.add_child(_label("第一次文明实验 · 创建星球，投放人类，观察一千年历史", 15, Color("#91a5bd")))
	var version := _label("v0.2.1", 15, Color("#8bd5ca"))
	version.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(version)

	var screens := Control.new()
	screens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screens.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(screens)
	_build_setup(screens)
	_build_dashboard(screens)
	_build_result()

func _build_setup(parent: Control) -> void:
	setup_screen = CenterContainer.new()
	_add_full_rect(parent, setup_screen)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 520)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#121d2b"), 22))
	setup_screen.add_child(panel)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 36)
	inner.add_theme_constant_override("margin_right", 36)
	inner.add_theme_constant_override("margin_top", 30)
	inner.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(inner)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	inner.add_child(layout)
	var title := _label("创建你的第一颗文明星球", 26, Color("#f4f7fb"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var intro := _label("环境会改变生存压力、人口上限和科技速度。每次实验都会产生不同历史。", 15, Color("#91a5bd"))
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(intro)

	var form := GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 22)
	form.add_theme_constant_override("v_separation", 15)
	layout.add_child(form)

	form.add_child(_label("星球名称", 16, Color("#d7e0ea")))
	planet_name = LineEdit.new()
	planet_name.text = "晨星"
	planet_name.placeholder_text = "例如：晨星、盖亚、远岸"
	planet_name.custom_minimum_size = Vector2(410, 44)
	form.add_child(planet_name)

	form.add_child(_label("气候", 16, Color("#d7e0ea")))
	climate_option = _option(["寒冷：适应困难", "温和：资源均衡", "炎热：灾害频繁"], 1)
	form.add_child(climate_option)

	form.add_child(_label("水资源", 16, Color("#d7e0ea")))
	water_option = _option(["贫瘠：人口上限低", "普通：适合农业", "丰沛：人口增长快"], 1)
	form.add_child(water_option)

	form.add_child(_label("矿产资源", 16, Color("#d7e0ea")))
	mineral_option = _option(["稀少：工业缓慢", "普通：路线均衡", "丰富：冶炼加速"], 1)
	form.add_child(mineral_option)

	form.add_child(_label("投放人类", 16, Color("#d7e0ea")))
	human_count = SpinBox.new()
	human_count.min_value = 20
	human_count.max_value = 500
	human_count.step = 10
	human_count.value = 120
	human_count.suffix = " 人"
	human_count.custom_minimum_size = Vector2(410, 44)
	form.add_child(human_count)

	var note := _label("实验会自动推进 1000 年。可以暂停，或使用 5×、20× 加速。", 14, Color("#8bd5ca"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(note)
	var start := Button.new()
	start.text = "创建星球并投放人类"
	start.custom_minimum_size = Vector2(0, 54)
	start.add_theme_font_size_override("font_size", 18)
	start.add_theme_stylebox_override("normal", _button_style(Color("#337a76")))
	start.add_theme_stylebox_override("hover", _button_style(Color("#40938e")))
	start.add_theme_stylebox_override("pressed", _button_style(Color("#286460")))
	start.pressed.connect(_start_experiment)
	layout.add_child(start)

func _build_dashboard(parent: Control) -> void:
	dashboard = VBoxContainer.new()
	_add_full_rect(parent, dashboard)
	dashboard.add_theme_constant_override("separation", 12)

	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 10)
	dashboard.add_child(metrics)
	year_label = _metric(metrics, "历史时间", "0 年")
	population_label = _metric(metrics, "人口", "0")
	technology_label = _metric(metrics, "文明阶段", TECH_NAMES[0])
	stability_label = _metric(metrics, "社会稳定", "75%")

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	dashboard.add_child(body)

	var world_panel := PanelContainer.new()
	world_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world_panel.add_theme_stylebox_override("panel", _panel_style(Color("#0f1926"), 18))
	body.add_child(world_panel)
	var world_margin := MarginContainer.new()
	for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		world_margin.add_theme_constant_override(key, 10)
	world_panel.add_child(world_margin)
	world_view = WorldViewScript.new()
	world_view.custom_minimum_size = Vector2(620, 420)
	world_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world_margin.add_child(world_view)

	var side := PanelContainer.new()
	side.custom_minimum_size = Vector2(350, 0)
	side.add_theme_stylebox_override("panel", _panel_style(Color("#111c2a"), 18))
	body.add_child(side)
	var side_margin := MarginContainer.new()
	for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		side_margin.add_theme_constant_override(key, 18)
	side.add_child(side_margin)
	var side_layout := VBoxContainer.new()
	side_layout.add_theme_constant_override("separation", 10)
	side_margin.add_child(side_layout)
	environment_label = _label("环境", 14, Color("#8bd5ca"))
	environment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_layout.add_child(environment_label)
	side_layout.add_child(_label("文明时间线", 18, Color("#f4f7fb")))
	timeline = RichTextLabel.new()
	timeline.bbcode_enabled = true
	timeline.scroll_following = true
	timeline.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline.custom_minimum_size = Vector2(0, 270)
	timeline.add_theme_font_size_override("normal_font_size", 14)
	timeline.add_theme_color_override("default_color", Color("#c8d2df"))
	side_layout.add_child(timeline)
	side_layout.add_child(_label("千年实验进度", 13, Color("#91a5bd")))
	progress = ProgressBar.new()
	progress.max_value = 1000
	progress.custom_minimum_size = Vector2(0, 24)
	side_layout.add_child(progress)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 7)
	side_layout.add_child(controls)
	pause_button = Button.new()
	pause_button.text = "暂停"
	pause_button.pressed.connect(_toggle_pause)
	controls.add_child(pause_button)
	for speed_value in [1.0, 5.0, 20.0]:
		var button := Button.new()
		button.text = "%d×" % int(speed_value)
		button.pressed.connect(_set_speed.bind(speed_value))
		controls.add_child(button)
	speed_label = _label("当前 1×", 13, Color("#8bd5ca"))
	speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls.add_child(speed_label)
	var reset := Button.new()
	reset.text = "重新创建星球"
	reset.pressed.connect(_show_setup)
	side_layout.add_child(reset)

func _build_result() -> void:
	result_overlay = ColorRect.new()
	result_overlay.color = Color(0.02, 0.04, 0.07, 0.94)
	_add_full_rect(self, result_overlay)
	var center := CenterContainer.new()
	_add_full_rect(result_overlay, center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(740, 520)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#142131"), 22))
	center.add_child(panel)
	var inner := MarginContainer.new()
	for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inner.add_theme_constant_override(key, 30)
	panel.add_child(inner)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	inner.add_child(layout)
	var title := _label("一千年文明实验完成", 26, Color("#f4f7fb"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	result_text = RichTextLabel.new()
	result_text.bbcode_enabled = true
	result_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_text.custom_minimum_size = Vector2(0, 340)
	result_text.add_theme_font_size_override("normal_font_size", 16)
	layout.add_child(result_text)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	layout.add_child(buttons)
	var rerun := Button.new()
	rerun.text = "同一环境再次实验"
	rerun.custom_minimum_size = Vector2(220, 46)
	rerun.pressed.connect(_start_experiment)
	buttons.add_child(rerun)
	var recreate := Button.new()
	recreate.text = "创建新星球"
	recreate.custom_minimum_size = Vector2(180, 46)
	recreate.pressed.connect(_show_setup)
	buttons.add_child(recreate)

func _start_experiment() -> void:
	phase = Phase.RUNNING
	paused = false
	speed = 1.0
	accumulator = 0.0
	setup_screen.visible = false
	dashboard.visible = true
	result_overlay.visible = false
	pause_button.text = "暂停"
	speed_label.text = "当前 1×"
	year = 0
	population = human_count.value
	knowledge = 0.0
	stability = 75.0
	food = 65.0
	tech_index = 0
	history.clear()
	timeline.clear()
	var climate_factor: float = float([0.82, 1.0, 0.9][climate_option.selected])
	var water_factor: float = float([0.62, 1.0, 1.38][water_option.selected])
	capacity = 13500.0 * climate_factor * water_factor
	world_view.configure({
		"seed": randi(),
		"climate": climate_option.selected,
		"water": water_option.selected,
		"minerals": mineral_option.selected
	})
	var name_text := planet_name.text.strip_edges()
	if name_text.is_empty():
		name_text = "未命名星球"
		planet_name.text = name_text
	environment_label.text = "%s · %s · %s · %s" % [
		name_text,
		["寒冷", "温和", "炎热"][climate_option.selected],
		["贫瘠", "普通", "丰沛"][water_option.selected],
		["矿产稀少", "矿产普通", "矿产丰富"][mineral_option.selected]
	]
	_add_history(0, "%d 名人类被投放到 %s，第一支部落诞生。" % [int(population), name_text], true)
	_update_dashboard()

func _simulate_step() -> void:
	year += 5
	var climate_factor: float = float([0.84, 1.0, 0.91][climate_option.selected])
	var water_factor: float = float([0.72, 1.0, 1.2][water_option.selected])
	var mineral_factor: float = float([0.82, 1.0, 1.28][mineral_option.selected])
	var pressure: float = 1.0 - population / max(capacity, 1.0)
	var growth: float = 0.022 * climate_factor * water_factor * pressure + randf_range(-0.006, 0.006)
	growth += tech_index * 0.0015
	population = max(0.0, population + population * growth)
	food = clampf(food + (water_factor - 1.0) * 1.4 + tech_index * 0.12 + randf_range(-2.2, 2.0), 5.0, 100.0)
	stability += randf_range(-1.8, 1.6)
	if food < 35.0:
		stability -= 2.0
	elif food > 75.0:
		stability += 0.6
	stability = clampf(stability, 0.0, 100.0)
	knowledge += max(0.7, population * 0.0038 * mineral_factor * (1.0 + tech_index * 0.07))
	_check_technology()
	_random_event()
	if year % 100 == 0:
		_add_history(year, "人口达到 %s，文明处于%s。" % [_format_population(int(population)), TECH_NAMES[tech_index]])
	_update_dashboard()
	if population < 8.0:
		_add_history(year, "最后的聚落消失，文明实验提前结束。", true)
		_finish(true)
	elif year >= 1000:
		_finish(false)

func _check_technology() -> void:
	while tech_index + 1 < TECH_THRESHOLDS.size() and knowledge >= TECH_THRESHOLDS[tech_index + 1]:
		tech_index += 1
		var discoveries := [
			"", "文明掌握火种与石制工具，夜晚第一次被照亮。",
			"农业革命发生，人类开始定居并储存粮食。",
			"文字与制度出现，历史不再只依靠口述。",
			"冶炼技术成熟，城市与王国开始扩张。",
			"机械化生产出现，人口和资源消耗快速增长。",
			"电力连接城市，文明进入大规模协作时代。",
			"计算机诞生，文明开始预测并改造自己的未来。"
		]
		_add_history(year, discoveries[tech_index], true)
		stability = min(100.0, stability + 5.0)
		capacity *= 1.16

func _random_event() -> void:
	if randf() > 0.045:
		return
	match randi_range(0, 5):
		0:
			population *= 0.94 if water_option.selected == 2 else 0.9
			food -= 14.0
			stability -= 7.0
			_add_history(year, "持续旱灾摧毁农田，部分人口被迫迁徙。", true)
		1:
			population *= 0.91
			stability -= 5.0
			_add_history(year, "疾病在聚落间传播，文明付出了沉重代价。", true)
		2:
			food += 18.0
			population *= 1.035
			stability += 4.0
			_add_history(year, "连续丰收带来人口增长与繁荣。")
		3:
			knowledge += 90.0 + tech_index * 30.0
			_add_history(year, "一位天才观察者提出新理论，知识积累突然加速。", true)
		4:
			stability += 12.0
			_add_history(year, "社会改革缓和矛盾，新的协作制度建立。")
		5:
			if mineral_option.selected == 2:
				knowledge += 130.0
				_add_history(year, "大型矿脉被发现，冶炼与工具制造迅速发展。", true)
			else:
				stability -= 9.0
				_add_history(year, "资源争夺引发冲突，多个聚落陷入对立。", true)
	food = clampf(food, 0.0, 100.0)
	stability = clampf(stability, 0.0, 100.0)

func _update_dashboard() -> void:
	year_label.text = "%d 年" % year
	population_label.text = _format_population(int(population))
	technology_label.text = TECH_NAMES[tech_index]
	stability_label.text = "%d%%" % int(stability)
	progress.value = year
	world_view.set_civilization_state(year, int(population), tech_index, population >= 8.0)

func _finish(extinct: bool) -> void:
	phase = Phase.RESULT
	paused = true
	result_overlay.visible = true
	var outcome := "文明结局：失落的星球" if extinct else _outcome()
	var recent := ""
	for i in range(max(0, history.size() - 5), history.size()):
		recent += "• %s\n" % history[i]
	result_text.text = "[center][color=#8bd5ca][font_size=22]%s[/font_size][/color][/center]\n\n" % outcome
	result_text.append_text("[b]星球：[/b]%s\n" % planet_name.text)
	result_text.append_text("[b]模拟时间：[/b]%d 年\n" % year)
	result_text.append_text("[b]最终人口：[/b]%s\n" % _format_population(int(population)))
	result_text.append_text("[b]文明阶段：[/b]%s\n" % TECH_NAMES[tech_index])
	result_text.append_text("[b]社会稳定：[/b]%d%%\n\n" % int(stability))
	result_text.append_text("[color=#91a5bd][b]最后的历史片段[/b][/color]\n%s" % recent)

func _outcome() -> String:
	if tech_index >= 7 and stability >= 60.0:
		return "文明结局：繁荣的计算文明"
	if tech_index >= 6 and stability < 45.0:
		return "文明结局：高速发展下的分裂社会"
	if tech_index >= 5:
		return "文明结局：工业化世界"
	if stability >= 75.0:
		return "文明结局：稳定的共同体"
	return "文明结局：仍在寻找未来的年轻文明"

func _show_setup() -> void:
	phase = Phase.SETUP
	paused = true
	setup_screen.visible = true
	dashboard.visible = false
	result_overlay.visible = false

func _toggle_pause() -> void:
	if phase != Phase.RUNNING:
		return
	paused = not paused
	pause_button.text = "继续" if paused else "暂停"

func _set_speed(value: float) -> void:
	speed = value
	speed_label.text = "当前 %d×" % int(value)
	if phase == Phase.RUNNING:
		paused = false
		pause_button.text = "暂停"

func _add_history(event_year: int, text: String, important: bool = false) -> void:
	var color := "#8bd5ca" if important else "#91a5bd"
	timeline.append_text("[color=%s][b]%d 年[/b][/color]\n%s\n\n" % [color, event_year, text])
	history.append("%d 年：%s" % [event_year, text])

func _add_full_rect(parent: Node, child: Control) -> void:
	parent.add_child(child)
	child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _remove_fallback() -> void:
	var background := get_node_or_null("FallbackBackground")
	var center := get_node_or_null("FallbackCenter")
	if background:
		background.queue_free()
	if center:
		center.queue_free()

func _write_startup_log(message: String) -> void:
	var file := FileAccess.open("user://Genesis.log", FileAccess.WRITE)
	if file:
		file.store_line(message)
		file.close()

func _format_population(value: int) -> String:
	if value >= 1000000:
		return "%.2f M" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1f K" % (float(value) / 1000.0)
	return str(value)

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _option(items: Array, selected_index: int) -> OptionButton:
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(410, 44)
	for item in items:
		option.add_item(str(item))
	option.select(selected_index)
	return option

func _metric(parent: Control, title: String, value: String) -> Label:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#121d2b"), 14))
	parent.add_child(panel)
	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 16)
	inner.add_theme_constant_override("margin_right", 16)
	inner.add_theme_constant_override("margin_top", 10)
	inner.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(inner)
	var layout := VBoxContainer.new()
	inner.add_child(layout)
	layout.add_child(_label(title, 12, Color("#8294aa")))
	var value_label := _label(value, 19, Color("#eef3f8"))
	layout.add_child(value_label)
	return value_label

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1, 1, 1, 0.08)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
