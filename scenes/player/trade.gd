extends RefCounted
class_name Trade

enum TradeOffer
{
	BuyMotherland,
	SellMotherland,
	DemandTribute,
	GiveTribute,
	BarterWithPlayer,
	TransferToColony,
}

var player : Player
var colony : CenterBuilding

var offer    : TradeOffer
var receiver : Variant
var action_resource_type : Term.ResourceType
var trade_resource_type  : Term.ResourceType
var action_amount : int
var trade_amount  : int
var is_persistent : bool = false

func is_valid() -> bool:
	if offer == TradeOffer.BuyMotherland or offer == TradeOffer.SellMotherland:
		return colony.bank.can_afford_resource_this_turn(action_resource_type, action_amount)
	elif offer == TradeOffer.DemandTribute:
		return true
	elif offer == TradeOffer.GiveTribute:
		return colony.bank.can_afford_resource_this_turn(action_resource_type, action_amount)
	elif offer == TradeOffer.BarterWithPlayer:
		return colony.bank.can_afford_resource_this_turn(action_resource_type, action_amount)
	elif offer == TradeOffer.TransferToColony:
		return colony.bank.can_afford_resource_this_turn(action_resource_type, action_amount)

	return false
