local function perfFixture()
 dofile('tests/wow.lua'); fakeUI()
 local A={}; module('Core',A); module('Categories',A); module('Store',A); module('Planner',A); module('MailQueue',A)
 local f={open=false,scans=0,items=0,visible=false,time=0}
 A.Client={requested={},GetContext=function() return {key='forever:Alliance',faction='Alliance',characterID='perf',name='Alice',realm='Oak'} end,Probe=function() return {mail=true,attachmentLimit=12} end,IsOpen=function() return f.open end,Now=function() return f.time end,HasManualDraft=function() return false end,Snapshot=function() f.scans=f.scans+1; return {{itemID=2447,count=20,bag=0,slot=1,category='herbs',eligible=true}} end}
 A.Options={panel={IsShown=function() return f.visible end,IsVisible=function() return f.visible and f.parentVisible~=false end},Register=function() end,Refresh=function() end,RefreshLock=function() end,RefreshItems=function() f.items=f.items+1 end}
 A.Mailbox={Refresh=function() end,Show=function() end,Hide=function() end}
 PostlyDB=nil; A.Initialize(); f.scans=0
 return A,f
end
test('item data and bag event bursts do no bag scans or hidden settings rebuilds away from mailbox',function()
 local A,f=perfFixture()
 for i=1,200 do A.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',i,true); A.OnEvent(nil,'ITEM_DATA_LOAD_RESULT',i,true); A.OnEvent(nil,'BAG_UPDATE_DELAYED') end
 A.frame.scripts.OnUpdate(A.frame,0.3)
 print('PERF closed mailbox: '..f.scans..' bag scans; '..f.items..' hidden settings rebuilds for 600 events')
 eq(f.scans,0); eq(f.items,0)
 CreateFrame=nil; Settings=nil
end)
test('closing the Settings parent prevents hidden canvas rebuilds even when the canvas remains shown',function()
 local A,f=perfFixture(); f.visible=true; f.parentVisible=false; A.Client.requested[2447]=0
 for i=1,121 do A.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',2447,true) end
 A.frame.scripts.OnUpdate(A.frame,0.3); eq(f.items,0); eq(f.scans,0)
 CreateFrame=nil; Settings=nil
end)
test('mailbox bursts coalesce bag planning and ignore unrelated item data without refreshing hidden settings',function()
 local A,f=perfFixture(); f.open=true; A.OnEvent(nil,'MAIL_SHOW'); f.scans=0; f.items=0
 for i=1,200 do A.OnEvent(nil,'BAG_UPDATE_DELAYED'); A.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',900000+i,true) end
 eq(f.scans,0); A.frame.scripts.OnUpdate(A.frame,0.3)
 eq(f.scans,1); eq(f.items,0)
 f.scans=0
 for i=1,200 do A.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',900000+i,true) end
 A.frame.scripts.OnUpdate(A.frame,0.3); eq(f.scans,0)
 CreateFrame=nil; Settings=nil
end)
test('owned item data refreshes once while Options are visible without scanning bags away from mailbox',function()
 local A,f=perfFixture(); f.visible=true; A.Client.requested[2447]=0
 for i=1,200 do A.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',2447,true) end
 eq(f.items,0); A.frame.scripts.OnUpdate(A.frame,0.3)
 eq(f.items,1); eq(f.scans,0)
 CreateFrame=nil; Settings=nil
end)
test('reported 121 item replies plus 1430 further replies perform no background inventory work',function()
 local A,f=perfFixture(); A.Client.requested[2447]=0
 for i=1,121 do A.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',i,true) end
 for i=1,1430 do A.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',900000+i,true) end
 A.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',2447,true)
 for i=1,60 do A.frame.scripts.OnUpdate(A.frame,1/60) end
 eq(f.scans,0); eq(f.items,0); eq(A.Client.requested[2447],nil)
 CreateFrame=nil; Settings=nil
end)
test('closing mailbox discards a queued scan and opening it always gets current inventory',function()
 local A,f=perfFixture(); f.open=true; A.OnEvent(nil,'MAIL_SHOW'); eq(f.scans,1)
 A.OnEvent(nil,'BAG_UPDATE_DELAYED'); A.OnEvent(nil,'MAIL_CLOSED'); f.open=false
 A.frame.scripts.OnUpdate(A.frame,0.3); eq(f.scans,1)
 f.open=true; A.OnEvent(nil,'MAIL_SHOW'); eq(f.scans,2)
 CreateFrame=nil; Settings=nil
end)
test('owned replies while mailbox is open are coalesced and duplicate completion events do not rescan',function()
 local A,f=perfFixture(); f.open=true; A.OnEvent(nil,'MAIL_SHOW'); f.scans=0
 for i=1,121 do A.Client.requested[10000+i]=0; A.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',10000+i,true) end
 A.frame.scripts.OnUpdate(A.frame,0.3); eq(f.scans,1)
 for i=1,121 do A.OnEvent(nil,'ITEM_DATA_LOAD_RESULT',10000+i,true) end
 A.frame.scripts.OnUpdate(A.frame,0.3); eq(f.scans,1)
 CreateFrame=nil; Settings=nil
end)
test('bag and combat events do not rebuild a visible rules list whose item data did not change',function()
 local A,f=perfFixture(); f.visible=true
 for i=1,121 do A.OnEvent(nil,'BAG_UPDATE_DELAYED'); A.OnEvent(nil,'PLAYER_REGEN_DISABLED'); A.OnEvent(nil,'PLAYER_REGEN_ENABLED') end
 A.frame.scripts.OnUpdate(A.frame,0.3); eq(f.items,0); eq(f.scans,0)
 CreateFrame=nil; Settings=nil
end)
