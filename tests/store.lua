local function setup()
 local A={}; module('Categories',A); module('Store',A)
 local ctx={key='realm:Alliance',characterID='one',name='Alice',realm='Test Realm',faction='Alliance'}
 return A,A.Store.Init(),ctx
end
test('configuration defaults empty and overrides copy independently',function()
 local A,db,c=setup(); local r=A.Store.Resolve(db,c)
 eq(r.recipient,nil); eq(r.rules.categories.herbs.enabled,false)
 assert(A.Store.SetRule(db,c,'category','herbs',{enabled=true,keep=20}))
 A.Store.CopySharedRules(db,c)
 assert(A.Store.SetRule(db,c,'category','herbs',{enabled=false,keep=7}))
 eq(A.Store.Resolve(db,c).rules.categories.herbs.keep,7)
 local other={key=c.key,characterID='two',name='Bob',realm=c.realm,faction=c.faction}
 eq(A.Store.Resolve(db,other).rules.categories.herbs.keep,20)
 local alien={key='other:Horde',characterID='three',name='Bob',realm='Other',faction='Horde'}
 eq(A.Store.Resolve(db,alien).rules.categories.herbs.enabled,false)
end)
test('recipient and rule override scopes are independent and persistent',function()
 local A,db,c=setup(); assert(A.Store.SetRecipient(db,c,'Banker',false))
 eq(A.Store.Resolve(db,c).recipient,'Banker')
 assert(A.Store.SetRecipient(db,c,'Vault-Other Realm',true))
 eq(A.Store.Resolve(db,c).recipient,'Vault OtherRealm')
 local restored=A.Store.Init(db); eq(A.Store.Resolve(restored,c).recipient,'Vault OtherRealm')
 eq(A.Store.Resolve(db,c).ruleSource,'Shared')
end)
test('recipient validates self names and preserves localized names',function()
 local A,db,c=setup()
 assert(not A.Store.SetRecipient(db,c,'alice-Test Realm',false))
 assert(not A.Store.SetRecipient(db,c,'bad|name',false))
 assert(A.Store.SetRecipient(db,c,'Élodie-Test Realm',false)); eq(A.Store.Resolve(db,c).recipient,'Élodie TestRealm')
end)
test('invalid keep edits do not replace valid rules and modes are exclusive',function()
 local A,db,c=setup()
 assert(A.Store.SetRule(db,c,'item',2447,{mode='always',keep=20}))
 assert(not A.Store.SetRule(db,c,'item',2447,{mode='never',keep=-1}))
 assert(not A.Store.SetRule(db,c,'category','herbs',{enabled=true,keep=0.5}))
 eq(A.Store.Resolve(db,c).rules.items[2447].mode,'always')
 assert(A.Store.SetRule(db,c,'item',2447,{mode='never'})); eq(A.Store.Resolve(db,c).rules.items[2447].mode,'never')
end)
test('future saved schema stays untouched and blocks writes',function()
 local A,_,c=setup(); local future={version=99,precious='yes'}
 eq(A.Store.Init(future),future); assert(not A.Store.SetRecipient(future,c,'Banker',false)); eq(future.precious,'yes')
end)
test('material categories use metadata and audited mining exceptions',function()
 local A=setup()
 for _,row in ipairs({{2447,7,9,'herbs'},{2770,7,7,'ore'},{2840,7,7,'bars'},{2835,7,7,'stone'},{2318,7,6,'leather'},{2589,7,5,'cloth'},{10940,7,12,'enchanting'},{818,7,11,'gems'},{2672,7,8,'cooking'}}) do
  eq(A.Categories.Classify(row[1],row[2],row[3]),row[4])
 end
 eq(A.Categories.Classify(999999,7,7),nil); eq(A.Categories.Classify(999999,2,0),nil)
 eq(A.Categories.Classify(12360,7,7),'bars'); eq(A.Categories.Classify(12655,7,7),'bars')
end)
test('item IDs reject infinite and out-of-range values',function()
 local A,db,c=setup()
 assert(not A.Store.SetRule(db,c,'item',math.huge,{mode='always'}))
 assert(not A.Store.SetRule(db,c,'item',2147483648,{mode='always'}))
end)
test('same-realm recipient displays as a name while keeping internal validation',function()
 local A,db,c=setup()
 assert(A.Store.SetRecipient(db,c,'Banker',false))
 eq(A.Store.RecipientLabel(A.Store.Resolve(db,c).recipient,c.realm),'Banker')
 eq(A.Store.RecipientLabel('Vault-OtherRealm',c.realm),'Vault OtherRealm')
end)
test('saved bank recipient is recovered across Forever character identity suffixes',function()
 local A,_,c=setup()
 local bankRules=A.Store.Resolve(A.Store.Init(),c).rules
 local mainRules=A.Store.Copy(bankRules); mainRules.categories.herbs={enabled=true,keep=20}
 local db=A.Store.Init({version=1,contexts={
  ['moneybags:Alliance']={recipient='Mosswick-Moneybags',rules=bankRules},
  ['eppingworth:Alliance']={rules=mainRules},
 },characters={
  bank={name='Mosswick',realm='Moneybags',contextKey='moneybags:Alliance'},
  main={name='Eryndor',realm='Eppingworth',contextKey='eppingworth:Alliance'},
 }})
 local main={key='eppingworth:Alliance',characterID='main',name='Eryndor',realm='Eppingworth',faction='Alliance'}
 local result=A.Store.Resolve(db,main)
 eq(result.recipient,'Mosswick Moneybags'); eq(result.rules.categories.herbs.keep,20)
 local bank={key='moneybags:Alliance',characterID='bank',name='Mosswick',realm='Moneybags',faction='Alliance'}
 eq(A.Store.Resolve(db,bank).recipient,'Mosswick Moneybags')
 eq(db.characters.bank.contextKey,db.characters.main.contextKey)
end)
test('bank registration is shared across same-faction characters on Forever',function()
 local A,db=setup()
 local bank={key='moneybags:Alliance',characterID='bank',name='Mosswick',realm='Moneybags',faction='Alliance'}
 assert(A.Store.RegisterBank(db,bank,false))
 local main={key='eppingworth:Alliance',characterID='main',name='Eryndor',realm='Eppingworth',faction='Alliance'}
 eq(A.Store.Resolve(db,main).recipient,'Mosswick Moneybags')
 assert(A.Store.SetRecipient(db,main,'Mosswick',false)); eq(A.Store.Resolve(db,main).recipient,'Mosswick')
 assert(A.Store.IsSelf('Mosswick',bank))
end)
test('conflicting existing saved bank recipients require an explicit choice',function()
 local A=setup()
 local db=A.Store.Init({version=1,contexts={['a:Alliance']={recipient='One-A'},['b:Alliance']={recipient='Two-B'}},characters={}})
 local r=A.Store.Resolve(db,{key='a:Alliance',characterID='one',name='Sender',realm='A',faction='Alliance'})
 eq(r.recipient,nil); assert(r.warning)
end)
test('shared-scope migration is idempotent and a key collision still recovers saved data',function()
 local A=setup()
 local db=A.Store.Init({version=1,contexts={['forever:Alliance']={},['moneybags:Alliance']={recipient='Mosswick-Moneybags'}},characters={}})
 local c={key='forever:Alliance',characterID='main',name='Sender',realm='Forever',faction='Alliance'}
 eq(A.Store.Resolve(db,c).recipient,'Mosswick Moneybags')
 assert(A.Store.SetRecipient(db,c,'Another',false)); eq(A.Store.Resolve(db,c).recipient,'Another')
 eq(db.contexts['moneybags:Alliance'].recipient,'Mosswick-Moneybags')
end)
test('differing existing selections remain available as character overrides',function()
 local A,_,c=setup(); local r=A.Store.Resolve(A.Store.Init(),c).rules
 local herbs=A.Store.Copy(r); herbs.categories.herbs={enabled=true,keep=20}
 local ore=A.Store.Copy(r); ore.categories.ore={enabled=true,keep=7}
 local db=A.Store.Init({version=1,contexts={['one:Alliance']={rules=herbs},['two:Alliance']={rules=ore}},characters={
  one={name='One',realm='One',contextKey='one:Alliance'},two={name='Two',realm='Two',contextKey='two:Alliance'},
 }})
 local one={key='one:Alliance',characterID='one',name='One',realm='One',faction='Alliance'}
 local two={key='two:Alliance',characterID='two',name='Two',realm='Two',faction='Alliance'}
 eq(A.Store.Resolve(db,one).rules.categories.herbs.keep,20)
 eq(A.Store.Resolve(db,two).rules.categories.ore.keep,7)
 eq(A.Store.Resolve(db,two).ruleSource,'Character')
end)
test('migration preserves explicitly disabled selections on another recorded character',function()
 local A,_,c=setup(); local empty=A.Store.Resolve(A.Store.Init(),c).rules
 local enabled=A.Store.Copy(empty); enabled.categories.herbs={enabled=true,keep=20}
 local db=A.Store.Init({version=1,contexts={['bank:Alliance']={rules=empty},['main:Alliance']={rules=enabled}},characters={
  bank={name='Banker',realm='Bank',contextKey='bank:Alliance'},main={name='Main',realm='Main',contextKey='main:Alliance'},
 }})
 A.Store.Resolve(db,{key='main:Alliance',characterID='main',name='Main',realm='Main',faction='Alliance'})
 local r=A.Store.Resolve(db,{key='bank:Alliance',characterID='bank',name='Banker',realm='Bank',faction='Alliance'})
 eq(r.rules.categories.herbs.enabled,false); eq(r.ruleSource,'Character')
end)
test('a populated legacy key collision retains a recovery copy of conflicting data',function()
 local A=setup()
 local db=A.Store.Init({version=1,contexts={['forever:Alliance']={recipient='One-A'},['moneybags:Alliance']={recipient='Two-B'}},characters={}})
 local r=A.Store.Resolve(db,{key='forever:Alliance',characterID='main',name='Sender',realm='Forever',faction='Alliance'})
 eq(r.recipient,nil); assert(r.warning)
 assert(db.scopeBackups); eq(db.scopeBackups['forever:Alliance'].recipient,'One-A')
end)
test('recipient equivalence accepts formatting but never another full address',function()
 local A=setup()
 eq(A.Store.SameRecipient('Mosswick-Moneybags',' mosswick - Moneybags '),true)
 eq(A.Store.SameRecipient('Mosswick-Moneybags','Mosswick-Other'),false)
 eq(A.Store.SameRecipient('Mosswick-Moneybags','Mosswick'),false)
 eq(A.Store.SameRecipient('Mosswick-Moneybags','Someone-Moneybags'),false)
end)
test('Forever full names use a space and upgrade stored hyphenated bank addresses',function()
 local A=setup()
 eq(A.Store.Normalize('Mosswick Moneybags'),'Mosswick Moneybags')
 eq(A.Store.Normalize('Mosswick-Moneybags'),'Mosswick Moneybags')
 eq(A.Store.SameRecipient('Mosswick-Moneybags','Mosswick Moneybags'),true)
 eq(A.Store.SameRecipient('Mosswick Moneybags','Mosswick Other'),false)
 local db=A.Store.Init({version=1,contexts={['forever:Alliance']={scope='forever',recipient='Mosswick-Moneybags'}},characters={}})
 local c={key='forever:Alliance',characterID='main',name='Eryndor',realm='Eppingworth',faction='Alliance'}
 eq(A.Store.Resolve(db,c).recipient,'Mosswick Moneybags')
end)
