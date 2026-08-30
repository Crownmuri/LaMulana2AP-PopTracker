-- ============================================================
-- Map Tracker (Offline) -- entrance tracker over UAT
-- ============================================================
-- Same tracker as var_0er, autotracked from the game mod's UAT server instead
-- of an Archipelago room. Rather than copy the ER item/location/layout data and
-- its ~2600 lines of entrance logic, this loads var_0er's own init and tells it
-- where those assets live: PopTracker resolves a path as "<active variant>/
-- <path>" then "<path>", so the explicit "var_0er/" prefix hits at pack root
-- from any variant, while bare paths keep resolving into THIS variant.
--
-- What stays local to var_3offline (bare paths, so they resolve here):
--   layouts/settings.json            -- ER settings grid
--   layouts/settings_tabs_base.json  -- swapped by entrance_mapping.lua's
--   layouts/settings_tabs_dlc.json      ApplyEntranceSettingsTabs, by bare path
ER_ASSET_PREFIX = "var_0er/"
ScriptHost:LoadScript("var_0er/scripts/init.lua")

-- ============================================================
-- UAT Autotracking
-- ============================================================
-- var_0er/scripts/init.lua has already loaded scripts/autotracking.lua, which
-- owns the shared apply logic plus the item watches, Go Mode and label updates
-- both backends need. Its Archipelago:Add*Handler registrations are inert with
-- no AP room, so this just layers the UAT adapter on top.
ScriptHost:LoadScript("scripts/uat.lua")
