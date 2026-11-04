extends "res://scripts/souls_arena.gd"
## Historical rail/hitscan prototype fixture; never the active game entry point.
func _ready() -> void:
 super._ready()
 pad_input.free_movement=false
func _start_match(size: int,map_id: int,seed_value: int,human_ids: Array,lan := false,attract := false) -> void:
 super._start_match(size,map_id,seed_value,human_ids,lan,attract)
 for p in rules.players:p["weapon"]="pulse";p["owned"]=["pulse"]
 _setup_round()
