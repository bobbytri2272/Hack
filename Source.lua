local Z_VALUE = "4119"
local Z_FLAG = gg.TYPE_DWORD
local MAX_Z = 800
local SAMPLES = 40
local TOTAL_MS = 20000
local SAMPLE_INTERVAL = math.floor(TOTAL_MS / SAMPLES)
gg.clearResults()
gg.removeListItems(gg.getListItems(true))

local function readX(addr)
    local t = gg.getValues({{address = addr, flags = Z_FLAG}})
    if t and t[1] then return t[1].value end
    return nil
end

local function sampleX(addr)
    local s = {}
    gg.clearResults()
    for i = 1, SAMPLES do
        local v = readX(addr)
        if v ~= nil then s[#s+1] = v end
        gg.sleep(SAMPLE_INTERVAL)
    end
    return s
end

local function decide(samples)
    local pos, neg = 0, 0
    for _, v in ipairs(samples) do
        if v < 0 then neg = neg + 1 else pos = pos + 1 end
    end
    if neg > pos then return "NEG" else return "POS" end
end

while true do
    gg.clearResults()
    gg.searchNumber(Z_VALUE, Z_FLAG)
    local zs = gg.getResults(MAX_Z)
    if zs and #zs > 0 then
        local xAddr = zs[1].address - 4
        local samples = sampleX(xAddr)
        if #samples >= 3 then
            local dir = decide(samples)
            local xFreeze = (dir == "NEG") and 1871900 or -1871900
            local yFreeze = 0

            local setZList = {}
            local freezeList = {}

            for i = 1, #zs do
                local z = zs[i]
                setZList[#setZList+1] = {
                    address = z.address,
                    flags = Z_FLAG,
                    value = z.value or 4119
                }
                local xaddr = z.address - 4
                local yaddr = z.address - 8
                local zaddr = z.address

                freezeList[#freezeList+1] = {
                    address = xaddr,
                    flags = Z_FLAG,
                    value = tostring(xFreeze),
                    freeze = true
                }
                freezeList[#freezeList+1] = {
                    address = yaddr,
                    flags = Z_FLAG,
                    value = tostring(yFreeze),
                    freeze = true
                }
                freezeList[#freezeList+1] = {
                    address = zaddr,
                    flags = Z_FLAG,
                    value = "4119",  -- Khóa Z luôn
                    freeze = true
                }
            end
            
            if #setZList > 0 then gg.setValues(setZList) end
            if #freezeList > 0 then gg.addListItems(freezeList) gg.clearResults() end
            break
        end
    end
    gg.sleep(200)
end
