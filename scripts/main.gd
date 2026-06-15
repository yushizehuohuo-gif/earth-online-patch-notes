extends Control

const EarthView = preload("res://scripts/earth_view.gd")

const MAX_PATCHES := 12
const CRISIS_THRESHOLD := 15.0
const FAIL_LIMIT := 8.0
const BG_COLOR := Color(0.027, 0.031, 0.039)
const SFX_MIX_RATE := 44100
const STARTING_STATS := {
	"civilization": 58.0,
	"ecology": 56.0,
	"joy": 54.0,
	"stability": 70.0,
}
const STARTING_RESOURCES := {
	"trust": 52,
	"ops": 6,
	"maintenance": 2,
	"rollback": 1,
}
const DIFFICULTIES := [
	{
		"key": "casual",
		"label": "休闲运营",
		"summary": "风险 -30%，事故热度增长 -50%，开局资源更宽松。",
		"stats": {"civilization": 62.0, "ecology": 60.0, "joy": 58.0, "stability": 76.0},
		"resources": {"trust": 62, "ops": 8, "maintenance": 3, "rollback": 2},
		"risk_multiplier": 0.7,
		"heat_multiplier": 0.5,
		"threshold_offset": 10.0,
		"victory_trust": 48,
		"victory_stat": 32,
	},
	{
		"key": "normal",
		"label": "正常值班",
		"summary": "默认数值。后台说这是可控范围，后台经常这么说。",
		"stats": STARTING_STATS,
		"resources": STARTING_RESOURCES,
		"risk_multiplier": 1.0,
		"heat_multiplier": 1.0,
		"threshold_offset": 0.0,
		"victory_trust": 48,
		"victory_stat": 33,
	},
	{
		"key": "hell",
		"label": "地狱轮值",
		"summary": "风险 +30%，事故热度增长 +50%，开局资源更少。",
		"stats": {"civilization": 52.0, "ecology": 50.0, "joy": 48.0, "stability": 62.0},
		"resources": {"trust": 42, "ops": 6, "maintenance": 2, "rollback": 0},
		"risk_multiplier": 1.3,
		"heat_multiplier": 1.2,
		"threshold_offset": -4.0,
		"victory_trust": 40,
		"victory_stat": 28,
	},
]
const STAT_DEFS := [
	{"key": "civilization", "label": "文明", "color": Color(0.38, 0.72, 1.0)},
	{"key": "ecology", "label": "生态", "color": Color(0.34, 0.82, 0.46)},
	{"key": "joy", "label": "快乐", "color": Color(1.0, 0.72, 0.28)},
	{"key": "stability", "label": "稳定", "color": Color(0.94, 0.48, 0.58)},
]
const RESOURCE_DEFS := [
	{"key": "trust", "label": "口碑"},
	{"key": "ops", "label": "预算"},
	{"key": "maintenance", "label": "维护窗"},
	{"key": "rollback", "label": "回滚令"},
]
const OBJECTIVES := [
	{
		"title": "季度目标：绿色公测",
		"text": "3 个版本内让生态达到 66，并保持稳定不低于 42。",
		"checks": {"ecology": 66, "stability": 42},
		"reward": {"trust": 11, "ops": 2},
		"fail": {"trust": -8, "stability": -5},
		"reward_text": "口碑 +11 / 预算 +2",
		"fail_text": "口碑 -8 / 稳定 -5"
	},
	{
		"title": "季度目标：别让玩家退游",
		"text": "3 个版本内把快乐推到 68，稳定保持 38 以上。",
		"checks": {"joy": 68, "stability": 38},
		"reward": {"trust": 12, "maintenance": 1},
		"fail": {"trust": -10, "joy": -5},
		"reward_text": "口碑 +12 / 维护窗 +1",
		"fail_text": "口碑 -10 / 快乐 -5"
	},
	{
		"title": "季度目标：文明版本号",
		"text": "3 个版本内让文明达到 70，同时生态不能低于 35。",
		"checks": {"civilization": 70, "ecology": 35},
		"reward": {"trust": 10, "ops": 3},
		"fail": {"trust": -9, "civilization": -5},
		"reward_text": "口碑 +10 / 预算 +3",
		"fail_text": "口碑 -9 / 文明 -5"
	},
	{
		"title": "季度目标：稳住别炸",
		"text": "3 个版本内稳定达到 72，任何指标不能低于 34。",
		"checks": {"stability": 72, "civilization": 34, "ecology": 34, "joy": 34},
		"reward": {"trust": 9, "rollback": 1},
		"fail": {"trust": -8, "stability": -8},
		"reward_text": "口碑 +9 / 回滚令 +1",
		"fail_text": "口碑 -8 / 稳定 -8"
	},
]
const INCIDENTS := [
	{
		"title": "地图加载雪崩",
		"body": "玩家同时涌向同一条人生支线，服务器把排队 UI 渲染成了天空。",
		"deltas": {"stability": -10, "joy": -5},
		"trust": -7,
		"cooldown": 13
	},
	{
		"title": "论坛大型复盘",
		"body": "玩家逐帧分析补丁说明，发现运营团队也在摸索地球规则。",
		"deltas": {"stability": -6, "civilization": -3},
		"trust": -8,
		"cooldown": 10
	},
	{
		"title": "生态副本反噬",
		"body": "被忽视太久的生态系统开始主动重写几条城市任务线。",
		"deltas": {"ecology": -8, "stability": -8},
		"trust": -6,
		"cooldown": 12
	},
	{
		"title": "情绪缓存溢出",
		"body": "大量玩家在深夜同时回忆人生，快乐服务器短暂掉线。",
		"deltas": {"joy": -11, "stability": -4},
		"trust": -5,
		"cooldown": 11
	},
	{
		"title": "文明模组冲突",
		"body": "效率插件和同理心插件抢同一个接口，文明进度条开始闪烁。",
		"deltas": {"civilization": -8, "joy": -4, "stability": -5},
		"trust": -6,
		"cooldown": 12
	},
]
const CARD_POOL := [
	{
		"title": "天气系统热修",
		"tag": "气候",
		"body": "云层获得懒加载，连续晴天不再无限叠加。",
		"deltas": {"ecology": 10, "joy": -2, "stability": -4},
		"cost": 1,
		"risk": 7,
		"trust": 2,
		"primary": "ecology",
		"note": "草地贴图不再一到高温就焦黄。",
		"bug": "雨伞仍会在玩家出门前自动卸载。"
	},
	{
		"title": "周一难度下调",
		"tag": "生活",
		"body": "周一上午的精神抗性惩罚降低，但咖啡经济开始波动。",
		"deltas": {"joy": 12, "civilization": -4, "stability": -5},
		"cost": 1,
		"risk": 8,
		"trust": 3,
		"primary": "joy",
		"note": "闹钟连续攻击的硬直时间缩短。",
		"bug": "周二玩家反馈自己被迫承接周一遗留任务。"
	},
	{
		"title": "通勤路径压缩",
		"tag": "城市",
		"body": "地铁、公交和步行路径获得更聪明的换乘算法。",
		"deltas": {"civilization": 10, "joy": 5, "stability": -8},
		"cost": 2,
		"risk": 10,
		"trust": 2,
		"primary": "civilization",
		"note": "早高峰碰撞盒被重新烘焙。",
		"bug": "少数电梯把第 13 层误判为剧情关卡。"
	},
	{
		"title": "梦境掉落表重做",
		"tag": "心理",
		"body": "普通梦境更像短片，噩梦不再连续暴击三晚。",
		"deltas": {"joy": 10, "stability": -5, "civilization": -1},
		"cost": 1,
		"risk": 6,
		"trust": 2,
		"primary": "joy",
		"note": "梦醒后五秒内会保留灵感碎片。",
		"bug": "部分玩家梦见补丁说明本身，循环风险待观察。"
	},
	{
		"title": "海洋蓝图回滚",
		"tag": "生态",
		"body": "珊瑚恢复速度提升，塑料漂浮物刷新率下降。",
		"deltas": {"ecology": 14, "civilization": -5, "stability": -3},
		"cost": 2,
		"risk": 7,
		"trust": 1,
		"primary": "ecology",
		"note": "鱼群寻路会避开大多数工业噪声。",
		"bug": "部分船只抱怨地图资源点变远。"
	},
	{
		"title": "科研队列加速",
		"tag": "科技",
		"body": "实验室产出提升，论文复现失败时给出更清晰报错。",
		"deltas": {"civilization": 14, "stability": -9, "ecology": -4},
		"cost": 2,
		"risk": 12,
		"trust": 3,
		"primary": "civilization",
		"note": "显微镜现在会正确显示“别急，再试一次”。",
		"bug": "后台出现大量“伦理委员会正在排队”。"
	},
	{
		"title": "森林静音补丁",
		"tag": "生态",
		"body": "林地噪声降低，鸟鸣和风声的声场重新混音。",
		"deltas": {"ecology": 9, "joy": 6, "civilization": -3},
		"cost": 1,
		"risk": 5,
		"trust": 2,
		"primary": "ecology",
		"note": "露营玩家的睡眠质量温和提升。",
		"bug": "有人误以为世界进入了加载界面。"
	},
	{
		"title": "社交冷却缩短",
		"tag": "社群",
		"body": "朋友之间重新开口的门槛下降，尴尬沉默时间减少。",
		"deltas": {"joy": 10, "civilization": 5, "stability": -6},
		"cost": 1,
		"risk": 8,
		"trust": 2,
		"primary": "joy",
		"note": "新增“我只是想起你了”的低消耗消息模板。",
		"bug": "部分群聊突然复活，通知量略高。"
	},
	{
		"title": "资源账本严查",
		"tag": "系统",
		"body": "高消耗行为会更快暴露代价，短期体验变硬。",
		"deltas": {"ecology": 12, "stability": 6, "civilization": -8, "joy": -5},
		"cost": 1,
		"risk": 4,
		"trust": -2,
		"primary": "stability",
		"note": "地球后台新增了一行“欠的迟早要还”。",
		"bug": "论坛中“真实感太强”帖子暴增。"
	},
	{
		"title": "随机善意刷新",
		"tag": "事件",
		"body": "陌生人帮忙、及时消息、刚好赶上的车概率上调。",
		"deltas": {"joy": 13, "stability": -3, "civilization": 2},
		"cost": 0,
		"risk": 9,
		"trust": 4,
		"primary": "joy",
		"note": "城市地图新增几乎不可见的温柔触发器。",
		"bug": "概率学玩家开始怀疑自己被剧情照顾。"
	},
	{
		"title": "物种协商协议",
		"tag": "生态",
		"body": "人类活动区和野生栖息地的边界重新计算。",
		"deltas": {"ecology": 10, "civilization": -3, "stability": 5},
		"cost": 1,
		"risk": 5,
		"trust": 1,
		"primary": "ecology",
		"note": "迁徙路线不再穿过那么多水泥迷宫。",
		"bug": "少数房地产任务链被标记为待审核。"
	},
	{
		"title": "创作灵感缓存",
		"tag": "文化",
		"body": "散步、洗澡和发呆时更容易拿到灵感碎片。",
		"deltas": {"joy": 8, "civilization": 7, "stability": -6},
		"cost": 1,
		"risk": 7,
		"trust": 3,
		"primary": "civilization",
		"note": "空白文档的威慑力小幅下降。",
		"bug": "睡前灵感仍然不会自动保存。"
	},
	{
		"title": "极端天气护栏",
		"tag": "气候",
		"body": "灾害峰值被压低，但需要暂停部分高耗能玩法。",
		"deltas": {"ecology": 15, "stability": 7, "civilization": -10, "joy": -4},
		"cost": 2,
		"risk": 5,
		"trust": -1,
		"primary": "ecology",
		"note": "新增长期主义提示音，音量非常克制。",
		"bug": "短线玩家表示这个版本不够刺激。"
	},
	{
		"title": "教育曲线重平衡",
		"tag": "成长",
		"body": "学习反馈更早出现，死记硬背收益降低。",
		"deltas": {"civilization": 10, "joy": 5, "stability": -5},
		"cost": 1,
		"risk": 7,
		"trust": 2,
		"primary": "civilization",
		"note": "好奇心从隐藏属性改为半公开属性。",
		"bug": "考试副本仍有过量压力残留。"
	},
	{
		"title": "夜空可见度提升",
		"tag": "宇宙",
		"body": "城市光污染略降，抬头看见星星的概率提升。",
		"deltas": {"joy": 7, "ecology": 7, "civilization": -2},
		"cost": 0,
		"risk": 4,
		"trust": 3,
		"primary": "joy",
		"note": "玩家获得短暂的宇宙尺度冷静。",
		"bug": "哲学讨论频道负载增加。"
	},
	{
		"title": "经济数值热平衡",
		"tag": "经济",
		"body": "过热增长被降温，基础生存压力略微回落。",
		"deltas": {"stability": 8, "joy": 4, "civilization": -5},
		"resources": {"ops": 2},
		"cost": 0,
		"risk": 6,
		"trust": 1,
		"primary": "stability",
		"note": "价格曲线开始承认普通人的存在。",
		"bug": "部分排行榜玩家质疑削弱过猛。"
	},
	{
		"title": "语言包扩容",
		"tag": "文化",
		"body": "更多方言、手势和沉默都能被识别为表达。",
		"deltas": {"civilization": 7, "joy": 7, "stability": -4},
		"cost": 1,
		"risk": 6,
		"trust": 3,
		"primary": "joy",
		"note": "误解不再默认升级为冲突。",
		"bug": "翻译系统偶尔会把叹气标注为诗。"
	},
	{
		"title": "微生物补丁日",
		"tag": "生物",
		"body": "土壤和肠道生态获得维护窗口。",
		"deltas": {"ecology": 8, "joy": 3, "stability": 6, "civilization": -3},
		"cost": 1,
		"risk": 3,
		"trust": 1,
		"primary": "stability",
		"note": "小到看不见的地方终于被认真测试。",
		"bug": "玩家很难直观看到更新，所以差评不少。"
	},
	{
		"title": "记忆碎片整理",
		"tag": "心理",
		"body": "旧遗憾不再随机弹窗，重要回忆更容易归档。",
		"deltas": {"joy": 10, "stability": 5, "civilization": -2},
		"cost": 1,
		"risk": 4,
		"trust": 2,
		"primary": "joy",
		"note": "新增“那时已经很努力了”的系统提示。",
		"bug": "怀旧滤镜偶尔过曝。"
	},
	{
		"title": "AI伦理协议热更新",
		"tag": "科技",
		"body": "自动化系统学会在提速前先问一句“这合适吗”。",
		"deltas": {"civilization": 9, "stability": 4, "joy": -3},
		"cost": 1,
		"risk": 9,
		"trust": 2,
		"primary": "civilization",
		"note": "决策日志新增了罕见的反省字段。",
		"bug": "部分模型开始申请周末，工单系统表示困惑。"
	},
	{
		"title": "睡眠服务器维护",
		"tag": "心理",
		"body": "深夜排队的思绪被限流，梦境加载时间略微缩短。",
		"deltas": {"joy": 11, "stability": 6, "civilization": -4},
		"cost": 1,
		"risk": 5,
		"trust": 2,
		"primary": "joy",
		"note": "枕头匹配算法终于承认脖子存在。",
		"bug": "少数玩家醒来后仍然记得凌晨三点的工单。"
	},
	{
		"title": "随机事件概率微调",
		"tag": "事件",
		"body": "糟糕巧合略降，刚好赶上最后一班车的概率上浮。",
		"deltas": {"joy": 6, "ecology": 3, "stability": -2},
		"cost": 0,
		"risk": 6,
		"trust": 3,
		"primary": "joy",
		"note": "小概率好事现在不会全部挤在别人账号里。",
		"bug": "统计学频道连续三天要求公开掉落表。"
	},
	{
		"title": "公共讨论降噪",
		"tag": "社群",
		"body": "高频重复争论被合并同类项，低声量事实获得短暂置顶。",
		"deltas": {"civilization": 6, "stability": 8, "joy": -4},
		"cost": 1,
		"risk": 7,
		"trust": 1,
		"primary": "stability",
		"note": "热搜算法学会了偶尔深呼吸。",
		"bug": "仍有人把冷静讨论误报为服务器无响应。"
	},
	{
		"title": "深海版本补光",
		"tag": "生态",
		"body": "深海任务线可见度提升，玩家第一次意识到地图还有负数楼层。",
		"deltas": {"ecology": 11, "civilization": 3, "stability": -6},
		"cost": 1,
		"risk": 8,
		"trust": 2,
		"primary": "ecology",
		"note": "冷泉和海沟获得更清晰的维护状态。",
		"bug": "部分海底居民投诉曝光过度。"
	},
]

