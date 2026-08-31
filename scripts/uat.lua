-- ============================================================
-- UAT Autotracking (offline / no-Archipelago play)
--
-- Drives the exact same tracker state as scripts/autotracking.lua, but from a
-- UAT server hosted by the game mod in offline mode instead of an AP room.
-- Every apply-side function here lives in autotracking.lua and is shared with
-- the AP path; this file is only the adapter that turns UAT variables into
-- calls to them.
--
-- WHY THE SHAPES DIFFER
-- AP hands the tracker an *event stream*: onItem fires once per received item,
-- onLocation once per check, and both are replayed in order on connect. UAT is
-- a *key/value store* -- the server answers Sync with a full dump of every
-- variable and then pushes each one again whenever it changes. So the mod
-- publishes cumulative state and this adapter works out the delta. Reconnects
-- are lossless for free, which the AP path has to reach through replay.
--
-- ID SPACE
-- Variables carry raw game IDs (the LocationID / ItemID enums the mod and
-- seed.lm2r speak), not AP IDs. ITEM_MAPPING / LOCATION_MAPPING are keyed by
-- AP IDs, so the bases below are added on the way in. slot_data is the one
-- exception: it is already game-space on both backends (starting_weapon is an
-- ItemID, item_placements are LocationID/ItemID), so it passes through as-is.
--
-- VARIABLE CONTRACT -- what the mod must publish
--   slot_data         object  same shape as the apworld's fill_slot_data(),
--                             i.e. SeedToSlotData's dict. Per-pool potsanity /
--                             glossanity toggles are read from .options.
--   items             array   game ItemIDs held, repeated per copy for
--                             stacking items (2 Ankh Jewels = the id twice).
--                             Order must be stable and append-only.
--   locations         array   game LocationIDs checked, any order.
--   guardian_kills    array   LocationID enum names as strings, matching
--                             GUARDIAN_KILL_DS_NAMES ("Fafnir", "Vritra", ...).
--   dissonance_count  number  cumulative natural dissonances absorbed. Ignored
--                             unless the seed left dissonance vanilla.
--   shop_items        object  LocationID (as a string key) -> ItemID for every
--                             shop slot. Replaces AP's LocationScouts round
--                             trip. Only slots the player has actually bought
--                             from get an icon, exactly as on AP -- see
--                             applyShopItems.
-- ============================================================

local AP_ITEM_BASE     = 420000
local AP_LOCATION_BASE = 430000

-- Game ItemIDs that AP collapses onto a different base id before it ever
-- reaches the tracker, so ITEM_MAPPING only knows the base.
--
-- The apworld builds Progressive Whip / Shield / Beherit as one AP item per
-- tier, all sharing the base id as their `code` (420061 / 420076 / 420175)
-- and carrying the per-tier game id on `lm2_game_id`. Online the tracker sees
-- the code and counts receptions. The seed files, however, record
-- `lm2_game_id` -- so offline the second whip arrives as game id 62, the
-- third as 63, and neither is in ITEM_MAPPING: progressives and beherits
-- simply stopped moving.
--
-- Folding here rather than in ITEM_MAPPING keeps that table honest as pure
-- AP-id space; this file is already the game-id -> AP-id adapter.
--
-- Families where AP collapses the id but ITEM_MAPPING lists every game id
-- too (Ankh Jewels, Crystal Skulls, Sacred Orbs, Research) need no entry --
-- both spellings already resolve to the same code.
local GAME_ID_BASE = {
    [62] = 61,   -- Whip2  -> Whip1  (Progressive Whip)
    [63] = 61,   -- Whip3  -> Whip1
    [77] = 76,   -- Shield2 -> Shield1 (Progressive Shield)
    [78] = 76,   -- Shield3 -> Shield1
    [176] = 175, -- ProgressiveBeherit2..7 -> ProgressiveBeherit1
    [177] = 175,
    [178] = 175,
    [179] = 175,
    [180] = 175,
    [181] = 175,
}

local UAT_VARIABLES = {
    "slot_data", "items", "locations",
    "guardian_kills", "dissonance_count", "shop_items",
}

-- Items already handed to onItem, in the order the server sent them. onItem
-- *increments* (prog[code] = prog[code] + 1), so replaying the whole list on
-- every push would multiply every count -- only the tail may be applied.
local _applied_items = {}

-- ============================================================
-- Value coercion
-- UAT values are whatever the server put in the JSON. PopTracker hands arrays
-- and objects over as Lua tables, but a server that has nothing yet may send
-- nil, and a one-element array can arrive from a sloppy encoder as a bare
-- scalar. Normalise rather than trusting the shape.
-- ============================================================

local function as_array(v)
    if type(v) == "table" then return v end
    if v == nil then return {} end
    return {v}
end

local function array_len(t)
    -- PopTracker's JSON->Lua conversion yields 1-based sequences, so # is
    -- right, but guard against a map-shaped table sneaking in.
    local n = 0
    for _ in ipairs(t) do n = n + 1 end
    return n
end

-- ============================================================
-- Appliers -- each one funnels into the shared autotracking.lua entry points
-- ============================================================

