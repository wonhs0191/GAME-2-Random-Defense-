extends Node
class_name AugmentManager

# 증강 진행을 담당한다. 뽑기 5회마다, 보스를 잡을 때마다 카드를 제시하고,
# 고른 증강은 격자 위 구역이 된다. 카드 선택과 구역 배치가 끝날 때까지 게임은 멈춘다.

signal offered(cards: Array[AugmentData])
signal placement_started(augment: AugmentData)
signal closed

const DRAWS_PER_OFFER := 5
const CARD_COUNT := 3

var draws_until_offer: int = DRAWS_PER_OFFER
var pending_offers: int = 0
var cards: Array[AugmentData] = []
var placing: AugmentData = null

var _grid: GridManager = null

func setup(grid: GridManager) -> void:
	_grid = grid
	_grid.zone_placed.connect(_on_zone_placed)

func is_busy() -> bool:
	return placing != null or not cards.is_empty()

func on_unit_drawn() -> void:
	draws_until_offer -= 1
	if draws_until_offer == 0:
		draws_until_offer = DRAWS_PER_OFFER
		request_offer()

# 이미 고르는 중이면 대기시켰다가 끝난 뒤 이어서 제시한다.
func request_offer() -> void:
	pending_offers += 1
	if not is_busy():
		_offer_next()

func choose(index: int) -> void:
	placing = cards[index]
	cards.clear()
	_grid.begin_zone_placement(placing.zone_size, placing.get_color())
	placement_started.emit(placing)

func _offer_next() -> void:
	pending_offers -= 1
	_grid.cancel_drag() # 드래그 중이면 원래 자리로 돌려놓고 멈춘다
	get_tree().paused = true
	var pool := Catalog.augments.duplicate()
	pool.shuffle()
	cards.assign(pool.slice(0, CARD_COUNT))
	offered.emit(cards)

func _on_zone_placed(rect: Rect2i) -> void:
	_grid.add_buff_zone(rect, placing.stat, placing.value)
	placing = null
	if pending_offers > 0:
		_offer_next()
		return
	get_tree().paused = false
	closed.emit()
