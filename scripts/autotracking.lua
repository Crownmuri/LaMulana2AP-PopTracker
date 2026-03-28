-- La-Mulana 2 AP PopTracker - Autotracking
-- scripts/autotracking.lua

ScriptHost:LoadScript("scripts/item_mapping.lua")
ScriptHost:LoadScript("scripts/location_mapping.lua")

local prog = {whip=0, shield=0, beherit=0}

function onItem(index, item_id, item_name, player)
    local item = ITEM_MAPPING[item_id]
    if not item or not item[1] then
        -- Not mapped (filler, weights, etc.) - ignore silently
        return
    end

    local code = item[1]
    local item_type = item[2]

    if item_type == "toggle" then
        local o = Tracker:FindObjectForCode(code)
        if o then o.Active = true end

    elseif item_type == "consumable" then
        local o = Tracker:FindObjectForCode(code)
        if o then o.AcquiredCount = o.AcquiredCount + 1 end

    elseif item_type == "progressive" then
        local o = Tracker:FindObjectForCode(code)
        if o then o.CurrentStage = o.CurrentStage + 1 end

    elseif item_type == "progressive_beherit" then
        prog.beherit = prog.beherit + 1
        local o = Tracker:FindObjectForCode(code)
        if o then o.AcquiredCount = prog.beherit end

    elseif item_type == "boss" then
        local o = Tracker:FindObjectForCode(code)
        if o then o.Active = true end

    elseif item_type == "guardian" then
        -- Guardian killed: set to dead stage
        -- bosses.json stages: [0]=FafnirA (ankh), [1]=Fafnir (dead)
        local o = Tracker:FindObjectForCode(code)
        if o then
            o.CurrentStage = 1  -- stage 1 = dead (Fafnir.png)
            o.Active = true
        end

    elseif item_type == "ankh" then
        -- Increment generic ankh jewel consumable count
        local o = Tracker:FindObjectForCode(code)
        if o then o.AcquiredCount = o.AcquiredCount + 1 end
        -- Show ankh on guardian icon if guardian-specific ankhs is ON
        -- bosses.json stages: [0]=FafnirA (ankh), [1]=Fafnir (dead)
        local guardian_code = item[3]
        if guardian_code then
            local setting = Tracker:FindObjectForCode("setting_guardian_ankhs")
            if setting and setting.Active then
                local boss = Tracker:FindObjectForCode(guardian_code)
                -- Only set ankh stage if guardian isn't already dead
                if boss and not (boss.Active and boss.CurrentStage == 1) then
                    boss.CurrentStage = 0  -- stage 0 = has ankh (FafnirA.png)
                    boss.Active = true     -- colored
                end
            end
        end
    end
end

function onLocation(location_id, location_name)
    local location_array = LOCATION_MAPPING[location_id]
    if not location_array or not location_array[1] then
        print(string.format("LM2: Unknown location ID %s (%s)", tostring(location_id), tostring(location_name)))
        return
    end
    for _, location in pairs(location_array) do
        local location_obj = Tracker:FindObjectForCode(location)
        if location_obj then
            if location:sub(1, 1) == "@" then
                location_obj.AvailableChestCount = location_obj.AvailableChestCount - 1
            else
                location_obj.Active = true
            end
        else
            print(string.format("LM2: Could not find object for code %s", location))
        end
    end
end

function onClear(slot_data)
    prog = {whip=0, shield=0, beherit=0}
    -- Reset guardian tracking state
    for _, g in ipairs(GUARDIANS) do
        _guardian_was_dead[g] = false
    end
end

Archipelago:AddItemHandler("*", onItem)
Archipelago:AddLocationHandler("*", onLocation)
Archipelago:AddClearHandler("", onClear)

-- ============================================================
-- Progressive Guardian State & Ankh Logic
-- Handles Ankh Jewel deduction and Stage skipping based on settings
--
-- bosses.json stages (progressive with allow_disabled):
--   Disabled (Active=false): grayed FafnirA
--   CurrentStage 0 (Active=true): colored FafnirA = has ankh
--   CurrentStage 1 (Active=true): colored Fafnir  = boss dead
-- ============================================================

GUARDIANS = {
    "fafnir", "kujata", "jormungand", "surtr", "vritra",
    "aten_ra", "anu", "echidna", "hel"
}

-- Track whether each guardian was previously dead (provides boss_X code)
_guardian_was_dead = {}
local _guardian_processing = false

