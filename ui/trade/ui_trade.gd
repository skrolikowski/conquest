extends PanelContainer
class_name UITrade

@onready var btn_new_trade := %BtnNewTrade as Button
@onready var btn_close := %BtnClose as Button
@onready var trade_list := %TradeList as Tree

var player : Player : set = _set_player
var colony : CenterBuilding

func _ready() -> void:
	btn_new_trade.connect("pressed", _on_new_trade_pressed)
	btn_close.connect("pressed", _on_close_pressed)


func _set_player(_player: Player) -> void:
	player = _player

	# -- Trade List
	var root : TreeItem = trade_list.create_item()
	trade_list.hide_root = true
	trade_list.columns = 1
	# trade_list.set_column_custom_minimum_width(0, 150)

	# var trades : Array[Trade] = player.get_trades_sorted_by_trade_type()
	for trade : Trade in player.trades:
		var child : TreeItem = trade_list.create_item(root)
		child.set_text(0, trade.get_title())


func _on_new_trade_pressed() -> void:
	WorldService.get_world_canvas().open_new_trade_menu(colony)


func _on_close_pressed() -> void:
	WorldService.get_world_canvas().close_all_sub_ui()