var stats: Dictionary = {}
var resources: Dictionary = {}
var deck: Array = []
var offered_patches: Array = []
var patch_log: Array[String] = []
var patch_index := 0
var incident_heat := 0.0
var game_over := false
var patch_transitioning := false
var animate_cards_on_render := false
var last_tag := ""
var combo_count := 0
var last_snapshot: Dictionary = {}
var current_objective: Dictionary = {}
var selected_difficulty_key := "normal"
var final_success := false
var final_reason := ""
var sfx_players: Dictionary = {}
var sfx_frames: Dictionary = {}

var main_frame: MarginContainer
var start_screen: Control
var star_particles: CPUParticles2D
var difficulty_buttons: Dictionary = {}
var difficulty_summary_label: Label
var version_label: Label
var status_label: Label
var result_label: Label
var goal_label: Label
var earth_view: Control
var card_list: VBoxContainer
var log_list: VBoxContainer
var stat_bars: Dictionary = {}
var stat_values: Dictionary = {}
var resource_labels: Dictionary = {}
var maintenance_button: Button
var hotfix_button: Button
var rollback_button: Button


func _ready() -> void:
	randomize()
	_build_audio()
	_build_layout()
	_build_start_screen()
	_select_difficulty(selected_difficulty_key)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_star_particles()


