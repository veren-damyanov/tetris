extends Control

var globals


func _ready():
    self.globals = get_node("/root/globals")
    $MainContainer/GridContainer/LayoutButton.grab_focus()

func _on_layout_button_pressed():
    var layout_button = $MainContainer/GridContainer/LayoutButton
    var text = layout_button.get_text()

    if text == 'desktop':
        layout_button.set_text('mobile')
        self.globals.current_layout = self.globals.LAYOUT.MOBILE
    elif text == 'mobile':
        layout_button.set_text('desktop')
        self.globals.current_layout = self.globals.LAYOUT.DESKTOP
    else:
        layout_button.set_text('ERROR!')

func _on_back_button_pressed():
    self.get_tree().change_scene_to_file("res://menu.tscn")

func _on_layout_button_focus_entered():
    $MainContainer/GridContainer/LayoutButton.add_theme_constant_override("outline_size", 2)

func _on_layout_button_focus_exited():
    $MainContainer/GridContainer/LayoutButton.remove_theme_constant_override("outline_size")

func _on_back_button_focus_entered():
    $MainContainer/BackButton.add_theme_constant_override("outline_size", 2)

func _on_back_button_focus_exited():
    $MainContainer/BackButton.remove_theme_constant_override("outline_size")
