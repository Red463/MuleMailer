local function coreFixture()
 local A={}; module('Core',A); module('Categories',A); module('Store',A); module('Planner',A); module('MailQueue',A)
 local f={open=false,starts=0,shown=0,hidden=0,registered=0,opened=0}
 local ctx={key='r:Alliance',characterID='one',name='Alice',realm='Realm',faction='Alliance'}
 A.Client={GetContext=function() return ctx end,Probe=function() return {mail=true,settings=true,attachmentLimit=12} end,Snapshot=function() return {{itemID=2447,count=20,bag=0,slot=1,eligible=true,category='herbs'}} end,IsOpen=function() return f.open end,HasManualDraft=function() return false end,Now=function() return 0 end}
 A.Mailbox={Show=function() f.shown=f.shown+1 end,Hide=function() f.hidden=f.hidden+1 end,Refresh=function() end,ExpandReview=function() f.review=true end}
 A.Options={Register=function() f.registered=f.registered+1 end,Open=function() f.opened=f.opened+1 end,Refresh=function() end,RefreshLock=function() end,RefreshItems=function() end}
 MuleMailerDB=nil; A.Initialize(); A.queue.Start=function() f.starts=f.starts+1; return true end
 return A,f,ctx
end
test('opening scans and shows controls but never starts or resumes sending',function()
 local A,f=coreFixture(); f.open=true; A.OnEvent(nil,'MAIL_SHOW'); eq(f.shown,1); eq(f.starts,0); assert(A.plan)
 A.OnEvent(nil,'MAIL_CLOSED'); eq(f.hidden,1); A.OnEvent(nil,'MAIL_SHOW'); eq(f.starts,0)
end)
test('completed login refreshes character discovery after early context changes',function()
 local A,f,c=coreFixture()
 c.key='r:Neutral'; c.faction='Neutral'; A.RefreshPlan()
 eq(A.db.characters[c.characterID].contextKey,'forever:Neutral')
 c.key='r:Alliance'; c.faction='Alliance'; A.OnEvent(nil,'PLAYER_LOGIN')
 eq(A.db.characters[c.characterID].contextKey,'forever:Alliance')
end)
test('missing recipient empty selection and self bank disable sending',function()
 local A,f,c=coreFixture(); f.open=true; A.RefreshPlan(); assert(A.SendDisabledReason())
 A.Store.SetRecipient(A.db,c,'Bank',false); A.RefreshPlan(); assert(A.SendDisabledReason())
 A.Store.SetRule(A.db,c,'category','herbs',{enabled=true,keep=0}); A.RefreshPlan(); eq(A.SendDisabledReason(),nil)
 A.Store.RegisterBank(A.db,c,false); A.RefreshPlan(); assert(A.SendDisabledReason())
end)
test('review option requires a second deliberate click for unchanged plan',function()
 local A,f,c=coreFixture(); f.open=true; A.Store.SetRecipient(A.db,c,'Bank',false); A.Store.SetRule(A.db,c,'category','herbs',{enabled=true,keep=0}); A.db.sending.review=true
 A.StartSend(); eq(f.starts,0); eq(f.review,true)
 A.StartSend(); eq(f.starts,1)
end)
test('settings mutations are rejected during a transfer and command opens options',function()
 local A,f=coreFixture(); A.queue.state='awaiting-result'
 local changed=false; assert(not A.EditSettings(function() changed=true; return true end)); eq(changed,false)
 A.OpenOptions(); eq(f.opened,1)
end)
test('native options controls save category rules and reject invalid keep edits',function()
 local A,f,c=coreFixture(); dofile('tests/wow.lua'); fakeUI(); module('Options',A)
 A.Client.ItemName=function(id) return 'Item '..id end
 A.Options.Register(); eq(Settings.registered.name,'Mule Mailer')
 A.Store.SetRecipient(A.db,c,'Banker',false); A.RefreshPlan(); A.Options.Refresh(); eq(A.Options.recipient:GetText(),'Banker')
 local row=A.Options.categories.herbs
 row.check:SetChecked(true); row.check.scripts.OnClick(row.check)
 eq(A.Store.Resolve(A.db,c).rules.categories.herbs.enabled,true)
 row.keep:SetFocus(); row.keep:SetText('-1'); row.keep.scripts.OnEnterPressed(row.keep)
 eq(A.Store.Resolve(A.db,c).rules.categories.herbs.keep,0); assert(A.Options.status:GetText():find('nonnegative'))
 A.Options.Open(); eq(Settings.opened,55)
 CreateFrame=nil; Settings=nil
end)
test('mail subject saves into the plan and persists with a reset to the existing default',function()
 local A,f=coreFixture(); dofile('tests/wow.lua'); fakeUI(); module('Options',A)
 A.Options.Register(); eq(A.Options.subject:GetText(),'Mule Mailer')
 A.Options.subject:SetText('Materials for the bank'); A.Options.subjectSave.scripts.OnClick()
 eq(A.db.sending.subject,'Materials for the bank'); eq(A.plan.subject,'Materials for the bank')
 A.db=A.Store.Init(A.Store.Copy(A.db)); A.RefreshPlan(); A.Options.Refresh()
 eq(A.Options.subject:GetText(),'Materials for the bank'); eq(A.plan.subject,'Materials for the bank')
 A.Options.subjectReset.scripts.OnClick()
 eq(A.db.sending.subject,'Mule Mailer'); eq(A.Options.subject:GetText(),'Mule Mailer'); eq(A.plan.subject,'Mule Mailer'); eq(f.starts,0)
 CreateFrame=nil; Settings=nil
end)

