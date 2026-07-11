DEBUG = true
ENABLE_DEBUG_LOG = DEBUG

-- ============================================================
-- Bulk-load performance
-- ============================================================
-- Location access rules are opaque "^$lm2_logic|..." Lua calls, so PopTracker
-- cannot dependency-track them and re-evaluates EVERY location rule on EVERY
-- item change -- and each rule runs a full CanReach flood-fill. On (re)connect
-- to a finished AP slot, hundreds of items and locations replay at once, so the
-- naive path is O(items x locations x flood-fill) and blocks the main thread
-- long enough for the AP socket to time out and disconnect. (Worse here: the ER
-- variant also loads the entrance + escape items and a dynamic entrance graph.)
--
-- AllowDeferredLogicUpdate lets PopTracker coalesce those into far fewer logic
-- passes (evaluated fewer times than items update), which is exactly "only do
-- the reachability work once per batch instead of once per item". It auto-
-- enables for 'ap' packs only since PopTracker 0.31.0, and this pack targets
-- 0.29.0, so it must be set explicitly. The nil-guard keeps older PopTracker
-- builds (< 0.28.1, which lack the property) working unchanged.
if Tracker.AllowDeferredLogicUpdate ~= nil then
    Tracker.AllowDeferredLogicUpdate = true
end

-- ============================================================
-- Items
-- ============================================================
Tracker:AddItems("items/equipment.json")
Tracker:AddItems("items/sigils.json")
Tracker:AddItems("items/weapons.json")
Tracker:AddItems("items/software.json")
Tracker:AddItems("items/software_combos.json")
Tracker:AddItems("items/mantras.json")
Tracker:AddItems("items/collectibles.json")
Tracker:AddItems("items/ammo.json")
Tracker:AddItems("items/options.json")
Tracker:AddItems("items/bosses.json")
Tracker:AddItems("items/settings.json")
Tracker:AddItems("items/entrances.json")
Tracker:AddItems("items/escape.json")
Tracker:AddItems("items/shop_marks.json")
Tracker:AddItems("items/cursed.json")

-- ============================================================
-- Locations
-- ============================================================
Tracker:AddLocations("locations/la-mulana.json")
Tracker:AddLocations("locations/roots_of_yggdrasil.json")
Tracker:AddLocations("locations/annwfn.json")
Tracker:AddLocations("locations/immortal_battlefield.json")
Tracker:AddLocations("locations/icefire_treetop.json")
Tracker:AddLocations("locations/divine_fortress.json")
Tracker:AddLocations("locations/shrine_of_the_frost_giants.json")
Tracker:AddLocations("locations/gate_of_the_dead.json")
Tracker:AddLocations("locations/takamagahara_shrine.json")
Tracker:AddLocations("locations/heavens_labyrinth.json")
Tracker:AddLocations("locations/valhalla.json")
Tracker:AddLocations("locations/dark_star_lords_mausoleum.json")
Tracker:AddLocations("locations/ancient_chaos.json")
Tracker:AddLocations("locations/hall_of_malice.json")
Tracker:AddLocations("locations/eternal_prison_doom.json")
Tracker:AddLocations("locations/eternal_prison_gloom.json")
Tracker:AddLocations("locations/spiral_hell.json")
Tracker:AddLocations("locations/starting_shop.json")
Tracker:AddLocations("locations/entrances.json")
Tracker:AddLocations("locations/potlegend.json")
Tracker:AddLocations("locations/enemyglossary.json")
Tracker:AddLocations("locations/glossarylegend.json")


-- ============================================================
-- Maps
-- ============================================================
Tracker:AddMaps("maps/maps.json")

-- ============================================================
-- Layouts
-- ============================================================
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/items.json")
Tracker:AddLayouts("layouts/maps.json")
Tracker:AddLayouts("layouts/broadcast.json")
Tracker:AddLayouts("layouts/settings.json")
Tracker:AddLayouts("layouts/entrances.json")
Tracker:AddLayouts("layouts/escape.json")
Tracker:AddLayouts("layouts/shops.json")


-- ============================================================
-- Logic
-- ============================================================
ScriptHost:LoadScript("scripts/logic.lua")
ScriptHost:LoadScript("scripts/entrance_mapping.lua")
ScriptHost:LoadScript("scripts/escape_route.lua")

-- ============================================================
-- AP Autotracking
-- ============================================================
ScriptHost:LoadScript("scripts/autotracking.lua")