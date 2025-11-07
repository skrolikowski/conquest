## Static utility class for procedural name generation
## Based on: https://github.com/xsellier/godot-name-generator
class_name NameGenerator
extends RefCounted

const MIN_LENGTH:int = 4
const MAX_LENGTH:int = 8
const LETTERS : Dictionary = {
	"VOWEL"        : ['a', 'e', 'a', 'e', 'i', 'o', 'o', 'a', 'e', 'a', 'e', 'i', 'a', 'e', 'a', 'e', 'i', 'o', 'o', 'a', 'e', 'a', 'e', 'i', 'y'],
	"DOUBLE_VOWEL" : ['oi', 'ai', 'ou', 'ei', 'ae', 'eu', 'ie', 'ea'],

	"CONST"        : ['b', 'c', 'c', 'd', 'f', 'g', 'h', 'j', 'l', 'm', 'n', 'n', 'p', 'r', 'r', 's', 't', 's', 't', 'b', 'c', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'n', 'p', 'r', 'r', 's', 't', 's', 't', 'v', 'w', 'x', 'z'],
	"DOUBLE_CONST" : ['mm', 'nn', 'st', 'ch', 'll', 'tt', 'ss'],

	"COMPOSE"      : ['qu', 'gu', 'cc', 'sc', 'tr', 'fr', 'pr', 'br', 'cr', 'ch', 'll', 'tt', 'ss', 'gn']
}

const TRANSITION : Dictionary = {
	"INITIAL"      : ["VOWEL", "CONST", "COMPOSE"],
	"VOWEL"        : ["CONST", "DOUBLE_CONST", "COMPOSE"],
	"DOUBLE_VOWEL" : ["CONST", "DOUBLE_CONST", "COMPOSE"],

	"CONST"        : ["VOWEL", "DOUBLE_VOWEL"],
	"DOUBLE_CONST" : ["VOWEL", "DOUBLE_VOWEL"],

	"COMPOSE"      : ["VOWEL"]
}

static func pick_random_number(max_value: int, min_value: int = 0) -> int:
	randomize()
	return round(randi() % (max_value - min_value) + min_value)


static func clone_array(_original: Array) -> Array:
	var result : Array = []
	for item: String in _original:
		result.append(item)
	return result


static func get_letter(_state: String, _max_length: int) -> Array[String]:
	var transitions : Array = clone_array(TRANSITION[_state])

	if _max_length < 3:
		transitions.erase("COMPOSE")
		transitions.erase("DOUBLE_CONST")
		transitions.erase("DOUBLE_VOWEL")

	var state_index : int = pick_random_number(transitions.size())
	var next_state  : String = transitions[state_index]
	#print("Next State: " + next_state)

	var letters_list : Array = LETTERS[next_state]
	var letter_index : int = pick_random_number(letters_list.size())
	var next_letters : String = letters_list[letter_index]
	#print("Next Letters: " + next_letters)
	return [next_state, next_letters]


static func generate(_min_length: int = MIN_LENGTH, _max_length: int = MAX_LENGTH) -> String:
	var _rand   : int = pick_random_number(_max_length, _min_length)
	var _name   : String = ""
	var last_letter : String = ""
	var index : int = 0
	var state : String = "INITIAL"

	while index < _rand:
		var obj : Array = get_letter(state, _rand - index)

		state = obj[0]
		last_letter = obj[1]

		_name += last_letter
		index += last_letter.length()

	return _name.capitalize()
