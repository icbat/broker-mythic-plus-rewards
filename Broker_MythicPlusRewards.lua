-------------
--- View Code
-------------

-- these are all defaulted and set after world load to avoid timing issues
local green_cutoff = 99999
local purple_cutoff = 99999
local highest_run = 0
local highest_vault = 0

local function color_cell(self, col, level)
    if level >= purple_cutoff then
        self:SetCellTextColor(self:GetLineCount(), col, 1, 0.5, 0, 1)
        return
    end

    if level < purple_cutoff and level > highest_run then
        self:SetCellTextColor(self:GetLineCount(), col, 0.64, 0.21, 0.93, 1)
        return
    end


    if level == highest_run then
        self:SetCellTextColor(self:GetLineCount(), col, 0.00, 0.44, 0.87, 1)
        return
    end

    if level > green_cutoff then
        self:SetCellTextColor(self:GetLineCount(), col, 0.12, 1, 0, 1)
        return
    end
end

local function build_tooltip(self)
    self:AddHeader("Key", "Run", "Vault")
    self:AddSeparator()

    local my_key_level = C_MythicPlus.GetOwnedKeystoneLevel()

    if my_key_level == nil then
        my_key_level = 0
    end

    for key_level = 1, 15, 1 do
        local vault_level, run_level = C_MythicPlus.GetRewardLevelForDifficultyLevel(key_level)
        self:AddLine(key_level, run_level, vault_level)
        color_cell(self, 2, run_level)
        color_cell(self, 3, vault_level)

        if my_key_level == key_level then
            self:SetCellColor(self:GetLineCount(), 1, 0, 1, 0, 0.5)
        end
    end
    if  my_key_level > 15 then
        self:SetCellColor(self:GetLineCount(), 1, 0, 1, 0, 0.5)
    end
end

--------------------
--- Wiring/LDB/QTip
--------------------

local ADDON, namespace = ...
local LibQTip = LibStub('LibQTip-1.0')
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:NewDataObject(ADDON, {
    type = "data source",
    text = "Mythic Plus Rewards"
})

local function OnRelease(self)
    LibQTip:Release(self.tooltip)
    self.tooltip = nil
end

local function anchor_OnEnter(self)
    if self.tooltip then
        LibQTip:Release(self.tooltip)
        self.tooltip = nil
    end

    local tooltip = LibQTip:Acquire(ADDON, 3, "CENTER", "CENTER", "CENTER")
    self.tooltip = tooltip
    tooltip.OnRelease = OnRelease
    tooltip.OnLeave = OnLeave
    tooltip:SetAutoHideDelay(.1, self)

    build_tooltip(tooltip)

    tooltip:SmartAnchorTo(self)

    tooltip:Show()
end

function dataobj:OnEnter()
    anchor_OnEnter(self)
end

--- Nothing to do. Needs to be defined for some display addons apparently
function dataobj:OnLeave()
end

--- there's some slight timing issues where the C_MythicPlus functions might return nil, so this is to safely wait for those to load first
local function figure_out_colors()
    local _, lowest_run = C_MythicPlus.GetRewardLevelForDifficultyLevel(1)
    highest_vault, highest_run = C_MythicPlus.GetRewardLevelForDifficultyLevel(15)
    green_cutoff = (highest_run - lowest_run) / 2 + lowest_run
    purple_cutoff = (highest_vault - highest_run) * 2 / 3 + highest_run
end

-- invisible frame for updating/hooking events
local f = CreateFrame("frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", figure_out_colors)
