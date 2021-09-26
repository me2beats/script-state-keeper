tool
extends EditorPlugin

const Utils = preload("utils.gd")

var script_editor: ScriptEditor
var current_textedit: TextEdit
var current_script: Script
const DataScript = preload("data.gd")
var data: DataScript


func _enter_tree():
	data = DataScript.new() # data related subroutines

	script_editor = get_editor_interface().get_script_editor()
	script_editor.connect("editor_script_changed", self, "_on_script_changed")
	script_editor.connect("script_close", self, "_on_script_close")
	
	_on_script_changed(script_editor.get_current_script()) # init call

func _on_script_changed(new_script:Script): # called when active script is changed
	if not new_script: return # all scripts are closed
	
	if current_script: # store data for current script
		data.update(current_script, current_textedit)
	
	var new_textedit = Utils.get_current_text_edit(script_editor) # get a TextEdit for new script
	if not new_textedit: return # just in case
	
	# restore:
	var script_path = new_script.resource_path
	data.restore(new_textedit, script_path)
	
	# make new script the current script
	current_script = new_script
	current_textedit = new_textedit

func _on_script_close(script): # called when active script is about to close
	if script != current_script: # in the case when there was no script change
		_on_script_changed(script) # act as if it has changed
	data.save_current_data() # save config file

func _exit_tree():
	script_editor.disconnect("editor_script_changed", self, "_on_script_changed")
	script_editor.disconnect("script_close", self, "_on_script_close")
	data.save_current_data()
	data = null
