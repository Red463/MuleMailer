local _,A=...
local O={controls={},categories={},itemRows={}}
A.Options=O
local W={}; A.Widgets=W
-- Shared warm-stone palette follows Gatherly's native WoW skin.
W.theme={panel={0.19,0.18,0.16,1},field={0.15,0.145,0.13,1},edge={0.52,0.48,0.40,1},text={0.94,0.88,0.75},muted={0.72,0.67,0.57},gold={1,0.82,0.35},row={0.15,0.145,0.13,1},hover={0.30,0.24,0.16,1}}
function W.Text(parent,value,x,y,width,font)
 local f=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlight')
 f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y); f:SetWidth(width); f:SetJustifyH('LEFT'); f:SetWordWrap(true); f:SetText(value)
 f:SetTextColor(unpack(font and font:find('Normal') and W.theme.gold or W.theme.text)); f:SetShadowColor(0,0,0,1); f:SetShadowOffset(1,-1)
 return f
end
function W.Button(parent,label,x,y,width,action)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate'); b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y); b:SetSize(width,24); b:SetText(label)
 b:SetNormalFontObject('GameFontNormal'); b:SetHighlightFontObject('GameFontHighlight'); b:SetDisabledFontObject('GameFontDisable')
 b:SetScript('OnClick',action); return b
end
function W.Edit(parent,x,y,width,max)
 local e=CreateFrame('EditBox',nil,parent,'BackdropTemplate'); e:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y); e:SetSize(width,24); e:SetAutoFocus(false); e:SetMaxLetters(max or 64)
 e:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
 e:SetBackdropColor(unpack(W.theme.field)); e:SetBackdropBorderColor(unpack(W.theme.edge))
 e:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',13,''); e:SetTextColor(unpack(W.theme.text)); e:SetTextInsets(10,10,0,0)
 e:HookScript('OnEditFocusGained',function(self) self:SetBackdropBorderColor(unpack(W.theme.gold)) end)
 e:HookScript('OnEditFocusLost',function(self) self:SetBackdropBorderColor(unpack(W.theme.edge)) end)
 e:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 return e
end
function W.Backdrop(frame)
 frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
 frame:SetBackdropColor(unpack(W.theme.panel)); frame:SetBackdropBorderColor(unpack(W.theme.edge))
end
function W.Window(frame)
 -- Native portrait chrome matches Gatherly; preserve Postly's own emblem.
 local base=frame:CreateTexture(nil,'BACKGROUND',nil,-8); base:SetAllPoints(); base:SetColorTexture(0.045,0.038,0.03,1); frame.opaqueBase=base
 if frame.SetTitle then frame:SetTitle('Postly v'..A.version) end
 if frame.Bg and frame.Bg.SetVertexColor then frame.Bg:SetVertexColor(0.85,0.85,0.85,1) end
 local container=frame.PortraitContainer or frame
 local portrait=frame.portrait or container.portrait or frame:CreateTexture(nil,'ARTWORK')
 portrait:ClearAllPoints(); portrait:SetPoint('CENTER',container,'TOPLEFT',26,-24); portrait:SetSize(58,58); portrait:SetTexture(A.media..'Icon'); portrait:SetTexCoord(0,1,0,1)
 if container.CircleMask then container.CircleMask:ClearAllPoints(); container.CircleMask:SetAllPoints(portrait) end
 frame.brandPortrait=portrait
end
function W.Tab(parent,label,x,y,width,action)
 W.tabCount=(W.tabCount or 0)+1
 local ok,b=pcall(CreateFrame,'Button','PostlySettingsTab'..W.tabCount,parent,'PanelTopTabButtonTemplate')
 local native=ok and b and b.Text and b.Left and b.Middle and b.Right and b.LeftActive and b.MiddleActive and b.RightActive
 if not native then if ok and b then b:Hide() end; b=W.Button(parent,label,x,y,width,action)
 else
  b:SetText(label); b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y); b:SetSize(width,28); b:SetScript('OnClick',action)
  if PanelTemplates_TabResize then PanelTemplates_TabResize(b,0,width) end
 end
 b.nativeTab=native and true or false; return b
end
function W.SelectTab(tab,selected)
 tab.selected=selected and true or false
 if tab.nativeTab then
  if selected and PanelTemplates_SelectTab then PanelTemplates_SelectTab(tab)
  elseif not selected and PanelTemplates_DeselectTab then PanelTemplates_DeselectTab(tab) end
  if tab.Text then tab.Text:SetTextColor(unpack(selected and W.theme.text or W.theme.gold)) end
 else tab:SetNormalFontObject(selected and 'GameFontHighlight' or 'GameFontNormal') end
