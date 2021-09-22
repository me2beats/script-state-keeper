tool
extends Resource

var cfg_path = "res://addons/script-state-keeper/data.cfg"
var config = ConfigFile.new()

var folded_lines = {}
var folded_lines_hash = {}

func _init():
	var err = config.load(cfg_path)
	if err == ERR_FILE_NOT_FOUND:
		config.save(cfg_path)
		return

	if not config.has_section_key('main', 'folded_lines'):
		config.set_value('main', 'folded_lines', {})
		config.save(cfg_path)
		return

	folded_lines = config.get_value('main', 'folded_lines')

func get_folded_lines(text_edit:TextEdit)->Array:
	var result = []
	for i in text_edit.get_line_count():
		if text_edit.is_folded(i):
			result.push_back(i)
	return result


func update_folded_lines(script:GDScript, text_edit:TextEdit):
	if not text_edit: return
	
	var path = script.resource_path

	var folded = get_folded_lines(text_edit)
	var folded_hash = folded.hash()
	if folded_hash == folded_lines_hash.get(path): return
	folded_lines[path] = folded
	folded_lines_hash[path] = folded_hash


func save_current_data():
	config.set_value('main', 'folded_lines', folded_lines)	
	config.save(cfg_path)


# from data
func set_folded_lines(textedit:TextEdit, script_path:String):
	
	var folded = folded_lines.get(script_path)
	if not folded: return

	for i in folded:
		textedit.fold_line(i)
