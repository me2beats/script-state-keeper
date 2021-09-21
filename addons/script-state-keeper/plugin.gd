tool
extends EditorPlugin

const Utils = preload("utils.gd")

var scr_ed = get_editor_interface().get_script_editor()
var tab_container = Utils.get_script_tab_container(scr_ed)

const data = preload("data.tres")

func _enter_tree():
	data.init(self)

	tab_container.connect("tab_changed", self, "on_tab")

	var current_script = scr_ed.get_current_script()
	if not current_script: return
	var current_textedit = Utils.get_current_text_edit(scr_ed)
	
	set_connections(current_textedit, tab_container.current_tab, current_script)


func set_connections(textedit:TextEdit, tab:int, script:GDScript):
	var vscroll:VScrollBar = textedit.get_node('VScrollBar')
	vscroll.connect("changed", self, "on_vscroll_changed", [vscroll, textedit, script])
	textedit.connect("tree_exiting", self, "on_text_edit_tree_exit", [textedit]) # mb no need



func on_tab(tab:int):
	yield(get_tree(), "idle_frame") # ensures text edit is ready, maybe there's a better way
	tab = tab_container.current_tab

	var current_script = scr_ed.get_current_script()
	if not current_script: # doc is opened, not a script
		return

	var current_textedit = Utils.get_current_text_edit(scr_ed)
	if not current_textedit: # is it possible? 
		return

	data.set_folded_lines(current_textedit, current_script.resource_path)

	if not current_textedit.is_connected("tree_exiting", self, "on_text_edit_tree_exit"):
		set_connections(current_textedit, tab, current_script)





func on_vscroll_changed(vscroll:VScrollBar, textedit:TextEdit, script:GDScript):
	if vscroll.has_meta("recent_max_val"):
		if vscroll.max_value == vscroll.get_meta("recent_max_val"): return
	vscroll.set_meta("recent_max_val", vscroll.max_value)

	data.update_folded_lines(script, textedit)


func on_text_edit_tree_exit(text_edit:TextEdit):
	data.save_current_data()

func _exit_tree():
	data.save_current_data()
