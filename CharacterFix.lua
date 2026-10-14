--[[--------------------------------------------------------------------------
    CharPanelFix_Mcode  —  3.3.5a (HD 客户端 / 蜗牛整合包) 角色面板修复

    背景
    ----
    这个客户端的 Interface\FrameXML 是从 MoP 时代移植回来的（烤在 patch-enus-9.mpq
    里），和 ElvUI / ElvUI_Enhanced / GearScoreLite 三者互相不知道对方存在，于是
    "角色"面板右侧的属性区被三层东西同时往同一块像素上画：

      1) 客户端自带的 MoP 版 PaperDollFrame：CharacterTitleText 和
         CharacterGuildText 的锚点是完全同一个点；另有一整套写死字号的高清
         "装备等级"字体串（GearScore2_B = ITEM_LEVEL:sub(1,-4)，PGearScore =
         CalculateAverage().." ("..PersonalGearScore:GetText()..")"，ARIALN 28），
         以及 PlayerStatFrameLeft/Right 那套下拉式属性面板。
      2) GearScoreLite：在 PaperDollFrame 上用绝对坐标写死 "GS: 0" / "GearScore"
         两个字体串，且从不更新 —— 客户端正是读它才拼出 "(GS: 0)"。
      3) ElvUI_Enhanced：自己又建了一个属性面板 CharacterStatsPane。

    最要命的一处（也是"金字压在属性上"的真正原因）：ElvUI_Enhanced 的
    PAPERDOLL_SIDEBARS 里有三个互斥侧栏，尺寸和锚点完全相同
    （169x350 @ TOPRIGHT, CharacterFrame.backdrop, -29, -64）：

        [1] CharacterStatsPane          属性      <- 用户想看的
        [2] PaperDollTitlesPane         称号      <- 军团士兵/弑君者/防御审判官...
        [3] PaperDollEquipmentManagerPane 装备管理

    它们靠 Show/Hide 切换，但没有任何一处代码保证"同时只有一个可见"。于是称号
    列表会和属性列表画在完全相同的位置上，形成截图里那一串叠在一起的金字。

    做法
    ----
    全部修复都在运行时施加，不修改任何其他插件的文件；删掉本文件夹即完全还原。
    每个组件都能单独开关，见文件顶部的 DEFAULTS。命令：

        /cpfix                显示帮助与当前开关状态
        /cpfix dump           把关键 frame 的存在/显示/锚点/字体/文字全部打印出来，
                              并放进一个可框选复制的窗口（排查残留问题用）
        /cpfix on  <组件>     打开某组件
        /cpfix off <组件>     关闭某组件
        /cpfix reload         重新施加全部修复

    前提（v1.1 起；v1.2 收紧）
    -------------------------
    面板类组件只在 ElvUI_Enhanced 的角色模块在场时执行（CharModuleActive）。
    没装 / 禁用 ElvUI、或只装核心没装 Enhanced 时，原版面板本来就是好的，
    本插件什么都不做。
    v1.2：广告清理功能整体移除（广告光环若再现，用 tools\purge_wa_ad.py 离线清）；
          EnsureGearScoreStub 纳入门控 —— 它之前是唯一无条件执行的保险，现在
          同样只在 ElvUI_Enhanced 在场时生效。
    v1.3：新增 tabAnchor —— 底部标签行改锚到 ElvUI 的窗口底框，消除"角色页/
          宠物页标签落点不一致"。它是唯一不看 CharModuleActive 的组件：错位
          来自 ElvUI 皮肤与客户端 FrameXML 对窗口几何的互相改写，与 Enhanced
          是否在场无关，门槛是窗口底框（CharacterFrame.backdrop）本身存在。
    v1.4：新增 textFit —— 汉化包用单一 CJK 字体顶替全部标准字体后拉丁字形变宽，
          公会页标题（250px）/ 名单 Lv 列（20px）/ 地下城列表等级列（60px）这些
          按原版窄字体写死宽度的文本框装不下文字，引擎自动省略号截断。放宽为
          330/34/84，原锚点不变。同样不看 CharModuleActive，门槛是对象存在。
    v1.5：textFit 收窄门控 —— 仅当 ElvUI 在场（GetE()）时生效，Enhanced 不参与
          判断（FriendsFrame / LFDParentFrame 与它无关）。
    v1.6：① itemLevel 只显示整数（"268.6"→"268"）。② clientGS 不再连带隐藏
          GearScoreLite 的 GS 数字/标签（PersonalGearScore / GearScore2）：
          它在场时保持显示，并且每次重施都刷新数值 —— GearScoreLite 自己只在
          面板 OnShow / 换装时更新且战斗中跳过，这里补成"一直显示、战斗中也准"。
          客户端烤在 MPQ 里的高清重复块 GearScore2_B 照旧隐藏；GearScoreLite
          不在场时这两个名字仍是隐藏空壳 stub，行为与 v1.5 一致。
    v1.7：新增 selfGS —— 悬停自己（角色模型 / 玩家框体）时提示框补一行自己的 GS。
          GearScoreLite 的算分门控是 CanInspect("mouseover")，而自己不能被观察，
          所以自己的 GS 行永远缺失（别人都有）。这里在它的钩子之后挂一个兜底：
          只处理单位=玩家的提示框，读本地装备数据（无需 NotifyInspect），
          格式与颜色和它自己画的完全一致；它已经画过的场合不重复加行。
          只看 GearScoreLite 是否在场，不看 CharModuleActive（提示框与 Enhanced 无关）。
    v1.8：itemLevel 的兜底口径从"固定 ÷16"改为"按实际件数平均"——与 Warmane 论坛
          流传的查装等宏（1-18 栏位去衬衣、有几件除几件）及 InspectEquip 的
          "平均物品等级"完全同口径。固定 ÷16 是 GS 时代的"16 部位"惯例：副手填上
          后 17 件全计总分再 ÷16，会虚高 17/16≈6.25%（Pcode 的 288 vs 271.71
          就是这个差）。显示仍只保留整数。
    v1.9：① GS 空壳（GSL 缺席时补建的 PersonalGearScore / GearScore2）改为先设字体
          再 SetText —— 本客户端对无字体字体串 SetText 会报 "Font not set"，此前
          这个错误会冲出 ApplyAll、把当轮排在后面的组件一起带停（GSL 关闭时的
          表现就是模型交互整场没装上、转不动）。② ApplyAll 改为逐组件 pcall：
          错误照常上报错误处理器（BugSack 可查，附组件名），但单个组件出错不再
          连坐后面的组件。③ modelControls 并入每秒重施循环：漏装时面板开着
          最迟 1 秒自愈。
    v1.9.1：周期重施同样隔离各组件错误；空壳检查实际字体、回退 GameFontNormal，
          字体及文本有效后才公开。暂时无法初始化时保留隐藏对象供下一轮重试。
    v1.9.2：新增独立 dressUpControls，给 ElvUI 试衣间补左键拖转，保留原旋转按钮。
          已有鼠标处理或 Enhanced 模型交互时让位；关闭后恢复本组件仍持有的脚本。
    v1.9.3：① 新增 enhancedEnable —— ElvUI_Enhanced 的"角色面板"模块开关是逐角色
          私密设置，出厂默认 false（Settings/Private.lua 的 V.enhanced.character.enable）。
          老角色的私密档案里存着显式 true，一切正常；新角色首次登录拿到自己的空
          档案 → 模块 Initialize 开头直接早退，整套面板增强缺席：右侧属性栏空白、
          没有展开小箭头、没有三个侧栏标签、装备管理图标反而露在外面、两个人物
          模型叠影、"GearScore" 标签孤立（20261013 新角色截图实证）。本组件在
          档案没有显式值时补 true；显式 false（用户自己关的）尊重不碰。② 门控同步
          收紧：CharModuleActive 连 enable 一起检查，开关为假时整体 stand down
          （此前模块对象在就算"在场"，照常藏客户端面板 = 只藏不建 = 右侧空白）。
          ③ GS 数字/标签在算不出分（score ≤ 0，新角色的常态）时整组隐藏 ——
          GearScoreLite 自己会把 0 染成近乎不可见的深灰，面板上只剩一个孤零零的
          "GearScore" 标签。
    v1.9.4：角色面板上的 GS 数字/标签不再显示（用户确认不需要）。v1.6~v1.9.3 的
          "常显 + 每轮重算刷新"撤销为一律隐藏；GearScoreLite 照常写文本（只是
          不可见），客户端读文本拼装等（PGearScore）的链路不受影响。恢复显示：
          /cpfix off clientGS 后 /reload（回到 GearScoreLite 原样）。

----------------------------------------------------------------------------]]

-- HDClientFix_Mcode 2.0.0: preserved character repair implementation and history.
local ADDON, ns = ...
ns = ns or {}

-- Old standalone copies must not install a second set of panel hooks.
if ns.OldAddonConflict and ns.OldAddonConflict("CharPanelFix_Mcode") then
    ns.characterConflict = true
    return
end

local G = _G
local type, pairs, tostring, tonumber = type, pairs, tostring, tonumber
local format, strfind, strmatch, gsub = string.format, string.find, string.match, string.gsub
local tinsert = table.insert

local TAG = "|cff33ff99[HD 客户端修复]|r "

--------------------------------------------------------------------------
-- 配置
--------------------------------------------------------------------------

local DEFAULTS = {
    -- 保证 属性/称号/装备管理 三个侧栏同时只有一个可见【根因修复】
    sidebar               = true,
    -- 打开角色面板时默认回到"属性"页（否则会停在上次选的"称号"页）
    sidebarDefaultToStats = true,

    -- 客户端烤在 MPQ 里的高清装备等级块：GearScore2_B(重复的"物品等级"标签)。
    -- GearScoreLite 的 GS 数字/标签（PersonalGearScore / GearScore2）自 v1.9.4 起
    -- 面板上一律不再显示（用户确认不需要）；对象保留给客户端读文本的链路
    clientGS              = true,
    -- 让装备等级只由一个来源显示：接管 ElvUI_Enhanced 的 ItemLevel 行，填真实
    -- 平均装等（v1.6 起只保留整数；v1.8 起按实际件数平均，Warmane 玩家口径），
    -- 并去掉 "(GS: 0)" 这个后缀噪音
    itemLevel             = true,
    -- 客户端自带那套 MoP 属性面板（与 ElvUI_Enhanced 的重复）：PlayerStat* / ALFA_*
    -- 以及 CharacterAttributesFrame / CharacterResistanceFrame
    clientStatPanels      = true,
    -- 客户端里重复出来的一批 32x32 开关按钮：ElvUI_Enhanced 只 Kill 了名字规整的
    -- PlayerTitleFrame / GearManagerToggleButton，这俩孪生版本还留在屏幕上，
    -- 显示成缺贴图的方块
    clientToggleButtons   = true,
    -- 人物模型：显示带 SetUnit 的那张模型并赋单位，收起用不了的另一张
    model                 = true,
    -- 模型交互：滚轮缩放 + 左键拖动旋转（+ 右键拖动平移）。
    -- 装的是客户端 UIParent.lua 自己那套 Model_*S 函数，手感与原版一致，立刻生效
    modelControls         = true,
    -- 试衣间左键拖转：只看 ElvUI 是否在场，不依赖 Enhanced 角色模块。
    dressUpControls       = true,
    -- 按种族的模型背景（E.db.enhanced.character.characterBackground）。
    -- 即时生效；只应用一次，之后你在 ElvUI 选项里关掉不会被覆盖
    modelFeatures         = true,
    -- 重建被 ElvUI 皮肤 Kill 掉的「客户端原版」面板底图 + 种族 Transmog 背景。
    -- 默认关：它会叠在 ElvUI 的半透明底框上，属于两种风格二选一
    clientPanelArt        = false,
    -- 客户端里锚点完全重合的一对字体串 CharacterTitleText / CharacterGuildText
    clientTitles          = true,
    -- 客户端自己的称号控件（ElvUI_Enhanced 开启时本来就会被 Kill，默认不动）
    clientTitleWidgets    = false,
    -- ElvUI_Enhanced 属性行的几何：写死 15px 行高对中文字太挤，物品等级写死 20 号字
    enhancedGeometry      = true,
    -- 在 LibSharedMedia 注册缺失的 AvantGarde LT 字体名（默认关，见 README）
    fonts                 = false,
    -- 底部 角色/宠物/声望/技能/货币 标签行改锚到 ElvUI 的窗口底框（backdrop）：
    -- 客户端 FrameXML 每次切页都在改写 CharacterFrame 的尺寸，标签行跟着漂。
    -- 关掉后建议 /reload 还原客户端 XML 的原始锚点
    tabAnchor             = true,
    -- 固定宽文本框适配 CJK 字体：汉化包用单一 CJK 字体顶替全部五种标准字体，
    -- 拉丁字形（数字/字母）变宽，公会页标题 / 名单 Lv 列 / 地下城列表等级列这些
    -- 按原版窄字体写死宽度的框装不下文字，引擎自动省略号截断。放宽这三处，
    -- 原锚点不变。仅当 ElvUI 在场时生效（v1.5）；关掉后建议 /reload 还原
    textFit               = true,
    -- 悬停自己（角色模型 / 玩家框体）时提示框补一行自己的 GS：GearScoreLite
    -- 的算分门控 CanInspect("mouseover") 对自己不成立（自己不可被观察），
    -- 自己的 GS 行永远缺失。仅当 GearScoreLite 在场时生效（v1.7）
    selfGS                = true,
    -- 新角色自动补开 ElvUI_Enhanced 的"角色面板"模块：该开关是逐角色私密设置，
    -- 出厂默认关闭，新角色自己的空档案会让整个面板增强缺席（详见文件头 v1.9.3）。
    -- 只在档案没有显式值时补；用户显式关掉的（false）不碰
    enhancedEnable        = true,
}

