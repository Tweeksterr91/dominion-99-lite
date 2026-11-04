extends SceneTree
const Rules = preload("res://scripts/match_rules.gd")
var failed := false
func check(ok: bool,detail: String) -> void:
 if not ok:
  failed = true
  push_error(detail)
func _initialize() -> void:
 var r := Rules.new()
 r.start(4,99)
 check(r.players.size()==8 and r.team_lives(0)==20,"4v4 has five lives each")
 check(not r.can_harm(0,4),"Collection protects players")
 check(not r.buy(0,"needle"),"Cannot buy outside shop")
 r.credit_essence(0,200)
 r.tick(82.5)
 check(r.phase==Rules.Phase.SHOP and r.remaining==30,"Collection lasts 82.5 seconds then shop 30 seconds")
 check(r.buy(0,"needle") and r.players[0]["souls"]==120,"Weapon costs souls")
 check(r.buy(0,"needle") and r.players[0]["souls"]==120,"Owned weapon equips free")
 check(not r.buy(0,"invented"),"Unknown purchase rejected")
 r.ready(0)
 check(not r.buy(0,"damage"),"Ready player cannot buy")
 for i in range(1,8):r.ready(i)
 check(r.phase==Rules.Phase.REVEAL and r.rewards.size()==8,"One shared roll per player after shopping")
 for p in r.players:check(p["gifts"].values().reduce(func(a,b):return a+b,0)==1,"One gift each")
 r.tick(3)
 check(r.phase==Rules.Phase.HUNT and r.remaining==82.5,"Hunt starts after reveal with 82.5 seconds")
 check(r.can_harm(0,4) and not r.can_harm(0,1),"Hunt has enemies and protects teammates")
 for victim in range(4,8):
  for life in range(5):r.lose_life(victim,0)
 check(r.round_index==1 and r.phase==Rules.Phase.RESULTS,"The first completed hunt ends the match")
 check(r.players[0]["frags"]==20 and r.players[4]["lives"]==0,"Final frags count without another-round reset")
 check(Rules.ROUND_COUNT==1,"Exactly one round is the match")
 r.tick(9999)
 check(r.phase==Rules.Phase.RESULTS,"Results is stable")
 print("FAIL" if failed else "PASS: phase lengths, one match, reset lives, teams, economy, shared rolls")
 quit(1 if failed else 0)
