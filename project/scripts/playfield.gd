extends Node2D

const DAS = 2          # Delayed Auto Shift in frames
const DAS_DELAY = 10   # DAS delay in frames
const START_POSITION = Vector2(5, 0)
const NEXT_POSITION = Vector2(14, 4)
const NEXT_OFFSET = 3
const SP_CLASS = preload("res://scripts/shape_provider.gd").ShapeProvider

var _matrix             # the board
var _active_shape       # the currently active (falling) shape
var _ghost_shape        # the ghost of the current active shape
var _next_shapes = []   # the currently scheduled "next" shapes

var _das_flag = false   # determines if DAS is active
var _current_delay = 0  # frames until next input is legal
var _gravity = [
    0.01667, 0.021017, 0.026977, 0.035256, 0.04693,
    0.06361, 0.0879,0.1236, 0.1775, 0.2598, 0.388,
    0.59, 0.92, 1.46, 2.36, 3.91, 6.61, 11.43, 20, 20]
var _gravity_sum = 0    # helper to keep track of gravity
var _game_over = false  # game over flag
var _score = 0          # tracks the score
var _lines = 0          # tracks number of lines completed
var _level = 1          # tracks the level
var _move = 'N/A'       # tracks direction of movement

@onready var globals = $'/root/globals'        # importing globals
@onready var secrets = $'/root/secrets'        # importing secrets
@onready var _mobile_buttons = $Buttons         # mobile input handler
@onready var _shape_provider = SP_CLASS.new()   # generates shapes on demand

func _ready():
    randomize()
    # initialize some things
    self._init_matrix()
    self._setup_theme()
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
    if self._game_over:
        return
    # update labels
    $Layout/Score.set_text("%d" % self._score)
    $Layout/Level.set_text("%d" % self._level)
    $Layout/Lines.set_text("%d" % self._lines)
    # collect input
    var up_press = input[0]
    var down = input[1]
    var space_press = input[2]
    var escape = input[3]
    # pause (this is not a permanent feature)
    if escape:
        return
    # hard drop
    if space_press:
        self._hard_drop()
    # rotate
    if up_press:
        self._rotate_active_if_possible()
    # left-right movement
    self._current_delay -= 1
    if self._current_delay <= 0:
        var new_delay = self.DAS_DELAY
        if self._das_flag == true:
            new_delay = self.DAS
        if self._move == 'left':
            self._das_flag = true
            self._current_delay = new_delay
            if self._is_shape_movable(self._active_shape, -1, 0):
                self._move_active_shape(-1)
        elif self._move == 'right':
            self._das_flag = true
            self._current_delay = new_delay
            if self._is_shape_movable(self._active_shape, 1, 0):
                self._move_active_shape(1)
    # gravity and downwards acceleration
    if down:
        self._gravity_sum += max(0.4, self._gravity[self._level-1] * 1.5)
    else:
        self._gravity_sum += self._gravity[self._level-1]
    if self._gravity_sum >= 1:
        self._gravitate()

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
        self._move = 'left'
    elif right_press and not left_press:
        self._move = 'right'
    if left_release:
        self._das_flag = false
        self._move = 'N/A'
        if right:
            self._move = 'right'
    if right_release:
        self._das_flag = false
        self._move = 'N/A'
        if left:
            self._move = 'left'
    return [up_press, down, space_press, escape]

func _process_input_mobile():
    var escape = Input.is_action_pressed("escape") # TODO: Provide some alternative to this
    var left = self._mobile_buttons.left
    var left_press = self._mobile_buttons.left_press
    var left_release = self._mobile_buttons.left_release
    var right = self._mobile_buttons.right
    var right_press = self._mobile_buttons.right_press
    var right_release = self._mobile_buttons.right_release
    var up_press = self._mobile_buttons.up_press
    var down = self._mobile_buttons.down
    var space_press = self._mobile_buttons.space_press
    self._mobile_buttons.input_processed = true
    # work out logic of left/right movement
    if left_press and not right_press:
        self._move = 'left'
    elif right_press and not left_press:
        self._move = 'right'
    if left_release:
        self._das_flag = false
        self._move = 'N/A'
        if right:
            self._move = 'right'
    if right_release:
        self._das_flag = false
        self._move = 'N/A'
        if left:
            self._move = 'left'
    return [up_press, down, space_press, escape]