func _build_layout() -> void:
	var background := ColorRect.new()
	background.color = BG_COLOR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	main_frame = MarginContainer.new()
	main_frame.visible = false
	main_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_frame.add_theme_constant_override("margin_left", 24)
	main_frame.add_theme_constant_override("margin_top", 22)
	main_frame.add_theme_constant_override("margin_right", 24)
	main_frame.add_theme_constant_override("margin_bottom", 22)
	add_child(main_frame)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	main_frame.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := _label("地球 Online：补丁说明", 34, Color(0.96, 0.98, 1.0))
	title_box.add_child(title)

	status_label = _label("", 16, Color(0.68, 0.75, 0.78), true)
	title_box.add_child(status_label)

	version_label = _label("", 20, Color(0.92, 0.84, 0.62))
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(version_label)

	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 16)
	root.add_child(main)

	main.add_child(_build_world_panel())
	main.add_child(_build_patch_panel())
	main.add_child(_build_log_panel())


func _build_start_screen() -> void:
	start_screen = Control.new()
	start_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(start_screen)

	star_particles = CPUParticles2D.new()
	star_particles.amount = 220
	star_particles.lifetime = 5.5
	star_particles.preprocess = 5.5
	star_particles.emitting = true
	star_particles.direction = Vector2(0, 1)
	star_particles.spread = 180.0
	star_particles.gravity = Vector2(0, 0)
	star_particles.initial_velocity_min = 3.0
	star_particles.initial_velocity_max = 14.0
	star_particles.scale_amount_min = 0.4
	star_particles.scale_amount_max = 1.7
	star_particles.color = Color(0.72, 0.92, 1.0, 0.7)
	star_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	start_screen.add_child(star_particles)
	_update_star_particles()

	var veil := ColorRect.new()
	veil.color = Color(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, 0.42)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen.add_child(veil)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(760, 0)
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var title := _label("地球 Online：补丁说明", 48, Color(0.96, 0.98, 1.0), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var flavor := _label("你是地球 Online 的值班运营，不是神。你能做的只有合补丁、看日志、压事故，然后假装这一切早在路线图里。", 18, Color(0.74, 0.86, 0.88), true)
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(flavor)

	var difficulty_row := HBoxContainer.new()
	difficulty_row.alignment = BoxContainer.ALIGNMENT_CENTER
	difficulty_row.add_theme_constant_override("separation", 10)
	box.add_child(difficulty_row)

	for difficulty in DIFFICULTIES:
		var button := _action_button(str(difficulty["label"]))
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(170, 48)
		var difficulty_key := str(difficulty["key"])
		button.pressed.connect(func() -> void: _select_difficulty(difficulty_key))
		difficulty_buttons[difficulty_key] = button
		difficulty_row.add_child(button)

	difficulty_summary_label = _label("", 15, Color(0.92, 0.84, 0.62), true)
	difficulty_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(difficulty_summary_label)

	var start_button := Button.new()
	start_button.text = "开始运营"
	start_button.custom_minimum_size = Vector2(220, 54)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.add_theme_stylebox_override("normal", _button_style(Color(0.32, 0.24, 0.13)))
	start_button.add_theme_stylebox_override("hover", _button_style(Color(0.45, 0.33, 0.16)))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color(0.19, 0.14, 0.08)))
	start_button.add_theme_color_override("font_color", Color(0.98, 0.93, 0.76))
	start_button.pressed.connect(_begin_selected_run)
	box.add_child(start_button)


