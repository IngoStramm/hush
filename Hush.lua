local ADDON_NAME = ...
local LOCALE = GetLocale and GetLocale() or "enUS"

local L = {
    ADDON_NAME = "Hush",
    ADDON_LONG = "Hide Unwanted Screen HUD",
    LOADED = "loaded. Use /hush help.",
    ENABLED = "Hush enabled.",
    DISABLED = "Hush disabled.",
    XP_ON = "XP bar hidden.",
    XP_OFF = "XP bar visible.",
    REP_ON = "Reputation bar hidden.",
    REP_OFF = "Reputation bar visible.",
    RESET = "Settings reset.",
    STATUS = "Status:",
    ON = "on",
    OFF = "off",
    HELP_HEADER = "Hush commands:",
    HELP_TOGGLE = "/hush - show status",
    HELP_ON = "/hush on - enable hiding",
    HELP_OFF = "/hush off - disable hiding",
    HELP_XP = "/hush xp - toggle XP bar hiding",
    HELP_REP = "/hush rep - toggle reputation bar hiding",
    HELP_RESET = "/hush reset - reset settings",
}

if LOCALE == "ptBR" then
    L = {
        ADDON_NAME = "Hush",
        ADDON_LONG = "Hide Unwanted Screen HUD",
        LOADED = "carregado. Use /hush help.",
        ENABLED = "Hush ativado.",
        DISABLED = "Hush desativado.",
        XP_ON = "Barra de XP oculta.",
        XP_OFF = "Barra de XP visivel.",
        REP_ON = "Barra de reputacao oculta.",
        REP_OFF = "Barra de reputacao visivel.",
        RESET = "Configuracao resetada.",
        STATUS = "Status:",
        ON = "ligado",
        OFF = "desligado",
        HELP_HEADER = "Comandos do Hush:",
        HELP_TOGGLE = "/hush - mostra o status",
        HELP_ON = "/hush on - ativa ocultacao",
        HELP_OFF = "/hush off - desativa ocultacao",
        HELP_XP = "/hush xp - alterna ocultacao da barra de XP",
        HELP_REP = "/hush rep - alterna ocultacao da barra de reputacao",
        HELP_RESET = "/hush reset - reseta a configuracao",
    }
end

local DEFAULTS = {
    enabled = true,
    hideXP = true,
    hideReputation = true,
}

local TARGETS = {
    xp = {
        setting = "hideXP",
        frames = {
            "MainStatusTrackingBarContainer",
            "MainMenuExpBar",
            "MainMenuBarMaxLevelBar",
            "ExhaustionTick",
            "ExhaustionLevelFillBar",
            "MainMenuBarExpText",
        },
    },
    reputation = {
        setting = "hideReputation",
        frames = {
            "MainStatusTrackingBarContainer",
            "SecondaryStatusTrackingBarContainer",
            "StatusTrackingBarManager",
            "ReputationWatchBar",
            "ReputationWatchStatusBar",
            "ReputationWatchBar.StatusBar",
        },
    },
}

local managedFrames = {}
local frameToTargets = {}
for key, target in pairs(TARGETS) do
    for _, frameName in ipairs(target.frames) do
        if not frameToTargets[frameName] then
            table.insert(managedFrames, frameName)
            frameToTargets[frameName] = {}
        end

        table.insert(frameToTargets[frameName], key)
    end
end

local db
local eventFrame = CreateFrame("Frame", "HushFrame")
local hookedFrames = {}
local hiddenByHush = {}

local function CopyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                CopyDefaults(target[key], value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            CopyDefaults(target[key], value)
        end
    end
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff" .. L.ADDON_NAME .. ":|r " .. message)
end

local function GetFrame(frameName)
    local object = _G
    for segment in string.gmatch(frameName, "[^%.]+") do
        object = object and object[segment]
    end
    return object
end

local function IsManagedFrameObject(object)
    return object and type(object.Hide) == "function" and type(object.Show) == "function"
end

local function ShouldHideTarget(targetKey)
    local target = TARGETS[targetKey]
    return db and target and db.enabled and db[target.setting]
end

local function ShouldHideFrame(frameName)
    local targetKeys = frameToTargets[frameName]
    if not targetKeys then
        return false
    end

    for _, targetKey in ipairs(targetKeys) do
        if ShouldHideTarget(targetKey) then
            return true
        end
    end

    return false
end

local function HookFrame(frameName, object)
    if hookedFrames[frameName] or not IsManagedFrameObject(object) then
        return
    end

    hookedFrames[frameName] = true

    if type(object.HookScript) == "function" then
        object:HookScript("OnShow", function(self)
            if ShouldHideFrame(frameName) then
                hiddenByHush[frameName] = true
                self:Hide()
            end
        end)
    end
end

local function ApplyFrame(frameName)
    local object = GetFrame(frameName)
    if not IsManagedFrameObject(object) then
        return
    end

    HookFrame(frameName, object)

    if ShouldHideFrame(frameName) then
        hiddenByHush[frameName] = true
        object:Hide()
    elseif hiddenByHush[frameName] then
        hiddenByHush[frameName] = nil
        object:Show()
    end
end

local function ApplyAll()
    if not db then
        return
    end

    for _, frameName in ipairs(managedFrames) do
        ApplyFrame(frameName)
    end
end

local function ScheduleApply()
    ApplyAll()

    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, ApplyAll)
        C_Timer.After(1, ApplyAll)
    end
end

local function PrintStatus()
    local enabled = db.enabled and L.ON or L.OFF
    local xp = db.hideXP and L.ON or L.OFF
    local reputation = db.hideReputation and L.ON or L.OFF

    Print(string.format("%s Hush=%s, XP=%s, Rep=%s", L.STATUS, enabled, xp, reputation))
end

local function PrintHelp()
    Print(L.HELP_HEADER)
    Print(L.HELP_TOGGLE)
    Print(L.HELP_ON)
    Print(L.HELP_OFF)
    Print(L.HELP_XP)
    Print(L.HELP_REP)
    Print(L.HELP_RESET)
end

local function ResetSettings()
    HushDB = {}
    CopyDefaults(HushDB, DEFAULTS)
    db = HushDB
    Print(L.RESET)
    ScheduleApply()
end

local function HandleSlash(message)
    message = string.lower((message or ""):match("^%s*(.-)%s*$"))

    if message == "" or message == "status" then
        PrintStatus()
    elseif message == "help" or message == "ajuda" then
        PrintHelp()
    elseif message == "on" or message == "ligar" then
        db.enabled = true
        Print(L.ENABLED)
        ScheduleApply()
    elseif message == "off" or message == "desligar" then
        db.enabled = false
        Print(L.DISABLED)
        ScheduleApply()
    elseif message == "xp" then
        db.hideXP = not db.hideXP
        Print(db.hideXP and L.XP_ON or L.XP_OFF)
        ScheduleApply()
    elseif message == "rep" or message == "reputation" or message == "reputacao" then
        db.hideReputation = not db.hideReputation
        Print(db.hideReputation and L.REP_ON or L.REP_OFF)
        ScheduleApply()
    elseif message == "reset" then
        ResetSettings()
    else
        PrintHelp()
    end
end

local function Initialize()
    HushDB = HushDB or {}
    CopyDefaults(HushDB, DEFAULTS)
    db = HushDB

    SLASH_HUSH1 = "/hush"
    SlashCmdList.HUSH = HandleSlash

    Print(L.LOADED)
    ScheduleApply()
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("UPDATE_EXHAUSTION")
eventFrame:RegisterEvent("UPDATE_FACTION")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        Initialize()
    else
        ScheduleApply()
    end
end)
