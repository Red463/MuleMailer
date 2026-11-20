local _,A=...
local M={reviewRows={}}
A.Mailbox=M
local function compactTooltip(self)
 if not GameTooltip then return end
 local active=A.queue and A.queue:Active(); local status=A.queue and A.queue:GetStatus()
 local plan=M.lastPlan or A.plan
 local recipient=active and status.recipient or plan and plan.recipient
 GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); GameTooltip:SetText('Postly')
 GameTooltip:AddLine('To: '..(recipient and A.Store.RecipientLabel(recipient) or 'Not configured'),1,0.85,0.5,true)
 GameTooltip:AddLine('Preset: '..(A.config and A.config.presetName or 'Default'),1,1,1,true)
 GameTooltip:AddLine('Subject: '..(active and A.queue.subject or plan and plan.subject or 'Postly'),1,1,1,true)
 GameTooltip:AddLine(M.summary:GetText(),1,1,1,true)
 GameTooltip:AddLine(M.status:GetText(),0.95,0.86,0.66,true)
 GameTooltip:AddLine('Use + to open the full window. Drag the logo to move.',0.8,0.75,0.65,true); GameTooltip:Show()
end
local function tooltipLeave(self)
 self.UpdateTooltip=nil; if GameTooltip then GameTooltip:Hide() end
end
local function place(frame)
 frame:ClearAllPoints()
 local point=A.db and A.db.display and A.db.display.point
 if point then frame:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',point.x,point.y)
 elseif MailFrame then frame:SetPoint('TOPLEFT',MailFrame,'TOPRIGHT',8,-30)
 else frame:SetPoint('CENTER',UIParent,'CENTER',260,0) end
end
local function draggable(frame)
 frame:SetMovable(true); frame:SetClampedToScreen(true); frame:EnableMouse(true); frame:RegisterForDrag('LeftButton')
 frame:SetScript('OnDragStart',function(self) self:StartMoving() end)
 frame:SetScript('OnDragStop',function(self)
  self:StopMovingOrSizing()
  if A.db.version==1 then A.db.display.point={x=self:GetLeft(),y=self:GetBottom()} end
 end)
