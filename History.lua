local _,A=...
local H={limit=500}; A.History=H
local function data()
 if not A.db or A.db.version~=1 then return nil end
 A.db.history=A.db.history or {nextID=0,entries={}}
 return A.db.history
end
local function stamp(client)
 if client and client.Timestamp then return client.Timestamp() end
 return time and time() or nil
end
function H.Money(copper)
 if type(copper)~='number' then return 'Unavailable' end
 local gold=math.floor(copper/10000); local silver=math.floor(copper/100)%100; local c=copper%100
 if gold>0 then return gold..'g '..silver..'s '..c..'c' end
 return silver>0 and silver..'s '..c..'c' or c..'c'
end
function H.When(value)
 return value and date and date('%d %b %Y %H:%M:%S',value) or value and tostring(value) or 'Time unavailable'
end
function H.Attempt(queue)
 local db=data(); if not db then return end
 local client=queue.client; local ctx=client.GetContext and client.GetContext() or A.context or {}
 local record={sender=A.Store.Normalize(ctx.name,ctx.realm) or ctx.name or 'Unknown',senderGUID=ctx.characterID,faction=ctx.faction,recipient=queue.recipient,subject=queue.subject,preset=queue.presetName or 'Default',submittedAt=stamp(client),outcome='pending',items={},totalUnits=0,totalStacks=#queue.batch}
 if client.Postage then record.postage=client.Postage() end
 for i,b in ipairs(queue.batch) do
  local display=client.ItemDisplay and client.ItemDisplay(b.itemID) or {}
  record.items[i]={itemID=b.itemID,count=b.count,identity=b.identity,link=b.link or b.identity,name=display.name or 'Item '..b.itemID,icon=display.icon,sourceGUID=b.guid,slot=i}
  record.totalUnits=record.totalUnits+b.count
 end
 db.nextID=db.nextID+1; record.id=db.nextID
 table.insert(db.entries,1,record); while #db.entries>H.limit do table.remove(db.entries) end
 queue.historyRecord=record
end
function H.Outcome(queue,outcome,reason)
 local record=queue.historyRecord
 if not record or record.outcome~='pending' then return end
 record.outcome=outcome; record.reason=reason; record.finishedAt=stamp(queue.client)
end
function H.Recover()
 local db=data(); if not db then return end
 for _,record in ipairs(db.entries) do
  if record.outcome=='pending' then record.outcome='uncertain'; record.reason='Client reloaded before the send result was confirmed. Check the recipient inbox.'; record.finishedAt=stamp(A.Client) end
 end
end
function H.Search(query,outcome)
 local db=data(); local out={}; query=(query or ''):lower()
 for _,record in ipairs(db and db.entries or {}) do
  if not outcome or outcome=='all' or record.outcome==outcome then
   local fields={record.sender or '',record.recipient or '',record.subject or '',record.preset or '',tostring(record.id),record.reason or ''}
   for _,item in ipairs(record.items or {}) do fields[#fields+1]=(item.name or '')..' '..item.itemID..' '..(item.link or '') end
   if query=='' or table.concat(fields,' '):lower():find(query,1,true) then out[#out+1]=record end
  end
 end
 return out
end
function H.Clear()
 local db=data(); if not db then return false end
 db.entries={}; return true
end
