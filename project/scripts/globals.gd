extends Node

const FIELD_X = 10 # x size of playfield in tiles
const FIELD_Y = 20 # y size of playfield in tiles
const TILE_SIZE = 8 # size of one tile in pixels
const LAYOUT_NAMES = {0: "desktop", 1: "mobile"}
const THEME_NAMES = {0: "classic", 1: "retro"}

enum LAYOUT {DESKTOP = 0, MOBILE = 1}
enum THEME {CLASSIC = 0, RETRO = 1}

var agent = JavaScriptBridge.eval("navigator.oscpu")
var current_layout = LAYOUT.DESKTOP
var current_theme = THEME.CLASSIC
var high_scores = []

func increment_layout():
    self.current_layout += 1
    if self.current_layout > 1:
        self.current_layout = 0

func increment_theme():
    self.current_theme += 1
    if self.current_theme > 1:
        self.current_theme = 0

func _ready():
    if self.agent == null:
        self.agent = 'dev'

