local _,A=...
local C={open=false,requested={}}
A.Client=C
local function fn(t,k) return type(t)=='table' and type(t[k])=='function' end
local function readable(v) return not issecretvalue or not issecretvalue(v) end
local function text(box) return box and box:GetText() or '' end
function C.Identity(link)
 if not readable(link) or type(link)~='string' or link=='' then return nil end
 return link:match('|H(item:[^|]+)|h') or link:match('^(item:[^|]+)$')
end
local function request(id)
 if not fn(C_Item,'RequestLoadItemDataByID') then return end
 local now=GetTime and GetTime() or 0
 if C.requested[id]==nil or now-C.requested[id]>=5 then C.requested[id]=now; C_Item.RequestLoadItemDataByID(id) end
end
function C.Probe()
 local p={multiSendVerified=false}
 p.inventory=fn(C_Container,'GetContainerNumSlots') and fn(C_Container,'GetContainerItemInfo') and fn(C_Container,'PickupContainerItem') and fn(C_Container,'GetContainerItemQuestInfo') and fn(C_Item,'GetItemInfo') and fn(C_Item,'IsBound') and fn(C_Item,'CanBeRefunded') and fn(C_Item,'GetItemGUID') and fn(ItemLocation,'CreateFromBagAndSlot')
 p.split=fn(C_Container,'SplitContainerItem')
 p.settings=fn(Settings,'RegisterCanvasLayoutCategory') and fn(Settings,'RegisterAddOnCategory') and fn(Settings,'OpenToCategory')
 p.attachmentLimit=type(ATTACHMENTS_MAX_SEND)=='number' and ATTACHMENTS_MAX_SEND>0 and ATTACHMENTS_MAX_SEND or nil
 p.mail=p.inventory and p.attachmentLimit~=nil and type(SendMail)=='function' and type(ClickSendMailItemButton)=='function' and type(GetSendMailItem)=='function' and type(GetSendMailItemLink)=='function' and type(HasSendMailItem)=='function' and type(GetSendMailMoney)=='function' and type(GetSendMailCOD)=='function' and type(GetCursorInfo)=='function' and type(SetSendMailMoney)=='function' and type(SetSendMailCOD)=='function' and type(GetSendMailPrice)=='function' and type(MoneyInputFrame_GetCopper)=='function' and SendMailNameEditBox~=nil and SendMailSubjectEditBox~=nil and SendMailBodyEditBox~=nil and SendMailFrame~=nil and SendMailFrameLockSendMail~=nil and MailFrameTab2~=nil and SendMailMailButton~=nil and type(GameLimitedMode_IsActive)=='function' and fn(C_Mail,'IsCommandPending') and type(strcmputf8i)=='function'
 if GetBuildInfo then local _,_,_,v=GetBuildInfo(); p.forever=v==16001 else p.forever=false end
 if not p.forever then p.mail=false; p.reason='Postly supports WoW Forever (interface 16001) only.'
 elseif not p.inventory then p.reason='Required Forever inventory APIs are unavailable.'
 elseif not p.mail then p.reason='Open the standard mailbox; required mail controls are unavailable.' end
 return p
end
function C.GetContext()
 if not UnitFullName or not UnitGUID or not UnitFactionGroup then return nil end
 local function nonempty(v) return type(v)=='string' and v~='' and v or nil end
 local name,realm=UnitFullName('player')
 realm=nonempty(realm) or (GetNormalizedRealmName and nonempty(GetNormalizedRealmName())) or (GetRealmName and nonempty(GetRealmName()))
 local guid=UnitGUID('player'); local faction=UnitFactionGroup('player')
 if not nonempty(name) or not realm or not nonempty(guid) or not nonempty(faction) then return nil end
 return {key='forever:'..faction,characterID=guid,name=name,realm=realm,faction=faction}
end
function C.ItemName(id)
 if fn(C_Item,'GetItemInfo') then local name=C_Item.GetItemInfo(id); if name then return name end end
 request(id)
 return 'Item '..tostring(id)..' (loading)'
end
function C.ItemDisplay(id)
 local info=fn(C_Item,'GetItemInfo') and {C_Item.GetItemInfo(id)} or {}
 local name,link,quality,icon=info[1],info[2],info[3],info[10]
 if not readable(name) or type(name)~='string' or name=='' then name=nil end
 if not readable(link) or type(link)~='string' or link=='' then link=nil end
 if not readable(quality) or type(quality)~='number' or quality<0 or quality>8 then quality=1 end
 if not readable(icon) or not icon then icon=fn(C_Item,'GetItemIconByID') and C_Item.GetItemIconByID(id) or nil end
 if not readable(icon) or not icon then icon='Interface\\Icons\\INV_Misc_QuestionMark' end
 if not name then request(id) end
 return {name=name or 'Item '..tostring(id)..' (loading)',link=link,quality=quality,icon=icon,loading=not name,category=A.Categories and readable(info[12]) and readable(info[13]) and A.Categories.Classify(id,info[12],info[13]) or nil}
