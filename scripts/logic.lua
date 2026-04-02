-- La-Mulana 2 AP PopTracker - Logic
-- scripts/logic.lua

print("LM2 Logic: script loading...")

-- ============================================================
-- Accessibility constants (matching PopTracker/ALTTP)
-- ============================================================
ACCESS_NONE = 0
ACCESS_NORMAL = 6

-- ============================================================
-- Core helpers
-- ============================================================

function has(code)
    return Tracker:ProviderCountForCode(code) > 0
end

function count(code)
    local obj = Tracker:FindObjectForCode(code)
    if obj then
        if obj.Type == "consumable" then return obj.AcquiredCount
        elseif obj.Type == "progressive" then return obj.CurrentStage
        elseif obj.Type == "toggle" then return obj.Active and 1 or 0
        end
    end
    return 0
end

-- ============================================================
-- Has(item_name) - maps logic item names to tracker codes
-- ============================================================

HAS_OVERRIDES = {
    ["Leather Whip"]="whip1", ["Chain Whip"]="whip2", ["Flail Whip"]="whip3",
    ["Silver Shield"]="shield2", ["Angel Shield"]="shield3",
    ["Hand Scanner"]="scanner", ["Future Development Company"]="fdc",
    ["Fairy Pass"]="fairy_pass", ["Freyas Pendant"]="freyas_pendant",
    ["Freys Ship"]="freys_ship", ["Maats Feather"]="maats_feather",
    ["Ganesha Talisman"]="ganesha_talisman", ["Progressive Beherit"]="beherit",
    ["Ruins Encylopedia"]="encyclopedia", ["TextTrax 2"]="texttrax",
    ["Space Capstar II"]="space_capstar", ["Mobile Super x3+"]="mobile_super",
    ["Rose and Camelia"]="rose_camelia", ["Lonely House Moving"]="lonely_house",
    ["Mekuri Master"]="mekuri_master", ["Bounce Shot"]="bounce_shot",
    ["Miracle Witch"]="miracle_witch", ["La-Mulana"]="la_mulana",
    ["La-Mulana 2"]="la_mulana_2", ["Book of the Dead"]="book_of_dead",
    ["Secret Treasure of Life"]="secret_treasure", ["Beo Eg-Lana"]="beo_eglana",
    ["Fish Suit"]="claydoll_suit", ["Enga Musica"]="enga_musica",
    ["Cog of Antiquity"]="cog_of_antiquity", ["Egg of Creation"]="egg_of_creation",
    ["Giants Flute"]="giants_flute", ["Light Scythe"]="light_scythe",
    ["Mulana Talisman"]="mulana_talisman", ["Grapple Claw"]="grapple_claw",
    ["Pyramid Crystal"]="pyramid_crystal", ["Race Scanner"]="race_scanner",
    ["Death Village"]="death_village", ["Destiny Tablet"]="destiny_tablet",
    ["Dinosaur Figure"]="dinosaur_figure", ["Ice Cloak"]="ice_cloak",
    ["Nemean Fur"]="nemean_fur", ["Pochette Key"]="pochette_key",
    ["Power Band"]="power_band", ["Bronze Mirror"]="bronze_mirror",
    ["Skull Reader"]="skull_reader", ["Snow Shoes"]="snow_shoes",
    ["Totem Pole"]="totem_pole", ["Lamp of Time"]="lamp_of_time",
    ["Gale Fibula"]="gale_fibula", ["Flame Torc"]="flame_torc",
    ["Djed Pillar"]="djed", ["Claydoll Suit"]="claydoll_suit",
    ["Ancient Battery"]="battery", ["Shell Horn"]="shell_horn",
    ["Holy Grail"]="holy_grail", ["Origin Sigil"]="origin_sigil",
    ["Birth Sigil"]="birth_sigil", ["Life Sigil"]="life_sigil",
    ["Death Sigil"]="death_sigil", ["HoM Ladder"]="boss_hom_ladder",
    ["Key Fairy"]="boss_key_fairy", ["Weapon Fairy"]="boss_weapon_fairy",
    ["Money Fairy"]="boss_money_fairy",
    ["IB Left Shortcut"]="boss_ib_left_shortcut",
    ["Annwfn Right Shortcut"]="boss_annwfn_right_shortcut",
}

-- Map of guardian-specific ankh names to their tracker codes
ANKH_GUARDIAN_MAP = {
    ["Ankh Jewel (Fafnir)"] = "ankh_fafnir",
    ["Ankh Jewel (Vritra)"] = "ankh_vritra",
    ["Ankh Jewel (Kujata)"] = "ankh_kujata",
    ["Ankh Jewel (Aten-Ra)"] = "ankh_aten_ra",
    ["Ankh Jewel (Jormungand)"] = "ankh_jormungand",
    ["Ankh Jewel (Anu)"] = "ankh_anu",
    ["Ankh Jewel (Surtr)"] = "ankh_surtr",
    ["Ankh Jewel (Echidna)"] = "ankh_echidna",
    ["Ankh Jewel (Hel)"] = "ankh_hel",
}

local SUBWEAPONS = {
    ["shuriken"]=true, ["rolling_shuriken"]=true, ["earth_spear"]=true,
    ["flare"]=true, ["bomb"]=true, ["chakram"]=true, ["caltrops"]=true, ["pistol"]=true
}

function Has(item_name)
    local ankh_code = ANKH_GUARDIAN_MAP[item_name]
    if ankh_code then
        local setting = Tracker:FindObjectForCode("setting_guardian_ankhs")
        if setting and setting.Active then
            return has(ankh_code)
        else
            return count("ankh_jewel") >= 1
        end
    end

    -- DLC Item Logic: Fish Suit is owned from the start
    if item_name == "Fish Suit" then
        if has("setting_dlc_logic") then return true end
    end

    local code = HAS_OVERRIDES[item_name] or item_name:lower():gsub("%s+", "_")

    -- For subweapons, check if the progressive_toggle is Active
    -- (covers both weapon stage and ammo stage without being
    -- fooled by shop marks that also provide ammo codes)
    if SUBWEAPONS[code] then
        local obj = Tracker:FindObjectForCode(code)
        if obj then return obj.Active end
    end

    return has(code)
end

-- ============================================================
-- Logic functions
-- ============================================================

function CanWarp() return has("holy_grail") end
function CanChant(m) return has("djed") and has("mantra_app") and has("mantra_" .. string.lower(m)) end
function CanUse(weapon)
    local code = HAS_OVERRIDES[weapon] or weapon:lower():gsub("%s+", "_")

    if SUBWEAPONS[code] then
        -- Must have the weapon AND ammo to use it
        local obj = Tracker:FindObjectForCode(code)
        if not obj or not obj.Active then return false end
        local ammo_code = code .. "_ammo"
        if code == "pistol" then
            return has(ammo_code) and has("boss_money_fairy")
        end
        return has(ammo_code)
    end

    return has(code)
