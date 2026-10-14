-- Native 3.3.5 settings; every existing repair retains its own switch.
local ADDON, ns = ...
local groups = {
    { title = "角色面板", help = "主要修复需要 ElvUI＋ElvUI_Enhanced，并启用其角色面板模块。", dependency = "character", items = {
        { "enhancedEnable", "为新角色补开 Enhanced 角色面板", "仅补充未设置的开关；尊重你明确关闭的状态。关闭此项不会撤销已补开的模块。", "enhanced" },
        { "sidebar", "修复属性、称号与装备管理侧栏互斥", "关闭后需 /reload 完全恢复。" },
        { "sidebarDefaultToStats", "打开角色面板时默认显示属性页", "依赖侧栏修复。" },
        { "clientGS", "隐藏角色面板的重复装等与 GS 文字", "保留 GearScoreLite 的数据处理；关闭后需 /reload 恢复。" },
        { "itemLevel", "统一平均物品等级显示", "按实际装备件数计算，保留整数。" },
        { "clientStatPanels", "隐藏重复的客户端属性面板", "关闭后需 /reload 完全恢复。" },
        { "clientToggleButtons", "隐藏重复的面板切换按钮", "关闭后需 /reload 完全恢复。" },
        { "model", "修复角色模型显示", "关闭后需 /reload 完全恢复。" },
        { "modelControls", "角色模型拖动旋转与滚轮缩放", "关闭时移除本插件安装的交互。" },
        { "modelFeatures", "补充角色模型的种族背景", "关闭后不再补充；已改的背景请在 ElvUI 设置中调整。" },
        { "clientPanelArt", "恢复客户端面板底图", "默认关闭；与 ElvUI 半透明面板属于不同风格。" },
        { "clientTitles", "修复称号与公会名字重叠", "关闭后需 /reload 完全恢复。" },
        { "clientTitleWidgets", "显示客户端原称号控件", "默认关闭；关闭后需 /reload 完全恢复。" },
        { "enhancedGeometry", "调整属性行距与物品等级字号", "关闭后需 /reload 完全恢复。" },
        { "tabAnchor", "修复底部标签行的位置", "需要 ElvUI 角色窗口底框；关闭后需 /reload 完全恢复。", "backdrop" },
    } },
    { title = "其他窗口与提示", help = "各项依赖分别标注，不要求全部安装 ElvUI_Enhanced。", items = {
        { "textFit", "修复公会页与地下城查找器文字截断", "需要 ElvUI；关闭后需 /reload 完全恢复。", "elvui" },
        { "dressUpControls", "试衣间左键拖动旋转", "需要 ElvUI；保留旋转按钮，已有鼠标处理时让位。", "elvui" },
        { "selfGS", "悬停自己时补充 GS 提示", "需要 GearScoreLite；不依赖 ElvUI_Enhanced。", "gsl" },
        { "fonts", "注册 AvantGarde LT 字体兼容名称", "默认关闭；需要 LibSharedMedia-3.0，关闭后需 /reload 恢复。", "lsm" },
    } },
    { title = "地图", help = "需要当前 HD 客户端内置的 WDM；不依赖 ElvUI。", dependency = "map", items = {
        { "transport", "汉化船只与飞艇目的地提示", "覆盖 19 种提示；即时切换，关闭后恢复原文字。", "map" },
    } },
}

local function text(parent, value, font)
    local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
    fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP"); fs:SetText(value)
    if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(true) end
    return fs
end

local function available(dependency)
    if dependency == "map" then return ns.MapTransport.Status() end
    if ns.characterConflict then return "旧 CharPanelFix_Mcode 仍在运行，请移出旧目录后重启", false end
    if dependency == "elvui" then return "需要 ElvUI", ns.HasElvUI and ns.HasElvUI() end
    if dependency == "enhanced" then return "需要 ElvUI_Enhanced 角色面板模块", ns.HasEnhanced and ns.HasEnhanced() end
    if dependency == "backdrop" then
        return "需要 ElvUI 角色窗口底框", ns.HasElvUI and ns.HasElvUI()
            and CharacterFrame and CharacterFrame.backdrop and CharacterFrameTab1 ~= nil
    end
    if dependency == "gsl" then
        return "需要 GearScoreLite", type(GearScore_GetScore) == "function" and type(GearScore_GetQuality) == "function"
    end
    if dependency == "lsm" then
        return "需要 LibSharedMedia-3.0", ns.HasFontLibrary and ns.HasFontLibrary()
    end
    return ns.CharacterStatus()
end

