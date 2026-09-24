-- ============================================================
-- 模块名   : RM_Theme
-- 职责     : 现代化深色主题令牌（配色/字体名/图标档位色），只数据
-- 对外接口 : RM.Theme（只读表）
-- 依赖     : 无
-- ============================================================
RM = RM or {}
RM.Theme = {
    colors = {
        -- 面板
        panelBg     = { r = 0.090, g = 0.100, b = 0.120 },  -- 深灰蓝底
        panelBorder = { r = 0.220, g = 0.240, b = 0.280 },  -- 边框
        titleBar    = { r = 0.130, g = 0.150, b = 0.180 },  -- 标题栏
        sectionText = { r = 0.550, g = 0.600, b = 0.680 },  -- 分区标题（灰蓝）
        text        = { r = 0.900, g = 0.920, b = 0.950 },  -- 主文字
        subText     = { r = 0.600, g = 0.640, b = 0.700 },  -- 次要文字
        barBg       = { r = 0.160, g = 0.180, b = 0.210 },  -- 进度条背景
        -- 档位
        good        = { r = 0.340, g = 0.720, b = 0.470 },  -- 达标（青绿）
        warn        = { r = 0.920, g = 0.680, b = 0.250 },  -- 注意（琥珀）
        bad         = { r = 0.900, g = 0.320, b = 0.320 },  -- 危险（红）
        excess      = { r = 0.620, g = 0.450, b = 0.850 },  -- 过量（紫）
        neutral     = { r = 0.500, g = 0.550, b = 0.600 },  -- 中性
        accent      = { r = 0.350, g = 0.680, b = 0.820 },  -- 强调（青蓝）
    },
    fonts = {
        main  = "Medium SansNumbers",
        small = "Small",
        title = "Medium_NewKitosan",
    },
    -- 状态图标档位色
    hydrationIcon = { normal = "good", thirsty = "warn", low = "bad", critical = "bad" },
    energyIcon    = { normal = "good", low = "warn", frozen = "bad" },
}
