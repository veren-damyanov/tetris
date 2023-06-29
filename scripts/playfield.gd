extends Node2D

const DAS = 8          # input delay in frames

var globals            # for importing globals
var matrix             # the board
var active_shape       # the currently active (falling) shape
var das_elapsed = 0    # time elapsed since last input
var gravity = 0.04     # gravity measured in tiles per frame # 0.0156G
var gravity_fast = 0.4 # gravity increase when down button is held
var gravity_sum = 0    # helper to keep track of gravity
var fast_mode = false  # regulates when we use fast gravity
var game_over = false  # game over flag
var starting_position = Vector2(5, 0)
# var graveyard = []   # storage for inactive shapes

var shape_map = {
    'I': [Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
    'J': [Vector2(-1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
    'L': [Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
    'O': [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
    'S': [Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0)],
    'T': [Vector2(0, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
    'Z': [Vector2(-1, -1), Vector2(0, -1), Vector2(0, 0), Vector2(1, 0)],
}

func _ready():
    self.globals = get_node("/root/globals")
    self._init_matrix()
    self.active_shape = self._new_active_shape()
    self.add_child(self.active_shape)

func _process(delta):
    # initialize stuff
    # self.get_node('Label').set_text("FPS %d" % Engine.get_frames_per_second())
    # var v = self.active_shape.get_position()
    # self.get_node('Label').set_text("x: %d, y: %d" % [v.x, v.y])
    # var v = self._coords_from_position(self.active_shape.get_position())
    # self.get_node('Label').set_text("x: %d, y: %d" % [v.x, v.y])
    if self.game_over:
        return
    # collect input
    var left = Input.is_action_pressed("left")
    var right = Input.is_action_pressed("right")
    var down = Input.is_action_pressed("down")
    var space = Input.is_action_pressed("space")
    var escape = Input.is_action_pressed("escape")
    if escape:
        return
    # process input and move
    self.das_elapsed += 1
    if not down:
        self.fast_mode = false
    if self.das_elapsed >= self.DAS:
        if left and not (right or down or space):
            self.das_elapsed = 0
            if self._is_active_shape_movable(-1, 0):
                self._move_active_shape(-1, 0)
        elif right and not (left or down or space):
            self.das_elapsed = 0
            if self._is_active_shape_movable(1, 0):
                self._move_active_shape(1, 0)
        elif space and not (left or right or down):
            self.das_elapsed = 0
            self._rotate_active_if_possible()
        elif down and not (left or right or space):
            self.das_elapsed = 0
            self.fast_mode = true
    # process gravity
    if fast_mode:
        self.gravity_sum += self.gravity_fast
    else:
        self.gravity_sum += self.gravity
    if self.gravity_sum >= 1:
        self.gravity_sum = 0
        if self._is_active_shape_movable(0, 1):
            self._move_active_shape(0, 1)
        else:
            if self._coords_from_position(self.active_shape.get_position()) == self.starting_position:
                self.game_over = true
                self.get_node('Label').set_text("GAME OVER")
                return
            self._deactivate_current_shape()
            self.active_shape = self._new_active_shape()
            self.add_child(self.active_shape)

func _rotate_active_if_possible():
    var new_coords = []
    var size = self.active_shape.get_size()
    # var tpos = self.active_shape.get_tpos()
    var matrix_pos = self._coords_from_position(self.active_shape.get_position())
    for v in self.active_shape.get_coords():
        var x = size - v.y
        var y = v.x
        if self.matrix[matrix_pos.x+x][matrix_pos.y+y][0] == 1:
            return
        new_coords.append(Vector2(x, y))
    self.active_shape.set_coords(new_coords)

func _new_active_shape():
    var shape = self._new_shape()
    shape.set_position(self._position_from_coords(self.starting_position))
    # shape.set_tpos(Vector2(5, 0))
    return shape

func _deactivate_current_shape():
    # var tpos = self.active_shape.get_tpos()
    var matrix_pos = self._coords_from_position(self.active_shape.get_position())
    var coords = self.active_shape.get_coords()
    # self.graveyard += self.active_shape.get_blocks()
    var blocks = self.active_shape.get_blocks()
    for i in range(coords.size()):
        var x = matrix_pos.x + coords[i].x
        var y = matrix_pos.y + coords[i].y
        self.matrix[x][y][0] = 1
        self.matrix[x][y][1] = blocks[i]
        self.active_shape.remove_child(blocks[i])
        self.add_child(blocks[i])
        blocks[i].set_position(self._position_from_coords(Vector2(x, y)))
    self.active_shape.queue_free()
    self._clear_lines()

func _clear_lines():
    var cleared_lines = []
    for i in range(self.globals.FIELD_Y, 0, -1):
        var line_full = true
        for j in range(1, self.globals.FIELD_X+1):
            if self.matrix[j][i][0] == 0:
                line_full = false
                break
        if line_full == true:
            print('line %d is full! clearing!' % i)
            for j in range(1, self.globals.FIELD_X+1):
                self.matrix[j][i][0] = 0
                self.remove_child(self.matrix[j][i][1])
                self.matrix[j][i][1] = null
            cleared_lines.append(i)
    if cleared_lines:
        self._settle_board(cleared_lines)
#            for k in range(i, 0, -1):
#                for l in range(1, self.globals.FIELD_X+1):
#                    if self.matrix[l][k][1] == null:
#                        continue
#                    self._move_block(self.matrix[l][k][1], 0, 1)

func _settle_board(cleared_lines):
    cleared_lines.sort()
    cleared_lines.reverse()
    print(cleared_lines)
    for i in range(self.globals.FIELD_Y, 0, -1):
        if i > cleared_lines[0] or i in cleared_lines:
            continue
        var q = 0
        for n in cleared_lines:
            if i > n:
                break
            q += 1
        for j in range(1, self.globals.FIELD_X+1):
            if self.matrix[j][i][1] != null:
                self._move_block(self.matrix[j][i][1], 0, q)
                await get_tree().create_timer(0.01).timeout

func _move_block(block, dx, dy):
    var v = self._coords_from_position(block.get_position())
    self.matrix[v.x][v.y][0] = 0
    self.matrix[v.x][v.y][1] = null
    v.y += dy
    block.set_position(self._position_from_coords(v))
    self.matrix[v.x][v.y][0] = 1
    self.matrix[v.x][v.y][1] = block
    

#func _settle_board():
#    for i in range(self.globals.FIELD_Y, 0, -1):
#        for j in range(1, self.globals.FIELD_X+1):
#            if self.matrix[j][i][1] != null:
#                self._drop_block(self.matrix[j][i][1])
#
#func _drop_block(block):
#    var v = self._coords_from_position(block.get_position())
#    var lowest = v.y
#    while lowest < 25:
#        if self.matrix[v.x][lowest+1][0] == 1:
#            break
#        lowest += 1
#    block.set_position(self._position_from_coords(Vector2(v.x, lowest)))
#    self.matrix[v.x][v.y][0] = 0
#    self.matrix[v.x][lowest][0] = 1
    

func _coords_from_position(vector):
    var x = (vector.x - globals.TILE_SIZE / 2) / self.globals.TILE_SIZE
    var y = (vector.y - globals.TILE_SIZE / 2) / self.globals.TILE_SIZE
    return Vector2(x, y)
    
func _position_from_coords(vector):
    var x = globals.TILE_SIZE / 2 + globals.TILE_SIZE * vector.x
    var y = globals.TILE_SIZE / 2 + globals.TILE_SIZE * vector.y
    return Vector2(x, y)

func _is_active_shape_movable(dx, dy):
    # var tpos = self.active_shape.get_tpos()
    var matrix_pos = self._coords_from_position(self.active_shape.get_position())
    var coords = self.active_shape.get_coords()
    for v in coords:
        var x = matrix_pos.x + v.x + dx
        var y = matrix_pos.y + v.y + dy
        if self.matrix[x][y][0] == 1:
            return false
    return true

func _move_active_shape(dx, dy):
    # var tpos = self.active_shape.get_tpos()
    var matrix_pos = self._coords_from_position(self.active_shape.get_position())
    matrix_pos.x += dx
    matrix_pos.y += dy
    # self.active_shape.set_tpos(matrix_pos)
    # var x = globals.TILE_SIZE / 2 + globals.TILE_SIZE * matrix_pos.x
    # var y = globals.TILE_SIZE / 2 + globals.TILE_SIZE * matrix_pos.y
    self.active_shape.set_position(self._position_from_coords(matrix_pos))

func _init_matrix():
    self.matrix = []
    for i in range(self.globals.FIELD_X+2):
        self.matrix.append([])
        for j in range(self.globals.FIELD_Y+1):
            if i == 0 or i == self.globals.FIELD_X+1:
                self.matrix[i].append([1, null])
            else:
                self.matrix[i].append([0, null])
        self.matrix[i].append([1, null])
    # print(matrix)

func _randomize():
    var options = ['I', 'J', 'L', 'O', 'S', 'T', 'Z']
    return options[randi() % options.size()]

func _new_shape():
    var shape = preload("res://shape.tscn").instantiate()
    var type = self._randomize()
    shape.init(type, self.shape_map[type])
    return shape
