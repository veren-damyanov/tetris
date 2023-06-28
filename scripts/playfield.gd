extends Node2D

var globals
var matrix           # the board
var active_shape     # currently active (falling) shape
# note: current implementation can't support gravity higher than 1G
# var gravity = 0.0156 # 0.0156G
var gravity = 0.04   # 0.0156G
var gravity_sum = 0  # elapsed gravity since last downwards move
var das_delay = 1    # input delay in frames

var shape_map = {
    'I': [Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
    'J': [Vector2(-1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
    'L': [Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
    'O': [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
    'S': [Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), Vector2(0, 0)],
    'T': [Vector2(0, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
    'Z': [Vector2(-1, -1), Vector2(0, -1), Vector2(0, 0), Vector2(1, 0)],
}

func _ready():
    self.globals = get_node("/root/globals")
    self._init_matrix()
    self.active_shape = self._new_active_shape()
    self.add_child(self.active_shape)

func _process(delta):
    self.get_node('Label').set_text("FPS %d" % Engine.get_frames_per_second())
    self.gravity_sum += gravity
    self.das_delay += 1

    var left = Input.is_action_pressed("left")
    var right = Input.is_action_pressed("right")
    var space = Input.is_action_pressed("space")

    if self.das_delay >= 10:
        if left and not right:
            self.das_delay = 0
            if self._is_active_shape_movable(-1, 0):
                self._move_active_shape(-1, 0)
        elif right and not left:
            self.das_delay = 0
            if self._is_active_shape_movable(1, 0):
                self._move_active_shape(1, 0)

    if self.gravity_sum >= 1:
        self.gravity_sum = 0
        if self._is_active_shape_movable(0, 1):
            self._move_active_shape(0, 1)
        else:
            self._deactivate_current_shape()
            self.active_shape = self._new_active_shape()
            self.add_child(self.active_shape)

func _new_active_shape():
    var shape = self._new_shape()
    var x = globals.TILE_SIZE / 2 + globals.TILE_SIZE * 5
    var y = globals.TILE_SIZE / 2 + globals.TILE_SIZE * 0 + globals.OFFSET_Y
    shape.set_position(Vector2(x, y))
    shape.set_tpos(Vector2(5, 0))  # FIXME: this position is temporary, should be changed (also above ^^)
    return shape

func _deactivate_current_shape():
    var tpos = self.active_shape.get_tpos()
    var coords = self.active_shape.get_coords()
    for v in coords:
        var x = tpos.x + v.x
        var y = tpos.y + v.y
        self.matrix[x][y] = 1

func _is_active_shape_movable(dx, dy):
    var tpos = self.active_shape.get_tpos()
    var coords = self.active_shape.get_coords()
    for v in coords:
        var x = tpos.x + v.x + dx
        var y = tpos.y + v.y + dy
        if self.matrix[x][y] == 1:
            return false
    return true

func _move_active_shape(dx, dy):
    var tpos = self.active_shape.get_tpos()
    tpos.x += dx
    tpos.y += dy
    self.active_shape.set_tpos(tpos)
    var x = globals.TILE_SIZE / 2 + globals.TILE_SIZE * tpos.x
    var y = globals.TILE_SIZE / 2 + globals.TILE_SIZE * tpos.y + globals.OFFSET_Y
    self.active_shape.set_position(Vector2(x, y))

func _init_matrix():
    self.matrix = []
    for i in range(self.globals.FIELD_X+2):
        self.matrix.append([])
        for j in range(self.globals.FIELD_Y+2):
            if i == 0 or i == self.globals.FIELD_X+1:
                self.matrix[i].append(1)
            else:
                self.matrix[i].append(0)
        self.matrix[i].append(1)
    print(self.matrix)

func _randomize():
    var options = ['I', 'J', 'L', 'O', 'S', 'T', 'Z']
    return options[randi() % options.size()]

func _new_shape():
    var shape = preload("res://shape.tscn").instantiate()
    var type = self._randomize()
    shape.init(type, shape_map[type])
    return shape
