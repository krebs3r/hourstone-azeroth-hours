local T=H.T
fire("ADDON_LOADED","AnotherAddon")
assert(not T.db)
fire("ADDON_LOADED","Hourstone")
fire("PLAYER_ENTERING_WORLD",true,false)
assert(REQUESTS==1 and T:Session()==0 and T:Value(T.key,T.record)==nil)
tick(10)
assert(T:Session()==10 and T:Value(T.key,T.record)==nil)
fire("TIME_PLAYED_MSG",10000,2000)
tick(20)
assert(T:Value(T.key,T.record)==10020 and T:Session()==30)
T:Request(); assert(REQUESTS==1)
tick(30); assert(REQUESTS==2)
tick(5); fire("TIME_PLAYED_MSG",10055,2045)
assert(T:Value(T.key,T.record)==10055) -- replacement, not baseline + delta twice
tick(5); assert(T:Value(T.key,T.record)==10060)
assert(not T:Receive(-100) and not T:Receive(0/0))
fire("PLAYER_LEVEL_UP",91); assert(T.record.level==91)
IDENTITY.level=91
fire("PLAYER_ENTERING_WORLD",false,false); assert(T:Session()==70 and REQUESTS==2)
fire("PLAYER_LOGOUT")
local db,key=T.db,T.key
assert(db.characters[key].seconds==10060)
-- Simulate a fresh Lua namespace after reload; GetTime continues in the same client.
advance(4); T:Init(db); T:Begin(true)
assert(T:Session()==74 and T:Value(key,T.record)==10064)
assert(REQUESTS==2) -- saved throttle survives reload
tick(16); assert(T:Value(key,T.record)==10080 and T:Session()==90)
T:Save()
-- Offline for a day: only the last known time returns, and session resets.
advance(86400); T:Init(db); T:Begin(false)
assert(T:Session()==0 and T:Value(key,T.record)==10080)
assert(REQUESTS==3)
fire("TIME_PLAYED_MSG",10082,42); tick(8); T:Save()
local previous=db.characters[key].seconds
IDENTITY.guid="Player-2-BBB"; IDENTITY.realm="Another Realm"
advance(1200); T:Init(db); T:Begin(false)
assert(T.key~=key and T:Session()==0 and T:Value(T.key,T.record)==nil)
tick(100)
assert(T:Value(key,db.characters[key])==previous) -- no offline ticking for other chars
assert(REQUESTS==5) -- one initial request and one retry after missing response
T:Receive(0); assert(T:Value(T.key,T.record)==0) -- legitimate zero is known
T:Save(); local current=T.key
advance(5); NOW=1; T:Init(db); T:Begin(true)
assert(T:Session()==0 and T:Value(current,T.record)==0) -- invalid monotonic carry discarded
