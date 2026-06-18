extends Node

const DEFAULT_RUN_ROSTER: Array[StringName] = [&"smug_tabby", &"ragclaw_brawler"]
const DEFAULT_RUN_LENGTH := 5

var _active: bool = false
var _route: Array[StringName] = []
var _current_index: int = -1


func start_new_run(start_encounter_id: StringName, route_length: int = DEFAULT_RUN_LENGTH) -> void:
    var roster := _build_run_roster()
    if roster.is_empty():
        push_warning("RunSession could not build a run route.")
        end_run()
        return

    var sanitized_length := maxi(1, route_length)
    var start_index := roster.find(start_encounter_id)
    if start_index < 0:
        start_index = 0

    _route.clear()
    for step in range(sanitized_length):
        _route.append(roster[(start_index + step) % roster.size()])

    _current_index = 0
    _active = true


func end_run() -> void:
    _active = false
    _current_index = -1
    _route.clear()


func is_active() -> bool:
    return _active


func get_route_length() -> int:
    return _route.size()


func get_current_step_number() -> int:
    if not _active or _current_index < 0 or _route.is_empty():
        return 0
    return _current_index + 1


func get_current_encounter_id() -> StringName:
    if not _active or _current_index < 0 or _current_index >= _route.size():
        return StringName()
    return _route[_current_index]


func has_next_encounter() -> bool:
    return _active and _current_index >= 0 and _current_index + 1 < _route.size()


func advance_to_next_encounter() -> StringName:
    if not has_next_encounter():
        return StringName()

    _current_index += 1
    return _route[_current_index]


func get_run_progress_text() -> String:
    if not _active or _route.is_empty():
        return ""
    return "Run %s/%s" % [get_current_step_number(), _route.size()]


func get_run_roster_summary() -> String:
    if _route.is_empty():
        return ""

    var roster_names: Array[String] = []
    for encounter_id in _route:
        roster_names.append(_encounter_display_name(encounter_id))
    return " -> ".join(roster_names)


func _build_run_roster() -> Array[StringName]:
    var roster: Array[StringName] = []
    for encounter_id in DEFAULT_RUN_ROSTER:
        if encounter_id == StringName():
            continue
        roster.append(encounter_id)
    return roster


func _encounter_display_name(encounter_id: StringName) -> String:
    match encounter_id:
        &"smug_tabby":
            return "Smug Tabby"
        &"ragclaw_brawler":
            return "Ragclaw"
    return String(encounter_id)
