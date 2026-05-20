-- ============================================================
-- Escape Sequence: derives a way out of the Immortal Battlefield toward
-- the Cliff from whatever entrances are currently paired.
--
-- Areas are the graph nodes; every tracked pairing becomes an edge
-- between the two areas it joins. One-way exits only allow travel
-- inward, so they never contribute an outbound edge. The shortest
-- route found is written into the escape_step_N rows as overlay text.
-- ============================================================

local NUM_STEPS = 20        -- escape_step_1 .. escape_step_N display rows
local SOURCE_FIELD = "Battlefield"
local TARGET_FIELD = "Cliff"

-- ER code -> routing field
local ER_FIELD = {
    -- Surface
    ["er_starting_area"] = "Surface",
    ["er_village_of_departure_next_to_xelpud"] = "Surface",
    ["er_village_of_departure_main__f_5"] = "Surface",
    ["er_village_of_departure_ladder_down__f_3"] = "Surface",
    -- Guidance
    ["er_gate_of_guidance_main_entrance__c_1"] = "Guidance",
    ["er_gate_of_guidance_ladder_down__a_6"] = "Guidance",
    ["er_gate_of_guidance_left_gate__a_3"] = "Guidance",
    -- Inferno Cavern
    ["er_inferno_cavern__b_1"] = "Inferno",
    -- Mausoleum
    ["er_mausoleum_of_giants_ladder_up__a_1"] = "Mausoleum",
    ["er_mausoleum_of_giants_left_door__a_5"] = "Mausoleum",
    -- Endless
    ["er_endless_corridor__c_1"] = "Endless",
    -- Illusion
    ["er_gate_of_illusion_left_gate__a_1"] = "Illusion",
    ["er_gate_of_illusion_right_gate__c_1"] = "Illusion",
    -- Yggdrasil
    ["er_roots_of_yggdrasil_main_gate__d_4"] = "Yggdrasil",
    ["er_roots_of_yggdrasil_top_left_switch_gate__a_1"] = "Yggdrasil",
    ["er_roots_of_yggdrasil_top_middle_nidhogg_gate__d_1"] = "Yggdrasil",
    ["er_roots_of_yggdrasil_top_right_birth_gate__g_1"] = "Yggdrasil",
    ["er_roots_of_yggdrasil_ladder_down__c_5"] = "Yggdrasil",
    ["er_roots_of_yggdrasil_bottom_soul_gate__d_6"] = "Yggdrasil",
    -- Annwfn
    ["er_annwfn_ladder_up__c_1"] = "Annwfn",
    ["er_annwfn_bottom_one_way_ladder__e_5"] = "Annwfn",
    ["er_annwfn_bifrost"] = "Annwfn",
    ["er_annwfn_soul_gate__a_4"] = "Annwfn",
    ["er_annwfn_right_gate__g_4"] = "Annwfn-Right",
    -- Immortal Battlefield
    ["er_immortal_battlefield_bifrost_fall"] = "Battlefield",
    ["er_immortal_battlefield_cetus_up_ladder__f_1"] = "Battlefield",
    ["er_immortal_battlefield_right_door__h_4"] = "Battlefield",
    ["er_immortal_battlefield_down_ladder_near_spinning_wheel__d_7"] = "Battlefield",
    ["er_immortal_battlefield_alviss_down_ladder__g_7"] = "Battlefield",
    ["er_immortal_battlefield_moon_altar_hallway__g_7"] = "Battlefield",
    ["er_immortal_battlefield_left_altar_door__d_3"] = "Battlefield",
    ["er_immortal_battlefield_right_altar_door__f_3"] = "Battlefield",
    ["er_immortal_battlefield_top_right_gate__h_2"] = "Battlefield",
    ["er_immortal_battlefield_left_gate__a_6"] = "Battlefield-Left",
    ["er_immortal_battlefield_bottom_left_gate__b_7"] = "Battlefield-Left",
    ["er_immortal_battlefield_spiral_boat_soul_gate_d_4"] = "Battlefield-Boat",
    -- Icefire
    ["er_icefire_treetop_middle_gate__d_3"] = "Icefire",
    ["er_icefire_treetop_fire_side_up_ladder__c_1"] = "Icefire",
    ["er_icefire_treetop_ice_side_left_ladder__f_1"] = "Icefire",
    ["er_icefire_treetop_ice_side_right_ladder__f_1"] = "Icefire",
    ["er_icefire_treetop_under_ratatoskr_soul_gate__g_3"] = "Icefire",
    ["er_icefire_treetop_vidofnir_soul_gate__d_6"] = "Icefire-Vidofnir",
    -- Divine Fortress
    ["er_divine_fortress_left_gate__a_3"] = "Divine",
    ["er_divine_fortress_soul_gate__c_5"] = "Divine",
    -- Frost Giants
    ["er_shrine_of_the_frost_giants_bergelmir_gate__b_4"] = "Frost-Giants",
    ["er_shrine_of_the_frost_giants_main_soul_gate__e_4"] = "Frost-Giants",
    ["er_shrine_of_the_frost_giants_backside_gate__b_2"] = "Frost-Giants-Back",
    ["er_shrine_of_the_frost_giants_balor_soul_gate__e_1"] = "Frost-Giants-Balor",
    -- Gate of the Dead
    ["er_gate_of_the_dead_wedjat_gate__f_5"] = "GOTD",
    ["er_gate_of_the_dead_soul_gate__c_4"] = "GOTD",
    -- Takamagahara
    ["er_takamagahara_shrine_bottom_gate__c_7"] = "Takamagahara",
    ["er_takamagahara_shrine_neck"] = "Takamagahara",
    ["er_takamagahara_shrine_top_main_soul_gate__d_1"] = "Takamagahara",
    ["er_takamagahara_shrine_belial_soul_gate__b_1"] = "Takamagahara-Belial",
    -- Heaven's Labyrinth
    ["er_heavens_labyrinth_gate__d_1"] = "Heaven",
    ["er_heavens_labyrinth_monster_s_jaw"] = "Heaven",
    ["er_heavens_labyrinth_soul_gate__e_5"] = "Heaven",
    -- Valhalla
    ["er_valhalla_gate__a_2"] = "Valhalla",
    ["er_valhalla_soul_gate__e_2"] = "Valhalla",
    -- DSLM
    ["er_dark_star_lord_s_mausoleum_gate__d_7"] = "DSLM",
    ["er_dark_star_lord_s_mausoleum_pyramid"] = "DSLM",
    -- Ancient Chaos
    ["er_ancient_chaos_gate__d_6"] = "Chaos",
    ["er_ancient_chaos_soul_gate__c_1"] = "Chaos-Blood",
    -- Hall of Malice
    ["er_hall_of_malice_gate__c_1"] = "Malice-Top",
    ["er_hall_of_malice_soul_gate__d_3"] = "Malice",
    -- Eternal Prison
    ["er_eternal_prison_gloom_soul_gate__d_2"] = "Eternal",
    -- Nibiru
    ["er_nibiru_spaceship"] = "Nibiru",
    -- Altar
    ["er_altar_left_door__a_1"] = "Altar-Left",
    ["er_altar_right_door__c_1"] = "Altar-Right",
    -- Cavern / Cliff
    ["er_cavern_left_door__a_1"] = "Cavern",
    ["er_cavern_right_door__d_1"] = "Cavern",
    ["er_cliff__a_1"] = "Cliff",
}

