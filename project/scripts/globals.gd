extends Node

const FIELD_X = 10 # x size of playfield in tiles
const FIELD_Y = 20 # y size of playfield in tiles
const TILE_SIZE = 8 # size of one tile in pixels

enum LAYOUT {DESKTOP = 0, MOBILE = 1}
var current_layout = LAYOUT.DESKTOP
