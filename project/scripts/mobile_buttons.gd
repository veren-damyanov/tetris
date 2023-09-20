extends GridContainer

var left = false
var left_press = false
var left_release = false
var right = false
var right_press = false
var right_release = false
var up_press = false
var down = false
var space_press = false
var shift_press = false
# var escape = false
var input_processed = false

func _process(_delta):
    if self.input_processed:
        if self.space_press:
            self.space_press = false
        if self.shift_press:
            self.shift_press = false
        if self.up_press:
            self.up_press = false
        if self.left_press:
            self.left_press = false
        if self.left_release:
            self.left_release = false
        if self.right_press:
            self.right_press = false
        if self.right_release:
            self.right_release = false
        self.input_processed = false

func _on_btn_drop_button_down():
    self.space_press = true

func _on_btn_drop_button_up():
    pass # remove?

func _on_btn_hold_button_down():
    self.shift_press = true

func _on_btn_hold_button_up():
    pass # remove?

func _on_btn_rotate_button_down():
    self.up_press = true

func _on_btn_rotate_button_up():
    pass # remove?

func _on_btn_left_button_down():
    self.left = true
    self.left_press = true

func _on_btn_left_button_up():
    self.left = false
    self.left_release = true

func _on_btn_down_button_down():
    self.down = true

func _on_btn_down_button_up():
    self.down = false

func _on_btn_right_button_down():
    self.right = true
    self.right_press = true

func _on_btn_right_button_up():
    self.right = false
    self.right_release = true
