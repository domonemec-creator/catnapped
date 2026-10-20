# Přepíše DeckDefinition .tres podle seznamu "card_id počet". Použití:
#   python scripts/card_game/tools/write_deck.py data/decks/x.tres card_a 4 card_b 3 ...
import io, re, sys
path = sys.argv[1]
args = sys.argv[2:]
entries = [(args[i], int(args[i + 1])) for i in range(0, len(args), 2)]
old = io.open(path, encoding='utf-8').read()
tail = old[old.index('[resource]'):]
tail = re.sub(r'cards = \[[^\]]*\]', 'cards = [%s]' % ', '.join('SubResource("%d_entry")' % i for i in range(1, len(entries) + 1)), tail)
out = ['[gd_resource type="Resource" script_class="DeckDefinition" load_steps=%d format=3]' % (len(entries) + 3), '',
       '[ext_resource type="Script" path="res://scripts/card_game/data/deck_definition.gd" id="1_deck_definition"]',
       '[ext_resource type="Script" path="res://scripts/card_game/data/deck_entry.gd" id="2_deck_entry"]', '']
for i, (card, count) in enumerate(entries, 1):
    out += ['[sub_resource type="Resource" id="%d_entry"]' % i, 'script = ExtResource("2_deck_entry")', 'card_id = &"%s"' % card, 'count = %d' % count, '']
io.open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(out) + tail)
print('%s: %d karet' % (path, sum(c for _, c in entries)))
