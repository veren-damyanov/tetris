extends Node2D

var globals
var type   # type of shape, e.g. J
var coords # relative coords of the 4 blocks
var size   # used for rotation
var color

func _ready():
    globals = get_node("/root/globals")
    var blocks = self.get_children()
    for i in range(4):
        blocks[i].position = self.coords[i] * self.globals.TILE_SIZE
        blocks[i].get_node('Sprite2D').set_modulate(self.color)

func init(type, coords, color):
    self.type = type
    self.coords = coords
    self.color = color
    self.size = 0
    if self.type in ['I', 'O']:
        self.size = 1

func get_blocks():
    return self.get_children()

func get_size():
    return self.size

func get_coords():
    return self.coords

func get_type():
    return self.type

func set_coords(new_coords):
    self.coords = new_coords
    self._adjust_positions()

func _adjust_positions():
    var blocks = self.get_children()
    for i in range(4):
        blocks[i].position = self.coords[i] * self.globals.TILE_SIZE
