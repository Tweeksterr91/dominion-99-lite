extends RefCounted
const RECORDS := [
 ["rook","Rook","male","Human","Courier","A dock runner buying back his family's name.",["Dockside Debt","Borrowed Cargo","The Brass Ledger","Last Delivery","A Name Reclaimed"],"minions"],
 ["silas","Silas","male","Human","Investigator","A disgraced inspector follows the city's missing witnesses.",["Cold Statement","Witness Line","False Testimony","The Sealed File","Final Evidence"],"win"],
 ["knox","Knox","male","Human","Enforcer","An ex-enforcer tears down the protection racket he once served.",["Broken Kneecaps","Collection Notice","House Rules","The Quiet Boss","No More Tribute"],"frags"],
 ["milo","Milo","male","Human","Mechanic","A rooftop mechanic uncovers a machine hidden beneath the ward.",["Loose Bearings","Stolen Current","The Lift Shaft","Dead Circuit","Keep It Running"],"souls"],
 ["dante","Dante","male","Human","Bandleader","A club musician hunts the syndicate that silenced his ensemble.",["Empty Stage","Backroom Rhythm","Brass Section","Black Tie Riot","The Last Encore"],"win"],
 ["voss","Voss","male","Human","Defector","A syndicate accountant turns a fortune into evidence.",["Double Entry","Missing Receipts","Balance Due","Frozen Assets","Closing Accounts"],"souls"],
 ["cade","Cade","male","Human","Rail Marshal","A former rail marshal reopens the city's occupied routes.",["Platform Zero","Signal Failure","Express Service","The Last Switch","All Lines Open"],"minions"],
 ["orson","Orson","male","Human","Night Watch","An old watchman refuses to surrender his neighborhood.",["First Watch","Shuttered Windows","The Alarm Bell","Holding the Block","Daybreak Promise"],"frags"],
 ["vera","Vera","female","Human","Reporter","An underground reporter builds the story the papers buried.",["Small Print","The Source","Ink and Ash","Front Page","The Whole Truth"],"win"],
 ["nyx","Nyx","female","Human","Burglar","A jewel thief steals back the names erased from the registry.",["Silent Entry","Glass Cases","The Vault Key","Missing Names","A Clean Escape"],"souls"],
 ["inez","Inez","female","Human","Unionist","A dock organizer takes on the ward's private army.",["Shift Change","The Picket Line","Closed Gates","Solid Ground","All Hands"],"minions"],
 ["mara","Mara","female","Human","Fixer","A fixer dismantles the network that keeps selling her friends.",["Small Favor","Crossed Wires","Burned Contacts","The Last Broker","Debt Forgiven"],"frags"],
 ["juno","Juno","female","Human","Pilot","A courier pilot tracks a stolen airship through the rooftops.",["Grounded","Fuel Run","The Landing Light","Storm Approach","Clear for Takeoff"],"win"],
 ["sable","Sable","female","Human","Clubkeeper","A speakeasy owner protects the city's last neutral room.",["Password Please","After Hours","The Side Door","Last Call","Open House"],"souls"],
 ["tess","Tess","female","Human","Surveyor","A surveyor uncovers the hidden plan to erase an entire borough.",["Boundary Stones","Wrong Address","Redrawn Lines","The Eviction","Our Streets"],"minions"],
 ["rhea","Rhea","female","Human","Bounty Hunter","A hunter follows a bounty that points back to her own employer.",["Wanted Alive","False Trail","A Higher Price","The Employer","Contract Closed"],"frags"],
 ["brass","Brass","anthro","Wolf","Detective","A wolf detective follows the ward's disappearing night workers.",["Fresh Tracks","Scent of Smoke","The Kennel","Moonless Witness","Case Closed"],"frags"],
 ["moxie","Moxie","anthro","Fox","Smuggler","A fox smuggler breaks a blockade without surrendering her crew.",["Hidden Compartment","Customs House","Narrow Passage","The Blockade","Free Passage"],"souls"],
 ["bramble","Bramble","anthro","Stag","Gardener","A stag caretaker reclaims the gardens feeding the borough.",["Broken Glasshouse","Bitter Harvest","Iron Roots","The Green Line","A Place to Grow"],"minions"],
 ["kestrel","Kestrel","anthro","Raven","Lookout","A raven lookout traces a warning signal across the skyline.",["High Perch","Dead Air","Black Feathers","The Warning","Skyline Chorus"],"win"],
 ["ledger","Ledger","robot","Automaton","Archivist","An archive automaton restores the city's stolen memories.",["Missing Record","Read Only","The Index","Memory Ward","Nothing Forgotten"],"souls"],
 ["static","Static","robot","Automaton","Broadcaster","A radio automaton fights to put the free signal back on air.",["White Noise","Relay Station","Dead Frequency","The Broadcast","Loud and Clear"],"win"],
 ["piston","Piston","robot","Automaton","Dockhand","A labor automaton seeks the workers taken from its assembly crew.",["Punch In","Heavy Lifting","Spare Parts","The Foreman","Clocking Out"],"minions"],
 ["cipher","Cipher","robot","Automaton","Codebreaker","A codebreaker automaton follows a command hidden in every city contract.",["First Key","False Credentials","The Cipher Room","Root Access","Free Will"],"frags"]
]
static func find(id: String) -> Dictionary:
 for i in range(RECORDS.size()):
  var r: Array=RECORDS[i]
  if r[0]==id:return {"id":r[0],"name":r[1],"kind":r[2],"species":r[3],"role":r[4],"bio":r[5],"titles":r[6],"goal":r[7],"index":i}
 return find("rook")
static func roster() -> Array:
 var result: Array=[]
 for r in RECORDS:result.append(find(r[0]))
 return result
static func mission(id: String,index: int) -> Dictionary:
 var hero:=find(id);var pool: Array=[0,1,2,3,4];var route: Array=[];var code: int=int(hero["index"])*5
 for divisor in [24,6,2,1,1]:
  var at: int=code/divisor;code=code%divisor;route.append(pool.pop_at(at%pool.size()))
 var goal: String=hero["goal"];var amount: int=1+index/2
 if goal=="souls":amount=(index+1)*15
 if goal=="win":amount=0
 var description: String={"minions":"Defeat at least %d minions"%amount,"frags":"Score at least %d frags"%amount,"souls":"Collect at least %d souls"%amount,"win":"Win the match"}[goal]
 return {"title":hero["titles"][index],"map":route[index],"size":[1,1,2,2,3][index],"goal":goal,"amount":amount,"description":description+" and win" if goal!="win" else description}
static func empty_career() -> Dictionary:
 return {"unlocked":1,"cleared":[],"matches":0,"wins":0,"frags":0,"souls":0,"best":{}}