func _setup_theme():
    var tn = globals.THEME_NAMES[globals.current_theme]
    $PlayfieldSprite.set_texture(load('res://assets/' + tn + '/sprites/playfield.png'))
    $BackgroundSprite.set_texture(load('res://assets/' + tn + '/sprites/playfield-background.png'))
    $Layout.set_theme(load('res://assets/' + tn + '/themes/general.tres'))
    $Buttons.set_theme(load('res://assets/' + tn + '/themes/buttons.tres'))
    for btn in ['Drop', 'Hold', 'Rotate', 'Left', 'Down', 'Right']:
        var stylebox = StyleBoxTexture.new()
        stylebox.set_texture(load('res://assets/'+tn+'/sprites/'+btn.to_lower()+'-pressed.png'))
        $Buttons.get_node(btn).add_theme_stylebox_override('pressed', stylebox)

func _init_matrix():
    self._matrix = []
    for i in range(self.globals.FIELD_X+2):
        self._matrix.append([])
        for j in range(self.globals.FIELD_Y+1):
            if i == 0 or i == self.globals.FIELD_X+1:
                self._matrix[i].append([1, null])
            else:
                self._matrix[i].append([0, null])
        self._matrix[i].append([1, null])

func _coords_from_position(vector):
    var x = (vector.x - globals.TILE_SIZE / 2) / self.globals.TILE_SIZE
    var y = (vector.y - globals.TILE_SIZE / 2) / self.globals.TILE_SIZE
    return Vector2(x, y)
    
func _position_from_coords(vector):
    var x = globals.TILE_SIZE / 2 + globals.TILE_SIZE * vector.x
    var y = globals.TILE_SIZE / 2 + globals.TILE_SIZE * vector.y
    return Vector2(x, y)

func _update_next_shapes():
    for i in range(self._next_shapes.size()):
        var coords = Vector2(self.NEXT_POSITION.x, self.NEXT_POSITION.y + self.NEXT_OFFSET * i)
        self._next_shapes[i].set_position(self._position_from_coords(coords))
    while self._next_shapes.size() < 3:
        var next = self._shape_provider.get_shape()
        var coords = Vector2(self.NEXT_POSITION.x, self.NEXT_POSITION.y + self.NEXT_OFFSET * self._next_shapes.size())
        next.set_position(self._position_from_coords(coords))
        self.add_child(next)
        self._next_shapes.append(next)

func _setup_active_shape():
    # jumpstart the system when no next shape (start of game)
    if self._next_shapes.size() < 3:
        self._update_next_shapes()
    # move the "next" shape and make it active
    var next = self._next_shapes.pop_front()
    next.set_position(self._position_from_coords(self.START_POSITION))
    self._active_shape = next
    # create new "next" shape
    self._update_next_shapes()
    # create and setup ghost of active_shape
    var ghost = self._shape_provider.get_ghost(self._active_shape.get_type())
    ghost.set_position(self._position_from_coords(self.START_POSITION))
    while(self._is_shape_movable(ghost, 0, 1)):
        self._move_shape(ghost, 0, 1)
    self.add_child(ghost)
    self._ghost_shape = ghost

func _is_shape_movable(shape, dx, dy):
    var matrix_pos = self._coords_from_position(shape.get_position())
    var coords = shape.get_coords()
    for v in coords:
        var x = matrix_pos.x + v.x + dx
        var y = max(0, matrix_pos.y + v.y + dy)
        if self._matrix[x][y][0] == 1:
            return false
    return true

func _is_shape_out(shape):
    var matrix_pos = self._coords_from_position(shape.get_position())
    var coords = shape.get_coords()
    for v in coords:
        var x = matrix_pos.x + v.x
        var y = matrix_pos.y + v.y
        if x < 1 or y < 1:
            return true
    return false

func _move_shape(shape, dx, dy):
    var matrix_pos = self._coords_from_position(shape.get_position())
    matrix_pos.x += dx
    matrix_pos.y += dy
    shape.set_position(self._position_from_coords(matrix_pos))

func _move_active_shape(dx):
    self._move_shape(self._active_shape, dx, 0)
    self._ghost_shape.set_position(self._active_shape.get_position())
    while(self._is_shape_movable(self._ghost_shape, 0, 1)):
        self._move_shape(self._ghost_shape, 0, 1)

