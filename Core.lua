local addonID,A=...
A.id=addonID
A.name='Mule Mailer'
A.media='Interface\\AddOns\\'..addonID..'\\Media\\'
A.version='0.5.1'
function A.Message(text)
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cffe8ba57Mule Mailer:|r '..tostring(text)) end
end
function A.RefreshPlan()
 if not A.db then return end
 A.context=A.Client.GetContext()
 if not A.context then return end
 A.config=A.Store.Resolve(A.db,A.context)
 if not (A.queue and A.queue:Active()) then
  A.plans=A.Planner.BuildRoutes(A.Client.Snapshot(),A.config,A.Client.Probe().attachmentLimit,A.exclusions)
  A.plan=nil
  for _,p in ipairs(A.plans) do if p.recipient==A.selectedRecipient then A.plan=p end end
  if not A.plan then
   for _,p in ipairs(A.plans) do if p.totalUnits>0 then A.plan=p; break end end
  end
  A.plan=A.plan or A.plans[1]; A.selectedRecipient=A.plan.recipient
 end
 if A.Mailbox then A.Mailbox.Refresh(A.plan,A.queue and A.queue:GetStatus()) end
end
function A.SendDisabledReason()
 if not A.context or not A.config then return 'Character data is not ready.' end
 if A.config.error then return A.config.error end
 if not A.Client.IsOpen() then return 'Open a mailbox first.' end
 if A.Client.CanAct then local ok,reason=A.Client.CanAct(); if not ok then return reason end end
 local p=A.Client.Probe(); if not p.mail then return p.reason or 'Required mail APIs are unavailable.' end
 if A.Client.eventsReady==false then return 'Required mail events are unavailable.' end
 if not A.plan or not A.plan.recipient then return 'Choose a bank alt in Options.' end
 if A.Store.IsSelf(A.plan.recipient,A.context) then return 'This character is the bank alt.' end
 if not A.plan or A.plan.totalUnits==0 then
  if A.plan and #(A.plan.excluded or {})>0 then return 'Matching items are unchecked. Include them in Review items.' end
  return 'No eligible items. Configure selections in Options.'
 end
 if A.Client.HasManualDraft() then return 'Clear or send the existing mail draft first.' end
 if InCombatLockdown and InCombatLockdown() then return 'Mail actions are paused during combat.' end
 return nil