local TUNING = {
    rowFontSize       = nil,    -- 属性行字号；nil = 用 ElvUI 的 general.fontSize
    rowHeight         = nil,    -- 属性行高度；nil = 自动（rowFontSize + 5）
    labelWidth        = 132,    -- 属性行标签宽度（原为写死的 122）
    itemLevelFontSize = 16,     -- 物品等级数字字号（原为写死的 20）
    itemLevelLabel    = "物品等级", -- 物品等级行的标题；设为 nil 则从客户端的 ITEM_LEVEL 字串里猜
    -- 隐藏重复的人物模型。默认 false，**不要随便打开**：
    -- CharacterModelFrame2 身上挂着主手/副手/远程/弹药四个槽位（它是那四个槽的父对象），
    -- 隐藏它会把这四个槽一起收走。只有真的出现两个模型叠在一起时才需要开。
    hideDuplicateModels = false,
    reapplyInterval   = 1.0,    -- 角色面板可见时每隔几秒重新施加一次隐藏
}

-- ElvUI_Enhanced 的三个互斥侧栏（顺序必须与它的 PAPERDOLL_SIDEBARS 一致）
local PANE_STATS, PANE_TITLES, PANE_SETS = 1, 2, 3
local PANE_NAMES = {
    "CharacterStatsPane",
    "PaperDollTitlesPane",
    "PaperDollEquipmentManagerPane",
}

--------------------------------------------------------------------------
-- 存档 / 小工具
--------------------------------------------------------------------------

local db
local function DB()
    if ns.GetCharacterDB then
        db = ns.GetCharacterDB()
        return db
    end
    if type(Mcode_CharPanelFixDB) ~= "table" then Mcode_CharPanelFixDB = {} end
    db = Mcode_CharPanelFixDB
    for k, v in pairs(DEFAULTS) do
        if db[k] == nil then db[k] = v end
    end
    return db
end

local function P(msg) print(TAG .. msg) end

-- 把 frame 藏起来（幂等；不存在就跳过）
local function HideFrame(f)
    if f and f.Hide and f:IsShown() then f:Hide() end
end

local function Name2Frame(name)
    local f = G[name]
    if type(f) == "table" and f.GetObjectType then return f end
    return nil
end

-- ElvUI 引擎与 ElvUI_Enhanced 的角色模块（拿不到就跳过相关组件，不报错）
-- 取 ElvUI 的引擎对象。
-- 坑：全局的 ElvUI 是它的 "Engine" 壳表，真正的 AddOn 对象在壳表的 [1] 上
-- （ElvUI\Init.lua:38 `Engine[1] = AddOn`，:43 `_G[AddOnName] = Engine`）。
-- GetModule / NewModule / LSM 这些方法都在 [1] 上，不在 ElvUI 本身。
-- 拿错的话 GetModule 就是 nil，所有依赖模块的修复会"安静地不生效"。
local function GetE()
    local engine = G.ElvUI
    if type(engine) == "table" then
        local addon = engine[1]
        if type(addon) == "table" and addon.GetModule then
            ns.engineVia = "ElvUI[1]"
            return addon
        end
        if engine.GetModule then
            ns.engineVia = "ElvUI"
            return engine
        end
    end
    local e = G.E
    if type(e) == "table" and e.GetModule then
        ns.engineVia = "_G.E"
        return e
    end
    ns.engineVia = nil
    return nil
end

local function GetCharModule()
    local E = GetE()
    if not E or not E.GetModule then return nil end
    -- silent = true，避免 AceAddon 找不到时往聊天框里刷提示
    local ok, m = pcall(E.GetModule, E, "Enhanced_CharacterFrame", true)
    if ok and type(m) == "table" then
        ns.moduleVia = "GetModule"
        return m
    end
    ns.moduleVia = nil
    return nil
end

-- 隐藏/接管类组件的门控：只在 ElvUI_Enhanced 的角色模块"真的在干活"时执行。
--
-- 为什么用模块对象而不是 GetE() 判断：本插件的存在理由是抵消 ElvUI_Enhanced 对
-- 这个 HD 客户端原版面板的破坏（侧栏互斥、OnEvent 被替换、属性行几何……）。
-- 模块不在场 —— 没装 ElvUI、ElvUI 被禁用、或只装了核心没装 Enhanced —— 时，
-- 原版面板并没有被破坏，反而是唯一能用的面板；此时照常执行隐藏类组件会把
-- 原版正在用的东西藏掉（属性区整个空白、称号/公会文字消失、装等读数消失）。
--
-- v1.9.3 收紧：模块对象存在 ≠ 模块在干活。ElvUI_Enhanced 的角色模块还有一个
-- 逐角色开关 E.private.enhanced.character.enable（私密设置，出厂默认 false，
-- 详见文件头 v1.9.3），enable 为假时它的 Initialize 在开头直接早退 —— 属性
-- 面板、展开按钮、侧栏标签全都不建。此时若照常隐藏客户端面板 = 只藏不建，
-- 右侧就只剩一片空白（20261013 新角色实证）。所以开关缺失（nil）或为假一律
-- 视为不在干活；enhancedEnable 组件会先把缺失的补上，下一轮（或同轮更早的
-- 调用点）这个门控自然为真。
--
-- 模块比本插件晚初始化的场景：每次 ApplyAll / OnUpdate 重施都会重新评估，
-- 模块一出现下一轮就自动生效，不需要 /reload。
local function CharModuleActive()
    if GetCharModule() == nil then return false end
    local E = GetE()
    local ch = E and E.private and E.private.enhanced and E.private.enhanced.character
    return (ch and ch.enable) and true or false
end