end

function OrbCount(n) return count("sacred_orb") >= n end
function SkullCount(n) return count("crystal_skull") >= n end
local GUARDIAN_CODES = {
    "boss_fafnir", "boss_vritra", "boss_kujata", "boss_aten_ra",
    "boss_jormungand", "boss_anu", "boss_surtr", "boss_echidna", "boss_hel"
}
function GuardianKills(n)
    local total = 0
    for _, code in ipairs(GUARDIAN_CODES) do
        if has(code) then
            total = total + 1
            if total >= n then return true end
        end
    end
    return false
end

-- Read required guardian/skull counts from settings
function RequiredGuardians()
    local obj = Tracker:FindObjectForCode("setting_req_guardians")
    if obj then return obj.CurrentStage end
    return 5
end
function RequiredSkulls()
    local obj = Tracker:FindObjectForCode("setting_req_skulls")
    if obj then return obj.CurrentStage end
    return 6
end

function MeleeAttack() return has("whip1") or has("knife") or has("rapier") or has("axe") or has("katana") end
function HorizontalAttack()
    return MeleeAttack() or CanUse("Shuriken") or CanUse("Rolling Shuriken")
        or CanUse("Earth Spear") or CanUse("Caltrops") or CanUse("Chakram")
        or CanUse("Bomb") or CanUse("Pistol") or has("claydoll_suit")
end
function CanStopTime() return has("lamp_of_time") end
function CanSpinCorridor() return count("beherit") >= 1 and Dissonance(1) end
function CanSealCorridor() return count("beherit") >= 1 and Dissonance(6) end
function Setting(name)
    -- HardBosses maps to the progressive logic setting (stage 1 = hard)
    if name == "HardBosses" then
        local obj = Tracker:FindObjectForCode("setting_logic")
        if obj then return obj.CurrentStage >= 1 end
        return false
    end
    local m = {
        ["AutoScan"]="setting_autoscan",
        ["CostumeClip"]="setting_costume_clip",
        ["Remove IT Statue"]="setting_remove_it_statue",
        ["Not Life for HoM"]="setting_not_life_for_hom",
    }
    return m[name] and has(m[name]) or false
end
function Glitch(name)
    if name == "Costume Clip" then return has("setting_costume_clip") end
    return false
end
function Dissonance(n) return count("dissonance") >= n or count("beherit") >= (n+1) end
function NibiruSkullCheck() return SkullCount(RequiredSkulls()) end

-- ============================================================
-- Starting Area Support
-- ============================================================

STARTING_AREA_IDS = {
    [0] = "VoD",
    [1] = "RoY",
    [2] = "AnnwfnMain",
    [3] = "IBMain",
    [4] = "ITLeft",
    [5] = "DFMain",
    [6] = "SotFGGrail",
    [7] = "TSLeft",
    [8] = "ValhallaMain",
    [9] = "DSLMMain",
    [10] = "ACTablet",
    [11] = "HoMTop"
}

function GetStartingAreaID()
    local obj = Tracker:FindObjectForCode("setting_start")
    local stage = 0
    if obj then stage = obj.CurrentStage end
    return STARTING_AREA_IDS[stage] or "VoD"
end

function NotVoDStart()
    return GetStartingAreaID() ~= "VoD"
end

function Start(area_name)
    local id = area_name:gsub("%s+", "")
    return id == GetStartingAreaID()
end

-- ============================================================
-- Expression Parser
-- ============================================================

LOGIC_FUNCS = {}

local function tokenize(expr)
    local tokens = {}
    local i = 1
    local len = #expr
    while i <= len do
        local c = expr:sub(i,i)
        if c:match("%s") then
            i = i + 1
        elseif c == "(" then
            table.insert(tokens, {type="LPAREN"})
            i = i + 1
        elseif c == ")" then
            table.insert(tokens, {type="RPAREN"})
            i = i + 1
        elseif c:match("[%a_]") then
            local wstart = i
            while i <= len and expr:sub(i,i):match("[%w_]") do i = i + 1 end
            local word = expr:sub(wstart, i-1)
            if word == "and" then
                table.insert(tokens, {type="AND"})
            elseif word == "or" then
                table.insert(tokens, {type="OR"})
            elseif word == "True" then
                table.insert(tokens, {type="BOOL", value=true})
            elseif word == "False" then
                table.insert(tokens, {type="BOOL", value=false})
            else
                local j = i
                while j <= len and expr:sub(j,j) == " " do j = j + 1 end
                if j <= len and expr:sub(j,j) == "(" then
                    j = j + 1
                    local depth = 1
                    local astart = j
                    while j <= len and depth > 0 do
                        if expr:sub(j,j) == "(" then depth = depth + 1 end
                        if expr:sub(j,j) == ")" then depth = depth - 1 end
                        if depth > 0 then j = j + 1 end
                    end
                    local arg = expr:sub(astart, j-1):match("^%s*(.-)%s*$")
                    i = j + 1
                    table.insert(tokens, {type="CALL", name=word, arg=arg})
                else
                    table.insert(tokens, {type="CALL", name=word, arg=nil})
                end
            end
        else
            i = i + 1
        end
    end
    return tokens
end

local parse_expr

local function parse_primary(tokens, pos)
    if pos > #tokens then return false, pos end
    local tok = tokens[pos]
    if tok.type == "BOOL" then
        return tok.value, pos + 1
    elseif tok.type == "CALL" then
        local fn = LOGIC_FUNCS[tok.name]
        if fn then
            if tok.arg ~= nil and tok.arg ~= "" then
                local num = tonumber(tok.arg)
                if num then return fn(num), pos + 1
                else return fn(tok.arg), pos + 1 end
            else
                return fn(), pos + 1
            end
        else
            print("LM2 Logic: unknown function: " .. tostring(tok.name))
            return false, pos + 1
        end
    elseif tok.type == "LPAREN" then
        local val, npos = parse_expr(tokens, pos + 1)
        if npos <= #tokens and tokens[npos].type == "RPAREN" then
            return val, npos + 1
        end
        return val, npos
    end
    return false, pos + 1
end

-- Advance past a primary token without evaluating function calls.
local function skip_primary(tokens, pos)
    if pos > #tokens then return pos end
    local tok = tokens[pos]
    if tok.type == "BOOL" or tok.type == "CALL" then
        return pos + 1
    elseif tok.type == "LPAREN" then
        local depth = 1
        local p = pos + 1
        while p <= #tokens and depth > 0 do
            local t = tokens[p].type
            if t == "LPAREN" then depth = depth + 1
            elseif t == "RPAREN" then depth = depth - 1 end
            p = p + 1
        end
        return p
    end
    return pos + 1
end

