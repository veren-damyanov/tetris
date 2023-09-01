extends Control

@onready var globals = get_node("/root/globals")

func _ready():
    self._setup_theme()
    self._setup_buttons()
    $MainContainer/GridContainer/LayoutButton.grab_focus()

func _setup_theme():
    var tn = globals.THEME_NAMES[globals.current_theme]
    $MenuBackground.set_texture(load('res://assets/' + tn + '/sprites/menu.png'))
    self.theme = load('res://assets/' + tn + '/themes/general.tres')

func _setup_buttons():
    $MainContainer/GridContainer/LayoutButton.set_text(globals.LAYOUT_NAMES[globals.current_layout])
    $MainContainer/GridContainer/ThemeButton.set_text(globals.THEME_NAMES[globals.current_theme])

func _on_layout_button_pressed():
    globals.increment_layout()
    self._setup_buttons()

func _on_theme_button_pressed():
    globals.increment_theme()
    self._setup_buttons()
    self._setup_theme()

func _on_back_button_pressed():
    self.get_tree().change_scene_to_file("res://menu.tscn")
