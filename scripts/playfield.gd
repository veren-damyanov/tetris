extends Node2D

const DAS = 8          # input delay in frames
const START_POSITION = Vector2(5, 0)

var globals            # for importing globals
var matrix             # the board
var active_shape       # the currently active (falling) shape
var das_elapsed = 0    # time elapsed since last input
var gravity = [
    0.01667, 0.021017, 0.026977, 0.035256, 0.04693,
    0.06361, 0.0879,0.1236, 0.1775, 0.2598, 0.388,
    0.59, 0.92, 1.46, 2.36, 3.91, 6.61, 11.43, 20
]
var gravity_sum = 0    # helper to keep track of gravity
var fast_mode = false  # regulates when we use fast gravity
var game_over = false  # game over flag
var score = 0          # tracks the score
var lines = 0          # tracks number of lines completed
var level = 1          # tracks the level

var shape_map = {
    'I': [Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
    'J': [Vector2(-1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
    'L': [Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
    'O': [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
    'S': [Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0)],
    'T': [Vector2(0, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
    'Z': [Vector2(-1, -1), Vector2(0, -1), Vector2(0, 0), Vector2(1, 0)],
}

var color_map = {
    'I': Color8(0, 200, 200), # cyan
    'J': Color8(65, 65, 240), # blue
    'L': Color8(255, 127, 0), # orange
    'O': Color8(200, 200, 0), # yellow
    'S': Color8(0, 200, 0),   # green
    'T': Color8(128, 0, 128), # purple
    'Z': Color8(200, 0, 0),   # red
}

func _ready():
    self.globals = get_node("/root/globals")
    self._init_matrix()
    self.active_shape = self._new_active_shape()
    self.add_child(self.active_shape)

func _process(delta):
    # update labels
    self.get_node('Score').set_text("[center][b]%d[/b][/center]" % self.score)
    self.get_node('Level').set_text("[center][b]%d[/b][/center]" % self.level)
    self.get_node('Lines').set_text("[center][b]%d[/b][/center]" % self.lines)
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
        self.gravity_sum += max(0.4, self.gravity[self.level-1] * 2)
    else:
        self.gravity_sum += self.gravity[self.level-1]
    if self.gravity_sum >= 1:
        self.gravity_sum = 0
        if self._is_active_shape_movable(0, 1):
            self._move_active_shape(0, 1)
        else:
            if self._coords_from_position(self.active_shape.get_position()) == self.START_POSITION:
                self.game_over = true
                self.get_node('Label').set_text("GAME OVER")
                return
            self._deactivate_current_shape()
            self.active_shape = self._new_active_shape()
            self.add_child(self.active_shape)

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

func _coords_from_position(vector):
    var x = (vector.x - globals.TILE_SIZE / 2) / self.globals.TILE_SIZE
    var y = (vector.y - globals.TILE_SIZE / 2) / self.globals.TILE_SIZE
    return Vector2(x, y)
    
func _position_from_coords(vector):
    var x = globals.TILE_SIZE / 2 + globals.TILE_SIZE * vector.x
    var y = globals.TILE_SIZE / 2 + globals.TILE_SIZE * vector.y
    return Vector2(x, y)

func _randomize():
    var options = ['I', 'J', 'L', 'O', 'S', 'T', 'Z']
    return options[randi() % options.size()]

func _new_shape():
    var shape = preload("res://shape.tscn").instantiate()
    var type = self._randomize()
    shape.init(type, self.shape_map[type], self.color_map[type])
    return shape

func _new_active_shape():
    var shape = self._new_shape()
    shape.set_position(self._position_from_coords(self.START_POSITION))
    return shape

func _is_active_shape_movable(dx, dy):
    var matrix_pos = self._coords_from_position(self.active_shape.get_position())
    var coords = self.active_shape.get_coords()
    for v in coords:
        var x = matrix_pos.x + v.x + dx
        var y = matrix_pos.y + v.y + dy
        if self.matrix[x][y][0] == 1:
            return false
    return true

func _move_active_shape(dx, dy):
    var matrix_pos = self._coords_from_position(self.active_shape.get_position())
    matrix_pos.x += dx
    matrix_pos.y += dy
    self.active_shape.set_position(self._position_from_coords(matrix_pos))

func _rotate_active_if_possible():
    var new_coords = []
    var size = self.active_shape.get_size()
    var matrix_pos = self._coords_from_position(self.active_shape.get_position())
    for v in self.active_shape.get_coords():
        var x = size - v.y
        var y = v.x
        if self.matrix[matrix_pos.x+x][matrix_pos.y+y][0] == 1:
            return
        new_coords.append(Vector2(x, y))
    self.active_shape.set_coords(new_coords)

func _deactivate_current_shape():
    var matrix_pos = self._coords_from_position(self.active_shape.get_position())
    var coords = self.active_shape.get_coords()
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

func _move_block(block, dx, dy):
    var v = self._coords_from_position(block.get_position())
    self.matrix[v.x][v.y][0] = 0
    self.matrix[v.x][v.y][1] = null
    v.y += dy
    block.set_position(self._position_from_coords(v))
    self.matrix[v.x][v.y][0] = 1
    self.matrix[v.x][v.y][1] = block

func _clear_lines():
    var cleared_lines = []
    for i in range(self.globals.FIELD_Y, 0, -1):
        var line_full = true
        for j in range(1, self.globals.FIELD_X+1):
            if self.matrix[j][i][0] == 0:
                line_full = false
                break
        if line_full == true:
            for j in range(1, self.globals.FIELD_X+1):
                self.matrix[j][i][0] = 0
                self.remove_child(self.matrix[j][i][1])
                self.matrix[j][i][1] = null
            cleared_lines.append(i)
    if cleared_lines:
        self._update_stats(cleared_lines)
        self._settle_board(cleared_lines)

func _settle_board(cleared_lines):
    cleared_lines.sort()
    cleared_lines.reverse()
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
                await get_tree().create_timer(0.008).timeout

func _update_stats(lines):
    var bases_map = { 1: 40, 2: 100, 3: 300, 4: 1200 }
    var base = bases_map[lines.size()]
    self.score += (self.level + 1) * base
    self.lines += lines.size()
    self.level = 1 + min(18, self.lines / 10)
