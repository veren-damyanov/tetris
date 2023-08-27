extends Control

var globals


func _ready():
    globals = $'/root/globals'
    self._setup_theme()
    $MainContainer/BackButton.grab_focus()
    # load by http only if necessary
    if globals.high_scores == []:
        $HTTPRequest.request_completed.connect(_on_request_completed)
        $HTTPRequest.request("https://www.dreamlo.com/lb/64eb3a5c8f40bb0ee0660c0a/json/10")
    else: 
        self._display_scores()

func _on_request_completed(result, response_code, headers, body):
    if response_code == 200:
        var json = JSON.parse_string(body.get_string_from_utf8())
        if json == null or json["dreamlo"] == null or json["dreamlo"]["leaderboard"] == null:
            print('Something went wrong with the leaderboard request.')
            return
        var entries = json["dreamlo"]["leaderboard"]["entry"]
        # somehow its not a list when there's only one record (!?)
        if typeof(entries) == 27:
            globals.high_scores = [entries]
        else:
            globals.high_scores = entries
        self._display_scores()

func _display_scores():
        print(globals.high_scores)
        for rec in globals.high_scores:
            var label_name = Label.new()
            label_name.set_text(rec["name"])
            $MainContainer/ScoresContainer.add_child(label_name)
            var label_score = Label.new()
            label_score.set_text(rec["score"])
            label_score.set_h_size_flags(10)
            $MainContainer/ScoresContainer.add_child(label_score)

func _setup_theme():
    var tn = globals.THEME_NAMES[globals.current_theme]
    $MenuBackground.set_texture(load('res://assets/' + tn + '/sprites/menu.png'))
    $MainContainer.theme = load('res://assets/' + tn + '/themes/general.tres')
    $MainContainer/ScoresContainer/NameLabel.add_theme_stylebox_override('normal', load('res://assets/' + tn + '/themes/underline.tres'))
    $MainContainer/ScoresContainer/ScoreLabel.add_theme_stylebox_override('normal', load('res://assets/' + tn + '/themes/underline.tres'))

func _on_back_button_pressed():
    self.get_tree().change_scene_to_file("res://menu.tscn")
