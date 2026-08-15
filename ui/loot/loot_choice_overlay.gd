class_name LootChoiceOverlay
extends Control

signal closed

const OFFER_CARD_SCENE := preload("res://ui/loot/loot_offer_card.tscn")

@onready var title_label: Label = %TitleLabel
@onready var type_label: Label = %TypeLabel
@onready var hint_label: Label = %HintLabel
@onready var status_label: Label = %StatusLabel
@onready var cards_host: HBoxContainer = %CardsHost
@onready var take_button: Button = %TakeButton

var _ui_manager: UIManager
var _active: bool = false
var _offers: Array[Dictionary] = []
var _index: int = 0
var _cards: Array = []
var _on_done: Callable = Callable()
var _reward_type: int = RoomData.RewardType.NONE


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sheet := get_node_or_null("%Sheet") as PanelContainer
	if sheet:
		UIPopupLayout.apply_sheet_panel(sheet)
	UIPopupLayout.apply_sheet_bands(
		get_node_or_null("%TopBand") as Control,
		get_node_or_null("%MidBand") as Control,
		get_node_or_null("%BottomBand") as Control
	)
	if take_button:
		take_button.pressed.connect(_on_take_pressed)
	if LocaleManager:
		LocaleManager.locale_changed.connect(_on_locale_changed)
	_refresh_texts()


func setup(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager


func open(offers: Array, reward_type: int, on_done: Callable) -> void:
	_offers.clear()
	for entry in offers:
		if entry is Dictionary:
			_offers.append(entry)
	_reward_type = reward_type
	_on_done = on_done
	_index = 0
	_active = true
	visible = true
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	if _ui_manager:
		_ui_manager.set_challenge_board_open(true)
	_rebuild_cards()
	_refresh_texts()
	_sync_take_enabled()


func close() -> void:
	if not _active:
		return
	_active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	if _ui_manager:
		_ui_manager.set_challenge_board_open(false)
	closed.emit()


func is_open() -> bool:
	return _active


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_move_index(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_move_index(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_take_pressed()
		get_viewport().set_input_as_handled()


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	_rebuild_cards()


func _refresh_texts() -> void:
	if title_label:
		title_label.text = tr("Choose a reward")
	if type_label:
		type_label.text = tr(LootService.reward_type_label_key(_reward_type))
	if hint_label:
		hint_label.text = tr("Select one offer")
	if take_button:
		take_button.text = tr("Take")


func _rebuild_cards() -> void:
	for child in cards_host.get_children():
		child.queue_free()
	_cards.clear()
	if _offers.is_empty():
		return
	for i in _offers.size():
		var card: LootOfferCard = OFFER_CARD_SCENE.instantiate()
		cards_host.add_child(card)
		card.setup(i)
		card.set_offer(_offers[i], _compare_item_for_offer(_offers[i]))
		card.card_pressed.connect(_on_card_pressed)
		card.card_activated.connect(_on_card_activated)
		_cards.append(card)
	_apply_focus()


func _compare_item_for_offer(offer: Dictionary) -> ItemData:
	if _ui_manager == null or _ui_manager.inventory_data == null:
		return null
	return _ui_manager.inventory_data.equipped_in_same_slot(offer.get("item") as ItemData)


func _on_card_pressed(i: int) -> void:
	_index = clampi(i, 0, maxi(0, _offers.size() - 1))
	_apply_focus()
	_sync_take_enabled()


func _on_card_activated(i: int) -> void:
	_on_card_pressed(i)
	_on_take_pressed()


func _move_index(delta: int) -> void:
	if _offers.is_empty():
		return
	_index = posmod(_index + delta, _offers.size())
	_apply_focus()
	_sync_take_enabled()


func _apply_focus() -> void:
	for i in _cards.size():
		var card: LootOfferCard = _cards[i]
		if card:
			card.set_selected(i == _index)


func _sync_take_enabled() -> void:
	if take_button == null:
		return
	if _offers.is_empty():
		take_button.disabled = true
		_set_status(tr("No rewards"))
		return
	var offer: Dictionary = _offers[_index]
	var blocked := false
	if LootService.offer_needs_inventory_slot(offer) and _ui_manager and _ui_manager.inventory_data:
		blocked = LootService.offer_inventory_full(_ui_manager.inventory_data, offer)
	take_button.disabled = blocked
	_set_status(tr("LOOT_INVENTORY_FULL") if blocked else "")


func _set_status(text: String) -> void:
	if status_label == null:
		return
	status_label.text = text
	status_label.visible = not text.is_empty()


func _on_take_pressed() -> void:
	if not _active or _offers.is_empty():
		return
	var offer: Dictionary = _offers[_index]
	if LootService.offer_needs_inventory_slot(offer) and _ui_manager and _ui_manager.inventory_data:
		if LootService.offer_inventory_full(_ui_manager.inventory_data, offer):
			_sync_take_enabled()
			return
	var cb := _on_done
	var chosen := offer.duplicate(true)
	close()
	if cb.is_valid():
		cb.call(chosen)