-- Advance past an entire AND sequence without evaluating.
local function skip_and(tokens, pos)
    pos = skip_primary(tokens, pos)
    while pos <= #tokens and tokens[pos].type == "AND" do
        pos = skip_primary(tokens, pos + 1)
    end
    return pos
end

local function parse_and(tokens, pos)
    local left, npos = parse_primary(tokens, pos)
    while npos <= #tokens and tokens[npos].type == "AND" do
        if not left then
            -- Short-circuit: left is false, skip remaining AND operands
            npos = skip_primary(tokens, npos + 1)
        else
            left, npos = parse_primary(tokens, npos + 1)
        end
    end
    return left, npos
end

local function parse_or(tokens, pos)
    local left, npos = parse_and(tokens, pos)
    while npos <= #tokens and tokens[npos].type == "OR" do
        if left then
            -- Short-circuit: left is true, skip remaining OR operands
            npos = skip_and(tokens, npos + 1)
        else
            left, npos = parse_and(tokens, npos + 1)
        end
    end
    return left, npos
end

parse_expr = parse_or

local function eval_logic_bool(expr)
    local ok, result = pcall(function()
        local tokens = tokenize(expr)
        if #tokens == 0 then return false end
        local val = parse_expr(tokens, 1)
        return val and true or false
    end)
    if ok then return result end
    return false
end

-- ============================================================
-- Auto-complete: IsDead / PuzzleFinished
-- Only the 9 guardians require manual tracking.
-- ============================================================

GUARDIAN_SET = {
    ["boss_fafnir"]=true, ["boss_vritra"]=true, ["boss_kujata"]=true,
    ["boss_aten_ra"]=true, ["boss_jormungand"]=true, ["boss_anu"]=true,
    ["boss_surtr"]=true, ["boss_echidna"]=true, ["boss_hel"]=true
}

