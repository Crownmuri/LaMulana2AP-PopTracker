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

-- Reverse lookup: section path → shop mark code (populated after SHOP_MARK_TO_SECTIONS)
local SECTION_TO_SHOP_MARK = {}

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
                -- If this is a shop slot, activate the shop memo icon
                local sm_code = SECTION_TO_SHOP_MARK[location]
                if sm_code then
                    local mark = Tracker:FindObjectForCode(sm_code)
                    if mark then
                        mark.Active = true
                    end
                end
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
    "setting_not_life_for_hom", "setting_start",
}

for i, watch_code in ipairs(GO_MODE_WATCH_CODES) do
    ScriptHost:AddWatchForCode("go_mode_watch_" .. i, watch_code, function()
        UpdateGoMode()
    end)
end

-- ============================================================
-- Beherit Image: swap icon at count thresholds
-- ============================================================

ScriptHost:AddWatchForCode("beherit_image", "beherit", function()
    local obj = Tracker:FindObjectForCode("beherit")
    if not obj then return end
    local c = obj.AcquiredCount
    if c >= 7 then
        obj.Icon = ImageReference:FromPackRelativePath("images/UseItems/Beherit3.png")
    elseif c >= 2 then
        obj.Icon = ImageReference:FromPackRelativePath("images/UseItems/Beherit2.png")
    else
        obj.Icon = ImageReference:FromPackRelativePath("images/UseItems/Beherit1.png")
    end
end)

-- ============================================================
-- Shop Mark → Subweapon Sync  (DISABLED — too expensive on reconnect)
-- When a shop is marked with ammo, flip the subweapon's
-- progressive_toggle to the ammo stage (stage 1).
-- ============================================================

-- local SHOP_MARK_PREFIXES = {
--     {"nebur",3}, {"modro",3}, {"sidro",3}, {"hiner",4},
--     {"korobock",3}, {"shuhoka",3}, {"pym",3}, {"btk",3},
--     {"mino",3}, {"bargainduck",3}, {"venum",3}, {"peibalusa",3},
--     {"hiro",3}, {"hydlit",3}, {"aytum",3}, {"kero",3},
--     {"ashgeen",3}, {"fairylan",3}, {"megarock",3}, {"startshop",3}
-- }
--
-- local SHOP_MARK_CODES = {}
-- for _, info in ipairs(SHOP_MARK_PREFIXES) do
--     for slot = 1, info[2] do
--         table.insert(SHOP_MARK_CODES, "sm_" .. info[1] .. "_" .. slot)
--     end
-- end
--
-- -- shop_marks.json stage index → subweapon code
-- -- Stage 0: question_mark, 1: Weight, 2-9: ammo, 10: Item
-- local SHOP_STAGE_TO_WEAPON = {
--     [2] = "shuriken", [3] = "rolling_shuriken", [4] = "earth_spear",
--     [5] = "flare", [6] = "bomb", [7] = "chakram",
--     [8] = "caltrops", [9] = "pistol"
-- }
--
-- local _shop_sync_processing = false
--
-- function UpdateSubweaponsFromShops()
--     if _shop_sync_processing then return end
--     _shop_sync_processing = true
--
--     -- Collect which ammo types are marked in any active (confirmed) shop mark
--     local ammo_marked = {}
--     for _, sm_code in ipairs(SHOP_MARK_CODES) do
--         local obj = Tracker:FindObjectForCode(sm_code)
--         if obj and obj.Active then
--             local weapon = SHOP_STAGE_TO_WEAPON[obj.CurrentStage]
--             if weapon then ammo_marked[weapon] = true end
--         end
--     end
--     -- Set subweapon progressive_toggle to ammo stage only when
--     -- the weapon is already found (Active) AND a shop has the ammo marked
--     for _, weapon_code in pairs(SHOP_STAGE_TO_WEAPON) do
--         local obj = Tracker:FindObjectForCode(weapon_code)
--         if obj and obj.Active and ammo_marked[weapon_code] then
--             if obj.CurrentStage ~= 1 then
--                 obj.CurrentStage = 1
--             end
--         end
--     end
--
--     _shop_sync_processing = false
-- end

-- ============================================================
-- Shop Mark → Section Check Sync
-- When a shop location is checked via AP, set hosted item to
-- sm_item icon.  (Subweapon sync watches removed for perf.)
-- ============================================================

