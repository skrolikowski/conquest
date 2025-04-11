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

var offer    : TradeOffer
var receiver : Variant
var action_resource_type : Term.ResourceType
var trade_resource_type  : Term.ResourceType
var action_amount : int
var trade_amount  : int
var is_persistent : bool = false