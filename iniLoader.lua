local ini = {}
local utf8 = require"utf8"

function utf8.sub(str, i, j)
    if i == 0 and j == 0 then
        return nil
    end
    local ii = i
    local jj = j
    if ii < 0 then ii = utf8.len(str)-math.abs(ii) + 1 end
    if jj < 0 then jj = utf8.len(str)-math.abs(jj) + 1 end
    local r = ""
    local s = utf8.offset(str, ii)
    for p = ii+1, jj+1 do
        local e = utf8.offset(str, p) - 1
        r = r .. str:sub(s, e)
        s = e+1
    end
    return r
end

;(getmetatable"").__sub = function (str, a, b)
    return utf8.sub(str, a, b)
end

function ini.LoadFromFile(path)
    local file = io.open(path, "r")
    local r = ini.Load(file:read("*a"))
    file:close()
    return r
end

local wc = {
    ["\n"] = true,
    ["\r"] = true,
    ["\t"] = true,
    [" "] = true
}

local skipWhitespace = function (str, idx)
    while wc[str:sub(idx, idx)] do
        idx = idx + 1
    end
    return idx
end

local readName = function (str, idx)
    local name = ""

    while idx <= #str and str:sub(idx, idx) ~= ']' do
        name = name .. str:sub(idx, idx)
        idx = idx + 1
    end

    return name, idx
end

local readVarName = function (str, idx)
    local name = ""

    while idx <= #str do
        name = name .. str:sub(idx, idx)
        idx = idx + 1
        if str:sub(idx, idx) == "=" or wc[str:sub(idx, idx)] then
            break
        end
    end

    return name, idx
end

local readValue = function (str, idx)
    local name = ""

    while idx <= #str do
        name = name .. str:sub(idx, idx)
        idx = idx + 1
        if str:sub(idx, idx) == "\r" or str:sub(idx, idx) == "\n" then
            break
        end
    end

    return name, idx
end

local readVar = function (str, idx)
    local r = {}

    while idx <= #str and str:sub(idx, idx) ~= '[' do
        idx = skipWhitespace(str, idx)

        local left, right

        left, idx = readVarName(str, idx)
        idx = skipWhitespace(str, idx)
        assert(str:sub(idx, idx) == '=', "Missing \"=\"")
        idx = idx + 1
        idx = skipWhitespace(str, idx)
        right, idx = readValue(str, idx)
        right = tonumber(right) or right

        r[tonumber(left) or left] = right
    end

    return r, idx
end

function ini.Load(str)
    local idx = 1
    local result = {}

    while idx <= #str do
        idx = skipWhitespace(str, idx)
        local name
        local char = str:sub(idx, idx)
        assert(char == "[", "The first character of INI file must be \"[\"")
        idx = idx + 1
        name, idx = readName(str, idx)
        assert(str:sub(idx, idx) == "]", "Missing \"]\"")
        idx = idx + 1
        result[name], idx = readVar(str, idx)
    end

    return result
end

return ini