func _update_star_particles() -> void:
	if not is_instance_valid(star_particles):
		return
	var viewport_size := get_viewport_rect().size
	star_particles.position = viewport_size * 0.5
	star_particles.emission_rect_extents = viewport_size * 0.56


func _select_difficulty(key: String) -> void:
	selected_difficulty_key = key
	for button_key in difficulty_buttons.keys():
		var button := difficulty_buttons[button_key] as Button
		var is_selected := str(button_key) == key
		button.button_pressed = is_selected
		if is_selected:
			button.add_theme_stylebox_override("normal", _button_style(Color(0.3, 0.24, 0.13)))
			button.add_theme_stylebox_override("hover", _button_style(Color(0.4, 0.31, 0.16)))
			button.add_theme_stylebox_override("pressed", _button_style(Color(0.36, 0.27, 0.14)))
		else:
			button.add_theme_stylebox_override("normal", _button_style(Color(0.15, 0.2, 0.23)))
			button.add_theme_stylebox_override("hover", _button_style(Color(0.2, 0.28, 0.32)))
			button.add_theme_stylebox_override("pressed", _button_style(Color(0.1, 0.15, 0.18)))

	if is_instance_valid(difficulty_summary_label):
		difficulty_summary_label.text = str(_current_difficulty()["summary"])


func _begin_selected_run() -> void:
	_play_sfx("click")
	start_screen.visible = false
	main_frame.visible = true
	_start_run()


func _build_world_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.042, 0.073, 0.061), Color(0.16, 0.31, 0.24)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	box.add_child(_label("世界仪表盘", 22, Color(0.93, 0.97, 1.0)))

	earth_view = EarthView.new()
	earth_view.custom_minimum_size = Vector2(280, 160)
	earth_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(earth_view)

	for stat_def in STAT_DEFS:
		box.add_child(_build_stat_row(stat_def))

	var separator := HSeparator.new()
	box.add_child(separator)

	var resources_grid := GridContainer.new()
	resources_grid.columns = 2
	resources_grid.add_theme_constant_override("h_separation", 10)
	resources_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(resources_grid)

	for resource_def in RESOURCE_DEFS:
		var key := str(resource_def["key"])
		var label := _label("", 15, Color(0.9, 0.92, 0.88))
		label.custom_minimum_size = Vector2(130, 26)
		label.tooltip_text = _resource_tip(key)
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		resource_labels[key] = label
		resources_grid.add_child(label)

	var heat_label := _label("", 15, Color(0.95, 0.72, 0.64))
	heat_label.custom_minimum_size = Vector2(130, 26)
	heat_label.tooltip_text = "事故热度越高，随机事故越容易触发；满值会直接停服。"
	heat_label.mouse_filter = Control.MOUSE_FILTER_STOP
	resource_labels["heat"] = heat_label
	resources_grid.add_child(heat_label)

	var combo_label := _label("", 15, Color(0.7, 0.86, 0.95))
	combo_label.custom_minimum_size = Vector2(130, 26)
	combo_label.tooltip_text = "连续合入同类补丁会先形成专题收益，过量后会变成专题疲劳。"
	combo_label.mouse_filter = Control.MOUSE_FILTER_STOP
	resource_labels["combo"] = combo_label
	resources_grid.add_child(combo_label)

	return panel


func _build_stat_row(stat_def: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 5)

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	row.add_child(line)

	var name := _label(str(stat_def["label"]), 15, Color(0.84, 0.9, 0.9))
	name.custom_minimum_size = Vector2(54, 0)
	name.tooltip_text = _stat_tip(str(stat_def["key"]))
	name.mouse_filter = Control.MOUSE_FILTER_STOP
	line.add_child(name)

	var value := _label("00", 15, Color(0.95, 0.97, 1.0))
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.tooltip_text = _stat_tip(str(stat_def["key"]))
	value.mouse_filter = Control.MOUSE_FILTER_STOP
	line.add_child(value)

	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	bar.add_theme_stylebox_override("background", _bar_style(Color(0.095, 0.105, 0.1)))
	bar.add_theme_stylebox_override("fill", _bar_style(stat_def["color"]))
	bar.tooltip_text = _stat_tip(str(stat_def["key"]))
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(bar)

	stat_bars[str(stat_def["key"])] = bar
	stat_values[str(stat_def["key"])] = value
	return row


func _build_patch_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.078, 0.065, 0.052), Color(0.32, 0.24, 0.15)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	box.add_child(_label("本次候选补丁", 22, Color(0.96, 0.93, 0.86)))

	goal_label = _label("", 15, Color(0.86, 0.88, 0.78), true)
	goal_label.add_theme_stylebox_override("normal", _label_box_style(Color(0.11, 0.095, 0.075), Color(0.28, 0.22, 0.15)))
	box.add_child(goal_label)

	result_label = _label("", 17, Color(0.94, 0.88, 0.66), true)
	result_label.visible = false
	box.add_child(result_label)

	var card_scroll := ScrollContainer.new()
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(card_scroll)

	card_list = VBoxContainer.new()
	card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_list.add_theme_constant_override("separation", 10)
	card_scroll.add_child(card_list)

	return panel


func _build_log_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(355, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.052, 0.056, 0.07), Color(0.19, 0.22, 0.3)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	box.add_child(_label("版本日志", 22, Color(0.93, 0.97, 1.0)))

	var action_box := VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 8)
	box.add_child(action_box)

	maintenance_button = _action_button("开维护窗")
	maintenance_button.pressed.connect(_open_maintenance_window)
	action_box.add_child(maintenance_button)

	hotfix_button = _action_button("紧急热修")
	hotfix_button.pressed.connect(_run_hotfix)
	action_box.add_child(hotfix_button)

	rollback_button = _action_button("回滚上一版")
	rollback_button.pressed.connect(_rollback_last_patch)
	action_box.add_child(rollback_button)

	var log_scroll := ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(log_scroll)

	log_list = VBoxContainer.new()
	log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_list.add_theme_constant_override("separation", 9)
	log_scroll.add_child(log_list)

	var restart := Button.new()
	restart.text = "重新开服"
	restart.custom_minimum_size = Vector2(0, 44)
	restart.add_theme_stylebox_override("normal", _button_style(Color(0.2, 0.25, 0.18)))
	restart.add_theme_stylebox_override("hover", _button_style(Color(0.26, 0.33, 0.22)))
	restart.add_theme_stylebox_override("pressed", _button_style(Color(0.14, 0.19, 0.13)))
	restart.pressed.connect(_start_run)
	box.add_child(restart)

	return panel


