extends RefCounted
const RULES=preload("res://scripts/match_rules.gd")
static func infinite(key: String) -> bool:return bool(RULES.WEAPONS[key].get("infinite",false))
static func melee(key: String) -> bool:return bool(RULES.WEAPONS[key].get("melee",false))
static func fresh(key: String) -> Dictionary:
 return {"ammo":int(RULES.WEAPONS[key]["mag"]),"reserve":-1 if infinite(key) else 72}
static func reset(p: Dictionary) -> void:
 p["inventory"]={}
 for key in p["owned"]:p["inventory"][key]=fresh(key)
 restore(p,p["weapon"])
static func store(p: Dictionary) -> void:
 if not p.has("inventory"):p["inventory"]={}
 p["inventory"][p["weapon"]]={"ammo":int(p["ammo"]),"reserve":-1 if infinite(p["weapon"]) else int(p["reserve"])}
static func restore(p: Dictionary,key: String) -> void:
 if not p.has("inventory"):p["inventory"]={}
 if not p["inventory"].has(key):p["inventory"][key]=fresh(key)
 p["weapon"]=key;p["ammo"]=int(p["inventory"][key]["ammo"]);p["reserve"]=-1 if infinite(key) else int(p["inventory"][key]["reserve"])
static func add_reserve(p: Dictionary,amount: int) -> bool:
 store(p)
 var best: String="";var lowest:=360
 var prefer_current: bool=not infinite(p["weapon"]) and int(p["reserve"])<360
 if prefer_current:best=p["weapon"];lowest=int(p["reserve"])
 for key in p["owned"]:
  if infinite(key):continue
  if not p["inventory"].has(key):p["inventory"][key]=fresh(key)
  var reserve:=int(p["inventory"][key]["reserve"])
  if not prefer_current and reserve<lowest:lowest=reserve;best=key
 if best.is_empty():return false
 p["inventory"][best]["reserve"]=mini(360,lowest+amount)
 restore(p,p["weapon"])
 return true
