-- HDClientFix_Mcode 2.0.6; Dire Maul outdoor map navigation.
local ADDON, ns = ...
local M = {
    installed = false,
    artName = "DireMaulEntrance",
    mapID = 689,
    parentMapID = 121,
    label = "厄运之槌（室外）",
    wrappers = {},
    menuDepth = 0,
    menuAdded = false,
}
ns.MapNavigation = M

local function pack(...)
    return { n = select("#", ...), ... }
end

local function unpackResult(values)
    return unpack(values, 1, values.n)
end

function M.IsCurrentMap()
    return type(GetMapInfo) == "function" and GetMapInfo() == M.artName
end

local function addMenuItem()
    if type(GetCurrentMapContinent) ~= "function" or GetCurrentMapContinent() ~= 1 then return false end
    if type(UIDropDownMenu_CreateInfo) ~= "function"
        or type(UIDropDownMenu_AddButton) ~= "function" then return false end

    local info = UIDropDownMenu_CreateInfo()
    info.text = M.label
    info.value = M.mapID
    info.checked = M.IsCurrentMap()
    info.func = function()
        if type(SetMapByID) == "function" then SetMapByID(M.mapID) end
        if type(UIDropDownMenu_SetText) == "function" and WorldMapZoneDropDown then
            UIDropDownMenu_SetText(WorldMapZoneDropDown, M.label)
        end
        if type(CloseDropDownMenus) == "function" then CloseDropDownMenus() end
    end
    UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
    return true
end

local function wrapInitializer(original)
    return function(...)
        local outer = M.menuDepth == 0
        if outer then M.menuAdded = false end
        M.menuDepth = M.menuDepth + 1
        local results = pack(original(...))
        M.menuDepth = M.menuDepth - 1
        if not M.menuAdded and addMenuItem() then M.menuAdded = true end
        if outer then M.menuAdded = false end
        return unpackResult(results)
    end
end

local function wrapUpdate(original)
    return function(...)
        local results = pack(original(...))
        if M.IsCurrentMap() and type(UIDropDownMenu_SetText) == "function"
            and WorldMapZoneDropDown then
            UIDropDownMenu_SetText(WorldMapZoneDropDown, M.label)
        end
        return unpackResult(results)
    end
end

local function wrapZoomOut(original)
    return function(...)
        if M.IsCurrentMap() and type(SetMapByID) == "function" then
            if WorldMapTooltip and type(WorldMapTooltip.Hide) == "function" then
                WorldMapTooltip:Hide()
            end
            SetMapByID(M.parentMapID)
            return
        end
        return original(...)
    end
end

local function installWrapper(name, factory)
    local original = _G[name]
    if type(original) ~= "function" or original == M.wrappers[name] then return false end
    local wrapper = factory(original)
    M.wrappers[name] = wrapper
    _G[name] = wrapper
    return true
end

function M.Install()
    if type(SetMapByID) ~= "function" or type(GetMapInfo) ~= "function" then return false end
    installWrapper("WorldMapZoomOutButton_OnClick", wrapZoomOut)
    installWrapper("WorldMapZoneDropDown_Initialize", wrapInitializer)
    installWrapper("WDMZoneDropDown_Initialize", wrapInitializer)
    installWrapper("WorldMapZoneDropDown_Update", wrapUpdate)
    M.installed = M.wrappers.WorldMapZoomOutButton_OnClick ~= nil
    return M.installed
end

function M.Status()
    if M.installed then return "厄运之槌室外地图导航已就绪" end
    return "厄运之槌室外地图导航尚未就绪"
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" or name == ADDON or name == "WDM" or name == "Mapster" then
        M.Install()
    end
end)
