extends Control

const WorldView = preload("res://scripts/world_view.gd")

const TECH_NAMES := [
	"石器部落",
	"火与工具",
	"农业定居",
	"文字城邦",
	"冶炼王国",
	"机械文明",
	"电气时代",
	"计算文明"
]

const TECH_THRESHOLDS := [0.0, 45.0, 150.0, 380.0, 820.0, 1500.0, 2600.0, 4200.0]

enum Phase { SETUP, RUNNING, RESULT }

var phase := Phase.SETUP
var paused := true
var simulation_speed := 1.0
var simulation_accumulator := 0.0

var planet_name_edit: LineEdit
var climate_option: OptionButton
var water_option: OptionButton
var mineral_option: OptionButton
var human_count_spin: SpinBox
var setup_screen: Control
var dashboard: Control
var result_overlay: Control
var result_summary: RichTextLabel
var world_view: Control
var timeline: RichTextLabel
var progress_bar: ProgressBar
var year_label: Label
var population_label: Label
var technology_label: Label
var stability_label: Label
var pause_button: Button
var speed_label: Label
var environment_label: Label

var year := 0
var population := 0.0
var knowledge := 0.0
var stability := 75.0
var food_security := 65.0
var carrying_capacity := 12000.0
var tech_index := 0
var world_seed := 1
var event_history: Array[String] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	randomize()
	_build_interface()
	_show_setup()

func _process(delta: float) -> void:
	if phase != Phase.RUNNING or paused:
		return

	simulation_accumulator += delta * simulation_speed
	while simulation_accumulator >= 0.24:
		simulation_accumulator -= 0.24
		_simulate_step()
		if phase != Phase.RUNNING:
			break

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#09111d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 16)
	margin.add_child(shell)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	shell.add_child(header)

	var header_text := VBoxContainer.new()
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_text)

	var title := _make_label("GENESIS", 28, Color("#f5f7fb"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	header_text.add_child(title)

	var subtitle := _make_label("第一次文明实验 · 创建世界，投放人类，观察一千年历史", 15, Color("#92a4bb"))
	header_text.add_child(subtitle)

	var version := _make_label("v0.2.0", 15, Color("#8bd5ca"))
	version.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(version)

	var content_holder := Control.new()
	content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(content_holder)

	_build_setup_screen(content_holder)
	_build_dashboard(content_holder)
	_build_result_overlay()

func _build_setup_screen(parent: Control) -> void:
	setup_screen = CenterContainer.new()
	setup_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(setup_screen)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 500)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#121d2b"), 22))
	setup_screen.add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 34)
	panel_margin.add_theme_constant_override("margin_right", 34)
	panel_margin.add_theme_constant_override("margin_top", 30)
	panel_margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(panel_margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	panel_margin.add_child(layout)

	var heading := _make_label("创建你的第一颗文明星球", 24, Color("#f5f7fb"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(heading)

	var intro := _make_label("环境不会直接决定文明，但会持续改变生存压力、人口上限与科技路线。", 15, Color("#93a5bb"))
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(intro)

	var form := GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 20)
	form.add_theme_constant_override("v_separation", 15)
	layout.add_child(form)

	form.add_child(_make_label("星球名称", 16, Color("#d7e0ea")))
	planet_name_edit = LineEdit.new()
	planet_name_edit.placeholder_text = "例如：晨星、盖亚、远岸"
	planet_name_edit.text = "晨星"
	planet_name_edit.custom_minimum_size = Vector2(390, 42)
	form.add_child(planet_name_edit)

	form.add_child(_make_label("气候", 16, Color("#d7e0ea")))
	climate_option = _make_option(["寒冷：生存困难，适应力增长快", "温和：资源平衡，人口稳定", "炎热：灾害较多，知识积累快"], 1)
	form.add_child(climate_option)

	form.add_child(_make_label("水资源", 16, Color("#d7e0ea")))
	water_option = _make_option(["贫瘠：人口上限较低", "普通：足以维持农业", "丰沛：人口增长更快"], 1)
	form.add_child(water_option)

	form.add_child(_make_label("矿产资源", 16, Color("#d7e0ea")))
	mineral_option = _make_option(["稀少：工业发展缓慢", "普通：科技路线均衡", "丰富：冶炼与工业加速"], 1)
	form.add_child(mineral_option)

	form.add_child(_make_label("投放人类", 16, Color("#d7e0ea")))
	human_count_spin = SpinBox.new()
	human_count_spin.min_value = 20
	human_count_spin.max_value = 500
	human_count_spin.step = 10
	human_count_spin.value = 120
	human_count_spin.suffix = " 人"
	human_count_spin.custom_minimum_size = Vector2(390, 42)
	form.add_child(human_count_spin)

	var experiment_note := _make_label("实验会自动推进 1000 年。你可以暂停，或使用 5×、20× 加速观察文明兴衰。", 14, Color("#8bd5ca"))
	experiment_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	experiment_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(experiment_note)

	var start_button := Button.new()
	start_button.text = "创建星球并投放人类"
	start_button.custom_minimum_size = Vector2(0, 52)
	start_button.add_theme_font_size_override("font_size", 18)
	start_button.add_theme_stylebox_override("normal", _button_style(Color("#337a76")))
	start_button.add_theme_stylebox_override("hover", _button_style(Color("#40938e")))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color("#286460")))
	start_button.pressed.connect(_start_experiment)
	layout.add_child(start_button)

