-- HDClientFix_Mcode 2.0.3; original 19 WDM translations by MuyuQ.
local ADDON, ns = ...
ns = ns or {}
local M = { installed = false }
ns.MapTransport = M
local translations = {
    ["Ship to Auberdine"] = "前往奥伯丁的船只",
    ["Ship to Booty Bay"] = "前往藏宝海湾的船只",
    ["Zeppelin to Brill"] = "前往布瑞尔的飞艇",
    ["Ship to Daggercap Bay"] = "前往匕鞘湾的船只",
    ["Zeppelin to Durotar"] = "前往杜隆塔尔的飞艇",
    ["Ship to Exodar"] = "前往埃索达的船只",
    ["Zeppelin to Grom'gol"] = "前往格罗姆高的飞艇",
    ["Ship to Kamagua"] = "前往卡玛古的船只",
    ["Ship to Menethil Harbor"] = "前往米奈希尔港的船只",
    ["Ship to Moa'ki"] = "前往莫亚基的船只",
    ["Ship to Ratchet"] = "前往棘齿城的船只",
    ["Ship to Stormwind"] = "前往暴风城的船只",
    ["Ship to Teldrassil"] = "前往泰达希尔的船只",
    ["Ship to Theramore"] = "前往塞拉摩的船只",
    ["Zeppelin to Thunder Bluff"] = "前往雷霆崖的飞艇",
    ["Ship to Unu'pe"] = "前往乌努比的船只",
    ["Ship to Valiance Keep"] = "前往无畏要塞的船只",
    ["Zeppelin to Vengeance Landing"] = "前往复仇港的飞艇",
    ["Zeppelin to Warsong Hold"] = "前往战歌要塞的飞艇",
}

local originals = setmetatable({}, { __mode = "k" })
local events = CreateFrame("Frame")

function M.Apply()
    -- WDM 在加载数据时已缓存语言表的文字，每次 ShowPOIs 又会写回标记。
    -- 只修改 WDM 创建的标记名称，原生悬停处理会读取这个名称。
    for i = 1, NUM_WORLDMAP_ATLAS_POI or 0 do
        local marker = _G["WorldMapFrameAtlasPOI" .. i]
        if marker then
            local previous = originals[marker]
            local enabled = not ns.mapConflict and (not ns.TransportEnabled or ns.TransportEnabled())
            if not enabled then
                if previous and marker.name == previous.translated then marker.name = previous.original end
                originals[marker] = nil
            else
                local translated = translations[marker.name]
                if translated then
                    originals[marker] = { original = marker.name, translated = translated }
                    marker.name = translated
                elseif previous and marker.name ~= previous.translated then
                    originals[marker] = nil
                end
            end
            if type(MouseIsOver) == "function" and MouseIsOver(marker)
                and type(WorldMapPOI_OnEnter) == "function" then
                WorldMapPOI_OnEnter(marker)
            end
        end
    end
end

local function Install()
    if ns.OldAddonConflict and ns.OldAddonConflict("WDM_ZH_Mcode") then
        ns.mapConflict = true; M.Apply()
        if ns.ScheduleLegacyConflictNotice then ns.ScheduleLegacyConflictNotice() end
        return
    end
    if M.installed then return end
    if not LibStub or type(hooksecurefunc) ~= "function" then return end
    local ace = LibStub("AceAddon-3.0", true)
    if not ace then return end
    local wdm = ace:GetAddon("WDM", true)
    if not wdm then return end
    local atlas = wdm:GetModule("AtlasPOI", true)
    if not atlas or type(atlas.ShowPOIs) ~= "function" then return end

    hooksecurefunc(atlas, "ShowPOIs", M.Apply)
    M.installed = true
    M.Apply()
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" or name == "WDM" or name == ADDON or name == "WDM_ZH_Mcode" then
        Install()
    end
end)

function M.Status()
    if ns.mapConflict then
        return "冲突：旧 WDM_ZH_Mcode 仍在运行。\n地图交通汉化已暂停。\n请移出旧目录并完全重启游戏。", false
    end
    if not M.installed then return "未加载 WDM 或其 AtlasPOI 模块", false end
    return "WDM 已就绪；覆盖 19 种船只与飞艇目的地", true
end
