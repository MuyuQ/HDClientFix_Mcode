-- HDClientFix_Mcode 2.0.2; character fixes by Mcode, WDM translation by MuyuQ.
local ADDON, ns = ...
HDClientFix_Mcode = ns
ns.version = "2.0.2"

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

function ns.Initialize()
    if ns.ready then return end
    local db = type(HDClientFix_McodeDB) == "table" and HDClientFix_McodeDB or {}
    HDClientFix_McodeDB = db
    if type(db.character) ~= "table" then
        db.character = type(Mcode_CharPanelFixDB) == "table" and copy(Mcode_CharPanelFixDB) or {}
    end
    if type(db.map) ~= "table" then db.map = {} end
    if db.map.transport == nil then db.map.transport = true end
    for key, value in pairs(ns.CharacterDefaults or {}) do
        if db.character[key] == nil then db.character[key] = value end
    end
    db.schema = 1
    -- A still-loaded legacy addon owns this table until the next clean restart.
    if not (ns.OldAddonConflict and ns.OldAddonConflict("CharPanelFix_Mcode")) then
        Mcode_CharPanelFixDB = nil
    end
    HDClientFix_McodeCharacterDB = type(HDClientFix_McodeCharacterDB) == "table"
        and HDClientFix_McodeCharacterDB or {}
    local role = HDClientFix_McodeCharacterDB
    if role.characterDisabled == true and type(role.character) ~= "table" then
        role.character = {}
        for key in pairs(ns.CharacterDefaults or {}) do role.character[key] = false end
    end
    role.characterDisabled = nil
    if type(role.character) == "table" then
        setmetatable(role.character, { __index = db.character })
    end
    ns.db, ns.role, ns.ready = db, role, true
end

function ns.GetCharacterDB()
    ns.Initialize()
    return ns.role.character or ns.db.character
end

function ns.TransportEnabled()
    ns.Initialize()
    if ns.role.transport ~= nil then return ns.role.transport == true end
    return ns.db.map.transport == true
end

function ns.SetTransport(value)
    ns.Initialize()
    if ns.role.transport ~= nil then ns.role.transport = value
    else ns.db.map.transport = value end
    if ns.MapTransport then ns.MapTransport.Apply() end
end

function ns.Print(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[HD 客户端修复]|r " .. text) end
end

function ns.OldAddonConflict(name)
    return type(IsAddOnLoaded) == "function" and IsAddOnLoaded(name) == true
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" or name == ADDON then ns.Initialize() end
end)