local function applyItems(list, from_index)
    for i = from_index, array_len(list) do
        local game_id = tonumber(list[i])
        if game_id then
            -- index/name/player are unused by onItem; pass the position and 0
            -- so a debug print in there still reads sensibly.
            onItem(i, AP_ITEM_BASE + (GAME_ID_BASE[game_id] or game_id), nil, 0)
            -- Record what the server sent, NOT the folded id: isAppendOnly
            -- compares against the raw array to decide whether the run
            -- rewound, and folding here would make every whip look like a
            -- mismatch and force a rebuild on every push.
            _applied_items[i] = game_id
        end
    end
end

local function applyLocations(list)
    -- onLocation dedupes through seen_locations, so replaying the full list is
    -- idempotent and there is no delta to track.
    for _, raw in ipairs(as_array(list)) do
        local game_id = tonumber(raw)
        if game_id then
            onLocation(AP_LOCATION_BASE + game_id, nil)
        end
    end
end

local function applyShopItems(map)
    if type(map) ~= "table" then return end
    -- Record the whole stock, but ApplyShopItem only puts an icon on a slot
    -- the player has already bought from, so this is not a spoiler: it is the
    -- same deal AP gets from a scout reply, and it is what turns a purchased
    -- slot into its Weights/ammo icon instead of a blank check.
    --
    -- Runs before the location replay in fullRebuild, which is deliberate:
    -- ApplyShopItem records the stage unconditionally, and onLocation reads
    -- LOCATION_ID_TO_SHOP_STAGE as it activates each mark.
    for loc_key, item_raw in pairs(map) do
        local loc_id, item_id = tonumber(loc_key), tonumber(item_raw)
        if loc_id and item_id then
            ApplyShopItem(AP_LOCATION_BASE + loc_id, AP_ITEM_BASE + item_id)
        end
    end
end

local function applyGuardianKills(list)
    local by_ds_name = {}
    for _, g in ipairs(GUARDIAN_KILL_DS_NAMES) do
        by_ds_name[g.ds_name] = g.code
    end
    for _, ds_name in ipairs(as_array(list)) do
        local code = by_ds_name[tostring(ds_name)]
        if code then MarkGuardianDead(code) end
    end
end

-- ============================================================
-- Sync
-- ============================================================

-- True when `list` still starts with everything already applied. A server that
-- rewinds (new game, different save) fails this and forces a full rebuild --
-- otherwise the tail-apply would bolt the new run onto the old counts.
local function isAppendOnly(list)
    local applied = array_len(_applied_items)
    if array_len(list) < applied then return false end
    for i = 1, applied do
        if tonumber(list[i]) ~= _applied_items[i] then return false end
    end
    return true
end

local function fullRebuild(store)
    -- Same order the AP backend reaches this state in: clear handlers (in
    -- registration order), then settings, then the item replay, then locations.
    onClear(nil)
    ResetShopItems()
    ResetMantraLabels()
    -- Before ApplySlotData, which sets the starting subweapon's ammo stage.
    ResetTrackedItems()
    _applied_items = {}

    local slot_data = store:ReadVariable("slot_data")
    SetDissonanceMode(slot_data and slot_data.random_dissonance)
    if slot_data then ApplySlotData(slot_data) end

    -- Before the locations: onLocation reads a shop slot's stage as it clears
    -- the section, and offline there is no scout reply to arrive late and fix
    -- it up afterwards.
    applyShopItems(store:ReadVariable("shop_items"))

    applyItems(as_array(store:ReadVariable("items")), 1)
    applyLocations(store:ReadVariable("locations"))
    applyGuardianKills(store:ReadVariable("guardian_kills"))
    SetDissonanceCount(store:ReadVariable("dissonance_count"))
end

local function onUatUpdate(store, changed)
    local touched = {}
    for _, name in ipairs(changed or {}) do touched[name] = true end

    local items = as_array(store:ReadVariable("items"))

    -- A slot_data push means a different seed or changed settings: nothing
    -- derived from the old one survives, so start over.
    if touched["slot_data"] or not isAppendOnly(items) then
        fullRebuild(store)
        return
    end

    if touched["items"] then
        applyItems(items, array_len(_applied_items) + 1)
    end
    if touched["locations"] then
        applyLocations(store:ReadVariable("locations"))
    end
    if touched["shop_items"] then
        applyShopItems(store:ReadVariable("shop_items"))
    end
    if touched["guardian_kills"] then
        applyGuardianKills(store:ReadVariable("guardian_kills"))
    end
    if touched["dissonance_count"] then
        SetDissonanceCount(store:ReadVariable("dissonance_count"))
    end

    -- Settings are untouched here, but goal progress moves with items and
    -- guardian kills, and neither of those is a watched item code.
    UpdateGoMode()
end

-- Exposed for the offline test harness, which drives the adapter with a fake
-- store rather than a live socket.
UAT_ON_UPDATE = onUatUpdate
UAT_FULL_REBUILD = fullRebuild

if ScriptHost.AddVariableWatch then
    ScriptHost:AddVariableWatch("lm2_uat", UAT_VARIABLES, onUatUpdate)
else
    print("LM2: PopTracker build has no UAT support (AddVariableWatch missing)")
end
