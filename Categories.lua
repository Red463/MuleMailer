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