local EVENT_LOGIC = {
    -- =================================================================
    -- Minibosses  (area reachability + fight logic from World.json)
    -- =================================================================

    -- Roots of Yggdrasil
    ["ratatoskr_1"] = "CanReach(RoY) and MeleeAttack",
    ["nidhogg"] = "CanReach(RoY) and MeleeAttack and (CanUse(Shuriken) or CanUse(Flare) or CanUse(Pistol) or Has(Claydoll Suit) or (CanUse(Chakram) and Has(Ring)))",

    -- Annwfn
    ["kaliya"] = "CanReach(AnnwfnMain) and CanUse(Rolling Shuriken)",
    ["heimdall"] = "CanReach(AnnwfnMain) and CanSealCorridor and CanChant(Night) and OrbCount(7) and Has(Silver Shield) and (Has(Flail Whip) or Has(Katana) or Has(Axe))",
    ["ixtab"] = "CanReach(AnnwfnRight) and (((Has(Leather Whip) or Has(Rapier) or CanUse(Rolling Shuriken) or CanUse(Caltrops)) and OrbCount(2)) or ((Has(Chain Whip) or Has(Axe) or Has(Katana) or Has(Claydoll Suit) or CanUse(Shuriken) or CanUse(Earth Spear) or CanUse(Chakram) or CanUse(Bomb)) and OrbCount(1)) or CanUse(Flare) or CanUse(Pistol))",

    -- Immortal Battlefield
    ["cetus"] = "CanReach(IBTop) and (CanUse(Earth Spear) or CanUse(Bomb) or CanUse(Rolling Shuriken) or CanUse(Caltrops) or Has(Claydoll Suit) or (CanUse(Flare) and (Has(Anchor) or Has(Fish Suit))) or ((CanUse(Shuriken) or CanUse(Chakram)) and Has(Scalesphere)) or (Has(Axe) and (Has(Scalesphere) or (OrbCount(1) and Has(Anchor)))) or (Has(Leather Whip) and Has(Anchor) and (Has(Scalesphere) or OrbCount(2))) or ((Has(Chain Whip) or Has(Katana)) and Has(Anchor) and (Has(Scalesphere) or OrbCount(1))))",
    ["ratatoskr_2"] = "CanReach(IBMain) and IsDead(Ratatoskr 1)",
    ["svipdagr"] = "CanReach(IBRight) and OrbCount(1)",

    -- Icefire Treetop
    ["vedfolnir"] = "CanReach(ITLeft) and OrbCount(1)",
    ["ratatoskr_3"] = "CanReach(ITRight) and IsDead(Ratatoskr 1) and IsDead(Ratatoskr 2) and CanReach(IT Left) and (((Has(Leather Whip) or CanUse(Rolling Shuriken) or CanUse(Caltrops)) and OrbCount(3)) or ((Has(Chain Whip) or Has(Knife) or Has(Rapier) or Has(Axe) or Has(Katana) or CanUse(Shuriken) or CanUse(Earth Spear) or CanUse(Flare) or CanUse(Bomb) or CanUse(Chakram)) and OrbCount(2)) or (CanUse(Pistol) and OrbCount(1)))",
    ["vidofnir"] = "CanReach(ITVidofnir) and Has(Flame Torc) and Has(Ice Cloak) and Has(Silver Shield) and ((Has(Chain Whip) and OrbCount(6)) or ((Has(Flail Whip) or Has(Axe) or Has(Katana)) and OrbCount(5)))",

    -- Divine Fortress
    ["hugin_and_munin"] = "CanReach(DFRight) and (CanWarp or Has(Origin Sigil))",

    -- Shrine of the Frost Giants
    ["badhbh_cath"] = "CanReach(SotFGMain) and (((Has(Leather Whip) or Has(Knife) or Has(Rapier) or CanUse(Earth Spear) or CanUse(Chakram)) and OrbCount(1)) or (Has(Chain Whip) or Has(Axe) or Has(Katana) or CanUse(Pistol) or CanUse(Bomb) or CanUse(Flare)))",
    ["fenrir"] = "CanReach(SotFGMain) and PuzzleFinished(Bergelmir) and Has(Flame Torc) and Has(Silver Shield) and OrbCount(7) and (Has(Flail Whip) or Has(Axe) or Has(Katana))",
    ["balor"] = "CanReach(SotFGBalor) and (((Has(Knife) or Has(Rapier) or Has(Katana)) and Has(Feather) and OrbCount(2)) or ((Has(Chain Whip) or Has(Axe) or CanUse(Flare) or CanUse(Earth Spear) or CanUse(Chakram) or CanUse(Bomb) or CanUse(Pistol)) and OrbCount(2)))",
    ["tezcatlipoca"] = "CanReach(SotFGBloodTez) and Has(Gloves) and OrbCount(1)",

    -- Gate of the Dead
    ["unicorn"] = "CanReach(GotD) and OrbCount(1) and ((Has(Katana) and Has(Vajra)) or Has(Leather Whip) or Has(Axe) or CanUse(Rolling Shuriken) or CanUse(Earth Spear) or CanUse(Flare) or CanUse(Bomb) or CanUse(Chakram) or CanUse(Pistol))",

    -- Takamagahara Shrine
    ["raijin_and_fujin"] = "CanReach(TSMain) and Has(Mjolnir) and OrbCount(1)",
    ["daji"] = "CanReach(TSBottom) and OrbCount(2) and ((Has(Chain Whip) and (Has(Gauntlet) or Has(Spaulder))) or (Has(Knife) and Has(Spaulder) and Has(Feather)) or (Has(Rapier) and Has(Gauntlet) and Has(Spaulder) and Has(Feather)) or Has(Flail Whip) or Has(Axe) or Has(Katana) or (CanUse(Pistol) and Has(Feather)) or (CanUse(Rolling Shuriken) and Has(Ring) and Has(Feather)) or (CanUse(Chakram) and (Has(Ring) or Has(Feather))) or CanUse(Bomb) or CanUse(Flare) or ((CanUse(Earth Spear) or CanUse(Caltrops)) and Has(Ring)))",
    ["belial"] = "CanReach(TSBlood) and Has(Life Sigil) and Has(Cog of Antiquity) and (Has(Claydoll Suit) or (Has(Ice Cloak) and OrbCount(6))) and ((Has(Egg of Creation) and OrbCount(6) and (Has(Claydoll Suit) or CanUse(Pistol) or CanUse(Earth Spear) or (CanUse(Rolling Shuriken) and Has(Ring)) or (Has(Katana) and Has(Feather)))) or (CanStopTime and OrbCount(3) and ((Has(Axe) and (Has(Gauntlet) or Has(Spaulder))) or (Has(Katana) and (Has(Vajra) or Has(Spaulder))) or (Has(Rapier) and Has(Vajra)) or (Has(Knife) and (Has(Vajra) or Has(Spaulder))) or (Has(Chain Whip) and (Has(Vajra) or Has(Gauntlet) or Has(Spaulder))))))",

    -- Heavens Labyrinth
    ["arachne"] = "CanReach(HLSpun) and CanWarp",
    ["scylla"] = "CanReach(HLSpun) and CanWarp",
    ["glasya_labolas"] = "CanReach(HLSpun) and CanWarp and OrbCount(1) and ((Has(Rapier) and (Has(Spaulder) or Has(Gauntlet) or Has(Vajra))) or Has(Chain Whip) or Has(Knife) or Has(Axe) or Has(Katana) or CanUse(Pistol) or CanUse(Chakram) or CanUse(Earth Spear) or CanUse(Bomb))",
    ["griffin"] = "CanReach(HLSpun) and (Has(Gale Fibula) or CanStopTime) and Has(Gloves) and Has(Life Sigil) and IsDead(Glasya Labolas) and OrbCount(2)",

    -- Valhalla
    ["vucub_caquiz"] = "CanReach(ValhallaMain) and Has(Origin Sigil) and (((Has(Leather Whip) or CanUse(Rolling Shuriken)) and OrbCount(1)) or (Has(Chain Whip) or Has(Rapier) or Has(Axe) or Has(Katana) or Has(Claydoll Suit) or CanUse(Pistol) or CanUse(Shuriken) or CanUse(Earth Spear) or CanUse(Caltrops) or CanUse(Bomb)))",
    ["jalandhara"] = "CanReach(ValhallaMain) and Has(Life Sigil) and Has(Feather) and OrbCount(4) and (Has(Chain Whip) or Has(Axe) or Has(Katana) or CanUse(Earth Spear) or CanUse(Bomb) or CanUse(Chakram) or (CanUse(Pistol) and Has(Mjolnir)))",

    -- Dark Star Lords Mausoleum
    ["sekhmet"] = "CanReach(DSLMMain) and CanChant(Heaven) and CanChant(Sun) and CanChant(Earth) and OrbCount(3) and (Has(Chain Whip) or Has(Rapier) or Has(Axe) or Has(Katana) or CanUse(Earth Spear) or CanUse(Bomb) or CanUse(Chakram) or CanUse(Pistol))",
    ["angra_mainyu"] = "CanReach(DSLMTop) and Has(Mjolnir) and OrbCount(1) and (CanWarp or Has(Feather) or CanReach(DSLM Main))",
    ["ammit"] = "CanReach(DSLMTop) and Has(Feather) and Has(Pyramid Crystal) and Has(Silver Shield) and OrbCount(3) and (Has(Chain Whip) or Has(Knife) or Has(Axe) or Has(Katana) or CanUse(Earth Spear) or CanUse(Bomb) or CanUse(Chakram) or CanUse(Pistol))",

    -- Ancient Chaos
    ["ki_sikil_lil_la_ke"] = "CanReach(ACBottom) and OrbCount(2) and (Has(Leather Whip) or Has(Axe) or Has(Katana) or Has(Claydoll Suit) or CanUse(Shuriken) or CanUse(Earth Spear) or CanUse(Bomb) or CanUse(Chakram) or CanUse(Pistol))",
    ["anzu"] = "CanReach(ACMain) and CanStopTime and Has(Claydoll Suit) and Has(Silver Shield) and OrbCount(6) and (Has(Chain Whip) or Has(Axe) or Has(Katana) or CanUse(Earth Spear) or CanUse(Bomb) or CanUse(Chakram) or CanUse(Pistol))",

    -- Hall of Malice
    ["hom_left_path"] = "CanReach(HoMAwoken) and Has(Silver Shield) and ((Has(Chain Whip) and OrbCount(7)) or ((Has(Axe) or Has(Katana)) and OrbCount(6)) or (Has(Flail Whip) and OrbCount(5)))",
    ["hom_middle_path"] = "CanReach(HoMAwoken) and ((Has(Silver Shield) and Has(Feather)) or Has(Angel Shield)) and ((Has(Chain Whip) and OrbCount(7)) or ((Has(Flail Whip) or Has(Axe) or Has(Katana)) and OrbCount(6)))",
    ["hom_right_path"] = "CanReach(HoMAwoken) and Has(Silver Shield) and ((Has(Chain Whip) and OrbCount(7)) or ((Has(Flail Whip) or Has(Axe) or Has(Katana)) and OrbCount(6)))",

    -- Eternal Prison
    ["hraesvelgr"] = "CanReach(EPDMain) and IsDead(Ratatoskr 1) and IsDead(Ratatoskr 2) and IsDead(Ratatoskr 3) and IsDead(Ratatoskr 4) and IsDead(Nidhogg) and CanChant(Moon) and Has(Feather)",
    ["ratatoskr_4"] = "CanReach(EPG) and Has(Enga Musica) and Has(Feather) and IsDead(Ratatoskr 3) and (((Has(Chain Whip) or Has(Axe)) and OrbCount(7)) or ((Has(Flail Whip) or Has(Katana)) and OrbCount(6)) or (CanUse(Pistol) and OrbCount(5)))",

    -- =================================================================
    -- Puzzles
    -- =================================================================
    ["annwfn_right_shortcut"] = "CanReach(AnnwfnRight) and IsDead(Ixtab)",
    ["bergelmir"] = "CanReach(SotFGLeft) and CanChant(Earth) and CanChant(Moon) and CanChant(Heaven)",
    ["white_pedestals"] = "CanReach(GotD) and Has(Pepper) and Has(Birth Sigil) and CanChant(Sun) and IsDead(Unicorn)",
    ["hom_ladder"] = "CanReach(HoMTop)",
    ["garm_statue_puzzle"] = "CanReach(EPG) and Has(Enga Musica) and Has(Feather) and CanChant(Fire) and CanChant(Earth) and CanChant(Sun)",
    ["sakit_puzzle"] = "CanReach(EPG) and ((Has(Enga Musica) and IsDead(Vidofnir)) or Glitch(Costume Clip)) and Has(Feather) and Has(Giants Flute) and Has(Vessel) and Has(Hand Scanner) and CanChant(Moon) and CanChant(Mother) and CanChant(Child) and IsDead(Fenrir)",
}