-- 扫描 _G 里符合给定 Lua pattern 的 frame 名（只认真正的 UI 对象）
local function ScanGlobals(patterns)
    local found = {}
    for k, v in pairs(G) do
        if type(k) == "string" and type(v) == "table" and v.GetObjectType then
            for i = 1, #patterns do
                if strfind(k, patterns[i]) then
                    found[#found + 1] = k
                    break
                end
            end
        end
    end
    return found
end

--------------------------------------------------------------------------
-- 前向声明
--------------------------------------------------------------------------
-- 这几个函数在后面的组件里定义，但前面的 OnShow 钩子（ApplySidebar）就要用到，
-- 所以必须先声明成局部变量，后面用赋值形式定义（而不能用 local function，
-- 那会再声明一个新的局部变量把这里的遮蔽掉，引用就变成全局 nil 了）。
local FixAllCategoriesNow
local EnsureItemLevelExpanded
local ApplyModel
local ApplyModelControls
local ApplyClientToggleButtons

--------------------------------------------------------------------------
-- 组件 1：侧栏互斥（根因）
--------------------------------------------------------------------------

local enforcing = false

local function PaneList()
    local list = {}
    for i = 1, #PANE_NAMES do
        local f = Name2Frame(PANE_NAMES[i])
        if f then list[i] = f end
    end
    return list
end

-- preferred: 想强制显示的侧栏序号（可选）
--
-- 重要：除了"明确要求显示某个侧栏"的情况，这里只做"隐藏多余的"，绝不主动 Show。
-- 因为角色面板处于折叠状态时三个侧栏本来就该全部隐藏，此时若去 Show 一个，
-- 就会凭空冒出一个孤零零的属性列表。
local function EnforceSidebar(preferred)
    if enforcing then return end

    local panes = PaneList()
    if not (panes[1] or panes[2] or panes[3]) then return end

    local visible = {}
    for i = 1, #PANE_NAMES do
        if panes[i] and panes[i]:IsShown() then visible[#visible + 1] = i end
    end

    local pdf = G.PaperDollFrame
    local expanded = G.CharacterFrame and G.CharacterFrame.Expanded
    local winner

    if preferred and panes[preferred] and (expanded or #visible > 0) then
        winner = preferred
    elseif #visible >= 2 then
        -- 同时可见多个 = ElvUI_Enhanced 状态错乱，这就是重叠的根因
        winner = DB().sidebarDefaultToStats and PANE_STATS
            or (pdf and pdf.currentSideBarID)
            or visible[1]
    else
        return                      -- 0 个或 1 个可见：一切正常，不干预
    end
    if not panes[winner] then winner = visible[1] end
    if not panes[winner] then return end

    enforcing = true

    -- 先无条件隐藏所有非胜者。不走淡出，避免 SetSidebar 里 UIFrameFadeOut 的
    -- finishedFunc 过 0.2 秒又把刚显示出来的侧栏藏掉。
    for i = 1, #PANE_NAMES do
        if i ~= winner and panes[i] then HideFrame(panes[i]) end
    end

    if pdf then
        pdf.currentSideBar = panes[winner]
        pdf.currentSideBarID = winner
    end

    local m = GetCharModule()
    if not panes[winner]:IsShown() then
        local tab = Name2Frame("PaperDollSidebarTab" .. winner)
        if m and m.PaperDollFrame_SetSidebar and tab then
            m:PaperDollFrame_SetSidebar(tab, winner)
        else
            panes[winner]:Show()
        end
    end

    if m and m.PaperDollFrame_UpdateSidebarTabs then
        pcall(m.PaperDollFrame_UpdateSidebarTabs, m)
    end

    enforcing = false
end

local function ApplySidebar()
    -- 挂钩子。注意这些 frame 是 ElvUI_Enhanced 在自己的 Initialize 里建的，
    -- 那发生在 PLAYER_LOGIN —— 也就是我们收到 ADDON_LOADED 之后。所以这里必须
    -- 逐个目标记录"挂上了没"，在后续的每次调用里重试，不能只做一次就收工。
    local hooks = ns.hooks
    if not hooks then hooks = {} ns.hooks = hooks end

    if not hooks.pdf then
        local pdf = Name2Frame("PaperDollFrame")
        if pdf then
            -- ElvUI_Enhanced 用 SetScript 替换了 OnShow/OnEvent，所以这里必须用
            -- HookScript 才不会被顶掉，而且会排在它后面执行。
            pdf:HookScript("OnShow", function()
                if DB().sidebar and not enforcing then
                    EnforceSidebar(DB().sidebarDefaultToStats and PANE_STATS or nil)
                end
                -- 面板刚打开就立刻修几何，不用等轮询
                if DB().enhancedGeometry then FixAllCategoriesNow() end
                if DB().itemLevel then EnsureItemLevelExpanded() end
                if DB().clientToggleButtons then ApplyClientToggleButtons() end
                if DB().model then ApplyModel() end
                ApplyModelControls()
            end)
            hooks.pdf = true
        end
    end

    for i = 1, #PANE_NAMES do
        if not hooks["pane" .. i] then
            local f = Name2Frame(PANE_NAMES[i])
            if f then
                f:HookScript("OnShow", function()
                    if DB().sidebar and not enforcing then EnforceSidebar() end
                    if DB().enhancedGeometry then FixAllCategoriesNow() end
                    if DB().itemLevel then EnsureItemLevelExpanded() end
                    if DB().clientToggleButtons then ApplyClientToggleButtons() end
                    if DB().model then ApplyModel() end
                end)
                hooks["pane" .. i] = true
            end
        end
    end

    for i = 1, #PANE_NAMES do
        if not hooks["tab" .. i] then
            local tab = Name2Frame("PaperDollSidebarTab" .. i)
            if tab then
                tab:HookScript("OnClick", function()
                    if DB().sidebar and not enforcing then EnforceSidebar(i) end
                end)
                hooks["tab" .. i] = true
            end
        end
    end

    if DB().sidebar then
        EnforceSidebar(DB().sidebarDefaultToStats and PANE_STATS or nil)
    end
end

--------------------------------------------------------------------------
-- 组件 2/3：客户端烤进 MPQ 的高清装备等级块
--------------------------------------------------------------------------

local clientFrameCache

-- 只在"确实挂在角色面板下面"时才认领，避免误伤同名前缀的其它 UI
local function IsUnderCharacterPanel(f)
    local node = f
    for _ = 1, 6 do
        if not node then return false end
        local name = node.GetName and node:GetName()
        if name == "PaperDollFrame" or name == "CharacterFrame"
            or name == "PetPaperDollFrame" then
            return true
        end
        node = node.GetParent and node:GetParent()
    end
    return false
end

local function ResolveClientFrames()
    if clientFrameCache then return clientFrameCache end

    local out = {}

    -- 明确已知的名字
    local explicit = {
        "GearScore2_B",         -- "物品等级" 标签（ITEM_LEVEL:sub(1,-4) 的产物）
        "GearScore2",
        "PersonalGearScore",    -- GearScoreLite 的 "GS: 0"
    }
    for i = 1, #explicit do out[#out + 1] = explicit[i] end

    -- 客户端 MoP 版属性面板 + 它的分组标题，做父级校验后才认领。
    -- 必须按前缀匹配：这个客户端的 FrameXML 里存在一整批名字尾部被多加了的异名容器
    -- （CharacterAttributesFrameer / PlayerStatLeftToper / PlayerStatLeftMiddleer /
    --  PlayerStatRightBottomer / PlayerStatFrameLeftDropDowner ...），而且
    -- PlayerStatFrameLeft1、PlayerStatLeftTop、PlayerStatRightTop 这些真正的子控件
    -- 是挂在 CharacterAttributesFrameer 下面的 —— 只按准确名字
    -- "CharacterAttributesFrame" 匹配就会漏掉整个客户端属性面板的父容器。
    local scanned = ScanGlobals({ "^PlayerStat", "^ALFA_%d", "^CharacterAttributes", "^CharacterResistance" })
    for i = 1, #scanned do
        local fr = Name2Frame(scanned[i])
        if fr and IsUnderCharacterPanel(fr) then
            out[#out + 1] = scanned[i]
        end
    end

    clientFrameCache = out
    return out
end

-- 客户端自带那套属性面板（含上面那些 "er" 异名容器）—— 归 clientStatPanels 组件管
local function IsClientStatPanel(name)
    return strfind(name, "^PlayerStat") or strfind(name, "^ALFA_%d")
        or strfind(name, "^CharacterAttributes") or strfind(name, "^CharacterResistance")
end

-- 这三个名字都长在 PaperDollFrame 上。v1.6 起本组件只隐藏 [1]（客户端烤在 MPQ
-- 里的高清重复标签）；[2][3] 是 GearScoreLite 的标签/数字，在场时常显（见下）
local GS_NAMES = { "GearScore2_B", "GearScore2", "PersonalGearScore" }

-- 原 HD 在 GS 对象缺席时已有平均装等回退。兼容空壳只在初始化完成后公开，
-- 避免让原客户端走到存在对象、但 GetText 仍为 nil 的分支。
local gsStubCache = {}
local function EnsureGearScoreStub()
    local pdf = Name2Frame("PaperDollFrame")
    if not pdf or not pdf.CreateFontString then return end

    local function hasFont(fs)
        local ok, path, size = pcall(fs.GetFont, fs)
        return ok and type(path) == "string" and path ~= ""
            and type(size) == "number" and size > 0
    end
    local function makeStub(name)
        if Name2Frame(name) then return end
        -- 不用全局名字创建半成品；失败时保留隐藏对象，下一轮重试同一对象。
        local fs = gsStubCache[name]
        if not fs then
            fs = pdf:CreateFontString(nil)
            gsStubCache[name] = fs
        end
        fs:Hide()
        pcall(fs.SetFont, fs, "Fonts\\FRIZQT__.TTF", 10)
        if not hasFont(fs) and fs.SetFontObject and G.GameFontNormal then
            pcall(fs.SetFontObject, fs, G.GameFontNormal)
        end
        if not hasFont(fs) then return end
        local ok = pcall(fs.SetText, fs, "")
        if not ok then return end
        local readable, text = pcall(fs.GetText, fs)
        if not readable or type(text) ~= "string" then return end
        G[name] = fs
    end

    makeStub("PersonalGearScore")
    makeStub("GearScore2")
end

local function ApplyClientGS()
    -- 没有 Enhanced 时保留原角色面板；缺 GS 对象的路径由原 HD 回退处理。
    if not CharModuleActive() then return end

    -- 仅补缺失的兼容对象，不改 GearScoreLite 自己创建的对象。
    EnsureGearScoreStub()

    -- 客户端烤在 MPQ 里的高清重复块（重复的"物品等级"标签）照旧隐藏，给
    -- ElvUI_Enhanced 的属性面板让位。客户端属性面板归 clientStatPanels 管 ——
    -- 两个组件必须各管各的，否则 /cpfix off 做二分时结果会是假的。
    HideFrame(Name2Frame(GS_NAMES[1]))

    -- v1.9.4（用户要求）：面板上的 GS 数字/标签不再显示 —— 一律隐藏。
    -- v1.6~v1.9.3 曾让这两个串（PersonalGearScore / GearScore2）"常显 + 每轮重算
    -- 刷新"，但实际呈现经常是：数字被 3D 模型盖住、或 0 分被 GSL 自己染成近乎
    -- 不可见的深灰 (0.1,0.1,0.1)，面板上往往只剩一个孤零零的 "GearScore" 标签
    -- （20261013 用户截图确认这里不需要）。现在统一隐藏；GearScoreLite 自己的
    -- OnShow / 换装刷新照常写文本（只是不可见），客户端读 PersonalGearScore 文本
    -- 拼装等（PGearScore）的链路不受影响；空壳路径与在场路径动作一致，HideFrame
    -- 幂等（含每秒重施、GSL 若重新 Show 也会被下一轮压回去）。
    -- 想恢复显示：/cpfix off clientGS 后 /reload（回到 GearScoreLite 原样）。
    HideFrame(Name2Frame("PersonalGearScore"))
    HideFrame(Name2Frame("GearScore2"))
end

local function ApplyClientStatPanels()
    -- 没有 Enhanced 的替代面板时，这套就是唯一的属性显示，藏掉 = 属性区空白
    if not CharModuleActive() then return end

    local list = ResolveClientFrames()
    for i = 1, #list do
        local name = list[i]
        if IsClientStatPanel(name) then
            HideFrame(Name2Frame(name))
        end
    end
end

local function ApplyClientTitles()
    -- 没装 Enhanced 时这两个是名字下方唯一的称号/公会显示，藏掉就是丢功能
    if not CharModuleActive() then return end

    HideFrame(Name2Frame("CharacterTitleText"))   -- 与 CharacterGuildText 锚点重合
    HideFrame(Name2Frame("CharacterGuildText"))

    if DB().clientTitleWidgets then
        HideFrame(Name2Frame("PlayerTitleFrame"))
        HideFrame(Name2Frame("PlayerTitlePickerFrame"))
    end
end

-- 客户端把 FrameXML 加载了两遍，于是 PlayerTitleFrame / GearManagerToggleButton
-- 各有一个孪生版本（PlayerTitleToggleButton / CharManagerToggleButton）。
-- ElvUI_Enhanced 只 Kill 了规整的那两个，这俩还可见，并且是 32x32 的方块。
local TOGGLE_BUTTON_NAMES = {
    "PlayerTitleToggleButton",
    "CharManagerToggleButton",
}

ApplyClientToggleButtons = function()
    -- 没装 Enhanced 时规整的那对按钮还在原位、与孪生版本完全重合，藏不藏都一样；
    -- 门控只是让"没 Enhanced 就什么都不做"这件事保持一致
    if not CharModuleActive() then return end

    for i = 1, #TOGGLE_BUTTON_NAMES do
        HideFrame(Name2Frame(TOGGLE_BUTTON_NAMES[i]))
    end
end

--------------------------------------------------------------------------
-- 组件：人物模型
--------------------------------------------------------------------------

-- 这个客户端把 XML 加载了两遍，人物模型因此有两个：
--   CharacterModelFrame   —— 规整的那个，带 SetUnit，尺寸/位置正好是 ElvUI_Enhanced 配置的
--   CharacterModelFrame2  —— 孪生版本，**没有 SetUnit**（给不了单位），却显示在最上层
-- 所以模型区是空的：能用的那张被藏着，露在外面的那张根本没法用。
--
-- 因此正确的做法不是"给可见的那张补单位"（补不上），而是反过来：
-- 让能用的那张显示出来，把用不了的孪生版本收掉。
--
-- 注意：SetUnit 每次登录只调一次。它会重置模型朝向和动画，
-- 每轮都调的结果就是模型一直抖、一直转回正面。
local modelFrames

local function ResolveModelFrames()
    -- 第一次扫描可能太早（frame 还没建出来），扫到空就下次再来
    if modelFrames and #modelFrames > 0 then return modelFrames end
    modelFrames = ScanGlobals({ "^CharacterModelFrame" })
    return modelFrames
end

-- 挑出"能用的那张"以及所有重复的模型。model 和 modelControls 共用这一份逻辑，
-- 免得两处判断漂移。
--   只有带 SetUnit 的才是真正的模型（CharacterModelFrameRotateLeft/RightButton
--   也会被名字前缀扫到，它们是按钮，会被过滤掉）；
--   名字规整的那张优先 —— ElvUI / ElvUI_Enhanced 配置的尺寸和位置都作用在它身上。
local function PickTargetModel()
    local list = ResolveModelFrames()
    local models = {}
    for i = 1, #list do
        local f = Name2Frame(list[i])
        if f and type(f.SetUnit) == "function" then
            models[#models + 1] = { name = list[i], frame = f }
        end
    end
    if #models == 0 then return nil end

    local target = models[1]
    for i = 1, #models do
        if models[i].name == "CharacterModelFrame" then
            target = models[i]
            break
        end
    end
    return target, models
end

ApplyModel = function()
    -- Enhanced 不在场时，客户端自己的 PaperDollFrame_OnEvent 会正常给
    -- CharacterModelFrame2 赋单位，模型本来就是好的 —— 什么都不做
    -- （若不做门控，这里会把那张 hidden 的空壳 CharacterModelFrame Show 出来）。
    if not CharModuleActive() then return end

    local target, models = PickTargetModel()
    if not target then return end

    -- 默认**不隐藏**重复的模型。
    -- 教训：我一开始为了"避免孪生版本盖住模型"隐藏了 CharacterModelFrame2，
    -- 结果把挂在他身上的主手/副手/远程/弹药槽一起隐藏了 —— 那几个槽位在客户端
    -- XML 里写在 CharacterModelFrame2 的 <Frames> 块里，**是它的子对象**，
    -- 隐藏父对象会连带隐藏子对象。
    -- 而且那个隐藏本来就是多余的：CharacterModelFrame2 从未被赋过单位
    -- （客户端的 SetUnit("player") 写在被 ElvUI_Enhanced 替换掉的 OnEvent 里），
    -- 它渲染不出任何东西，不可能盖住模型。
    -- TUNING.hideDuplicateModels 留作万一真的出现两个模型叠在一起时的开关。
    if TUNING.hideDuplicateModels then
        for i = 1, #models do
            if models[i] ~= target then HideFrame(models[i].frame) end
        end
    end

    local f = target.frame
    if not f:IsShown() then f:Show() end

    local unit = f.GetUnit and f:GetUnit()
    if unit then
        -- 能读到单位：不是 player 就补一次
        if unit ~= "player" then f:SetUnit("player") end
    else
        -- 读不到单位：每次登录只补一次
        if not ns.modelFixed then ns.modelFixed = {} end
        if not ns.modelFixed[target.name] then
            ns.modelFixed[target.name] = true
            f:SetUnit("player")
        end
    end
end

--------------------------------------------------------------------------
-- 组件：模型交互（滚轮缩放 + 拖动旋转）
--------------------------------------------------------------------------

-- 这个客户端的 UIParent.lua 里那套模型函数**全都还在**，客户端自己的 XML 就是拿它们
-- 给 CharacterModelFrame2 装上交互的：
--     <OnMouseWheel> Model_OnMouseWheelS(self, delta * 0.48) </OnMouseWheel>
--     <OnLoad>  Model_OnLoadS(self)
--     <OnUpdate function="Model_OnUpdateS"/>
--     <OnMouseDown function="Model_OnMouseDownS"/>
--     <OnMouseUp  function="Model_OnMouseUpS"/>
-- 我们只是把**同一套函数、同样的参数**装到"现在真正显示的那张"模型上 ——
-- 相当于把客户端原本的交互原样还回来，手感完全一致
-- （缩放上限 GLOBAL_MODEL_MAX_ZOOM = 0.64、拖动系数 0.010、默认朝向 0.61）。
-- 而且立刻生效，不需要 /reload。
--
-- 为什么不用 ElvUI_Enhanced 的 Enhanced Model Frames(modelFrames) 选项：
--   1) MF:Initialize() 遍历 5 个模型 frame 和 10 个旋转按钮，全程没有 nil 检查，
--      这个客户端的 FrameXML 是裁剪过的，少一个就在登录时报错；
--   2) MF:Model_OnUpdate 每帧调 SetRotation(frame.rotation)，而 frame.rotation
--      只在 MF:Model_Reset 里被赋过值，初始化路径不保证走到 → 可能每帧报错；
--   3) 它需要 /reload 才生效。
-- 模型 frame 比客户端原本的模型宽 32px：
--     客户端原本的 CharacterModelFrame2 : 起点 56，宽 212 → 右边界 268
--     ElvUI 配置的（我们现在显示的）    : 起点 63，宽 237 → 右边界 300
--                         右列装备槽位 : 起点 269，宽 34  → 右边界 303
-- 客户端原本的模型正好在右列槽位开始处收住（268 → 269），ElvUI 拉宽到 300 以后
-- 多出来的那条就压住了右列槽位。加上模型现在有鼠标交互 + characterBackground 铺的背景，
-- 就同时造成"被遮挡"和"鼠标移上去没有装备提示"（鼠标在 WoW 里是由**层级**决定的，
-- 上层有鼠标的 frame 先拿到事件）。
--
-- 修法：把所有可见的装备槽位抬到模型之上 —— 槽位本来就该画在模型上面。
-- 比"给模型设命中矩形内缩"稳：不用做坐标/缩放换算，不会因为算错而时好时坏。
local function CollectVisibleSlots(model)
    local out = {}
    local pdf = Name2Frame("PaperDollFrame")
    if not pdf or not pdf.GetChildren then return out end

    local function consider(fr)
        local name = fr.GetName and fr:GetName()
        if fr ~= model and fr:IsShown() and name and strfind(name, "Slot") then
            out[#out + 1] = fr
        end
    end

    -- 两层：PaperDollFrame 的直接子对象，以及它们的子对象
    -- （后者覆盖挂在 CharacterModelFrame2 下面的主手/副手/远程/弹药槽）
    local kids = { pdf:GetChildren() }
    for i = 1, #kids do
        consider(kids[i])
        if kids[i].GetChildren then
            local sub = { kids[i]:GetChildren() }
            for j = 1, #sub do consider(sub[j]) end
        end
    end
    return out
end

local function RaiseSlotsAboveModel(model)
    local level = (model:GetFrameLevel() or 1) + 1
    local slots = CollectVisibleSlots(model)
    for i = 1, #slots do
        local fr = slots[i]
        if not fr.__cpfixOrigLevel then
            fr.__cpfixOrigLevel = fr:GetFrameLevel()          -- 记下来，关掉时还原
        end
        fr:SetFrameLevel(level)
    end
    ns.modelSlotCount = #slots
    ns.modelSlotLevel = level
end

local function RestoreSlotLevels()
    local pdf = Name2Frame("PaperDollFrame")
    if not pdf or not pdf.GetChildren then return end
    local function restore(fr)
        if fr.__cpfixOrigLevel then
            fr:SetFrameLevel(fr.__cpfixOrigLevel)
            fr.__cpfixOrigLevel = nil
        end
    end
    local kids = { pdf:GetChildren() }
    for i = 1, #kids do
        restore(kids[i])
        if kids[i].GetChildren then
            local sub = { kids[i]:GetChildren() }
            for j = 1, #sub do restore(sub[j]) end
        end
    end
    ns.modelSlotCount = nil
    ns.modelSlotLevel = nil
end

local function RemoveModelControls(model)
    if not model or not model.__cpfixControls then return end
    model.__cpfixControls = nil
    model:SetScript("OnMouseWheel", nil)
    model:SetScript("OnMouseDown", nil)
    model:SetScript("OnMouseUp", nil)
    model:SetScript("OnUpdate", nil)
    RestoreSlotLevels()
    ns.modelControlsOwner = nil
end

ApplyModelControls = function()
    local target = PickTargetModel()
    local model = target and target.frame

    -- 先处理"关掉"的情况：把之前装的脚本卸干净、槽位层级还原
    if not DB().modelControls then
        if ns.modelControlsFrame then
            RemoveModelControls(ns.modelControlsFrame)
            ns.modelControlsFrame = nil
        else
            RestoreSlotLevels()
        end
        return
    end

    if not model then return end

    -- Enhanced 不在场时，客户端 XML 自己就给 CharacterModelFrame2 装好了同一套
    -- 交互，不需要也不应该接管（PickTargetModel 此时选中的是那张空壳）。
    -- 只拦"安装"方向：之前装过的话仍然要卸干净。
    if not CharModuleActive() then
        if ns.modelControlsFrame then
            RemoveModelControls(ns.modelControlsFrame)
            ns.modelControlsFrame = nil
        end
        return
    end

    -- 你自己在 ElvUI 选项里开了 Enhanced Model Frames 的话，就让它接管，
    -- 避免两套实现抢同一批脚本
    local E = GetE()
    if E and E.private and E.private.enhanced and E.private.enhanced.character
        and E.private.enhanced.character.modelFrames then
        ns.modelControlsOwner = "ElvUI_Enhanced"
        return
    end

    -- 客户端这套函数要是在（换了客户端就可能没有），不硬装
    if type(G.Model_OnLoadS) ~= "function" or type(G.Model_OnUpdateS) ~= "function"
        or type(G.Model_OnMouseWheelS) ~= "function"
        or type(G.Model_OnMouseDownS) ~= "function" or type(G.Model_OnMouseUpS) ~= "function" then
        ns.modelControlsOwner = nil
        return
    end

    -- 槽位层级每一轮都要保证（面板重建、客户端自己调 level 都可能把它压回去）
    RaiseSlotsAboveModel(model)

    if model.__cpfixControls then
        ns.modelControlsOwner = "CharPanelFix_Mcode"
        ns.modelControlsFrame = model
        return
    end

    model:EnableMouse(true)
    model:EnableMouseWheel(true)

    -- 参数照抄客户端 XML：delta * 0.48
    model:SetScript("OnMouseWheel", function(self, delta)
        G.Model_OnMouseWheelS(self, delta * 0.48)
    end)
    model:SetScript("OnMouseDown", G.Model_OnMouseDownS)
    model:SetScript("OnMouseUp", G.Model_OnMouseUpS)
    model:SetScript("OnUpdate", G.Model_OnUpdateS)

    -- 初始化缩放区间/默认朝向/相机位置（照抄它的 <OnLoad>）
    G.Model_OnLoadS(model)

    model.__cpfixControls = true
    ns.modelControlsOwner = "CharPanelFix_Mcode"
    ns.modelControlsFrame = model
end

--------------------------------------------------------------------------
-- 组件：试衣间左键拖转，保留原生旋转按钮与其他插件的交互
--------------------------------------------------------------------------

local function RemoveDressUpControls()
    local state = ns.dressUpControlsState
    if not state then return end
    state.active, state.dragging, state.cursor = false, false, nil
    local owned = true
    for event, handler in pairs(state.handlers) do
        if state.model:GetScript(event) ~= handler then owned = false end
    end
    for event, handler in pairs(state.handlers) do
        if state.model:GetScript(event) == handler then
            state.model:SetScript(event, state.original[event])
        end
    end
    -- 后装的插件可能仍引用我们的包装函数；停用状态使它只转发原脚本。
    -- 它已接管脚本时，不恢复旧的鼠标开关，以免关闭新插件所需的输入。
    if owned then state.model:EnableMouse(state.mouseEnabled) end
    ns.dressUpControlsState = nil
end

local function ApplyDressUpControls()
    local E = GetE()
    local enhanced = E and E.private and E.private.enhanced
    local otherOwner = enhanced and enhanced.character and enhanced.character.modelFrames
    if not DB().dressUpControls or not E or otherOwner then
        RemoveDressUpControls()
        return
    end
    local model = G.DressUpModel
    local state = ns.dressUpControlsState
    if state then
        if state.model == model then
            local owned = true
            for event, handler in pairs(state.handlers) do
                if model:GetScript(event) ~= handler then owned = false end
            end
            if owned then return end
        end
        RemoveDressUpControls()
    end
    if not model or type(model.GetScript) ~= "function"
        or type(model.IsMouseEnabled) ~= "function" or type(model.SetRotation) ~= "function"
        or type(G.GetCursorPosition) ~= "function" then return end
    -- 已有拖动/平移实现时保留其所有权，不按组件重施覆盖它。
    if model:GetScript("OnMouseDown") or model:GetScript("OnMouseUp") then return end

    state = { model = model, active = true, original = {}, handlers = {},
              mouseEnabled = model:IsMouseEnabled() }
    for _, event in ipairs({ "OnMouseDown", "OnMouseUp", "OnUpdate", "OnHide" }) do
        state.original[event] = model:GetScript(event)
    end
    state.handlers.OnMouseDown = function(_, button)
        if state.active and button == "LeftButton" then
            state.dragging = true
            state.cursor = G.GetCursorPosition()
        end
    end
    state.handlers.OnMouseUp = function(_, button)
        if button == "LeftButton" then state.dragging, state.cursor = false, nil end
    end
    state.handlers.OnUpdate = function(self, dt)
        if state.original.OnUpdate then state.original.OnUpdate(self, dt) end
        if not state.active or not state.dragging then return end
        if G.IsMouseButtonDown and not G.IsMouseButtonDown("LeftButton") then
            state.dragging, state.cursor = false, nil
            return
        end
        local x = G.GetCursorPosition()
        local rotation = self.rotation
        if type(rotation) ~= "number" and self.GetFacing then rotation = self:GetFacing() end
        if type(rotation) == "number" and type(x) == "number" and state.cursor then
            self.rotation = (rotation + (x - state.cursor) * 0.01) % (2 * math.pi)
            self:SetRotation(self.rotation)
        end
        state.cursor = x
    end
    state.handlers.OnHide = function(self, ...)
        state.dragging, state.cursor = false, nil
        if state.original.OnHide then state.original.OnHide(self, ...) end
    end
    model:EnableMouse(true)
    for event, handler in pairs(state.handlers) do model:SetScript(event, handler) end
    ns.dressUpControlsState = state
end

--------------------------------------------------------------------------
-- 组件：模型种族背景（ElvUI_Enhanced 的功能，默认关闭）
--------------------------------------------------------------------------

-- E.db.enhanced.character.characterBackground 的 schema 默认值是 false
-- （Settings\Profile.lua:43），当前配置里没有覆盖它，所以一直是关的。
-- 打开后 ElvUI_Enhanced 的 CharacterFrame.lua:1841 会按种族给模型加背景贴图。
--
-- 它是**即时生效**的 —— 选项自身的 set 回调就是调 UpdateCharacterModelFrame()，
-- 插件这里照做一遍，所以不需要 /reload。
--
-- 只应用一次（标记写进 Mcode_CharPanelFixDB）。这样你之后在 ElvUI 选项里手动关掉，
-- 我不会下次登录又给你打开。
--
-- 这里**不碰** E.private.enhanced.character.modelFrames（模型鼠标交互那一项）：
-- 它的实现在 ModelFrames.lua 里有两个隐患（遍历 5 个模型 frame 无 nil 检查、
-- 每帧 SetRotation(frame.rotation) 而该字段的初始化路径不保证赋值），
-- 所以交互改由 modelControls 组件用客户端自己的函数实现。
local function ApplyModelFeatures()
    local E = GetE()
    if not E or not E.db then return false end

    local pub = E.db.enhanced and E.db.enhanced.character
    if type(pub) ~= "table" then return false end

    local store = DB()
    if store.modelFeaturesApplied then return true end      -- 应用过了，尊重手动选择

    if not pub.characterBackground then
        pub.characterBackground = true
        ns.modelFeaturesChanged = { "模型种族背景" }
        -- 这一项即时生效：它的 set 回调就是调 UpdateCharacterModelFrame()
        local m = GetCharModule()
        if m and m.UpdateCharacterModelFrame then
            pcall(m.UpdateCharacterModelFrame, m)
        end
    end

    store.modelFeaturesApplied = true
    return true
end

--------------------------------------------------------------------------
-- 组件：客户端原版面板底图（默认关）
--------------------------------------------------------------------------

-- ElvUI 的皮肤把 PaperDollFrame 自带的贴图整个 Kill 掉了：
--   ElvUI\Modules\Skins\Blizzard\Character.lua:47   PaperDollFrame:StripTextures(true)
-- 而 StripTextures 的第二个参数是 kill（**不是** recursive —— 它只遍历这个 frame
-- 自己的区域，不递归子 frame），于是正好把原版面板底图和按种族的模型背景一起清掉：
--   UI-Character-newpaperdoll            593x595 @ TOPLEFT 0,-1，TexCoords 见下
--   paperdoll-background-race-<种族>      206x318 @ TOPLEFT 59,-74
--
-- 这里按 XML 原值重建它们。属于"两种风格二选一"（会叠在 ElvUI 的半透明底框上），
-- 所以默认关闭。
--
-- 关于种族背景：为了**绝不出现缺贴图的方块**，只有当文件路径能从客户端自己那张
-- 贴图上读出来时才重建（读不到就只留面板底图）。这样我一个路径都不用猜。
local clientArt

-- 复刻客户端 PaperShowFondoCool() 里的种族文件名映射
local function ModelRaceKey()
    local _, fileName = UnitRace("player")
    if fileName == "Skeleton" or fileName == "Tuskarr" then
        fileName = "pandaren"
    elseif fileName == "Scourge" then
        fileName = "undead"
    elseif fileName == "Naga_" then
        fileName = "vulpera"
    elseif fileName == "Taunka" then
        fileName = "lightforged"
    elseif fileName == "Broken" then
        fileName = "nightborne"
    elseif fileName == "FelOrc" or fileName == "IceTroll" then
        fileName = "voidelf"
    end
    return string.lower(fileName or "")
end

local function BuildClientPanelArt()
    if clientArt then return end

    local pdf = Name2Frame("PaperDollFrame")
    if not pdf or not pdf.CreateTexture then return end

    local art = {}

    -- 面板底图（路径与 TexCoords 照抄 patch-enus-9 的 PaperDollFrame.xml:604-616）
    local bg = pdf:CreateTexture("McodeCharPanelFixArtBackground", "BACKGROUND")
    bg:SetTexture("Interface\\FrameXML\\PaperDollInfoFrame\\UI-Character-newpaperdoll")
    bg:SetSize(593, 595)
    bg:SetPoint("TOPLEFT", 0, -1)
    bg:SetTexCoord(0, 0.65343750, 0, 0.59000625)
    art[#art + 1] = bg

    -- 按种族的模型背景：文件名和 TexCoords 都从客户端自己那张贴图上读。
    -- 注意 TexCoords 是必须的：那是 512x512 的图集，实例继承了 virtual 的裁剪
    -- (0.001953125, 0.576171875, 0.001953125, 0.966796875)，不设就会整张糊上去。
    local raceKey = ModelRaceKey()
    local src = Name2Frame("paperdoll-background-race-" .. raceKey)
    local path = src and src.GetTexture and src:GetTexture()
    if type(path) == "string" and path ~= "" then
        local race = pdf:CreateTexture("McodeCharPanelFixArtRace", "BACKGROUND")
        race:SetTexture(path)
        race:SetSize(206, 318)
        race:SetPoint("TOPLEFT", 59, -74)

        local l, r, t, b
        if src.GetTexCoord then
            l, r, t, b = src:GetTexCoord()
        end
        if type(l) == "number" and type(b) == "number" then
            race:SetTexCoord(l, r, t, b)                    -- 优先照抄客户端的裁剪
        else
            race:SetTexCoord(0.001953125, 0.576171875, 0.001953125, 0.966796875)
        end

        art[#art + 1] = race
        ns.clientArtRacePath = path
    else
        ns.clientArtRacePath = nil
    end

    clientArt = art
end

local function ApplyClientPanelArt()
    -- 这个组件的定义是"重建被 ElvUI 皮肤 Kill 掉的原版底图"。没有 Enhanced 时
    -- 底图根本没被 Kill，重建只会叠一份重复的 —— 门控掉。
    if not CharModuleActive() then return end

    BuildClientPanelArt()
    if not clientArt then return end

    local on = DB().clientPanelArt
    for i = 1, #clientArt do
        if on then clientArt[i]:Show() else clientArt[i]:Hide() end
    end
end

--------------------------------------------------------------------------
-- 组件 4：让装备等级只有一个来源
--------------------------------------------------------------------------

-- 客户端算好的装等文本（形如 "258 (GS: 0)"），取开头的数字，顺手把后缀去掉。
-- v1.6 起只保留整数部分（"268.6"→"268"）
local function ClientItemLevelText()
    local f = Name2Frame("PGearScore")
    if not f or not f.GetText then return nil end
    local text = f:GetText()
    if type(text) ~= "string" or text == "" then return nil end
    -- 必须从行首就是数字，避免像 "GS: 0" 这种被误取成 0；只截整数，不四舍五入
    local num = strmatch(text, "^%s*(%d+)")
    if not num or tonumber(num) == 0 then return nil end
    return num
end

-- 兜底：自己按装备算一遍。口径 = Warmane 玩家习惯（论坛流传的查装等宏与
-- InspectEquip 同款）：1-18 栏位去衬衣（slot 4），有几件除几件；空栏不把
-- 平均拖低，副手填上也不虚高。客户端烤包的 CalculateAverage 断链时走这里。
local function ComputeItemLevel()
    local total, count = 0, 0
    for slot = 1, 18 do
        if slot ~= 4 then                       -- 4 = 衬衫，不计入
            local link = GetInventoryItemLink("player", slot)
            if link then
                local _, _, _, ilvl = GetItemInfo(link)
                if ilvl and ilvl > 0 then
                    total = total + ilvl
                    count = count + 1
                end
            end
        end
    end
    if count == 0 then return nil end
    return total / count
end

local function ItemLevelColor()
    if G.GetItemLevelColor then
        local r, g, b = G.GetItemLevelColor()
        if r then return r, g, b end
    end
    return 1, 1, 1
end

local function ApplyItemLevel()
    local m = GetCharModule()
    if not m or type(m.ItemLevel) ~= "function" or m.__cpfixItemLevel then return false end

    local orig = m.ItemLevel

    -- 注意：PAPERDOLL_STATINFO 的闭包是 module:ItemLevel(...) 调用的，
    -- 所以直接替换 module 上的这个方法就能生效。
    m.ItemLevel = function(self, statFrame, unit)
        if statFrame and statFrame.Label then
            local numText = ClientItemLevelText()
            if not numText then
                local avg = ComputeItemLevel()
                -- v1.6：整数显示，与 ClientItemLevelText 的截法一致
                if avg then numText = format("%d", math.floor(avg)) end
            end

            if numText then
                statFrame.Label:SetText(numText)
                statFrame.Label:SetTextColor(ItemLevelColor())
                if statFrame.Value then statFrame.Value:SetText("") end
                return
            end
        end
        return orig(self, statFrame, unit)
    end

    m.__cpfixItemLevel = true

    -- 客户端那块大号 258 (GS: 0) 现在没用了，收掉它
    HideFrame(Name2Frame("PGearScore"))
    return true
end

-- ITEM_LEVEL 分类在存档里是**折叠**的（collapsedName2.ITEM_LEVEL = true），折叠状态下
-- 行不画、装等数字看不到。这里把它展开：既改 frame 上的状态并重画，也把存档里的折叠
-- 标记翻掉 —— 否则每次打开面板 PaperDoll_InitStatCategories 又会把它折回去。
-- 只在本次登录做一次，之后你想手动折叠就随你。
EnsureItemLevelExpanded = function()
    if ns.itemLevelExpanded then return end

    local m = GetCharModule()
    local pane = Name2Frame("CharacterStatsPane")
    if not m or not pane or type(pane.Categories) ~= "table" then return end

    local E = GetE()
    local char = E and E.private and E.private.enhanced and E.private.enhanced.character
    local priv = char and char.player
    if type(priv) == "table" then
        local keys = { "collapsedName", "collapsedName2" }
        for i = 1, #keys do
            local t = priv[keys[i]]
            if type(t) == "table" then t.ITEM_LEVEL = false end
        end
    end

    for i = 1, 8 do
        local cat = pane.Categories[i]
        if cat and cat.Category == "ITEM_LEVEL" and cat.collapsed then
            cat.collapsed = false
            if cat.Toolbar then cat.Toolbar:SetAlpha(1) end
            -- 复刻它自己的 ExpandStatCategory：重画这个分类 + 重算滚动高度
            pcall(m.PaperDollFrame_UpdateStatCategory, m, cat)
            if m.PaperDollFrame_UpdateStatScrollChildHeight then
                pcall(m.PaperDollFrame_UpdateStatScrollChildHeight, m)
            end
        end
    end

    ns.itemLevelExpanded = true
end

--------------------------------------------------------------------------
-- 组件 5：ElvUI_Enhanced 属性行的几何
--------------------------------------------------------------------------

-- "物品等级"这个标题：默认用 TUNING.itemLevelLabel；把它设成 nil 时会从客户端的
-- ITEM_LEVEL 字串里取（汉化包是 "物品等级 %d" 之类），最后退回英文。
local function ItemLevelLabel()
    local label = TUNING.itemLevelLabel
    if type(label) == "string" and label ~= "" then return label end
    local raw = G.ITEM_LEVEL
    if type(raw) == "string" then
        -- 只取开头的非数字部分（Lua 的字符类按字节工作，别把多字节标点写进 [] 里）
        local s = strmatch(raw, "^[^%d]*")
        if s and s ~= "" then return s end
    end
    return "Item Level"
end

-- 属性行的字号：默认跟随 ElvUI 的 general.fontSize
local function ResolveFontSize()
    if type(TUNING.rowFontSize) == "number" then return TUNING.rowFontSize end
    local E = GetE()
    local size = E and E.db and E.db.general and E.db.general.fontSize
    if type(size) ~= "number" or size < 6 then size = 14 end
    return size
end

-- 属性行的高度。中文字框比字号高，行高必须留余量，否则相邻行会互相压
-- （原逻辑写死 15px，行与行是零间距串接的，必然重叠）。
local function ResolveRowHeight()
    if type(TUNING.rowHeight) == "number" then return TUNING.rowHeight end
    return ResolveFontSize() + 5
end

local function FixStatRows(categoryFrame)
    local stats = categoryFrame and categoryFrame.Stats
    if type(stats) ~= "table" then return end

    -- ITEM_LEVEL 分类只有一个 stat（"ITEM_LEVEL"），它的行由原逻辑设成 30px、
    -- 标签 187px 居中、字号 20；其余分类的行高/标签宽都是写死的拉丁文尺寸。
    local isItemLevelCategory = (categoryFrame.Category == "ITEM_LEVEL")

    -- 原生逻辑在 GearScoreLite 存在时会把标题写成英文 "Gear Score"。
    -- 我们显示的是平均装等，标题应该还是"物品等级"。
    if isItemLevelCategory and categoryFrame.NameText then
        categoryFrame.NameText:SetText(ItemLevelLabel())
    end

    local fontSize = ResolveFontSize()
    local rowHeight = ResolveRowHeight()

    for i = 1, #stats do
        local row = stats[i]
        if row and row.Label and row.Label.FontTemplate then
            if isItemLevelCategory then
                row:Height(30)
                row.Label:Width(187)
                row.Label:ClearAllPoints()
                row.Label:SetPoint("CENTER")
                row.Label:SetJustifyH("CENTER")
                row.Label:FontTemplate(nil, TUNING.itemLevelFontSize, "NONE")
            else
                row:Height(rowHeight)
                row.Label:Width(TUNING.labelWidth)
                -- 标签和数值统一字号。这个 HD 客户端里标签用的 GameFontNormalSmall
                -- 和数值用的 GameFontHighlightSmall 不等大（截图里绿色数字明显更大），
                -- 只调行高的话数值仍会溢出到相邻行。
                row.Label:FontTemplate(nil, fontSize, "NONE")
                if row.Value and row.Value.FontTemplate then
                    row.Value:FontTemplate(nil, fontSize, "NONE")
                end
            end
        end
    end
end

-- 照搬 ElvUI_Enhanced 自己的高度算法重排分类，这样即使拿不到它的模块对象，
-- 几何也能修正（它的 PaperDollFrame_UpdateStatCategory 只对展开的分类设高度，
-- 折叠的分类保持它 CollapseStatCategory 设的 18px，所以这里也不碰折叠的）。
local function LayoutPane()
    local pane = Name2Frame("CharacterStatsPane")
    if not pane or type(pane.Categories) ~= "table" then return end

    local total = 0
    local shownCount = 0

    for i = 1, 8 do
        local cat = pane.Categories[i]
        if cat then
            if cat.Category and cat:IsShown() and not cat.collapsed then
                local h = (cat.NameText and cat.NameText:GetHeight() or 0) + 10
                local stats = cat.Stats
                if type(stats) == "table" then
                    for j = 1, #stats do
                        local row = stats[j]
                        if row and row:IsShown() then h = h + row:GetHeight() end
                    end
                end
                cat:Height(h)
            end

            if cat:IsShown() then
                total = total + cat:GetHeight() + 4
                shownCount = shownCount + 1
            end
        end
    end

    local child = Name2Frame("CharacterStatsPaneScrollChild")
    if child and shownCount > 0 then
        child:Height(total + 10 - (pane.initialOffsetY or 0))
    end
end

-- 对当前面板整体跑一遍几何修正（幂等，可以随便重复调用）
FixAllCategoriesNow = function()
    local pane = Name2Frame("CharacterStatsPane")
    if not pane or type(pane.Categories) ~= "table" then return false end

    local touched = false
    for i = 1, 8 do
        local cat = pane.Categories[i]
        if cat and cat.Category and cat:IsShown() then
            FixStatRows(cat)
            touched = true
        end
    end
    if touched then LayoutPane() end
    return touched
end

local function ApplyEnhancedGeometry()
    local m = GetCharModule()

    -- 能拿到模块就把它的分类更新包一层：这样每次它自己刷新时几何立刻是对的，
    -- 不用等下面的轮询。
    if m and not m.__cpfixGeometry and type(m.PaperDollFrame_UpdateStatCategory) == "function" then
        local origCategory = m.PaperDollFrame_UpdateStatCategory

        m.PaperDollFrame_UpdateStatCategory = function(self, categoryFrame)
            -- 先把已存在的行纠正过来，这样原函数累加分类高度时用的是真实行高
            FixStatRows(categoryFrame)

            local ok, err = pcall(origCategory, self, categoryFrame)

            -- 再纠正一遍（本次调用里新建的行拿到的是 XML 模板的 15px），并重排高度
            FixStatRows(categoryFrame)
            LayoutPane()

            if not ok then error(err, 0) end
        end

        m.__cpfixGeometry = true
    end

    -- 不管有没有包上模块，都整体跑一遍兜底
    FixAllCategoriesNow()
    return true
end

--------------------------------------------------------------------------
-- 组件 6：LibSharedMedia 字体名
--------------------------------------------------------------------------

-- 配置里引用了 "AvantGarde LT Medium" / "AvantGarde LT Bold" 共 40 多处，
-- 但这两个名字没有任何 LSM 注册，于是全部静默回退到 Fonts\ZYKai_T.ttf。
-- 这里把名字显式绑定到"当前实际生效的那套中文字体"，消除隐式回退：
-- 视觉结果不变，但配置与呈现不再脱节。（想换成真正的拉丁 AvantGarde，
-- 把下面的路径改成 Interface\AddOns\ElvUI_CustomMedia\Fonts\AvantGarde.ttf，
-- 但那样中文会缺字形。）
local function ApplyFonts()
    local E = GetE()
    local LSM = (E and E.LSM) or (G.LibStub and G.LibStub("LibSharedMedia-3.0", true))
    if not LSM then return false end

    local cjkKai = "Fonts\\ZYKai_T.ttf"
    local cjkHei = "Fonts\\ZYHei.ttf"

    if not LSM:IsValid("font", "AvantGarde LT Medium") then
        LSM:Register("font", "AvantGarde LT Medium", cjkKai)
    end
    if not LSM:IsValid("font", "AvantGarde LT Bold") then
        LSM:Register("font", "AvantGarde LT Bold", cjkHei)
    end
    return true
end

--------------------------------------------------------------------------
-- 组件 7：底部标签行跟随可见窗口（tabAnchor）
--------------------------------------------------------------------------

-- 现象：底部 角色/宠物/声望/技能/货币 那排标签（CharacterFrameTab1-5），在"角色"页
-- 和"宠物（小伙伴）"页的落点不一致，窗口一变它们就漂。
--
-- 根因：三层代码在抢同一个 CharacterFrame 的几何，且各写各的值 ——
--   1) 客户端 FrameXML（patch-enus-9 的 CharacterFrame.lua）：
--      characterframe_toggle_size() 在每次切页/开关面板时把窗口改写成
--      525x506（角色页）或 384x512（其余所有页），还顺带挪关闭按钮；
--   2) ElvUI 皮肤（Modules\Skins\Blizzard\Character.lua）：给窗口建半透明底框
--      CharacterFrame.backdrop（钉在 (11,-12)~(-32,76)），并通过
--      SetUIPanelWindowInfo 写 UIPanelLayout-width 属性 —— 这个属性一变，
--      UIParent 会把整个窗口重新锚定一次（窗口在屏幕上平移）；
--   3) ElvUI_Enhanced 的展开/收起（Modules\Blizzard\CharacterFrame.lua）：
--      又把 backdrop 改成绝对尺寸 Size(341,424) / Width(538)，同样写宽度属性。
-- 标签行本体锚在 frame 的 BOTTOMLEFT(11,46)、Tab2-5 依次链在右侧，不跟 backdrop
-- —— 窗口矩形每页被不同的代码改写一遍，标签行相对"看得见的窗口"的落点就变了。
--
-- 修法（最小改）：把 CharacterFrameTab1 改锚到 backdrop 的 BOTTOMLEFT(0,-30)。
-- backdrop 的左/下边界就是看得见的窗口边界，标签行相对它恒定 —— 之后无论哪套
-- 代码把窗口改成什么尺寸，这排标签都贴住窗口左下角。Tab2-5 链在 Tab1 右边，
-- 自动跟随；运行时没有任何代码会重新 SetPoint Tab1（PetPaperDollFrame 的
-- UpdateIsAvailable 只动 Tab3），所以补一次锚 + 面板 OnShow 时重申即可。
-- 偏移 (0,-30) 是原位换算：backdrop 左边界 = frame 左 +11（与 Tab1 原 x 相同），
-- backdrop 底边界 = frame 底上方 76，Tab1 原本在 frame 底上方 46 → 相对 backdrop
-- 底就是 -30。视觉位置与原来一致，只消除页面间的漂移。
--
-- 门控说明：这是唯一不看 CharModuleActive 的组件 —— 错位是 ElvUI 本体皮肤和
-- 客户端 FrameXML 的相互作用（Enhanced 只是参与方之一），门槛是 backdrop 本身
-- 存在：皮肤没跑就没有 backdrop，标签行留在客户端 XML 的原锚点上，那套布局
-- 自成一体，不该动。关掉组件后锚点不会自动还原，建议 /reload。

local function ApplyTabAnchor()
    -- 面板每次打开都补一遍：ElvUI 皮肤可能比我们晚建 backdrop
    local hooks = ns.hooks
    if not hooks then hooks = {} ns.hooks = hooks end
    if not hooks.tabAnchor then
        local cf0 = Name2Frame("CharacterFrame")
        if cf0 then
            cf0:HookScript("OnShow", function()
                if DB().tabAnchor then ApplyTabAnchor() end
            end)
            hooks.tabAnchor = true
        end
    end

    local cf = Name2Frame("CharacterFrame")
    local bd = cf and cf.backdrop
    local tab1 = Name2Frame("CharacterFrameTab1")
    if not (bd and tab1) then return false end

    -- 幂等：GetPoint(1) 的 relativeTo 拿到的就是那张表，直接比对
    local ok, point, rel = pcall(tab1.GetPoint, tab1, 1)
    if ok and point == "BOTTOMLEFT" and rel == bd then return true end

    tab1:ClearAllPoints()
    tab1:SetPoint("BOTTOMLEFT", bd, "BOTTOMLEFT", 0, -30)
    return true
end

--------------------------------------------------------------------------
-- 组件 8：固定宽文本框适配 CJK 字体（textFit）
--------------------------------------------------------------------------

-- 现象：公会页标题 "Shadow Priest Supremacy - Initi..."、公会名单 Lv 列全部显示
-- ".."、地下城查找器列表 "(80 - ..."。看着像窗口尺寸问题，其实窗口宽与原版一致
-- （FriendsFrame 384、LFDParentFrame 355），ElvUI 也没写死过这些宽度 ——
--
-- 根因：汉化包（patch-enus-z.mpq）用同一个 CJK 字体顶替了客户端全部五种标准字体
-- （Fonts.xml 里 FRIZQT__/ARIALN/MORPHEUS/SKurri/Friendsframe 全指向同一文件），
-- 它的拉丁字形（数字/字母）比原版宽得多。而下面这几处文本框是按原版窄字体写死的
-- 固定宽度，文字装不下时 WoW 引擎自动打省略号。所以裸客户端（不开任何插件）同样
-- 截断，修法只能是放宽文本框：
--   FriendsFrameTitleText                          250 -> 330   公会名 - 军衔
--   GuildFrameButton%dLevel                        20 -> 34     名单 Lv 列（"80" 都装不下）
--   GuildFrameGuildStatusButton%dLevel             20 -> 34     公会状态视图的同款列
--   LFDQueueFrameSpecificListButton%dInstanceLevel 60 -> 84     "(80 - 80)" 约 70px
-- 实例名已从生效层 XML 逐一核对（FriendsFrame.xml=patch-enus-3、LFGFrame.xml=
-- patch-enus-2；LFDFrame.xml 里没有重定义宽度的副本，也没有其他 Choice 模板实例）。
--
-- SetWidth 保持原锚点、原位扩宽：标题是 TOP 居中锚（对称扩，330 仍在 384 宽的框
-- 内）；LFD 等级串 RIGHT 锚钉在行右缘（向左扩，名字列 RIGHT 链在它左侧 -10，自动
-- 让位，最长名"安卡赫特：古代王国"仍有余量）；公会行的 level 被 ElvUI 皮肤钉在
-- TOPLEFT(10,-1)（向右扩到 x=44，职业图标在 x=48，不重叠）。ClearAllPoints 不会
-- 重置宽度，ElvUI 皮肤晚于我们跑也不会冲掉。
--
-- 门控说明（v1.5 起）：仅当 ElvUI 在场（GetE() 拿到引擎）时生效。裸客户端同样会
-- 截断 —— 根因是"字体 × 客户端 XML 固定宽度"，与 Enhanced 是否在场无关，所以这里
-- 用的门槛是 ElvUI 本体而不是 CharModuleActive；但按约定，ElvUI 不在时不碰任何
-- 面板。关掉组件后宽度要 /reload 才还原。

local function ApplyTextFit()
    -- ElvUI 不在场就不装钩子、不碰宽度（ElvUI 按字母序先于本插件加载，
    -- ADDON_LOADED 时全局 ElvUI 已就绪；之后再启用必然经过 /reload，无需补偿）
    if not GetE() then return false end

    -- 面板每次打开都补一遍：目前没有任何代码会重设这些宽度，但 Hook 的成本可以忽略
    local hooks = ns.hooks
    if not hooks then hooks = {} ns.hooks = hooks end
    for i = 1, 2 do
        local name = (i == 1) and "FriendsFrame" or "LFDParentFrame"
        if not hooks["textFit_" .. name] then
            local fr = Name2Frame(name)
            if fr then
                fr:HookScript("OnShow", function()
                    if DB().textFit then ApplyTextFit() end
                end)
                hooks["textFit_" .. name] = true
            end
        end
    end

    local applied = 0

    local title = Name2Frame("FriendsFrameTitleText")
    if title then
        title:SetWidth(330)
        applied = applied + 1
    end

    local rowPrefixes = { "GuildFrameButton", "GuildFrameGuildStatusButton" }
    for p = 1, 2 do
        for i = 1, 13 do
            local fs = Name2Frame(rowPrefixes[p] .. i .. "Level")
            if fs then
                fs:SetWidth(34)
                applied = applied + 1
            end
        end
    end

    for i = 1, 15 do
        local fs = Name2Frame("LFDQueueFrameSpecificListButton" .. i .. "InstanceLevel")
        if fs then
            fs:SetWidth(84)
            applied = applied + 1
        end
    end

    return applied > 0
end

--------------------------------------------------------------------------
-- 组件 9：悬停自己补 GS 行（selfGS，v1.7）
--------------------------------------------------------------------------

-- GearScoreLite 的算分门控是 `CanInspect("mouseover")`，而自己不能被观察，
-- 于是悬停自己的角色模型 / 玩家框体时永远没有 GS 行（别人都有）。
-- 这里在它的钩子之后补一行：只处理单位=玩家的提示框，读本地装备数据
-- （无需 NotifyInspect，也没有异步等待），格式与颜色和它自己画的完全一致。
-- 门控只看 GearScoreLite 是否在场（提示框与 Enhanced 无关，不看 CharModuleActive）。
local function SelfGSLineExists(tt)
    for i = 1, tt:NumLines() do
        local line = _G["GameTooltipTextLeft" .. i]
        local text = line and line.GetText and line:GetText()
        if type(text) == "string" and strfind(text, "GearScore:") then return true end
    end
    return false
end

local function ApplySelfGS()
    local hooks = ns.hooks
    if not hooks then hooks = {} ns.hooks = hooks end
    if hooks.selfGS then return end

    -- GearScoreLite 没到场就等下一轮（本插件在字母序上先于它加载，ADDON_LOADED
    -- 那轮必然拿不到；PLAYER_LOGIN 之后它一定在）
    if not (type(G.GearScore_GetScore) == "function"
        and type(G.GearScore_GetQuality) == "function") then return end

    hooks.selfGS = true

    -- 必须排在 GearScoreLite 自己的钩子之后（它在文件加载时就挂好了，我们在
    -- PLAYER_LOGIN 轮才挂）——这样别人身上它已画完 GS 行，这里只兜自己的底
    GameTooltip:HookScript("OnTooltipSetUnit", function(tt)
        if not DB().selfGS then return end
        if G.GS_PlayerIsInCombat then return end          -- 与 GearScoreLite 的战斗门控一致
        local settings = G.GS_Settings
        if settings and settings.Player ~= 1 then return end

        local _, unit = tt:GetUnit()
        if not unit or not UnitIsUnit(unit, "player") then return end
        if SelfGSLineExists(tt) then return end           -- 它已经画过就不重复

        local ok, score, avg = pcall(G.GearScore_GetScore, UnitName("player"), "player")
        if not ok or type(score) ~= "number" or score <= 0 then return end
        local okQ, r, b, g = pcall(G.GearScore_GetQuality, score)
        if not okQ or not r then return end

        -- 颜色消参与 GearScoreLite 一致：GetQuality 返回 (R,G,B)，它按 (R,B,G) 接、
        -- 再按 (R,G,B) 传；这里同样按 (r,g,b)=(第1,第3,第2) 传
        if settings and settings.Level == 1 and avg then
            tt:AddDoubleLine("GearScore: " .. score, "(iLevel: " .. avg .. ")", r, g, b, r, g, b)
        else
            tt:AddLine("GearScore: " .. score, r, g, b)
        end
    end)
end

--------------------------------------------------------------------------
-- 组件 10：新角色自动补开 Enhanced 角色面板模块（enhancedEnable，v1.9.3）
--------------------------------------------------------------------------

-- 现象：新建的角色（以及所有从没单独开过"角色面板"模块的角色）面板缺一整套增强：
-- 右侧属性栏空白、左下没有展开/收起小箭头、右上没有三个侧栏切换标签、
-- 装备管理图标反而露在外面、人物模型两个叠影、"GearScore" 标签孤零零没有数字。
--
-- 根因（20261013 逐层查实）：
--   * ElvUI_Enhanced 的"角色面板"开关 E.private.enhanced.character.enable 是
--     **逐角色私密设置**，出厂默认 false（Settings/Private.lua: V.enhanced.character.enable）。
--   * 老角色的私密档案（ElvPrivateDB.profileKeys 映射到的共享档案，如"白羊丨骑 - BD霜语"）
--     里存着显式 true，所以一切正常；每个新角色首次登录会拿到自己的空档案 →
--     enable 取默认 false → 模块 Initialize 开头 `if not ...enable then return end`
--     直接早退：属性面板/展开按钮/侧栏标签都不建、客户端原版 OnEvent 不被替换
--     （CharacterModelFrame2 拿到单位、和本插件显示的那张模型叠成两个）、
--     GearManagerToggleButton 不被 Kill（那个露在外面的徽章图标）。
--   * 本插件旧门控只看模块对象在不在（对象在、只是没初始化），照常隐藏客户端
--     面板 —— 于是右侧只剩空白。
--
-- 修法：本角色档案里**没有显式值**时补 enable=true（显式 false = 用户自己关的，
-- 尊重不碰），并保证模块初始化恰好跑一次、不依赖加载顺序：
--   * 给 module.Initialize 换一层"只真正执行一次"的壳 —— 引擎的初始化回调用
--     的是 module:Initialize()（读表上的字段），所以壳能拦住重复调用；判断
--     "真的初始化了"看 CharacterStatsPane（模块 Initialize 里建的；enable 为假
--     时早退不会出现），早退不算数，开关补上后还要能再跑。
--   * 引擎在它自己的 PLAYER_LOGIN 里才初始化各模块（RegisterModule →
--     InitializeCallback）；本插件字母序在它前面、PLAYER_LOGIN 处理器也先跑，
--     所以登录轮里设置 enable 引擎就能看到。万一时序异常（过了
--     PLAYER_ENTERING_WORLD 还没初始化），这里主动补调一次；壳保证不双初始化。
-- 效果持久：值写进档案后，以后每次登录引擎自己就会正常初始化，本组件只是兜底。
-- 关掉本组件 = 不再自动补，已补过的值不退回（想退回在 ElvUI 选项里关该模块）。

-- 直接读存档侧的开关：ElvPrivateDB.profileKeys[角色键] → ElvPrivateDB.profiles[档案键]。
-- 返回该档案里的 enhanced.character 表（可能不存在），用来分辨：
--   表不存在 / 没有 enable 键 = 从没设过（新角色的默认态）→ 补
--   enable = false           = 用户显式关的 → 不碰
local function RawEnhancedCharacter()
    local pdb = G.ElvPrivateDB
    local E = GetE()
    local name = (E and E.myname) or G.UnitName("player")
    local realm = (E and E.myrealm) or G.GetRealmName()
    if not (pdb and name and realm) then return nil end
    local key = pdb.profileKeys and pdb.profileKeys[name .. " - " .. realm]
    local prof = key and pdb.profiles and pdb.profiles[key]
    return prof and prof.enhanced and prof.enhanced.character
end

local function EnsureEnhancedModule()
    local m = GetCharModule()
    if not m then return false end

    -- 只跑一次的壳（每个 UI 载入至多装一次）
    if not m.__cpfixInitOnce then
        local orig = m.Initialize
        if type(orig) == "function" then
            m.__cpfixInitOnce = true
            m.Initialize = function(self, ...)
                if ns.enhInitDone then return end
                local r = { orig(self, ...) }
                if G.CharacterStatsPane then ns.enhInitDone = true end
                return unpack(r)
            end
        end
    end

    local raw = RawEnhancedCharacter()
    if raw and raw.enable == false then return false end   -- 显式关：尊重

    local E = GetE()
    local live = E and E.private and E.private.enhanced and E.private.enhanced.character
    if live and live.enable ~= true then live.enable = true end
    -- 存档侧也写一份：运行时表与存档表若是两份拷贝，靠这里持久化（同一份则幂等）。
    -- 档案还不存在（角色全新建档）时跳过，下轮再补。
    if raw then raw.enable = true end

    if ns.enhInitDone or G.CharacterStatsPane then
        ns.enhInitDone = true
        return true
    end

    -- 兜底初始化：只在 PLAYER_ENTERING_WORLD 之后。那之前引擎的初始化轮可能还没
    -- 跑到（本插件 PLAYER_LOGIN 处理器在它前面），设置 enable 就够了；过了进入
    -- 世界还没初始化，说明引擎那轮已经带着旧的 enable 早退过，这里手动补一次。
    if ns.enhPastLogin then
        pcall(m.Initialize, m)
        local ok = G.CharacterStatsPane ~= nil
        if ok then ns.enhInitDone = true end
        -- 面板此刻开着：把它的 OnShow 走一遍，属性栏/展开按钮之类立即就位
        local pdf = Name2Frame("PaperDollFrame")
        if ok and pdf and pdf:IsShown() then
            local handler = pdf.GetScript and pdf:GetScript("OnShow")
            if type(handler) == "function" then pcall(handler, pdf) end
        end
        return ok
    end
    return true
end

--------------------------------------------------------------------------
-- 统一施加
--------------------------------------------------------------------------

-- 逐组件隔离：单个组件出错只记一笔，不再连坐后面的组件。
-- 20261008 教训：GSL 缺席时 GS 空壳的 SetText 报 "Font not set"，错误从 clientGS
-- 冲出 ApplyAll，排在后面的模型交互安装等整轮全都没跑 —— 表现就是"停用
-- GearScoreLite 后模型不能转"。错误仍交给错误处理器（BugSack 会记录，附组件名），
-- 只是不再中断施加流程。
local function RunComponent(name, func)
    local ok, err = pcall(func)
    if not ok then
        local hasHandler, handler = pcall(geterrorhandler)
        if hasHandler and type(handler) == "function" then
            pcall(handler, format("[HDClientFix] 组件 %s 出错（其余组件照常施加）：%s",
                tostring(name), tostring(err)))
        end
    end
end

local function ApplyAll()
    DB()

    -- 最先跑：它要把 Enhanced 角色模块开关补开，后面所有走 CharModuleActive
    -- 门控的组件才能在同一轮里正常干活（见组件 10 头注释）
    if db.enhancedEnable then RunComponent("enhancedEnable", EnsureEnhancedModule) end
    if db.sidebar then RunComponent("sidebar", ApplySidebar) end
    if db.clientGS then RunComponent("clientGS", ApplyClientGS) end
    if db.selfGS then RunComponent("selfGS", ApplySelfGS) end
    if db.clientStatPanels then RunComponent("clientStatPanels", ApplyClientStatPanels) end
    if db.clientTitles then RunComponent("clientTitles", ApplyClientTitles) end
    if db.clientToggleButtons then RunComponent("clientToggleButtons", ApplyClientToggleButtons) end
    if db.tabAnchor then RunComponent("tabAnchor", ApplyTabAnchor) end
    if db.textFit then RunComponent("textFit", ApplyTextFit) end
    if db.model then RunComponent("model", ApplyModel) end

    if db.itemLevel then
        RunComponent("itemLevel", function()
            if ApplyItemLevel() then
                -- 接管成功后立刻重画一次属性面板
                local m = GetCharModule()
                if m and m.PaperDollFrame_UpdateStats then pcall(m.PaperDollFrame_UpdateStats, m) end
            end
        end)
        RunComponent("itemLevelExpand", EnsureItemLevelExpanded)
    end

    if db.enhancedGeometry then RunComponent("enhancedGeometry", ApplyEnhancedGeometry) end
    if db.modelFeatures then RunComponent("modelFeatures", ApplyModelFeatures) end
    -- 无条件调用：关掉组件时要能把装上去的脚本卸掉
    RunComponent("modelControls", ApplyModelControls)
    RunComponent("dressUpControls", ApplyDressUpControls)
    -- 无条件调用：关掉这个组件时要能把它建出来的贴图收回去
    RunComponent("clientPanelArt", ApplyClientPanelArt)
    if db.fonts then RunComponent("fonts", ApplyFonts) end
end

-- 种族背景是即时生效的，所以只需要提一句；模型交互由 modelControls 自己装，
-- 也不需要 /reload。
local function AnnounceModelFeatures()
    if ns.modelFeaturesAnnounced then return end
    local changed = ns.modelFeaturesChanged
    if not changed or #changed == 0 then return end
    ns.modelFeaturesAnnounced = true
    P("已为你打开 ElvUI_Enhanced 的：" .. table.concat(changed, "、") .. "（已即时生效）。")
end

--------------------------------------------------------------------------
-- 事件
--------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:Show()        -- OnUpdate 只在可见的 frame 上跑，显式 Show 一下免得依赖默认值

local elapsed = 0
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            DB()
            ApplyAll()
        end
    elseif event == "PLAYER_LOGIN" then
        ApplyAll()
        AnnounceModelFeatures()
    else
        -- PLAYER_ENTERING_WORLD 之后，ElvUI 引擎的模块初始化轮必然已经跑过
        -- （它在那之前就完成了），enhancedEnable 的兜底初始化从此可以启用
        ns.enhPastLogin = true
        ApplyAll()
    end
end)

-- 角色面板可见时轻量地周期性重施（防止客户端自己的更新流程把东西又显示出来，
-- 也兜住"拿不到 ElvUI_Enhanced 模块"时几何修正失效的情况）
f:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < TUNING.reapplyInterval then return end
    elapsed = 0

    -- 试衣间独立于 PaperDollFrame；只开试衣间时也能补装或让位。
    local dress = G.DressUpModel
    if ns.dressUpControlsState or (dress and dress.IsShown and dress:IsShown()) then
        RunComponent("dressUpControls", ApplyDressUpControls)
    end
    local pdf = G.PaperDollFrame
    if not (pdf and pdf.IsShown and pdf:IsShown()) then return end

    local d = DB()

    if d.enhancedEnable then RunComponent("enhancedEnable", EnsureEnhancedModule) end
    if d.sidebar then RunComponent("sidebar", EnforceSidebar) end
    if d.clientGS then RunComponent("clientGS", ApplyClientGS) end
    if d.clientStatPanels then RunComponent("clientStatPanels", ApplyClientStatPanels) end
    if d.clientToggleButtons then RunComponent("clientToggleButtons", ApplyClientToggleButtons) end
    if d.tabAnchor then RunComponent("tabAnchor", ApplyTabAnchor) end
    if d.enhancedGeometry then RunComponent("enhancedGeometry", FixAllCategoriesNow) end
    -- 模型只补一次，SetUnit 会重置朝向，不能每轮都调（ApplyModel 内部有判断）
    if d.model then RunComponent("model", ApplyModel) end
    -- 模型交互：已装时只是重抬槽位（幂等）；哪一轮没装上，面板开着最迟 1 秒
    -- 由这里补上（20261008：曾因 clientGS 报错整场没装上，只能靠 /cpfix reload）
    if d.modelControls then RunComponent("modelControls", ApplyModelControls) end
end)