-- Exits you can only fall/drop into; they never let you leave the area again.
local ONEWAY_EXIT = {
    ["er_annwfn_bottom_one_way_ladder__e_5"] = true,
    ["er_immortal_battlefield_bifrost_fall"] = true,
    ["er_immortal_battlefield_moon_altar_hallway__g_7"] = true,
    ["er_heavens_labyrinth_monster_s_jaw"] = true,
    ["er_inferno_cavern__b_1"] = true,
}

-- Field -> friendly name for the display.
local FIELD_NAME = {
    ["Altar-Right"] = "Altar",
    ["Altar-Left"] = "Altar",
    ["Annwfn"] = "Annwfn",
    ["Annwfn-Right"] = "Annwfn",
    ["Battlefield"] = "Immortal Battlefield",
    ["Battlefield-Left"] = "Immortal Battlefield",
    ["Battlefield-Boat"] = "Immortal Battlefield",
    ["Cavern"] = "Cavern",
    ["Chaos"] = "Ancient Chaos",
    ["Chaos-Blood"] = "Ancient Chaos",
    ["Cliff"] = "Cliff",
    ["DSLM"] = "Dark Star Lord's Mausoleum",
    ["Divine"] = "Divine Fortress",
    ["Eternal"] = "Eternal Prison",
    ["Endless"] = "Endless Corridor",
    ["Forest"] = "Forest",
    ["Frost-Giants"] = "Shrine of the Frost Giants",
    ["Frost-Giants-Back"] = "Shrine of the Frost Giants",
    ["Frost-Giants-Balor"] = "Shrine of the Frost Giants",
    ["GOTD"] = "Gate of the Dead",
    ["Guidance"] = "Gate of Guidance",
    ["Heaven"] = "Heaven's Labyrinth",
    ["Icefire"] = "Icefire Treetop",
    ["Icefire-Vidofnir"] = "Icefire Treetop",
    ["Inferno"] = "Inferno Cavern",
    ["Illusion"] = "Gate of Illusion",
    ["Malice"] = "Hall of Malice",
    ["Malice-Top"] = "Hall of Malice",
    ["Mausoleum"] = "Mausoleum of the Giants",
    ["Surface"] = "Village of Departure",
    ["Takamagahara"] = "Takamagahara Shrine",
    ["Takamagahara-Belial"] = "Takamagahara Shrine",
    ["Valhalla"] = "Valhalla",
    ["Yggdrasil"] = "Roots of Yggdrasil",
}