end
local function planKey(p)
 local parts={p.recipient or '',p.subject or ''}
 for _,row in ipairs(p.items) do
  parts[#parts+1]=row.itemID..':'..row.send..':'..row.keep
  local guids={}; for guid in pairs(row.sources or {}) do guids[#guids+1]=guid end; table.sort(guids)
  for _,guid in ipairs(guids) do local s=row.sources[guid]; parts[#parts+1]=guid..':'..s.identity..':'..s.count end
 end
 return table.concat(parts,';')
end
function A.StartSend()
 if not A.queue then return end
 if A.queue:Active() then
  local ok,why=A.queue:Continue(); if not ok and why then A.Message(why) end
  return
 end
 A.RefreshPlan()
 local why=A.SendDisabledReason(); if why then A.Message(why); return false,why end
 if A.config.sending.review then
  local key=planKey(A.plan)
  if A.reviewKey~=key then
   A.reviewKey=key; A.Mailbox.ExpandReview(); A.Mailbox.Refresh(A.plan,A.queue:GetStatus()); return false,'Review the items, then click Send reviewed items.'
  end
 end
 A.reviewKey=nil
 local ok,reason=A.queue:Start(A.plan)
 if not ok and reason then A.Message(reason) end
 return ok,reason
end
function A.EditSettings(change)
 if A.queue and A.queue:Active() then return false,'Stop the current transfer before changing settings.' end
 if not A.db or A.db.version~=1 then return false,'Saved settings use an unsupported version.' end
 local ok,why=change()
 if ok==false then return false,why end
 A.reviewKey=nil; A.RefreshPlan()
 if A.Options then A.Options.Refresh() end
 return true
end
function A.OpenOptions()
 if A.Options then A.Options.Open() end
end
function A.SelectDestination(recipient)
 if A.queue and A.queue:Active() then return false,'Stop the transfer before changing destinations.' end
 for _,p in ipairs(A.plans or {}) do
  if p.recipient==recipient then A.selectedRecipient=recipient; A.plan=p; A.reviewKey=nil; if A.Mailbox then A.Mailbox.Refresh(p,A.queue:GetStatus()) end; return true end
 end
 return false,'Destination not found.'
end
function A.SelectPreset(id)
 return A.EditSettings(function()
  local ok,why=A.Store.SelectPreset(A.db,A.context,id)
  if ok then A.selectedRecipient=nil end
  return ok,why
 end)
end
function A.ToggleExcluded(id)
 if A.queue and A.queue:Active() then return false,'Stop the transfer before changing reviewed items.' end
 A.exclusions=A.exclusions or {}; A.exclusions[id]=not A.exclusions[id] or nil
 A.reviewKey=nil; A.RefreshPlan(); return true
end
function A.QuickRule(id,mode)
 return A.EditSettings(function()
  local old=A.config.rules.items[id]
  return A.Store.SetRule(A.db,A.context,'item',id,{mode=mode,keep=old and old.keep})
 end)
end
function A.CloseMailbox()
 A.Client.open=false; A.reviewKey=nil; A.exclusions={}
 A.queue:OnEvent('MAIL_CLOSED'); A.Mailbox.Hide()
 if A.Workflows then A.Workflows.CloseMailbox() end
end
function A.Command(args)
 if type(args)=='string' and args:match('^%s*(.-)%s*$'):lower()=='debug' then
  local status=A.queue and A.queue:GetStatus()
  A.Message('v'..A.version..' queue='..(status and status.state or 'not initialized')..'; '..(A.draftDiagnostic or status and (status.reason or status.waitReason) or 'No stop recorded this session.'))
  return
 end
 A.OpenOptions()
end
function A.Initialize()
 if A.initialized then return end
 MuleMailerDB=A.Store.Init(MuleMailerDB); A.db=MuleMailerDB
 A.context=A.Client.GetContext(); if not A.context then return end
 A.initialized=true
 if A.History then A.History.Recover() end
 A.queue=A.MailQueue.New(A.Client,function(status)
  local previous=A.lastQueueState; A.lastQueueState=status.state
  if status.state=='complete' and previous~='complete' and status.sentMails>0 and A.config and A.config.sending.completion then
   A.Message(status.sentMails..' mail(s) accepted for '..(status.recipient or 'bank alt')..'.')
  end
  if status.state=='complete' and previous~='complete' then A.RefreshPlan()
  elseif A.Mailbox then A.Mailbox.Refresh(A.plan,status) end
  if A.Options then A.Options.RefreshLock() end
  if A.Workflows then A.Workflows.RefreshHistory() end
 end)
 if A.eventSupport then
  A.Client.eventsReady=true
  for _,event in ipairs({'MAIL_SHOW','MAIL_CLOSED','MAIL_SEND_SUCCESS','MAIL_FAILED','MAIL_SEND_INFO_UPDATE','BAG_UPDATE_DELAYED'}) do
   if not A.eventSupport[event] then A.Client.eventsReady=false end
  end
 end
 A.RefreshPlan(); A.Options.Register()
 SLASH_MULEMAILER1='/mulemailer'; SlashCmdList=SlashCmdList or {}; SlashCmdList.MULEMAILER=A.Command
end
function A.OnEvent(_,event,...)
 if event=='ADDON_LOADED' then
  if (...)==A.id then A.Initialize() end
  return
 elseif event=='PLAYER_LOGIN' or event=='PLAYER_ENTERING_WORLD' then
  A.Initialize(); A.RefreshPlan(); return
 end
 if not A.initialized then return end
 if event=='MAIL_SHOW' then
  A.Client.open=true; A.reviewKey=nil; A.RefreshPlan()
  if A.config and A.config.display.autoShow~=false then A.Mailbox.Show() end
 elseif event=='MAIL_CLOSED' then
  A.CloseMailbox()
 else
  A.queue:OnEvent(event,...)
  if event=='BAG_UPDATE_DELAYED' or event=='MAIL_SEND_INFO_UPDATE' or event=='ITEM_DATA_LOAD_RESULT' or event=='GET_ITEM_INFO_RECEIVED' or event=='MAIL_SEND_SUCCESS' or event=='MAIL_FAILED' or event=='PLAYER_REGEN_ENABLED' or event=='PLAYER_REGEN_DISABLED' then
   A.RefreshPlan()
   if A.Options then A.Options.RefreshItems() end
  end
 end
end
if CreateFrame then
 A.frame=CreateFrame('Frame'); A.eventSupport={}
 for _,event in ipairs({'ADDON_LOADED','PLAYER_LOGIN','PLAYER_ENTERING_WORLD','MAIL_SHOW','MAIL_CLOSED','MAIL_SEND_SUCCESS','MAIL_FAILED','MAIL_SEND_INFO_UPDATE','BAG_UPDATE_DELAYED','ITEM_DATA_LOAD_RESULT','GET_ITEM_INFO_RECEIVED','PLAYER_REGEN_ENABLED','PLAYER_REGEN_DISABLED','ADDON_ACTION_BLOCKED','ADDON_ACTION_FORBIDDEN'}) do
  A.eventSupport[event]=pcall(A.frame.RegisterEvent,A.frame,event)
 end
 A.frame:SetScript('OnEvent',function(frame,event,...)
  if event=='ADDON_ACTION_BLOCKED' or event=='ADDON_ACTION_FORBIDDEN' then
   local addon,action=...
   if addon==A.id then
    A.draftDiagnostic='Blocked action: '..(type(action)=='string' and action or 'unknown')
    if A.Client then A.Client.blockedAction=action or true end
    if A.History and A.queue and A.queue.inSubmit and type(action)=='string' and action:match('^SendMail') then
     A.History.Outcome(A.queue,'blocked','Blizzard blocked SendMail; no bypass or retry was attempted.')
    end
    if A.queue and A.queue:Active() then A.queue:Fail('Blizzard blocked this action. Use the standard mail window; no bypass or retry.') end
   end
  else A.OnEvent(frame,event,...) end
 end)
 local elapsed=0
 A.frame:SetScript('OnUpdate',function(_,dt)
  elapsed=elapsed+dt
  if elapsed>=0.1 then
   elapsed=0
   if A.queue and A.queue:Active() then A.queue:Tick(A.Client.Now()) end
   if A.initialized and A.Mailbox and A.Mailbox.panel and (A.Mailbox.panel:IsShown() or A.Mailbox.compact and A.Mailbox.compact:IsShown()) and not A.queue:Active() and A.Client.IsOpen() then
    -- Text-only compose changes have no mail event. Refresh only the visible
    -- button/status; full bag plans still refresh on inventory/mail events.
    local reason=A.SendDisabledReason() or false
    if reason~=A.lastIdleReason then A.lastIdleReason=reason; A.Mailbox.Refresh(A.plan,A.queue:GetStatus()) end
   end
  end
 end)
end
