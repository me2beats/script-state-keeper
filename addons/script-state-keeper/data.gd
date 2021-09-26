var cfg_path = "res://addons/script-state-keeper/data.cfg"
var config = ConfigFile.new()
var file = File.new()

var md5 = {}

var folded_lines = {}
var folded_lines_hash = {}

var bookmarks = {}
var bookmarks_hash = {}

var breakpoints = {}
var breakpoints_hash = {}


const keys = ['md5', 'folded_lines', 'bookmarks', 'breakpoints']


func _init():

	var err = config.load(cfg_path)
	if err == ERR_FILE_NOT_FOUND or !config.has_section("main"):
		config_set_defaults()
		config.save(cfg_path)
		return

	var need_save = false

	for key in keys:
		if not config.has_section_key('main', key):
			config.set_value('main', 'folded_lines', {})
			need_save = true

		set(key, config.get_value('main', key))

	if need_save:
		config.save(cfg_path)

func config_set_defaults():
	for key in keys:
		config.set_value('main', key, {})

func get_folded_lines(text_edit:TextEdit)->Array:
	var result = []
	for i in text_edit.get_line_count():
		if text_edit.is_folded(i):
			result.push_back(i)
	return result

func get_bookmarks(textedit:TextEdit)->Array:
	var result = []
	for i in textedit.get_line_count():
		if textedit.is_line_set_as_bookmark(i):
			result.push_back(i)
	return result

func get_breakpoints(textedit:TextEdit)->Array:
	var result = []
	for i in textedit.get_line_count():
		if textedit.is_line_set_as_breakpoint(i):
			result.push_back(i)
	return result

func update(script:GDScript, text_edit:TextEdit):
	if not text_edit: return
	var path = script.resource_path
	
	for key in keys.slice(1, keys.size()): # except md5
		var items = call('get_'+key, text_edit)
		var _hash = items.hash()
		if _hash == get(key+'_hash').get(path): return
		get(key)[path] = items
		get(key+'_hash')[path] = _hash

func save_current_data():
	for path in folded_lines.keys():
		md5[path] = file.get_md5(path)
	for key in keys:
		config.set_value('main', key, get(key))
	config.save(cfg_path)

# set from data:

func set_folded_lines(textedit:TextEdit, script_path:String):
	for i in folded_lines.get(script_path, []):
		textedit.fold_line(i)

func set_bookmarks(textedit:TextEdit, script_path:String):
	for i in bookmarks.get(script_path, []):
		textedit.set_line_as_bookmark(i, true)

func set_breakpoints(textedit:TextEdit, script_path:String):
	for i in breakpoints.get(script_path, []):
		textedit.set_line_as_breakpoint(i, true)

func restore(textedit:TextEdit, script_path: String):
	_validate_path(script_path)
	
	set_folded_lines(textedit, script_path)
	set_bookmarks(textedit, script_path)
	set_breakpoints(textedit, script_path)

func _validate_path(script_path: String):
	var _hash = md5.get(script_path)
	
	if not _hash: # the path is invalid
		var outdated_path := ''
		_hash = file.get_md5(script_path)
		for key in md5.keys():
			if md5[key] == _hash: # found already stored hash
				outdated_path = key
				break
		
		for key in keys:
			var dict: Dictionary = get(key)
			if outdated_path: # name or location of the script has been changed
				var value = dict[outdated_path]
				dict[script_path] = value # add correct records
			dict.erase(outdated_path) # get rid of outdated records
