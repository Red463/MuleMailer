test('full TOC startup native settings mailbox and real client adapter cooperate',function()
 dofile('tests/wow.lua'); fakeUI()
 local stock=20; local cursor; local attachments={}; local sent=0; local pending=false
 local A={}
 GetBuildInfo=function() return '1.60.1','70959','',16001 end
 UnitFullName=function() return 'Alice','Realm' end; UnitGUID=function() return 'Player-1' end; UnitFactionGroup=function() return 'Alliance' end
 GetTime=function() return 1 end; InCombatLockdown=function() return false end
 GameLimitedMode_IsActive=function() return false end; C_Mail={IsCommandPending=function() return pending end}
 strcmputf8i=function(a,b) return a:lower()==b:lower() and 0 or 1 end
 NUM_TOTAL_EQUIPPED_BAG_SLOTS=0; ATTACHMENTS_MAX_SEND=12
 C_Container={GetContainerNumSlots=function() return 1 end,GetContainerItemInfo=function() if stock>0 then return {itemID=2447,stackCount=stock,isLocked=false,isBound=false,hyperlink='item:2447'} end end,PickupContainerItem=function() cursor={id=2447,count=stock}; stock=0 end,SplitContainerItem=function(_,_,n) cursor={id=2447,count=n}; stock=stock-n end,GetContainerItemQuestInfo=function() return {isQuestItem=false} end}
 C_Item={GetItemInfo=function() return 'Peacebloom','item:2447',1,1,1,'Trade Goods','Herb',20,'',1,0,7,9,0 end,IsBound=function() return false end,CanBeRefunded=function() return false end,GetItemGUID=function() return 'bootstrap-source' end}
 ItemLocation={CreateFromBagAndSlot=function() return {} end}
 GetCursorInfo=function() if cursor then return 'item',cursor.id,'item:'..cursor.id end end
 GetSendMailItem=function(i) local a=attachments[i]; if a then return 'Peacebloom',a.itemID,1,a.count end end
 GetSendMailItemLink=function(i) if attachments[i] then return 'item:2447' end end
 HasSendMailItem=function(i) return attachments[i]~=nil end
 GetSendMailMoney=function() return 0 end; GetSendMailCOD=function() return 0 end
 ClickSendMailItemButton=function() attachments[#attachments+1]={itemID=cursor.id,count=cursor.count}; cursor=nil end
 SendMailNameEditBox=CreateFrame('EditBox'); SendMailSubjectEditBox=CreateFrame('EditBox'); SendMailBodyEditBox=CreateFrame('EditBox'); SendMailMoney=CreateFrame('Frame'); SendMailCODButton=CreateFrame('CheckButton')
 SendMailFrame=CreateFrame('Frame'); SendMailFrame:Hide(); MailFrameTab2=CreateFrame('Button'); SendMailMailButton=CreateFrame('Button'); SendMailFrameLockSendMail=CreateFrame('Frame'); SendMailFrameLockSendMail:Hide()
 MailFrameTab_OnClick=function() SendMailFrame:Show() end
 MoneyInputFrame_GetCopper=function() return 0 end; GetMoney=function() return 10000 end; GetSendMailPrice=function() return 30 end
 SetSendMailMoney=function(v) eq(v,0) end; SetSendMailCOD=function(v) eq(v,0) end
 SendMail=function(to,subject,body) eq(to,'Bank'); eq(subject,'Postly'); eq(body,''); eq(attachments[1].count,15); sent=sent+1; pending=true end
 PostlyDB=nil
 for line in io.lines('Postly.toc') do if line:match('%.lua$') then local path=line:gsub('%.lua$',''); module(path,A) end end
 A.OnEvent(nil,'ADDON_LOADED','Postly'); assert(A.initialized); assert(A.Options.category)
 eq(SLASH_POSTLY1,'/postly'); eq(SLASH_POSTLY2,nil); eq(SlashCmdList.POSTLY,A.Command)
 A.Store.SetRecipient(A.db,A.context,'Bank',false); A.Store.SetRule(A.db,A.context,'category','herbs',{enabled=true,keep=5})
 SendMailBodyEditBox:SetText('manual letter')
 A.OnEvent(nil,'MAIL_SHOW'); eq(sent,0); assert(A.Mailbox.panel:IsShown()); assert(A.Client.Probe().mail); eq(A.Mailbox.send.enabled,false)
 SendMailBodyEditBox:SetText(''); A.frame.scripts.OnUpdate(A.frame,0.2); eq(A.Mailbox.send.enabled,true)
 A.Mailbox.collapse.scripts.OnClick(); eq(A.Mailbox.compact:IsShown(),true)
 SendMailBodyEditBox:SetText('another manual draft'); A.frame.scripts.OnUpdate(A.frame,0.2); eq(A.Mailbox.compactSend.enabled,false)
 SendMailBodyEditBox:SetText(''); A.frame.scripts.OnUpdate(A.frame,0.2); eq(A.Mailbox.compactSend.enabled,true)
 A.Mailbox.compactSend.scripts.OnClick(A.Mailbox.compactSend); eq(sent,1); eq(stock,5); eq(A.queue.state,'awaiting-result')
 eq(A.Mailbox.compactSend:GetText(),'Waiting...'); eq(A.Mailbox.compactSend.enabled,false)
 A.Mailbox.compactExpand.scripts.OnClick(); eq(A.Mailbox.panel:IsShown(),true); eq(A.queue.state,'awaiting-result'); eq(sent,1)
 attachments={}; pending=false; SendMailNameEditBox:SetText(''); SendMailSubjectEditBox:SetText('')
 A.OnEvent(nil,'MAIL_SEND_SUCCESS'); eq(A.queue.state,'complete'); A.OnEvent(nil,'MAIL_CLOSED'); eq(A.Mailbox.panel:IsShown(),false)
 local record=A.db.history.entries[1]
 eq(record.outcome,'accepted'); eq(record.senderGUID,'Player-1'); eq(record.recipient,'Bank'); eq(record.postage,30)
 eq(record.items[1].itemID,2447); eq(record.items[1].count,15); eq(record.items[1].link,'item:2447'); eq(record.totalUnits,15)
 A.frame.scripts.OnEvent(A.frame,'ADDON_ACTION_FORBIDDEN','Postly','SetSendMailMoney')
 eq(A.Client.blockedAction,'SetSendMailMoney'); assert(A.draftDiagnostic:find('SetSendMailMoney'))
 assert(not A.Client.CanAct())
 CreateFrame=nil; Settings=nil; C_Container=nil; C_Item=nil; ItemLocation=nil; NUM_TOTAL_EQUIPPED_BAG_SLOTS=nil
end)

test('slash registration does not reassign the Blizzard command table or touch guild invite handlers',function()
 local A={}; local writes=0; local guild=function() return 'native guild handler' end
 local nativeCommands={GUILD_INVITE=guild}; local env
 env=setmetatable({CreateFrame=false,PostlyDB=false},{
  __index=function(_,key) if key=='SlashCmdList' then return nativeCommands end; return _G[key] end,
  __newindex=function(t,key,value)
   if key=='SlashCmdList' then writes=writes+1; nativeCommands=value else rawset(t,key,value) end
  end,
 })
 local core=assert(loadfile('Core.lua')); setfenv(core,env); core('Postly',A)
 module('Categories',A); module('Store',A); module('Planner',A); module('MailQueue',A)
 A.Client={GetContext=function() return {key='forever:Alliance',faction='Alliance',characterID='one',name='Alice',realm='Oak'} end,IsOpen=function() return false end,Probe=function() return {attachmentLimit=12} end}
 A.Options={Register=function() end}; A.Mailbox={Refresh=function() end}
 A.Initialize()
 eq(writes,0); eq(nativeCommands.GUILD_INVITE,guild); eq(nativeCommands.POSTLY,A.Command); eq(env.SLASH_POSTLY1,'/postly')
end)
