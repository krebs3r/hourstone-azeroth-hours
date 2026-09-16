local M,S,T,C=H.M,H.S,H.T,H.C
GetCurrentRegion=function() return 3 end
if C.Flavor():match("^project%-") then WOW_PROJECT_ID=1 end
local function observation(fields)
    local row={sourceId="local-source",region="eu",flavor=C.Flavor(),guid=IDENTITY.guid,
        name=IDENTITY.name,realm=IDENTITY.realm,class=IDENTITY.class,level=IDENTITY.level,
        seconds=100,updatedAt=EPOCH,serverSeconds=100,serverAt=EPOCH}
    for key,value in pairs(fields or {}) do row[key]=value end
    return row
end
local function payload(version, rows)
    return {formatVersion=version,sources={["local-source"]={observations=rows}}}
end
local original=observation({guild="Dawnwatch",guildUpdatedAt=EPOCH-100})
local key=C.Identity("local-source").key
HourstoneDB={version=2,sourceId="local-source",characters={[key]=original}}
IN_GUILD=true; GUILD_NAME=nil
fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
assert(T.record.guild=="Dawnwatch" and T.record.guildUpdatedAt==EPOCH-100)
local readCount=GUILD_READS
advance(10); tick(1)
assert(GUILD_READS==readCount) -- no guild polling on the one-second UI/played timer
IN_GUILD=nil; T:Save()
assert(T.record.guild=="Dawnwatch" and T.record.guildUpdatedAt==EPOCH-111)
IN_GUILD=true; GUILD_NAME="Evening Watch"
readCount=GUILD_READS; fire("PLAYER_GUILD_UPDATE","party1")
assert(GUILD_READS==readCount and T.record.guild=="Dawnwatch")
fire("GUILD_ROSTER_UPDATE",true)
assert(T.record.guild=="Evening Watch" and T.record.guildUpdatedAt==EPOCH)
local firstStamp=EPOCH
advance(5); T:Save()
assert(T.record.guildUpdatedAt==firstStamp+5) -- unchanged name is freshly observed
IN_GUILD=true; GUILD_NAME=""
advance(5); fire("PLAYER_GUILD_UPDATE","player")
assert(T.record.guild=="Evening Watch" and T.record.guildUpdatedAt==firstStamp+5)
IN_GUILD=false; GUILD_NAME=nil
advance(1); fire("GUILD_ROSTER_UPDATE",false)
assert(T.record.guild=="Evening Watch") -- roster cache alone does not confirm departure
fire("PLAYER_GUILD_UPDATE","player")
assert(T.record.guild=="" and T.record.guildUpdatedAt==EPOCH)
advance(1); IN_GUILD=true; GUILD_NAME="Dawnwatch"; fire("PLAYER_GUILD_UPDATE","player")
assert(T.record.guild=="Dawnwatch")
IN_GUILD=false; GUILD_NAME=nil; fire("PLAYER_GUILD_UPDATE","player")
assert(T.record.guild=="") -- an explicit local departure wins immediately within the same second
advance(1); T:Save(); assert(T.record.guild=="" and T.record.guildUpdatedAt==EPOCH)
local stamp=T.record.guildUpdatedAt
EPOCH=EPOCH-10; IN_GUILD=true; GUILD_NAME="A stale guild"; fire("PLAYER_GUILD_UPDATE","player")
assert(T.record.guild=="" and T.record.guildUpdatedAt==stamp)
EPOCH=stamp+1
local serverTime=GetServerTime
GetServerTime=nil; T:UpdateGuild(true); assert(T.record.guild=="" and T.record.guildUpdatedAt==stamp)
GetServerTime=serverTime
GUILD_NAME=string.rep("ä",65); T:UpdateGuild(true); assert(T.record.guild=="")
GUILD_NAME="|cffff0000Safe|r"; T:UpdateGuild(true)
assert(T.record.guild==GUILD_NAME)
assert(M.GuildText(T.record)==H.L.guild..": ||cffff0000Safe||r")

-- Fresh guildless login waits for a trustworthy save or own-guild event.
IN_GUILD=false; GUILD_NAME=nil
local fresh=M.Init({version=2,sourceId="fresh-source"}); T:Init(fresh); T:Begin(false)
assert(T.record.guild==nil and T.record.guildUpdatedAt==nil)
T:Save(); assert(T.record.guild=="" and T.record.guildUpdatedAt==EPOCH)
local legacy=M.Init({version=1,characters={legacy={guild="Untrusted",guildUpdatedAt=EPOCH}}})
assert(legacy.characters.legacy.guild==nil and legacy.characters.legacy.guildUpdatedAt==nil)

