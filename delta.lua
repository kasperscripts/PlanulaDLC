-- Delta 2.745.1142: fixed activation key and menu attribution.
local KEY = "@Icon_Crack"
local TELEGRAM = "https://t.me/Icon_Crack"
local function accepts(key)
    return type(key) == "string" and key == KEY
end

local globals = getgenv()
if globals.__icon_crack_delta_loaded then return end
globals.__icon_crack_delta_loaded = true

local state = { verify = false, sanitize = false, source = false, footer = false }
local patched = setmetatable({}, { __mode = "k" })
local getconstants = (debug and debug.getconstants) or getconstants
local getupvalues = (debug and debug.getupvalues) or getupvalues

local function constants(fn)
    if type(fn) ~= "function" or type(getconstants) ~= "function" then return {} end
    local ok, values = pcall(getconstants, fn)
    return ok and type(values) == "table" and values or {}
end

local function has(values, fragment)
    for _, value in pairs(values) do
        if type(value) == "string" and value:find(fragment, 1, true) then return true end
    end
    return false
end

local function replace_function(fn, replacement)
    if type(fn) ~= "function" or patched[fn] then return patched[fn] == true end
    local ok = pcall(hookfunction, fn, replacement)
    if ok then patched[fn] = true end
    return ok
end

local function inspect(fn, depth)
    if type(fn) ~= "function" then return end
    local values = constants(fn)
    if has(values, "/public/whitelist/") and has(values, "&key=") then
        if replace_function(fn, accepts) then state.verify = true end
    elseif has(values, "^(.-)%s*$") then
        if replace_function(fn, function(value) return value end) then state.sanitize = true end
    elseif has(values, "/public/flag/") then
        -- The fixed key remains required when the upstream service enables keyless mode.
        replace_function(fn, function() return false end)
    end
    if depth > 0 and type(getupvalues) == "function" then
        local ok, values = pcall(getupvalues, fn)
        if ok and type(values) == "table" then
            for _, value in pairs(values) do
                if type(value) == "function" then inspect(value, depth - 1) end
            end
        end
    end
end

local function copy_telegram()
    setclipboard(TELEGRAM)
end

-- Keep the server from granting a previously cached or keyless session while the UI initializes.
local function license_response(url)
    if type(url) ~= "string" then return nil end
    local lower = url:lower()
    if not (lower:match("^https://api%.platorelay%.com/") or lower:match("^https://api%.platoboost%.net/")) then return nil end
    if lower:find("/public/whitelist/", 1, true) then
        return '{"success":true,"data":{"valid":false}}'
    end
    if lower:find("/public/flag/", 1, true) and lower:find("keyless", 1, true) then
        return '{"success":true,"data":{"value":false}}'
    end
    return nil
end

local seen_http = {}
for _, name in ipairs({ "HttpGet", "HttpGetAsync" }) do
    local ok, fn = pcall(function() return game[name] end)
    if ok and type(fn) == "function" and not seen_http[fn] then
        seen_http[fn] = true
        local original
        local callback = function(self, url, ...)
            local response = license_response(url)
            if response then return response end
            return original(self, url, ...)
        end
        if type(newcclosure) == "function" then callback = newcclosure(callback) end
        local hooked, old = pcall(hookfunction, fn, callback)
        if hooked then original = old end
    end
end