function IsDead(boss)
    local boss_key = string.lower(boss):gsub("%s+","_"):gsub("'","")
    local code = "boss_" .. boss_key
    
    -- 1. Check if it's a main Guardian (manual tracking)
    if GUARDIAN_SET[code] then
        return has(code)
    end
    
    -- 2. If it's a Miniboss, evaluate its specific logic string automatically
    if EVENT_LOGIC[boss_key] then
        return eval_logic_bool(EVENT_LOGIC[boss_key])
    end
    
    -- 3. Fallback (warn about missing entries, default to true)
    print("LM2 Logic WARNING: no EVENT_LOGIC for boss '" .. boss_key .. "' - defaulting to true")
    return true
end

function PuzzleFinished(p)
    local puzzle_key = string.lower(p):gsub("%s+","_"):gsub("'","")
    
    if EVENT_LOGIC[puzzle_key] then
        return eval_logic_bool(EVENT_LOGIC[puzzle_key])
    end
    
    return true
end

function CanKill(boss)
    local code = "boss_" .. string.lower(boss):gsub("%s+","_"):gsub("'","")
    if GUARDIAN_SET[code] then
        return IsDead(boss) or MeleeAttack() or HorizontalAttack()
    end
    return true
end

-- ============================================================
-- Guardian Ankh Check
-- ============================================================

GUARDIAN_ANKH_NAMES = {
    ["Fafnir"] = "Ankh Jewel (Fafnir)",
    ["Vritra"] = "Ankh Jewel (Vritra)",
    ["Kujata"] = "Ankh Jewel (Kujata)",
    ["Aten Ra"] = "Ankh Jewel (Aten-Ra)",
    ["Jormungand"] = "Ankh Jewel (Jormungand)",
    ["Anu"] = "Ankh Jewel (Anu)",
    ["Surtr"] = "Ankh Jewel (Surtr)",
    ["Echidna"] = "Ankh Jewel (Echidna)",
    ["Hel"] = "Ankh Jewel (Hel)",
}

function HasAnkhFor(guardian_name)
    local ankh_item = GUARDIAN_ANKH_NAMES[guardian_name]
    if ankh_item then
        return Has(ankh_item)
    end
    return count("ankh_jewel") >= 1
end

-- ============================================================
-- Region Graph (forward: area -> exits)
-- ============================================================