func _start_run() -> void:
	stats = _starting_stats_for_difficulty()
	resources = _starting_resources_for_difficulty()
	patch_index = 0
	incident_heat = 0.0
	game_over = false
	patch_transitioning = false
	last_tag = ""
	combo_count = 0
	last_snapshot = {}
	final_success = false
	final_reason = ""
	patch_log = [
		"v2.00 内测服开放。难度：%s。现在你不是神，你是地球 Online 的值班运营。" % _difficulty_label(),
	]
	_build_deck()
	_set_next_objective()
	_deal_patches()
	result_label.text = ""
	result_label.visible = false
	_refresh_ui()


func _build_deck() -> void:
	deck = CARD_POOL.duplicate(true)
	deck.shuffle()


func _deal_patches() -> void:
	offered_patches.clear()
	if deck.size() < 3:
		_build_deck()

	while offered_patches.size() < 3 and deck.size() > 0:
		offered_patches.append(deck.pop_back())
	animate_cards_on_render = true


func _apply_patch(patch: Dictionary) -> void:
	if game_over:
		patch_transitioning = false
		return

	var cost := int(patch.get("cost", 0))
	if int(resources["ops"]) < cost:
		patch_log.push_front("预算不足：这个补丁还在排队，财务模块假装没看见。")
		patch_transitioning = false
		_refresh_ui()
		return

	last_snapshot = stats.duplicate()
	resources["ops"] = int(resources["ops"]) - cost
	patch_index += 1

	var math := _patch_math(patch)
	var deltas := math["deltas"] as Dictionary
	for key in deltas.keys():
		_add_stat(str(key), float(deltas[key]))

	_apply_resource_deltas(patch.get("resources", {}) as Dictionary)
	_add_resource("trust", int(math["trust"]))
	_apply_pressure_rules()

	var risk := int(math["risk"])
	var heat_gain := float(risk) + maxf(0.0, 50.0 - float(stats["stability"])) * 0.09
	incident_heat = clampf(incident_heat + heat_gain * _heat_growth_multiplier(), 0.0, 100.0)
	_update_combo_state(str(patch["tag"]))

	patch_log.push_front(_compose_patch_log(patch, math))
	_maybe_trigger_incident(patch)
	_maybe_resolve_objective()

	var stop_reason := _get_stop_reason()
	if stop_reason != "":
		_finish_run(false, stop_reason)
	elif patch_index >= MAX_PATCHES:
		_finish_run(_final_success(), _final_message())
	else:
		_deal_patches()

	patch_transitioning = false
	_refresh_ui()


func _open_maintenance_window() -> void:
	if game_over or int(resources["maintenance"]) <= 0:
		return

	resources["maintenance"] = int(resources["maintenance"]) - 1
	_add_stat("stability", 8.0)
	_add_stat("joy", -2.0)
	_add_resource("trust", -2)
	incident_heat = maxf(0.0, incident_heat - 12.0)
	patch_log.push_front("维护窗口：稳定 +8，事故热度下降。但玩家发现自己又要等进度条。")
	_refresh_ui()


func _run_hotfix() -> void:
	if game_over or int(resources["ops"]) < 2:
		return

	resources["ops"] = int(resources["ops"]) - 2
	var worst_key := _lowest_stat_key()
	_add_stat(worst_key, 10.0)
	_add_resource("trust", 1)
	incident_heat = clampf(incident_heat + 6.0 * _heat_growth_multiplier(), 0.0, 100.0)
	patch_log.push_front("紧急热修：%s +10，口碑 +1。代码是热的，事故热度也热了。" % _stat_label(worst_key))
	_refresh_ui()


func _rollback_last_patch() -> void:
	if game_over or int(resources["rollback"]) <= 0 or last_snapshot.is_empty():
		return

	resources["rollback"] = int(resources["rollback"]) - 1
	for key in stats.keys():
		if last_snapshot.has(key):
			stats[key] = lerpf(float(stats[key]), float(last_snapshot[key]), 0.8)
	_add_resource("trust", -8)
	incident_heat = maxf(0.0, incident_heat - 12.0)
	patch_log.push_front("版本回滚：世界回到上一份快照的 80%，口碑 -8。玩家最讨厌的不是回滚，是假装没回滚。")
	_deal_patches()
	_refresh_ui()


func _patch_math(patch: Dictionary) -> Dictionary:
	var deltas: Dictionary = (patch["deltas"] as Dictionary).duplicate()
	var risk := int(patch.get("risk", 0))
	var trust := int(patch.get("trust", 0))
	var tag := str(patch.get("tag", ""))
	var primary := str(patch.get("primary", "joy"))
	var combo_text := ""

	if last_tag == tag and combo_count == 1:
		_add_delta(deltas, primary, 4.0)
		risk = max(0, risk - 3)
		trust += 2
		combo_text = "专题二连：主属性 +4，风险 -3，口碑 +2。"
	elif last_tag == tag and combo_count >= 2:
		_add_delta(deltas, "joy", -3.0)
		risk += 7
		trust -= 2
		combo_text = "专题疲劳：同类补丁太多，快乐 -3，风险 +7。"
	elif last_tag != "" and combo_count >= 2:
		risk = max(0, risk - 2)
		combo_text = "换题降噪：结束专题连更，风险 -2。"
	risk = _scaled_risk(risk)

	return {
		"deltas": deltas,
		"risk": risk,
		"trust": trust,
		"combo_text": combo_text,
	}


func _update_combo_state(tag: String) -> void:
	if last_tag == tag:
		combo_count += 1
	else:
		last_tag = tag
		combo_count = 1


func _apply_pressure_rules() -> void:
	if float(stats["civilization"]) > 82.0 and float(stats["ecology"]) < 38.0:
		_add_stat("stability", -6.0)
		incident_heat = clampf(incident_heat + 5.0 * _heat_growth_multiplier(), 0.0, 100.0)
		patch_log.push_front("后台警报：文明和生态发生资源锁冲突，稳定 -6，事故热度上升。")
	if float(stats["joy"]) < 28.0:
		_add_stat("civilization", -4.0)
		patch_log.push_front("后台警报：低快乐降低协作效率，文明 -4。")
	if float(stats["ecology"]) > 78.0 and float(stats["joy"]) > 70.0:
		_add_stat("stability", 4.0)
		patch_log.push_front("正反馈：生态和快乐互相回血，稳定 +4。")
	_apply_crisis_drain()


func _apply_crisis_drain() -> void:
	for stat_def in STAT_DEFS:
		var key := str(stat_def["key"])
		if float(stats[key]) < CRISIS_THRESHOLD:
			_add_stat(key, -3.0)
			var label := str(stat_def["label"])
			patch_log.push_front("危机警告：%s 低于 %.0f 点，持续下滑中（本回合 -3）。再不干预就要停服了。" % [label, CRISIS_THRESHOLD])


