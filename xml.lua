local function newState(source)
    _G.STATE = {
        source = source,
        ptr = 1,
        line = 1,
        lptr = 1
    }
end

local function newNode(name)
    return {
        name = name,
        children = {},
        property = {},
        value = nil
    }
end

local function addChild(node, child)
    node.children[#(node.children) + 1] = child
end

local function addProperty(node, k, v)
    node.property[k] = v
end

local function current()
    local idx = _G.STATE.ptr
    return _G.STATE.source:sub(idx, idx)
end

local _a = assert
local function assert(b, msg)
    _a(b, (msg or "ERROR:") .. string.format("\nLine: %d\n       Position: %d \tCharacter: %s",
        _G.STATE.line, _G.STATE.lptr, current()))
end

local function lookahead()
    local idx = _G.STATE.ptr + 1
    return _G.STATE.source:sub(idx, idx)
end

local function next()
    local idx = _G.STATE.ptr
    local char = current()
    _G.STATE.ptr = idx + 1
    local i = _G.STATE.lptr
    _G.STATE.lptr = i + 1
    return char
end

local function isSpace()
    return current() == ' ' or current() == '\t'
end

local function isLine()
    return current() == '\r' or current() == '\n'
end

local function notEnd()
    return _G.STATE.ptr <= #_G.STATE.source
end

local function isComment()
    local oldp = _G.STATE.ptr
    local oldlp = _G.STATE.lptr
    local oldli = _G.STATE.line
    local old = next()
    if old == '<' and current() == '!' and lookahead() == '-' then
        next()
        if lookahead() == '-' then
            next(); next()
            return true
        end
    end
    _G.STATE.ptr = oldp
    _G.STATE.lptr = oldlp
    _G.STATE.line = oldli
    return false
end

local function skipComment()
    while notEnd() do
        if isLine() then
            local old = next()
            if old ~= current() then
                next()
            end
            _G.STATE.lptr = 1
            _G.STATE.line = _G.STATE.line + 1
        else
            local old = next()
            if old == '-' and current() == '-' and lookahead() == '>' then
                next()
                next()
                return
            end
        end
    end
end

local function skipWhitespace()
    local isc = isComment()
    while isSpace() or isLine() or isc do
        if isLine() then
            local old = next()
            if old ~= current() and isLine() then
                next()
            end
            _G.STATE.lptr = 1
            _G.STATE.line = _G.STATE.line + 1
        elseif isc then
            skipComment()
        else
            next()
        end
        isc = isComment()
    end
end

local function readString()
    assert(current() == '\'' or current() == '\"', "Not a string")
    local old = next()
    local s = ""
    while notEnd() and current() ~= old do
        s = s .. next()
    end
    next()
    return s
end

local function readName()
    local r = ""
    while notEnd() and (isLine() == false) do
        r = r .. next()
    end
    return r
end

local function readNodeName()
    local r = ""
    while notEnd() do
        r = r .. next()
        if current() == '>' or isSpace() then
            break
        end
    end
    return r
end

local function readValue()
    if current() == '\'' or current() == '\"' then
        return readString()
    else
        local n = readName()
        return tonumber(n) or n
    end
end

local readChild

local function readNode()
    assert(next() == '<', "Unknown start operator")
    local name = readNodeName()
    local node = newNode(name)
    skipWhitespace()
    while current() ~= '>' do
        assert(notEnd(), "Missing >")
        skipWhitespace()
        local cname = readNodeName()
        skipWhitespace()
        assert(next() == "=", "Missing =")
        skipWhitespace()
        local cvalue = readValue()
        addProperty(node, cname, cvalue)
        if current() == '>' then break end
        assert(isLine() or isSpace(), "Need whitespaces between names")
    end
    next()
    skipWhitespace()
    local c = readChild()
    if type(c) == "table" then
        node.children = c
    else
        node.value = c
    end
    skipWhitespace()
    assert(current() == '<' and lookahead() == '/', "Missing end part")
    next(); next()
    local _name = readNodeName()
    assert(_name == name, "Unequaled name")
    next()
    return node
end

readChild = function ()
    skipWhitespace()
    if current() == '<' then
        local c = {}
        while notEnd() and current() == '<' and lookahead() ~= '/' do
            skipWhitespace()
            c[#c + 1] = readNode()
            
        end
        
        return c
    else
        local v = readValue()
        return v
    end
end

local function readTree(str)
    newState(str)
    skipWhitespace()
    return readNode()
end

return {
    ReadTree = readTree,
    ReadFile = function (path)
        local file = io.open(path, "r")
        local c = readTree(file:read("*a"))
        file:close()
        return c
    end
}