end
local function track(control,edit)
 O.controls[#O.controls+1]={control=control,edit=edit}; return control
end
local function button(parent,label,x,y,width,action) return track(W.Button(parent,label,x,y,width,action)) end
local function edit(parent,x,y,width,max) return track(W.Edit(parent,x,y,width,max),true) end
local function check(parent,label,x,y,action)
 local b=track(CreateFrame('CheckButton',nil,parent,'UICheckButtonTemplate'))
 b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y); b:SetSize(26,26)
 b.label=W.Text(parent,label,x+30,y+6,420)
 b:SetScript('OnClick',function(self) action(self:GetChecked() and true or false) end)
 return b
end
function O.Report(ok,why)
 if O.status then O.status:SetText(ok and 'Saved.' or (why or 'Could not save this setting.')); O.status:SetTextColor(ok and 0.65 or 1,ok and 0.9 or 0.4,ok and 0.65 or 0.3) end
end
local function change(fn) local ok,why=A.EditSettings(fn); O.Report(ok,why); return ok end
local function pref(group,key,value)
 return change(function() A.db[group][key]=value; return true end)
end
local function commit(e,fn)
 local function save(self) fn(self:GetText()) end
 e:SetScript('OnEnterPressed',function(self) self.skipFocusCommit=true; save(self); self:ClearFocus(); self.skipFocusCommit=nil end)
 e:SetScript('OnEditFocusLost',function(self) self:SetBackdropBorderColor(unpack(W.theme.edge)); if not self.skipFocusCommit then save(self) end end)
 e:SetScript('OnEscapePressed',function(self) self.skipFocusCommit=true; O.Refresh(); self:ClearFocus(); self.skipFocusCommit=nil end)
end
function O.RefreshLock()
 if not O.panel then return end
 local locked=A.db.version~=1 or A.queue and A.queue:Active()
 for _,entry in ipairs(O.controls) do
  local c=entry.control
  if entry.edit then c:EnableMouse(not locked); c:EnableKeyboard(not locked); if locked then c:ClearFocus() end
  else c:SetEnabled(not locked) end
 end
 if locked then O.status:SetText('Settings are locked during a transfer or for an unsupported saved-data version.') end
 if A.Workflows then A.Workflows.Lock() end
end
local modeLabels={always='Always send',never='Never send',inherit='Use material selection'}
local function itemName(id) return A.Client.ItemName and A.Client.ItemName(id) or 'Item '..id end
local function tip(widget,id)
 widget:SetScript('OnEnter',function(self) if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); GameTooltip:SetItemByID(id); GameTooltip:Show() end end)
 widget:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
