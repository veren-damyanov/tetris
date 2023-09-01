class ShapeProvider:

    const _SHAPES = ['I', 'J', 'L', 'O', 'S', 'T', 'Z']
    const _SHAPE_MAP = {
        'I': [Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
        'J': [Vector2(-1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
        'L': [Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
        'O': [Vector2(0, -1), Vector2(1, -1), Vector2(0, 0), Vector2(1, 0)],
        'S': [Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0)],
        'T': [Vector2(0, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
        'Z': [Vector2(-1, -1), Vector2(0, -1), Vector2(0, 0), Vector2(1, 0)]
    }
    const _COLOR_MAP = {
        'I': Color8(0, 200, 200), # cyan
        'J': Color8(65, 65, 240), # blue
        'L': Color8(255, 127, 0), # orange
        'O': Color8(200, 200, 0), # yellow
        'S': Color8(0, 200, 0),   # green
        'T': Color8(128, 0, 128), # purple
        'Z': Color8(200, 0, 0),   # red
    }

    var _queue

    func _init():
        self._queue = []

    func get_shape():
        if self._queue.size() == 0:
            self._queue = self._SHAPES.duplicate()
            self._queue.shuffle()
        var shape = preload("res://shape.tscn").instantiate()
        var type = self._queue.pop_front() # this is just the letter
        shape.init(type, self._SHAPE_MAP[type], self._COLOR_MAP[type])
        # shape.init(type, self._SHAPE_MAP[type], Color8(65, 255, 0, 200))
        return shape
    
    func get_ghost(active_shape_type):
        var shape = preload("res://shape.tscn").instantiate()
        shape.init(active_shape_type, self._SHAPE_MAP[active_shape_type], Color(1, 1, 1, 0.2))
        return shape
