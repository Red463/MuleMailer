local passed,failed=0,0
-- Native chat command registry exists before addons load in the client.
SlashCmdList={}
function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed=passed+1 else failed=failed+1; print('FAIL '..name..': '..tostring(err)) end
end
function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
function module(name,A)
 local chunk,err=loadfile(name..'.lua'); assert(chunk,err); chunk('MuleMailer',A)
end
for _,suite in ipairs({'client','store','planner','queue','ui','bootstrap','review','branding','workflows','performance'}) do
 local f=assert(io.open('tests/'..suite..'.lua'),'Missing required test suite: '..suite); f:close(); dofile('tests/'..suite..'.lua')
end
print(string.format('RESULT %d passed, %d failed',passed,failed))
assert(failed==0,'test failures')
