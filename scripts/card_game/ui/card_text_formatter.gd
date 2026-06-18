class_name CardTextFormatter
extends RefCounted

const CardGameConstants = preload("res://scripts/card_game/data/card_game_constants.gd")


static func rules_preview_bbcode(card_definition: CardDefinition) -> String:
    if card_definition == null:
        return "No extra text."

    if not card_definition.rules_text.is_empty():
        return _emphasize_rule_text(card_definition.rules_text)

    if card_definition.keywords.is_empty():
        return "No extra text."

    var lines: Array[String] = []
    for keyword in card_definition.keywords:
        lines.append("[b]%s:[/b] %s" % [
            CardGameConstants.keyword_label(keyword),
            CardGameConstants.keyword_summary(keyword),
        ])
    return "\n".join(lines)


static func _emphasize_rule_text(rules_text: String) -> String:
    var emphasis_labels := {}
    for label in CardGameConstants.KEYWORD_LABELS.values():
        emphasis_labels[str(label)] = true

    var formatted_lines: Array[String] = []
    for raw_line in rules_text.split("\n", false):
        var line := raw_line.strip_edges()
        if line.is_empty():
            formatted_lines.append("")
            continue

        var colon_index := line.find(":")
        if colon_index > 0:
            var prefix := line.substr(0, colon_index)
            if emphasis_labels.has(prefix):
                var suffix := line.substr(colon_index + 1)
                formatted_lines.append("[b]%s:[/b]%s" % [prefix, suffix])
                continue

        formatted_lines.append(line)

    return "\n".join(formatted_lines)
