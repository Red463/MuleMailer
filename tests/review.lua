local function clientFixture()
 dofile('tests/wow.lua'); fakeUI()
 local f={nativeMoney=0,nativeCOD=0,visibleMoney=0,occupied={},items={},trial=false,pending=false,stock=20,submitted=0}
 local A={}; module('Categories',A); module('Store',A); module('Client',A)
 GetBuildInfo=function() return '1.60.1','70959','',16001 end
 GetTime=function() return 1 end; InCombatLockdown=function() return false end
 GameLimitedMode_IsActive=function() return f.trial end
 C_Mail={IsCommandPending=function() return f.pending end}
 NUM_TOTAL_EQUIPPED_BAG_SLOTS=0; ATTACHMENTS_MAX_SEND=12
 C_Container={GetContainerNumSlots=function() return 1 end,GetContainerItemInfo=function() if f.stock>0 then return {itemID=2447,stackCount=f.stock,isLocked=false,isBound=false,hyperlink='item:2447:0'} end end,PickupContainerItem=function() end,SplitContainerItem=function() end,GetContainerItemQuestInfo=function() return {isQuestItem=false} end}
 C_Item={GetItemInfo=function() return 'Peacebloom','item:2447:0',1,1,1,'Trade Goods','Herb',20,'',1,0,7,9,0 end,IsBound=function() return false end,CanBeRefunded=function() return false end,GetItemGUID=function() return 'original-guid' end}
 ItemLocation={CreateFromBagAndSlot=function() return {} end}
 GetCursorInfo=function() return nil end
 GetSendMailItem=function(i) local x=f.items[i]; if x then return x.name,x.itemID,1,x.count end end
 GetSendMailItemLink=function(i) return f.items[i] and f.items[i].link end
 HasSendMailItem=function(i) return f.occupied[i] or f.items[i]~=nil end
 GetSendMailMoney=function() return f.nativeMoney end; GetSendMailCOD=function() return f.nativeCOD end
 ClickSendMailItemButton=function() end
 SendMailNameEditBox=CreateFrame('EditBox'); SendMailSubjectEditBox=CreateFrame('EditBox'); SendMailBodyEditBox=CreateFrame('EditBox'); SendMailMoney=CreateFrame('Frame'); SendMailCODButton=CreateFrame('CheckButton')
 SendMailFrame=CreateFrame('Frame'); SendMailFrame:Hide(); MailFrameTab2=CreateFrame('Button'); SendMailMailButton=CreateFrame('Button'); SendMailFrameLockSendMail=CreateFrame('Frame'); SendMailFrameLockSendMail:Hide()
 MoneyInputFrame_GetCopper=function() return f.visibleMoney end; GetMoney=function() return 10000 end; GetSendMailPrice=function() return 30 end
 SetSendMailMoney=function(n) f.nativeMoney=n end; SetSendMailCOD=function(n) f.nativeCOD=n end
 MailFrameTab_OnClick=function() SendMailFrame:Show(); if f.onTab then f.onTab() end end
 SendMail=function() f.submitted=f.submitted+1 end
 strcmputf8i=function(a,b) local function lower(s) return s:gsub('É','é'):lower() end; a=lower(a); b=lower(b); return a==b and 0 or (a<b and -1 or 1) end
 A.Client.open=true
 return A,f
