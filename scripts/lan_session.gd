extends Node
## LAN-only ENet rooms. The host owns rules and accepts actions, never client stats.
signal lobby_changed
signal launch(config: Dictionary)
signal state_received(state: Dictionary)
signal action_received(fighter: int, kind: String, value: Variant, sequence: int)
signal connection_error(message: String)
signal fighter_disconnected(fighter: int)
const PROTOCOL := 7
const PORT := 27799
var active := false
var in_match := false
var hosting := false
var local_slot := 0
var team_size := 1
var biome := 0
var peers: Dictionary = {}
var ready_peers: Dictionary = {}
var human_slots: Array[int] = [0]
var last_sequence: Dictionary = {}
var rate_count: Dictionary = {}
var rate_time: Dictionary = {}
var sequence := 0
var status := ""
var connecting_until := 0
var incoming: Dictionary = {}
var delivered := -1

func _process(_delta: float) -> void:
	if connecting_until>0 and Time.get_ticks_msec()>connecting_until:
		_failed()

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(_failed)
	multiplayer.server_disconnected.connect(_server_left)

func host(size: int, map_id: int, port := PORT) -> Error:
	close()
	team_size = clampi(size, 1, 4)
	biome = clampi(map_id, 0, 4)
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, team_size * 2 - 1)
	if error != OK:
		status = "Could not open the room."
		return error
	multiplayer.multiplayer_peer = peer
	active = true
	hosting = true
	peers = {1: 0}
	ready_peers = {1: true}
	human_slots = [0]
	status = "ROOM OPEN / %dv%d" % [team_size, team_size]
	lobby_changed.emit()
	return OK