func _build_dashboard(parent: Control) -> void:
	dashboard = VBoxContainer.new()
	dashboard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dashboard.add_theme_constant_override("separation", 12)
	parent.add_child(dashboard)

	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 10)
	dashboard.add_child(metrics)
	year_label = _add_metric(metrics, "历史时间", "0 年")
	population_label = _add_metric(metrics, "人口", "0")
	technology_label = _add_metric(metrics, "文明阶段", TECH_NAMES[0])
	stability_label = _add_metric(metrics, "社会稳定", "75%")

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	dashboard.add_child(body)

	var world_panel := PanelContainer.new()
	world_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world_panel.add_theme_stylebox_override("panel", _panel_style(Color("#0f1926"), 18))
	body.add_child(world_panel)

	var world_margin := MarginContainer.new()
	world_margin.add_theme_constant_override("margin_left", 10)
	world_margin.add_theme_constant_override("margin_right", 10)
	world_margin.add_theme_constant_override("margin_top", 10)
	world_margin.add_theme_constant_override("margin_bottom", 10)
	world_panel.add_child(world_margin)

	world_view = WorldView.new()
	world_view.custom_minimum_size = Vector2(650, 430)
	world_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world_margin.add_child(world_view)

	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(340, 0)
	side_panel.add_theme_stylebox_override("panel", _panel_style(Color("#111c2a"), 18))
	body.add_child(side_panel)

	var side_margin := MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 18)
	side_margin.add_theme_constant_override("margin_right", 18)
	side_margin.add_theme_constant_override("margin_top", 18)
	side_margin.add_theme_constant_override("margin_bottom", 18)
	side_panel.add_child(side_margin)

	var side_layout := VBoxContainer.new()
	side_layout.add_theme_constant_override("separation", 10)
	side_margin.add_child(side_layout)

	environment_label = _make_label("环境", 14, Color("#8bd5ca"))
	environment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_layout.add_child(environment_label)

	var timeline_title := _make_label("文明时间线", 18, Color("#f5f7fb"))
	side_layout.add_child(timeline_title)

	timeline = RichTextLabel.new()
	timeline.bbcode_enabled = true
	timeline.scroll_following = true
	timeline.fit_content = false
	timeline.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline.custom_minimum_size = Vector2(0, 280)
	timeline.add_theme_font_size_override("normal_font_size", 14)
	timeline.add_theme_color_override("default_color", Color("#c8d2df"))
	side_layout.add_child(timeline)

	var progress_title := _make_label("千年实验进度", 13, Color("#93a5bb"))
	side_layout.add_child(progress_title)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 1000
	progress_bar.value = 0
	progress_bar.show_percentage = true
	progress_bar.custom_minimum_size = Vector2(0, 24)
	side_layout.add_child(progress_bar)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 7)
	side_layout.add_child(controls)

	pause_button = Button.new()
	pause_button.text = "暂停"
	pause_button.pressed.connect(_toggle_pause)
	controls.add_child(pause_button)

	for speed_value in [1.0, 5.0, 20.0]:
		var speed_button := Button.new()
		speed_button.text = "%d×" % int(speed_value)
		speed_button.pressed.connect(_set_speed.bind(speed_value))
		controls.add_child(speed_button)

	speed_label = _make_label("当前 1×", 13, Color("#8bd5ca"))
	speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls.add_child(speed_label)

	var reset_button := Button.new()
	reset_button.text = "重新创建星球"
	reset_button.pressed.connect(_show_setup)
	side_layout.add_child(reset_button)