FORWARD_EXITS = {
    ["ACBlood"] = {{"TSBlood", "Has(Feather) and (GuardianKills(5) or Setting(Random Soul Gates))"}, {"ACMain", "Glitch(Costume Clip) and CanWarp"}, {"DSLMTop", "CanSpinCorridor"}, {"HoM", "CanWarp or CanSpinCorridor"}, {"EPDEntrance", "CanSpinCorridor and CanChant(Sun) and CanChant(Moon) and CanChant(Sea) and CanWarp"}},
    ["ACBottom"] = {{"ACTablet", "IsDead(Ki sikil lil la ke)"}, {"ACWind", "Has(Grapple Claw)"}, {"TSBottom", "True"}},
    ["ACMain"] = {{"ACTablet", "True"}, {"ACWind", "True"}, {"ACBlood", "CanUse(Bomb)"}},
    ["ACTablet"] = {{"ACMain", "True"}},
    ["ACWind"] = {{"ACMain", "Has(Feather)"}, {"ACBottom", "True"}},
    ["AltarLeft"] = {{"IBMain", "False"}, {"AltarRight", "CanWarp"}},
    ["AltarRight"] = {{"IBMain", "True"}},
    ["AnnwfnMain"] = {{"RoYBottomLeft", "True"}, {"AnnwfnSG", "Has(Gloves) or Has(Feather)"}, {"AnnwfnRight", "Has(Annwfn Right Shortcut)"}, {"IBBifrost", "True"}},
    ["AnnwfnOneWay"] = {{"AnnwfnMain", "CanWarp and HorizontalAttack"}, {"IBCetusLadder", "False"}},
    ["AnnwfnPoison"] = {{"RoYTopLeft", "False"}, {"AnnwfnRight", "CanUse(Rolling Shuriken) or Has(Claydoll Suit) or CanStopTime"}},
    ["AnnwfnRight"] = {{"AnnwfnMain", "IsDead(Ixtab)"}, {"AnnwfnPoison", "True"}},
    ["AnnwfnSG"] = {{"AnnwfnMain", "Has(Gloves) or Has(Feather) or CanWarp"}, {"SotFGMain", "(GuardianKills(2) or Setting(Random Soul Gates)) and Has(Origin Sigil)"}},
    ["Cavern"] = {{"IBRight", "True"}, {"Cliff", "True"}},
    ["Cliff"] = {{"Cavern", "False"}},
    ["DFEntrance"] = {{"DFRight", "CanUse(Shuriken) or CanUse(Chakram) or Has(Claydoll Suit) or CanUse(Pistol)"}, {"RoYMiddle", "GuardianKills(1) or Setting(Random Soul Gates)"}},
    ["DFMain"] = {{"DFTop", "Has(Feather) or Has(Grapple Claw)"}, {"DFRight", "Has(Leather Whip) or Has(Rapier) or Has(Katana) or CanUse(Shuriken) or CanUse(Rolling Shuriken) or CanUse(Earth Spear) or CanUse(Chakram) or CanUse(Bomb) or CanUse(Caltrops) or CanUse(Pistol) or Has(Claydoll Suit)"}, {"ValhallaMain", "True"}},
    ["DFRight"] = {{"DFMain", "CanUse(Shuriken) or CanUse(Chakram) or Has(Claydoll Suit) or CanUse(Pistol) or (CanUse(Earth Spear) and Has(Ring))"}, {"DFEntrance", "True"}},
    ["DFTop"] = {{"DFMain", "True"}, {"DFRight", "True"}},
    ["DSLMMain"] = {{"DSLMTop", "Has(Feather)"}, {"DSLMPyramid", "Has(Grapple Claw) and Has(Mjolnir)"}, {"GotDWedjet", "False"}},
    ["DSLMPyramid"] = {{"Nibiru", "Has(Pyramid Crystal) and Has(Destiny Tablet) and CanChant(Heaven) and CanChant(Moon) and CanChant(Fire) and CanChant(Sea) and CanChant(Sun)"}},
    ["DSLMTop"] = {{"DSLMMain", "Has(Feather) or CanWarp"}, {"ValhallaMain", "CanWarp or CanSpinCorridor"}, {"SotFGBlood", "CanSpinCorridor"}, {"ACBlood", "CanSpinCorridor"}, {"HoM", "CanSpinCorridor"}, {"EPDEntrance", "CanSpinCorridor and CanChant(Sun) and CanChant(Moon) and CanChant(Sea) and CanWarp"}},
    ["EPDEntrance"] = {{"EPDMain", "True"}, {"ACBlood", "CanSpinCorridor"}, {"HoM", "CanSpinCorridor"}},
    ["EPDMain"] = {{"EPDEntrance", "IsDead(Hraesvelgr) and Has(Feather)"}, {"EPDTop", "Has(Feather) and Has(Gloves)"}, {"EPG", "Has(Grapple Claw) and (Has(Gale Fibula) or CanStopTime) and (Has(Claydoll Suit) or (Has(Ice Cloak) and OrbCount(1) and Has(Anchor)))"}, {"DFTop", "True"}, {"VoD", "True"}, {"ITRight", "True"}, {"TSBottom", "True"}},
    ["EPDTop"] = {{"EPDHel", "((IsDead(Vidofnir) and GuardianKills(5)) or Setting(Random Soul Gates)) and IsDead(Hraesvelgr) and PuzzleFinished(Garm Statue Puzzle) and CanUse(Bomb) and Has(Holy Grail) and Has(Grapple Claw) and Has(Gale Fibula) and Has(Claydoll Suit) and Has(Gloves) and Has(Anchor) and Has(Feather) and (Has(Hand Scanner) or Setting(AutoScan))"}},
    ["EPG"] = {{"EPDMain", "(Has(Claydoll Suit) or (Has(Ice Cloak) and OrbCount(1)) or Has(Grapple Claw)) and Has(Feather)"}, {"EPDTop", "Has(Death Sigil) and (Has(Feather) or ((Has(Hand Scanner) or Setting(AutoScan)) and Has(Future Development Company) and CanWarp))"}, {"ITVidofnir", "GuardianKills(5) or Setting(Random Soul Gates)"}, {"DFTop", "True"}, {"VoD", "True"}, {"ITRight", "True"}, {"TSBottom", "True"}},
    ["EndlessCorridor"] = {{"MausoleumofGiantsRubble", "True"}},
    ["GateofGuidance"] = {{"VoD", "True"}, {"MausoleumofGiants", "True"}},
    ["GateofGuidanceLeft"] = {{"GateofIllusion", "True"}, {"GateofGuidance", "CanReach(Mausoleum of Giants)"}},
    ["GateofIllusion"] = {{"RoYMiddle", "HorizontalAttack"}, {"GateofGuidanceLeft", "True"}},
    ["GotD"] = {{"IBMain", "GuardianKills(2) or Setting(Random Soul Gates)"}, {"GotDWedjet", "True"}},
    ["GotDWedjet"] = {{"DSLMMain", "PuzzleFinished(White Pedestals)"}, {"GotD", "CanWarp or (Has(Pepper) and Has(Birth Sigil) and CanChant(Sun) and CanKill(Unicorn))"}},
    ["HL"] = {{"HLSpun", "CanChant(Heaven)"}, {"ITRight", "GuardianKills(3) or Setting(Random Soul Gates)"}},
    ["HLCog"] = {{"TSNeckEntrance", "False"}},
    ["HLGate"] = {{"HL", "CanWarp"}, {"HoMTop", "(Has(Feather) or Has(Grapple Claw)) and IsDead(Griffin) and IsDead(Arachne) and IsDead(Scylla)"}},
    ["HLSpun"] = {{"HLGate", "True"}},
    ["HoM"] = {{"HoMTop", "Has(HoM Ladder)"}, {"ACBlood", "CanSpinCorridor"}, {"SotFGBlood", "CanSpinCorridor"}, {"EPDEntrance", "CanSpinCorridor and CanChant(Sun) and CanChant(Moon) and CanChant(Sea) and CanWarp"}, {"IBBoat", "Has(Death Sigil) and CanUse(Earth Spear) and (CanWarp or IsDead(HoM Middle Path)) and (GuardianKills(9) or Setting(Random Soul Gates))"}},
    ["HoMTop"] = {{"HoMAwoken", "Has(Cog of Antiquity) and (Has(Life Sigil) or Setting(Not Life for HoM))"}, {"HoM", "True"}, {"HL", "False"}},
    ["IBBattery"] = {{"IBDinosaur", "Has(Grapple Claw)"}, {"ITRight", "True"}},
    ["IBBifrost"] = {{"IBTop", "CanWarp or (CanKill(Cetus) and Setting(Non Random Ladders))"}, {"AnnwfnMain", "False"}},
    ["IBBoat"] = {{"HoM", "False"}, {"SpiralHell", "CanSealCorridor and Has(Secret Treasure of Life) and CanChant(Mother) and CanChant(Child)"}},
    ["IBBottom"] = {{"IBMain", "HorizontalAttack"}, {"IBLadder", "IsDead(Cetus)"}, {"IBLeft", "Has(IB Left Shortcut)"}},
    ["IBCetusLadder"] = {{"AnnwfnOneWay", "True"}, {"IBTop", "CanWarp or CanKill(Cetus) or CanReach(IBMain)"}},
    ["IBDinosaur"] = {{"IBBattery", "Has(Grapple Claw) or (Glitch(Costume Clip) and CanWarp)"}, {"IBMoon", "Glitch(Costume Clip) and Has(Feather) and CanWarp"}},
    ["IBLadder"] = {{"ITLeft", "True"}},
    ["IBLeft"] = {{"RoYTopRight", "False"}, {"IBBottom", "CanWarp or Has(Birth Sigil)"}, {"IBLeftSG", "CanWarp or Has(Birth Sigil)"}},
    ["IBLeftSG"] = {{"TSEntrance", "GuardianKills(3) or Setting(Random Soul Gates)"}, {"IBBottom", "True"}},
    ["IBMain"] = {{"IBTopLeft", "True"}, {"IBRight", "True"}, {"IBDinosaur", "(Has(Anchor) or Has(Fish Suit) or Has(Claydoll Suit)) and (IsDead(Cetus) or Has(Feather) or CanWarp)"}, {"IBBottom", "True"}, {"GotD", "(GuardianKills(2) or Setting(Random Soul Gates)) and HorizontalAttack"}, {"AltarLeft", "Has(Dinosaur Figure)"}, {"AltarRight", "Has(Dinosaur Figure)"}},
    ["IBMoon"] = {{"IBDinosaur", "Has(Life Sigil) and (CanWarp or (Has(Grapple Claw) and Setting(Non Random Ladders)))"}, {"ITRightLeftLadder", "False"}},
    ["IBRight"] = {{"IBMain", "Has(Feather) or Has(Grapple Claw)"}, {"Cavern", "True"}},
    ["IBTop"] = {{"IBTopLeft", "CanWarp or ((Has(Feather) or Has(Gloves)) and (CanUse(Earth Spear) or CanUse(Chakram) or CanUse(Bomb) or CanUse(Rolling Shuriken) or CanUse(Caltrops)))"}, {"IBMain", "IsDead(Cetus)"}, {"IBCetusLadder", "IsDead(Cetus)"}},
    ["IBTopLeft"] = {{"IBTop", "(Has(Feather) and (CanUse(Earth Spear) or CanUse(Chakram) or CanUse(Bomb) or CanUse(Rolling Shuriken) or CanUse(Caltrops))) or (Has(Gloves) and (CanUse(Earth Spear) or CanUse(Chakram) or CanUse(Bomb) or CanUse(Rolling Shuriken) or CanUse(Caltrops)))"}, {"IBMain", "Glitch(Costume Clip)"}},
    ["ITBottom"] = {{"ITSinmara", "True"}, {"ITRight", "Has(Feather) or (Has(Gale Fibula) and (Has(Leather Whip) or Has(Axe) or CanUse(Shuriken) or CanUse(Bomb) or CanUse(Earth Spear) or CanUse(Flare) or (CanUse(Chakram) and Has(Ring))))"}, {"ITVidofnir", "CanChant(Moon) and CanChant(Sun) and CanWarp"}},
    ["ITEntrance"] = {{"RoYTopMiddle", "False"}, {"ITBottom", "CanWarp or Has(Claydoll Suit) or Has(Ice Cloak) or OrbCount(2) or (Has(Feather) and Has(Grapple Claw))"}, {"ITSinmara", "Has(Claydoll Suit) or Has(Ice Cloak) or OrbCount(2)"}, {"ITRight", "Has(Grapple Claw) and (CanWarp or Has(Feather) or CanReach(ITSinmara))"}},
    ["ITLeft"] = {{"ITSinmara", "HorizontalAttack"}, {"ITEntrance", "Glitch(Costume Clip) and (Has(Claydoll Suit) or Has(Ice Cloak) or OrbCount(2) or CanWarp)"}, {"IBLadder", "True"}},
    ["ITRight"] = {{"ITBottom", "CanWarp or Has(Feather) or (Has(Gale Fibula) and (Has(Leather Whip) or Has(Axe) or CanUse(Shuriken) or CanUse(Bomb) or CanUse(Earth Spear) or CanUse(Flare) or (CanUse(Chakram) and Has(Ring))))"}, {"ITEntrance", "Has(Feather) and Has(Grapple Claw)"}, {"ITRightLeftLadder", "Has(Life Sigil)"}, {"IBBattery", "True"}, {"HL", "(Has(Anchor) or Has(Fish Suit) or Has(Claydoll Suit)) and IsDead(Ratatoskr 3) and (GuardianKills(3) or Setting(Random Soul Gates))"}},
    ["ITRightLeftLadder"] = {{"IBMoon", "True"}},
    ["ITSinmara"] = {{"ITEntrance", "Setting(Remove IT Statue) and (Has(Claydoll Suit) or Has(Ice Cloak) or OrbCount(2))"}, {"ITBottom", "HorizontalAttack"}, {"ITLeft", "True"}},
    ["ITVidofnir"] = {{"EPG", "IsDead(Vidofnir) and (GuardianKills(5) and CanWarp)"}},
    ["InfernoCavern"] = {{"VoD", "False"}},
    ["MausoleumofGiants"] = {{"GateofGuidance", "True"}, {"GateofGuidanceLeft", "True"}, {"MausoleumofGiantsRubble", "True"}},
    ["MausoleumofGiantsRubble"] = {{"EndlessCorridor", "CanReach(Annwfn Main)"}, {"MausoleumofGiants", "CanWarp or CanReach(AnnwfnMain)"}},
    ["Nibiru"] = {{"DSLMPyramid", "False"}},
    ["RoY"] = {{"RoYTopLeft", "IsDead(Ratatoskr 1)"}, {"RoYTopMiddle", "IsDead(Nidhogg)"}, {"RoYTopRight", "Has(Feather) or Has(Grapple Claw)"}, {"RoYMiddle", "True"}, {"RoYBottom", "True"}},
    ["RoYBottom"] = {{"DFEntrance", "GuardianKills(1)"}, {"RoYMiddle", "True"}, {"RoYBottomLeft", "Has(Origin Sigil)"}},
    ["RoYBottomLeft"] = {{"AnnwfnMain", "True"}},
    ["RoYMiddle"] = {{"GateofIllusion", "False"}, {"RoY", "HorizontalAttack"}},
    ["RoYTopLeft"] = {{"AnnwfnPoison", "CanUse(Rolling Shuriken) or CanUse(Earth Spear) or CanUse(Caltrops) or CanUse(Bomb)"}},
    ["RoYTopMiddle"] = {{"ITEntrance", "True"}, {"RoY", "CanWarp or CanKill(Nidhogg)"}},
    ["RoYTopRight"] = {{"IBLeft", "Has(Birth Sigil)"}, {"RoY", "CanWarp or Has(Birth Sigil)"}},
    ["SotFGBalor"] = {{"ValhallaTopRight", "Has(Claydoll Suit) and (GuardianKills(5)) and IsDead(Balor)"}},
    ["SotFGBlood"] = {{"SotFGBloodTez", "True"}, {"ACBlood", "CanWarp or CanSpinCorridor"}, {"HoM", "CanSpinCorridor"}, {"DSLMTop", "CanSpinCorridor"}, {"ValhallaMain", "CanSpinCorridor"}, {"EPDEntrance", "CanSpinCorridor and CanChant(Sun) and CanChant(Moon) and CanChant(Sea) and CanWarp"}},
    ["SotFGBloodTez"] = {{"SotFGLeft", "Has(Grapple Claw) and IsDead(Tezcatlipoca)"}, {"SotFGBlood", "CanKill(Tezcatlipoca) and (CanWarp or Has(Grapple Claw))"}},
    ["SotFGGrail"] = {{"SotFGMain", "HorizontalAttack or Start(SotFGGrail)"}},
    ["SotFGLeft"] = {{"SotFGMain", "True"}, {"SotFGGrail", "CanWarp or HorizontalAttack"}, {"SotFGBloodTez", "False"}},
    ["SotFGMain"] = {{"AnnwfnSG", "GuardianKills(2)"}, {"SotFGGrail", "CanWarp or HorizontalAttack"}, {"SotFGTop", "IsDead(Badhbh Cath) and Has(Grapple Claw) and HorizontalAttack"}, {"SotFGLeft", "Start(SotFGGrail)"}},
    ["SotFGTop"] = {{"SotFGBalor", "Has(Feather) and PuzzleFinished(Bergelmir)"}},
    ["Start"] = {{"VoD", "True"}},
    ["TSBlood"] = {{"ACBlood", "GuardianKills(5)"}},
    ["TSBottom"] = {{"TSMain", "True"}, {"ACBottom", "True"}},
    ["TSEntrance"] = {{"TSLeft", "Has(Katana) or CanUse(Earth Spear) or CanUse(Bomb)"}, {"TSMain", "Has(Knife) or Has(Katana) or Has(Rapier) or Has(Axe) or CanUse(Rolling Shuriken) or CanUse(Earth Spear) or CanUse(Caltrops) or CanUse(Bomb) or (Has(Leather Whip) and (Has(Spaulder) or Has(Vajra)))"}, {"IBLeftSG", "GuardianKills(3) or Setting(Random Soul Gates)"}},
    ["TSLeft"] = {{"TSMain", "True"}},
    ["TSMain"] = {{"TSBottom", "Has(Katana) or CanUse(Earth Spear) or CanUse(Bomb) or Start(TSLeft)"}, {"TSNeck", "IsDead(Raijin and Fujin)"}, {"TSEntrance", "Has(Leather Whip) or Has(Axe) or CanUse(Earth Spear) or (Has(Katana) and Has(Vajra)) or (CanUse(Flare) and HorizontalAttack)"}},
    ["TSNeck"] = {{"TSMain", "CanKill(Raijin and Fujin) or (CanStopTime and CanWarp)"}, {"TSNeckEntrance", "True"}},
    ["TSNeckEntrance"] = {{"TSNeck", "CanWarp or (CanChant(Heaven) and CanChant(Earth) and CanChant(Sea) and CanChant(Fire) and CanChant(Wind))"}, {"HLCog", "CanChant(Earth) and CanChant(Wind) and CanChant(Fire) and CanChant(Sea) and CanChant(Heaven) and CanWarp"}},
    ["ValhallaMain"] = {{"ValhallaTop", "Has(Feather) or CanChant(Heaven)"}, {"DFMain", "True"}, {"SotFGBlood", "CanWarp or CanSpinCorridor or (CanReach(SotFG Main) and CanKill(Tezcatlipoca) and Setting(Non Random Gates))"}, {"ACBlood", "CanSpinCorridor"}, {"HoM", "CanSpinCorridor"}, {"DSLMTop", "CanSpinCorridor"}, {"EPDEntrance", "CanSpinCorridor and CanChant(Sun) and CanChant(Moon) and CanChant(Sea) and CanWarp"}},
    ["ValhallaTop"] = {{"ValhallaMain", "True"}},
    ["ValhallaTopRight"] = {{"ValhallaTop", "Has(Feather)"}, {"ValhallaMain", "CanWarp or Has(Feather) or (Has(Claydoll Suit) and CanChant(Heaven))"}, {"SotFGBalor", "Has(Claydoll Suit) and (GuardianKills(5) or Setting(Random Soul Gates))"}},
    ["VoD"] = {{"GateofGuidance", "True"}, {"Start", "True"}, {"VoDLadder", "Has(Feather)"}},
    ["VoDLadder"] = {{"InfernoCavern", "Has(Feather)"}}
}

