local _,A=...
local S={}
A.Store=S
function S.Copy(v)
 if type(v)~='table' then return v end
 local out={}; for k,x in pairs(v) do out[k]=S.Copy(x) end; return out
end
local function defaults()
 local rules={categories={},items={}}
 for _,row in ipairs(A.Categories.list) do rules.categories[row[1]]={enabled=false,keep=0} end
 return rules
end
function S.Init(db)
 if type(db)~='table' then db={} end
 if db.version and db.version~=1 then return db end
 db.version=1; db.contexts=db.contexts or {}; db.characters=db.characters or {}
 db.display=db.display or {autoShow=true,compact=false}
 db.sending=db.sending or {review=false,completion=true,subject='Mule Mailer'}
 if db.sending.postage==nil then db.sending.postage=true end
 db.presets=db.presets or {}; db.nextPresetID=db.nextPresetID or 0
 return db
end
local function writable(db) return type(db)=='table' and db.version==1 end
local function factionOf(ctx)
 return ctx.faction or (ctx.key and ctx.key:match(':([^:]+)$')) or 'Unknown'
end
function S.ScopeKey(ctx) return 'forever:'..factionOf(ctx) end
local function ruleSignature(rules)
 if type(rules)~='table' then return '' end
 local parts={}; local configured=false
 for _,row in ipairs(A.Categories.list) do
  local value=rules.categories and rules.categories[row[1]] or {}
  local enabled=value.enabled and true or false; local keep=value.keep or 0
  parts[#parts+1]=row[1]..':'..tostring(enabled)..':'..tostring(keep)
  configured=configured or enabled or keep~=0
 end
 local ids={}; for id in pairs(rules.items or {}) do ids[#ids+1]=id end; table.sort(ids)
 for _,id in ipairs(ids) do local item=rules.items[id]; parts[#parts+1]=id..':'..tostring(item.mode)..':'..tostring(item.keep); configured=true end
 return configured and table.concat(parts,';') or ''
end
local function migrateScope(db,ctx)
 local key=S.ScopeKey(ctx)
 if db.contexts[key] and db.contexts[key].scope=='forever' then return db.contexts[key] end
 local faction=factionOf(ctx); local keys={}
 for oldKey in pairs(db.contexts) do if oldKey:match(':([^:]+)$')==faction then keys[#keys+1]=oldKey end end
 table.sort(keys)
 local shared={scope='forever',rules=defaults()}; local recipients={}; local signatures={}; local ruleCount=0
 for _,oldKey in ipairs(keys) do
  local source=db.contexts[oldKey]
  if source.recipient and source.recipient~='' then
   local candidate=S.Normalize(source.recipient) or source.recipient
   local found=false
   for _,recipient in ipairs(recipients) do
    local same=type(strcmputf8i)=='function' and strcmputf8i(recipient,candidate)==0 or recipient:lower()==candidate:lower()
    if same then found=true end
   end
   if not found then recipients[#recipients+1]=candidate end
  end
  local signature=ruleSignature(source.rules)
  if signature~='' and not signatures[signature] then
   signatures[signature]=true; ruleCount=ruleCount+1
   if ruleCount==1 or oldKey==ctx.key then shared.rules=S.Copy(source.rules) end
  end
 end
 if #recipients==1 then shared.recipient=recipients[1]
 elseif #recipients>1 then shared.warning='Multiple saved bank characters were found. Choose the shared bank character in Options.' end
 for _,char in pairs(db.characters) do
  local old=db.contexts[char.contextKey]
  local characterFaction=char.faction or char.contextKey and char.contextKey:match(':([^:]+)$')
  if characterFaction==faction then
   -- Preserve differing selections as character overrides instead of losing
   -- configuration when several previous scopes contain distinct rules.
   if not char.rules and old and old.rules and ruleSignature(old.rules)~=ruleSignature(shared.rules) then char.rules=S.Copy(old.rules) end
   char.contextKey=key; char.faction=faction
  end
 end
 if db.contexts[key] then
  db.scopeBackups=db.scopeBackups or {}
  if not db.scopeBackups[key] then db.scopeBackups[key]=S.Copy(db.contexts[key]) end
 end
 db.contexts[key]=shared
 return shared
end
local function rows(db,ctx)
 local shared=migrateScope(db,ctx)
 db.characters[ctx.characterID]=db.characters[ctx.characterID] or {}
 local char=db.characters[ctx.characterID]
 char.name=ctx.name; char.realm=ctx.realm; char.contextKey=S.ScopeKey(ctx); char.faction=factionOf(ctx)
 shared.rules=shared.rules or defaults()
 shared.routes=shared.routes or {categories={},items={}}
 for _,row in ipairs(A.Categories.list) do
  shared.rules.categories[row[1]]=shared.rules.categories[row[1]] or {enabled=false,keep=0}
 end
 return shared,char
end
local function preset(db,ctx,char)
 local entries=db.presets and db.presets[S.ScopeKey(ctx)]
 return entries and entries[char.presetID]
end
function S.Resolve(db,ctx)
 if not writable(db) then return {rules=defaults(),ruleSource='Unavailable',error='Saved settings use an unsupported version; no changes have been made.',display={autoShow=true},sending={}} end
 local shared,char=rows(db,ctx)
 if shared.recipient then shared.recipient=S.Normalize(shared.recipient) or shared.recipient end
 if char.recipient then char.recipient=S.Normalize(char.recipient) or char.recipient end
 local profile=preset(db,ctx,char); local sending=S.Copy(db.sending)
 if profile then sending.subject=profile.subject or 'Mule Mailer' end
 local recipient=char.recipient or shared.recipient; if profile then recipient=profile.recipient end
 return {recipient=recipient,rules=profile and profile.rules or char.rules or shared.rules,ruleSource=profile and 'Preset' or char.rules and 'Character' or 'Shared',recipientSource=profile and 'Preset' or char.recipient and 'Character' or 'Shared',display=db.display,sending=sending,warning=shared.warning,routes=profile and profile.routes or shared.routes,presetID=profile and char.presetID or nil,presetName=profile and profile.name or 'Default'}
end
function S.Normalize(text,surname)
 if type(text)~='string' then return nil end
 text=text:match('^%s*(.-)%s*$')
 if text=='' then return nil end
 local first,last=text:match('^([^%-]+)%-(.+)$')
 if first then
  first=first:match('^%s*(.-)%s*$'); last=last:gsub('%s','')
 else
  first,last=text:match('^(%S+)%s+(%S+)$')
  if not first then first=text; last=surname and surname:gsub('%s','') end
 end
 local function valid(part)
  if not part or part=='' then return false end
  for i=1,#part do local b=part:byte(i); if b<128 and not (b>=65 and b<=90 or b>=97 and b<=122) then return false end end
  return true
 end
 if not valid(first) or last and not valid(last) then return nil end
 return last and first..' '..last or first
end
function S.IsSelf(recipient,ctx)
 local other=S.Normalize(recipient)
 if not other then return false end
 if not other:find(' ',1,true) then
  if type(strcmputf8i)=='function' then return strcmputf8i(other,ctx.name)==0 end
  return other:lower()==ctx.name:lower()
 end
 return S.SameRecipient(other,S.Normalize(ctx.name,ctx.realm))
end
function S.SameRecipient(expected,actual)
 local function canonical(value)
  if type(value)~='string' or issecretvalue and issecretvalue(value) then return nil end
  value=value:match('^%s*(.-)%s*$'):gsub('%s*%-%s*','-')
  return S.Normalize(value)
 end
 local a,b=canonical(expected),canonical(actual)
 if not a or not b then return false end
 if type(strcmputf8i)=='function' then return strcmputf8i(a,b)==0 end
 return a:lower()==b:lower()
end
-- Forever mail uses the complete first name and surname, separated by a space.
function S.RecipientLabel(recipient)
 return S.Normalize(recipient) or recipient or ''
end
function S.SetRecipient(db,ctx,value,override)
 if not writable(db) then return false,'Unsupported saved settings version.' end
 local recipient=S.Normalize(value)
 if not recipient then return false,'Enter the full character name, for example Mosswick Moneybags.' end
 if S.IsSelf(recipient,ctx) then return false,'Choose another character; this is your bank alt.' end
 local shared,char=rows(db,ctx)
 local profile=preset(db,ctx,char)
 if profile then profile.recipient=recipient elseif override then char.recipient=recipient else shared.recipient=recipient; shared.warning=nil end
 return true
end
function S.UseSharedRecipient(db,ctx)
 if not writable(db) then return false end
 local _,char=rows(db,ctx); char.recipient=nil; return true
end
function S.UseSharedRules(db,ctx)
 if not writable(db) then return false end
 local _,char=rows(db,ctx); char.rules=nil; return true
end
function S.CopySharedRules(db,ctx)
 if not writable(db) then return false end
 local shared,char=rows(db,ctx); char.rules=S.Copy(shared.rules); return true
end
function S.ValidKeep(v) return type(v)=='number' and v>=0 and v==math.floor(v) and v<=2147483647 end
function S.SetRule(db,ctx,kind,key,value)
 if not writable(db) then return false,'Unsupported saved settings version.' end
 local shared,char=rows(db,ctx); local profile=preset(db,ctx,char); local rules=profile and profile.rules or char.rules or shared.rules
 if kind=='item' then
  if type(key)~='number' or key<=0 or key>2147483647 or key~=math.floor(key) then return false,'Enter a positive whole item ID up to 2147483647.' end
  if value==nil then rules.items[key]=nil; return true end
  if value.mode~='always' and value.mode~='never' then return false,'Choose Always send or Never send.' end
  if value.keep~=nil and not S.ValidKeep(value.keep) then return false,'Keep must be a nonnegative whole number.' end
  rules.items[key]={mode=value.mode,keep=value.keep}
 elseif kind=='category' then
  if not rules.categories[key] or type(value)~='table' or type(value.enabled)~='boolean' or not S.ValidKeep(value.keep) then return false,'Keep must be a nonnegative whole number.' end
  rules.categories[key]={enabled=value.enabled,keep=value.keep}
 else return false,'Unknown rule type.' end
 return true
end
-- Registering the bank character itself is intentionally separate from sending
-- validation: the bank must be able to save its own identity for other alts.
function S.RegisterBank(db,ctx,override)
 if not writable(db) then return false,'Unsupported saved settings version.' end
 local shared,char=rows(db,ctx); local name=S.Normalize(ctx.name,ctx.realm)
 local profile=preset(db,ctx,char)
 if profile then profile.recipient=name elseif override then char.recipient=name else shared.recipient=name; shared.warning=nil end
 return true
end
function S.ListPresets(db,ctx)
 local out={}
 for id,p in pairs(db.presets and db.presets[S.ScopeKey(ctx)] or {}) do out[#out+1]={id=id,name=p.name} end
 table.sort(out,function(a,b) return a.name:lower()<b.name:lower() end); return out
end
local function validName(db,ctx,name,except)
 if type(name)~='string' then return nil end
 name=name:match('^%s*(.-)%s*$')
 if name=='' or #name>48 or name:find('[%c|]') or name:lower()=='default' then return nil end
 for _,p in ipairs(S.ListPresets(db,ctx)) do if p.id~=except and p.name:lower()==name:lower() then return nil end end
 return name
end
function S.CreatePreset(db,ctx,name)
 if not writable(db) then return false,'Unsupported saved settings version.' end
 name=validName(db,ctx,name)
 if not name then return false,'Choose a unique preset name (1–48 characters), other than Default.' end
 local cfg=S.Resolve(db,ctx); local _,char=rows(db,ctx)
 db.nextPresetID=db.nextPresetID+1; local id=tostring(db.nextPresetID); local key=S.ScopeKey(ctx)
 db.presets[key]=db.presets[key] or {}
 db.presets[key][id]={name=name,recipient=cfg.recipient,rules=S.Copy(cfg.rules),routes=S.Copy(cfg.routes),subject=cfg.sending.subject or 'Mule Mailer'}
 char.presetID=id; return true,id
end
function S.SelectPreset(db,ctx,id)
 if not writable(db) then return false,'Unsupported saved settings version.' end
 if id and not (db.presets[S.ScopeKey(ctx)] and db.presets[S.ScopeKey(ctx)][id]) then return false,'Preset not found.' end
 local _,char=rows(db,ctx); char.presetID=id; return true
end
function S.RenamePreset(db,ctx,id,name)
 if not writable(db) then return false,'Unsupported saved settings version.' end
 name=validName(db,ctx,name,id); local p=db.presets[S.ScopeKey(ctx)] and db.presets[S.ScopeKey(ctx)][id]
 if not name or not p then return false,'Choose an existing preset and a unique name.' end
 p.name=name; return true
end
function S.DeletePreset(db,ctx,id)
 if not writable(db) then return false,'Unsupported saved settings version.' end
 local entries=db.presets[S.ScopeKey(ctx)]
 if not entries or not entries[id] then return false,'Select a saved preset first.' end
 entries[id]=nil
 for _,char in pairs(db.characters) do if char.contextKey==S.ScopeKey(ctx) and char.presetID==id then char.presetID=nil end end
 return true
end
function S.SetSubject(db,ctx,value)
 if not writable(db) then return false,'Unsupported saved settings version.' end
 if type(value)~='string' or not value:find('%S') or value:find('[%c]') then return false,'Enter a mail subject without control characters.' end
 local _,char=rows(db,ctx); local p=preset(db,ctx,char)
 if p then p.subject=value else db.sending.subject=value end
 return true
end
function S.SetDestination(db,ctx,kind,key,value)
 if not writable(db) then return false,'Unsupported saved settings version.' end
 local shared,char=rows(db,ctx); local p=preset(db,ctx,char)
 if kind=='category' then
  if not shared.rules.categories[key] then return false,'Unknown material category.' end
 elseif kind~='item' or type(key)~='number' or key<1 or key~=math.floor(key) then return false,'Enter a positive item ID.' end
 local recipient=value and value:match('%S') and S.Normalize(value) or nil
 if value and value:match('%S') and not recipient then return false,'Enter the full character name.' end
 if recipient and S.IsSelf(recipient,ctx) then return false,'Choose another character as destination.' end
 local routes=p and p.routes or shared.routes
 routes[kind=='item' and 'items' or 'categories'][key]=recipient; return true
end
