local M,L=H.M,H.L
assert(M.Format(1125000,"hours")== (H.de and "312,5 Std." or "312.5 hrs"))
assert(M.Format(1125000,"combined")== (H.de and "13 T. 0 Std. 30 Min." or "13d 0h 30m"))
assert(M.Format(nil)==L.unavailable and M.Format(-1)==L.unavailable)
assert(M.Format(0,"combined")== (H.de and "0 T. 0 Std. 0 Min." or "0d 0h 0m"))
assert(not M.Number(0/0) and not M.Number(math.huge))
local db=M.Init({settings={scale=99,format="broken",position={x="5",y="-8"}}})
assert(db.version==3 and db.settings.scale==1.3 and db.settings.format=="combined")
assert(db.settings.position.x==5)
assert(M.Init({version=99})==nil)
db.characters={
    a={name="Same",realm="One",seconds=100,level=10,updatedAt=10},
    b={name="Same",realm="Two",seconds=200,level=20,updatedAt=20},
    c={name="Third",realm="One",seconds=nil,level=30},
    broken=false,
}
local rows,stats=M.List(db)
assert(#rows==3 and rows[1].key=="b" and rows[3].key=="c")
assert(stats.total==300 and stats.missing==1 and stats.count==3 and #stats.realms==2)
rows,stats=M.List(db,"SaMe","One")
assert(#rows==1 and rows[1].key=="a" and stats.visible==100 and stats.total==300)
rows=M.List(db,"[",nil) -- plain search, never a Lua pattern
assert(#rows==0)
rows=M.List(db,nil,nil,"seconds",false)
assert(rows[1].key=="a" and rows[3].key=="c")
rows=M.List(db,nil,nil,"level",true)
assert(rows[1].key=="c")
rows=M.List(db,nil,nil,"updatedAt",false)
assert(rows[1].key=="a" and rows[3].key=="c")
assert(M.SumText(0,1,1,"hours")==L.unavailable)
assert(M.Age(EPOCH+3,EPOCH)==L.now)

assert(M.SessionFormat(8040)==(H.de and "2 Std. 14 Min." or "2h 14m"))
assert(M.SessionFormat(0)==(H.de and "0 Std. 0 Min." or "0h 0m"))
assert(M.SessionFormat(86460)==M.Format(86460,"combined"))
assert(M.Format(7633560,"hours")== (H.de and "2.120,4 Std." or "2,120.4 hrs"))