func join_room(address: String, port := PORT) -> Error:
	close()
	var clean := address.strip_edges()
	if clean.is_empty() or clean.length() > 80:
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(clean, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	active = true
	status = "CONNECTING..."
	connecting_until = Time.get_ticks_msec()+10000
	lobby_changed.emit()
	return OK

func close() -> void:
	if active:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	connecting_until = 0
	active = false
	in_match = false
	hosting = false
	peers.clear()
	ready_peers.clear()
	human_slots = [0]
	local_slot = 0
	sequence = 0
	incoming.clear()
	delivered = -1
	last_sequence.clear()
	rate_count.clear()
	rate_time.clear()

func local_address() -> String:
	for address in IP.get_local_addresses():
		if address.begins_with("192.168.") or address.begins_with("10.") or address.begins_with("172."):
			return address
	return "Check the phone's Wi-Fi IP address"

func _peer_connected(id: int) -> void:
	# Bound disconnect detection for a phone leaving Wi-Fi or closing the app.
	var peer: ENetMultiplayerPeer = multiplayer.multiplayer_peer
	peer.get_peer(id).set_timeout(8,2000,5000)

func _connected() -> void:
	connecting_until = 0
	_register.rpc_id(1, PROTOCOL)

func _failed() -> void:
	close()
	status = "Connection failed. Use the same Wi-Fi/hotspot and host IP."
	connection_error.emit(status)

func _server_left() -> void:
	close()
	status = "The host left the room."
	connection_error.emit(status)

func _peer_disconnected(peer: int) -> void:
	if not hosting or not peers.has(peer):
		return
	var slot := int(peers[peer])
	peers.erase(peer)
	ready_peers.erase(peer)
	human_slots.erase(slot)
	if in_match:
		fighter_disconnected.emit(slot)
	_broadcast_lobby()

@rpc("any_peer", "call_remote", "reliable")
func _register(version: int) -> void:
	if not hosting:
		return
	var sender := multiplayer.get_remote_sender_id()
	if version != PROTOCOL or in_match:
		_rejected.rpc_id(sender, "Use the same game version. Join before the match starts.")
		return
	if peers.has(sender):
		return
	var order: Array[int] = []
	for i in range(team_size):
		order.append(i)
		order.append(i + team_size)
	var slot := -1
	for candidate in order:
		if candidate not in human_slots:
			slot = candidate
			break
	if slot < 0:
		_rejected.rpc_id(sender, "Room full.")
		return
	peers[sender] = slot
	human_slots.append(slot)
	ready_peers[sender] = false
	_welcome.rpc_id(sender, slot)
	_broadcast_lobby()

@rpc("authority", "call_remote", "reliable")
func _rejected(message: String) -> void:
	close()
	connection_error.emit(message)

@rpc("authority", "call_remote", "reliable")
func _welcome(slot: int) -> void:
	local_slot = slot

func set_ready() -> void:
	if not active or in_match:
		return
	if hosting:
		ready_peers[1] = true
	else:
		_ready_request.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _ready_request() -> void:
	if hosting and peers.has(multiplayer.get_remote_sender_id()) and not in_match:
		ready_peers[multiplayer.get_remote_sender_id()] = true
		_broadcast_lobby()

func can_start() -> bool:
	if not hosting or peers.size() < 2:
		return false
	for peer in peers:
		if not ready_peers.get(peer, false):
			return false
	return true

func start_match(seed_value: int) -> bool:
	if not can_start():
		return false
	var config := {"size": team_size, "biome": biome, "seed": seed_value, "humans": human_slots.duplicate()}
	in_match = true
	_launch.rpc(config)
	launch.emit(config)
	return true

@rpc("authority", "call_remote", "reliable")
func _launch(config: Dictionary) -> void:
	in_match = true
	launch.emit(config)

func _broadcast_lobby() -> void:
	var slots: Array = []
	for peer in peers:
		slots.append({"slot": peers[peer], "ready": ready_peers.get(peer, false)})
	_lobby.rpc(team_size, biome, slots)
	lobby_changed.emit()

@rpc("authority", "call_remote", "reliable")
func _lobby(size: int, map_id: int, slots: Array) -> void:
	team_size = size
	biome = map_id
	human_slots.clear()
	ready_peers.clear()
	for p in slots:
		human_slots.append(int(p["slot"]))
		ready_peers[int(p["slot"])] = p["ready"]
	status = "CONNECTED / PLAYER %d / %dv%d" % [local_slot + 1, team_size, team_size]
	lobby_changed.emit()

func send_action(kind: String, value: Variant = null) -> int:
	sequence += 1
	if hosting:
		action_received.emit(local_slot, kind, value, sequence)
	else:
		_action.rpc_id(1, kind, value, sequence)
	return sequence

@rpc("any_peer", "call_remote", "reliable")
func _action(kind: String, value: Variant, seq: int) -> void:
	if not hosting or not in_match:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not peers.has(sender) or seq <= int(last_sequence.get(sender, 0)):
		return
	if kind not in ["aim", "turn", "jump", "reverse", "fire", "reload", "suction", "buy", "ready"]:
		return
	var now := Time.get_ticks_msec()
	if now - int(rate_time.get(sender, 0)) > 1000:
		rate_time[sender] = now
		rate_count[sender] = 0
	rate_count[sender] = int(rate_count.get(sender, 0)) + 1
	if int(rate_count[sender]) > 80:
		return
	last_sequence[sender] = seq
	action_received.emit(int(peers[sender]), kind, value, seq)

func publish(data: Dictionary) -> void:
	if not hosting or not in_match:return
	# Keep each UDP packet below the MTU, even with eight players and essence.
	var raw := var_to_bytes(data)
	var packed := raw.compress(FileAccess.COMPRESSION_ZSTD)
	var count := ceili(packed.size()/1000.0)
	for i in range(count):
		_snapshot_chunk.rpc(int(data["seq"]),raw.size(),i,count,packed.slice(i*1000,mini((i+1)*1000,packed.size())))

@rpc("authority", "call_remote", "unreliable", 1)
func _snapshot_chunk(seq: int,raw_size: int,index: int,count: int,chunk: PackedByteArray) -> void:
	if seq<=delivered or raw_size<=0 or raw_size>262144 or count<1 or count>64 or index<0 or index>=count or chunk.size()>1000:return
	if not incoming.has(seq):incoming[seq] = {"parts":{},"count":count,"size":raw_size}
	var record: Dictionary = incoming[seq]
	if record["count"]!=count or record["size"]!=raw_size:return
	record["parts"][index] = chunk
	if record["parts"].size()==count:
		var packed := PackedByteArray()
		for i in range(count):packed.append_array(record["parts"][i])
		var raw := packed.decompress(raw_size,FileAccess.COMPRESSION_ZSTD)
		var value: Variant = bytes_to_var(raw) # Object decoding is disabled.
		if value is Dictionary:
			delivered = seq
			state_received.emit(value)
	for old in incoming.keys():
		if old<=delivered or old<seq-3:incoming.erase(old)