end
local function inspect(bag,slot,info)
 local s={bag=bag,slot=slot,itemID=info.itemID,count=info.stackCount,locked=info.isLocked,eligible=false,uncertain=true,link=info.hyperlink}
 if not readable(s.itemID) or not readable(s.count) or type(s.itemID)~='number' or type(s.count)~='number' then return nil end
 local name,_,_,_,_,_,_,_,_,_,_,classID,subclassID,bindType=C_Item.GetItemInfo(s.itemID)
 if not readable(name) or not readable(classID) or not readable(bindType) then s.reason='Item data unavailable'; return s end
 s.name=name
 if not name or classID==nil or bindType==nil then
  s.reason='Item data loading'
  request(s.itemID)
  return s
 end
 s.identity=C.Identity(s.link)
 local loc=ItemLocation:CreateFromBagAndSlot(bag,slot)
 s.guid=C_Item.GetItemGUID(loc)
 if not s.identity or not readable(s.guid) or type(s.guid)~='string' or s.guid=='' then s.reason='Item identity unavailable'; return s end
 s.category=A.Categories and A.Categories.Classify(s.itemID,classID,subclassID)
 local quest=C_Container.GetContainerItemQuestInfo(bag,slot)
 if not quest then s.reason='Quest status unavailable'; return s end
 s.uncertain=false
 if classID==12 or (quest and (quest.isQuestItem or quest.questID)) then s.reason='Quest item'; return s end
 local bound=C_Item.IsBound(loc)
 if not readable(bound) or type(bound)~='boolean' then s.reason='Binding status unavailable'; s.uncertain=true; return s end
 if bound or bindType==1 or bindType>3 then s.reason='Bound or special-binding item'; return s end
 local refundable=C_Item.CanBeRefunded(loc)
 if not readable(refundable) or type(refundable)~='boolean' then s.reason='Refund status unavailable'; s.uncertain=true; return s end
 if refundable then s.reason='Refundable item'; return s end
 if not readable(s.locked) or s.locked then s.reason='Item is locked'; return s end
 s.eligible=true
 return s
