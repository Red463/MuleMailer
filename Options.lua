local _,A=...
local O={controls={},categories={},itemRows={}}
A.Options=O
local W={}; A.Widgets=W
function W.Text(parent,value,x,y,width,font)
 local f=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlight')
 f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y); f:SetWidth(width); f:SetJustifyH('LEFT'); f:SetWordWrap(true); f:SetText(value)
 return f
end
function W.Button(parent,label,x,y,width,action)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate'); b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y); b:SetSize(width,24); b:SetText(label)
 b:SetScript('OnClick',action); return b
end
function W.Edit(parent,x,y,width,max)
 local e=CreateFrame('EditBox',nil,parent,'InputBoxTemplate'); e:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y); e:SetSize(width,24); e:SetAutoFocus(false); e:SetMaxLetters(max or 64)
 e:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 return e
end
function W.Backdrop(frame)
 frame:SetBackdrop({bgFile='Interface\\Tooltips\\UI-Tooltip-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 frame:SetBackdropColor(0.14,0.035,0.022,0.98); frame:SetBackdropBorderColor(0.9,0.65,0.24,1)
end
local function track(control,edit)
 O.controls[#O.controls+1]={control=control,edit=edit}; return control
end
local function button(parent,label,x,y,width,action) return track(W.Button(parent,label,x,y,width,action)) end
local function edit(parent,x,y,width,max) return track(W.Edit(parent,x,y,width,max),true) end
local function check(parent,label,x,y,action)
 local b=track(CreateFrame('CheckButton',nil,parent,'UICheckButtonTemplate'))
 b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y); b:SetSize(26,26)
 W.Text(parent,label,x+30,y+6,420)
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
 e:SetScript('OnEditFocusLost',function(self) if not self.skipFocusCommit then save(self) end end)
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
function O.RefreshItems()
 if not O.itemContent or not A.config then return end
 local ids={}; for id in pairs(A.config.rules.items) do ids[#ids+1]=id end; table.sort(ids)
 for i,row in ipairs(O.itemRows) do row.frame:Hide() end
 for i,id in ipairs(ids) do
  local row=O.itemRows[i]
  if not row then
   row={}; row.frame=CreateFrame('Frame',nil,O.itemContent); row.frame:SetSize(590,38); row.frame:SetPoint('TOPLEFT',O.itemContent,'TOPLEFT',0,-(i-1)*40)
   row.select=button(row.frame,'Edit',0,5,48,function() end)
   row.label=W.Text(row.frame,'',58,3,430,'GameFontHighlightSmall')
   row.remove=button(row.frame,'Remove',500,5,76,function() end)
   O.itemRows[i]=row
  end
  local itemID=id; local rule=A.config.rules.items[itemID]
  row.label:SetText(A.Client.ItemName(itemID)..' ['..itemID..']\n'..(rule.mode=='never' and 'Never send' or 'Always send')..'  |  Keep: '..(rule.keep~=nil and tostring(rule.keep) or 'category default'))
  if A.Workflows then
   row.label:SetWidth(380)
   if not row.destination then row.destination=button(row.frame,'To...',450,5,44,function() end) end
   row.destination:SetScript('OnClick',function() A.Workflows.Destination('item',itemID) end)
   row.destination:SetText(A.config.routes.items[itemID] and 'Set' or 'To...')
  end
  row.select:SetScript('OnClick',function()
   O.itemID:SetText(tostring(itemID)); O.itemKeep:SetText(rule.keep~=nil and tostring(rule.keep) or ''); O.itemMode=rule.mode; O.mode:SetText(rule.mode=='never' and 'Never send' or 'Always send')
  end)
  row.remove:SetScript('OnClick',function() change(function() return A.Store.SetRule(A.db,A.context,'item',itemID,nil) end) end)
  row.select:SetScript('OnEnter',function(self) if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); GameTooltip:SetItemByID(itemID); GameTooltip:Show() end end)
  row.select:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
  row.frame:Show()
 end
 O.itemContent:SetHeight(math.max(170,#ids*40))
 if O.emptyItems then O.emptyItems:SetShown(#ids==0) end
 O.RefreshLock()
end
function O.Refresh()
 if not O.panel or not A.context then return end
 local cfg=A.Store.Resolve(A.db,A.context)
 O.source:SetText('Rules: '..cfg.ruleSource..'  |  Recipient: '..(cfg.recipientSource or 'Unavailable'))
 O.recipient:SetText(A.Store.RecipientLabel(cfg.recipient,A.context.realm))
 O.pendingOverride=cfg.recipientSource=='Character'; O.override:SetChecked(O.pendingOverride)
 for key,row in pairs(O.categories) do local v=cfg.rules.categories[key] or {enabled=false,keep=0}; row.check:SetChecked(v.enabled); row.keep:SetText(tostring(v.keep)) end
 O.autoShow:SetChecked(cfg.display.autoShow~=false); O.compact:SetChecked(cfg.display.compact)
 O.review:SetChecked(cfg.sending.review); O.completion:SetChecked(cfg.sending.completion~=false); O.subject:SetText(cfg.sending.subject or 'Mule Mailer')
 if cfg.error or cfg.warning then O.status:SetText(cfg.error or cfg.warning) end
 O.RefreshItems(); O.RefreshLock()
 if A.Workflows then A.Workflows.RefreshOptions() end
end
local function picker(anchor)
 if O.picker then O.picker:Hide() end
 local p=CreateFrame('Frame',nil,O.panel,'BackdropTemplate'); O.picker=p
 p:SetSize(310,240); p:SetPoint('TOPLEFT',anchor,'BOTTOMLEFT',0,-2); p:SetFrameStrata('DIALOG'); W.Backdrop(p)
 W.Text(p,'Choose your bank alt',12,12,280)
 W.Button(p,'Close',228,202,68,function() p:Hide() end)
 local scroll=CreateFrame('ScrollFrame',nil,p,'UIPanelScrollFrameTemplate'); scroll:SetPoint('TOPLEFT',p,'TOPLEFT',12,-40); scroll:SetPoint('BOTTOMRIGHT',p,'BOTTOMRIGHT',-30,42)
 local child=CreateFrame('Frame',nil,scroll); child:SetSize(260,150); scroll:SetScrollChild(child)
 local choices={}
 for guid,char in pairs(A.db.characters or {}) do if char.contextKey==A.Store.ScopeKey(A.context) and guid~=A.context.characterID then choices[#choices+1]=char end end
 table.sort(choices,function(a,b) return a.name<b.name end)
 for i,char in ipairs(choices) do
  local recipient=A.Store.Normalize(char.name,char.realm)
  W.Button(child,A.Store.RecipientLabel(recipient,A.context.realm),0,(i-1)*27,255,function()
   if change(function() return A.Store.SetRecipient(A.db,A.context,recipient,O.pendingOverride) end) then p:Hide() end
  end)
 end
 if #choices==0 then W.Text(child,'No other characters recorded yet.\n\nLog into another character with Mule Mailer enabled, then return here. Characters must be on the same faction.\n\nYou can also enter your bank character name in the field above.',0,0,250) end
 child:SetHeight(math.max(150,#choices*27)); p:Show()
end
function O.Register()
 if O.panel then return end
 if not A.Client.Probe().settings then return end
 local panel=CreateFrame('Frame'); O.panel=panel; panel.name='Mule Mailer'; panel:Hide()
 local brand=CreateFrame('Frame',nil,panel,'BackdropTemplate'); brand:SetPoint('TOPLEFT',panel,'TOPLEFT',8,-8); brand:SetPoint('TOPRIGHT',panel,'TOPRIGHT',-8,-8); brand:SetHeight(152); W.Backdrop(brand)
 local logo=brand:CreateTexture(nil,'ARTWORK'); logo:SetPoint('TOPLEFT',brand,'TOPLEFT',12,-2); logo:SetSize(300,150); logo:SetTexture(A.media..'Header')
 W.Text(brand,'A little help for your bank alt.',330,44,250,'GameFontNormalLarge')
 W.Text(brand,'Choose what travels.\nKeep what you need.',330,84,250,'GameFontHighlight')
 O.status=W.Text(panel,'Enter the full bank name (First name Surname), click Save, then choose materials.',16,174,620,'GameFontHighlightSmall')
 local scroll=CreateFrame('ScrollFrame',nil,panel,'UIPanelScrollFrameTemplate'); O.scroll=scroll; scroll:SetPoint('TOPLEFT',panel,'TOPLEFT',16,-210); scroll:SetPoint('BOTTOMRIGHT',panel,'BOTTOMRIGHT',-32,16)
 local body=CreateFrame('Frame',nil,scroll); body:SetSize(620,1405); scroll:SetScrollChild(body)
 local content=CreateFrame('Frame',nil,body); O.content=content; content:SetSize(620,1405); content:SetPoint('TOPLEFT',body,'TOPLEFT',0,A.Workflows and -148 or 0)
 local function heading(label,y) W.Text(content,label,0,y,600,'GameFontNormalLarge') end
 heading('Bank alt',0)
 O.source=W.Text(content,'',0,30,600,'GameFontHighlightSmall')
 W.Text(content,'Full character name',0,58,150)
 O.recipient=edit(content,160,52,290)
 button(content,'Save',465,52,90,function() change(function() return A.Store.SetRecipient(A.db,A.context,O.recipient:GetText(),O.pendingOverride) end) end)
 O.override=check(content,'Use a separate recipient for this character',0,85,function(value)
  O.pendingOverride=value
  if not value then change(function() return A.Store.UseSharedRecipient(A.db,A.context) end) end
 end)
 button(content,'Use this character as bank alt',0,122,245,function() change(function() return A.Store.RegisterBank(A.db,A.context,O.pendingOverride) end) end)
 local seen; seen=button(content,'Choose seen character',260,122,200,function() picker(seen) end)
 heading('Materials',170)
 W.Text(content,'Selection applies to every item in a group. Keep is per item type.',0,200,600,'GameFontHighlightSmall')
 W.Text(content,'Keep units',440,225,120,'GameFontNormal')
 for i,category in ipairs(A.Categories.list) do
  local key,label=category[1],category[2]; local y=250+(i-1)*29
  local row={}; O.categories[key]=row
  row.check=check(content,label,0,y,function(enabled)
   local old=A.config.rules.categories[key]
   change(function() return A.Store.SetRule(A.db,A.context,'category',key,{enabled=enabled,keep=old.keep}) end)
  end)
  row.keep=edit(content,445,y,90,10)
  commit(row.keep,function(value)
   local old=A.config.rules.categories[key]
   local ok=change(function() return A.Store.SetRule(A.db,A.context,'category',key,{enabled=old.enabled,keep=tonumber(value)}) end)
   if not ok then row.keep:SetText(tostring(old.keep)) end
  end)
 end
 heading('Individual items',530)
 W.Text(content,'Never send overrides selections. A blank keep value inherits the group default.\nClick Edit beside an item to change it; unresolved items wait for game data.',0,560,600,'GameFontHighlightSmall')
 W.Text(content,'Item ID / drop item',0,602,160,'GameFontNormalSmall'); W.Text(content,'Rule',170,602,140,'GameFontNormalSmall'); W.Text(content,'Keep (optional)',335,602,120,'GameFontNormalSmall')
 O.itemID=edit(content,5,625,145,12); O.itemKeep=edit(content,340,625,100,10); O.itemMode='always'
 O.mode=button(content,'Always send',170,625,150,function() O.itemMode=O.itemMode=='always' and 'never' or 'always'; O.mode:SetText(O.itemMode=='always' and 'Always send' or 'Never send') end)
 button(content,'Add / Update',460,625,120,function()
  local id=tonumber(O.itemID:GetText()); local value=O.itemKeep:GetText(); local keep=value~='' and tonumber(value) or nil
  if value~='' and not keep then O.Report(false,'Keep must be a nonnegative whole number.'); return end
  change(function() return A.Store.SetRule(A.db,A.context,'item',id,{mode=O.itemMode,keep=keep}) end)
 end)
 O.itemID:SetScript('OnReceiveDrag',function()
  if A.queue and A.queue:Active() then return end
  local kind,id,_,extra=GetCursorInfo()
  if kind=='item' then
   id=type(id)=='number' and id or extra
   if type(id)=='number' then O.itemID:SetText(tostring(id)); if ClearCursor then ClearCursor() end end
  end
 end)
 local itemScroll=CreateFrame('ScrollFrame',nil,content,'UIPanelScrollFrameTemplate'); itemScroll:SetPoint('TOPLEFT',content,'TOPLEFT',0,-665); itemScroll:SetSize(590,180)
 O.itemContent=CreateFrame('Frame',nil,itemScroll); O.itemContent:SetSize(590,170); itemScroll:SetScrollChild(O.itemContent)
 O.emptyItems=W.Text(O.itemContent,'No individual item rules yet.',5,12,550,'GameFontDisable')
 heading('Character settings',875)
 W.Text(content,'A character copy can be edited independently. Recipient overrides are separate.',0,905,600,'GameFontHighlightSmall')
 local copyRules=button(content,'Copy shared rules to this character',0,932,275,function() change(function() return A.Store.CopySharedRules(A.db,A.context) end) end)
 local sharedRules=button(content,'Use shared rules',290,932,180,function() change(function() return A.Store.UseSharedRules(A.db,A.context) end) end)
 O.defaultControls={O.override,copyRules,sharedRules}
 heading('Mailbox display',985)
 O.autoShow=check(content,'Show automatically at the mailbox',0,1015,function(v)
  if pref('display','autoShow',v) and A.Mailbox then if v and A.Client.IsOpen() then A.Mailbox.Show() elseif not v then A.Mailbox.Hide() end end
 end)
 O.compact=check(content,'Use the compact mailbox mini bar',0,1048,function(v) if pref('display','compact',v) and A.Mailbox and A.Client.IsOpen() then A.Mailbox.Show() end end)
 button(content,'Reset mailbox panel position',0,1085,245,function() if pref('display','point',nil) and A.Mailbox and A.Client.IsOpen() then A.Mailbox.Show() end end)
 heading('Sending',1138)
 O.review=check(content,'Review items before starting a transfer',0,1168,function(v) pref('sending','review',v) end)
 O.completion=check(content,'Print a completion message in my chat',0,1201,function(v) pref('sending','completion',v) end)
 W.Text(content,'Mail subject',0,1245,150); O.subject=edit(content,165,1239,285,48)
 local function saveSubject(value)
  if not value:find('%S') or value:find('[%c]') then O.Report(false,'Enter a mail subject without control characters.'); return end
  change(function() return A.Store.SetSubject(A.db,A.context,value) end)
 end
 commit(O.subject,saveSubject)
 O.subjectSave=button(content,'Save',465,1239,90,function() saveSubject(O.subject:GetText()) end)
 O.subjectReset=button(content,'Reset to default',165,1273,150,function() change(function() return A.Store.SetSubject(A.db,A.context,'Mule Mailer') end) end)
 W.Text(content,'Default: Mule Mailer. Saved with the selected preset. Press Enter or click Save.',0,1310,600,'GameFontHighlightSmall')
 W.Text(content,'Each mail requires your click. Blizzard restrictions are respected; no automatic retries.\nNo gold or COD is sent. You must be at an open mailbox.',0,1340,600,'GameFontHighlightSmall')
 content:SetHeight(1405)
 if A.Workflows then A.Workflows.BuildOptions(body,content) end
 panel:SetScript('OnShow',O.Refresh)
 O.category=Settings.RegisterCanvasLayoutCategory(panel,'Mule Mailer')
 Settings.RegisterAddOnCategory(O.category)
 O.Refresh()
end
function O.Open()
 if not O.panel then O.Register() end
 if not O.category then A.Message('The native Settings API is unavailable on this client.'); return end
 Settings.OpenToCategory(O.category:GetID())
end
