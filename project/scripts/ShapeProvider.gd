

class ShapeProvider:
    const _shapes = ['I', 'J', 'L', 'O', 'S', 'T', 'Z']

    const _shape_map = {
        'I': [Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
        'J': [Vector2(-1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
        'L': [Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
        'O': [Vector2(0, -1), Vector2(1, -1), Vector2(0, 0), Vector2(1, 0)],
        'S': [Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0)],
        'T': [Vector2(0, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
        'Z': [Vector2(-1, -1), Vector2(0, -1), Vector2(0, 0), Vector2(1, 0)],
    }

    const _color_map = {
        'I': Color8(0, 200, 200), # cyan
        'J': Color8(65, 65, 240), # blue
        'L': Color8(255, 127, 0), # orange
        'O': Color8(200, 200, 0), # yellow
        'S': Color8(0, 200, 0),   # green
        'T': Color8(128, 0, 128), # purple
        'Z': Color8(200, 0, 0),   # red
    }

    var _queue
    # var _active_shape_type

    func _init():
        self._queue = []

    func get_shape():
        if self._queue.size() == 0:
            self._queue = _shapes.duplicate()
            self._queue.shuffle()
        
        var shape = preload("res://shape.tscn").instantiate()
        var type = self._queue.pop_front() # this is just the letter
        shape.init(type, self._shape_map[type], self._color_map[type])
        # self._active_shape_type = shape.get_type()
        return shape
    
    func get_ghost(active_shape_type):
        var shape = preload("res://shape.tscn").instantiate()
        # var active_shape_type = self.get_parent()
        shape.init(active_shape_type, self._shape_map[active_shape_type], Color(1, 1, 1, 0.2))
        return shape
