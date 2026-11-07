extends Node
class_name AugmentManager

# 카드 선택을 담당한다. 뽑기 5회마다, 보스를 잡을 때마다 증강을 제시하고, 고른 증강은 격자 위
# 구역이 된다. 필살기 교체 카드도 같은 패널을 쓴다. 고르고 놓는 동안 게임은 멈춘다.

signal offered(cards: Array[Resource], title: String)
signal placement_started(augment: AugmentData)
signal closed

const DRAWS_PER_OFFER := 5
const CARD_COUNT := 3
const AUGMENT_TITLE := "우주 변칙 현상"
const ULTIMATE_TITLE := "필살기 교체"

var draws_until_offer: int = DRAWS_PER_OFFER
var pending_offers: int:
	get:
		return _queue.size()
var cards: Array[Resource] = []
var placing: AugmentData = null

var _grid: GridManager = null
var _ultimates: UltimateManager = null
var _queue: Array[Dictionary] = [] # 대기 중인 패널 {cards_from, title}

func setup(grid: GridManager, ultimates: UltimateManager) -> void:
	_grid = grid
	_ultimates = ultimates
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
	_enqueue(Catalog.augments, AUGMENT_TITLE)

func request_ultimate_offer() -> void:
	_enqueue(Catalog.ultimates, ULTIMATE_TITLE)

func _enqueue(pool: Array, title: String) -> void:
	_queue.append({"pool": pool, "title": title})
	if not is_busy():
		_offer_next()

func choose(index: int) -> void:
	var card := cards[index]
	cards.clear()
	if card is UltimateData:
		_ultimates.equip(card)
		_finish_choice()
		return
	placing = card
	_grid.begin_zone_placement(placing.zone_size, placing.get_color())
	placement_started.emit(placing)

func _offer_next() -> void:
	var offer: Dictionary = _queue.pop_front()
	_grid.cancel_drag() # 드래그 중이면 원래 자리로 돌려놓고 멈춘다
	get_tree().paused = true
	var pool: Array = offer["pool"].duplicate()
	pool.shuffle()
	cards.assign(pool.slice(0, CARD_COUNT))
	offered.emit(cards, offer["title"])

func _on_zone_placed(rect: Rect2i) -> void:
	_grid.add_buff_zone(rect, placing.stat, placing.value)
	placing = null
	_finish_choice()

func _finish_choice() -> void:
	if not _queue.is_empty():
		_offer_next()
		return
	get_tree().paused = false
	closed.emit()