-- Fields a Holy Grail warp can reach once one of the activation fields is touched.
local GRAIL_FIELDS = {
    "Surface", "Yggdrasil", "Annwfn", "Battlefield", "Icefire", "Divine",
    "Frost-Giants", "GOTD", "Takamagahara", "Heaven", "Valhalla", "DSLM",
    "Chaos", "Malice", "Eternal",
}
local GRAIL_ACTIVATORS = { "Guidance", "Mausoleum", "Surface", "Illusion", "Nibiru" }

local function field_name(f)
    return FIELD_NAME[f] or f
end

-- Build the routing graph: edges[field] = { {to=, via=, arrive=}, ... }
--   via    = the entrance/mechanic used to LEAVE `from`
--   arrive = the entrance you come out of in `to` (nil for mechanic edges)
local function build_edges()
    local edges = {}
    local function add(from, to, via, arrive)
        if not edges[from] then edges[from] = {} end
        table.insert(edges[from], { to = to, via = via, arrive = arrive })
    end

    -- Fixed connections: sub-area merges plus permanent in-game traversal links.
    add("Annwfn-Right", "Annwfn", nil)
    add("Battlefield-Left", "Battlefield", nil)
    add("Battlefield-Boat", "Battlefield", nil)
    add("Eternal", "Takamagahara", "False Gate (IGT xx:01-xx:15)")
    add("Eternal", "Surface", "False Gate (IGT xx:16-xx:30)")
    add("Eternal", "Icefire", "False Gate (IGT xx:31-xx:45)")
    add("Eternal", "Divine", "False Gate (IGT xx:46-xx:60)")
    add("Frost-Giants", "Frost-Giants-Balor", nil)
    add("Icefire", "Icefire-Vidofnir", nil)
    add("Malice-Top", "Malice", nil)
    add("Mausoleum", "Guidance", "Mausoleum Elevator (A-5)")
    add("Altar-Left", "Altar-Right", nil)

    -- Corridor of Blood: once the spin is available these backside areas all
    -- interconnect, so treat them as one fully-connected cluster.
    local CORRIDOR = {
        "Valhalla", "Frost-Giants-Back", "Chaos-Blood", "Eternal", "DSLM", "Malice",
    }
    for _, a in ipairs(CORRIDOR) do
        for _, b in ipairs(CORRIDOR) do
            if a ~= b then add(a, b, "Corridor of Blood") end
        end
    end

    -- Holy Grail warps from any activator field to all grail fields.
    for _, orig in ipairs(GRAIL_ACTIVATORS) do
        for _, field in ipairs(GRAIL_FIELDS) do
            add(orig, field,
                "warp to " .. field_name(field) .. " (" .. field_name(orig) .. " unlocks the Holy Grail)")
        end
    end

    -- Live entrance pairings. ER_PAIRINGS is bidirectional, so iterate every
    -- code and add an outbound edge from its field unless it is a one-way exit.
    for code, dest in pairs(ER_PAIRINGS or {}) do
        if not ONEWAY_EXIT[code] then
            local from = ER_FIELD[code]
            local to = ER_FIELD[dest]
            if from and to and from ~= to then
                add(from, to, ER_ENTRANCE_NAMES[code] or code, ER_ENTRANCE_NAMES[dest] or dest)
            end
        end
    end

    return edges