--------------------------------------------------------------------------
-- /cpfix dump
--------------------------------------------------------------------------

local dumpBox

-- 描述一个 frame 有没有模型相关的方法。
-- 只打印 GetUnit() 的返回值是不够的 —— 区分不出"没有这个方法"和"方法返回 nil"，
-- 上一轮就是因为这个多绕了一圈。
local function FmtModelMethods(fr)
    if not fr then return "?" end
    local setUnit = (type(fr.SetUnit) == "function") and "有" or "无"
    local getUnit = (type(fr.GetUnit) == "function") and "有" or "无"
    local unit = "?"
    if type(fr.GetUnit) == "function" then unit = tostring(fr:GetUnit()) end
    return format("SetUnit=%s GetUnit=%s(%s)", setUnit, getUnit, unit)
end

-- 紧凑地描述一个 frame 挂在哪、挂在谁身上 —— 判断"谁压着谁"靠这个
local function FmtWhere(fr)
    if not fr then return "?" end
    local parent = fr.GetParent and fr:GetParent()
    local pname = (parent and parent.GetName and parent:GetName()) or "?"
    if not fr.GetPoint then return format("[%s]", tostring(pname)) end
    local p, rel, rp, x, y = fr:GetPoint(1)
    if not p then return format("[%s] 无锚点", tostring(pname)) end
    local relName = (type(rel) == "table" and rel.GetName and rel:GetName()) or tostring(rel)
    return format("[%s] %s -> %s(%s) %s,%s", tostring(pname), tostring(p), tostring(rp),
        tostring(relName), tostring(x and format("%.0f", x)), tostring(y and format("%.0f", y)))
