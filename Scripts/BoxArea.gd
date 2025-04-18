extends Area2D

@export_range(1, 100) var max_capacity: int
@export var inventory: Dictionary[int, int] = {}
@export var items = 0


func _ready() -> void:
	evaluate_capacity()

@rpc("any_peer", "call_local", "reliable")
func interact(player_name):
	if is_multiplayer_authority():
		var player = get_node("../" + player_name)
		if player.carry_addr.is_empty():
			if player.carry_id >= 0:
				add_box(player)
			else:
				player.open_storage_ui.rpc(inventory)

@rpc("any_peer", "call_local", "reliable")
func open_storage_ui_rpc(player_name, inventory):
	get_node("../" + player_name).open_storage_ui(inventory)

func add_box(player: RigidBody2D) -> void:
	if items + player.carry_count > max_capacity:
		print("Area is full")
		return
	
	var carry_id = player.carry_id
	var carry_count = player.carry_count
	
	items += carry_count
	# If such a box already exists, add to it, otherwise put it in
	if inventory.has(carry_id):
		inventory[carry_id] += carry_count
	else:
		inventory[carry_id] = carry_count
	
	remove_from_player.rpc(player.name)
	
@rpc("any_peer", "call_local", "reliable")
func remove_from_player(player_name):
	get_node("../" + player_name).set_carry_id(-1)
	get_node("../" + player_name).set_carry_count(0)
	get_node("../" + player_name).get_node("Box").hide()

@rpc("any_peer", "call_local", "reliable")
func remove_item(player_name : String, id: int, count: int) -> void:
	if is_multiplayer_authority():
		var player = get_node("../" + player_name)
		inventory[id] -= count
		if inventory[id] <= 0:
			inventory.erase(id)
		
		items -= count
		player.set_carry_id(id)
		player.set_carry_count(count)


func evaluate_capacity():
	items = 0
	for value in inventory.values():
		items += value
