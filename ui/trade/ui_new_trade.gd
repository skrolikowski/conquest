extends PanelContainer
class_name UINewTrade

@onready var btn_close       := %BtnClose as Button
@onready var btn_cancel      := %BtnCancel as Button
@onready var btn_accept      := %BtnAccept as Button
@onready var btn_persistent  := %BtnPersistent as Button

@onready var opt_trade       := %OptTrade as OptionButton
@onready var opt_receiver    := %OptReceiver as OptionButton

@onready var action_label    := %ActionLabel as Label
@onready var action_amt      := %BtnActionAmt as SpinBox
@onready var action_resource := %OptActionResource as OptionButton

@onready var trade_container := %TradeContainer as HBoxContainer
@onready var trade_label     := %TradeLabel as Label
@onready var trade_amt       := %BtnTradeAmt as SpinBox
@onready var trade_resource  := %OptTradeResource as OptionButton
@onready var trade_message   := %TradeMessage as Label

var player : Player : set = _set_player
var colony : CenterBuilding
var trade  : Trade

var npc_options    : Array[NPC] = []
var colony_options : Array[CenterBuilding] = []

var trade_offer          : Trade.TradeOffer
var trade_receiver       : Variant
var action_resource_type : Term.ResourceType = Term.ResourceType.METAL
var trade_resource_type  : Term.ResourceType = Term.ResourceType.GOLD

const BUY_RATE  : Array[int] = [0, 10, 10, 30, 10]
const SELL_RATE : Array[int] = [0,  5,  5, 15,  5]


func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)
	btn_cancel.connect("pressed", _on_close_pressed)
	btn_accept.connect("pressed", _on_accept_pressed)
	btn_accept.disabled = true
	
	action_resource.connect("item_selected", _on_action_resource_selected)
	trade_resource.connect("item_selected", _on_trade_resource_selected)
	opt_receiver.connect("item_selected", _on_receiver_selected)
	opt_trade.connect("item_selected", _on_opt_trade_selected)
	action_amt.connect("value_changed", _on_action_amount_changed)
	trade_amt.connect("value_changed", _on_trade_amount_changed)
	
	# -- Setup resource options..
	for i: String in Term.ResourceType:
		if i != "NONE":
			action_resource.add_item(i.capitalize())
			trade_resource.add_item(i.capitalize())

	# -- Setup NPC options..
	for npc: NPC in Def.get_player_manager().npcs:
		npc_options.append(npc)


func _set_player(_player:Player) -> void:
	player = _player

	# -- New trade opportunity..
	trade = Trade.new()
	trade.player = player
	trade.colony = colony

	# -- Setup colony options..
	for building: CenterBuilding in player.get_colonies():
		colony_options.append(building)
	
	opt_trade.select(0)
	opt_trade.item_selected.emit(0)


func _set_new_trade_with_motherland() -> void:
	btn_persistent.show()
	btn_persistent.disabled = false
	
	opt_receiver.disabled = true
	opt_receiver.clear()
	
	# -- Trading..
	trade_container.show()
	trade_resource.show()
	trade_resource.select(0)
	trade_resource.disabled = true
	trade_resource_type = Term.ResourceType.GOLD
	trade_amt.editable = false
	trade_message.text = "Shipment arrives in 2 turns."

	# -- Buying..
	if trade_offer == Trade.TradeOffer.BuyMotherland:
		action_label.text = "Buy:"
	else:
		action_label.text = "Sell:"
	action_resource.set_item_disabled(0, true)
	action_resource.select(1)
	action_resource.item_selected.emit(1)
	action_amt.value = 1


func _set_new_tribute_with_npc() -> void:
	btn_persistent.hide()
	btn_persistent.set_pressed_no_signal(false)
	
	# -- Trade receiver.. (NPC)
	opt_receiver.disabled = false
	opt_receiver.clear()
	for npc: NPC in npc_options:
		opt_receiver.add_item(npc.title)
	
	# -- Buying..
	if trade_offer == Trade.TradeOffer.DemandTribute:
		action_label.text = "Demand:"
	else:
		action_label.text = "Give:"
	action_resource.select(0)
	action_resource.item_selected.emit(0)
	action_amt.set_value_no_signal(1)
	
	# -- Trading...
	trade_container.hide()
	trade_resource.hide()
	trade_resource_type = Term.ResourceType.NONE
	trade_amt.set_value_no_signal(0)
	trade_message.text = "Shipment will arrive in x turn(s)."


