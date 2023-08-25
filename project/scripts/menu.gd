extends Control

func _ready():
    $VBoxContainer/StartButton.grab_focus()
    var agent = JavaScriptBridge.eval("navigator.oscpu")
    if agent == null:
        agent = 'dev'
    $PlatformLabel.set_text("platform: " + agent)

func _on_start_button_pressed():
    self.get_tree().change_scene_to_file("res://playfield.tscn")

func _on_options_button_pressed():
    self.get_tree().change_scene_to_file("res://options.tscn")

func _on_scores_button_pressed():
    pass # TODO: Implement

func _on_start_button_focus_entered():
    $VBoxContainer/StartButton.add_theme_constant_override("outline_size", 2)

func _on_start_button_focus_exited():
    $VBoxContainer/StartButton.remove_theme_constant_override("outline_size")

func _on_options_button_focus_entered():
    $VBoxContainer/OptionsButton.add_theme_constant_override("outline_size", 2)

func _on_options_button_focus_exited():
    $VBoxContainer/OptionsButton.remove_theme_constant_override("outline_size")

func _on_scores_button_focus_entered():
    $VBoxContainer/ScoresButton.add_theme_constant_override("outline_size", 2)

func _on_scores_button_focus_exited():
    $VBoxContainer/ScoresButton.remove_theme_constant_override("outline_size")
