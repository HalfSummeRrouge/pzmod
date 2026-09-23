-- ============================================================
-- 模块名   : RM_Theme
-- 职责     : Vanilla-Native 主题令牌（配色/字体名/图标档位色），只数据
-- 所属里程碑: M1（图标位图为美术资产，另行处理）
-- 对外接口 : RM.Theme（只读表）
-- 依赖     : 无
-- ============================================================
RM = RM or {}
RM.Theme = {
    -- 纸感米色 + 深棕描边（对齐原版 moodle 视觉语言）
    colors = {
        paper       = { r = 0.910, g = 0.875, b = 0.784 },  -- 米色纸底
        ink         = { r = 0.231, g = 0.184, b = 0.118 },  -- 深棕描边/文字
        good        = { r = 0.420, g = 0.620, b = 0.380 },  -- 达标（绿）
        warn        = { r = 0.860, g = 0.650, b = 0.280 },  -- 注意（琥珀）
        bad         = { r = 0.780, g = 0.290, b = 0.240 },  -- 危险（砖红）
        excess      = { r = 0.520, g = 0.400, b = 0.740 },  -- 过量（紫）
        neutral     = { r = 0.600, g = 0.540, b = 0.460 },  -- 中性（灰棕）
        accent      = { r = 0.240, g = 0.480, b = 0.620 },  -- 强调（蓝）
    },
    fonts = {
        main  = "Medium SansNumbers",
        small = "Small",
        title = "Medium_NewKitosan",     -- TODO(S7): 确认 NeatUI 可用字体清单
    },
    -- 状态图标档位色（水合 4 档 / 能量 3 档）
    hydrationIcon = { normal = "good", thirsty = "warn", low = "bad", critical = "bad" },
    energyIcon    = { normal = "good", low = "warn", frozen = "bad" },
}
