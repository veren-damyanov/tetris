extends Node2D

var globals
var type   # type of shape, e.g. J
var coords # relative coords of the 4 blocks
var size   # used for rotation
var tpos  # position within field matrix

func _ready():
    globals = get_node("/root/globals")
    var blocks = self.get_children()
    var color = self._pick_random_color()
    for i in range(4):
        blocks[i].position = coords[i] * globals.TILE_SIZE
        blocks[i].get_node('Sprite2D').set_modulate(color)

#func _process(delta):
#	pass

func _pick_random_color():
    var options = [
        Color8(0, 200, 200),   # cyan
        Color8(200, 200, 0),   # yellow
        Color8(128, 0, 128),   # purple
        Color8(0, 200, 0),     # green
        Color8(200, 0, 0),     # red
        Color8(65, 65, 240),     # blue
        Color8(255, 127, 0),   # orange
        Color8(150, 150, 150), # gray
    ]
    return options[randi() % options.size()]

func set_tpos(tpos):
    self.tpos = tpos

func get_tpos():
    return self.tpos

func get_coords():
    return self.coords

func init(type, coords):
    self.type = type
    self.coords = coords
    self.size = 0
    if self.type == 'I':
        self.size = 1