-- Guild merge is independent, immutable, and retains the playtime winner's provenance.
local localRow=observation({guild="Old guild",guildUpdatedAt=EPOCH-100})
local remote=observation({sourceId="remote-source",seconds=80,serverSeconds=80,serverAt=EPOCH-200,
    updatedAt=EPOCH-200,guild="New guild",guildUpdatedAt=EPOCH-10})
local unknown=observation({sourceId="other-source",seconds=120,serverSeconds=120,serverAt=EPOCH+1,updatedAt=EPOCH+1})
local merged,winner=S.Choose(localRow,remote)
assert(winner==localRow and merged~=localRow and merged~=remote)
assert(merged.seconds==100 and merged.serverAt==localRow.serverAt and merged.guild=="New guild")
assert(localRow.guild=="Old guild" and remote.seconds==80)
local associative=S.Choose(S.Choose(localRow,remote),unknown)
local other=S.Choose(localRow,S.Choose(remote,unknown))
assert(associative.seconds==120 and other.seconds==120 and associative.guild=="New guild" and other.guild=="New guild")
for _,order in ipairs({{localRow,remote,unknown},{localRow,unknown,remote},{remote,localRow,unknown},
    {remote,unknown,localRow},{unknown,localRow,remote},{unknown,remote,localRow}}) do
    local result; for _,row in ipairs(order) do result=S.Choose(result,row) end
    assert(result.seconds==120 and result.serverAt==unknown.serverAt and result.guild=="New guild" and result.guildUpdatedAt==remote.guildUpdatedAt)
end
local db=M.Init({version=2,sourceId="local-source",characters={[key]=localRow}})
T:Init(db); IN_GUILD=nil; GUILD_NAME=nil; T:Begin(false)
assert(S.Import(db,payload(2,{remote})))
local projected=S.Display(db).characters[key]
assert(projected and projected._local and projected.guild=="New guild" and projected.seconds==100)
assert(db.characters[key].guild=="Old guild" and S.received[S.Key(remote)].guild=="New guild")
advance(1); T:Save()
assert(db.characters[key].guild=="Old guild") -- imported metadata cannot be re-exported as local
assert(S.Import(db,payload(1,{observation()})))
assert(not S.Import(db,payload(1,{remote})))
assert(S.Import(db,payload(2,{remote})))
assert(not S.Import(db,payload(3,{remote})))

-- UI has a dedicated escaped guild line and full tooltip; search uses raw names.
H.UI.db=db; H.UI:Create(); H.UI:Refresh()
assert(H.UI.rows[1].guild:GetText()==H.L.guild..": Old guild")
assert(H.UI.rows[1].active:IsShown())
local markup=observation({guild="|Hplayer:Example|hGuild [test]|h",guildUpdatedAt=EPOCH})
db.characters[key]=markup; H.UI:Refresh()
local guildLine=H.L.guild..": ||Hplayer:Example||hGuild [test]||h"
assert(H.UI.rows[1].guild:GetText()==guildLine)
H.UI:RowTooltip(H.UI.rows[1])
local found=false; for _,line in ipairs(GameTooltip.lines) do if line==guildLine then found=true end end
assert(found)
local rows=M.List(db,"guild [test]"); assert(#rows==1)
rows=M.List(db,IDENTITY.name); assert(#rows==1)
rows=M.List(db,"missing"); assert(#rows==0)
markup.guild=""; assert(M.GuildText(markup)==H.L.guild..": "..H.L.noGuild)
markup.guild=nil; markup.guildUpdatedAt=nil
assert(M.GuildText(markup)==H.L.guild..": "..H.L.guildUnknown)

-- Pair and number validation includes empty strings and the exact JSON/Lua limit.
assert(S.ValidGuild(nil,nil) and S.ValidGuild("",0) and S.ValidGuild(string.rep("ä",64),9007199254740991))
assert(not S.ValidGuild("x",nil) and not S.ValidGuild(nil,0))
assert(not S.ValidGuild("x",math.huge) and not S.ValidGuild("x",0/0) and not S.ValidGuild("x",-1))
assert(not S.ValidGuild("x",9007199254740992) and not S.ValidGuild("line\nbreak",0))
