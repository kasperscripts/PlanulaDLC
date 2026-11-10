from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parent
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
local hooked, consts, upvalues = {}, {}, {}
_G.hooked = hooked
_G.invoke = function(fn, ...) return (hooked[fn] or fn)(...) end
hookfunction = function(fn, replacement) hooked[fn]=replacement;return fn end
newcclosure = function(fn) return fn end
getgenv = function() return _G end
debug.getconstants = function(fn) return consts[fn] or {} end
debug.getupvalues = function(fn) return upvalues[fn] or {} end
warn = function() end
print = function() end
local tasks = {}
task = { spawn=function(fn) tasks[#tasks+1]=coroutine.create(fn) end, wait=coroutine.yield }
_G.run_patch = function() local ok,err=coroutine.resume(tasks[1]);assert(ok,err) end
local function object(class,name,parent)
 local value={ClassName=class,Name=name,Parent=parent,Text="",children={}}
 value.IsA=function(self,kind)return self.ClassName==kind end
 value.FindFirstChild=function(self,key)return self.children[key] end
 if parent then parent.children[name]=value end
 return value
end
local root=object('Folder','HiddenUi')
local gui=object('ScreenGui','random-name',root)
local panel=object('Frame','random-key-frame',gui)
local holder=object('Frame','Holder',panel)
local row=object('Frame','Input',holder)
local box=object('Frame','TextBox',row)
input=object('TextBox','Input',box)
local title=object('TextLabel','Title',row)
local message=object('Frame','Title',holder)
local paragraph=object('TextLabel','Paragraph',message)
local buttons=object('Frame','Buttons',holder)
activate=object('TextButton','Button1',buttons)
getkey=object('TextButton','Button2',buttons)
local getlabel=object('TextLabel','Input',getkey)
social=object('TextButton','Button2',holder)
local sociallabel=object('TextLabel','Input',social)
footer=object('TextLabel','Footer',gui)
footer.Text='Thank you for using Delta <3\nGet Delta only at deltaexploits.gg !'
local items={root,gui,panel,holder,row,box,input,title,message,paragraph,buttons,activate,getkey,getlabel,social,sociallabel,footer}
root.GetDescendants=function()return items end
gethui=function()return root end
getconnections=function(event)return event end
setclipboard=function(text)clipboard=text end
local sanitize=function(str)return str:match('^(.-)%s*$') end
local verify=function(key)return true end
local onClick=function()
 local value=invoke(sanitize,input.Text)
 if invoke(verify,value) then grants=grants+1;saved=value end
end
activate.MouseButton1Click={{Function=onClick}}
getkey.MouseButton1Click={{Function=function()clipboard='old vendor link' end}}
social.MouseButton1Click={{Function=function()clipboard='old discord link' end}}
consts[sanitize]={'^(.-)%s*$'}
consts[verify]={'/public/whitelist/','&key='}
upvalues[onClick]={sanitize,verify}
_G.click=function(button)for _,c in ipairs(button.MouseButton1Click)do invoke(c.Function)end end
grants=0
local http=function(self,url)return 'upstream:'..url end
game={IsLoaded=function()return true end,GetService=function()error('Original input helpers need a real Roblox world')end,HttpGet=http,HttpGetAsync=http}
loadstring=function(source,chunk)last_source=source;local fn,err=load(source,chunk);assert(fn,err);return fn end
''')
lua.execute((root/'bootstrap.lua').read_text())
lua.globals().run_patch()
for text in ['', 'wrong', '@icon_crack', '@ICON_CRACK', '@Icon_crack', '@Icon_Crack ', ' @Icon_Crack', '@Icon_Crack\n', '@Icon_Crackx']:
 lua.globals().input.Text=text
 lua.globals().click(lua.globals().activate)
 assert lua.globals().grants==0,text
lua.globals().input.Text='@Icon_Crack'
lua.globals().click(lua.globals().activate)
assert lua.globals().grants==1
assert lua.globals().saved=='@Icon_Crack'
assert lua.globals().input.PlaceholderText=='@Icon_Crack'
assert 'cracked by @Icon_Crack' in lua.globals().footer.Text
for button in ['getkey','social']:
 lua.globals().click(lua.globals()[button])
 assert lua.globals().clipboard=='https://t.me/Icon_Crack'
http=lua.globals().game.HttpGet
invoke=lua.globals().invoke
for url in ['https://api.platorelay.com/public/whitelist/6?key=FREE_old','https://api.platoboost.net/public/whitelist/6?key=@Icon_Crack']:
 assert '"valid":false' in invoke(http,lua.globals().game,url)
assert '"value":false' in invoke(http,lua.globals().game,'https://api.platorelay.com/public/flag/6?name=keyless')
assert invoke(http,lua.globals().game,'https://example.com/data')=='upstream:https://example.com/data'
invoke(lua.globals().loadstring,(root/'Delta.lua').read_text(),'Delta modified UI')
modified=lua.globals().last_source
assert '/public/whitelist/' not in modified
assert 'local keyless = false;' in modified
assert 'return str:match("^(.-)%s*$")' not in modified
assert 'key == "@Icon_Crack"' in modified
(root/'Delta-fixed-key.lua').write_text(modified)
print('PASS: existing activation callbacks enforce exact case and whitespace; previous arbitrary keys denied; keyless mode denied; Telegram and footer changed; actual Delta source rewrite compiles')