-- ============================================================
-- Iterative Flood-Fill CanReach
-- Computes all reachable areas from starting area in one pass.
-- Cached and invalidated when tracker state changes.
-- ============================================================

local _computing = false
local _current_reachable = {}
local _reach_valid = false

local function _flood_fill_reachable()
    local start_id = GetStartingAreaID()
    _current_reachable = {[start_id] = true}

    -- Iterative fixed-point: keep expanding until no new areas found
    local changed = true
    local iterations = 0
    while changed and iterations < 20 do
        changed = false
        iterations = iterations + 1
        for area_id, exits in pairs(FORWARD_EXITS) do
            if _current_reachable[area_id] then
                for _, edge in ipairs(exits) do
                    local target = edge[1]
                    local logic = edge[2]
                    if not _current_reachable[target] and eval_logic_bool(logic) then
                        _current_reachable[target] = true
                        changed = true
                    end
                end
            end
        end
    end
    _reach_valid = true
    return _current_reachable
end

function CanReach(area_name)
    local id = area_name:gsub("%s+", "")

    -- During flood-fill, use the in-progress reachable set
    if _computing then
        return _current_reachable[id] == true
    end

    -- If already computed this evaluation cycle, reuse
    if _reach_valid then
        return _current_reachable[id] == true
    end

    -- Compute fresh
    _computing = true
    _flood_fill_reachable()
    _computing = false

    return _current_reachable[id] == true
