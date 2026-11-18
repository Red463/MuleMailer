local _,A=...
local P={}
A.Planner=P
function P.Build(stacks,rules,recipient,limit,excluded)
 local plan={recipient=recipient,items={},skipped={},excluded={},totalUnits=0,totalStacks=0,estimatedMails=0}
 local groups,ids={},{}
 for _,s in ipairs(stacks) do
  local id=s.itemID
  if type(id)=='number' and type(s.count)=='number' and s.count>0 then
   if not groups[id] then groups[id]={total=0,eligible=0,stacks={},category=s.category,name=s.name}; ids[#ids+1]=id end
   local g=groups[id]; g.total=g.total+s.count
   if not g.category then g.category=s.category end
   if s.eligible and not s.locked then g.eligible=g.eligible+s.count; g.stacks[#g.stacks+1]=s
   else plan.skipped[#plan.skipped+1]={itemID=id,count=s.count,reason=s.reason or 'Item is locked'} end
  end
 end
 table.sort(ids)
 for _,id in ipairs(ids) do
  local g=groups[id]; local item=rules.items[id]; local cat=rules.categories[g.category]
  local selected=(item and item.mode=='always') or (cat and cat.enabled)
  if item and item.mode=='never' then selected=false end
  if selected then
   local keep=item and item.keep
   if keep==nil then keep=cat and cat.keep or 0 end
   local send=math.min(g.eligible,math.max(0,g.total-keep))
   if send>0 then
    local row={itemID=id,name=g.name,send=send,keep=math.min(keep,g.total),retained=g.total-send,category=g.category,sources={}}
    for _,s in ipairs(g.stacks) do
     if s.guid and s.identity then row.sources[s.guid]={count=s.count,identity=s.identity} end
    end
    if excluded and excluded[id] then
     row.retained=g.total; row.send=0; row.reason='Excluded for this mailbox visit'; plan.excluded[#plan.excluded+1]=row
    else
    plan.items[#plan.items+1]=row; plan.totalUnits=plan.totalUnits+send
    local sorted={}; for _,s in ipairs(g.stacks) do sorted[#sorted+1]=s end
    table.sort(sorted,function(a,b) if a.bag~=b.bag then return a.bag<b.bag end; return a.slot<b.slot end)
    local left=send
    for _,s in ipairs(sorted) do if left>0 then plan.totalStacks=plan.totalStacks+1; left=left-math.min(left,s.count) end end
    end
   elseif g.eligible>0 then plan.skipped[#plan.skipped+1]={itemID=id,count=g.eligible,category=g.category,reason='Keeping your minimum ('..keep..')'} end
  elseif g.eligible>0 then
   plan.skipped[#plan.skipped+1]={itemID=id,count=g.eligible,category=g.category,reason=item and item.mode=='never' and 'Never send rule' or g.category and 'Material category is not selected' or 'No matching category; add an item rule'}
  end
 end
 if limit and limit>0 then plan.estimatedMails=math.ceil(plan.totalStacks/limit) end
 return plan
end
function P.BuildRoutes(stacks,cfg,limit,excluded)
 local groups,keys={},{}; local categories={}
 for _,s in ipairs(stacks) do categories[s.itemID]=categories[s.itemID] or s.category end
 local routes=cfg.routes or {}; local itemRoutes=routes.items or {}; local categoryRoutes=routes.categories or {}
 for _,s in ipairs(stacks) do
  local recipient=itemRoutes[s.itemID] or categoryRoutes[categories[s.itemID]] or cfg.recipient or ''
  if not groups[recipient] then groups[recipient]={}; keys[#keys+1]=recipient end
  groups[recipient][#groups[recipient]+1]=s
 end
 if #keys==0 then keys={cfg.recipient or ''}; groups[keys[1]]={} end
 table.sort(keys)
 local out,unused={},{}
 for _,key in ipairs(keys) do
  local p=P.Build(groups[key],cfg.rules,key~='' and key or nil,limit,excluded)
  p.subject=cfg.sending.subject or 'Mule Mailer'; p.presetName=cfg.presetName or 'Default'; p.presetID=cfg.presetID
  for _,s in ipairs(p.skipped) do s.category=categories[s.itemID] end
  if p.totalUnits>0 or #p.excluded>0 then out[#out+1]=p else unused[#unused+1]=p end
 end
 if #out==0 then out[1]=table.remove(unused,1) end
 for _,p in ipairs(unused) do for _,s in ipairs(p.skipped) do out[1].skipped[#out[1].skipped+1]=s end end
 return out
end