for _, g in ipairs(GUARDIANS) do
    _guardian_was_dead[g] = false

    ScriptHost:AddWatchForCode("guardian_state_"..g, "guardian_"..g, function(code)
        if _guardian_processing then return end
        _guardian_processing = true

        local obj = Tracker:FindObjectForCode(code)
        if not obj then
            _guardian_processing = false
            return
        end

        local setting = Tracker:FindObjectForCode("setting_guardian_ankhs")
        local ankh_mode = setting and setting.Active

        -- When Guardian Ankhs is OFF, skip the ankh stage (CurrentStage 0)
        -- Jump directly between disabled and dead (CurrentStage 1)
        if not ankh_mode and obj.Active and obj.CurrentStage == 0 then
            if _guardian_was_dead[g] then
                -- Coming from dead (right-click backward): skip to disabled
                obj.Active = false
                obj.CurrentStage = 0
            else
                -- Coming from disabled (left-click forward): skip to dead
                obj.CurrentStage = 1
            end
        end

        -- Determine if guardian is now dead by checking the boss code
        local is_dead = has("boss_" .. g)
        local was_dead = _guardian_was_dead[g]

        -- Deduct or refund a generic ankh jewel on dead-state transitions
        if is_dead ~= was_dead then
            local ankh_jewel = Tracker:FindObjectForCode("ankh_jewel")
            if ankh_jewel then
                if is_dead and not was_dead and ankh_jewel.AcquiredCount > 0 then
                    ankh_jewel.AcquiredCount = ankh_jewel.AcquiredCount - 1
                elseif not is_dead and was_dead then
                    ankh_jewel.AcquiredCount = ankh_jewel.AcquiredCount + 1
                end
            end
            _guardian_was_dead[g] = is_dead
        end

        _guardian_processing = false
    end)
end

-- ============================================================
-- Go Mode: auto-toggle boss_ninth_child when Ninth Child is
-- logically reachable.  Uses lm2_logic() from logic.lua.
-- ============================================================

local GO_MODE_EXPR =
    "CanReach(SpiralHell) and "
    .. "CanChant(Heaven) and CanChant(Earth) and CanChant(Sun) and "
    .. "CanChant(Moon) and CanChant(Fire) and CanChant(Sea) and "
    .. "CanChant(Wind) and CanChant(Mother) and CanChant(Child) and "
    .. "CanChant(Night) and Dissonance(6) and Has(Grapple Claw) and "
    .. "Has(Feather) and Has(Flame Torc) and OrbCount(8) and "
    .. "(Has(Flail Whip) or Has(Axe))"

function UpdateGoMode()
    local result = lm2_logic(GO_MODE_EXPR)
    local obj = Tracker:FindObjectForCode("boss_ninth_child")
    if obj then
        obj.Active = (result == ACCESS_NORMAL)
    end
end

-- Codes whose changes can affect go mode reachability
local GO_MODE_WATCH_CODES = {
    -- Direct Ninth Child requirements
    "grapple_claw", "feather", "flame_torc", "sacred_orb",
    "whip1", "axe",
    -- Mantras + chanting
    "djed", "mantra_app",
    "mantra_heaven", "mantra_earth", "mantra_sun", "mantra_moon",
    "mantra_fire", "mantra_sea", "mantra_wind",
    "mantra_mother", "mantra_child", "mantra_night",
    -- Corridor / dissonance
    "beherit", "dissonance",
    -- Spiral Hell access path (IBBoat via HoM)
    "secret_treasure", "death_sigil", "earth_spear_ammo", "holy_grail",
    "boss_hom_ladder", "boss_hom_middle_path",
    "cog_of_antiquity", "life_sigil",
    -- Backside reachability
    "origin_sigil", "birth_sigil",
    -- Guardian kills (soul gates + GuardianKills)
    "guardian_fafnir", "guardian_vritra", "guardian_kujata",
    "guardian_aten_ra", "guardian_jormungand", "guardian_anu",
    "guardian_surtr", "guardian_echidna", "guardian_hel",
    -- Key movement items
    "gloves", "claydoll_suit", "ice_cloak", "anchor",
    -- Settings
    "setting_random_soul_gates", "setting_random_gates",
    "setting_not_life_for_hom", "setting_start",
}

for i, watch_code in ipairs(GO_MODE_WATCH_CODES) do
    ScriptHost:AddWatchForCode("go_mode_watch_" .. i, watch_code, function()
        UpdateGoMode()
    end)
end

print("LM2 AP Autotracking loaded!")