func _build_result_overlay() -> void:
	result_overlay = ColorRect.new()
	result_overlay.color = Color(0.02, 0.04, 0.07, 0.92)
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(result_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 520)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#142131"), 22))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var title := _make_label("一千年文明实验完成", 25, Color("#f5f7fb"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	result_summary = RichTextLabel.new()
	result_summary.bbcode_enabled = true
	result_summary.fit_content = false
	result_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_summary.custom_minimum_size = Vector2(0, 330)
	result_summary.add_theme_font_size_override("normal_font_size", 16)
	layout.add_child(result_summary)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	layout.add_child(buttons)

	var rerun_button := Button.new()
	rerun_button.text = "同一环境再次实验"
	rerun_button.custom_minimum_size = Vector2(220, 46)
	rerun_button.pressed.connect(_rerun_experiment)
	buttons.add_child(rerun_button)

	var new_planet_button := Button.new()
	new_planet_button.text = "创建新星球"
	new_planet_button.custom_minimum_size = Vector2(180, 46)
	new_planet_button.pressed.connect(_show_setup)
	buttons.add_child(new_planet_button)

func _start_experiment() -> void:
	phase = Phase.RUNNING
	paused = false
	simulation_speed = 1.0
	simulation_accumulator = 0.0
	pause_button.text = "暂停"
	speed_label.text = "当前 1×"
	setup_screen.visible = false
	dashboard.visible = true
	result_overlay.visible = false

	year = 0
	population = human_count_spin.value
	knowledge = 0.0
	stability = 75.0
	food_security = 62.0
	tech_index = 0
	world_seed = randi()
	event_history.clear()
	timeline.clear()

	var climate_factor := [0.82, 1.0, 0.9][climate_option.selected]
	var water_factor := [0.62, 1.0, 1.38][water_option.selected]
	carrying_capacity = 13500.0 * climate_factor * water_factor

	world_view.configure({
		"seed": world_seed,
		"climate": climate_option.selected,
		"water": water_option.selected,
		"minerals": mineral_option.selected
	})

	var planet_name := planet_name_edit.text.strip_edges()
	if planet_name.is_empty():
		planet_name = "未命名星球"
		planet_name_edit.text = planet_name

	environment_label.text = "%s · %s · %s · %s" % [
		planet_name,
		["寒冷", "温和", "炎热"][climate_option.selected],
		["贫瘠", "普通", "丰沛"][water_option.selected],
		["矿产稀少", "矿产普通", "矿产丰富"][mineral_option.selected]
	]

	_add_history(0, "%d 名人类被投放到 %s，第一支部落诞生。" % [int(population), planet_name], true)
	_update_dashboard()

func _simulate_step() -> void:
	year += 5

	var climate_factor := [0.84, 1.0, 0.91][climate_option.selected]
	var water_factor := [0.72, 1.0, 1.2][water_option.selected]
	var mineral_factor := [0.82, 1.0, 1.28][mineral_option.selected]
	var capacity_pressure := 1.0 - population / max(carrying_capacity, 1.0)
	var growth_rate := 0.022 * climate_factor * water_factor * capacity_pressure
	growth_rate += randf_range(-0.006, 0.006)
	growth_rate += tech_index * 0.0015
	population = max(0.0, population + population * growth_rate)

	food_security += (water_factor - 1.0) * 1.4
	food_security += tech_index * 0.12
	food_security += randf_range(-2.2, 2.0)
	food_security = clampf(food_security, 5.0, 100.0)

	stability += randf_range(-1.8, 1.6)
	if food_security < 35.0:
		stability -= 2.0
	elif food_security > 75.0:
		stability += 0.6
	stability = clampf(stability, 0.0, 100.0)

	knowledge += max(0.7, population * 0.0038 * mineral_factor * (1.0 + tech_index * 0.07))
	_check_technology_progress()
	_try_random_event()

	if year % 100 == 0:
		_add_history(year, "人口达到 %s，文明处于%s。" % [_format_population(int(population)), TECH_NAMES[tech_index]])

	_update_dashboard()

	if population < 8.0:
		_add_history(year, "最后的聚落消失，文明实验提前结束。", true)
		_finish_experiment(true)
	elif year >= 1000:
		_finish_experiment(false)

func _check_technology_progress() -> void:
	while tech_index + 1 < TECH_THRESHOLDS.size() and knowledge >= TECH_THRESHOLDS[tech_index + 1]:
		tech_index += 1
		var discovery_text := [
			"",
			"文明掌握了火种与石制工具，夜晚第一次被照亮。",
			"农业革命发生，人类开始定居并储存粮食。",
			"文字与制度出现，历史不再只依靠口述。",
			"冶炼技术成熟，城市与王国开始扩张。",
			"机械化生产出现，人口和资源消耗快速增长。",
			"电力连接城市，文明进入大规模协作时代。",
			"计算机诞生，文明开始预测并改造自己的未来。"
		][tech_index]
		_add_history(year, discovery_text, true)
		stability = min(100.0, stability + 5.0)
		carrying_capacity *= 1.16

