extends PanelContainer
class_name UINewTrade

@onready var btn_close       := %BtnClose as Button
@onready var btn_cancel      := %BtnAccept as Button
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

var npc_options    : Array[NPC] = []
var colony_options : Array[CenterBuilding] = []

var trade_offer          : Trade.TradeOffer
var trade_receiver       : Variant
var action_resource_type : Term.ResourceType
var trade_resource_type  : Term.ResourceType


func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)
	btn_cancel.connect("pressed", _on_close_pressed)
	btn_accept.connect("pressed", _on_accept_pressed)
	btn_accept.disabled = true
	
	action_resource.connect("item_selected", _on_action_resource_selected)
	trade_resource.connect("item_selected", _on_trade_resource_selected)
	opt_receiver.connect("item_selected", _on_receiver_selected)
	opt_trade.connect("item_selected", _on_opt_trade_selected)
	
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

	# -- Setup colony options..
	for building: CenterBuilding in player.get_colonies():
		colony_options.append(building)
	
	opt_trade.select(0)


func _set_new_trade_with_motherland() -> void:
	trade_resource_type = Term.ResourceType.GOLD
	
	# -- Trade receiver..
	opt_receiver.clear()
	
	# -- Buying..
	if trade_offer == Trade.TradeOffer.BuyMotherland:
		action_label.text = "Buy"
	else:
		action_label.text = "Sell"
	action_amt.value = 1
	action_resource.select(1)
	
	# -- Trading..
	trade_container.show()
	trade_label.text = "for:"
	trade_amt.editable = false
	trade_amt.value = 1
	trade_resource.select(0)
	trade_message.text = "Trading with Motherland."


func _set_new_tribute_with_npc() -> void:
	
	# -- Trade receiver.. (NPC)
	opt_receiver.clear()
	for npc: NPC in npc_options:
		opt_receiver.add_item(npc.title)
	
	# -- Buying..
	if trade_offer == Trade.TradeOffer.DemandTribute:
		action_label.text = "Demand:"
	else:
		action_label.text = "Give:"
	action_amt.value = 1
	action_resource.select(1)
	
	# -- Trading...
	trade_container.hide()
	trade_message.text = ""


func _set_new_trade_with_npc() -> void:
	
	# -- Trade receiver.. (NPC)
	opt_receiver.clear()
	for npc: NPC in npc_options:
		opt_receiver.add_item(npc.title)
	
	# -- Offering..
	action_label.text = "Offer:"
	
	# -- Trading..
	trade_container.show()
	trade_label.text = "for:"
	trade_amt.editable = true
	trade_amt.value = 1
	trade_resource.select(0)
	trade_message.text = "Bartering with an NPC."


func _set_new_trade_with_colony() -> void:
	
	# -- Trade receiver.. (Colony)
	opt_receiver.clear()
	for building: CenterBuilding in colony_options:
		opt_receiver.add_item(building.title)
	
	# -- Offering..
	action_label.text = "Transfer:"
	
	# -- Trading..
	trade_container.show()
	trade_label.text = "for:"
	trade_amt.editable = true
	trade_amt.value = 1
	trade_resource.select(0)
	trade_message.text = "Transfer to Colony."


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


func _on_trade_resource_selected(_index:int) -> void:
	trade_resource_type = _index as Term.ResourceType


func _on_receiver_selected(_index:int) -> void:
	
	if trade_offer == Trade.TradeOffer.DemandTribute or \
	   trade_offer == Trade.TradeOffer.GiveTribute or \
	   trade_offer == Trade.TradeOffer.BarterWithPlayer:
		trade_receiver = npc_options[_index] as NPC
	elif trade_offer == Trade.TradeOffer.TransferToColony:
		trade_receiver = colony_options[_index] as CenterBuilding


func _on_accept_pressed() -> void:
	var new_trade : Trade = Trade.new()
	new_trade.offer = trade_offer
	new_trade.receiver = trade_receiver
	new_trade.action_resource_type = action_resource_type
	new_trade.action_amount = int(action_amt.value)
	new_trade.trade_resource_type = trade_resource_type
	new_trade.trade_amount = int(trade_amt.value)
	new_trade.is_persistent = btn_persistent.button_pressed
	player.trades.append(new_trade)


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_sub_ui(self)