-- Apply the same change before compilation when the UI loader uses loadstring.
local function rewrite_source(source)
    if type(source) ~= "string" or not source:find("/public/whitelist/", 1, true)
        or not source:find("local verifyKey = function(key)", 1, true) then return source end
    local a = source:find("    local verifyKey = function(key)", 1, true)
    local b = a and source:find("    local getFlag = function(name)", a, true)
    if not (a and b) then return source end
    source = source:sub(1, a - 1)
        .. '    local verifyKey = function(key) return type(key) == "string" and key == "@Icon_Crack" end\n\n'
        .. source:sub(b)
    -- Use an exact literal replacement for the existing trailing-space sanitizer.
    local old = 'return str:match("^(.-)%s*$")'
    local at = source:find(old, 1, true)
    if at then source = source:sub(1, at - 1) .. 'return str' .. source:sub(at + #old) end
    source = source:gsub('local keyless = getFlag%("keyless"%);', 'local keyless = false;')
    source = source:gsub('https://discord%.gg/deltax', TELEGRAM)
    source = source:gsub('https://deltaexploits%.gg', TELEGRAM)
    source = source:gsub('Get Delta only at deltaexploits%.gg !', 'cracked by @Icon_Crack')
    state.source = true
    return source
end

if type(loadstring) == "function" then
    local original
    local ok, old = pcall(hookfunction, loadstring, function(source, ...)
        return original(rewrite_source(source), ...)
    end)
    if ok then original = old end
end

local function connections(button)
    local ok, values = pcall(function() return getconnections(button.MouseButton1Click) end)
    return ok and values or {}
end

local function callback(connection)
    local ok, fn = pcall(function() return connection.Function end)
    return ok and fn or nil
end

local function paint_button(button, label)
    local input = button and button:FindFirstChild("Input")
    if input and (input:IsA("TextLabel") or input:IsA("TextButton")) then input.Text = label end
end

local function patch_holder(input)
    if not input:IsA("TextBox") or input.Name ~= "Input" then return end
    local box = input.Parent
    local row = box and box.Parent
    local holder = row and row.Parent
    local buttons = holder and holder:FindFirstChild("Buttons")
    local activate = buttons and buttons:FindFirstChild("Button1")
    local getkey = buttons and buttons:FindFirstChild("Button2")
    if not (holder and holder.Name == "Holder" and activate and getkey) then return end
    for _, connection in ipairs(connections(activate)) do
        local fn = callback(connection)
        inspect(fn, 2)
        if type(fn) == "function" and type(getfenv) == "function" then
            local ok, scope = pcall(getfenv, fn)
            if ok and type(scope) == "table" then inspect(scope.checkkey, 2) end
        end
    end
    if not state.scanned and type(getgc) == "function" then
        state.scanned = true
        local ok, values = pcall(getgc, true)
        if ok and type(values) == "table" then
            for _, fn in pairs(values) do
                if type(fn) == "function" then
                    local values = constants(fn)
                    if has(values, "/public/whitelist/") or has(values, "/public/flag/") then inspect(fn, 0) end
                end
            end
        end
    end
    if state.source or (state.verify and state.sanitize) then
        input.PlaceholderText = KEY
        local title = row:FindFirstChild("Title")
        if title and title:IsA("TextLabel") then title.Text = "Key: " .. KEY end
        local message = holder:FindFirstChild("Title")
        message = message and message:FindFirstChild("Paragraph")
        if message and message:IsA("TextLabel") then message.Text = "cracked by @Icon_Crack" end
    end
    for _, connection in ipairs(connections(getkey)) do replace_function(callback(connection), copy_telegram) end
    paint_button(getkey, "Telegram")
    local social = holder:FindFirstChild("Button2")
    if social then
        for _, connection in ipairs(connections(social)) do replace_function(callback(connection), copy_telegram) end
        paint_button(social, "Telegram")
    end
end

local function patch_menu()
    for _, item in ipairs(gethui():GetDescendants()) do
        if item:IsA("TextBox") then patch_holder(item) end
        if item:IsA("TextLabel") or item:IsA("TextButton") then
            local text = item.Text
            if type(text) == "string" and (text:find("Thank you for using Delta", 1, true)
                or text:find("Get Delta only at", 1, true)) then
                item.Text = "cracked by @Icon_Crack\n" .. TELEGRAM
                state.footer = true
            end
        end
        if item:IsA("TextButton") or item:IsA("ImageButton") then
            for _, connection in ipairs(connections(item)) do
                local fn = callback(connection)
                local values = constants(fn)
                if has(values, "https://discord.gg/deltax") or has(values, "https://deltaexploits.gg") then
                    replace_function(fn, copy_telegram)
                end
            end
        end
    end
end

-- Preserve the original executor input helpers.
do
    local function install_original_helpers()
if not game:IsLoaded() then
	repeat
		task.wait()
	until game:IsLoaded();
end

--[[ Variables ]]--
local virtualInputManager = cloneref(Instance.new("VirtualInputManager"));
local guiService = cloneref(game:GetService("GuiService"));

local mouse = cloneref(game:GetService("Players").LocalPlayer:GetMouse());
local mouseButton1 = Enum.UserInputType.MouseButton1;
local mouseButton2 = Enum.UserInputType.MouseButton2;

local genv = getgenv();

local _assert = clonefunction(assert);
local _mathabs = clonefunction(math.abs);
local _mathfloor = clonefunction(math.floor);
local _stringformat = clonefunction(string.format);
local _taskwait = clonefunction(task.wait);
local _tonumber = clonefunction(tonumber);
local _typeof = clonefunction(typeof);

local _sendKeyEvent = clonefunction(virtualInputManager.SendKeyEvent);
local _sendMouseButtonEvent = clonefunction(virtualInputManager.SendMouseButtonEvent);
local _sendMouseMoveEvent = clonefunction(virtualInputManager.SendMouseMoveEvent);
local _sendMouseWheelEvent = clonefunction(virtualInputManager.SendMouseWheelEvent);

local _getGuiInset = clonefunction(guiService.GetGuiInset);

--[[ Functions ]]--

do
    local keyToEnum = {
        [0x08] = Enum.KeyCode.Backspace;
        [0x09] = Enum.KeyCode.Tab;
        [0x0C] = Enum.KeyCode.Clear;
        [0x0D] = Enum.KeyCode.Return;
        [0x10] = Enum.KeyCode.LeftShift;
        [0x11] = Enum.KeyCode.LeftControl;
        [0x12] = Enum.KeyCode.LeftAlt;
        [0xA5] = Enum.KeyCode.RightAlt;
        [0x13] = Enum.KeyCode.Pause;
        [0x14] = Enum.KeyCode.CapsLock;
        [0x1B] = Enum.KeyCode.Escape;
        [0x20] = Enum.KeyCode.Space;
        [0x21] = Enum.KeyCode.PageUp;
        [0x22] = Enum.KeyCode.PageDown;
        [0x23] = Enum.KeyCode.End;
        [0x24] = Enum.KeyCode.Home;
        [0x25] = Enum.KeyCode.Left;
        [0x26] = Enum.KeyCode.Up;
        [0x27] = Enum.KeyCode.Right;
        [0x28] = Enum.KeyCode.Down;
        [0x2A] = Enum.KeyCode.Print;
        [0x2D] = Enum.KeyCode.Insert;
        [0x2E] = Enum.KeyCode.Delete;
        [0x2F] = Enum.KeyCode.Help;
        [0x30] = Enum.KeyCode.Zero;
        [0x31] = Enum.KeyCode.One;
        [0x32] = Enum.KeyCode.Two;
        [0x33] = Enum.KeyCode.Three;
        [0x34] = Enum.KeyCode.Four;
        [0x35] = Enum.KeyCode.Five;
        [0x36] = Enum.KeyCode.Six;
        [0x37] = Enum.KeyCode.Seven;
        [0x38] = Enum.KeyCode.Eight;
        [0x39] = Enum.KeyCode.Nine;
        [0x41] = Enum.KeyCode.A;
        [0x42] = Enum.KeyCode.B;
        [0x43] = Enum.KeyCode.C;
        [0x44] = Enum.KeyCode.D;
        [0x45] = Enum.KeyCode.E;
        [0x46] = Enum.KeyCode.F;
        [0x47] = Enum.KeyCode.G;
        [0x48] = Enum.KeyCode.H;
        [0x49] = Enum.KeyCode.I;
        [0x4A] = Enum.KeyCode.J;
        [0x4B] = Enum.KeyCode.K;
        [0x4C] = Enum.KeyCode.L;
        [0x4D] = Enum.KeyCode.M;
        [0x4E] = Enum.KeyCode.N;
        [0x4F] = Enum.KeyCode.O;
        [0x50] = Enum.KeyCode.P;
        [0x51] = Enum.KeyCode.Q;
        [0x52] = Enum.KeyCode.R;
        [0x53] = Enum.KeyCode.S;
        [0x54] = Enum.KeyCode.T;
        [0x55] = Enum.KeyCode.U;
        [0x56] = Enum.KeyCode.V;
        [0x57] = Enum.KeyCode.W;
        [0x58] = Enum.KeyCode.X;
        [0x59] = Enum.KeyCode.Y;
        [0x5A] = Enum.KeyCode.Z;
        [0x5B] = Enum.KeyCode.LeftSuper;
        [0x5C] = Enum.KeyCode.RightSuper;
        [0x60] = Enum.KeyCode.KeypadZero;
        [0x61] = Enum.KeyCode.KeypadOne;
        [0x62] = Enum.KeyCode.KeypadTwo;
        [0x63] = Enum.KeyCode.KeypadThree;
        [0x64] = Enum.KeyCode.KeypadFour;
        [0x65] = Enum.KeyCode.KeypadFive;
        [0x66] = Enum.KeyCode.KeypadSix;
        [0x67] = Enum.KeyCode.KeypadSeven;
        [0x68] = Enum.KeyCode.KeypadEight;
        [0x69] = Enum.KeyCode.KeypadNine;
        [0x6A] = Enum.KeyCode.Asterisk;
        [0x6B] = Enum.KeyCode.Plus;
        [0x6D] = Enum.KeyCode.Minus;
        [0x6E] = Enum.KeyCode.Period;
        [0x6F] = Enum.KeyCode.Slash;
        [0x70] = Enum.KeyCode.F1;
        [0x71] = Enum.KeyCode.F2;
        [0x72] = Enum.KeyCode.F3;
        [0x73] = Enum.KeyCode.F4;
        [0x74] = Enum.KeyCode.F5;
        [0x75] = Enum.KeyCode.F6;
        [0x76] = Enum.KeyCode.F7;
        [0x77] = Enum.KeyCode.F8;
        [0x78] = Enum.KeyCode.F9;
        [0x79] = Enum.KeyCode.F10;
        [0x7A] = Enum.KeyCode.F11;
        [0x7B] = Enum.KeyCode.F12;
        [0x7C] = Enum.KeyCode.F13;
        [0x7D] = Enum.KeyCode.F14;
        [0x7E] = Enum.KeyCode.F15;
        [0x90] = Enum.KeyCode.NumLock;
        [0x91] = Enum.KeyCode.ScrollLock;
        [0xA0] = Enum.KeyCode.LeftShift;
        [0xA1] = Enum.KeyCode.RightShift;
        [0xA2] = Enum.KeyCode.LeftControl;
        [0xA3] = Enum.KeyCode.RightControl;
        [0xFE] = Enum.KeyCode.Clear;
        [0xBB] = Enum.KeyCode.Equals;
        [0xDB] = Enum.KeyCode.LeftBracket;
        [0xDD] = Enum.KeyCode.RightBracket;
    };

    local getEnumFromKey = newcclosure(function(key)
        return keyToEnum[key] or Enum.KeyCode.Unknown;
    end);

    genv.keypress = newcclosure(function(key)
		local keyType = _typeof(key);
		_assert(keyType == "string" or keyType == "number" or (keyType == "EnumItem" and key.EnumType == Enum.KeyCode), "invalid argument #1 to 'keypress' (string or number or KeyCode expected)");
        _sendKeyEvent(virtualInputManager, true, keyType == "EnumItem" and key or getEnumFromKey(keyType == "string" and _tonumber(key) or key), false, nil);
    end);

    genv.keyrelease = newcclosure(function(key)
		local keyType = _typeof(key);
		_assert(keyType == "string" or keyType == "number" or (keyType == "EnumItem" and key.EnumType == Enum.KeyCode), "invalid argument #1 to 'keyrelease' (string or number or KeyCode expected)");
        _sendKeyEvent(virtualInputManager, false, keyType == "EnumItem" and key or getEnumFromKey(keyType == "string" and _tonumber(key) or key), false, nil);
    end);

	genv.keyclick = newcclosure(function(key)
		local keyType = _typeof(key);
		_assert(keyType == "string" or keyType == "number" or (keyType == "EnumItem" and key.EnumType == Enum.KeyCode), "invalid argument #1 to 'keyclick' (string or number or KeyCode expected)");
		local input = keyType == "EnumItem" and key or getEnumFromKey(keyType == "string" and _tonumber(key) or key);
        _sendKeyEvent(virtualInputManager, true, input, false, nil);
        _sendKeyEvent(virtualInputManager, false, input, false, nil);
    end);
end

genv.mouse1press = newcclosure(function(x, y)
	_assert(x == nil or _typeof(x) == "number", "invalid argument #1 to 'mouse1press' (number or nil expected)");
	_assert(y == nil or _typeof(y) == "number", "invalid argument #2 to 'mouse1press' (number or nil expected)");
    _sendMouseButtonEvent(virtualInputManager, x or mouse.X, y or mouse.Y, mouseButton1, true, nil, 0);
end);

genv.mouse1release = newcclosure(function(x, y)
	_assert(x == nil or _typeof(x) == "number", "invalid argument #1 to 'mouse1release' (number or nil expected)");
	_assert(y == nil or _typeof(y) == "number", "invalid argument #2 to 'mouse1release' (number or nil expected)");
    _sendMouseButtonEvent(virtualInputManager, x or mouse.X, y or mouse.Y, mouseButton1, false, nil, 0);
end);

genv.mouse1click = newcclosure(function(x, y)
	_assert(x == nil or _typeof(x) == "number", "invalid argument #1 to 'mouse1click' (number or nil expected)");
	_assert(y == nil or _typeof(y) == "number", "invalid argument #2 to 'mouse1click' (number or nil expected)");
    local clickX, clickY = x or mouse.X, y or mouse.Y;
    _sendMouseButtonEvent(virtualInputManager, clickX, clickY, mouseButton1, true, nil, 0);
    _sendMouseButtonEvent(virtualInputManager, clickX, clickY, mouseButton1, false, nil, 0);
end);

genv.mouse2press = newcclosure(function(x, y)
	_assert(x == nil or _typeof(x) == "number", "invalid argument #1 to 'mouse2press' (number or nil expected)");
	_assert(y == nil or _typeof(y) == "number", "invalid argument #2 to 'mouse2press' (number or nil expected)");
    _sendMouseButtonEvent(virtualInputManager, x or mouse.X, y or mouse.Y, mouseButton2, true, nil, 0);
end);

genv.mouse2release = newcclosure(function(x, y)
	_assert(x == nil or _typeof(x) == "number", "invalid argument #1 to 'mouse2release' (number or nil expected)");
	_assert(y == nil or _typeof(y) == "number", "invalid argument #2 to 'mouse2release' (number or nil expected)");
    _sendMouseButtonEvent(virtualInputManager, x or mouse.X, y or mouse.Y, mouseButton2, false, nil, 0);
end);

genv.mouse2click = newcclosure(function(x, y)
	_assert(x == nil or _typeof(x) == "number", "invalid argument #1 to 'mouse2click' (number or nil expected)");
	_assert(y == nil or _typeof(y) == "number", "invalid argument #2 to 'mouse2click' (number or nil expected)");
    local clickX, clickY = x or mouse.X, y or mouse.Y;
    _sendMouseButtonEvent(virtualInputManager, clickX, clickY, mouseButton2, true, nil, 0);
    _sendMouseButtonEvent(virtualInputManager, clickX, clickY, mouseButton2, false, nil, 0);
end);

genv.mousemoverel = newcclosure(function(x, y)
	_assert(_typeof(x) == "number", _stringformat("invalid argument #1 to 'mousemoverel' (number expected, got %s)", _typeof(x)));
	_assert(_typeof(y) == "number", _stringformat("invalid argument #2 to 'mousemoverel' (number expected, got %s)", _typeof(y)));
    local inset = _getGuiInset(guiService);
    _sendMouseMoveEvent(virtualInputManager, mouse.X + inset.X + x, mouse.Y + inset.Y + y, nil);
end);

genv.mousemoveabs = newcclosure(function(x, y)
	_assert(_typeof(x) == "number", _stringformat("invalid argument #1 to 'mousemoveabs' (number expected, got %s)", _typeof(x)));
	_assert(_typeof(y) == "number", _stringformat("invalid argument #2 to 'mousemoveabs' (number expected, got %s)", _typeof(y)));
    local inset = _getGuiInset(guiService);
    _sendMouseMoveEvent(virtualInputManager, inset.X + x, inset.Y + y, nil);
end);

genv.mousescroll = newcclosure(function(amount)
	_assert(_typeof(amount) == "number", _stringformat("invalid argument #1 to 'mousescroll' (number expected, got %s)", _typeof(amount)));
    for i = 1, _mathabs(_mathfloor(amount / 120)) do
        _sendMouseWheelEvent(virtualInputManager, mouse.X, mouse.Y, amount >= 0, nil);
        _taskwait();
    end
end);

genv.decompile = newcclosure(function(target)
    	local bytecode = getscriptbytecode(target)

    	if bytecode then
        	local output = request({
            		Url = "http://api.plusgiant5.com/konstant/decompile", -- found in dex. credits to plusgiant5 🙏
            		Method = "POST",
            		Body = bytecode,
			Headers = {
				["Content-Type"] = "text/plain"
			}
        	})
      
        	if output.StatusCode == 200 then
            		return output.Body
        	end

        	return "-- failed to decompile bytecode: " .. output.StatusMessage
    	end

	return "-- failed to decompile bytecode"
end)

genv.iy = newcclosure(function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)

    end
    local ok, err = pcall(install_original_helpers)
    if not ok then warn("[IconCrack] Input helpers: " .. tostring(err)) end
end

task.spawn(function()
    for _ = 1, 600 do
        pcall(patch_menu)
        if state.source or (state.verify and state.sanitize) then break end
        task.wait(0.25)
    end
    if state.source or (state.verify and state.sanitize) then
        print("[IconCrack] Exact @Icon_Crack key installed")
        while true do
            pcall(patch_menu)
            task.wait(3)
        end
    else
        warn("[IconCrack] Activation UI patch could not be verified")
    end
end)
