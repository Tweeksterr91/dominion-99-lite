extends RefCounted
## Authoritative, renderer-independent five-round match rules.
enum Phase { COLLECTION, SHOP, REVEAL, HUNT, RESULTS }
const COLLECTION_TIME := 165.0
const SHOP_TIME := 60.0
const HUNT_TIME := 165.0
const ROUND_COUNT := 5
const ROUND_LIVES := 5
const WEAPONS := {
	"pulse": {"name": "D-9 PULSE", "damage": 34.0, "interval": 0.22, "mag": 12, "reload": 1.6, "cost": 0},
	"needle": {"name": "NEEDLE CARBINE", "damage": 23.0, "interval": 0.13, "mag": 24, "reload": 1.9, "cost": 80},
	"scatter": {"name": "ASH SCATTERGUN", "damage": 62.0, "interval": 0.60, "mag": 6, "reload": 1.8, "cost": 100},
}
const UPGRADES := {
	"damage": {"name": "EDGE / +5% DAMAGE", "cost": 45, "limit": 3},
	"shield": {"name": "AEGIS / +20 MAX SHIELD", "cost": 40, "limit": 3},
	"health": {"name": "VITAL / +20 MAX HEALTH", "cost": 40, "limit": 3},
	"reload": {"name": "CHAMBER / 8% FASTER RELOAD", "cost": 45, "limit": 3},
	"heal": {"name": "FIELD PATCH / RESTORE HEALTH", "cost": 20, "limit": 99},
	"ammo": {"name": "RESUPPLY / +72 RESERVE", "cost": 15, "limit": 99},
}
const GIFTS := [
	{"id": "edge", "name": "QUIET EDGE", "detail": "+2% damage"},
	{"id": "aegis", "name": "THIN AEGIS", "detail": "+5 max shield"},
	{"id": "chamber", "name": "QUICK CHAMBER", "detail": "3% faster reload"},
	{"id": "reach", "name": "LONG REACH", "detail": "+1 m essence pull"},
	{"id": "recovery", "name": "SECOND BREATH", "detail": "Shield recovers 0.15 s earlier"},
]
var players: Array[Dictionary] = []
var phase := Phase.COLLECTION
var remaining := COLLECTION_TIME
var round_index := 1
var team_rounds := [0, 0]
var last_round_winner := -1
var match_winner := -1
var rewards: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var revision := 0

func start(team_size := 1, seed_value := 99) -> void:
	team_size = clampi(team_size, 1, 4)
	rng.seed = seed_value
	players.clear()
	var names := ["YOU", "VEX", "MORROW", "ASH", "VALE", "ECHO", "ROOK", "CINDER"]
	for i in range(team_size * 2):
		players.append({"id": i, "name": names[i], "team": 0 if i < team_size else 1, "lives": ROUND_LIVES, "souls": 0, "frags": 0, "round_frags": 0, "essence": 0, "round_essence": 0, "minions": 0, "weapon": "pulse", "owned": ["pulse"], "upgrades": {}, "gifts": {}, "ready": false})
	round_index = 1
	team_rounds = [0, 0]
	match_winner = -1
	last_round_winner = -1
	rewards.clear()
	_set_phase(Phase.COLLECTION, COLLECTION_TIME)

func _set_phase(value: Phase, seconds: float) -> void:
	phase = value
	remaining = seconds
	revision += 1

func tick(delta: float) -> bool:
	if phase == Phase.RESULTS or delta <= 0:
		return false
	var changed := false
	while phase != Phase.RESULTS and delta >= remaining:
		delta -= remaining
		advance()
		changed = true
	if phase != Phase.RESULTS:remaining = maxf(0,remaining-delta)
	return changed

func advance() -> void:
	match phase:
		Phase.COLLECTION:
			for p in players:
				p["ready"] = false
			_set_phase(Phase.SHOP, SHOP_TIME)
		Phase.SHOP:
			_roll_gifts()
			_set_phase(Phase.REVEAL, 6.0)
		Phase.REVEAL:
			_set_phase(Phase.HUNT, HUNT_TIME)
		Phase.HUNT:
			_finish_round()

func ready(id: int) -> void:
	if phase != Phase.SHOP:
		return
	players[id]["ready"] = true
	for p in players:
		if not p["ready"]:
			return
	advance()