end
function C.Snapshot()
 local out={}
 if not C.Probe().inventory then out.uncertain=true; return out end
 local last=NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
 for bag=0,last do
  for slot=1,C_Container.GetContainerNumSlots(bag) do
   local ok,s=pcall(function()
    local info=C_Container.GetContainerItemInfo(bag,slot)
    return info and inspect(bag,slot,info)
   end)
   if ok and s then out[#out+1]=s elseif not ok then out.uncertain=true end
  end
 end
 return out
end
function C.Attachments()
 local list={}
 if type(HasSendMailItem)~='function' then list.uncertain=true; return list end
 for i=1,(C.Probe().attachmentLimit or 0) do
  local occupied=HasSendMailItem(i)
  local name,id,_,count=GetSendMailItem(i)
  if occupied or name or id then
   if not id and GetSendMailItemLink then id=tonumber((GetSendMailItemLink(i) or ''):match('item:(%d+)')) end
   local identity=C.Identity(GetSendMailItemLink(i))
   list[#list+1]={index=i,itemID=id,count=count,identity=identity,unresolved=not identity or not id or not count}
  end
 end
 return list
end
function C.Draft()
 local copper=SendMailMoney and MoneyInputFrame_GetCopper and MoneyInputFrame_GetCopper(SendMailMoney) or 0
 local money=GetSendMailMoney and GetSendMailMoney(); local cod=GetSendMailCOD and GetSendMailCOD()
 local uncertain=not readable(money) or not readable(cod) or type(money)~='number' or type(cod)~='number'
 return {recipient=text(SendMailNameEditBox),subject=text(SendMailSubjectEditBox),body=text(SendMailBodyEditBox),money=uncertain and copper or math.max(copper,money),cod=(SendMailCODButton and SendMailCODButton:GetChecked()) or (not uncertain and cod~=0) or false,uncertain=uncertain,attachments=C.Attachments()}
end
function C.HasManualDraft()
 local d=C.Draft()
 return d.uncertain or d.attachments.uncertain or d.recipient~='' or d.subject~='' or d.body~='' or d.money~=0 or d.cod or #d.attachments>0,'Clear or send the existing mail draft first.'
end
function C.IsOpen() return C.open and MailFrame and MailFrame:IsShown() end
function C.CursorEmpty() return not GetCursorInfo() end
function C.Now() return GetTime() end
function C.Timestamp() return time and time() or nil end
function C.Postage()
 if not GetSendMailPrice then return nil end
 local ok,value=pcall(GetSendMailPrice)
 if ok and readable(value) and type(value)=='number' and value>=0 then return value end
end
function C.EstimatePostage(plan)
 if not C.IsOpen() then return nil end
 local attachments=C.Attachments()
 if attachments.uncertain or #attachments>0 then return nil end
 local price=C.Postage()
 return price and price*(plan.totalStacks or 0) or nil
end
function C.CommandPending() return not fn(C_Mail,'IsCommandPending') or C_Mail.IsCommandPending()~=false end
function C.CanAct(requireComposer)
 if C.blockedAction then return false,'Blizzard blocked a mail action. Reload after updating; no automatic retry.' end
 if not C.IsOpen() then return false,'Open a mailbox first.' end
 if InCombatLockdown and InCombatLockdown() then return false,'Mail actions are paused during combat.' end
 local p=C.Probe(); if not p.mail then return false,p.reason end
 if C.eventsReady==false then return false,'Required mail events are unavailable.' end
 -- Native panel tabs disable clicks on the selected tab. That is not an
 -- account restriction: accept it only when this is the selected, active,
 -- visible Send Mail composer. Other disabled tabs remain unavailable.
 local selected=PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(MailFrame) or MailFrame.selectedTab
 local selectedComposer=selected==2 and MailFrame.activeSubFrame==SendMailFrame and SendMailFrame:IsShown()
 if GameLimitedMode_IsActive() or not MailFrameTab2:IsShown() or MailFrameTab2.isDisabled or (not MailFrameTab2:IsEnabled() and not selectedComposer) then return false,'The standard Send Mail tab is unavailable for this account.' end
 if C.CommandPending() then return false,'Wait for the pending mail command to finish.' end
 if SendMailFrameLockSendMail:IsShown() or StaticPopup_Visible and StaticPopup_Visible('CONFIRM_MAIL_ITEM_UNREFUNDABLE') then return false,'Resolve the standard mail confirmation before continuing.' end
 if requireComposer and not SendMailFrame:IsShown() then return false,'Open the standard Send Mail tab before continuing.' end
 return true
end
function C.Begin(recipient,subject)
 local ok,why=C.CanAct(); if not ok then return false,why end
 if C.HasManualDraft() then return false,'Clear or send the existing mail draft first.' end
 if not C.CursorEmpty() then return false,'Empty your cursor first.' end
 if MailFrameTab_OnClick then MailFrameTab_OnClick(nil,2) end
 ok,why=C.CanAct(true); if not ok then return false,why end
 if C.HasManualDraft() or not C.CursorEmpty() then return false,'Mail contents changed while opening Send Mail. Your draft has been preserved.' end
 SendMailNameEditBox:SetText(recipient); SendMailSubjectEditBox:SetText(subject); SendMailBodyEditBox:SetText('')
 return true
end
function C.Attach(stack,count)
 local ok,why=C.CanAct(true); if not ok then return false,why end
 if not C.CursorEmpty() then return false,'Cursor changed; unsent items remain in the mail window.' end
 local current=C_Container.GetContainerItemInfo(stack.bag,stack.slot)
 local guid=C_Item.GetItemGUID(ItemLocation:CreateFromBagAndSlot(stack.bag,stack.slot))
 if not current or guid~=stack.guid or C.Identity(current.hyperlink)~=stack.identity or current.stackCount~=stack.count then return false,'Original item changed before pickup. Start a fresh transfer.' end
 if count<stack.count then
  if not C.Probe().split then return false,'Partial stacks are unsupported on this client.' end
  C_Container.SplitContainerItem(stack.bag,stack.slot,count)
 else C_Container.PickupContainerItem(stack.bag,stack.slot) end
 local kind,id,link,cursorID=GetCursorInfo()
 if kind~='item' or (id~=stack.itemID and cursorID~=stack.itemID) or C.Identity(link)~=stack.identity then return false,'Item pickup did not match. Check your cursor and mail window.' end
 ClickSendMailItemButton()
 if not C.CursorEmpty() then return false,'Item could not be attached. Check your cursor and mail window.' end
 return true
end
function C.Affordable()
 if not GetSendMailPrice or not GetMoney then return false end
 return GetMoney()>=GetSendMailPrice()
end
-- Only the explicit mailbox button's OnClick path may call Submit.
-- Events and timers never call this function or synthesize a click.
function C.Submit(recipient,subject)
 local ok,why=C.CanAct(true); if not ok then return false,why end
 if not SendMailMailButton:IsEnabled() then return false,'The standard Send Mail button is disabled.' end
 local d=C.Draft()
 if d.uncertain or d.money~=0 or d.cod or not A.Store.SameRecipient(recipient,d.recipient) or d.subject~=subject or d.body~='' then return false,'Mail contents changed. Your draft has been preserved.' end
 if not C.Affordable() then return false,'Not enough money for postage.' end
 -- The verified draft already contains zero money/COD. Their setters are
 -- protected; never call them from addon code, even to reset them to zero.
 SendMail(recipient,subject,'')
 return true
end