end
local function cleanup() CreateFrame=nil; Settings=nil; C_Container=nil; C_Item=nil; ItemLocation=nil; C_Mail=nil; GetCursorInfo=nil; NUM_TOTAL_EQUIPPED_BAG_SLOTS=nil end
test('submitting item-only mail never invokes protected money setters',function()
 local A,f=clientFixture(); SendMailFrame:Show()
 SendMailNameEditBox:SetText('Bank-Realm'); SendMailSubjectEditBox:SetText('Mule Mailer')
 SetSendMailMoney=function() error('Protected money setter called') end
 SetSendMailCOD=function() error('Protected COD setter called') end
 assert(A.Client.Submit('Bank-Realm','Mule Mailer')); eq(f.submitted,1)
 cleanup()
end)
test('debug command only reports cached diagnostics without inspecting native UI',function()
 local A={}; module('Core',A); local message
 A.Message=function(s) message=s end; A.OpenOptions=function() error('UI must not be inspected by debug') end
 A.draftDiagnostic='recipient changed'; A.Command('debug'); assert(message:find('recipient changed'))
 assert(message:find(A.version,1,true)); assert(message:find('queue=',1,true))
end)
test('selected Send Mail tab may be click-disabled while its composer is available',function()
 local A,f=clientFixture()
 SendMailFrame:Show(); MailFrame.selectedTab=2; MailFrame.activeSubFrame=SendMailFrame; MailFrameTab2:Disable()
 assert(A.Client.CanAct(true))
 MailFrameTab2.isDisabled=1; assert(not A.Client.CanAct(true)); MailFrameTab2.isDisabled=nil
 f.trial=true; assert(not A.Client.CanAct(true)); f.trial=false
 MailFrameTab2:Hide(); assert(not A.Client.CanAct(true)); MailFrameTab2:Show()
 SendMailFrameLockSendMail:Show(); assert(not A.Client.CanAct(true)); SendMailFrameLockSendMail:Hide()
 f.pending=true; assert(not A.Client.CanAct(true)); f.pending=false
 MailFrame.selectedTab=1; assert(not A.Client.CanAct(true))
 cleanup()
end)
test('occupied unresolved mail slots and hidden money are preserved as drafts',function()
 local A,f=clientFixture(); f.occupied[1]=true
 assert(A.Client.HasManualDraft()); eq(#A.Client.Attachments(),1)
 f.occupied={}; f.nativeMoney=10; assert(A.Client.HasManualDraft())
 f.nativeMoney=0; f.nativeCOD=10; assert(A.Client.HasManualDraft()); cleanup()
end)
test('tab callbacks cannot have their draft overwritten',function()
 local A,f=clientFixture(); f.onTab=function() SendMailBodyEditBox:SetText('manual text') end
 assert(not A.Client.Begin('Bank-Realm','MuleMailer')); eq(SendMailBodyEditBox:GetText(),'manual text'); eq(SendMailNameEditBox:GetText(),''); cleanup()
end)
test('native limited locked pending hidden or disabled controls prevent actions',function()
 for _,mode in ipairs({'trial','hidden-tab','disabled-tab','lock','pending','hidden-composer','disabled-send'}) do
  local A,f=clientFixture(); SendMailFrame:Show()
  if mode=='trial' then f.trial=true elseif mode=='hidden-tab' then MailFrameTab2:Hide() elseif mode=='disabled-tab' then MailFrameTab2:Disable() elseif mode=='lock' then SendMailFrameLockSendMail:Show() elseif mode=='pending' then f.pending=true elseif mode=='hidden-composer' then SendMailFrame:Hide() else SendMailMailButton:Disable() end
  assert(not A.Client.Submit('Bank-Realm','MuleMailer'),mode); eq(f.submitted,0)
 end
 cleanup()
end)
test('missing quest or refund inspection never makes an item eligible',function()
 local A,f=clientFixture(); C_Container.GetContainerItemQuestInfo=nil
 local s=A.Client.Snapshot(); assert(not A.Client.Probe().mail); assert(#s==0 or not s[1].eligible)
 A,f=clientFixture(); C_Item.CanBeRefunded=nil; assert(not A.Client.Probe().mail); s=A.Client.Snapshot(); assert(#s==0 or not s[1].eligible); cleanup()
end)
test('localized self recipient uses the client UTF8 comparator',function()
 local A=clientFixture(); assert(A.Store.IsSelf('élodie-Test Realm',{name='Élodie',realm='TestRealm'})); cleanup()
end)
test('raw tradegoods gems use explicit IDs without selecting generic goods',function()
 local A={}; module('Categories',A)
 eq(A.Categories.Classify(818,7,11),'gems'); eq(A.Categories.Classify(774,7,0),'gems'); eq(A.Categories.Classify(999999,7,11),nil)
end)
test('repeated Stop retains the pending submission lock',function()
 local _,q,f,p=queueFixture(); q:Start(p); q:Stop(); q:Stop(); eq(q.state,'stopping'); f.success(q); eq(q.state,'stopped')
end)
test('success arriving before attachment clear reconciles on a later tick',function()
 local _,q,f,p=queueFixture(1,12); q:Start(p); q:OnEvent('MAIL_SEND_SUCCESS'); eq(q.state,'awaiting-result')
 f.commandPending=false; f.attached={}; q:Tick(1); eq(q.state,'complete'); eq(q.sentMails,1)
end)
test('stale success after early clear cannot acknowledge a native pending command',function()
 local _,q,f,p=queueFixture(2,1); q:Start(p); f.success(q); q:Continue()
 f.attached={}; f.commandPending=true; q:OnEvent('MAIL_SEND_SUCCESS'); eq(q.sentMails,1); eq(q.state,'awaiting-result')
 f.commandPending=false; q:OnEvent('MAIL_SEND_SUCCESS'); eq(q.sentMails,2)
end)
test('new stack sorting first never replaces original inventory',function()
 local _,q,f,p=queueFixture(2,1); q:Start(p); f.success(q); f.stock[2].slot=5
 table.insert(f.stock,1,{bag=0,slot=2,itemID=2447,count=20,eligible=true,category='herbs',guid='new',identity='item:2447:0'})
 q:Continue(); eq(f.stock[1].count,20); eq(f.stock[3].count,0)
end)
test('a foreign attachment variant with same base item ID stops submission',function()
 local _,q,f,p=queueFixture(1,12); f.async=true; q:Start(p); f.attached={f.pending}; f.pending=nil; q:Tick(1)
 f.attached[1].identity='item:2447:999'; assert(not q:Continue()); eq(#f.log,0)
end)
test('lost eligibility data on planned inventory stops rather than completes',function()
 local _,q,f,p=queueFixture(2,1); q:Start(p); f.success(q)
 f.stock[2].eligible=false; f.stock[2].uncertain=true; f.stock[2].reason='Item data loading'
 assert(not q:Continue()); eq(q.state,'error'); eq(#f.log,1)
end)
test('unreadable planned inventory prevents even a full prepared batch from submitting',function()
 local _,q,f,p=queueFixture(1,12); f.async=true; q:Start(p); f.attached={f.pending}; f.pending=nil
 f.stock[#f.stock+1]={bag=0,slot=2,itemID=2447,count=10,eligible=false,uncertain=true,reason='Item data unavailable'}
 q:Tick(1); assert(not q:Continue()); eq(#f.log,0); eq(q.state,'error')
end)