func _try_random_event() -> void:
	if randf() > 0.045:
		return

	var event_roll := randi_range(0, 5)
	match event_roll:
		0:
			var loss := 0.04 if water_option.selected == 2 else 0.1
			population *= 1.0 - loss
			food_security -= 14.0
			stability -= 7.0
			_add_history(year, "持续旱灾摧毁农田，部分人口被迫迁徙。", true)
		1:
			population *= 0.91
			stability -= 5.0
			_add_history(year, "疾病在聚落间传播，文明付出了沉重代价。", true)
		2:
			food_security += 18.0
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

	food_security = clampf(food_security, 0.0, 100.0)
	stability = clampf(stability, 0.0, 100.0)

func _update_dashboard() -> void:
	year_label.text = "%d 年" % year
	population_label.text = _format_population(int(population))
	technology_label.text = TECH_NAMES[tech_index]
	stability_label.text = "%d%%" % int(stability)
	progress_bar.value = year
	world_view.set_civilization_state(year, int(population), tech_index, population >= 8.0)

	if stability < 30.0:
		stability_label.add_theme_color_override("font_color", Color("#f08b81"))
	elif stability > 70.0:
		stability_label.add_theme_color_override("font_color", Color("#8bd5ca"))
	else:
		stability_label.add_theme_color_override("font_color", Color("#f1d18a"))

func _finish_experiment(extinct: bool) -> void:
	phase = Phase.RESULT
	paused = true
	result_overlay.visible = true

	var planet_name := planet_name_edit.text.strip_edges()
	var outcome := _determine_outcome(extinct)
	var highlights := ""
	var start_index := max(0, event_history.size() - 5)
	for i in range(start_index, event_history.size()):
		highlights += "• %s\n" % event_history[i]

	result_summary.text = "[center][color=#8bd5ca][font_size=22]%s[/font_size][/color][/center]\n\n" % outcome
	result_summary.append_text("[b]星球：[/b]%s\n" % planet_name)
	result_summary.append_text("[b]模拟时间：[/b]%d 年\n" % year)
	result_summary.append_text("[b]最终人口：[/b]%s\n" % _format_population(int(population)))
	result_summary.append_text("[b]文明阶段：[/b]%s\n" % TECH_NAMES[tech_index])
	result_summary.append_text("[b]社会稳定：[/b]%d%%\n" % int(stability))
	result_summary.append_text("[b]积累知识：[/b]%d\n\n" % int(knowledge))
	result_summary.append_text("[color=#93a5bb][b]最后的历史片段[/b][/color]\n%s" % highlights)

func _determine_outcome(extinct: bool) -> String:
	if extinct:
		return "文明结局：失落的星球"
	if tech_index >= 7 and stability >= 60.0:
		return "文明结局：繁荣的计算文明"
	if tech_index >= 6 and stability < 45.0:
		return "文明结局：高速发展下的分裂社会"
	if tech_index >= 5:
		return "文明结局：工业化世界"
	if population > carrying_capacity * 0.75:
		return "文明结局：人口繁盛的农业帝国"
	if stability >= 75.0:
		return "文明结局：稳定的共同体"
	return "文明结局：仍在寻找未来的年轻文明"

func _add_history(event_year: int, text: String, important: bool = false) -> void:
	var color := "#8bd5ca" if important else "#93a5bb"
	timeline.append_text("[color=%s][b]%d 年[/b][/color]\n%s\n\n" % [color, event_year, text])
	event_history.append("%d 年：%s" % [event_year, text])

func _toggle_pause() -> void:
	if phase != Phase.RUNNING:
		return
	paused = not paused
	pause_button.text = "继续" if paused else "暂停"

func _set_speed(value: float) -> void:
	simulation_speed = value
	speed_label.text = "当前 %d×" % int(value)
	if phase == Phase.RUNNING:
		paused = false
		pause_button.text = "暂停"

func _rerun_experiment() -> void:
	_start_experiment()

func _show_setup() -> void:
	phase = Phase.SETUP
	paused = true
	setup_screen.visible = true
	dashboard.visible = false
	result_overlay.visible = false

func _format_population(value: int) -> String:
	if value >= 1000000:
		return "%.2f M" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1f K" % (float(value) / 1000.0)
	return str(value)

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_option(items: Array, selected_index: int) -> OptionButton:
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(390, 42)
	for item in items:
		option.add_item(str(item))
	option.select(selected_index)
	return option

func _add_metric(parent: Control, title: String, value: String) -> Label:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#121d2b"), 14))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	margin.add_child(layout)
	layout.add_child(_make_label(title, 12, Color("#8294aa")))
	var value_label := _make_label(value, 19, Color("#eef3f8"))
	layout.add_child(value_label)
	return value_label

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1, 1, 1, 0.08)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
