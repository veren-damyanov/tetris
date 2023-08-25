extends Control

func _ready():
    self._setup_theme()
    $VBoxContainer/StartButton.grab_focus()
    var agent = JavaScriptBridge.eval("navigator.oscpu")
    if agent == null:
        agent = 'dev'
    $PlatformLabel.set_text("platform: " + agent)

func _setup_theme():
    var tn = globals.THEME_NAMES[globals.current_theme]
    $MenuBackground.set_texture(load('res://assets/' + tn + '/sprites/menu.png'))
    self.theme = load('res://assets/' + tn + '/themes/text-general.tres')

func _on_start_button_pressed():
    self.get_tree().change_scene_to_file("res://playfield.tscn")

func _on_options_button_pressed():
    self.get_tree().change_scene_to_file("res://options.tscn")

func _on_scores_button_pressed():
    pass # TODO: Implement
