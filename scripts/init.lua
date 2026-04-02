DEBUG = true
ENABLE_DEBUG_LOG = DEBUG
-- ============================================================
-- Items
-- ============================================================
Tracker:AddItems("items/equipment.json")
Tracker:AddItems("items/sigils.json")
Tracker:AddItems("items/weapons.json")
Tracker:AddItems("items/software.json")
Tracker:AddItems("items/mantras.json")
Tracker:AddItems("items/collectibles.json")
Tracker:AddItems("items/ammo.json")
Tracker:AddItems("items/options.json")
Tracker:AddItems("items/bosses.json")
Tracker:AddItems("items/settings.json")
Tracker:AddItems("items/shop_marks.json")

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
Tracker:AddLayouts("layouts/shops.json")

-- ============================================================
-- Logic
-- ============================================================
ScriptHost:LoadScript("scripts/logic.lua")

-- ============================================================
-- AP Autotracking
-- ============================================================
ScriptHost:LoadScript("scripts/autotracking.lua")