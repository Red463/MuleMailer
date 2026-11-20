local _,A=...
local C={}
A.Categories=C
C.list={{'herbs','Herbs'},{'ore','Ore'},{'bars','Bars'},{'stone','Stone'},{'leather','Leather and hides'},{'cloth','Cloth'},{'enchanting','Enchanting materials'},{'gems','Gems'},{'cooking','Cooking ingredients'}}
-- Vanilla mining item IDs: Copper/Tin/Silver/Iron/Gold/Mithril/Truesilver/
-- Thorium/Dark Iron, plus Bronze/Steel alloys and the five mining stones.
-- Primary historical item groups (mining and ingredbar):
-- https://repos.wowace.com/wow/mr-plow/rev/2fc621ca2a33
-- Only item identifiers are used; no third-party implementation is included.
-- These exceptions still require trade-goods metadata. New Forever materials
-- remain unclassified until audited; explicit item selections work meanwhile.
local mining={}
local rawGems={}
-- Raw gem IDs in the same primary mining group. Forever can classify these
-- under generic trade goods (e.g. Tigerseye 818 under subclass 11).
for _,id in ipairs({818,774,1210,1206,1705,1529,3864,7909,7910,12361,12364,12799,12800,12363,11754}) do rawGems[id]=true end
for _,id in ipairs({2770,2771,2775,2772,2776,3858,7911,10620,11370}) do mining[id]='ore' end
for _,id in ipairs({2840,3576,2842,3575,3577,3860,6037,12359,11371,2841,3859,12360,12655}) do mining[id]='bars' end
for _,id in ipairs({2835,2836,2838,7912,12365}) do mining[id]='stone' end
function C.Classify(id,class,subclass)
 if class==3 then return 'gems' end
 if class~=7 then return nil end
 if rawGems[id] then return 'gems' end
 if mining[id] then return mining[id] end
 return ({[9]='herbs',[6]='leather',[5]='cloth',[12]='enchanting',[8]='cooking'})[subclass]
end

-- Audited base materials supplement items discovered through inventory metadata.
-- Metadata remains authoritative for sending; this list is for browsing only.
C.catalog={
 herbs={2447,765,2449,785,2450,2452,2453,3355,3369,3356,3357,3818,3820,3819,4625,8831,8836,8838,8839,8845,8846,13463,13464,13465,13466,13467,13468},
 leather={2934,2318,2319,4234,4304,8170,783,4232,4235,8169,15417,15419,15416,15414,15415,17012},
 cloth={2589,2592,4306,4338,14047,14256},
 enchanting={10940,10938,10939,10978,11083,11082,11084,11137,11134,11135,11138,11139,11176,11174,11175,11177,11178,16204,16202,16203,14343,14344,20725},
 cooking={2672,2673,2674,2675,2677,2886,3172,3173,3174,3667,3685,3712,3730,3731,4603,4655,5465,5466,5467,5468,5469,5470,5471,5503,5504,6289,6291,6303,6308,6317,6361,6362,6889,7974,8365,8959,12037,12184,12202,12203,12204,12205,12206,12207,12208,12223,13754,13755,13756,13758,13759,13760,13888,13889,13893,20424},
 ore={},bars={},stone={},gems={}
}
for id,key in pairs(mining) do C.catalog[key][#C.catalog[key]+1]=id end
for id in pairs(rawGems) do C.catalog.gems[#C.catalog.gems+1]=id end
function C.Observe(stacks,db)
 if not db or db.version~=1 then return end
 db.materialCatalog=db.materialCatalog or {}
 for _,s in ipairs(stacks) do if s.category then db.materialCatalog[s.itemID]=s.category end end
end
function C.Items(key,db)
 local ids,seen={},{}
 local function include(id) if not seen[id] then seen[id]=true; ids[#ids+1]=id end end
 for _,id in ipairs(C.catalog[key] or {}) do include(id) end
 for id,category in pairs(db.materialCatalog or {}) do if category==key then include(id) end end
 table.sort(ids); return ids
end
