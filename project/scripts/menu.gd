extends Control

@onready var globals = $'/root/globals'

func _ready():
    self._setup_theme()
    $VBoxContainer/StartButton.grab_focus()
    $PlatformLabel.set_text(globals.agent)

func _setup_theme():
    $'/root'.set_content_scale_size(Vector2i(144, 279))
    var tn = globals.THEME_NAMES[globals.current_theme]
    $MenuBackground.set_texture(load('res://assets/' + tn + '/sprites/menu.png'))
    self.theme = load('res://assets/' + tn + '/themes/general.tres')

func _on_start_button_pressed():
    self.get_tree().change_scene_to_file("res://playfield.tscn")

func _on_options_button_pressed():
    self.get_tree().change_scene_to_file("res://options.tscn")

func _on_scores_button_pressed():
    self.get_tree().change_scene_to_file("res://scores.tscn")
