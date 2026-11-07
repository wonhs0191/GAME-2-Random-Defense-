extends Node

# 한 판의 런타임 상태. 게임 씬이 시작될 때 reset으로 초기화한다.

signal gold_changed(gold: int)
signal lives_changed(lives: int)
signal game_ended(cleared: bool)

const START_GOLD := 100
const GACHA_COST := 20

var gold: int = 0
var lives: int = 0
var is_over: bool = false

func reset(start_lives: int) -> void:
	gold = START_GOLD
	lives = start_lives
	is_over = false
	gold_changed.emit(gold)
	lives_changed.emit(lives)

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

# 골드가 충분하면 차감하고 true를 돌려준다.
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	add_gold(-amount)
	return true

func lose_lives(amount: int) -> void:
	if is_over:
		return
	lives = max(lives - amount, 0)
	lives_changed.emit(lives)
	if lives == 0:
		end_game(false)

func end_game(cleared: bool) -> void:
	if is_over:
		return
	is_over = true
	game_ended.emit(cleared)
