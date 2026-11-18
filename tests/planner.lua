local function planner()
 local A={}; module('Categories',A); module('Store',A); module('Planner',A)
 local r=A.Store.Resolve(A.Store.Init(),{key='x',characterID='one',name='Alice',realm='Realm'}).rules
 r.categories.herbs={enabled=true,keep=20}
 return A,r
end
local function stack(n,slot,eligible)
 return {itemID=2447,count=n,bag=0,slot=slot or 1,category='herbs',eligible=eligible~=false}
end
test('keep applies once across stacks and planner never mutates input',function()
 local A,r=planner(); local input={stack(20,1),stack(20,2),stack(13,3)}
 local p=A.Planner.Build(input,r,'Bank-Realm',12)
 eq(p.items[1].send,33); eq(p.items[1].keep,20); eq(p.totalUnits,33); eq(p.totalStacks,2); eq(p.estimatedMails,1)
 eq(input[1].count,20); eq(input[3].slot,3)
 eq(A.Planner.Build({stack(53)},r,'Bank-Realm',12).totalUnits,33)
end)
test('never beats category and per-item keep overrides defaults',function()
 local A,r=planner(); r.items[2447]={mode='never'}
 eq(A.Planner.Build({stack(53)},r,'Bank-Realm',12).totalUnits,0)
 r.items[2447]={mode='always',keep=7}; eq(A.Planner.Build({stack(53)},r,'Bank-Realm',12).totalUnits,46)
 r.categories.herbs.enabled=false; r.items[999]={mode='always'}
 local p=A.Planner.Build({{itemID=999,count=4,bag=0,slot=1,eligible=true}},r,'Bank-Realm',12)
 eq(p.totalUnits,4)
end)
test('excluded units retain keep allowance but are never sent',function()
 local A,r=planner(); local bad=stack(20,1,false); bad.reason='Bound'
 local p=A.Planner.Build({bad,stack(33,2)},r,'Bank-Realm',12)
 eq(p.totalUnits,33); eq(#p.skipped,1); eq(p.skipped[1].reason,'Bound')
 eq(A.Planner.Build({stack(7)},r,'Bank-Realm',12).totalUnits,0)
end)
test('unresolved locked unselected and unmailable items stay carried',function()
 local A,r=planner(); local locked=stack(30); locked.locked=true
 local unknown={itemID=999,count=7,bag=0,slot=2,eligible=true}
 local p=A.Planner.Build({locked,unknown,stack(40,3,false)},r,'Bank-Realm',12)
 eq(p.totalUnits,0); eq(p.estimatedMails,0); eq(#p.skipped,3)
end)