end
function M.Create()
 if M.panel then return end
 local W=A.Widgets
 local p=CreateFrame('Frame',nil,MailFrame or UIParent,'BackdropTemplate'); M.panel=p; p:SetSize(320,248); p:SetFrameStrata('DIALOG'); W.Backdrop(p); draggable(p)
 local mark=p:CreateTexture(nil,'ARTWORK'); mark:SetPoint('TOPLEFT',p,'TOPLEFT',16,-12); mark:SetSize(64,64); mark:SetTexture(A.media..'Icon')
 W.Text(p,'Postly',92,22,166,'GameFontNormalLarge')
 local tagline=W.Text(p,'A little help for your bank alt.',92,44,166,'GameFontHighlightSmall'); tagline:SetHeight(30); tagline:SetTextColor(unpack(W.theme.muted))
 local close=CreateFrame('Button',nil,p,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',p,'TOPRIGHT',-3,-3); close:SetScript('OnClick',function() p:Hide() end)
 M.collapse=W.Button(p,'-',258,8,22,function() M.SetCompact(true) end); M.collapse:SetHeight(22)
 M.collapse:SetScript('OnEnter',function(self)
  if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); GameTooltip:SetText('Collapse to mini bar'); GameTooltip:Show() end
 end); M.collapse:SetScript('OnLeave',tooltipLeave)
 M.recipient=W.Text(p,'',16,92,285,'GameFontNormal'); M.recipient:SetHeight(26)
 M.summary=W.Text(p,'',16,124,285); M.summary:SetHeight(20); M.summary:SetTextColor(unpack(W.theme.text))
 M.status=W.Text(p,'',16,128,285,'GameFontHighlightSmall'); M.status:SetTextColor(unpack(W.theme.text))
 M.send=W.Button(p,'Send to bank alt',16,201,288,function() A.StartSend() end)
 M.review=W.Button(p,'Review items',16,237,100,function() M.expanded=not M.expanded; M.Refresh(A.plan,A.queue:GetStatus()) end)
 M.options=W.Button(p,'Options',124,237,90,function() A.OpenOptions() end)
 M.stop=W.Button(p,'Stop',222,237,82,function() if A.queue then A.queue:Stop() end end)
 if A.Workflows then
  M.preset=W.Button(p,'',16,64,288,function() A.Workflows.PresetMenu(M.preset) end)
  M.destination=W.Button(p,'',16,64,288,function() A.Workflows.DestinationMenu(M.destination) end)
  M.history=W.Button(p,'History',222,237,82,A.Workflows.ShowHistory)
  M.postage=W.Text(p,'',16,124,285,'GameFontHighlightSmall'); M.postage:SetHeight(20)
 end
 local scroll=CreateFrame('ScrollFrame',nil,p,'UIPanelScrollFrameTemplate'); M.scroll=scroll
 scroll:SetPoint('TOPLEFT',p,'TOPLEFT',16,-274); scroll:SetPoint('BOTTOMRIGHT',p,'BOTTOMRIGHT',-32,16)
 M.reviewContent=CreateFrame('Frame',nil,scroll); M.reviewContent:SetSize(265,230); scroll:SetScrollChild(M.reviewContent)
 M.readyHeader=W.Text(M.reviewContent,'Ready to send',0,0,265,'GameFontNormal')
 M.emptyReview=W.Text(M.reviewContent,'No items are ready to send. Choose materials in Options.',0,26,260); M.emptyReview:SetHeight(36); M.emptyReview:Hide()
 M.skippedHeader=W.Button(M.reviewContent,'Skipped items',0,0,265,function()
  M.showSkipped=not M.showSkipped; M.Refresh(M.reviewPlan or A.plan,A.queue:GetStatus())
 end); M.skippedHeader:Hide()
 scroll:Hide(); p:Hide()
 local compact=CreateFrame('Frame',nil,MailFrame or UIParent,'BackdropTemplate'); M.compact=compact
 compact:SetSize(252,52); compact:SetFrameStrata('DIALOG'); W.Backdrop(compact); draggable(compact)
 local icon=compact:CreateTexture(nil,'ARTWORK'); icon:SetPoint('TOPLEFT',compact,'TOPLEFT',8,-9); icon:SetSize(34,34); icon:SetTexture(A.media..'MiniIcon')
 M.compactSend=W.Button(compact,'Send items',50,10,156,function() A.StartSend() end); M.compactSend:SetHeight(32)
 M.compactExpand=W.Button(compact,'+',214,10,30,function() M.SetCompact(false) end); M.compactExpand:SetHeight(32)
 for _,frame in ipairs({compact,M.compactSend}) do
  frame:SetScript('OnEnter',function(self) self.UpdateTooltip=compactTooltip; compactTooltip(self) end)
  frame:SetScript('OnLeave',tooltipLeave)
  frame:SetScript('OnHide',tooltipLeave)
 end
 M.compactExpand:SetScript('OnEnter',function(self)
  if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); GameTooltip:SetText('Open full Postly window'); GameTooltip:Show() end
 end)
 M.compactExpand:SetScript('OnLeave',tooltipLeave); compact:Hide()
 if MailFrame then
  MailFrame:HookScript('OnHide',function()
   A.CloseMailbox()
  end)
 end
end
function M.SetCompact(value)
 if not A.db or A.db.version~=1 then return false end
 -- Display-only change: leave the active queue, reviewed plan and rules intact.
 A.db.display.compact=value and true or false
 if A.Options and A.Options.compact then A.Options.compact:SetChecked(A.db.display.compact) end
 if A.Client.IsOpen() then M.Show() else M.Hide() end
 return true
end
function M.Show()
 M.Create(); M.panel:Hide(); M.compact:Hide()
 local frame=A.config and A.config.display.compact and M.compact or M.panel
 place(frame); frame:Show(); M.Refresh(A.plan,A.queue and A.queue:GetStatus())
end
function M.Hide()
 if M.panel then M.panel:Hide(); M.compact:Hide() end
end
function M.ExpandReview()
 M.Create(); M.expanded=true; M.compact:Hide(); place(M.panel); M.panel:Show()
end
local rarityFallback={
 [0]={0.62,0.62,0.62},[1]={1,1,1},[2]={0.12,1,0},[3]={0,0.44,0.87},
 [4]={0.64,0.21,0.93},[5]={1,0.5,0},[6]={0.9,0.8,0.5},[7]={0,0.8,1},[8]={0,0.8,1},
}
local function rarityColor(quality)
 local color=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
 if color then return color.r,color.g,color.b end
 return unpack(rarityFallback[quality] or rarityFallback[1])
