class_name EncounterDefinition
extends Resource

@export var id: StringName = StringName()
@export var display_name: String = ""
@export var npc_name: String = ""
@export_file("*.png") var portrait_path: String = ""
@export var deck_id: StringName = StringName()
@export var table_power_id: StringName = StringName()
@export var starting_life: int = 10