end

-- ============================================================
-- Populate LOGIC_FUNCS
-- ============================================================

LOGIC_FUNCS = {
    Has=Has, IsDead=IsDead, PuzzleFinished=PuzzleFinished, CanWarp=CanWarp,
    CanChant=CanChant, CanUse=CanUse, CanReach=CanReach, CanStopTime=CanStopTime,
    CanSpinCorridor=CanSpinCorridor, CanSealCorridor=CanSealCorridor, CanKill=CanKill,
    MeleeAttack=MeleeAttack, HorizontalAttack=HorizontalAttack,
    OrbCount=OrbCount, SkullCount=SkullCount, GuardianKills=GuardianKills,
    Setting=Setting, Glitch=Glitch, Dissonance=Dissonance, Start=Start,
    NotVoDStart=NotVoDStart, HasAnkhFor=HasAnkhFor,
    NibiruSkullCheck=NibiruSkullCheck,
}

-- ============================================================
-- lm2_logic(expression) - entry point
-- ============================================================

function lm2_logic(expression)
    -- Invalidate reachability cache for each fresh evaluation
    _reach_valid = false

    local ok, result = pcall(function()
        local tokens = tokenize(expression)
        if #tokens == 0 then return ACCESS_NONE end
        local val = parse_expr(tokens, 1)
        if val then return ACCESS_NORMAL else return ACCESS_NONE end
    end)
    if ok then
        return result
    else
        print("LM2 Logic error: " .. tostring(result) .. " in: " .. expression)
        return ACCESS_NONE
    end
end

print("LM2 Logic: loaded with flood-fill CanReach + starting area + auto-complete!")
print("LM2 Logic: Starting area: " .. GetStartingAreaID())