end
local function showItemTooltip(frame)
 if not GameTooltip or not frame.entry then return end
 local entry=frame.entry
 GameTooltip:SetOwner(frame,'ANCHOR_RIGHT')
 if entry.display.link then GameTooltip:SetHyperlink(entry.display.link) else GameTooltip:SetItemByID(entry.item.itemID) end
 local note=entry.skipped and entry.item.reason or ('Send '..entry.item.send..'  |  Keep '..entry.item.retained)
 GameTooltip:AddLine(note,0.95,0.86,0.66,true); GameTooltip:Show()
end
local function reviewRow(index,item,skipped,y,excluded)
 local row=M.reviewRows[index]; local W=A.Widgets
 if not row then
  row={}; row.frame=CreateFrame('Frame',nil,M.reviewContent,'BackdropTemplate'); row.frame:EnableMouse(true)
  row.frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'})
  row.iconFrame=CreateFrame('Frame',nil,row.frame,'BackdropTemplate'); row.iconFrame:SetPoint('TOPLEFT',row.frame,'TOPLEFT',2,-7); row.iconFrame:SetSize(34,34)
  row.iconFrame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
  row.iconFrame:SetBackdropColor(0,0,0,0.8)
  row.icon=row.iconFrame:CreateTexture(nil,'ARTWORK'); row.icon:SetPoint('TOPLEFT',row.iconFrame,'TOPLEFT',1,-1); row.icon:SetPoint('BOTTOMRIGHT',row.iconFrame,'BOTTOMRIGHT',-1,1); row.icon:SetTexCoord(0.07,0.93,0.07,0.93)
  row.quantity=W.Text(row.iconFrame,'',1,19,30,'NumberFontNormalSmall'); row.quantity:SetJustifyH('RIGHT')
  row.name=W.Text(row.frame,'',44,5,212); row.name:SetHeight(18); row.name:SetWordWrap(false)
  row.send=W.Text(row.frame,'',44,27,98); row.send:SetHeight(17); row.send:SetTextColor(0.55,0.95,0.55)
  row.keep=W.Text(row.frame,'',146,27,112); row.keep:SetHeight(17); row.keep:SetTextColor(unpack(A.Widgets.theme.text))
  row.reason=W.Text(row.frame,'',44,26,212,'GameFontHighlightSmall'); row.reason:SetHeight(32); row.reason:SetTextColor(unpack(A.Widgets.theme.muted))
  row.frame:SetScript('OnEnter',function(self) self:SetBackdropColor(unpack(A.Widgets.theme.hover)); self.UpdateTooltip=showItemTooltip; showItemTooltip(self) end)
  row.frame:SetScript('OnLeave',function(self) self:SetBackdropColor(unpack(A.Widgets.theme.row)); self.UpdateTooltip=nil; if GameTooltip then GameTooltip:Hide() end end)
  row.frame:SetScript('OnHide',function(self) self.UpdateTooltip=nil; if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
  if A.Workflows then
   row.check=CreateFrame('CheckButton',nil,row.frame,'UICheckButtonTemplate'); row.check:SetSize(24,24); row.check:SetPoint('TOPLEFT',row.frame,'TOPLEFT',0,-13)
   row.check:SetScript('OnClick',function() if row.frame.entry then A.ToggleExcluded(row.frame.entry.item.itemID) end end)
   row.iconFrame:ClearAllPoints(); row.iconFrame:SetPoint('TOPLEFT',row.frame,'TOPLEFT',26,-7)
   row.name:ClearAllPoints(); row.name:SetPoint('TOPLEFT',row.frame,'TOPLEFT',68,-5); row.name:SetWidth(164)
   row.send:ClearAllPoints(); row.send:SetPoint('TOPLEFT',row.frame,'TOPLEFT',68,-27); row.send:SetWidth(95)
   row.keep:ClearAllPoints(); row.keep:SetPoint('TOPLEFT',row.frame,'TOPLEFT',166,-27); row.keep:SetWidth(96)
   row.reason:ClearAllPoints(); row.reason:SetPoint('TOPLEFT',row.frame,'TOPLEFT',68,-26); row.reason:SetWidth(164)
   row.actions=W.Button(row.frame,'...',236,4,28,function()
    local entry=row.frame.entry; A.Workflows.ItemMenu(row.actions,entry.item,entry.excluded,entry.skipped)
   end)
  end
  M.reviewRows[index]=row
 end
 local display=A.Client.ItemDisplay(item.itemID)
 row.frame.entry={item=item,display=display,skipped=skipped,excluded=excluded}
 if row.check then
  row.check:SetShown(not skipped); row.check:SetChecked(not excluded); row.check:SetEnabled(not A.queue:Active()); row.actions:SetEnabled(not A.queue:Active())
 end
 row.frame:ClearAllPoints(); row.frame:SetPoint('TOPLEFT',M.reviewContent,'TOPLEFT',0,-y); row.frame:SetSize(265,skipped and 62 or 48)
 row.frame:SetBackdropColor(unpack(A.Widgets.theme.row))
 row.icon:SetTexture(display.icon); row.icon:SetAlpha(skipped and 0.65 or 1)
 local r,g,b=rarityColor(display.quality)
 row.iconFrame:SetBackdropBorderColor(r,g,b,0.85); row.name:SetTextColor(r,g,b); row.name:SetText(display.name)
 local count=skipped and item.count or item.send; row.quantity:SetText(count>1 and tostring(count) or '')
 row.send:SetShown(not skipped); row.keep:SetShown(not skipped); row.reason:SetShown(skipped)
 if skipped then row.reason:SetText(item.reason) else row.send:SetText(excluded and 'Excluded' or 'Send '..item.send); row.keep:SetText('Keep '..item.retained) end
 row.frame:Show()
 if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(row.frame) then showItemTooltip(row.frame) end
 return y+(skipped and 66 or 52)
end
local function review(plan)
 M.reviewPlan=plan
 local items=plan and plan.items or {}; local skipped=plan and plan.skipped or {}; local excluded=plan and plan.excluded or {}
 local heading=A.queue and A.queue:Active() and 'Transfer plan' or 'Ready to send'
 M.readyHeader:SetText(#excluded>0 and (#items..' ready  |  '..#excluded..' excluded this visit') or heading..' ('..#items..')'); M.emptyReview:SetShown(#items==0 and #excluded==0)
 local y,index=24,0
 for _,item in ipairs(items) do index=index+1; y=reviewRow(index,item,false,y) end
 for _,item in ipairs(excluded) do index=index+1; y=reviewRow(index,item,false,y,true) end
 if #items+#excluded==0 then y=66 else y=y-4 end
 M.skippedHeader:SetShown(#skipped>0)
 if #skipped>0 then
  M.skippedHeader:ClearAllPoints(); M.skippedHeader:SetPoint('TOPLEFT',M.reviewContent,'TOPLEFT',0,-(y+8))
  M.skippedHeader:SetText((M.showSkipped and 'Hide skipped (' or 'Show skipped (')..#skipped..')')
  y=y+40
  if M.showSkipped then for _,item in ipairs(skipped) do index=index+1; y=reviewRow(index,item,true,y) end end
 end
 for i=index+1,#M.reviewRows do M.reviewRows[i].frame:Hide() end
 M.reviewContent:SetHeight(math.max(260,y))
end
function M.Refresh(plan,status)
 if not M.panel then return end
 status=status or {state='idle',sentMails=0,remainingUnits=0}
 M.lastPlan=plan
 if status.state=='error' and M.lastQueueState~='error' and M.compact:IsShown() and A.Client.IsOpen() then
  M.compact:Hide(); place(M.panel); M.panel:Show()
 end
 M.lastQueueState=status.state
 local active=A.queue and A.queue:Active()
 local recipient=active and status.recipient or plan and plan.recipient
 M.recipient:SetText('To: '..(recipient and A.Store.RecipientLabel(recipient,A.context.realm) or 'Not configured'))
 local function counted(count,singular,plural) return count..' '..(count==1 and singular or plural) end
 local stacks=plan and plan.totalStacks or 0
 M.summary:SetText(active and (counted(status.sentMails,'mail','mails')..' sent  |  '..status.remainingUnits..' items left') or (stacks==0 and 'Nothing ready to send' or counted(stacks,'stack','stacks')..'  |  '..counted(plan.estimatedMails,'mail','mails')))
 local label,enabled,reason='Send to bank alt',true,nil
 if status.state=='preparing' then label='Preparing attachments...'; enabled=false; reason='Wait for preparation. If needed, click Send prepared mail when ready.'
 elseif status.state=='awaiting-result' then label='Waiting for mail result...'; enabled=false
 elseif status.state=='stopping' then label='Stopping after pending mail...'; enabled=false
 elseif status.state=='ready' then label='Send prepared mail'; reason='Check the recipient and prepared attachments, then click to send.'
 elseif status.state=='awaiting-click' then label='Send next batch'; reason='Each mail requires another click.'
 else
  reason=A.SendDisabledReason(); enabled=reason==nil
  if A.reviewKey then label='Send reviewed items'; reason='Review the list below, then click to send.' end
 end
 M.status:SetText(status.reason or reason or 'Click to send selected items. No gold or COD.')
 M.send:SetText(label); M.send:SetEnabled(enabled); M.stop:SetShown(active and true or false); M.stop:SetEnabled(active and status.state~='stopping')
 local compactLabel=label
 if status.state=='preparing' then compactLabel='Preparing...'
 elseif status.state=='awaiting-result' then compactLabel='Waiting...'
 elseif status.state=='stopping' then compactLabel='Stopping...'
 elseif not active then
  if stacks==0 then compactLabel='Nothing ready'
  elseif not enabled then compactLabel='Not ready'
  elseif A.reviewKey then compactLabel='Send reviewed items'
  elseif A.config and A.config.sending.review then compactLabel='Review items'
  else compactLabel='Send '..counted(stacks,'stack','stacks') end
 end
 M.compactSend:SetText(compactLabel); M.compactSend:SetEnabled(enabled)
 -- Measure unrestricted wrapped text before positioning controls below it.
 local offset=24
 if M.preset then
  local presets=A.Store.ListPresets(A.db,A.context); local showPreset=#presets>0
  M.preset:SetShown(showPreset); M.preset:SetText('Preset: '..(A.config.presetName or 'Default')); M.preset:SetEnabled(not active)
  M.preset:ClearAllPoints(); M.preset:SetPoint('TOPLEFT',M.panel,'TOPLEFT',16,-88)
  if showPreset then offset=offset+30 end
  local showDestination=#(A.plans or {})>1
  M.destination:SetShown(showDestination); M.destination:SetText('Destination: '..(recipient or 'Choose bank alt')); M.destination:SetEnabled(not active)
  M.destination:ClearAllPoints(); M.destination:SetPoint('TOPLEFT',M.panel,'TOPLEFT',16,-(64+offset))
  if showDestination then offset=offset+30 end
  M.recipient:ClearAllPoints(); M.recipient:SetPoint('TOPLEFT',M.panel,'TOPLEFT',16,-(68+offset))
  M.summary:ClearAllPoints(); M.summary:SetPoint('TOPLEFT',M.panel,'TOPLEFT',16,-(100+offset))
  local showPostage=A.config.sending.postage~=false and ((plan and plan.totalStacks or 0)>0 or active)
  M.postage:SetShown(showPostage); M.postage:ClearAllPoints(); M.postage:SetPoint('TOPLEFT',M.panel,'TOPLEFT',16,-(124+offset))
  if showPostage then
   local prepared=active and (status.state=='ready' or status.state=='awaiting-result' or status.state=='stopping')
   local price
   if prepared and status.state~='ready' then price=A.queue.historyRecord and A.queue.historyRecord.postage
   elseif prepared and A.Client.Postage then price=A.Client.Postage()
   elseif not active and A.Client.EstimatePostage then price=A.Client.EstimatePostage(plan) end
   M.postage:SetText((prepared and 'This mail: ' or 'Estimated postage: ')..A.History.Money(price)); offset=offset+24
  end
  M.history:SetShown(not active)
 end
 M.status:ClearAllPoints(); M.status:SetPoint('TOPLEFT',M.panel,'TOPLEFT',16,-(128+offset)); M.status:SetHeight(0)
 local statusHeight=math.max(28,M.status.GetStringHeight and M.status:GetStringHeight() or 36)
 M.status:SetHeight(statusHeight)
 local sendY=128+offset+statusHeight+12; local footerY=sendY+34; local reviewY=footerY+36
 local function position(frame,x,y,width)
  frame:ClearAllPoints(); frame:SetPoint('TOPLEFT',M.panel,'TOPLEFT',x,-y); frame:SetWidth(width)
 end
 position(M.send,16,sendY,288)
 position(M.review,16,footerY,(active or M.history) and 100 or 140)
 position(M.options,(active or M.history) and 124 or 164,footerY,(active or M.history) and 90 or 140)
 position(M.stop,222,footerY,82)
 if M.history then position(M.history,222,footerY,82) end
 M.scroll:ClearAllPoints(); M.scroll:SetPoint('TOPLEFT',M.panel,'TOPLEFT',16,-reviewY); M.scroll:SetPoint('BOTTOMRIGHT',M.panel,'BOTTOMRIGHT',-32,16)
 M.panel:SetHeight(M.expanded and reviewY+281+16 or footerY+24+16); M.scroll:SetShown(M.expanded)
 M.review:SetText(M.expanded and 'Hide review' or 'Review items')
 if M.expanded and M.panel:IsShown() then review(plan) end
end