func _set_new_trade_with_npc() -> void:
	btn_persistent.hide()
	btn_persistent.set_pressed_no_signal(false)
	
	# -- Trade receiver.. (NPC)
	opt_receiver.disabled = false
	opt_receiver.clear()
	for npc: NPC in npc_options:
		opt_receiver.add_item(npc.title)
	
	# -- Offering..
	action_label.text = "Offer:"
	action_resource.select(0)
	action_resource.item_selected.emit(0)
	action_amt.set_value_no_signal(1)
	
	# -- Trading..
	trade_container.show()
	trade_resource.show()
	trade_resource.select(0)
	trade_resource.disabled = false
	trade_resource.item_selected.emit(0)
	trade_label.text = "for:"
	trade_amt.editable = true
	trade_amt.set_value_no_signal(1)
	trade_message.text = "Shipment will arrive in x turn(s)."


func _set_new_trade_with_colony() -> void:
	btn_persistent.show()
	btn_persistent.disabled = false
	
	# -- Trade receiver.. (Colony)
	opt_receiver.disabled = false
	opt_receiver.clear()
	for building: CenterBuilding in colony_options:
		opt_receiver.add_item(building.title)
	
	# -- Offering..
	action_label.text = "Transfer:"
	action_resource.select(0)
	action_resource.item_selected.emit(0)
	action_amt.set_value_no_signal(1)
	
	# -- Trading...
	trade_container.hide()
	trade_resource.hide()
	trade_resource_type = Term.ResourceType.NONE
	trade_amt.set_value_no_signal(0)
	trade_message.text = "Shipment will arrive in x turn(s)."


func _on_opt_trade_selected(_index:int) -> void:
	trade_offer = _index as Trade.TradeOffer
	
	if trade_offer == Trade.TradeOffer.BuyMotherland or trade_offer == Trade.TradeOffer.SellMotherland:
		_set_new_trade_with_motherland()
	elif trade_offer == Trade.TradeOffer.DemandTribute or trade_offer == Trade.TradeOffer.GiveTribute:
		_set_new_tribute_with_npc()
	elif trade_offer == Trade.TradeOffer.BarterWithPlayer:
		_set_new_trade_with_npc()
	elif trade_offer == Trade.TradeOffer.TransferToColony:
		_set_new_trade_with_colony()


func _on_action_resource_selected(_index:int) -> void:
	action_resource_type = _index as Term.ResourceType
	action_amt.value_changed.emit(action_amt.value)


func _on_trade_resource_selected(_index:int) -> void:
	trade_resource_type = _index as Term.ResourceType
	trade_amt.value_changed.emit(trade_amt.value)


func _on_action_amount_changed(_value:int) -> void:
	if trade_offer == Trade.TradeOffer.BuyMotherland:
		trade_amt.value = _value * BUY_RATE[action_resource_type]
	elif trade_offer == Trade.TradeOffer.SellMotherland:
		trade_amt.value = _value * SELL_RATE[action_resource_type]
	_validate_trade()


func _on_trade_amount_changed(_value:int) -> void:
	_validate_trade()


func _on_receiver_selected(_index:int) -> void:
	if trade_offer == Trade.TradeOffer.DemandTribute or \
	   trade_offer == Trade.TradeOffer.GiveTribute or \
	   trade_offer == Trade.TradeOffer.BarterWithPlayer:
		trade_receiver = npc_options[_index] as NPC
	elif trade_offer == Trade.TradeOffer.TransferToColony:
		trade_receiver = colony_options[_index] as CenterBuilding

	#TODO: update trade_message (shipment will arrive in x turns)


func _validate_trade() -> void:
	btn_accept.disabled = not trade.is_valid()


func _on_accept_pressed() -> void:
	# var new_trade : Trade = Trade.new()
	# new_trade.offer = trade_offer
	# new_trade.receiver = trade_receiver
	# new_trade.action_resource_type = action_resource_type
	# new_trade.action_amount = int(action_amt.value)
	# new_trade.trade_resource_type = trade_resource_type
	# new_trade.trade_amount = int(trade_amt.value)
	# new_trade.is_persistent = btn_persistent.button_pressed
	player.trades.append(trade)


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_sub_ui(self)