end

-- BFS from SOURCE_FIELD to TARGET_FIELD. Returns an ordered list of steps:
--   { {field=, arrive=<door you came in by, nil at source>,
--      exit=<door you leave by, nil at target>}, ... }
-- or nil if unreachable.
local function find_route()
    local edges = build_edges()

    if SOURCE_FIELD == TARGET_FIELD then
        return { { field = TARGET_FIELD } }
    end

    local seen = { [SOURCE_FIELD] = true }
    local backtrack = {}
    local queue = { SOURCE_FIELD }
    local head = 1

    while head <= #queue do
        local field = queue[head]; head = head + 1
        if field == TARGET_FIELD then break end
        for _, e in ipairs(edges[field] or {}) do
            if not seen[e.to] then
                seen[e.to] = true
                backtrack[e.to] = { from = field, via = e.via, arrive = e.arrive }
                queue[#queue + 1] = e.to
            end
        end
    end

    if not seen[TARGET_FIELD] then return nil end

    -- Recover the field order source..target by walking the backtrack tree.
    local fields = {}
    local field = TARGET_FIELD
    while field ~= SOURCE_FIELD do
        table.insert(fields, 1, field)
        field = backtrack[field].from
    end
    table.insert(fields, 1, SOURCE_FIELD)

    -- For each field, attach the door you entered through (this field's
    -- backtrack.arrive) and the door you leave through (the next field's
    -- backtrack.via).
    local chain = {}
    for i, f in ipairs(fields) do
        local entry = { field = f }
        if backtrack[f] then entry.arrive = backtrack[f].arrive end
        if i < #fields then entry.exit = backtrack[fields[i + 1]].via end
        chain[i] = entry
    end
    return chain
end

local function clear_steps()
    for i = 1, NUM_STEPS do
        local obj = Tracker:FindObjectForCode("escape_step_" .. i)
        if obj then
            obj:SetOverlay("")
            obj:SetOverlayBackground("#00000000")
        end
    end
end

local function set_step(i, text, highlight)
    local obj = Tracker:FindObjectForCode("escape_step_" .. i)
    if not obj then return end
    obj:SetOverlayAlign("left")
    obj:SetOverlayFontSize(11)
    obj:SetOverlay(text)
    obj:SetOverlayBackground(highlight and "#FF333333" or "#00000000")
end

-- Public: recompute the escape route and repaint the display rows.
function UpdateEscapeRoute()
    clear_steps()

    local route = find_route()
    if not route then
        set_step(1, "No route to Cliff yet", false)
        set_step(2, "(track more entrances)", false)
        return
    end

    -- Render each field as a highlighted header, with the door you arrive
    -- through and the door you leave through ("-->") indented beneath it.
    local row = 1
    local function emit(text, highlight)
        if row > NUM_STEPS then return end
        set_step(row, text, highlight)
        row = row + 1
    end

    for _, step in ipairs(route) do
        if row > NUM_STEPS then break end
        emit(field_name(step.field), true)
        if step.arrive then emit("    " .. step.arrive, false) end
        if step.exit then emit("    --> " .. step.exit, false) end
    end
end

-- Initial paint (restore/spoiler will repaint once pairings load).
UpdateEscapeRoute()