end
local function bankLabel(address) return A.Store.BankLabel(A.db,A.context,address) end
function O.BankMenu(anchor,action,inherit)
 local choices={}
 if inherit then choices[#choices+1]={label='Use default destination',action=function() action(nil) end} end
 for _,b in ipairs(A.Store.ListBanks(A.db,A.context)) do
  local address=b.recipient
  choices[#choices+1]={label=b.name,action=function() action(address) end,enabled=not A.Store.IsSelf(address,A.context)}
 end
 if #choices==0 then choices={{label='Add a bank alt on the Bank alts tab',enabled=false}} end
 if A.Workflows then A.Workflows.Menu(anchor,choices) end
end
function O.DestinationMenu(anchor,kind,key)
 if A.queue and A.queue:Active() then return end
 O.BankMenu(anchor,function(address) change(function() return A.Store.SetDestination(A.db,A.context,kind,key,address) end) end,true)
end
function O.EditItem(id)
 local rule=A.config.rules.items[id]
 O.ShowTab('items'); O.itemID:SetText(tostring(id)); O.itemKeep:SetText(rule and rule.keep~=nil and tostring(rule.keep) or '')
 O.itemMode=rule and rule.mode or 'always'; O.mode:SetText(modeLabels[O.itemMode])
 O.itemDestination:SetText(bankLabel(A.config.routes and A.config.routes.items[id])..'  v')
end
local function iconControl(row,x)
 row.iconFrame=CreateFrame('Button',nil,row.frame); row.iconFrame:SetSize(32,32); row.iconFrame:SetPoint('TOPLEFT',row.frame,'TOPLEFT',x,-6)
 row.icon=row.iconFrame:CreateTexture(nil,'ARTWORK'); row.icon:SetAllPoints(); row.icon:SetTexCoord(0.07,0.93,0.07,0.93)
end
local function itemVisual(row,id)
 local display=A.Client.ItemDisplay and A.Client.ItemDisplay(id)
 row.name=display and display.name or itemName(id)
 row.icon:SetTexture(display and display.icon or 'Interface\\Icons\\INV_Misc_QuestionMark')
 tip(row.iconFrame,id)
end
local function filterRows(rows,search,content,empty,step,emptyText)
 local query=(search and search:GetText() or ''):match('^%s*(.-)%s*$'):lower()
 local count,total=0,0
 for _,row in ipairs(rows) do
  if row.active then
   total=total+1
   local matches=query=='' or tostring(row.itemID):find(query,1,true) or (row.name or ''):lower():find(query,1,true)
   -- Cache replies may change a loading name. Keep its active editor intact.
   local editing=row.keep and row.keep.HasFocus and row.keep:HasFocus()
   row.frame:SetShown(matches or editing)
   if matches or editing then row.frame:ClearAllPoints(); row.frame:SetPoint('TOPLEFT',content,'TOPLEFT',0,-count*step); count=count+1 end
  else row.frame:Hide() end
 end
 content:SetHeight(math.max(100,count*step)); empty:SetText(total==0 and emptyText or 'No items match your search.'); empty:SetShown(count==0)
end
function O.FilterItems()
 if O.itemContent then filterRows(O.itemRows,O.itemSearch,O.itemContent,O.emptyItems,54,'No individual item rules yet.') end
end
function O.FilterMaterial()
 if O.materialContent then filterRows(O.materialRows,O.materialSearch,O.materialContent,O.materialEmpty,50,'No known items in this material category yet.') end
end
function O.RefreshItems(labelsOnly)
 if labelsOnly then
  -- Item-data events must never hide controls or replace an unfinished edit.
  for _,row in ipairs(O.itemRows) do
   local rule=A.config.rules.items[row.itemID]
   if rule and row.active then itemVisual(row,row.itemID); row.label:SetText(row.name..' ['..row.itemID..']\n'..(modeLabels[rule.mode] or rule.mode)..' | Keep: '..(rule.keep~=nil and tostring(rule.keep) or 'material default')) end
  end
  if O.material and O.material:IsVisible() then
   for _,row in ipairs(O.materialRows) do
    local rule=A.config.rules.items[row.itemID]
    if row.active then itemVisual(row,row.itemID); row.label:SetText(row.name..' ['..row.itemID..']\n'..(rule and modeLabels[rule.mode] or 'Use material selection')) end
   end
   O.FilterMaterial()
  end
  O.FilterItems()
  return
 end
 if not O.itemContent or not A.config then return end
 local ids={}; for id in pairs(A.config.rules.items) do ids[#ids+1]=id end; table.sort(ids)
 for _,row in ipairs(O.itemRows) do row.active=false; row.frame:Hide() end
 for i,id in ipairs(ids) do
  local row=O.itemRows[i]
  if not row then
   row={}; row.frame=CreateFrame('Frame',nil,O.itemContent); row.frame:SetSize(730,52); row.frame:SetPoint('TOPLEFT',O.itemContent,'TOPLEFT',0,-(i-1)*54)
   row.select=button(row.frame,'Edit',0,10,48,function() end)
   iconControl(row,58)
   row.label=W.Text(row.frame,'',100,4,308,'GameFontHighlightSmall')
   row.destination=button(row.frame,'',420,10,190,function() end)
   row.remove=button(row.frame,'Remove',620,10,90,function() end); O.itemRows[i]=row
  end
  local itemID=id; local rule=A.config.rules.items[id]; row.itemID=id; row.active=true; itemVisual(row,id)
  row.label:SetText(row.name..' ['..id..']\n'..(modeLabels[rule.mode] or rule.mode)..' | Keep: '..(rule.keep~=nil and tostring(rule.keep) or 'material default'))
  row.destination:SetText(bankLabel(A.config.routes and A.config.routes.items[id])..'  v')
  row.destination:SetScript('OnClick',function() O.DestinationMenu(row.destination,'item',itemID) end)
  row.select:SetScript('OnClick',function() O.EditItem(itemID) end); tip(row.select,itemID)
  row.remove:SetScript('OnClick',function() change(function() return A.Store.SetRule(A.db,A.context,'item',itemID,nil) end) end)
  row.frame:Show()
 end
 O.FilterItems()
 if O.material and O.material:IsShown() then O.RefreshMaterial() end
 O.RefreshLock()
end
function O.RefreshBanks()
 if not O.bankContent then return end
 local banks=A.Store.ListBanks(A.db,A.context)
 for _,row in ipairs(O.bankRows) do row.frame:Hide() end
 for i,b in ipairs(banks) do
  local bank=b; local row=O.bankRows[i]
  if not row then
   row={}; row.frame=CreateFrame('Frame',nil,O.bankContent); row.frame:SetSize(720,45); row.frame:SetPoint('TOPLEFT',O.bankContent,'TOPLEFT',0,-(i-1)*47)
   row.label=W.Text(row.frame,'',0,4,400)
   row.select=button(row.frame,'Edit',430,4,80,function() end)
   row.remove=button(row.frame,'Delete',525,4,80,function() end); O.bankRows[i]=row
  end
  row.label:SetText(bank.name..'\n'..bank.recipient)
  row.select:SetScript('OnClick',function() O.bankID=bank.id; O.bankFriendly:SetText(bank.name); O.bankCharacter:SetText(bank.recipient); O.bankSave:SetText('Save changes') end)
  row.remove:SetScript('OnClick',function()
   if change(function() return A.Store.DeleteBank(A.db,A.context,bank.id) end) and O.bankID==bank.id then O.NewBank() end
  end); row.frame:Show()
 end
 O.bankContent:SetHeight(math.max(80,#banks*47)); O.contents.banks:SetHeight(350+math.max(80,#banks*47))
 O.emptyBanks:SetShown(#banks==0)
 O.defaultBank:SetText((A.config.recipient and bankLabel(A.config.recipient) or 'Choose a bank alt')..'  v')
end
function O.NewBank()
 O.bankID=nil; O.bankFriendly:SetText(''); O.bankCharacter:SetText(''); O.bankSave:SetText('Add bank alt')
end
function O.Refresh()
 if not O.panel or not A.context then return end
 local cfg=A.Store.Resolve(A.db,A.context)
 O.source:SetText('Rules: '..cfg.ruleSource..' | Recipient: '..(cfg.recipientSource or 'Unavailable'))
 O.recipient:SetText(A.Store.RecipientLabel(cfg.recipient))
 O.pendingOverride=cfg.recipientSource=='Character'; O.override:SetChecked(O.pendingOverride)
 for key,row in pairs(O.categories) do
  local v=cfg.rules.categories[key] or {enabled=false,keep=0}; row.check:SetChecked(v.enabled); row.keep:SetText(tostring(v.keep))
  row.destination:SetText(bankLabel(cfg.routes and cfg.routes.categories[key])..'  v')
 end
 O.autoShow:SetChecked(cfg.display.autoShow~=false); O.compact:SetChecked(cfg.display.compact)
 O.review:SetChecked(cfg.sending.review); O.completion:SetChecked(cfg.sending.completion~=false); O.subject:SetText(cfg.sending.subject or 'Postly')
 local id=tonumber(O.itemID:GetText()); O.itemDestination:SetText(bankLabel(cfg.routes and cfg.routes.items[id])..'  v')
 if cfg.error or cfg.warning then O.status:SetText(cfg.error or cfg.warning) end
 O.RefreshBanks(); O.RefreshItems(); O.RefreshLock()
 if A.Workflows then A.Workflows.RefreshOptions() end
end
local function picker(anchor)
 if O.picker then O.picker:Hide() end
 local p=CreateFrame('Frame',nil,O.panel,'BackdropTemplate'); O.picker=p
 p:SetSize(340,260); p:SetPoint('TOPLEFT',anchor,'BOTTOMLEFT',0,-2); p:SetFrameStrata('DIALOG'); W.Backdrop(p)
 W.Text(p,'Choose a recorded character',12,12,300)
 W.Button(p,'Close',240,226,80,function() p:Hide() end)
 local scroll=CreateFrame('ScrollFrame',nil,p,'UIPanelScrollFrameTemplate'); scroll:SetPoint('TOPLEFT',p,'TOPLEFT',12,-40); scroll:SetPoint('BOTTOMRIGHT',p,'BOTTOMRIGHT',-30,42)
 local child=CreateFrame('Frame',nil,scroll); child:SetSize(290,150); scroll:SetScrollChild(child)
 local choices={}
 for _,char in pairs(A.db.characters or {}) do if char.contextKey==A.Store.ScopeKey(A.context) then choices[#choices+1]=char end end
 table.sort(choices,function(a,b) return a.name<b.name end)
 for i,char in ipairs(choices) do
  local recipient=A.Store.Normalize(char.name,char.realm)
  W.Button(child,recipient,0,(i-1)*27,285,function() if not (A.queue and A.queue:Active()) then O.bankCharacter:SetText(recipient); p:Hide() end end)
 end
 if #choices==0 then W.Text(child,'No characters recorded yet. Log in with Postly enabled, or type the full character name.',0,0,280) end
 child:SetHeight(math.max(150,#choices*27)); p:Show()
end
function O.ShowTab(key)
 if not O.pages or not O.pages[key] then return end
 -- Commit focused edits before hiding their page.
 for _,entry in ipairs(O.controls) do if entry.edit then entry.control:ClearFocus() end end
 if O.picker then O.picker:Hide() end
 if A.Workflows and A.Workflows.menu then A.Workflows.menu:Hide() end
 if key~='history' and A.Workflows and A.Workflows.history then A.Workflows.history:Hide() end
 O.activeTab=key
 for name,page in pairs(O.pages) do page:SetShown(name==key); W.SelectTab(O.tabs[name],name==key) end
 O.scroll=O.scrolls[key]
 if key=='history' and A.Workflows then A.Workflows.ShowHistory(true) end
end
local function page(key)
 local frame=CreateFrame('Frame',nil,O.panel); O.pages[key]=frame; frame:SetPoint('TOPLEFT',O.panel,'TOPLEFT',20,-136); frame:SetSize(780,480); frame:Hide()
 if key=='history' then return frame end
 local scroll=CreateFrame('ScrollFrame',nil,frame,'UIPanelScrollFrameTemplate'); scroll:SetPoint('TOPLEFT',frame,'TOPLEFT',0,0); scroll:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',-28,0)
 local content=CreateFrame('Frame',nil,scroll); content:SetSize(738,470); scroll:SetScrollChild(content)
 O.contents[key]=content; O.scrolls[key]=scroll; return content
end
local function heading(parent,label,y) W.Text(parent,label,0,y or 0,720,'GameFontNormalLarge') end
function O.Register()
 if O.panel then return end
 O.pages={}; O.contents={}; O.tabs={}; O.scrolls={}; O.bankRows={}; O.materialRows={}
 local panel=CreateFrame('Frame','PostlySettings',UIParent,'PortraitFrameTemplate'); O.panel=panel; panel:Hide()
 panel:SetSize(820,680); panel:SetPoint('CENTER'); panel:SetFrameStrata('DIALOG'); panel:SetClampedToScreen(true); W.Window(panel)
 panel:SetMovable(true); panel:EnableMouse(true); panel:RegisterForDrag('LeftButton'); panel:SetScript('OnDragStart',panel.StartMoving); panel:SetScript('OnDragStop',panel.StopMovingOrSizing)
 if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]='PostlySettings' end
 local close=panel.CloseButton or CreateFrame('Button',nil,panel,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',panel,'TOPRIGHT',-3,-3); close:SetScript('OnClick',function() panel:Hide() end); O.close=close
 W.Text(panel,'Postly settings',85,46,650,'GameFontNormalLarge'); W.Text(panel,'Choose what travels. Keep what you need.  /postly',85,72,650)
 O.status=W.Text(panel,'Add bank alts, choose materials, then visit a mailbox.',20,635,770,'GameFontHighlightSmall'); O.status:SetHeight(35)
 for i,tab in ipairs({{'banks','Bank alts',100},{'materials','Materials',100},{'items','Individual items',126},{'presets','Presets',90},{'sending','Sending',90},{'display','Display',90},{'history','History',90}}) do
  local key=tab[1]; local x=20; for j=1,i-1 do x=x+({100,100,126,90,90,90,90})[j]+8 end
  O.tabs[key]=W.Tab(panel,tab[2],x,98,tab[3],function() O.ShowTab(key) end); page(key)
 end
 local banks=O.contents.banks
 heading(banks,'Bank alts')
 W.Text(banks,'Give each bank alt a friendly name, then type or choose its full character name.',0,30,720)
 W.Text(banks,'Friendly name (for example: Crafting)',0,62,300); W.Text(banks,'Full character name (First name Surname)',320,62,400)
 O.bankFriendly=edit(banks,5,86,280,48); O.bankCharacter=edit(banks,325,86,385,64)
 O.bankSave=button(banks,'Add bank alt',0,122,140,function()
  local id=O.bankID
  if change(function() return A.Store.SaveBank(A.db,A.context,id,O.bankFriendly:GetText(),O.bankCharacter:GetText()) end) then O.NewBank() end
 end)
 button(banks,'Clear form',150,122,100,O.NewBank)
 local seen; seen=button(banks,'Choose seen character',260,122,185,function() picker(seen) end)
 button(banks,'Use this character',455,122,155,function() O.bankCharacter:SetText(A.Store.Normalize(A.context.name,A.context.realm)) end)
 W.Text(banks,'Default destination',0,174,250)
 O.defaultBank=button(banks,'Choose a bank alt  v',200,168,300,function()
  if A.queue and A.queue:Active() then return end
  O.BankMenu(O.defaultBank,function(address) change(function() return A.Store.SetRecipient(A.db,A.context,address,O.pendingOverride) end) end)
 end)
 O.recipient=W.Text(banks,'',200,200,510,'GameFontHighlightSmall')
 W.Text(banks,'Material and individual item destinations can override this default. Names are shared\nwith your same-faction characters. Log into an alt once to add it to the character picker.',0,234,720,'GameFontHighlightSmall')
 O.bankContent=CreateFrame('Frame',nil,banks); O.bankContent:SetSize(720,100); O.bankContent:SetPoint('TOPLEFT',banks,'TOPLEFT',0,-300)
 O.emptyBanks=W.Text(O.bankContent,'No bank alts configured. Add one above to get started.',0,6,700)
 local materials=O.contents.materials
 heading(materials,'Materials')
 W.Text(materials,'Keep is per item type across carried bags: enter units (20) or a percentage (20%).\nPercentages round up and are fixed when a transfer starts. More... edits individual items.',0,32,730,'GameFontHighlightSmall')
 W.Text(materials,'Material',0,90,240,'GameFontNormal'); W.Text(materials,'Keep',278,90,90,'GameFontNormal'); W.Text(materials,'Send to bank alt',380,90,210,'GameFontNormal')
 for i,category in ipairs(A.Categories.list) do
  local key,label=category[1],category[2]; local y=118+(i-1)*36; local row={}; O.categories[key]=row
  row.check=check(materials,label,0,y,function(enabled)
   local old=A.config.rules.categories[key]; change(function() return A.Store.SetRule(A.db,A.context,'category',key,{enabled=enabled,keep=old.keep}) end)
  end)
  row.check.label:SetWidth(235)
  row.keep=edit(materials,280,y,80,12)
  commit(row.keep,function(value)
   local old=A.config.rules.categories[key]
   local ok=change(function() return A.Store.SetRule(A.db,A.context,'category',key,{enabled=old.enabled,keep=value}) end)
   if not ok then row.keep:SetText(tostring(old.keep)) end
  end)
  row.destination=button(materials,'',380,y,220,function() O.DestinationMenu(row.destination,'category',key) end)
  row.more=button(materials,'More...',615,y,95,function() O.ShowMaterial(key) end)
 end
 local items=O.contents.items; heading(items,'Individual items')
 W.Text(items,'Type an item ID below, or drag an item from your bags onto the Item ID box.\nChoose a rule, optionally override Keep, then click Add / Update. Never send takes priority.',0,30,730,'GameFontHighlightSmall')
 W.Text(items,'Item ID (type or drop an item here)',0,80,250,'GameFontNormalSmall'); W.Text(items,'Selection rule',265,80,230,'GameFontNormalSmall'); W.Text(items,'Keep: units or % (blank = inherit)',510,80,230,'GameFontNormalSmall')
 O.itemID=edit(items,5,105,235,12); O.itemKeep=edit(items,515,105,195,12); O.itemMode='always'
 O.mode=button(items,'Always send',265,105,225,function() O.itemMode=O.itemMode=='always' and 'never' or O.itemMode=='never' and 'inherit' or 'always'; O.mode:SetText(modeLabels[O.itemMode]) end)
 O.itemID:SetScript('OnReceiveDrag',function()
  if A.queue and A.queue:Active() then return end
  if not GetCursorInfo then return end
  local kind,id,_,extra=GetCursorInfo(); if kind=='item' then id=type(id)=='number' and id or extra; if type(id)=='number' then O.itemID:SetText(tostring(id)); if ClearCursor then ClearCursor() end end end
 end)
 O.itemID:SetScript('OnTextChanged',function() local id=tonumber(O.itemID:GetText()); if O.itemDestination then O.itemDestination:SetText(bankLabel(A.config.routes and A.config.routes.items[id])..'  v') end end)
 W.Text(items,'Send this item to',0,149,160)
 O.itemDestination=button(items,'Default destination  v',165,143,325,function()
  local id=tonumber(O.itemID:GetText())
  if not id or id<1 or id~=math.floor(id) or id>2147483647 then O.Report(false,'Enter an item ID or drop an item first.'); return end
  O.DestinationMenu(O.itemDestination,'item',id)
 end)
 O.itemSave=button(items,'Add / Update',515,143,195,function()
  local value=O.itemKeep:GetText(); change(function() return A.Store.SetRule(A.db,A.context,'item',tonumber(O.itemID:GetText()),{mode=O.itemMode,keep=value~='' and value or nil}) end)
 end)
 W.Text(items,'An item destination overrides its material destination. Blank Keep inherits the material.\nRemoving a rule retains its destination; choose Use default destination to clear that route.',0,185,730,'GameFontHighlightSmall')
 W.Text(items,'Search name or item ID',0,233,160,'GameFontHighlightSmall')
 O.itemSearch=W.Edit(items,170,227,350,80)
 O.itemSearchClear=W.Button(items,'Clear search',535,227,120,function() O.itemSearch:SetText('') end)
 local itemScroll=CreateFrame('ScrollFrame',nil,items,'UIPanelScrollFrameTemplate'); O.itemScroll=itemScroll; itemScroll:SetPoint('TOPLEFT',items,'TOPLEFT',0,-266); itemScroll:SetSize(730,194)
 O.itemContent=CreateFrame('Frame',nil,itemScroll); O.itemContent:SetSize(730,200); itemScroll:SetScrollChild(O.itemContent)
 O.emptyItems=W.Text(O.itemContent,'No individual item rules yet.',5,12,700,'GameFontDisable')
 O.itemSearch:SetScript('OnTextChanged',function() O.itemScroll:SetVerticalScroll(0); O.FilterItems() end)
 local presets=O.contents.presets
 O.source=W.Text(presets,'',0,164,720,'GameFontHighlightSmall')
 heading(presets,'Character settings',205)
 W.Text(presets,'These controls apply to Default. Saved presets keep their own rules and recipient.',0,237,720,'GameFontHighlightSmall')
 O.override=check(presets,'Use a separate default recipient for this character',0,268,function(value)
  O.pendingOverride=value
  if not value then change(function() return A.Store.UseSharedRecipient(A.db,A.context) end) end
 end)
 local copyRules=button(presets,'Copy shared rules to this character',0,310,290,function() change(function() return A.Store.CopySharedRules(A.db,A.context) end) end)
 local sharedRules=button(presets,'Use shared rules',310,310,190,function() change(function() return A.Store.UseSharedRules(A.db,A.context) end) end)
 O.defaultControls={O.override,copyRules,sharedRules}
 local display=O.contents.display; heading(display,'Mailbox display')
 O.autoShow=check(display,'Show automatically at the mailbox',0,45,function(v)
  if pref('display','autoShow',v) and A.Mailbox then if v and A.Client.IsOpen() then A.Mailbox.Show() elseif not v then A.Mailbox.Hide() end end
 end)
 O.compact=check(display,'Use the compact mailbox mini bar',0,82,function(v) if pref('display','compact',v) and A.Mailbox and A.Client.IsOpen() then A.Mailbox.Show() end end)
 button(display,'Reset mailbox panel position',0,128,260,function() if pref('display','point',nil) and A.Mailbox and A.Client.IsOpen() then A.Mailbox.Show() end end)
 local sending=O.contents.sending; heading(sending,'Sending')
 O.review=check(sending,'Review items before starting a transfer',0,45,function(v) pref('sending','review',v) end)
 O.completion=check(sending,'Print a completion message in my chat',0,82,function(v) pref('sending','completion',v) end)
 W.Text(sending,'Mail subject',0,142,150); O.subject=edit(sending,165,136,360,48)
 local function saveSubject(value) change(function() return A.Store.SetSubject(A.db,A.context,value) end) end
 commit(O.subject,saveSubject); O.subjectSave=button(sending,'Save',550,136,100,function() saveSubject(O.subject:GetText()) end)
 O.subjectReset=button(sending,'Reset to default',165,175,150,function() change(function() return A.Store.SetSubject(A.db,A.context,'Postly') end) end)
 W.Text(sending,'Default: Postly. Saved with the selected preset. Press Enter or click Save.',0,216,720,'GameFontHighlightSmall')
 W.Text(sending,'Each mail requires your click at an open mailbox. No gold or COD is sent.\nEach destination is reviewed separately; the addon never automatically sends to the next bank alt.',0,310,720,'GameFontHighlightSmall')
 if A.Workflows then A.Workflows.BuildOptions(presets,sending) end
 panel:SetScript('OnShow',O.Refresh)
 panel:SetScript('OnHide',function()
  if O.picker then O.picker:Hide() end; if O.material then O.material:Hide() end
  if A.Workflows and A.Workflows.history then A.Workflows.history:Hide() end
  if A.Workflows then if A.Workflows.menu then A.Workflows.menu:Hide() end; if A.Workflows.destination then A.Workflows.destination:Hide() end end
 end)
 -- Native Settings is a small launcher, independent of the standalone window.
 if A.Client.Probe().settings then
  local launcher=CreateFrame('Frame'); O.launcher=launcher; launcher.name='Postly'
  W.Text(launcher,'Postly',16,20,600,'GameFontNormalLarge')
  W.Text(launcher,'Configure bank alts, materials, individual items and mail history in the dedicated window.\n\nCommand: /postly',16,65,600)
  O.launcherOpen=W.Button(launcher,'Open Postly settings',16,148,270,O.Open)
  O.category=Settings.RegisterCanvasLayoutCategory(launcher,'Postly'); Settings.RegisterAddOnCategory(O.category)
 end
 O.ShowTab('banks'); O.Refresh()
end
function O.Open(key)
 if not O.panel then O.Register() end
 if not O.panel then return end
 -- The native Settings frame must not cover the settings we just opened.
 if SettingsPanel and SettingsPanel:IsShown() then SettingsPanel:Hide() end
 O.panel:Show(); O.ShowTab(key or O.activeTab or 'banks')
end
function O.ShowMaterial(key)
 if A.queue and A.queue:Active() then O.Report(false,'Stop the transfer before editing material items.'); return end
 O.Open('materials'); O.materialKey=key
 if not O.material then
  local p=CreateFrame('Frame',nil,O.panel,'BackdropTemplate'); O.material=p; p:SetSize(770,560); p:SetPoint('CENTER'); p:SetFrameStrata('DIALOG'); p:SetClampedToScreen(true); W.Backdrop(p)
  O.materialTitle=W.Text(p,'',16,16,610,'GameFontNormalLarge')
  W.Button(p,'Close',664,12,90,function() p:Hide() end)
  W.Text(p,'Included items follow the category selection. Never send excludes an item.\nKnown base items and discovered materials are listed; new materials can appear as you encounter them.\nKeep: enter units or a percentage; blank inherits the category. Reset removes this item rule.',16,50,730,'GameFontHighlightSmall')
  W.Text(p,'Search name or item ID',16,119,170,'GameFontHighlightSmall')
  O.materialSearch=W.Edit(p,195,112,365,80)
  O.materialSearchClear=W.Button(p,'Clear search',575,112,120,function() O.materialSearch:SetText('') end)
  W.Text(p,'Included / item',16,151,395,'GameFontNormal'); W.Text(p,'Keep override (units or %)',432,151,210,'GameFontNormal')
  local scroll=CreateFrame('ScrollFrame',nil,p,'UIPanelScrollFrameTemplate'); O.materialScroll=scroll
  scroll:SetPoint('TOPLEFT',p,'TOPLEFT',16,-181); scroll:SetPoint('BOTTOMRIGHT',p,'BOTTOMRIGHT',-32,20)
  O.materialContent=CreateFrame('Frame',nil,scroll); O.materialContent:SetSize(710,344); scroll:SetScrollChild(O.materialContent)
  O.materialEmpty=W.Text(O.materialContent,'',0,10,700,'GameFontDisable')
  O.materialSearch:SetScript('OnTextChanged',function() O.materialScroll:SetVerticalScroll(0); O.FilterMaterial() end)
 end
 -- A deliberate open may inspect bags. Event refreshes only update existing rows.
 if A.Client.Snapshot then A.Categories.Observe(A.Client.Snapshot(),A.db) end
 if A.Client.ItemDisplay then
  for id in pairs(A.config.rules.items) do
   local display=A.Client.ItemDisplay(id)
   if display and display.category then A.Categories.Observe({{itemID=id,category=display.category}},A.db) end
  end
 end
 O.materialIDs=A.Categories.Items(key,A.db); O.materialSearch:SetText(''); O.materialScroll:SetVerticalScroll(0)
 -- Scroll-child controls sit several levels above the settings frame.
 -- Reapply on every open in case the native window was raised.
 O.material:SetFrameLevel(O.panel:GetFrameLevel()+40); O.material:EnableMouse(true)
 O.material:Show(); O.RefreshMaterial()
end
function O.RefreshMaterial()
 if not O.material or not O.material:IsShown() then return end
 for _,category in ipairs(A.Categories.list) do if category[1]==O.materialKey then O.materialTitle:SetText(category[2]..' - individual items') end end
 for _,row in ipairs(O.materialRows) do row.active=false; row.frame:Hide() end
 for i,id in ipairs(O.materialIDs or {}) do
  local row=O.materialRows[i]
  if not row then
   row={}; row.frame=CreateFrame('Frame',nil,O.materialContent); row.frame:SetSize(710,48); row.frame:SetPoint('TOPLEFT',O.materialContent,'TOPLEFT',0,-(i-1)*50)
   row.enabled=track(CreateFrame('CheckButton',nil,row.frame,'UICheckButtonTemplate')); row.enabled:SetSize(26,26); row.enabled:SetPoint('TOPLEFT',row.frame,'TOPLEFT',0,-4)
   iconControl(row,32)
   row.label=W.Text(row.frame,'',74,3,326,'GameFontHighlightSmall')
   row.keep=edit(row.frame,420,4,145,12); row.reset=button(row.frame,'Reset',588,4,100,function() end)
   O.materialRows[i]=row
  end
  local itemID=id; local rule=A.config.rules.items[id]; row.itemID=id; row.active=true; itemVisual(row,id)
  row.label:SetText(row.name..' ['..id..']\n'..(rule and modeLabels[rule.mode] or 'Use material selection'))
  row.enabled:SetChecked(not rule or rule.mode~='never'); row.keep:SetText(rule and rule.keep~=nil and tostring(rule.keep) or '')
  row.enabled:SetScript('OnClick',function(self)
   local old=A.config.rules.items[itemID]
   change(function() return A.Store.SetRule(A.db,A.context,'item',itemID,{mode=self:GetChecked() and 'inherit' or 'never',keep=old and old.keep}) end)
  end)
  commit(row.keep,function(value)
   local old=A.config.rules.items[itemID]
   if not change(function() return A.Store.SetRule(A.db,A.context,'item',itemID,{mode=old and old.mode or 'inherit',keep=value~='' and value or nil}) end) then
    row.keep:SetText(old and old.keep~=nil and tostring(old.keep) or '')
   end
  end)
  row.reset:SetScript('OnClick',function() change(function() return A.Store.SetRule(A.db,A.context,'item',itemID,nil) end) end)
  tip(row.enabled,itemID); row.frame:Show()
 end
 O.FilterMaterial(); O.RefreshLock()
end
