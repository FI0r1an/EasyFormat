local json = {}

local function charString(str, idx)
    local name = ""
    idx = idx + 1

    while idx <= #str do
        local ch = str:sub(idx, idx)

        if ch == "\"" then break end

        name = name .. ch
        idx = idx + 1
    end

    return name, idx+1
end

local function charVar(str, idx)
    if str:sub(idx, idx+3) == "true" then
        return true, idx+4
    elseif str:sub(idx, idx+3) == "null" then
        return nil, idx+4
    elseif str:sub(idx, idx+4) == "false" then
        return false, idx+5
    end

    error("Unfinished Word At Position:" .. tostring(idx))
end

local function charNumber(str, idx)
    local name = ""
    local isn = false
    local isnn = false

    while idx <= #str do
        local ch = str:sub(idx, idx)

        if (ch ~= "." and ch ~= "-" and tonumber(ch) == nil) or (ch == "." and isn) or (ch == "-" and isnn) then break end

        if ch == "." then isn = true end
        if ch == "-" then isnn = true end

        name = name .. ch
        idx = idx + 1
    end

    return tonumber(name), idx
end

local function skipWhitespace(str, idx)
    local ws = "\n\t\r "
    local ch = str:sub(idx, idx)

    while idx <= #str and (ws:find(ch, 1, true)) do
        idx = idx + 1
        ch = str:sub(idx, idx)
    end

    return idx
end

local function charArray(str, idx)
    local r = {}
    idx = idx + 1
    local p
    local id = 1

    while idx <= #str do
        idx = skipWhitespace(str, idx)
        local ch = str:sub(idx, idx)

        if ch == "]" then
            break
        elseif ch == "," then
            idx = skipWhitespace(str, idx+1)
        end

        local v, i = json.parse(str, idx)
        p = v

        r[id] = v
        idx = i
        id = id + 1

        ch = str:sub(idx, idx)

        if ch == "]" then
            break
        end
    end

    return r, idx+1
end

local function charObject(str, idx)
    local r = {}
    idx = idx + 1

    while idx <= #str do
        idx = skipWhitespace(str, idx)

        if str:sub(idx, idx) == "}" then
            break
        elseif str:sub(idx, idx) == "," then
            idx = skipWhitespace(str, idx+1)
        end

        local key, i = json.parse(str, idx)
        idx = i

    if type(key) == "string" then else error("Only String can be Keys" .. tostring(idx)) end

        idx = skipWhitespace(str, idx)

        if str:sub(idx, idx) ~= ":" then
            error("Missing \":\" at Position:" .. tostring(idx))
        else
            idx = idx + 1
        end

        idx = skipWhitespace(str, idx)

        local value, i = json.parse(str, idx)
        idx = i

        r[key] = value
    end

    return r, idx+1
end

local charMap = {
    ["\""] = charString,
    t = charVar,
    n = charVar,
    f = charVar,
    ["["] = charArray,
    ["-"] = charNumber,
    ["{"] = charObject
}

for i = 0, 9 do
    charMap[tostring(i)] = charNumber
end

function json.tostring(tbl)
    local result = ""

    for k, v in pairs(tbl) do
        local t = {k, " = ", [4] = ", "}

        t[3] = "\"" .. tostring(v) .. "\""

        if type(v) == "table" then
            t[3] = json.tostring(v)
        end
        if type(k) == "number" then
            t[1] = "[" .. tostring(k) .. "]"
        end

        if type(v) == "function" then
            t[3] = "func"
        elseif type(v) == "boolean" or type(v) == "number" then
            t[3] = tostring(v)
        end

        result = result .. table.concat(t)
    end

    result = result:sub(1, -3)

    return "{ " .. result .. " }"
end

function json.parse(str, idx)
    local ch = str:sub(idx, idx)

    if charMap[ch] then
        return charMap[ch](str, idx)
    end
    error"something wrong when parsing json"
end

function json.decode(str)
    local idx = 1

    while idx <= #str do
        local ch = str:sub(idx, idx)

        if ch == "\t" or ch == " " then
            idx = idx + 1
        else
            return json.parse(str, idx)
        end
    end
end

local function tov(v)
    local t = type(v)

    if t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "string" then
        return "\"" .. v .. "\""
    elseif t == "table" then
        return json.encode(v)
    end

    return tostring(v)
end

function json.encode(tbl)
    local result = ""
    local sp, ep

    for k, v in pairs(tbl) do
        local t

        if type(k) == "number" then
            sp = "[ "
            ep = " ]"

            t = {tov(v), ", "}
        else
            sp = "{ "
            ep = " }"

            t = {"\"" .. k .. "\"", " : ", tov(v), ", "}
        end

        result = result .. table.concat(t)
    end

    result = result:sub(1, -3)

    return sp .. result .. ep
end

function json.decodeFromFile(fn)
    local file = io.open(fn, "r")
    local txt = file:read"*a"
    file:close()
    return json.decode(txt)
end

return json