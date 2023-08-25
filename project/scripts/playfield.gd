extends Node2D

const DAS = 2          # Delayed Auto Shift in frames
const DAS_DELAY = 10   # DAS delay in frames
const START_POSITION = Vector2(5, 0)
const NEXT_POSITION = Vector2(14, 4)
const NEXT_OFFSET = 3

const ShapeProvider = preload("res://scripts/ShapeProvider.gd").ShapeProvider

var globals            # for importing globals
var matrix             # the board

var active_shape       # the currently active (falling) shape
var next_shapes = []   # the currently scheduled "next" shape
var ghost_shape        # the ghost of the current active shape

var das_flag = false   # determines if DAS is active
var current_delay = 0  # frames until next input is legal
var gravity = [
    0.01667, 0.021017, 0.026977, 0.035256, 0.04693,
    0.06361, 0.0879,0.1236, 0.1775, 0.2598, 0.388,
    0.59, 0.92, 1.46, 2.36, 3.91, 6.61, 11.43, 20, 20]
var gravity_sum = 0    # helper to keep track of gravity
var game_over = false  # game over flag
var score = 0          # tracks the score
var lines = 0          # tracks number of lines completed
var level = 1          # tracks the level
var move = 'N/A'       # tracks direction of movement

var shape_provider
@onready var mb = $Buttons

func _ready():
    randomize()
    # initialize some things
    self.shape_provider = ShapeProvider.new()
    self.globals = $'/root/globals'
    self._init_matrix()
    self._setup_theme()
    self.next_shapes
    # set up viewport according to the layout
    match globals.current_layout:
        globals.LAYOUT.DESKTOP:
            $'/root'.set_content_scale_size(Vector2i(144, 215))
        globals.LAYOUT.MOBILE:
            $'/root'.set_content_scale_size(Vector2i(144, 279))
    # create new active shape
    self._setup_active_shape()
    self._update_stats_visual(true, 0)

func _process(delta):
    var input = self._process_input()
    if self.game_over:
        if input[2]:
            self.get_tree().change_scene_to_file("res://menu.tscn")
            $'/root'.set_content_scale_size(Vector2i(144, 279))
        return
    # update labels
    $Text/Score.set_text("%d" % self.score)
    $Text/Level.set_text("%d" % self.level)
    $Text/Lines.set_text("%d" % self.lines)
    # collect input
    var up_press = input[0]
    var down = input[1]
    var space_press = input[2]
    var escape = input[3]
    # pause (this is probably not a permanent feature)
    if escape:
        return
    # hard drop
    if space_press:
        self._hard_drop()
    # rotate
    if up_press:
        self._rotate_active_if_possible()
    # left-right movement
    self.current_delay -= 1
    if self.current_delay <= 0:
        var new_delay = self.DAS_DELAY
        if self.das_flag == true:
            new_delay = self.DAS
        if self.move == 'left':
            self.das_flag = true
            self.current_delay = new_delay
            if self._is_shape_movable(self.active_shape, -1, 0):
                self._move_active_shape(-1)
        elif self.move == 'right':
            self.das_flag = true
            self.current_delay = new_delay
            if self._is_shape_movable(self.active_shape, 1, 0):
                self._move_active_shape(1)
    # gravity and downwards acceleration
    if down:
        self.gravity_sum += max(0.4, self.gravity[self.level-1] * 1.5)
    else:
        self.gravity_sum += self.gravity[self.level-1]
    if self.gravity_sum >= 1:
        self._gravity()

func _process_input():
    match globals.current_layout:
        globals.LAYOUT.DESKTOP:
            return self._process_input_desktop()
        globals.LAYOUT.MOBILE:
            return self._process_input_mobile()

func _process_input_desktop():
    var left = Input.is_action_pressed("left")
    var left_press = Input.is_action_just_pressed("left")
    var left_release = Input.is_action_just_released("left")
    var right = Input.is_action_pressed("right")
    var right_press = Input.is_action_just_pressed("right")
    var right_release = Input.is_action_just_released("right")
    var up_press = Input.is_action_just_pressed("up")
    var down = Input.is_action_pressed("down")
    var space_press = Input.is_action_just_pressed("space")
    var escape = Input.is_action_pressed("escape")
    # work out logic of left/right movement
    if left_press and not right_press:
        self.move = 'left'
    elif right_press and not left_press:
        self.move = 'right'
    if left_release:
        self.das_flag = false
        self.move = 'N/A'
        if right:
            self.move = 'right'
    if right_release:
        self.das_flag = false
        self.move = 'N/A'
        if left:
            self.move = 'left'
    return [up_press, down, space_press, escape]

func _process_input_mobile():
    var escape = Input.is_action_pressed("escape") # TODO: Provide some alternative to this
    var left = mb.left
    var left_press = mb.left_press
    var left_release = mb.left_release
    var right = mb.right
    var right_press = mb.right_press
    var right_release = mb.right_release
    var up_press = mb.up_press
    var down = mb.down
    var space_press = mb.space_press
    mb.input_processed = true
    # work out logic of left/right movement
    if left_press and not right_press:
        self.move = 'left'
    elif right_press and not left_press:
        self.move = 'right'
    if left_release:
        self.das_flag = false
        self.move = 'N/A'
        if right:
            self.move = 'right'
    if right_release:
        self.das_flag = false
        self.move = 'N/A'
        if left:
            self.move = 'left'
    return [up_press, down, space_press, escape]

