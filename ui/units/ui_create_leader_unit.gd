extends PanelContainer
class_name UICreateLeaderUnit

@onready var btn_close  : Button = %BtnClose as Button
@onready var btn_submit : Button = %BtnSubmit as Button
@onready var btn_cancel : Button = %BtnCancel as Button

var building : CenterBuilding
var leader   : UnitStats : set = _set_leader

func _ready() -> void:
	tree_exiting.connect(_on_unready)
	
	btn_submit.pressed.connect(_on_submit_pressed)
	btn_close.pressed.connect(_on_cancel_pressed)
	btn_cancel.pressed.connect(_on_cancel_pressed)

	WorldService.get_world_canvas().block_other_ui(self)


func _set_leader(_leader: UnitStats) -> void:
	leader = _leader

	%InputName.text = leader.unit_name


func _on_submit_pressed() -> void:
	WorldService.get_world_canvas().close_ui(self)


func _on_cancel_pressed() -> void:
	building.commission_leader = false

	WorldService.get_world_canvas().close_sub_ui(self)


func _on_unready() -> void:
	WorldService.get_world_canvas().refresh_current_ui()
	WorldService.get_world_canvas().unblock_all_ui()
