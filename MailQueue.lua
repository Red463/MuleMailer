local _,A=...
local Q={}; Q.__index=Q
A.MailQueue={}
function A.MailQueue.New(client,onChange)
 return setmetatable({client=client,onChange=onChange or function() end,state='idle',sentMails=0,quota={},keep={},batch={}},Q)
end
function Q:GetStatus()
 local units=0; for _,n in pairs(self.quota) do units=units+n end
 return {state=self.state,recipient=self.recipient,sentMails=self.sentMails,remainingUnits=units,reason=self.reason,waitReason=self.waitReason}
end
function Q:Notify() self.onChange(self:GetStatus()) end
function Q:Active()
 return self.state=='preparing' or self.state=='ready' or self.state=='awaiting-click' or self.state=='awaiting-result' or self.state=='stopping'
end
function Q:Fail(reason,detail)
 if A.History then A.History.Outcome(self,'uncertain',reason) end
 self.state='error'; self.reason=reason or 'Mail stopped. Check the mail window for unsent items.'; self.pending=nil
 A.draftDiagnostic=self.reason
 if type(detail)=='string' and (not issecretvalue or not issecretvalue(detail)) then A.draftDiagnostic=A.draftDiagnostic..' ['..detail:gsub('[%c]',' '):sub(1,300)..']' end
 self:Notify(); return false,self.reason
end
local function totals(stock,id)
 local total=0; for _,s in ipairs(stock) do if s.itemID==id then total=total+s.count end end; return total
