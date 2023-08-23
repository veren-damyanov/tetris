extends Control


func _ready():
    $MainContainer/GridContainer/LayoutButton.grab_focus()


func _on_layout_button_pressed():
    var layout_button = $MainContainer/GridContainer/LayoutButton
    var text = layout_button.get_text()
    if text == 'desktop':
        layout_button.set_text('mobile')
    elif text == 'mobile':
        layout_button.set_text('desktop')
    else:
        layout_button.set_text('ERROR!')

func _on_back_button_pressed():
    self.get_tree().change_scene_to_file("res://menu.tscn")