local SHOP_MARK_TO_SECTIONS = {
    ["sm_nebur_1"] = {"@La-Mulana/Nebur/Shop Slot 1"},
    ["sm_nebur_2"] = {"@La-Mulana/Nebur/Shop Slot 2"},
    ["sm_nebur_3"] = {"@La-Mulana/Nebur/Shop Slot 3"},
    ["sm_modro_1"] = {"@La-Mulana/Modro/Shop Slot 1"},
    ["sm_modro_2"] = {"@La-Mulana/Modro/Shop Slot 2"},
    ["sm_modro_3"] = {"@La-Mulana/Modro/Shop Slot 3"},
    ["sm_sidro_1"] = {"@La-Mulana/Sidro/Shop Slot 1"},
    ["sm_sidro_2"] = {"@La-Mulana/Sidro/Shop Slot 2"},
    ["sm_sidro_3"] = {"@La-Mulana/Sidro/Shop Slot 3"},
    ["sm_hiner_1"] = {"@La-Mulana/Hiner/Shop Slot 1"},
    ["sm_hiner_2"] = {"@La-Mulana/Hiner/Shop Slot 2"},
    ["sm_hiner_3"] = {"@La-Mulana/Hiner/Shop Slot 3"},
    ["sm_hiner_4"] = {"@La-Mulana/Hiner/Shop Slot 4"},
    ["sm_korobock_1"] = {"@Roots of Yggdrasil/Korobock/Shop Slot 1"},
    ["sm_korobock_2"] = {"@Roots of Yggdrasil/Korobock/Shop Slot 2"},
    ["sm_korobock_3"] = {"@Roots of Yggdrasil/Korobock/Shop Slot 3"},
    ["sm_shuhoka_1"] = {"@Divine Fortress/Shuhoka/Shop Slot 1"},
    ["sm_shuhoka_2"] = {"@Divine Fortress/Shuhoka/Shop Slot 2"},
    ["sm_shuhoka_3"] = {"@Divine Fortress/Shuhoka/Shop Slot 3"},
    ["sm_pym_1"] = {"@Annwfn/Pym/Shop Slot 1"},
    ["sm_pym_2"] = {"@Annwfn/Pym/Shop Slot 2"},
    ["sm_pym_3"] = {"@Annwfn/Pym/Shop Slot 3"},
    ["sm_btk_1"] = {"@Icefire Treetop/BTK/Shop Slot 1"},
    ["sm_btk_2"] = {"@Icefire Treetop/BTK/Shop Slot 2"},
    ["sm_btk_3"] = {"@Icefire Treetop/BTK/Shop Slot 3"},
    ["sm_mino_1"] = {"@Icefire Treetop/Mino the Bomb Guy/Shop Slot 1"},
    ["sm_mino_2"] = {"@Icefire Treetop/Mino the Bomb Guy/Shop Slot 2"},
    ["sm_mino_3"] = {"@Icefire Treetop/Mino the Bomb Guy/Shop Slot 3"},
    ["sm_bargainduck_1"] = {"@Valhalla/Bargain Duck/Shop Slot 1"},
    ["sm_bargainduck_2"] = {"@Valhalla/Bargain Duck/Shop Slot 2"},
    ["sm_bargainduck_3"] = {"@Valhalla/Bargain Duck/Shop Slot 3"},
    ["sm_venum_1"] = {"@Ancient Chaos/Venum/Shop Slot 1"},
    ["sm_venum_2"] = {"@Ancient Chaos/Venum/Shop Slot 2"},
    ["sm_venum_3"] = {"@Ancient Chaos/Venum/Shop Slot 3"},
    ["sm_peibalusa_1"] = {"@Immortal Battlefield/Peibalusa/Shop Slot 1"},
    ["sm_peibalusa_2"] = {"@Immortal Battlefield/Peibalusa/Shop Slot 2"},
    ["sm_peibalusa_3"] = {"@Immortal Battlefield/Peibalusa/Shop Slot 3"},
    ["sm_hiro_1"] = {"@Immortal Battlefield/Hiro Roderick/Shop Slot 1"},
    ["sm_hiro_2"] = {"@Immortal Battlefield/Hiro Roderick/Shop Slot 2"},
    ["sm_hiro_3"] = {"@Immortal Battlefield/Hiro Roderick/Shop Slot 3"},
    ["sm_hydlit_1"] = {"@Shrine of the Frost Giants/Hydlit/Shop Slot 1"},
    ["sm_hydlit_2"] = {"@Shrine of the Frost Giants/Hydlit/Shop Slot 2"},
    ["sm_hydlit_3"] = {"@Shrine of the Frost Giants/Hydlit/Shop Slot 3"},
    ["sm_aytum_1"] = {"@Gate of the Dead/Aytum/Shop Slot 1"},
    ["sm_aytum_2"] = {"@Gate of the Dead/Aytum/Shop Slot 2"},
    ["sm_aytum_3"] = {"@Gate of the Dead/Aytum/Shop Slot 3"},
    ["sm_kero_1"] = {"@Dark Star Lords Mausoleum/Kero/Shop Slot 1"},
    ["sm_kero_2"] = {"@Dark Star Lords Mausoleum/Kero/Shop Slot 2"},
    ["sm_kero_3"] = {"@Dark Star Lords Mausoleum/Kero/Shop Slot 3"},
    ["sm_ashgeen_1"] = {"@Takamagahara Shrine/Ash Geen/Shop Slot 1"},
    ["sm_ashgeen_2"] = {"@Takamagahara Shrine/Ash Geen/Shop Slot 2"},
    ["sm_ashgeen_3"] = {"@Takamagahara Shrine/Ash Geen/Shop Slot 3"},
    ["sm_fairylan_1"] = {"@Hall of Malice/Fairylan/Shop Slot 1"},
    ["sm_fairylan_2"] = {"@Hall of Malice/Fairylan/Shop Slot 2"},
    ["sm_fairylan_3"] = {"@Hall of Malice/Fairylan/Shop Slot 3"},
    ["sm_megarock_1"] = {"@Heavens Labyrinth/Megarock/Shop Slot 1"},
    ["sm_megarock_2"] = {"@Heavens Labyrinth/Megarock/Shop Slot 2"},
    ["sm_megarock_3"] = {"@Heavens Labyrinth/Megarock/Shop Slot 3"},
    ["sm_startshop_1"] = {
        "@Starting Shop RoY/Shop Slot 1", "@Starting Shop Ann/Shop Slot 1",
        "@Starting Shop IB/Shop Slot 1", "@Starting Shop IT/Shop Slot 1",
        "@Starting Shop DF/Shop Slot 1", "@Starting Shop SFG/Shop Slot 1",
        "@Starting Shop TS/Shop Slot 1", "@Starting Shop Val/Shop Slot 1",
        "@Starting Shop DSLM/Shop Slot 1", "@Starting Shop AC/Shop Slot 1",
        "@Starting Shop HoM/Shop Slot 1"
    },
    ["sm_startshop_2"] = {
        "@Starting Shop RoY/Shop Slot 2", "@Starting Shop Ann/Shop Slot 2",
        "@Starting Shop IB/Shop Slot 2", "@Starting Shop IT/Shop Slot 2",
        "@Starting Shop DF/Shop Slot 2", "@Starting Shop SFG/Shop Slot 2",
        "@Starting Shop TS/Shop Slot 2", "@Starting Shop Val/Shop Slot 2",
        "@Starting Shop DSLM/Shop Slot 2", "@Starting Shop AC/Shop Slot 2",
        "@Starting Shop HoM/Shop Slot 2"
    },
    ["sm_startshop_3"] = {
        "@Starting Shop RoY/Shop Slot 3", "@Starting Shop Ann/Shop Slot 3",
        "@Starting Shop IB/Shop Slot 3", "@Starting Shop IT/Shop Slot 3",
        "@Starting Shop DF/Shop Slot 3", "@Starting Shop SFG/Shop Slot 3",
        "@Starting Shop TS/Shop Slot 3", "@Starting Shop Val/Shop Slot 3",
        "@Starting Shop DSLM/Shop Slot 3", "@Starting Shop AC/Shop Slot 3",
        "@Starting Shop HoM/Shop Slot 3"
    },
}

