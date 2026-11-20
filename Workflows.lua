local _,A=...
local F={controls={},menuRows={},historyRows={},historyExpanded={}}; A.Workflows=F
local function change(fn)
 local ok,why=A.EditSettings(fn); A.Options.Report(ok,why); return ok
end
local function control(widget,edit) F.controls[#F.controls+1]={widget=widget,edit=edit}; return widget end
local function button(parent,label,x,y,width,fn) return control(A.Widgets.Button(parent,label,x,y,width,fn)) end
local function closeButton(parent)
 local close=CreateFrame('Button',nil,parent,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',parent,'TOPRIGHT',-3,-3); close:SetScript('OnClick',function() parent:Hide() end)
end
function F.Menu(anchor,choices)
 local W=A.Widgets
 if not F.menu then
  local p=CreateFrame('Frame',nil,UIParent,'BackdropTemplate'); F.menu=p; p:SetFrameStrata('TOOLTIP'); p:SetClampedToScreen(true); W.Backdrop(p); closeButton(p)
  local scroll=CreateFrame('ScrollFrame',nil,p,'UIPanelScrollFrameTemplate'); scroll:SetPoint('TOPLEFT',p,'TOPLEFT',12,-30); scroll:SetPoint('BOTTOMRIGHT',p,'BOTTOMRIGHT',-30,12)
  F.menuContent=CreateFrame('Frame',nil,scroll); F.menuContent:SetWidth(240); scroll:SetScrollChild(F.menuContent); F.menuScroll=scroll
 end
 F.menu:ClearAllPoints(); F.menu:SetPoint('TOPLEFT',anchor,'BOTTOMLEFT',0,-2); F.menu:SetSize(282,math.min(330,42+#choices*28))
 for i,choice in ipairs(choices) do
  local row=F.menuRows[i]
  if not row then row=W.Button(F.menuContent,'',0,(i-1)*28,240,function() end); F.menuRows[i]=row end
  local action=choice.action; row:SetText(choice.label); row:SetEnabled(choice.enabled~=false)
  row:SetScript('OnClick',function() F.menu:Hide(); if action then action() end end); row:Show()
 end
 for i=#choices+1,#F.menuRows do F.menuRows[i]:Hide() end
 F.menuContent:SetHeight(#choices*28); F.menuScroll:SetVerticalScroll(0); F.menu:Show()
end
function F.PresetMenu(anchor)
 local choices={{label='Default',action=function() A.SelectPreset(nil) end}}
 for _,p in ipairs(A.Store.ListPresets(A.db,A.context)) do
  local id=p.id; choices[#choices+1]={label=p.name,action=function() A.SelectPreset(id) end}
 end
 F.Menu(anchor,choices)
end
function F.DestinationMenu(anchor)
 local choices={}
 for _,p in ipairs(A.plans or {}) do
  local recipient=p.recipient; choices[#choices+1]={label=(recipient or 'Choose bank alt')..' ('..p.totalStacks..' stacks)',action=function() A.SelectDestination(recipient) end}
 end
 F.Menu(anchor,choices)
end
function F.Destination(kind,key)
 if A.queue and A.queue:Active() then return end
 local W=A.Widgets
 if not F.destination then
  local p=CreateFrame('Frame',nil,UIParent,'BackdropTemplate'); F.destination=p; p:SetSize(420,260); p:SetPoint('CENTER'); p:SetFrameStrata('DIALOG'); p:SetClampedToScreen(true); W.Backdrop(p); closeButton(p)
  F.destinationTitle=W.Text(p,'Destination',16,18,370,'GameFontNormalLarge')
  W.Text(p,'Full character name (First name Surname)',16,55,380)
  F.destinationName=control(W.Edit(p,20,79,282,64),true)
  button(p,'Choose',311,79,90,function()
   local choices={}
   for guid,char in pairs(A.db.characters) do
    if guid~=A.context.characterID and char.contextKey==A.Store.ScopeKey(A.context) then
     local name=A.Store.Normalize(char.name,char.realm); choices[#choices+1]={label=name,action=function() F.destinationName:SetText(name) end}
    end
   end
   table.sort(choices,function(a,b) return a.label<b.label end)
   if #choices==0 then choices={{label='No other characters recorded',enabled=false}} end
   F.Menu(F.destinationName,choices)
  end)
  local function saveDestination()
   local ok,why=A.EditSettings(function() return A.Store.SetDestination(A.db,A.context,F.destinationKind,F.destinationKey,F.destinationName:GetText()) end)
   A.Options.Report(ok,why)
   if ok then p:Hide() else F.destinationStatus:SetText(why or 'Could not save destination.') end
  end
  F.destinationSave=button(p,'Save destination',16,119,160,saveDestination)
  F.destinationName:SetScript('OnEnterPressed',saveDestination)
  button(p,'Use default destination',186,119,210,function()
   if change(function() return A.Store.SetDestination(A.db,A.context,F.destinationKind,F.destinationKey,nil) end) then p:Hide() end
  end)
  F.destinationHint=W.Text(p,'',16,159,380,'GameFontHighlightSmall'); F.destinationHint:SetHeight(45)
  F.destinationStatus=W.Text(p,'',16,213,380,'GameFontHighlightSmall'); F.destinationStatus:SetHeight(32); F.destinationStatus:SetTextColor(1,0.4,0.3)
 end
 F.destinationKind=kind; F.destinationKey=key
 local routes=A.config.routes or {}; local value=(kind=='item' and routes.items or routes.categories or {})[key]
 local label=tostring(key)
 if kind=='category' then for _,category in ipairs(A.Categories.list) do if category[1]==key then label=category[2] end end else label=A.Client.ItemName and A.Client.ItemName(key) or 'Item '..key end
 F.destinationTitle:SetText('Send '..label..' to:'); F.destinationName:SetText(value or '')
 F.destinationStatus:SetText('')
 F.destinationHint:SetText('Blank uses '..(kind=='item' and 'the material destination, then your bank alt.' or 'your bank alt.')..' Only selected items are sent.\nItem destinations override material destinations.')
 F.destination:Show()
end
function F.ItemMenu(anchor,item,excluded,skipped)
 local locked=A.queue and A.queue:Active(); local choices={}
 if not skipped then choices[#choices+1]={label=excluded and 'Include this time' or 'Exclude this time',enabled=not locked,action=function() A.ToggleExcluded(item.itemID) end} end
 choices[#choices+1]={label='Always send this item',enabled=not locked,action=function() A.QuickRule(item.itemID,'always') end}
 choices[#choices+1]={label='Never send this item',enabled=not locked,action=function() A.QuickRule(item.itemID,'never') end}
 choices[#choices+1]={label='Set item destination...',enabled=not locked,action=function() F.Destination('item',item.itemID) end}
 choices[#choices+1]={label='Edit item rule...',enabled=not locked,action=function() F.EditRule(item.itemID) end}
 if item.category then choices[#choices+1]={label='Edit material settings...',enabled=not locked,action=function() F.EditRule(nil,item.category) end} end
 F.Menu(anchor,choices)
end
function F.EditRule(id,category)
 A.Options.Open(id and 'items' or 'materials')
 if id then A.Options.EditItem(id) elseif category then A.Options.ShowMaterial(category) end
end
function F.BuildOptions(body,sending)
 local W=A.Widgets
 W.Text(body,'Mailing preset',0,0,600,'GameFontNormalLarge')
 F.preset=button(body,'Default',0,30,245,function() F.PresetMenu(F.preset) end)
 W.Text(body,'New name / rename',265,8,200,'GameFontHighlightSmall')
 F.presetName=control(W.Edit(body,265,30,200,48),true)
 F.createPreset=button(body,'Create copy',480,30,120,function()
  change(function()
   local ok,id=A.Store.CreatePreset(A.db,A.context,F.presetName:GetText()); if ok then A.selectedRecipient=nil end; return ok,id
  end)
 end)
 F.renamePreset=button(body,'Rename',265,64,100,function() change(function() return A.Store.RenamePreset(A.db,A.context,A.config.presetID,F.presetName:GetText()) end) end)
 F.deletePreset=button(body,'Delete preset',375,64,120,function()
  local id=A.config.presetID
  if not id then A.Options.Report(false,'Select a saved preset first.'); return end
  if F.confirmDelete~=id then F.confirmDelete=id; F.deletePreset:SetText('Confirm delete'); return end
  F.confirmDelete=nil; F.deletePreset:SetText('Delete preset')
  change(function() return A.Store.DeletePreset(A.db,A.context,id) end)
 end)
 W.Text(body,'Presets save recipient, materials, item rules, destinations and subject.\nDefault keeps your existing settings. Type a name and Create copy to start.',0,103,600,'GameFontHighlightSmall')
 F.postage=control(CreateFrame('CheckButton',nil,sending,'UICheckButtonTemplate')); F.postage:SetPoint('TOPLEFT',sending,'TOPLEFT',0,-255); F.postage:SetSize(26,26)
 W.Text(sending,'Show postage preview in the mailbox',30,261,620)
 F.postage:SetScript('OnClick',function(self) change(function() A.db.sending.postage=self:GetChecked() and true or false; return true end) end)
end
function F.RefreshOptions()
 if not F.preset or not A.config then return end
 F.preset:SetText(A.config.presetName or 'Default'); F.postage:SetChecked(A.config.sending.postage~=false)
 if F.deletePreset and F.confirmDelete and F.confirmDelete~=A.config.presetID then F.confirmDelete=nil; F.deletePreset:SetText('Delete preset') end
 F.Lock()
end
function F.Lock()
 local locked=A.db.version~=1 or A.queue and A.queue:Active()
 for _,entry in ipairs(F.controls) do
  local widget=entry.widget
  if entry.edit then widget:EnableMouse(not locked); widget:EnableKeyboard(not locked); if locked then widget:ClearFocus() end
  else widget:SetEnabled(not locked) end
 end
 for _,widget in ipairs(A.Options.defaultControls or {}) do widget:SetEnabled(not locked and not A.config.presetID) end
 if F.renamePreset then F.renamePreset:SetEnabled(not locked and A.config.presetID~=nil); F.deletePreset:SetEnabled(not locked and A.config.presetID~=nil) end
 if F.historyClear then F.historyClear:SetEnabled(not locked) end
end
local outcomes={all='All outcomes',accepted='Accepted by client',failed='Failed',blocked='Blocked',uncertain='Uncertain',pending='Pending'}
function F.ShowHistory(embedded)
 if not embedded then A.Options.Open('history'); return end
 local W=A.Widgets
 if not F.history then
  local p=CreateFrame('Frame',nil,A.Options.pages.history); F.history=p; p:SetSize(752,480); p:SetPoint('TOPLEFT')
  W.Text(p,'Mail history',0,0,700,'GameFontNormalLarge')
  W.Text(p,'Search sender, recipient, subject, preset, item or ID',0,30,720,'GameFontHighlightSmall')
  F.historySearch=W.Edit(p,5,55,425,120); F.historySearch:SetScript('OnTextChanged',function() if F.historyScroll then F.historyScroll:SetVerticalScroll(0) end; F.RefreshHistory() end)
  F.historyFilter=W.Button(p,'All outcomes',450,55,270,function()
   local choices={}
   for _,value in ipairs({'all','accepted','failed','blocked','uncertain','pending'}) do
    local selected=value; choices[#choices+1]={label=outcomes[value],action=function() F.outcome=selected; F.historyFilter:SetText(outcomes[selected]); F.historyScroll:SetVerticalScroll(0); F.RefreshHistory() end}
   end
   F.Menu(F.historyFilter,choices)
  end)
  local scroll=CreateFrame('ScrollFrame',nil,p,'UIPanelScrollFrameTemplate'); F.historyScroll=scroll; scroll:SetPoint('TOPLEFT',p,'TOPLEFT',0,-97); scroll:SetPoint('BOTTOMRIGHT',p,'BOTTOMRIGHT',-28,70)
  F.historyContent=CreateFrame('Frame',nil,scroll); F.historyContent:SetWidth(700); scroll:SetScrollChild(F.historyContent)
  F.historyEmpty=W.Text(F.historyContent,'No matching mail. Only messages sent by Postly are recorded.',0,0,700); F.historyEmpty:SetHeight(40)
  F.historyCount=W.Text(p,'',0,423,500,'GameFontHighlightSmall')
  F.historyClear=W.Button(p,'Clear history',560,415,160,function()
   if A.queue:Active() or A.db.version~=1 then return end
   if not F.confirmClear then F.confirmClear=true; F.historyClear:SetText('Confirm clear'); return end
   A.History.Clear(); F.confirmClear=nil; F.historyClear:SetText('Clear history'); F.RefreshHistory()
  end)
  W.Text(p,'Accepted confirms sending, not delivery. Latest 500 messages retained locally.',0,460,740,'GameFontHighlightSmall')
  p:SetScript('OnHide',function() F.confirmClear=nil; F.historyClear:SetText('Clear history') end)
 end
 F.history:Show(); F.RefreshHistory(); F.Lock()
end
function F.RefreshHistory()
 if not F.history or not F.history:IsVisible() then return end
 local W=A.Widgets; local H=A.History
 local matches=H.Search(F.historySearch:GetText(),F.outcome or 'all'); F.historyMatches=matches
 F.historyCount:SetText(#matches..' matching messages. Click a message for details.'); F.historyEmpty:SetShown(#matches==0)
 local y=0
 for i,record in ipairs(matches) do
  local row=F.historyRows[i]
  if not row then
   row={}; F.historyRows[i]=row; row.header=W.Button(F.historyContent,'',0,0,700,function() end)
   row.details=CreateFrame('Frame',nil,F.historyContent); row.details:SetWidth(700)
   row.text=W.Text(row.details,'',8,8,684,'GameFontHighlightSmall'); row.text:SetJustifyV('TOP'); row.itemRows={}
  end
  row.header:ClearAllPoints(); row.header:SetPoint('TOPLEFT',F.historyContent,'TOPLEFT',0,-y); row.header:SetHeight(48)
  local id=record.id
  row.header:SetText(H.When(record.submittedAt)..'  |  '..(record.recipient or '?')..'\n'..(outcomes[record.outcome] or record.outcome)..'  |  '..(record.totalUnits or 0)..' items  |  '..H.Money(record.postage))
  row.header:SetScript('OnClick',function() F.historyExpanded[id]=not F.historyExpanded[id]; F.RefreshHistory() end); row.header:Show(); y=y+52
  local expanded=F.historyExpanded[id]; row.details:SetShown(expanded)
  if expanded then
   row.details:ClearAllPoints(); row.details:SetPoint('TOPLEFT',F.historyContent,'TOPLEFT',0,-y)
   row.text:SetText('From: '..(record.sender or '?')..'  →  '..(record.recipient or '?')..'\nSubject: '..(record.subject or '')..'\nPreset: '..(record.preset or 'Default')..'  |  Message #'..record.id..'\nSubmitted: '..H.When(record.submittedAt)..'\nResult: '..H.When(record.finishedAt)..'  |  '..(outcomes[record.outcome] or record.outcome)..'\n'..(record.reason or 'Waiting for a confirmed result.')..'\nPostage: '..H.Money(record.postage)..'  |  '..(record.totalStacks or 0)..' attachments')
   row.text:SetHeight(0); local detailY=math.max(148,row.text.GetStringHeight and row.text:GetStringHeight()+16 or 164); row.text:SetHeight(detailY-8)
   for j,item in ipairs(record.items or {}) do
    local ir=row.itemRows[j]
    if not ir then
     ir=CreateFrame('Button',nil,row.details); row.itemRows[j]=ir; ir:SetSize(680,30)
     ir.icon=ir:CreateTexture(nil,'ARTWORK'); ir.icon:SetSize(24,24); ir.icon:SetPoint('TOPLEFT',ir,'TOPLEFT',0,0)
     ir.text=W.Text(ir,'',32,2,640,'GameFontHighlightSmall')
    end
    ir:ClearAllPoints(); ir:SetPoint('TOPLEFT',row.details,'TOPLEFT',8,-detailY)
    ir.icon:SetTexture(item.icon or 'Interface\\Icons\\INV_Misc_QuestionMark'); ir.text:SetText(item.count..' × '..(item.name or 'Item '..item.itemID)..'  [ID '..item.itemID..']')
    local link=item.link or item.identity
    ir:SetScript('OnEnter',function(self) if GameTooltip and link then GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); GameTooltip:SetHyperlink(link); GameTooltip:Show() end end)
    ir:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end); ir:Show(); detailY=detailY+32
   end
   for j=#(record.items or {})+1,#row.itemRows do row.itemRows[j]:Hide() end
   row.details:SetHeight(detailY+8); y=y+detailY+12
  end
 end
 for i=#matches+1,#F.historyRows do F.historyRows[i].header:Hide(); F.historyRows[i].details:Hide() end
 F.historyContent:SetHeight(math.max(60,y))
end
function F.CloseMailbox()
 for _,p in pairs({F.menu,F.destination}) do p:Hide() end
end