test('mail subject rejects blank or control characters and cannot change during a transfer',function()
 local A,f=coreFixture(); dofile('tests/wow.lua'); fakeUI(); module('Options',A)
 A.Options.Register()
 for _,value in ipairs({'','   ','Bad\nsubject'}) do
  A.Options.subject:SetText(value); A.Options.subjectSave.scripts.OnClick(); eq(A.db.sending.subject,'Mule Mailer')
 end
 A.queue.state='awaiting-result'; A.Options.subject:SetText('Changed'); A.Options.subjectSave.scripts.OnClick()
 eq(A.db.sending.subject,'Mule Mailer'); eq(f.starts,0)
 CreateFrame=nil; Settings=nil
end)

test('mounted mailbox shows recipient and only click starts transfer',function()
 local A,f,c=coreFixture(); dofile('tests/wow.lua'); fakeUI(); module('Options',A); module('Mailbox',A)
 A.Client.ItemName=function(id) return 'Item '..id end
 A.Store.SetRecipient(A.db,c,'Bank',false); A.Store.SetRule(A.db,c,'category','herbs',{enabled=true,keep=0})
 f.open=true; A.RefreshPlan(); A.Mailbox.Show(); eq(f.starts,0)
 eq(A.Mailbox.recipient:GetText(),'To: Bank')
 A.Mailbox.send.scripts.OnClick(A.Mailbox.send); eq(f.starts,1)
 CreateFrame=nil; Settings=nil
end)