func _set_next_objective() -> void:
	current_objective = (OBJECTIVES[randi() % OBJECTIVES.size()] as Dictionary).duplicate(true)
	current_objective["due"] = mini(patch_index + 3, MAX_PATCHES)


func _maybe_resolve_objective() -> void:
	if current_objective.is_empty() or patch_index < int(current_objective["due"]):
		return

	var checks := current_objective["checks"] as Dictionary
	var passed := true
	for key in checks.keys():
		if float(stats[str(key)]) < float(checks[key]):
			passed = false
			break

	if passed:
		_apply_resource_deltas(current_objective["reward"] as Dictionary)
		patch_log.push_front("季度验收通过：%s。奖励：%s。" % [str(current_objective["title"]), str(current_objective["reward_text"])])
		_play_sfx("quarter_pass")
	else:
		_apply_mixed_penalty(current_objective["fail"] as Dictionary)
		patch_log.push_front("季度验收失败：%s。惩罚：%s。" % [str(current_objective["title"]), str(current_objective["fail_text"])])
		_play_sfx("quarter_fail")

	if patch_index < MAX_PATCHES:
		_set_next_objective()


func _apply_mixed_penalty(values: Dictionary) -> void:
	for key in values.keys():
		var key_text := str(key)
		if stats.has(key_text):
			_add_stat(key_text, float(values[key]))
		else:
			_add_resource(key_text, int(values[key]))


func _apply_resource_deltas(values: Dictionary) -> void:
	for key in values.keys():
		_add_resource(str(key), int(values[key]))


func _add_delta(deltas: Dictionary, key: String, amount: float) -> void:
	var current := 0.0
	if deltas.has(key):
		current = float(deltas[key])
	deltas[key] = current + amount


func _add_stat(key: String, amount: float) -> void:
	stats[key] = clampf(float(stats[key]) + amount, 0.0, 100.0)


func _add_resource(key: String, amount: int) -> void:
	if not resources.has(key):
		resources[key] = 0
	var max_value := 100
	if key == "ops":
		max_value = 12
	elif key == "maintenance":
		max_value = 5
	elif key == "rollback":
		max_value = 3
	resources[key] = clampi(int(resources[key]) + amount, 0, max_value)


func _get_stop_reason() -> String:
	for stat_def in STAT_DEFS:
		var key := str(stat_def["key"])
		if float(stats[key]) <= FAIL_LIMIT:
			return "%s归零，世界进入紧急停服。" % str(stat_def["label"])
	if int(resources["trust"]) <= 0:
		return "口碑归零，玩家集体把地球 Online 打成“多半差评”。"
	if incident_heat >= 100.0:
		return "事故热度爆表，后台日志开始自己写遗书。"
	return ""


func _finish_run(success: bool, reason: String) -> void:
	game_over = true
	final_success = success
	final_reason = reason
	if success:
		result_label.text = "发布成功：%s" % reason
	else:
		result_label.text = "停服公告：%s" % reason
	result_label.visible = true
	_play_sfx("game_over")


func _final_success() -> bool:
	var diff := _current_difficulty()
	return int(resources["trust"]) >= int(diff.get("victory_trust", 45)) and float(stats[_lowest_stat_key()]) >= float(diff.get("victory_stat", 28.0))


func _final_message() -> String:
	if _final_success():
		return "十二个版本后，地球 Online 仍然不完美，但玩家愿意继续等下个补丁。"
	return "十二个版本发完了，但世界像一台带着胶带运行的老服务器。算上线，算惊险。"


func _refresh_ui() -> void:
	version_label.text = "%s / %s · %s" % [_version_name(), MAX_PATCHES, _difficulty_label()]
	status_label.text = _world_status_line()
	goal_label.text = _objective_text()

	for stat_def in STAT_DEFS:
		var key := str(stat_def["key"])
		var value := int(round(float(stats[key])))
		(stat_bars[key] as ProgressBar).value = value
		(stat_values[key] as Label).text = str(value)

	for resource_def in RESOURCE_DEFS:
		var resource_key := str(resource_def["key"])
		var resource_label := resource_labels[resource_key] as Label
		resource_label.text = "%s %s" % [str(resource_def["label"]), int(resources[resource_key])]

	(resource_labels["heat"] as Label).text = "事故热度 %s" % int(round(incident_heat))
	(resource_labels["combo"] as Label).text = _combo_text()

	earth_view.set_world_state(stats, patch_index, game_over)
	_update_action_buttons()
	_render_cards()
	_render_logs()


func _update_action_buttons() -> void:
	maintenance_button.text = "开维护窗  稳定+12  剩余%s" % int(resources["maintenance"])
	maintenance_button.disabled = game_over or int(resources["maintenance"]) <= 0

	hotfix_button.text = "紧急热修  最低项+10  预算2"
	hotfix_button.disabled = game_over or int(resources["ops"]) < 2

	rollback_button.text = "回滚上一版  剩余%s" % int(resources["rollback"])
	rollback_button.disabled = game_over or int(resources["rollback"]) <= 0 or last_snapshot.is_empty()


func _render_cards() -> void:
	_clear_children(card_list)

	if game_over:
		card_list.add_child(_build_end_summary_panel())
		return

	var should_animate := animate_cards_on_render
	animate_cards_on_render = false
	var card_number := 0
	for patch_variant in offered_patches:
		var patch := patch_variant as Dictionary
		var card := _build_patch_card(patch)
		card_list.add_child(card)
		if should_animate:
			_animate_card_enter(card, card_number)
		card_number += 1