end

local function FmtFrame(name)
    local fr = Name2Frame(name)
    if not fr then return format("%-34s 缺失", name) end

    local shown = fr:IsShown() and "显示" or "隐藏"
    local p, rel, rp, x, y = fr:GetPoint(1)
    local where
    if p and rel then
        local relName = (type(rel) == "table" and rel.GetName and rel:GetName()) or tostring(rel)
        where = format("%s -> %s(%s) %s,%s", tostring(p), tostring(rp), tostring(relName),
            tostring(x and format("%.0f", x)), tostring(y and format("%.0f", y)))
    else
        where = "无锚点"
    end

    local text = ""
    if fr.GetText then
        local t = fr:GetText()
        if type(t) == "string" and t ~= "" then text = " 文字=" .. t end
    end

    local font = ""
    if fr.GetFont then
        local path, size, flags = fr:GetFont()
        if path then font = format(" 字体=%.0f %s", size or 0, tostring(flags)) end
    end

    return format("%-34s %s  [%s]%s%s", name, shown, where, font, text)
end

local function FontSizeOf(fs)
    if not fs or not fs.GetFont then return "?" end
    local _, size, flags = fs:GetFont()
    if not size then return "?" end
    if flags and flags ~= "" then return format("%.0f/%s", size, flags) end
    return format("%.0f", size)
