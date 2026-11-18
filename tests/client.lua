test('missing client APIs disable sending with a reason',function()
 local A={}; module('Client',A)
 local p=A.Client.Probe(); eq(p.mail,false); eq(p.inventory,false); assert(p.reason)
end)
test('postage estimates use a readable empty-composer rate and never guess a missing native value',function()
 local A={}; module('Client',A); local C=A.Client
 C.IsOpen=function() return true end; C.Attachments=function() return {} end
 GetSendMailPrice=function() return 30 end; eq(C.EstimatePostage({totalStacks=5}),150); eq(C.Postage(),30)
 C.Attachments=function() return {{itemID=2447}} end; eq(C.EstimatePostage({totalStacks=5}),nil)
 GetSendMailPrice=function() error('Unavailable') end; eq(C.Postage(),nil)
 GetSendMailPrice=function() return -1 end; eq(C.Postage(),nil)
 GetSendMailPrice=nil
end)
test('unresolved item requests are throttled across repeated bag scans',function()
 local A={}; module('Client',A); local requests=0
 C_Item={GetItemInfo=function() return nil end,RequestLoadItemDataByID=function() requests=requests+1 end}
 for i=1,20 do A.Client.ItemName(2447) end
 eq(requests,1); C_Item=nil
end)
test('login context falls back from an empty full-name realm and waits for identity',function()
 local A={}; module('Client',A)
 UnitFullName=function() return 'Banker','' end
 UnitGUID=function() return 'Player-Banker' end; UnitFactionGroup=function() return 'Alliance' end
 GetNormalizedRealmName=function() return 'Forever' end
 local c=A.Client.GetContext(); eq(c.realm,'Forever'); eq(c.key,'forever:Alliance')
 UnitFullName=function() return '','' end; eq(A.Client.GetContext(),nil)
 UnitFullName=nil; UnitGUID=nil; UnitFactionGroup=nil; GetNormalizedRealmName=nil
end)
test('item display metadata provides icons links quality and a safe loading placeholder',function()
 local A={}; module('Client',A)
 C_Item={GetItemInfo=function() return 'Tigerseye','item:818',2,1,1,'Trade Goods','Other',20,'',134118 end}
 local item=A.Client.ItemDisplay(818)
 eq(item.name,'Tigerseye'); eq(item.link,'item:818'); eq(item.icon,134118); eq(item.quality,2)
 C_Item={GetItemInfo=function() return nil end,GetItemIconByID=function() return 134118 end}
 item=A.Client.ItemDisplay(818); eq(item.icon,134118); assert(item.loading); eq(item.link,nil)
 C_Item=nil; item=A.Client.ItemDisplay(818); assert(item.icon); assert(item.name); eq(item.quality,1)
end)
test('Forever probes modern functions rather than numeric retail version',function()
 local A={}; module('Client',A)
 C_Container={GetContainerNumSlots=function() return 0 end,GetContainerItemInfo=function() end,PickupContainerItem=function() end,GetContainerItemQuestInfo=function() return {isQuestItem=false} end}
 C_Item={GetItemInfo=function() end,IsBound=function() return false end,CanBeRefunded=function() return false end,GetItemGUID=function() return 'one' end}; ItemLocation={CreateFromBagAndSlot=function() end}
 GetBuildInfo=function() return '1.60.1', 'test', '',16001 end
 local p=A.Client.Probe(); eq(p.inventory,true); eq(p.attachmentLimit,nil); eq(p.mail,false)
 C_Container=nil; C_Item=nil; ItemLocation=nil
end)
test('unknown or unreadable item data cannot be sent',function()
 local A={Categories={Classify=function() return 'herbs' end}}; module('Client',A)
 NUM_BAG_SLOTS=0
 C_Container={GetContainerNumSlots=function() return 1 end,GetContainerItemInfo=function() return {itemID=2447,stackCount=20,isLocked=false,isBound=false} end,PickupContainerItem=function() end,GetContainerItemQuestInfo=function() return {isQuestItem=false} end}
 C_Item={GetItemInfo=function() return nil end,IsBound=function() return false end,CanBeRefunded=function() return false end,GetItemGUID=function() return 'one' end}; ItemLocation={CreateFromBagAndSlot=function() return {} end}
 local s=A.Client.Snapshot(); eq(#s,1); eq(s[1].eligible,false); assert(s[1].reason)
 C_Container=nil; C_Item=nil; ItemLocation=nil
end)
