extends Node2D

var _type     # type of the shape, e.g. J
var _coords   # relative coords of the 4 blocks
var _size     # used for rotation
var _color    # color of the shape

@onready var globals = $'/root/globals'

func _ready():
    var blocks = self.get_children()
    var texture = load('res://assets/' + globals.THEME_NAMES[globals.current_theme] + '/sprites/tile.png')
    for i in range(4):
        blocks[i].position = self._coords[i] * globals.TILE_SIZE
        blocks[i].get_node('Sprite2D').set_modulate(self._color)
        blocks[i].get_node('Sprite2D').set_texture(texture)

func init(type, coords, color):
    self._type = type
    self._coords = coords
    self._size = 0
    self._color = color
    if self._type in ['I', 'O']:
        self._size = 1

func get_blocks():
    return self.get_children()

func get_type():
    return self._type

func get_coords():
    return self._coords

func set_coords(new_coords):
    self._coords = new_coords
    self._adjust_positions()

func get_size():
    return self._size

func _adjust_positions():
    var blocks = self.get_children()
    for i in range(4):
        blocks[i].position = self._coords[i] * globals.TILE_SIZE