end
function Q:AvailableStock()
 local raw=self.client.Snapshot(); local out={uncertain=raw.uncertain}; local reserved={}
 for _,b in ipairs(self.batch) do
  local r=reserved[b.guid]
  if not r then r={before=b.before,count=0}; reserved[b.guid]=r end
  r.count=r.count+b.count
 end
 for _,s in ipairs(raw) do
  local copy={}; for k,v in pairs(s) do copy[k]=v end
  local r=reserved[s.guid]
  if r then
   -- Attached items can remain in their original bag slots until SendMail.
   -- Count them once, whether the bag API echoes the old quantity or already
   -- reflects removal. Intermediate/ambiguous quantities are conservative.
   local remaining=math.max(0,r.before-r.count)
   if copy.count>remaining then copy.count=math.max(0,copy.count-r.count) end
  end
  out[#out+1]=copy
 end
 return out
end
function Q:ValidateStock(stock)
 if stock.uncertain then return self:Fail('Inventory data became unavailable. Unsent items remain in the mail window.') end
 for _,s in ipairs(stock) do
  if s.count>0 and (self.quota[s.itemID] or 0)>0 then
   if s.uncertain then return self:Fail('Item eligibility became unavailable. Start a fresh transfer after item data loads.') end
   local source=s.guid and self.sources[s.guid]
   if source and source.count>0 and not s.eligible and not s.locked then return self:Fail('An original item is no longer eligible. Check the mail window before starting again.') end
  end
 end
 return true
end
function Q:MatchesDraft()
 local d=self.client.Draft()
 local why
 if d.uncertain then why='money/COD information unavailable'
 elseif not A.Store.SameRecipient(self.recipient,d.recipient) then
  local function quoted(value)
   if type(value)~='string' or issecretvalue and issecretvalue(value) then return '<unavailable>' end
   return string.format('%q',value:gsub('|','||')):sub(1,120)
  end
  why='recipient changed; expected '..quoted(self.recipient)..', actual '..quoted(d.recipient)
 elseif d.subject~=self.subject then why='subject changed'
 elseif d.body~='' then why='body changed'
 elseif d.money~=0 then why='money attached'
 elseif d.cod then why='COD selected' end
 if why then A.draftDiagnostic=why; return false,why end
 return true
end
function Q:MatchesAttachments(allowPending)
 local actual=self.client.Attachments()
 if actual.uncertain then return false,false,'attachment data unavailable' end
 if #actual>#self.batch then return false,false,'unexpected extra attachment' end
 local expected=#self.batch
 if allowPending and self.pending then expected=expected-1 end
 if #actual<expected then return false,false,'expected attachment missing' end
 for i,s in ipairs(actual) do
  local b=self.batch[i]
  if not b then return false,false,'unexpected attachment slot' end
  if s.unresolved then return false,false,'occupied attachment details not loaded' end
  if s.itemID~=b.itemID then return false,false,'attachment item ID changed' end
  if s.count~=b.count then return false,false,'attachment quantity changed' end
  if s.index~=i then return false,false,'attachment position changed' end
  if s.identity~=b.identity then return false,false,'item link differs: expected '..b.identity..' / actual '..s.identity end
 end
 return true,#actual==#self.batch
end
function Q:Start(plan)
 if self:Active() then return false,'A transfer is already active.' end
 local c=self.client
 local ok,why=c.CanAct(); if not ok then return self:Fail(why) end
 if not plan.recipient or plan.recipient=='' then return self:Fail('Choose a bank alt in Options first.') end
 local ctx=c.GetContext()
 if ctx and A.Store.IsSelf(plan.recipient,ctx) then return self:Fail('This character is the bank alt; choose a different recipient.') end
 if c.HasManualDraft() then return self:Fail('Clear or send the existing mail draft first.') end
 if not c.CursorEmpty() then return self:Fail('Empty your cursor first.') end
 if not c.Affordable() then return self:Fail('Not enough money for postage.') end
 self.quota={}; self.keep={}; self.ids={}; self.sources={}; self.sentMails=0; self.reason=nil; self.successCandidate=nil
 self.waitReason=nil; A.draftDiagnostic=nil
 self.recipient=A.Store.Normalize(plan.recipient) or plan.recipient; self.subject=plan.subject or 'Postly'
 self.presetName=plan.presetName; self.historyRecord=nil
 for _,row in ipairs(plan.items) do
  self.quota[row.itemID]=row.send; self.keep[row.itemID]=row.keep; self.ids[#self.ids+1]=row.itemID
  for guid,source in pairs(row.sources or {}) do self.sources[guid]={count=source.count,identity=source.identity} end
  if not next(row.sources or {}) then return self:Fail('Original item identities are unavailable. Start a fresh transfer.') end
 end
 table.sort(self.ids)
 if #self.ids==0 then return self:Fail('No eligible items to send.') end
 return self:PrepareFromClick()
end
function Q:PrepareFromClick()
 local c=self.client
 if not c.CursorEmpty() then return self:Fail('Empty your cursor first.') end
 if c.HasManualDraft() then return self:Fail('Clear or send the existing mail draft first.') end
 local p=c.Probe(); self.limit=p.attachmentLimit; self.split=p.split
 if not p.mail or not self.limit then return self:Fail(p.reason or 'Mail APIs are unavailable.') end
 self.batch={}; self.pending=nil; self.state='preparing'; self.deadline=c.Now()+10
 self.busy=true
 local called,ok,why=pcall(c.Begin,self.recipient,self.subject)
 self.busy=false
 if not called or not ok then return self:Fail(called and why or 'Mail preparation was blocked. Use the standard mail window.') end
 self:Pump()
 -- This path is entered ONLY by an actual button click. When preparation is
 -- asynchronous, Pump leaves us preparing and a later click must submit.
 if self.state=='ready' then return self:SubmitFromClick() end
 return self.state~='error',self.reason
end
function Q:Choose(stock)
 if stock.uncertain then self:Fail('Inventory data became unavailable. Unsent items remain in the mail window.'); return end
 local reserved,sourceReserved={},{}
 for _,b in ipairs(self.batch) do reserved[b.itemID]=(reserved[b.itemID] or 0)+b.count; sourceReserved[b.guid]=(sourceReserved[b.guid] or 0)+b.count end
 table.sort(stock,function(a,b) if a.itemID~=b.itemID then return a.itemID<b.itemID end; if a.bag~=b.bag then return a.bag<b.bag end; return a.slot<b.slot end)
 local blocked=false
 for _,id in ipairs(self.ids) do
  local held=reserved[id] or 0
  local available=math.max(0,totals(stock,id)-(self.keep[id] or 0))
  local need=math.min(math.max(0,self.quota[id]-held),available)
  self.quota[id]=held+need
  if need>0 then
   local locked=false
   for _,s in ipairs(stock) do
    if s.itemID==id and s.count>0 then
     if s.uncertain then self:Fail('Item eligibility became unavailable. Start a fresh transfer after item data loads.'); return end
     if s.locked then locked=true
     elseif s.eligible then
      local source=self.sources[s.guid]
      local permitted=source and source.identity==s.identity and math.max(0,source.count-(sourceReserved[s.guid] or 0)) or 0
      if permitted>0 then return s,math.min(s.count,need,permitted) end
     else self:Fail('A planned item is no longer eligible. Check the mail window before starting again.'); return end
    end
   end
   if locked then blocked=true else self:Fail('Original stacks changed, combined, or were replaced. Start a fresh transfer.'); return end
  end
 end
 return nil,nil,blocked
end
function Q:Pump()
 if self.busy or self.state~='preparing' then return end
 self.busy=true
 local ok,err=pcall(function()
  local c=self.client
  local allowed,reason=c.CanAct(); if not allowed then self:Fail(reason); return end
  local same,difference=self:MatchesDraft()
  if not same then self:Fail('Mail draft changed: '..difference..'. Check the mail window before continuing.'); return end
  if not c.CursorEmpty() then self:Fail('Cursor changed. Check your cursor and mail window.'); return end
  for _=1,self.limit+1 do
   local matches,complete,difference=self:MatchesAttachments(true)
   if not matches then self:Fail('Mail attachments changed. Unsent attachments remain in the mail window.',difference); return end
   local stock=self:AvailableStock()
   if not self:ValidateStock(stock) then return end
   if self.pending then
    if not complete then self.waitReason='Waiting for native attachment confirmation ('..#self.batch..' planned).'; return end
    self.pending=nil; self.waitReason=nil; self.deadline=c.Now()+10
   end
   if #self.batch>=self.limit then self.state='ready'; self:Notify(); return end
   local s,n,blocked=self:Choose(stock)
   if self.state=='error' then return end
   if not s then
    if blocked then return end
    self.state=#self.batch>0 and 'ready' or 'complete'
    if self.state=='complete' then self.reason='No eligible items remain in this transfer.' end
    self:Notify(); return
   end
   if n<s.count and not self.split then self:Fail('Partial stacks are unsupported; unsent items remain in the mail window.'); return end
   local b={itemID=s.itemID,count=n,identity=s.identity,link=s.link,guid=s.guid,before=s.count}
   self.batch[#self.batch+1]=b
   self.pending={itemID=s.itemID,count=n,before=totals(stock,s.itemID)}
   local attached,why=c.Attach(s,n)
   if not attached then self:Fail(why); return end
  end
 end)
 self.busy=false
 if not ok then self:Fail('A mail action was blocked or unavailable. Check the mail window; no automatic retry.',err); return end
 if self.state=='preparing' then self:Notify() end
end
function Q:SubmitFromClick()
 if self.state~='ready' then return false,'Wait for attachments to finish preparing.' end
 local c=self.client; local ok,why=c.CanAct()
 if not ok then return self:Fail(why) end
 local matches,complete=self:MatchesAttachments(false)
 if not matches or not complete or #self.batch==0 or not self:MatchesDraft() or not c.CursorEmpty() then return self:Fail('Mail contents changed. Check recipient and attachments before continuing.') end
 if not c.Affordable() then return self:Fail('Not enough money for postage. Unsent items remain in the mail window.') end
 local stock=self:AvailableStock()
 if not self:ValidateStock(stock) then return false,self.reason end
 for _,b in ipairs(self.batch) do
  if totals(stock,b.itemID)<(self.keep[b.itemID] or 0) then return self:Fail('Retained inventory changed. Check unsent attachments before starting again.') end
 end
 self.successCandidate=nil; self.state='awaiting-result'; self.deadline=c.Now()+30; self:Notify()
 self.inSubmit=true
 if A.History then A.History.Attempt(self) end
 local called,sent,reason=pcall(c.Submit,self.recipient,self.subject)
 self.inSubmit=false
 if not called or not sent then
  if A.History then A.History.Outcome(self,called and 'blocked' or 'uncertain',called and reason or 'Native send raised an error; outcome unknown.') end
  return self:Fail(called and reason or 'Sending was blocked. Check the mail window; no automatic retry.')
 end
 self:ReconcileResult()
 return true
end
function Q:Continue()
 if self.state=='ready' then return self:SubmitFromClick() end
 if self.state=='awaiting-click' then return self:PrepareFromClick() end
 return false,'This transfer is not ready for another click.'
end
function Q:Stop()
 if self.state=='stopping' then return end
 if self.state=='awaiting-result' then self.state='stopping'; self.reason='Stopping after the pending mail result.'
 elseif self:Active() then self.state='stopped'; self.pending=nil; self.reason='Stopped. Retrieve any unsent attachments from the mail window.' end
 self:Notify()
end
function Q:Tick(now)
 self:ReconcileResult()
 if (self.state=='preparing' or self.state=='awaiting-result' or self.state=='stopping') and now>self.deadline then
  return self:Fail('Mail operation timed out. Check the mail window and inbox before starting a fresh transfer; no automatic retry.')
 end
 if self.state=='preparing' then self:Pump() end
end
function Q:ReconcileResult()
 if self.inSubmit or not self.successCandidate or self.state~='awaiting-result' and self.state~='stopping' then return end
 local attachments=self.client.Attachments()
 if attachments.uncertain or #attachments>0 or self.client.CommandPending() then return end
 local stopping=self.state=='stopping'
 if A.History then A.History.Outcome(self,'accepted','Client confirmed acceptance. Recipient delivery is not independently verified.') end
 for _,b in ipairs(self.batch) do
  self.quota[b.itemID]=math.max(0,self.quota[b.itemID]-b.count)
  self.sources[b.guid].count=math.max(0,self.sources[b.guid].count-b.count)
 end
 self.successCandidate=nil; self.batch={}; self.sentMails=self.sentMails+1
 local left=self:GetStatus().remainingUnits
 self.state=stopping and 'stopped' or (left>0 and 'awaiting-click' or 'complete')
 self.reason=stopping and 'Stopped after the pending mail completed.' or nil
 self:Notify()
end
function Q:OnEvent(event,...)
 if event=='MAIL_CLOSED' then
  if A.History then A.History.Outcome(self,'uncertain','Mailbox closed before the send result was confirmed. Check the recipient inbox.') end
  if self:Active() then self.state='stopped'; self.reason='Mailbox closed. Check pending mail before starting again.'; self.pending=nil; self:Notify() end
 elseif event=='MAIL_FAILED' then
  if A.History then A.History.Outcome(self,'failed','The client reported MAIL_FAILED. Check the draft before retrying.') end
  if self:Active() then self:Fail('Mail failed. Check the recipient and retrieve unsent attachments before starting again.') end
 elseif event=='MAIL_SEND_SUCCESS' then
  if self.state~='awaiting-result' and self.state~='stopping' then return end
  -- These events have no transaction ID. Latch a candidate, then wait for
  -- both physical composer clearing and native command completion. Never
  -- submit another message here, even after a confirmed result.
  self.successCandidate=true; self:ReconcileResult()
 elseif event=='MAIL_SEND_INFO_UPDATE' or event=='BAG_UPDATE_DELAYED' then self:Pump() end
end