func _build_patch_card(patch: Dictionary) -> Control:
	var math := _patch_math(patch)
	var can_afford := int(resources["ops"]) >= int(patch.get("cost", 0))

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border_color := Color(0.29, 0.25, 0.19)
	if not can_afford:
		border_color = Color(0.24, 0.16, 0.16)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.103, 0.095, 0.083), border_color))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 13)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 13)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	box.add_child(top)

	var title := _label(str(patch["title"]), 20, Color(0.98, 0.96, 0.9), true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	var tag := _label(str(patch["tag"]), 14, Color(0.68, 0.8, 0.76))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.custom_minimum_size = Vector2(58, 0)
	top.add_child(tag)

	box.add_child(_label(str(patch["body"]), 15, Color(0.76, 0.78, 0.74), true))
	box.add_child(_label(_delta_text(math["deltas"] as Dictionary), 15, Color(0.86, 0.94, 0.78), true))
	var meta := _label(_card_meta_text(patch, math), 14, Color(0.95, 0.78, 0.58), true)
	meta.tooltip_text = "风险值会推高事故热度；当前难度已经计入风险修正。"
	meta.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(meta)

	var combo := str(math["combo_text"])
	if combo != "":
		box.add_child(_label(combo, 14, Color(0.68, 0.86, 0.94), true))

	var apply := Button.new()
	apply.text = "合入此补丁" if can_afford else "预算不足"
	apply.disabled = not can_afford
	apply.custom_minimum_size = Vector2(0, 42)
	apply.add_theme_stylebox_override("normal", _button_style(Color(0.29, 0.22, 0.14)))
	apply.add_theme_stylebox_override("hover", _button_style(Color(0.4, 0.29, 0.17)))
	apply.add_theme_stylebox_override("pressed", _button_style(Color(0.18, 0.14, 0.09)))
	apply.add_theme_stylebox_override("disabled", _button_style(Color(0.12, 0.1, 0.09)))
	apply.add_theme_color_override("font_color", Color(0.98, 0.96, 0.88))
	var patch_data := patch
	apply.pressed.connect(func() -> void: _choose_patch_with_animation(patch_data, panel))
	box.add_child(apply)

	return panel


func _build_end_summary_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.08, 0.075), Color(0.5, 0.38, 0.19)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	box.add_child(_label("结算报告  评价 %s" % _grade_rank(), 24, Color(0.98, 0.92, 0.68), true))
	var summary := _label(_final_result_text(), 16, Color(0.88, 0.91, 0.88), true)
	box.add_child(summary)

	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(stats_grid)

	for stat_def in STAT_DEFS:
		var key := str(stat_def["key"])
		var stat_line := _label("%s  %s/100" % [str(stat_def["label"]), int(round(float(stats[key])))], 16, stat_def["color"])
		stat_line.tooltip_text = _stat_tip(key)
		stat_line.mouse_filter = Control.MOUSE_FILTER_STOP
		stats_grid.add_child(stat_line)

	box.add_child(_label("版本日志回顾", 18, Color(0.93, 0.97, 1.0)))
	for entry in _log_review_lines():
		box.add_child(_label(entry, 14, Color(0.76, 0.81, 0.86), true))

	box.add_child(_label("补丁线已冻结。右侧可以重新开服，再做一版更会运营的地球。", 16, Color(0.96, 0.9, 0.72), true))
	return panel


func _choose_patch_with_animation(patch: Dictionary, card: Control) -> void:
	if game_over or patch_transitioning:
		return
	patch_transitioning = true
	_play_sfx("click")
	card.pivot_offset = card.size * 0.5

	for child in card_list.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2(1.035, 1.035), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 0.0, 0.16).set_delay(0.05)
	tween.tween_property(card, "position:y", card.position.y - 10.0, 0.16).set_delay(0.05)
	tween.finished.connect(func() -> void: _apply_patch(patch))


func _animate_card_enter(card: Control, index: int) -> void:
	call_deferred("_play_card_enter_animation", card, index)


func _play_card_enter_animation(card: Control, index: int) -> void:
	if not is_instance_valid(card) or card.is_queued_for_deletion():
		return
	var target_position := card.position
	card.position = target_position + Vector2(0, 28)
	card.modulate.a = 0.0

	var delay := float(index) * 0.045
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", target_position, 0.2).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.16).set_delay(delay)


func _render_logs() -> void:
	_clear_children(log_list)
	for entry in patch_log:
		var item := PanelContainer.new()
		item.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.075, 0.087), Color(0.15, 0.17, 0.22), 6))
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 10)
		item.add_child(margin)
		margin.add_child(_label(entry, 14, Color(0.76, 0.81, 0.86), true))
		log_list.add_child(item)


func _compose_patch_log(patch: Dictionary, math: Dictionary) -> String:
	var resource_text := _resource_delta_text(patch.get("resources", {}) as Dictionary)
	var combo := str(math["combo_text"])
	var line := "%s %s：%s 玩家反馈：%s" % [_version_name(), str(patch["title"]), str(patch["note"]), str(patch["bug"])]
	line += "  口碑 %+d，风险 %d。" % [int(math["trust"]), int(math["risk"])]
	if resource_text != "":
		line += " " + resource_text
	if combo != "":
		line += " " + combo
	return line


func _delta_text(deltas: Dictionary) -> String:
	var parts: Array[String] = []
	for stat_def in STAT_DEFS:
		var key := str(stat_def["key"])
		if deltas.has(key):
			var value := int(round(float(deltas[key])))
			var sign := "+" if value > 0 else ""
			parts.append("%s %s%s" % [str(stat_def["label"]), sign, value])

	return "   ".join(parts)


func _resource_delta_text(values: Dictionary) -> String:
	var parts: Array[String] = []
	for key in values.keys():
		var amount := int(values[key])
		var sign := "+" if amount > 0 else ""
		parts.append("%s %s%s" % [_resource_label(str(key)), sign, amount])
	return "   ".join(parts)


func _card_meta_text(patch: Dictionary, math: Dictionary) -> String:
	var cost := int(patch.get("cost", 0))
	var trust := int(math["trust"])
	var trust_sign := "+" if trust > 0 else ""
	var resource_text := _resource_delta_text(patch.get("resources", {}) as Dictionary)
	var text := "预算 %s   风险 %s   口碑 %s%s" % [cost, int(math["risk"]), trust_sign, trust]
	if resource_text != "":
		text += "   " + resource_text
	return text


func _final_result_text() -> String:
	var title := "发布成功" if final_success else "停服公告"
	var lowest_key := _lowest_stat_key()
	return "%s：%s\n口碑 %s，最低属性 %s %s。评价等级按口碑和最低属性共同结算。" % [
		title,
		final_reason,
		int(resources["trust"]),
		_stat_label(lowest_key),
		int(round(float(stats[lowest_key]))),
	]


func _grade_rank() -> String:
	var trust := int(resources["trust"])
	var lowest := int(round(float(stats[_lowest_stat_key()])))
	if trust >= 78 and lowest >= 70:
		return "S"
	if trust >= 62 and lowest >= 55:
		return "A"
	if trust >= 45 and lowest >= 40:
		return "B"
	if trust >= 25 and lowest >= 25:
		return "C"
	return "D"


func _log_review_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("共发布 %s/%s 个版本，累计 %s 条后台日志。" % [patch_index, MAX_PATCHES, patch_log.size()])
	var count := mini(4, patch_log.size())
	for i in count:
		lines.append("- " + _shorten_text(str(patch_log[i]), 72))
	return lines


func _shorten_text(text: String, limit: int) -> String:
	if text.length() <= limit:
		return text
	return text.substr(0, max(0, limit - 3)) + "..."


func _current_difficulty() -> Dictionary:
	for difficulty in DIFFICULTIES:
		var item := difficulty as Dictionary
		if str(item["key"]) == selected_difficulty_key:
			return item
	return DIFFICULTIES[1] as Dictionary


func _difficulty_label() -> String:
	return str(_current_difficulty()["label"])


func _starting_stats_for_difficulty() -> Dictionary:
	var values: Dictionary = {}
	var configured := _current_difficulty()["stats"] as Dictionary
	for stat_def in STAT_DEFS:
		var key := str(stat_def["key"])
		values[key] = float(configured.get(key, STARTING_STATS[key]))
	return values


