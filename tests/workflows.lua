local function fixture()
 local A={}; module('Categories',A); module('Store',A); module('Planner',A)
 local c={key='forever:Alliance',faction='Alliance',characterID='one',name='Alice',realm='Oak'}
 local db=A.Store.Init(); A.Store.Resolve(db,c)
 return A,db,c
end
test('presets copy current settings independently and preserve Default and character selection',function()
 local A,db,c=fixture(); local S=A.Store
 S.SetRecipient(db,c,'Bank Oak',false); S.SetRule(db,c,'category','herbs',{enabled=true,keep=7})
 local ok,id=S.CreatePreset(db,c,'Crafting'); assert(ok)
 eq(S.Resolve(db,c).presetName,'Crafting'); S.SetRecipient(db,c,'Crafter Pine',false)
 S.SetRule(db,c,'category','herbs',{enabled=true,keep=20}); S.SetSubject(db,c,'Craft supplies')
 local other=S.Copy(c); other.characterID='two'
 eq(S.Resolve(db,other).recipient,'Bank Oak'); eq(S.Resolve(db,c).sending.subject,'Craft supplies')
 S.SelectPreset(db,c,nil); eq(S.Resolve(db,c).rules.categories.herbs.keep,7)
 S.SelectPreset(db,c,id); eq(S.Resolve(S.Init(S.Copy(db)),c).rules.categories.herbs.keep,20)
 assert(S.RenamePreset(db,c,id,'Alchemy')); eq(S.Resolve(db,c).presetName,'Alchemy')
 assert(S.DeletePreset(db,c,id)); eq(S.Resolve(db,c).recipient,'Bank Oak'); eq(#S.ListPresets(db,c),0)
end)
test('history records each native-confirmed batch once with immutable full details',function()
 local A,q,f,p,c=queueFixture(2,1); module('History',A); A.db=A.Store.Init(); A.context={name='Alice',realm='Oak',characterID='guid',faction='Alliance'}
 c.GetContext=function() return A.context end; c.Timestamp=function() return 100 end; c.Postage=function() return 30 end
 c.ItemDisplay=function(id) return {name='Peacebloom',link='item:'..id,icon=1} end
 p.presetName='Selling'; q:Start(p)
 local record=A.db.history.entries[1]; eq(record.outcome,'pending'); eq(record.recipient,'Bank Realm'); eq(record.items[1].count,20); eq(record.sender,'Alice Oak'); eq(record.subject,p.subject); eq(record.postage,30); eq(record.preset,'Selling')
 f.success(q); eq(record.outcome,'accepted'); q:OnEvent('MAIL_SEND_SUCCESS'); eq(#A.db.history.entries,1)
 q:Continue(); eq(#A.db.history.entries,2); f.success(q); eq(record.items[1].count,20)
 eq(#A.History.Search('selling','accepted'),2); eq(#A.History.Search('Peacebloom','accepted'),2); eq(#A.History.Search('unknown','all'),0)
end)
test('history distinguishes failed blocked and uncertain sends and recovers pending on reload',function()
 for _,mode in ipairs({'failure','blocked','closed','timeout','reload'}) do
  local A,q,f,p,c=queueFixture(1,12); module('History',A); A.db=A.Store.Init()
  if mode=='blocked' then c.Submit=function() return false,'Blocked' end end
  q:Start(p)
  if mode=='failure' then q:OnEvent('MAIL_FAILED') elseif mode=='closed' then q:OnEvent('MAIL_CLOSED') elseif mode=='timeout' then q:Tick(99) elseif mode=='reload' then A.History.Recover() end
  local entry=A.db.history.entries[1]
  eq(entry.outcome,mode=='failure' and 'failed' or mode=='blocked' and 'blocked' or 'uncertain'); assert(entry.reason)
 end
end)
test('history retention bounds size without dropping the newest record and missing postage stays unknown',function()
 local A,q,f,p,c=queueFixture(1,12); module('History',A); A.db=A.Store.Init()
 A.db.history={nextID=500,entries={}}; for i=1,500 do A.db.history.entries[i]={id=i,outcome='accepted'} end
 q:Start(p); eq(#A.db.history.entries,500); eq(A.db.history.entries[1].id,501); eq(A.db.history.entries[1].postage,nil)
end)
test('native blocked SendMail events during submission record blocked rather than uncertain',function()
 local A,q,f,p,c=queueFixture(1,12); dofile('tests/wow.lua'); fakeUI(); module('Core',A); module('History',A)
 A.db=A.Store.Init(); A.queue=q; A.Client=c
 c.Submit=function()
  A.frame.scripts.OnEvent(A.frame,'ADDON_ACTION_BLOCKED','MuleMailer','SendMail')
  return true
 end
 q:Start(p); eq(q.state,'error'); eq(A.db.history.entries[1].outcome,'blocked'); eq(#f.log,0)
 CreateFrame=nil; Settings=nil
end)
test('exact postage history is recorded even when its preview is disabled',function()
 local A,q,f,p,c=queueFixture(1,12); module('History',A); A.db=A.Store.Init(); A.db.sending.postage=false
 c.Postage=function() return 60 end; q:Start(p); eq(A.db.history.entries[1].postage,60)
end)
test('presets reject invalid names and cross-faction selection without altering settings',function()
 local A,db,c=fixture(); local S=A.Store
 assert(not S.CreatePreset(db,c,' ')); assert(not S.CreatePreset(db,c,'Bad\nname'))
 local ok,id=S.CreatePreset(db,c,'Storage'); assert(ok); assert(not S.CreatePreset(db,c,'storage'))
 local alien=S.Copy(c); alien.faction='Horde'; alien.characterID='horde'
 assert(not S.SelectPreset(db,alien,id)); eq(S.Resolve(db,alien).presetName,'Default')
 eq(S.Init({version=9}).presets,nil)
end)
test('routing uses item then category then default without duplicating units or bypassing rules',function()
 local A,db,c=fixture(); local S=A.Store
 S.SetRecipient(db,c,'Bank Oak',false); S.SetRule(db,c,'category','herbs',{enabled=true,keep=5}); S.SetRule(db,c,'category','ore',{enabled=true,keep=0})
 assert(S.SetDestination(db,c,'category','herbs','Herbalist Pine'))
 assert(S.SetDestination(db,c,'item',2447,'Alchemist Ash'))
 local stock={{itemID=2447,count=20,bag=0,slot=1,category='herbs',eligible=true},{itemID=765,count=9,bag=0,slot=2,category='herbs',eligible=true},{itemID=2770,count=7,bag=0,slot=3,category='ore',eligible=true}}
 local plans=A.Planner.BuildRoutes(stock,S.Resolve(db,c),12,{})
 eq(#plans,3); local totals={}; for _,p in ipairs(plans) do totals[p.recipient]=p.totalUnits end
 eq(totals['Alchemist Ash'],15); eq(totals['Herbalist Pine'],4); eq(totals['Bank Oak'],7)
 S.SetRule(db,c,'item',2447,{mode='never'})
 plans=A.Planner.BuildRoutes(stock,S.Resolve(db,c),12,{})
 for _,p in ipairs(plans) do for _,item in ipairs(p.items) do assert(item.itemID~=2447) end end
 assert(not S.SetDestination(db,c,'item',2447,'Alice Oak'))
end)
test('temporary exclusions are reversible and preserve keep and source settings',function()
 local A,db,c=fixture(); local S=A.Store
 S.SetRecipient(db,c,'Bank Oak',false); S.SetRule(db,c,'category','herbs',{enabled=true,keep=5})
 local stock={{itemID=2447,count=20,bag=0,slot=1,category='herbs',eligible=true,guid='g',identity='item:2447'}}
 local cfg=S.Resolve(db,c); local p=A.Planner.BuildRoutes(stock,cfg,12,{[2447]=true})[1]
 eq(p.totalUnits,0); eq(p.excluded[1].itemID,2447); eq(p.excluded[1].retained,20)
 p=A.Planner.BuildRoutes(stock,cfg,12,{})[1]; eq(p.totalUnits,15); eq(p.items[1].sources.g.count,20)
 eq(cfg.rules.categories.herbs.keep,5); eq(stock[1].count,20)
end)
