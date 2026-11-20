function queueFixture(count,limit)
 local A={}; module('Categories',A); module('Store',A); module('Planner',A); module('MailQueue',A)
 local ctx={name='Alice',realm='Realm'}
 local f={time=0,open=true,cursor=true,stock={},attached={},log={},recipient='',subject='',body='',money=0,cod=false,affordable=true,limit=limit or 1}
 for i=1,(count or 3) do f.stock[i]={bag=0,slot=i,itemID=2447,count=20,eligible=true,category='herbs',guid='original-'..i,identity='item:2447:0'} end
 local c={}
 c.Now=function() return f.time end
 c.CommandPending=function() return f.commandPending or false end
 c.GetContext=function() return ctx end
 c.Probe=function() return {mail=true,attachmentLimit=f.limit,split=true} end
 c.CanAct=function() return f.open,f.open and nil or 'Closed' end
 c.CursorEmpty=function() return f.cursor end
 c.Snapshot=function() return A.Store.Copy(f.stock) end
 c.Attachments=function() return A.Store.Copy(f.attached) end
 c.Draft=function() return {recipient=f.recipient,subject=f.subject,body=f.body,money=f.money,cod=f.cod,attachments=c.Attachments()} end
 c.HasManualDraft=function() return f.recipient~='' or #f.attached>0 or f.money>0 or f.body~='' end
 c.Affordable=function() return f.affordable end
 c.Begin=function(to,subject)
  if c.HasManualDraft() then return false,'Draft exists' end
  f.recipient=to; f.subject=subject; return true
 end
 c.Attach=function(s,n)
  if f.attachFailure then return false,'Pickup failed' end
  local match
  for i,x in ipairs(f.stock) do if x.bag==s.bag and x.slot==s.slot then match=x; break end end
  assert(match and match.count>=n)
  match.count=match.count-n
  local entry={index=#f.attached+1,itemID=s.itemID,count=n,identity=s.identity}
  if f.async then f.pending=entry else f.attached[#f.attached+1]=entry end
  return true
 end
 c.Submit=function(to,subject)
  f.commandPending=true
  f.log[#f.log+1]={recipient=to,subject=subject,attachments=c.Attachments(),money=f.money,cod=f.cod}
  return true
 end
 f.success=function(q)
  f.commandPending=false
  f.attached={}; f.recipient=''; f.subject=''; f.body=''
  q:OnEvent('MAIL_SEND_SUCCESS')
 end
 local rules={categories={herbs={enabled=true,keep=0}},items={}}
 local p=A.Planner.Build(c.Snapshot(),rules,'Bank-Realm',f.limit)
 p.subject='Postly'
 return A,A.MailQueue.New(c,function() end),f,p,c
end
test('one click sends a verified synchronous batch with no gold or COD',function()
 local _,q,f,p=queueFixture(1,12); assert(q:Start(p)); eq(#f.log,1); eq(q:GetStatus().state,'awaiting-result')
 eq(f.log[1].recipient,'Bank Realm'); eq(f.log[1].money,0); eq(f.log[1].cod,false)
 f.success(q); eq(q:GetStatus().state,'complete'); eq(q:GetStatus().sentMails,1)
end)
test('native recipient formatting during attachment does not stop the batch',function()
 local _,q,f,p,c=queueFixture(3,12); local attach=c.Attach; f.async=true
 c.Attach=function(s,n) local ok,why=attach(s,n); f.recipient=' bank - Realm '; return ok,why end
 q:Start(p); f.attached={f.pending}; f.pending=nil; f.async=false
 q:Tick(1); eq(#f.attached,3); eq(#f.log,0); eq(q.state,'ready')
 q:Continue(); eq(#f.log,1); eq(f.log[1].recipient,'Bank Realm')
end)
test('mail attachments may remain locked in bag snapshots until the mail is sent',function()
 local _,q,f,p,c=queueFixture(5,12)
 c.Attach=function(s,n)
  for _,raw in ipairs(f.stock) do if raw.guid==s.guid then raw.locked=true end end
  f.attached[#f.attached+1]={index=#f.attached+1,itemID=s.itemID,count=n,identity=s.identity}
  return true
 end
 q:Start(p); eq(#f.attached,5); eq(#f.log,1); eq(q.state,'awaiting-result')
 for _,raw in ipairs(f.stock) do eq(raw.count,20) end
end)
test('bag-echo reservations preserve keep quantities and detect lost retained stock',function()
 for _,lost in ipairs({false,true}) do
  local _,q,f,p,c=queueFixture(1,12); f.stock[1].count=53; p.items[1].sources['original-1'].count=53; p.items[1].send=33; p.items[1].keep=20; p.totalUnits=33
  c.Attach=function(s,n)
   f.stock[1].locked=true
   f.pending={index=1,itemID=s.itemID,count=n,identity=s.identity}; return true
  end
  q:Start(p); eq(#f.log,0)
  f.attached={f.pending}; f.pending=nil
  if lost then f.stock[1].count=43 end
  q:Tick(1); q:Continue()
  if lost then eq(#f.log,0); eq(q.state,'error') else eq(#f.log,1); eq(f.log[1].attachments[1].count,33) end
 end
end)
test('every queue failure records a cached diagnostic, including attachment and Lua errors',function()
 local A,q,f,p,c=queueFixture(1,12); f.async=true; q:Start(p)
 f.attached={{index=1,itemID=999,count=20,identity='item:999'}}; q:Tick(1)
 assert(A.draftDiagnostic and A.draftDiagnostic:find('attachments'))
 local B,q2,f2,p2,c2=queueFixture(1,12)
 c2.Attach=function() error('simulated native update failure') end
 q2:Start(p2); assert(B.draftDiagnostic and B.draftDiagnostic:find('simulated native update failure'))
end)
test('each later batch needs another click and duplicate events do nothing',function()
 local _,q,f,p=queueFixture(3,1); q:Start(p); f.success(q)
 eq(q:GetStatus().state,'awaiting-click'); eq(#f.log,1)
 q:OnEvent('MAIL_SEND_SUCCESS'); q:Tick(1); eq(#f.log,1); eq(q:GetStatus().sentMails,1)
 assert(q:Continue()); eq(#f.log,2)
 f.success(q); q:Continue(); f.success(q); eq(#f.log,3); eq(q:GetStatus().state,'complete')
end)
test('asynchronous preparation never sends from an event or timer',function()
 local _,q,f,p=queueFixture(1,12); f.async=true; q:Start(p); eq(#f.log,0); eq(q:GetStatus().state,'preparing')
 f.attached={f.pending}; f.pending=nil; q:OnEvent('MAIL_SEND_INFO_UPDATE'); q:Tick(1)
 eq(q:GetStatus().state,'ready'); eq(#f.log,0)
 q:Continue(); eq(#f.log,1)
end)
test('stop while a mail is pending waits and submits no more',function()
 local _,q,f,p=queueFixture(); q:Start(p); q:Stop(); eq(q:GetStatus().state,'stopping')
 f.success(q); eq(q:GetStatus().state,'stopped'); eq(#f.log,1)
end)
test('mailbox closure failure and timeout never retry',function()
 for _,event in ipairs({'MAIL_CLOSED','MAIL_FAILED','timeout'}) do
  local _,q,f,p=queueFixture(); q:Start(p)
  if event=='timeout' then f.time=31; q:Tick(f.time) else q:OnEvent(event) end
  q:Tick(99); eq(#f.log,1); assert(q:GetStatus().state=='error' or q:GetStatus().state=='stopped')
 end
end)
test('manual draft cursor self recipient and postage block preparation',function()
 for _,mode in ipairs({'draft','cursor','self','postage'}) do
  local _,q,f,p=queueFixture()
  if mode=='draft' then f.body='my letter' elseif mode=='cursor' then f.cursor=false elseif mode=='self' then p.recipient='Alice-Realm' else f.affordable=false end
  assert(not q:Start(p)); eq(#f.log,0); eq(#f.attached,0)
 end
end)
test('changed attachments body recipient money or COD stop before sending',function()
 for _,mode in ipairs({'attachment','body','recipient','money','cod'}) do
  local _,q,f,p=queueFixture(1,12); f.async=true; q:Start(p)
  f.attached={f.pending}; f.pending=nil; q:Tick(1); eq(q:GetStatus().state,'ready')
  if mode=='attachment' then f.attached[1].count=999 elseif mode=='body' then f.body='my letter' elseif mode=='recipient' then f.recipient='SomeoneElse-Realm' elseif mode=='money' then f.money=1 else f.cod=true end
  assert(not q:Continue()); eq(#f.log,0); eq(q:GetStatus().state,'error')
 end
end)
test('bag moves are revalidated and new stock never increases frozen quota',function()
 local _,q,f,p=queueFixture(2,1); q:Start(p); f.success(q)
 f.stock[2].slot=8; f.stock[#f.stock+1]={bag=0,slot=9,itemID=2447,count=200,eligible=true,category='herbs'}
 q:Continue(); f.success(q); eq(q:GetStatus().state,'complete'); eq(#f.log,2)
 eq(f.stock[3].count,200)
end)
test('keep quantity survives diminished inventory between batches',function()
 local _,q,f,p=queueFixture(3,1); p.items[1].send=40; p.items[1].keep=20; p.totalUnits=40
 q:Start(p); f.success(q); f.stock[2].count=5; f.stock[3].count=20
 q:Continue(); eq(f.log[2].attachments[1].count,5)
 f.success(q); eq(q:GetStatus().state,'complete'); eq(f.stock[3].count,20)
end)
test('failed pickup unsupported split and locked items cannot submit',function()
 local _,q,f,p,c=queueFixture(1,12); f.attachFailure=true; assert(not q:Start(p)); eq(#f.log,0)
 local _,q2,f2,p2,c2=queueFixture(1,12); p2.items[1].send=3; p2.items[1].keep=17; c2.Probe=function() return {mail=true,split=false,attachmentLimit=12} end
 assert(not q2:Start(p2)); eq(#f2.log,0)
 local _,q3,f3,p3=queueFixture(1,12); f3.stock[1].locked=true; q3:Start(p3); eq(#f3.log,0); f3.time=11; q3:Tick(11); eq(q3:GetStatus().state,'error')
end)
test('a stale success while attachments still exist does not acknowledge current submission',function()
 local _,q,f,p=queueFixture(2,1); q:Start(p); q:OnEvent('MAIL_SEND_SUCCESS')
 eq(q:GetStatus().sentMails,0); eq(q:GetStatus().state,'awaiting-result')
end)
test('losing retained materials after preparation blocks submission',function()
 local _,q,f,p=queueFixture(2,12); p.items[1].send=20; p.items[1].keep=20; p.totalUnits=20; f.async=true
 q:Start(p); f.attached={f.pending}; f.pending=nil; q:Tick(1); eq(q:GetStatus().state,'ready')
 f.stock[2].count=3
 assert(not q:Continue()); eq(#f.log,0)
end)

test('percentage reserve remains fixed across queue batches',function()
 local A,q,f,p,c=queueFixture(3,1)
 local rules={categories={herbs={enabled=true,keep='20%'}},items={}}
 p=A.Planner.Build(c.Snapshot(),rules,'Bank Realm',1); p.subject='Materials'
 eq(p.items[1].keep,12); eq(p.totalUnits,48)
 q:Start(p); eq(#f.log,1); eq(q.keep[2447],12)
 f.success(q); q:Continue(); eq(#f.log,2); eq(q.keep[2447],12)
 f.success(q); q:Continue(); eq(#f.log,3); eq(f.log[3].attachments[1].count,8)
 f.success(q); eq(q.state,'complete'); eq(f.stock[3].count,12)
end)