local function register()
    if ns.options or type(InterfaceOptions_AddCategory) ~= "function" then return end
    ns.Initialize()
    local panel = CreateFrame("Frame", "HDClientFixOptions", InterfaceOptionsFramePanelContainer or UIParent)
    panel.name = "HD 客户端修复"; panel:SetAllPoints(panel:GetParent()); panel:Hide()
    local scroll = CreateFrame("ScrollFrame", "HDClientFixOptionsScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -16); scroll:SetPoint("BOTTOMRIGHT", -36, 16)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(400); content:SetHeight(1400); scroll:SetScrollChild(content)
    local rows = {}
    local function paragraph(value, font, gap)
        rows[#rows + 1] = { label = text(content, value, font), gap = gap or 8 }
        return rows[#rows]
    end
    paragraph("Mcode HD 客户端修复", "GameFontNormalLarge", 14)
    paragraph("补充修复 HD 客户端中的显示与交互问题。\n各项功能独立开启或关闭，旧版设置在升级时保留。\n部分项目关闭后需要 /reload，具体条件见选项说明。", nil, 16)
    local statusRows, boxes = {}, {}
    for _, group in ipairs(groups) do
        paragraph(group.title, "GameFontNormal", 4)
        paragraph(group.help, nil, 6)
        if group.dependency then
            local row = paragraph("", "GameFontHighlightSmall", 10)
            row.dependency = group.dependency; statusRows[#statusRows + 1] = row
        end
        for _, item in ipairs(group.items) do
            local key, dependency = item[1], item[4] or group.dependency
            local box = CreateFrame("CheckButton", "HDClientFixOption" .. key, content, "UICheckButtonTemplate")
            box:SetWidth(24); box:SetHeight(24)
            local row = { box = box, label = text(content, item[2]), gap = 2 }
            rows[#rows + 1] = row
            local help = paragraph(item[3], "GameFontHighlightSmall", 10); help.indent = 26
            box:SetScript("OnClick", function(self)
                if type(InCombatLockdown) == "function" and InCombatLockdown() then
                    self:SetChecked(key == "transport" and ns.TransportEnabled()
                        or key ~= "transport" and ns.GetCharacterDB()[key] == true)
                    ns.Print("战斗结束后再修改修复选项。"); return
                end
                local value = self:GetChecked() and true or false
                if key == "transport" then ns.SetTransport(value)
                else ns.CharacterSet(key, value) end
                panel:Refresh()
            end)
            boxes[#boxes + 1] = { box = box, key = key, dependency = dependency }
        end
    end
    paragraph("版本 " .. ns.version .. " · /hdfix 打开设置\n角色面板修复作者：Mcode；地图交通提示汉化：MuyuQ。", "GameFontHighlightSmall", 8)
    function panel:Layout()
        local width, y = math.max(100, scroll:GetWidth() - 8), 0
        content:SetWidth(width)
        for _, row in ipairs(rows) do
            local indent = row.box and 26 or row.indent or 0
            row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT", indent, -y)
            row.label:SetWidth(width - indent); row.label:SetHeight(0)
            local height = math.max(row.box and 24 or 0, math.ceil(row.label:GetStringHeight()) + 4)
            row.label:SetHeight(height)
            if row.box then row.box:ClearAllPoints(); row.box:SetPoint("TOPLEFT", -4, -y + 4) end
            y = y + height + row.gap
        end
        content:SetHeight(y + 8); scroll:UpdateScrollChildRect()
    end
    function panel:Refresh()
        for _, item in ipairs(boxes) do
            item.box:SetChecked(item.key == "transport" and ns.TransportEnabled()
                or item.key ~= "transport" and ns.GetCharacterDB()[item.key] == true)
            local _, ready = available(item.dependency)
            local combat = type(InCombatLockdown) == "function" and InCombatLockdown()
            if ready and not combat then item.box:Enable() else item.box:Disable() end
        end
        for _, row in ipairs(statusRows) do
            local message = available(row.dependency)
            row.label:SetText("状态：" .. message)
        end
        self:Layout()
    end
    panel:SetScript("OnShow", function(self) self:Refresh() end)
    panel:SetScript("OnSizeChanged", function(self) self:Layout() end)
    local elapsed = 0
    panel:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed >= 1 then elapsed = 0; self:Refresh() end
    end)
    panel.scroll, panel.boxes = scroll, boxes
    InterfaceOptions_AddCategory(panel); ns.options = panel
end

function ns.ShowOptions()
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        ns.Print("战斗结束后输入 /hdfix 查看设置。"); return
    end
    register()
    if ns.options and type(InterfaceOptionsFrame_OpenToCategory) == "function" then
        InterfaceOptionsFrame_OpenToCategory(ns.options)
        InterfaceOptionsFrame_OpenToCategory(ns.options)
    end
end
SLASH_HDCLIENTFIX1 = "/hdfix"
SlashCmdList.HDCLIENTFIX = function() ns.ShowOptions() end
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" or name == ADDON then register() end
end)
