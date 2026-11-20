-- Small explicit widget fake: verifies callbacks and state, not game rendering.
function fakeUI()
 local created={}; local widget={}; widget.__index=widget
 local function new(kind,parent)
  local o=setmetatable({kind=kind,parent=parent,scripts={},shown=true,enabled=true,value='',width=700,height=500},widget)
  created[#created+1]=o; return o
 end
 function widget:SetPoint(...) self.point={...} end
 function widget:ClearAllPoints() self.point=nil end
 function widget:SetAllPoints() end
 function widget:SetSize(w,h) self.width=w; self.height=h end
 function widget:SetWidth(w) self.width=w end
 function widget:SetHeight(h) self.height=h end
 function widget:GetWidth() return self.width end
 function widget:GetHeight() return self.height end
 function widget:GetLeft() return 20 end
 function widget:GetBottom() return 20 end
 function widget:GetRight() return self.width+20 end
 function widget:GetParent() return self.parent end
 function widget:CreateFontString() return new('FontString',self) end
 function widget:CreateTexture() return new('Texture',self) end
 function widget:SetText(v) self.value=tostring(v or ''); if self.kind=='EditBox' and self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end end
 function widget:GetText() return self.value end
 function widget:SetScript(k,v) self.scripts[k]=v end
 function widget:HookScript(k,v) local old=self.scripts[k]; self.scripts[k]=function(...) if old then old(...) end; v(...) end end
 function widget:Show() local changed=not self.shown; self.shown=true; if changed and self.scripts.OnShow then self.scripts.OnShow(self) end end
 function widget:Hide() local changed=self.shown; self.shown=false; if changed and self.scripts.OnHide then self.scripts.OnHide(self) end end
 function widget:IsShown() return self.shown end
 function widget:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
 function widget:SetShown(v) if v then self:Show() else self:Hide() end end
 function widget:SetEnabled(v) self.enabled=v end
 function widget:IsEnabled() return self.enabled end
 function widget:Enable() self.enabled=true end
 function widget:Disable() self.enabled=false end
 function widget:SetChecked(v) self.checked=v end
 function widget:GetChecked() return self.checked end
 function widget:SetScrollChild(v) self.child=v end
 function widget:SetVerticalScroll(v) self.scroll=v end
 function widget:SetAutoFocus() end
 function widget:SetMaxLetters() end
 function widget:SetNumeric() end
 function widget:SetFontObject() end
 function widget:SetNormalFontObject(v) self.normalFont=v end
 function widget:SetHighlightFontObject(v) self.highlightFont=v end
 function widget:SetDisabledFontObject(v) self.disabledFont=v end
 function widget:SetFont(...) self.font={...} end
 function widget:SetTextInsets(...) self.textInsets={...} end
 function widget:SetShadowColor() end
 function widget:SetShadowOffset() end
 function widget:SetColorTexture(...) self.fill={...} end
 function widget:SetVertexColor(...) self.tint={...} end
 function widget:SetJustifyH() end
 function widget:SetJustifyV() end
 function widget:SetTextColor(...) self.color={...} end
 function widget:SetWordWrap() end
 function widget:SetBackdrop(v) self.backdrop=v end
 function widget:SetBackdropColor(...) self.backgroundColor={...} end
 function widget:SetBackdropBorderColor(...) self.borderColor={...} end
 function widget:SetMovable() end
 function widget:SetClampedToScreen() end
 function widget:EnableMouse(v) self.mouseEnabled=v end
 function widget:EnableKeyboard() end
 function widget:RegisterForDrag() end
 function widget:RegisterForClicks() end
 function widget:StartMoving() end
 function widget:StopMovingOrSizing() end
 function widget:SetFrameStrata(v) self.strata=v end
 function widget:GetFrameStrata() return self.strata or self.parent and self.parent:GetFrameStrata() or "MEDIUM" end
 function widget:SetFrameLevel(v) self.frameLevel=v end
 function widget:GetFrameLevel() return self.frameLevel or (self.parent and self.parent:GetFrameLevel()+1 or 0) end
 function widget:SetNormalTexture() end
 function widget:SetHighlightTexture() end
 function widget:SetTexture(path) self.texture=path end
 function widget:SetTexCoord() end
 function widget:SetAlpha() end
 function widget:ClearFocus() if self.focused then self.focused=false; if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end end end
 function widget:HighlightText() end
 function widget:SetFocus() self.focused=true end
 function widget:HasFocus() return self.focused and true or false end
 function widget:SetOwner() end
 function widget:SetHyperlink(link) self.link=link end
 function widget:AddLine() end
 function widget:SetItemByID(id) self.itemID=id end
 function widget:RegisterEvent() end
 UIParent=new('Frame'); UIParent.width=1600
 MailFrame=new('Frame'); GameTooltip=new('Frame')
 CreateFrame=function(kind,_,parent,template) local w=new(kind,parent); w.template=template; return w end
 Settings={RegisterCanvasLayoutCategory=function(panel,name) return {GetID=function() return 55 end,panel=panel,name=name} end,RegisterAddOnCategory=function(c) Settings.registered=c end,OpenToCategory=function(id) Settings.opened=id end}
 return created
end