func _gravitate():
    self._gravity_sum = 0
    if self._is_shape_movable(self._active_shape, 0, 1):
        self._move_shape(self._active_shape, 0, 1)
    else:
        if self._is_shape_out(self._active_shape):
            self._game_over = true
            $Layout/Dialog.visible = true
            $Layout/Dialog/Container/NameInput.grab_focus()
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
        if self._matrix[matrix_pos.x+x][max(0, matrix_pos.y+y)][0] == 1:
            return
        new_coords.append(Vector2(x, y))
    shape.set_coords(new_coords)

func _rotate_active_if_possible():
    self._rotate_shape_if_possible(self._active_shape)
    self._ghost_shape.set_position(self._active_shape.get_position())
    self._rotate_shape_if_possible(self._ghost_shape)
    while(self._is_shape_movable(self._ghost_shape, 0, 1)):
        self._move_shape(self._ghost_shape, 0, 1)

func _hard_drop():
    while (self._is_shape_movable(self._active_shape, 0, 1)):
        self._move_shape(self._active_shape, 0, 1)
    self._gravitate()

func _deactivate_current_shape():
    var matrix_pos = self._coords_from_position(self._active_shape.get_position())
    var coords = self._active_shape.get_coords()
    var blocks = self._active_shape.get_blocks()
    for i in range(coords.size()):
        var x = matrix_pos.x + coords[i].x
        var y = matrix_pos.y + coords[i].y
        self._matrix[x][y][0] = 1
        self._matrix[x][y][1] = blocks[i]
        self._active_shape.remove_child(blocks[i])
        self.add_child(blocks[i])
        blocks[i].set_position(self._position_from_coords(Vector2(x, y)))
    self._active_shape.queue_free()
    self._ghost_shape.queue_free()
    self._clear_lines()

func _move_block(block, dx, dy):
    var v = self._coords_from_position(block.get_position())
    self._matrix[v.x][v.y][0] = 0
    self._matrix[v.x][v.y][1] = null
    v.y += dy
    block.set_position(self._position_from_coords(v))
    self._matrix[v.x][v.y][0] = 1
    self._matrix[v.x][v.y][1] = block

func _clear_lines():
    var cleared_lines = []
    for i in range(self.globals.FIELD_Y, 0, -1):
        var line_full = true
        for j in range(1, self.globals.FIELD_X+1):
            if self._matrix[j][i][0] == 0:
                line_full = false
                break
        if line_full == true:
            for j in range(1, self.globals.FIELD_X+1):
                self._matrix[j][i][0] = 0
                self.remove_child(self._matrix[j][i][1])
                self._matrix[j][i][1] = null
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
            if self._matrix[j][i][1] != null:
                self._move_block(self._matrix[j][i][1], 0, q)
        await get_tree().create_timer(0.02).timeout  # TODO: reconsider this

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
        cr.set_position(Vector2(50 + self._level*2, 205))
        cr.set_size(Vector2(2, 2))
        self.add_child(cr)

func _update_stats(cleared_lines):
    var bases_map = { 1: 40, 2: 100, 3: 300, 4: 1200 }
    var base = bases_map[cleared_lines.size()]
    self._score += (self._level + 1) * base
    self._lines += cleared_lines.size()
    var new_level = self._level < 1 + min(18, self._lines / 10)
    self._level = 1 + min(18, self._lines / 10)
    self._update_stats_visual(new_level, cleared_lines.size())

func _on_exit_button_pressed():
    var name = $Layout/Dialog/Container/NameInput.get_text()
    # not saving if dev, or no secret token, or no name
    if globals.agent == 'dev' or secrets == null or name.length() < 1:
        self.get_tree().change_scene_to_file("res://menu.tscn")
        return
    $HTTPRequest.request_completed.connect(_on_request_completed)
    $HTTPRequest.request("https://www.dreamlo.com/lb/"+secrets.HTTP_TOKEN+"/add/"+name+"/"+str(self._score))

func _on_request_completed(result, response_code, headers, body):
    globals.high_scores = []
    self.get_tree().change_scene_to_file("res://menu.tscn")

func _on_name_input_focus_entered():
    DisplayServer.virtual_keyboard_show("")

func _on_name_input_focus_exited():
    DisplayServer.virtual_keyboard_hide()