func credit_essence(id: int, value: int) -> void:
	if id < 0 or id >= players.size() or value <= 0:
		return
	players[id]["souls"] += value
	players[id]["essence"] += value
	players[id]["round_essence"] += value

func can_harm(attacker: int, victim: int) -> bool:
	return phase == Phase.HUNT and attacker != victim and attacker >= 0 and victim >= 0 and attacker < players.size() and victim < players.size() and players[attacker]["team"] != players[victim]["team"] and players[attacker]["lives"] > 0 and players[victim]["lives"] > 0

func lose_life(victim: int, attacker := -1) -> void:
	if victim < 0 or victim >= players.size() or players[victim]["lives"] <= 0:
		return
	var credited := can_harm(attacker, victim)
	players[victim]["lives"] -= 1
	if credited:
		players[attacker]["frags"] += 1
		players[attacker]["round_frags"] += 1
	if phase == Phase.HUNT and (team_lives(0) == 0 or team_lives(1) == 0):
		_finish_round()

func team_lives(team: int) -> int:
	var total := 0
	for p in players:
		if p["team"] == team:
			total += p["lives"]
	return total

func _finish_round() -> void:
	var score := [[0,0,0],[0,0,0]]
	for p in players:
		var team: int = p["team"]
		score[team][0] += p["lives"]
		score[team][1] += p["round_frags"]
		score[team][2] += p["round_essence"]
	last_round_winner = -1
	for criterion in range(3):
		if score[0][criterion]!=score[1][criterion]:
			last_round_winner = 0 if score[0][criterion]>score[1][criterion] else 1
			break
	if last_round_winner >= 0:
		team_rounds[last_round_winner] += 1
	if round_index >= ROUND_COUNT:
		match_winner = -1 if team_rounds[0] == team_rounds[1] else (0 if team_rounds[0] > team_rounds[1] else 1)
		_set_phase(Phase.RESULTS, 0)
		return
	round_index += 1
	for p in players:
		p["lives"] = ROUND_LIVES
		p["round_frags"] = 0
		p["round_essence"] = 0
		p["ready"] = false
	_set_phase(Phase.COLLECTION, COLLECTION_TIME)

func _roll_gifts() -> void:
	rewards.clear()
	for p in players:
		var gift: Dictionary = GIFTS[rng.randi_range(0, GIFTS.size() - 1)].duplicate()
		p["gifts"][gift["id"]] = int(p["gifts"].get(gift["id"], 0)) + 1
		gift["player"] = p["id"]
		rewards.append(gift)

func buy(id: int, item: String) -> bool:
	if phase != Phase.SHOP or id < 0 or id >= players.size() or players[id]["ready"]:
		return false
	var p := players[id]
	if WEAPONS.has(item):
		if item in p["owned"]:
			p["weapon"] = item
			return true
		var cost: int = WEAPONS[item]["cost"]
		if p["souls"] < cost:
			return false
		p["souls"] -= cost
		p["owned"].append(item)
		p["weapon"] = item
		return true
	if not UPGRADES.has(item):
		return false
	var data: Dictionary = UPGRADES[item]
	var level := int(p["upgrades"].get(item, 0))
	if p["souls"] < data["cost"] or level >= data["limit"]:
		return false
	p["souls"] -= data["cost"]
	p["upgrades"][item] = level + 1
	return true

func stats(id: int) -> Dictionary:
	var p := players[id]
	var u: Dictionary = p["upgrades"]
	var g: Dictionary = p["gifts"]
	var weapon: Dictionary = WEAPONS[p["weapon"]]
	return {"health": 100 + int(u.get("health", 0)) * 20, "shield": 100 + int(u.get("shield", 0)) * 20 + int(g.get("aegis", 0)) * 5, "damage": weapon["damage"] * (1.0 + int(u.get("damage", 0)) * 0.05 + int(g.get("edge", 0)) * 0.02), "interval": weapon["interval"], "mag": weapon["mag"], "reload": weapon["reload"] * pow(0.92, int(u.get("reload", 0))) * pow(0.97, int(g.get("chamber", 0))), "reach": 12.0 + int(g.get("reach", 0)), "shield_delay": maxf(2.0, 4.0 - int(g.get("recovery", 0)) * 0.15)}
