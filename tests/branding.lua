test('Mule Mailer owns its runtime identity and preserves its custom settings',function()
 local A={}; module('Core',A); module('Categories',A); module('Store',A)
 eq(A.name,'Mule Mailer'); eq(A.id,'MuleMailer')
 local original={version=1,contexts={realm={recipient='Vault-Realm',rules={categories={},items={}}}},characters={},display={compact=true},sending={subject='My auction stock',review=true,completion=false}}
 local db=A.Store.Init(original); eq(db,original); eq(db.contexts.realm.recipient,'Vault-Realm'); eq(db.sending.subject,'My auction stock'); eq(db.sending.review,true); eq(db.display.compact,true)
 eq(A.Store.Init().sending.subject,'Mule Mailer')
end)
