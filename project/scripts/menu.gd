extends Control

func _ready():
    $VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed():
    self.get_tree().change_scene_to_file("res://playfield.tscn")


func _on_options_button_pressed():
    self.get_tree().change_scene_to_file("res://options.tscn")


func _on_scores_button_pressed():
    pass # TODO: Implement