end

local function FmtRow(row, prefix)
    if not row then return prefix .. "缺失" end
    local label = row.Label and row.Label.GetText and row.Label:GetText() or ""
    local value = row.Value and row.Value.GetText and row.Value:GetText() or ""
    return format("%s h=%.0f w=%.0f %s 字号 标签=%s 数值=%s | %-14s = %s",
        prefix, row:GetHeight() or 0, row:GetWidth() or 0,
        row:IsShown() and "显示" or "隐藏",
        FontSizeOf(row.Label), FontSizeOf(row.Value),
        tostring(label), tostring(value))
end

local function BuildDump()
    local out = {}
    local function add(s) out[#out + 1] = s end

    local E = GetE()
    local m = GetCharModule()

    add("===== CharPanelFix_Mcode 自检 =====")
    add(format("引擎获取方式: %s   角色模块获取方式: %s",
        tostring(ns.engineVia), tostring(ns.moduleVia)))
    add(format("ElvUI 引擎: %s   角色模块 Enhanced_CharacterFrame: %s",
        E and "已找到" or "未找到", m and "已找到" or "未找到"))
    do
        -- v1.9.3：开关的 live/档案两份值 + 模块是否真的初始化过（新角色排查入口）
        local ch = E and E.private and E.private.enhanced and E.private.enhanced.character
        local raw = RawEnhancedCharacter()
        add(format("Enhanced 角色模块开关: live=%s  档案=%s  已初始化=%s",
            tostring(ch and ch.enable),
            raw and tostring(raw.enable) or "无（档案缺此节）",
            tostring(G.CharacterStatsPane ~= nil)))
    end
    add(format("几何已包装: %s   装等已接管: %s   ITEM_LEVEL 已展开: %s",
        tostring(m and m.__cpfixGeometry or false),
        tostring(m and m.__cpfixItemLevel or false),
        tostring(ns.itemLevelExpanded or false)))
    add(format("生效行高/字号: rowHeight=%s rowFontSize=%s labelWidth=%s itemLevelFontSize=%s",
        tostring(ResolveRowHeight()), tostring(ResolveFontSize()),
        tostring(TUNING.labelWidth), tostring(TUNING.itemLevelFontSize)))
    if E and E.db and E.db.general then
        add(format("ElvUI 字体: %s / 字号 %s", tostring(E.db.general.font), tostring(E.db.general.fontSize)))
    end
    if E and E.private and E.private.enhanced and E.private.enhanced.character then
        local priv = E.private.enhanced.character
        local pub = E.db and E.db.enhanced and E.db.enhanced.character
        add(format("模型功能: characterBackground=%s  (本插件应用过=%s)",
            tostring(pub and pub.characterBackground),
            tostring(DB().modelFeaturesApplied or false)))
        add(format("  modelFrames(ElvUI_Enhanced 的交互)=%s", tostring(priv.modelFrames)))
        add(format("  模型交互当前由谁接管: %s", tostring(ns.modelControlsOwner or "无（未装）")))
    end
    if E and E.myrealm then
        add(format("角色: %s - %s  专精组: %s", tostring(E.myname), tostring(E.myrealm),
            tostring(G.GetActiveTalentGroup and G.GetActiveTalentGroup())))
    end

    add("")
    add("--- 侧栏（三者互斥，锚点相同）---")
    for i = 1, #PANE_NAMES do add(FmtFrame(PANE_NAMES[i])) end
    local pdf = Name2Frame("PaperDollFrame")
    add(format("PaperDollFrame.currentSideBarID = %s",
        tostring(pdf and pdf.currentSideBarID)))
    add(format("PAPERDOLL_SIDEBARS(全局) = %s", tostring(G.PAPERDOLL_SIDEBARS and #G.PAPERDOLL_SIDEBARS or "无")))

    add("")
    add("--- 底部标签行（tabAnchor）---")
    local cfMain = Name2Frame("CharacterFrame")
    add(FmtFrame("CharacterFrameTab1"))
    add(FmtFrame("CharacterFrameTab2"))
    if cfMain then
        local bd = cfMain.backdrop
        local bdText
        if bd then
            bdText = format("%.0fx%.0f  %s", bd:GetWidth() or 0, bd:GetHeight() or 0, FmtWhere(bd))
        else
            bdText = "无（ElvUI 角色皮肤未接管，tabAnchor 不生效）"
        end
        add(format("CharacterFrame 尺寸 %.0fx%.0f  Expanded=%s", cfMain:GetWidth() or 0,
            cfMain:GetHeight() or 0, tostring(cfMain.Expanded)))
        add(format("  backdrop: %s", bdText))
    end

    add("")
    add("--- 固定宽文本（textFit，应显示 330/34/84）---")
    local function FmtWidth(name)
        local fr = Name2Frame(name)
        if not fr then return format("  %-46s 缺失", name) end
        local t = ""
        if fr.GetText then
            local s = fr:GetText()
            if type(s) == "string" and s ~= "" then t = "  文字=" .. s end
        end
        return format("  %-46s w=%.0f%s", name, fr:GetWidth() or 0, t)
    end
    add(FmtWidth("FriendsFrameTitleText"))
    add(FmtWidth("GuildFrameButton1Level"))
    add(FmtWidth("GuildFrameGuildStatusButton1Level"))
    add(FmtWidth("LFDQueueFrameSpecificListButton1InstanceLevel"))

    add("")
    add("--- ElvUI_Enhanced 属性面板每一行 ---")
    local pane = Name2Frame("CharacterStatsPane")
    if pane and pane.Categories then
        for i = 1, 8 do
            local cat = pane.Categories[i]
            if cat then
                local title = cat.NameText and cat.NameText.GetText and cat.NameText:GetText() or "?"
                add(format("分类[%d] %-16s %s h=%.0f collapsed=%s 标题=%s", i, tostring(cat.Category),
                    cat:IsShown() and "显示" or "隐藏", cat:GetHeight() or 0,
                    tostring(cat.collapsed), tostring(title)))
                if type(cat.Stats) == "table" then
                    for j = 1, #cat.Stats do add(FmtRow(cat.Stats[j], format("     行%d ", j))) end
                end
            end
        end
    else
        add("CharacterStatsPane 缺失（ElvUI_Enhanced 角色模块可能没开）")
    end

    -- 这一节不依赖我知道任何名字：凡是还画在角色面板上的东西都会现形。
    -- 排查"还有残留重叠"时先看这里。
    add("")
    add("--- 角色面板下当前【可见】的东西（残留重叠就看这里）---")
    if pdf and pdf.GetChildren then
        local kids = { pdf:GetChildren() }
        local shownKids, shownRegions = 0, 0

        -- 只列 PaperDollFrame 的直接子对象是不够的 —— 挂在这些子对象**下面**的东西
        -- 就完全看不见了。之前"隐藏 CharacterModelFrame2 顺手收走了武器槽"就是这么漏掉的：
        -- 武器槽是 CharacterModelFrame2 的子对象，从来没有进过这份清单。
        -- 所以这里对每个可见子对象再列一层它的可见子对象。
        local function ListFrame(kid, indent)
            local text = ""
            if kid.GetText then
                local t = kid:GetText()
                if type(t) == "string" and t ~= "" then text = " 文字=" .. t end
            end
            local unit = ""
            if kid.SetUnit or kid.GetUnit then
                unit = " " .. FmtModelMethods(kid)
            end
            add(format("  %s%-28s h=%.0f w=%.0f %s%s%s",
                indent, tostring(kid:GetName()), kid:GetHeight() or 0, kid:GetWidth() or 0,
                FmtWhere(kid), unit, text))
        end

        for i = 1, #kids do
            local kid = kids[i]
            if kid:IsShown() then
                shownKids = shownKids + 1
                ListFrame(kid, "")

                if kid.GetChildren then
                    local sub = { kid:GetChildren() }
                    for j = 1, #sub do
                        if sub[j]:IsShown() then
                            ListFrame(sub[j], "  └ ")
                        end
                    end
                end
            end
        end

        if pdf.GetRegions then
            local regs = { pdf:GetRegions() }
            for i = 1, #regs do
                local reg = regs[i]
                if reg and reg.IsShown and reg:IsShown() and reg.GetText then
                    local t = reg:GetText()
                    if type(t) == "string" and t ~= "" then
                        shownRegions = shownRegions + 1
                        add(format("  [区域] %-28s 文字=%s", tostring(reg:GetName()), t))
                    end
                end
            end
        end
        add(format("  共 %d 个可见子 frame、%d 个有文字的区域（装备槽位/模型/属性面板都是正常的）",
            shownKids, shownRegions))
    else
        add("  取不到 PaperDollFrame")
    end

    -- 每个重复模型身上挂着什么 —— 上一版就是在这里看漏了：
    -- 武器槽挂在 CharacterModelFrame2 下面，隐藏它会把槽位一起收走。
    add("")
    add("--- 各模型 frame 的子对象（隐藏模型前先看这里）---")
    do
        local list = ResolveModelFrames()
        local reported = false
        for i = 1, #list do
            local fr = Name2Frame(list[i])
            if fr and fr.GetChildren then
                local kids2 = { fr:GetChildren() }
                if #kids2 > 0 then
                    reported = true
                    add(format("  %s 有 %d 个子对象:", list[i], #kids2))
                    for j = 1, #kids2 do
                        local k = kids2[j]
                        add(format("      %-32s %s", tostring(k:GetName()),
                            k:IsShown() and "显示" or "隐藏"))
                    end
                end
            end
        end
        if not reported then
            add("  （所有模型 frame 都没有子对象）")
        end
    end

    -- 人物模型单独看：这个客户端把 XML 加载了两遍，模型有两个。能用的那张（带 SetUnit）
    -- 常常是被藏着的那张，而露在外面的孪生版本给不了单位 —— 所以模型区是空的。
    add("")
    add("--- 人物模型 frame ---")
    modelFrames = nil                          -- 重扫
    local models = ResolveModelFrames()
    if #models == 0 then
        add("  一个都没找到（^CharacterModelFrame）")
    else
        for i = 1, #models do
            local fr = Name2Frame(models[i])
            if fr then
                add(format("  %-24s %s h=%.0f w=%.0f %s %s",
                    models[i], fr:IsShown() and "显示" or "隐藏",
                    fr:GetHeight() or 0, fr:GetWidth() or 0,
                    FmtModelMethods(fr), FmtWhere(fr)))
            end
        end
    end

    add("")
    add(format("客户端原版底图: clientPanelArt=%s", tostring(DB().clientPanelArt)))
    add(format("  种族背景贴图路径: %s", tostring(ns.clientArtRacePath
        or "（从客户端贴图上读不到路径 → 已跳过种族背景，只留面板底图）")))

    -- 鼠标由**层级**决定（上层有鼠标的 frame 先拿到事件），坐标一样不代表谁在上面。
    -- 上一版就是因为只盯着坐标/显隐、没看层级，才漏掉"模型吃掉右列槽位鼠标"这个问题。
    add("")
    add("--- 层级（决定鼠标归谁）---")
    do
        local t = PickTargetModel()
        local model = t and t.frame
        if model then
            add(format("  模型 %s  level=%s", tostring(model:GetName()),
                tostring(model:GetFrameLevel())))
            add(format("  已抬升的可见槽位: %s 个 → level=%s",
                tostring(ns.modelSlotCount or 0), tostring(ns.modelSlotLevel or "-")))
            local slots = CollectVisibleSlots(model)
            local minL, maxL
            for i = 1, #slots do
                local l = slots[i]:GetFrameLevel()
                if l then
                    minL = (not minL or l < minL) and l or minL
                    maxL = (not maxL or l > maxL) and l or maxL
                end
            end
            add(format("  实际可见槽位 level 区间: %s ~ %s（都应高于模型的 level）",
                tostring(minL or "-"), tostring(maxL or "-")))
        else
            add("  取不到模型 frame")
        end
    end

    add("")
    add("--- 客户端残留控件 ---")
    clientFrameCache = nil                  -- 重新扫一遍，保证自检结果是最新的
    local list = ResolveClientFrames()
    for i = 1, #list do add(FmtFrame(list[i])) end

    add("")
    add("--- 属性数据通路（这里为 0 就说明是客户端 API 的问题，不是排版问题）---")
    if G.UnitStat then
        local parts = {}
        for i = 1, 5 do
            local stat, eff = G.UnitStat("player", i)
            local label = G["SPELL_STAT" .. i .. "_NAME"] or i
            parts[#parts + 1] = format("%s=%s", tostring(label), tostring(eff or stat))
        end
        add("UnitStat(player)  " .. table.concat(parts, "  "))
    end
    if G.UnitArmor then
        local base, eff = G.UnitArmor("player")
        add(format("UnitArmor(player) = %s / %s", tostring(base), tostring(eff)))
    end
    add(format("GetDodgeChance/Parry/Block = %s / %s / %s",
        tostring(G.GetDodgeChance and G.GetDodgeChance()),
        tostring(G.GetParryChance and G.GetParryChance()),
        tostring(G.GetBlockChance and G.GetBlockChance())))
    add(format("GearScore_GetScore 存在=%s  PGearScore 文本=%s",
        tostring(G.GearScore_GetScore ~= nil),
        tostring(Name2Frame("PGearScore") and Name2Frame("PGearScore"):GetText())))
    add(format("本插件算出的装等 = %s", tostring(ComputeItemLevel())))

    add("")
    add("--- 开关状态 ---")
    for k, v in pairs(DB()) do
        add(format("%-22s = %s", k, tostring(v)))
    end

    return table.concat(out, "\n")
end

local function ShowDump()
    local text = BuildDump()

    if not dumpBox then
        local box = CreateFrame("Frame", "McodeCharPanelFixDump", G.UIParent)
        box:SetSize(720, 460)
        box:SetPoint("CENTER")
        box:SetFrameStrata("DIALOG")
        box:EnableMouse(true)
        box:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        box:SetMovable(true)
        box:RegisterForDrag("LeftButton")
        box:SetScript("OnDragStart", box.StartMoving)
        box:SetScript("OnDragStop", box.StopMovingOrSizing)

        local title = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -14)
        title:SetText("HDClientFix_Mcode 自检输出 —— 点进框里 Ctrl+A 再 Ctrl+C 复制")

        local scroll = CreateFrame("ScrollFrame", "McodeCharPanelFixDumpScroll", box, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 16, -36)
        scroll:SetPoint("BOTTOMRIGHT", -34, 16)

        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(650)
        edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        edit:SetScript("OnMouseDown", function(self) self:SetFocus() end)
        scroll:SetScrollChild(edit)

        local close = CreateFrame("Button", nil, box, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -6, -6)

        box.edit = edit
        dumpBox = box
        tinsert(G.UISpecialFrames, "McodeCharPanelFixDump")
    end

    dumpBox.edit:SetText(text)
    dumpBox.edit:SetCursorPosition(0)
    dumpBox:Show()
    dumpBox.edit:SetFocus()
    dumpBox.edit:HighlightText()

    P("自检输出已生成，内容见弹窗（已全选，Ctrl+C 即可复制）。")
end

--------------------------------------------------------------------------
-- 斜杠命令
--------------------------------------------------------------------------

local function PrintHelp()
    P("组件开关：")
    local keys = {}
    for k in pairs(DEFAULTS) do keys[#keys + 1] = k end
    table.sort(keys)
    for i = 1, #keys do
        P(format("  %-22s %s", keys[i], DB()[keys[i]] and "|cff00ff00开|r" or "|cffff5555关|r"))
    end
    -- 面板类组件只在 ElvUI_Enhanced 的角色模块在场时才动手（见 CharModuleActive），
    -- 没装 ElvUI 的用户看到"全是开却没效果"，原因就在这一行
    P(format("ElvUI_Enhanced 角色模块：%s（不在场时本插件不执行任何修复）",
        CharModuleActive() and "|cff00ff00在场|r" or "|cffff5555不在场|r"))
    P("用法： |cffffff00/cpfix dump|r 自检 |cffffff00/cpfix on <组件>|r |cffffff00/cpfix off <组件>|r "
        .. "|cffffff00/cpfix reload|r")
end

local function SetComponent(name, value)
    if DEFAULTS[name] == nil then
        P("没有这个组件：" .. tostring(name))
        return
    end
    DB()[name] = value
    if name == "modelFeatures" and value then
        -- 重新应用一次，这样改完再 /reload 就会生效；同时也清掉"已提示过"
        DB().modelFeaturesApplied = nil
        ns.modelFeaturesAnnounced = nil
        ns.modelFeaturesChanged = nil
    end
    if name == "sidebar" or name == "clientTitleWidgets" or name == "tabAnchor" or name == "textFit" then
        -- 这两项关掉后需要把已经从可见状态改过的东西还原
        P(format("%s 已设为 %s，建议 /reload 一次以完全还原。", name, tostring(value)))
    end
    ApplyAll()
    P(format("%s = %s", name, tostring(value)))
end

SLASH_MCODECHARPANELFIX1 = "/cpfix"
SlashCmdList["MCODECHARPANELFIX"] = function(input)
    DB()
    input = gsub(input or "", "^%s*(.-)%s*$", "%1")
    local cmd, rest = strmatch(input, "^(%S*)%s*(.-)$")

    if cmd == "dump" then
        ShowDump()
    elseif cmd == "reload" then
        ApplyAll()
        P("已重新施加全部修复。")
    elseif cmd == "on" then
        SetComponent(rest, true)
    elseif cmd == "off" then
        SetComponent(rest, false)
    else
        PrintHelp()
    end
end

-- Shared settings use the existing component setters and dependency gates.
ns.CharacterDefaults = DEFAULTS
ns.CharacterSet = SetComponent
ns.CharacterApply = ApplyAll
ns.CharacterStatus = function()
    if not GetE() then return "未加载 ElvUI", false end
    if not GetCharModule() then return "未加载 ElvUI_Enhanced 角色面板模块", false end
    if not CharModuleActive() then return "ElvUI_Enhanced 角色面板模块未启用", false end
    return "依赖已就绪；按各项开关执行", true
end
ns.HasElvUI = function() return GetE() ~= nil end
ns.HasEnhanced = function() return GetCharModule() ~= nil end