-- Populate reverse mapping for onLocation autotracking
for sm_code, section_paths in pairs(SHOP_MARK_TO_SECTIONS) do
    for _, path in ipairs(section_paths) do
        SECTION_TO_SHOP_MARK[path] = sm_code
    end
end

-- Shop mark watches disabled for performance.
-- The onLocation handler (above) still sets shop marks to sm_item stage
-- when AP reports a shop location as checked, so the hosted-item icon
-- updates correctly without any watches.

-- for sm_code, section_paths in pairs(SHOP_MARK_TO_SECTIONS) do
--     ScriptHost:AddWatchForCode("shop_watch_" .. sm_code, sm_code, function()
--         local mark = Tracker:FindObjectForCode(sm_code)
--         if not mark then return end
--         if mark.Active and mark.CurrentStage > 0 then
--             for _, path in ipairs(section_paths) do
--                 local section = Tracker:FindObjectForCode(path)
--                 if section and section.AvailableChestCount > 0 then
--                     section.AvailableChestCount = 0
--                 end
--             end
--         end
--         UpdateSubweaponsFromShops()
--     end)
-- end
--
-- for _, weapon_code in pairs(SHOP_STAGE_TO_WEAPON) do
--     ScriptHost:AddWatchForCode("weapon_sync_" .. weapon_code, weapon_code, UpdateSubweaponsFromShops)
-- end

print("LM2 AP Autotracking loaded!")