func _setup_theme():
    var tn = globals.THEME_NAMES[globals.current_theme]
    $PlayfieldSprite.set_texture(load('res://assets/' + tn + '/sprites/playfield.png'))
    $BackgroundSprite.set_texture(load('res://assets/' + tn + '/sprites/playfield-background.png'))
    $Text.set_theme(load('res://assets/' + tn + '/themes/text-general.tres'))
    $Buttons.set_theme(load('res://assets/' + tn + '/themes/buttons.tres'))
    for btn in ['Drop', 'Hold', 'Rotate', 'Left', 'Down', 'Right']:
        var stylebox = StyleBoxTexture.new()
        stylebox.set_texture(load('res://assets/'+tn+'/sprites/'+btn.to_lower()+'-pressed.png'))
        $Buttons.get_node(btn).add_theme_stylebox_override('pressed', stylebox)

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

func _update_next_shapes():
    for i in range(self.next_shapes.size()):
        var coords = Vector2(self.NEXT_POSITION.x, self.NEXT_POSITION.y + self.NEXT_OFFSET * i)
        self.next_shapes[i].set_position(self._position_from_coords(coords))
    while self.next_shapes.size() < 3:
        var next = self.shape_provider.get_shape()
        var coords = Vector2(self.NEXT_POSITION.x, self.NEXT_POSITION.y + self.NEXT_OFFSET * self.next_shapes.size())
        next.set_position(self._position_from_coords(coords))
        self.add_child(next)
        self.next_shapes.append(next)

func _setup_active_shape():
    # jumpstart the system when no next shape (start of game)
    if self.next_shapes.size() < 3:
        self._update_next_shapes()
    # move the "next" shape and make it active
    var next = self.next_shapes.pop_front()
    next.set_position(self._position_from_coords(self.START_POSITION))
    self.active_shape = next
    # create new "next" shape
    self._update_next_shapes()
    # create and setup ghost of active_shape
    var ghost = self.shape_provider.get_ghost(self.active_shape.get_type())
    ghost.set_position(self._position_from_coords(self.START_POSITION))
    while(self._is_shape_movable(ghost, 0, 1)):
        self._move_shape(ghost, 0, 1)
    self.add_child(ghost)
    self.ghost_shape = ghost

func _is_shape_movable(shape, dx, dy):
    var matrix_pos = self._coords_from_position(shape.get_position())
    var coords = shape.get_coords()
    for v in coords:
        var x = matrix_pos.x + v.x + dx
        var y = max(0, matrix_pos.y + v.y + dy)
        if self.matrix[x][y][0] == 1:
            return false
    return true

func _move_shape(shape, dx, dy):
    var matrix_pos = self._coords_from_position(shape.get_position())
    matrix_pos.x += dx
    matrix_pos.y += dy
    shape.set_position(self._position_from_coords(matrix_pos))

func _move_active_shape(dx):
    self._move_shape(self.active_shape, dx, 0)
    self.ghost_shape.set_position(self.active_shape.get_position())
    while(self._is_shape_movable(self.ghost_shape, 0, 1)):
        self._move_shape(self.ghost_shape, 0, 1)

func _gravity():
    self.gravity_sum = 0
    if self._is_shape_movable(self.active_shape, 0, 1):
        self._move_shape(self.active_shape, 0, 1)
    else:
        if self._coords_from_position(self.active_shape.get_position()) == self.START_POSITION:
            self.game_over = true
            $Text/GameOver.set_text("GAME OVER")
            return
        self._deactivate_current_shape()
        self._setup_active_shape()

func _rotate_shape_if_possible(shape):
    var new_coords = []
    var size = shape.get_size()
    var matrix_pos = self._coords_from_position(shape.get_position())
    for v in shape.get_coords():
        var x = size - v.y
        var y = v.x
        if self.matrix[matrix_pos.x+x][max(0, matrix_pos.y+y)][0] == 1:
            return
        new_coords.append(Vector2(x, y))
    shape.set_coords(new_coords)

func _rotate_active_if_possible():
    self._rotate_shape_if_possible(self.active_shape)
    self.ghost_shape.set_position(self.active_shape.get_position())
    self._rotate_shape_if_possible(self.ghost_shape)
    while(self._is_shape_movable(self.ghost_shape, 0, 1)):
        self._move_shape(self.ghost_shape, 0, 1)

func _hard_drop():
    while (self._is_shape_movable(self.active_shape, 0, 1)):
        self._move_shape(self.active_shape, 0, 1)
    self._gravity()

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
    self.ghost_shape.queue_free()
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
        await get_tree().create_timer(0.02).timeout

func _update_stats_visual(new_level, cleared_lines):
    if globals.current_theme != globals.THEME.RETRO:
        return
    for i in range(1, 5):
        var status = false
        if i <= cleared_lines:
            status = true
        $PlayfieldSprite.get_node('Lamp' + str(i)).visible = status
    if new_level:
        var cr = ColorRect.new()
        cr.color = Color(Color8(65, 255, 0), 150/255.0)
        cr.set_position(Vector2(50 + self.level*2, 205))
        cr.set_size(Vector2(2, 2))
        self.add_child(cr)

func _update_stats(cleared_lines):
    var bases_map = { 1: 40, 2: 100, 3: 300, 4: 1200 }
    var base = bases_map[cleared_lines.size()]
    self.score += (self.level + 1) * base
    self.lines += cleared_lines.size()
    var new_level = self.level < 1 + min(18, self.lines / 10)
    self.level = 1 + min(18, self.lines / 10)
    self._update_stats_visual(new_level, cleared_lines.size())
