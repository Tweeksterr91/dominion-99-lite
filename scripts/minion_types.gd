extends RefCounted
const TYPES := {
	"scavenger":{"name":"SCAVENGER","hp":65.0,"speed":2.8,"damage":9.0,"interval":1.15,"scale":0.67,"drops":3,"value":5,"gold":false},
	"stalker":{"name":"STALKER","hp":40.0,"speed":4.2,"damage":7.0,"interval":0.85,"scale":0.62,"drops":3,"value":5,"gold":false},
	"brute":{"name":"BRUTE","hp":110.0,"speed":2.2,"damage":15.0,"interval":1.5,"scale":0.78,"drops":4,"value":5,"gold":false},
	"treasure":{"name":"GILDED REVENANT","hp":80.0,"speed":3.6,"damage":0.0,"interval":1.0,"scale":0.67,"drops":6,"value":15,"gold":true},
}
static func ordinary(roll: float) -> String:
	return "scavenger" if roll<0.50 else ("stalker" if roll<0.80 else "brute")
