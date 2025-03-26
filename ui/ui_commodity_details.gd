extends PanelContainer
class_name UICommodityDetails

@onready var btn_close : Button = %BtnClose as Button

var colony : CenterBuilding : set = _set_colony

func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)


func _set_colony(_building: CenterBuilding) -> void:
	colony = _building
	
	%ColonyTitle.text = colony.title

	var expected_gold_produce : int = colony.get_expected_produce_value_by_resource_type(Term.ResourceType.GOLD)
	var actual_gold_produce   : int = colony.get_actual_produce_value_by_resource_type(Term.ResourceType.GOLD)
	var gold_consume          : int = colony.get_consume_value_by_resource_type(Term.ResourceType.GOLD)
	var gold_trade            : int = colony.get_trade_value_by_resource_type(Term.ResourceType.GOLD)
	var gold_total            : int = actual_gold_produce - gold_consume + gold_trade

	%GoldProducing.text = str(actual_gold_produce)+" of "+str(expected_gold_produce)
	%GoldConsuming.text = str(gold_consume) if gold_consume == 0 else "-"+str(gold_consume)
	%GoldTrading.text   = str(gold_trade)
	%GoldTotal.text     = str(gold_total)

	var expected_wood_produce : int = colony.get_expected_produce_value_by_resource_type(Term.ResourceType.WOOD)
	var actual_wood_produce   : int = colony.get_actual_produce_value_by_resource_type(Term.ResourceType.WOOD)
	var wood_consume          : int = colony.get_consume_value_by_resource_type(Term.ResourceType.WOOD)
	var wood_trade            : int = colony.get_trade_value_by_resource_type(Term.ResourceType.WOOD)
	var wood_total            : int = colony.get_total_value_by_resource_type(Term.ResourceType.WOOD)

	%WoodProducing.text = str(actual_wood_produce)+" of "+str(expected_wood_produce)
	%WoodConsuming.text = str(wood_consume) if wood_consume == 0 else "-" + str(wood_consume)
	%WoodTrading.text   = str(wood_trade)
	%WoodTotal.text     = str(wood_total)

	var expected_metal_produce : int = colony.get_expected_produce_value_by_resource_type(Term.ResourceType.METAL)
	var actual_metal_produce   : int = colony.get_actual_produce_value_by_resource_type(Term.ResourceType.METAL)
	var metal_consume          : int = colony.get_consume_value_by_resource_type(Term.ResourceType.METAL)
	var metal_trade            : int = colony.get_trade_value_by_resource_type(Term.ResourceType.METAL)
	var metal_total            : int = actual_metal_produce - metal_consume + metal_trade

	%MetalProducing.text = str(actual_metal_produce)+" of "+str(expected_metal_produce)
	%MetalConsuming.text = str(metal_consume) if metal_consume == 0 else "-" + str(metal_consume)
	%MetalTrading.text   = str(metal_trade)
	%MetalTotal.text     = str(metal_total)

	var expected_goods_produce : int = colony.get_expected_produce_value_by_resource_type(Term.ResourceType.GOODS)
	var actual_goods_produce   : int = colony.get_actual_produce_value_by_resource_type(Term.ResourceType.GOODS)
	var goods_consume          : int = colony.get_consume_value_by_resource_type(Term.ResourceType.GOODS)
	var goods_trade            : int = colony.get_trade_value_by_resource_type(Term.ResourceType.GOODS)
	var goods_total            : int = actual_goods_produce - goods_consume + goods_trade

	%GoodsProducing.text = str(actual_goods_produce)+" of "+str(expected_goods_produce)
	%GoodsConsuming.text = str(goods_consume) if goods_consume == 0 else "-" + str(goods_consume)
	%GoodsTrading.text   = str(goods_trade)
	%GoodsTotal.text     = str(goods_total)

	var expected_crops_produce : int = colony.get_expected_produce_value_by_resource_type(Term.ResourceType.CROPS)
	var actual_crops_produce   : int = colony.get_actual_produce_value_by_resource_type(Term.ResourceType.CROPS)
	var crops_consume          : int = colony.get_consume_value_by_resource_type(Term.ResourceType.CROPS)
	var crops_trade            : int = colony.get_trade_value_by_resource_type(Term.ResourceType.CROPS)
	var crops_total            : int = actual_crops_produce - crops_consume + crops_trade

	%CropsProducing.text = str(actual_crops_produce)+" of "+str(expected_crops_produce)
	%CropsConsuming.text = str(crops_consume) if crops_consume == 0 else "-" + str(crops_consume)
	%CropsTrading.text   = str(crops_trade)
	%CropsTotal.text     = str(crops_total)
	
	
func _on_close_pressed() -> void:
	Def.get_world_canvas().close_sub_ui(self)