func _starting_resources_for_difficulty() -> Dictionary:
	var values: Dictionary = {}
	var configured := _current_difficulty()["resources"] as Dictionary
	for resource_def in RESOURCE_DEFS:
		var key := str(resource_def["key"])
		values[key] = int(configured.get(key, STARTING_RESOURCES[key]))
	return values


func _scaled_risk(risk: int) -> int:
	return max(0, int(round(float(risk) * float(_current_difficulty()["risk_multiplier"]))))


func _heat_growth_multiplier() -> float:
	return float(_current_difficulty()["heat_multiplier"])


func _incident_threshold() -> float:
	return maxf(10.0, 20.0 + randf() * 14.0 + float(_current_difficulty()["threshold_offset"]))


func _maybe_trigger_incident(patch: Dictionary) -> void:
	var threshold := _incident_threshold()
	var force_trigger := incident_heat >= 65.0
	if not force_trigger and incident_heat < threshold:
		return

	var incident := INCIDENTS[randi() % INCIDENTS.size()] as Dictionary
	var deltas := incident["deltas"] as Dictionary
	for key in deltas.keys():
		_add_stat(str(key), float(deltas[key]))

	_add_resource("trust", int(incident.get("trust", 0)))
	incident_heat = maxf(0.0, incident_heat - float(incident.get("cooldown", 10)))
	var force_note := " [热度强制触发]" if force_trigger else ""
	patch_log.push_front("事故：%s。%s%s" % [str(incident["title"]), str(incident["body"]), force_note])
	_play_sfx("warning")


func _stat_tip(key: String) -> String:
	match key:
		"civilization":
			return "文明代表科技、协作和制度成熟度；过低会让系统退化成临时群聊。"
		"ecology":
			return "生态代表自然系统余量；过低时很多补丁会开始互相报错。"
		"joy":
			return "快乐代表玩家愿不愿意继续登录；过低会拖累文明效率。"
		"stability":
			return "稳定代表后台承压能力；越低越容易积累事故热度。"
	return "未知指标。"


func _resource_tip(key: String) -> String:
	match key:
		"trust":
			return "口碑是玩家还愿不愿意相信运营的程度；归零会停服。"
		"ops":
			return "预算用于合入补丁和紧急热修；预算不足时好主意只能排队。"
		"maintenance":
			return "维护窗可换取稳定并降低事故热度，但会消耗玩家耐心。"
		"rollback":
			return "回滚令能撤回上一版属性快照，但口碑会受损。"
	return "运营资源。"


func _world_status_line() -> String:
	if game_over:
		return "维护窗口已开启。最后一个版本会被写进地球后台的长日志里。"

	var lowest_key := _lowest_stat_key()
	var lowest_value := float(stats[lowest_key])
	if incident_heat > 55.0:
		return "事故热度偏高，下一条高风险补丁可能把后台点着。"
	if lowest_value < 24.0:
		return "%s告急，玩家已经开始在论坛写长帖。" % _stat_label(lowest_key)
	if int(resources["ops"]) <= 1:
		return "预算快见底了，便宜补丁和经济补丁突然变得很性感。"
	if float(stats["ecology"]) > 74.0 and float(stats["joy"]) > 64.0:
		return "风景和心情都在回血，地球服务器暂时有点像理想版本。"
	return "运营中。盯住季度目标，也别让事故热度滚起来。"


func _objective_text() -> String:
	if current_objective.is_empty():
		return ""
	var remain := int(current_objective["due"]) - patch_index
	return "%s\n%s\n剩余 %s 个版本；奖励：%s；失败：%s" % [
		str(current_objective["title"]),
		str(current_objective["text"]),
		remain,
		str(current_objective["reward_text"]),
		str(current_objective["fail_text"]),
	]


func _combo_text() -> String:
	if last_tag == "":
		return "专题 --"
	return "专题 %s x%s" % [last_tag, combo_count]


func _lowest_stat_key() -> String:
	var lowest_key := "stability"
	var lowest_value := 101.0
	for stat_def in STAT_DEFS:
		var key := str(stat_def["key"])
		if float(stats[key]) < lowest_value:
			lowest_value = float(stats[key])
			lowest_key = key
	return lowest_key


func _stat_label(key: String) -> String:
	for stat_def in STAT_DEFS:
		if str(stat_def["key"]) == key:
			return str(stat_def["label"])
	return key


func _resource_label(key: String) -> String:
	for resource_def in RESOURCE_DEFS:
		if str(resource_def["key"]) == key:
			return str(resource_def["label"])
	return key


func _version_name() -> String:
	return "v2.%02d" % patch_index


func _build_audio() -> void:
	_cache_sfx("click", 620.0, 740.0, 0.07, 0.08)
	_cache_sfx("warning", 880.0, 420.0, 0.28, 0.1)
	_cache_sfx("quarter_pass", 620.0, 930.0, 0.18, 0.09)
	_cache_sfx("quarter_fail", 260.0, 170.0, 0.24, 0.09)
	_cache_sfx("game_over", 180.0, 520.0, 0.42, 0.1)


func _cache_sfx(name: String, start_frequency: float, end_frequency: float, duration: float, volume: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SFX_MIX_RATE
	stream.buffer_length = duration + 0.08

	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)

	sfx_players[name] = player
	sfx_frames[name] = _make_sine_frames(start_frequency, end_frequency, duration, volume)


func _make_sine_frames(start_frequency: float, end_frequency: float, duration: float, volume: float) -> PackedVector2Array:
	var frame_count: int = max(1, int(float(SFX_MIX_RATE) * duration))
	var fade_count: int = max(1, int(float(SFX_MIX_RATE) * 0.012))
	var frames := PackedVector2Array()
	frames.resize(frame_count)

	for i in frame_count:
		var progress := float(i) / float(frame_count)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		var fade := minf(1.0, float(i) / float(fade_count))
		fade = minf(fade, float(frame_count - i - 1) / float(fade_count))
		fade = clampf(fade, 0.0, 1.0)
		var sample := sin(TAU * frequency * float(i) / float(SFX_MIX_RATE)) * volume * fade
		frames[i] = Vector2(sample, sample)
	return frames


func _play_sfx(name: String) -> void:
	if not sfx_players.has(name):
		return

	var player := sfx_players[name] as AudioStreamPlayer
	var frames: PackedVector2Array = sfx_frames[name]
	player.stop()
	player.play()

	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	for frame in frames:
		playback.push_frame(frame)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _label(text: String, size: int, color: Color, autowrap := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if autowrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.15, 0.2, 0.23)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.2, 0.28, 0.32)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.1, 0.15, 0.18)))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.08, 0.09, 0.1)))
	return button


func _panel_style(bg: Color, border: Color, radius := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


func _label_box_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(bg, border, 7)
	style.content_margin_left = 10
	style.content_margin_top = 9
	style.content_margin_right = 10
	style.content_margin_bottom = 9
	return style


func _button_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(7)
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _bar_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(6)
	return style