test('core temporary review exclusions do not save rules or send and clear on mailbox close',function()
 local A,f,c=coreFixture(); f.open=true
 A.Store.SetRecipient(A.db,c,'Bank Oak',false); A.Store.SetRule(A.db,c,'category','herbs',{enabled=true,keep=5}); A.RefreshPlan()
 assert(A.ToggleExcluded(2447)); eq(A.plan.totalUnits,0); eq(A.config.rules.categories.herbs.keep,5); eq(f.starts,0)
 assert(A.ToggleExcluded(2447)); eq(A.plan.totalUnits,15)
 A.ToggleExcluded(2447); A.OnEvent(nil,'MAIL_CLOSED'); A.RefreshPlan(); eq(A.plan.totalUnits,15)
 A.queue.state='ready'; assert(not A.ToggleExcluded(2447)); eq(A.plan.totalUnits,15)
end)
test('core destination selection displays the chosen recipient without changing the fallback or sending',function()
 local A,f,c=coreFixture(); f.open=true
 A.Store.SetRecipient(A.db,c,'Bank Oak',false); A.Store.SetRule(A.db,c,'category','herbs',{enabled=true,keep=0})
 A.Store.SetDestination(A.db,c,'category','herbs','Crafter Pine'); A.RefreshPlan()
 eq(A.plan.recipient,'Crafter Pine'); eq(A.SendDisabledReason(),nil); eq(A.config.recipient,'Bank Oak')
 assert(not A.SelectDestination('Unknown')); eq(f.starts,0)
end)
test('workflow options expose presets destinations optional postage and searchable detailed history',function()
 local A,f,c=coreFixture(); dofile('tests/wow.lua'); fakeUI(); module('Options',A); module('History',A); module('Workflows',A)
 A.Options.Register(); local F=A.Workflows
 eq(F.postage:GetChecked(),true); F.postage:SetChecked(false); F.postage.scripts.OnClick(F.postage); eq(A.db.sending.postage,false)
 F.presetName:SetText('Selling'); F.createPreset.scripts.OnClick(); eq(A.config.presetName,'Selling')
 F.Destination('category','herbs'); F.destinationName:SetText('Bad123'); F.destinationSave.scripts.OnClick(); assert(F.destinationStatus:GetText():find('full character name')); eq(F.destination:IsShown(),true)
 F.destinationName:SetText('Crafter Pine'); F.destinationSave.scripts.OnClick(); eq(A.config.routes.categories.herbs,'Crafter Pine')
 A.db.history={nextID=1,entries={{id=1,sender='Alice Oak',recipient='Bank Oak',subject='Materials',preset='Selling',outcome='accepted',postage=30,totalUnits=4,totalStacks=1,items={{itemID=2447,name='Peacebloom',count=4,link='item:2447'}}}}}
 F.ShowHistory(); eq(#F.historyMatches,1); F.historyRows[1].header.scripts.OnClick(); assert(F.historyRows[1].details:IsShown())
 F.historySearch:SetText('No match'); eq(#F.historyMatches,0)
 F.historySearch:SetText('Peacebloom'); eq(#F.historyMatches,1); eq(f.starts,0)
 CreateFrame=nil; Settings=nil
end)
test('review checkboxes and quick actions update real plans while postage toggle avoids price reads',function()
 local A,f,c=coreFixture(); dofile('tests/wow.lua'); fakeUI(); module('Options',A); module('History',A); module('Workflows',A); module('Mailbox',A)
 A.Client.ItemDisplay=function(id) return {name='Peacebloom',icon=1,link='item:'..id,quality=1} end
 A.Client.ItemName=function() return 'Peacebloom' end
 local estimates=0; A.Client.EstimatePostage=function() estimates=estimates+1; return 30 end
 A.Store.SetRecipient(A.db,c,'Bank Oak',false); A.Store.SetRule(A.db,c,'category','herbs',{enabled=true,keep=5})
 f.open=true; A.RefreshPlan(); A.Options.Register(); A.Mailbox.Show(); A.Mailbox.ExpandReview(); A.Mailbox.Refresh(A.plan,A.queue:GetStatus())
 eq(A.Mailbox.postage:IsShown(),true); assert(A.Mailbox.postage:GetText():find('30c')); assert(estimates>0)
 local row=A.Mailbox.reviewRows[1]; row.check.scripts.OnClick(); eq(A.plan.totalUnits,0); eq(row.check:GetChecked(),false); eq(row.send:GetText(),'Excluded')
 row.check.scripts.OnClick(); eq(A.plan.totalUnits,15); eq(row.check:GetChecked(),true)
 row.actions.scripts.OnClick(); eq(A.Workflows.menu:IsShown(),true)
 A.Workflows.menuRows[3].scripts.OnClick(); eq(A.config.rules.items[2447].mode,'never'); eq(A.plan.totalUnits,0)
 A.QuickRule(2447,'always'); A.db.sending.postage=false; A.RefreshPlan(); local before=estimates
 A.Mailbox.Refresh(A.plan,A.queue:GetStatus()); eq(A.Mailbox.postage:IsShown(),false); eq(estimates,before)
 A.queue.state='ready'; A.Mailbox.Refresh(A.plan,A.queue:GetStatus()); eq(A.Mailbox.reviewRows[1].check:IsEnabled(),false)
 eq(f.starts,0); A.Workflows.ShowHistory(); MailFrame:Hide(); eq(A.Workflows.history:IsShown(),false)
 CreateFrame=nil; Settings=nil
end)
test('excluding the last item for one destination never switches the next send to another recipient',function()
 local A,f,c=coreFixture(); f.open=true
 A.Store.SetRecipient(A.db,c,'Bank Oak',false); A.Store.SetRule(A.db,c,'category','herbs',{enabled=true,keep=0}); A.Store.SetRule(A.db,c,'category','ore',{enabled=true,keep=0})
 A.Store.SetDestination(A.db,c,'category','herbs','Crafter Pine')
 A.Client.Snapshot=function() return {{itemID=2447,count=20,bag=0,slot=1,category='herbs',eligible=true},{itemID=2770,count=5,bag=0,slot=2,category='ore',eligible=true}} end
 A.RefreshPlan(); assert(A.SelectDestination('Crafter Pine')); A.ToggleExcluded(2447)
 eq(A.plan.recipient,'Crafter Pine'); eq(A.plan.totalUnits,0); A.StartSend(); eq(f.starts,0)
 assert(A.SelectDestination('Bank Oak')); eq(A.plan.totalUnits,5)
end)
test('mailbox visit exclusions survive switching presets until closure',function()
 local A,f,c=coreFixture(); A.Store.SetRecipient(A.db,c,'Bank Oak',false); A.Store.SetRule(A.db,c,'category','herbs',{enabled=true,keep=0})
 local ok,id=A.Store.CreatePreset(A.db,c,'Storage'); assert(ok); A.RefreshPlan(); A.ToggleExcluded(2447)
 A.SelectPreset(nil); eq(A.plan.totalUnits,0); A.SelectPreset(id); eq(A.plan.totalUnits,0)
 A.CloseMailbox(); A.RefreshPlan(); eq(A.plan.totalUnits,20)
end)
test('native mailbox hide closes both displays and stops a transfer without MAIL_CLOSED',function()
 local A,f=coreFixture(); dofile('tests/wow.lua'); fakeUI(); module('Options',A); module('Mailbox',A)
 f.open=true; A.Mailbox.Show(); A.Mailbox.ExpandReview(); A.queue.state='awaiting-result'
 MailFrame:Hide()
 eq(A.Mailbox.panel:IsShown(),false); eq(A.Mailbox.compact:IsShown(),false); eq(A.queue:Active(),false); eq(f.starts,0)
 MailFrame:Show(); eq(A.Mailbox.panel:IsShown(),false)
 A.config.display.compact=true; A.Mailbox.Show(); eq(A.Mailbox.compact:IsShown(),true)
 MailFrame:Hide(); eq(A.Mailbox.compact:IsShown(),false)
 MailFrame:Show(); eq(A.Mailbox.compact:IsShown(),false)
 CreateFrame=nil; Settings=nil
end)
test('idle mailbox hides Stop but exposes it during a transfer',function()
 local A,f=coreFixture(); dofile('tests/wow.lua'); fakeUI(); module('Options',A); module('Mailbox',A)
 f.open=true; A.Mailbox.Show(); eq(A.Mailbox.stop:IsShown(),false)
 A.queue.state='awaiting-result'; A.Mailbox.Refresh(A.plan,A.queue:GetStatus()); eq(A.Mailbox.stop:IsShown(),true)
 A.queue.state='idle'; A.Mailbox.Refresh(A.plan,A.queue:GetStatus()); eq(A.Mailbox.stop:IsShown(),false)
 CreateFrame=nil; Settings=nil
end)
test('picker offers another recorded character by name and saves it as bank alt',function()
 local A,f,c=coreFixture(); dofile('tests/wow.lua'); local widgets=fakeUI(); module('Options',A)
 A.Client.ItemName=function(id) return 'Item '..id end
 A.Store.Resolve(A.db,{key=c.key,characterID='bank-guid',name='Banker',realm=c.realm,faction=c.faction})
 A.Options.Register()
 local pickerButton
 for _,w in ipairs(widgets) do if w:GetText()=='Choose seen character' then pickerButton=w end end
 assert(pickerButton); pickerButton.scripts.OnClick(pickerButton)
 local banker
 for _,w in ipairs(widgets) do if w.kind=='Button' and w:GetText()=='Banker Realm' then banker=w end end
 assert(banker,'The other logged character must appear with its full native name')
 banker.scripts.OnClick(banker)
 eq(A.Store.Resolve(A.db,c).recipient,'Banker Realm'); eq(A.Options.recipient:GetText(),'Banker Realm')
 CreateFrame=nil; Settings=nil
end)
test('review shows item icons and distinct send keep counts without sending',function()
 local A,f=coreFixture(); dofile('tests/wow.lua'); fakeUI(); module('Options',A); module('Mailbox',A)
 A.Client.ItemDisplay=function(id) return {name=id==818 and 'Tigerseye' or 'Light Leather',icon=id==818 and 134118 or 134252,quality=id==818 and 2 or 1,link='item:'..id} end
 local plan={recipient='Bank',totalStacks=2,estimatedMails=1,items={{itemID=818,send=3,retained=7},{itemID=2318,send=12,retained=0}},skipped={}}
 A.Mailbox.ExpandReview(); A.Mailbox.Refresh(plan,A.queue:GetStatus())
 local row=A.Mailbox.reviewRows[1]
 eq(row.icon.texture,134118); eq(row.name:GetText(),'Tigerseye'); eq(row.send:GetText(),'Send 3'); eq(row.keep:GetText(),'Keep 7')
 assert(row.name.color[2]>row.name.color[1],'Uncommon items should use green rarity text')
 row.frame.scripts.OnEnter(row.frame); eq(GameTooltip.link,'item:818'); eq(f.starts,0)
 plan.items={{itemID=2318,send=1,retained=5}}; A.Mailbox.Refresh(plan,A.queue:GetStatus())
 eq(row.icon.texture,134252); eq(row.name:GetText(),'Light Leather'); eq(row.send:GetText(),'Send 1'); eq(row.keep:GetText(),'Keep 5')
 row.frame.scripts.OnEnter(row.frame); eq(GameTooltip.link,'item:2318'); eq(A.Mailbox.reviewRows[2].frame:IsShown(),false)
 CreateFrame=nil; Settings=nil
end)
test('skipped review rows are separate and expand with their reason',function()
 local A,f=coreFixture(); dofile('tests/wow.lua'); fakeUI(); module('Options',A); module('Mailbox',A)
 A.Client.ItemDisplay=function(id) return {name='Item '..id,icon=134118,quality=1} end
 A.plan={recipient='Bank',totalStacks=1,estimatedMails=1,items={{itemID=818,send=3,retained=0}},skipped={{itemID=2447,count=20,reason='Never send'}}}
 A.Mailbox.ExpandReview(); A.Mailbox.Refresh(A.plan,A.queue:GetStatus())
 eq(A.Mailbox.skippedHeader:IsShown(),true); assert(A.Mailbox.skippedHeader:GetText():find('1'))
 eq(#A.Mailbox.reviewRows,1)
 A.Mailbox.skippedHeader.scripts.OnClick(A.Mailbox.skippedHeader)
 local row=A.Mailbox.reviewRows[2]; assert(row and row.frame:IsShown()); eq(row.reason:GetText(),'Never send'); eq(row.send:IsShown(),false)
 A.Mailbox.skippedHeader.scripts.OnClick(A.Mailbox.skippedHeader); eq(row.frame:IsShown(),false); eq(f.starts,0)
 CreateFrame=nil; Settings=nil
end)
