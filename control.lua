local supports = {}

local SAVE_BURNER_FIELDS = {"currently_burning", "heat", "remaining_burning_fuel" }
local BURNER_INVENTORIES = {"inventory", "burnt_result_inventory" }

local function check_belt(prev, lanes)
    -- We want normal behavior if the transport belt has items on it, because the new blueprint might expect it to
    -- have different items and deconstructing it also removes its contents.
    for i=1,lanes do
        if #prev.get_transport_line(i) > 0 then
            return
        end
    end
    return true
end

local function always() return true end

local function restore_inventory(contents, inv)
    local n
    for name, count in pairs(contents) do
        count = count - inv.insert({count=count, name=name})
        contents[name] = count
        if count ~= 0 then
            return contents
        end
    end
    return
end

local function revive_hack(ghost, prev)
    -- Can't read the configuration of some items to reapply it... so instantly destroy a deconstructed item
    -- and then revive the ghost instead.  This does not grant free materials since the deconstructed item would
    -- provide them.

    local function empty_inventory(inv)
        return (not inv) or inv.is_empty()
    end

    local hp = prev.health
    local energy = prev.energy
    local burner, burner_inv

    if not (
        empty_inventory(prev.get_output_inventory())
        and empty_inventory(prev.get_module_inventory())
    ) then
        game.print("Failed empty inventory check")
        return
    end

    if prev.burner then
        --if not settings.global["GhostBuster_allow-burners"].value then
        --    game.print("Failed setting enabled check")
        --    return
        --end
        burner = {}
        burner_inv = {}
        for _,k in pairs(SAVE_BURNER_FIELDS) do
            burner[k] = prev.burner[k]
        end
        for _,k in pairs(BURNER_INVENTORIES) do
            local inv = prev.burner[k]
            if inv and inv.valid then
                burner_inv[k] = inv.get_contents()
            end
        end
    end

    prev.destroy()
    local ent = select(2, ghost.revive())
    ent.health = hp
    ent.energy = energy

    if burner then
        if not ent.burner then
            game.print("[GhostBuster] While reviving " .. ent.name .. ": Target lacks burner but source had one")
            return
        end
        for _,k in pairs(SAVE_BURNER_FIELDS) do
            ent.burner[k] = burner[k]
        end
        for k,v in pairs(burner_inv) do
            leftover = restore_inventory(v, ent.burner[k])
            if leftover then
                game.print("[GhostBuster] While reviving " .. ent.name .. ": Unable to fully insert " .. k .. ".  Lost contents: " .. serpent.block(leftover))
            end
        end
    end

    return
end

local function forbid_inventory(what)
    local fn
    if type(what) == 'table' then
        function fn(ghost, prev, player)
            local inv
            for _,k in pairs(what) do
                inv = prev.get_inventory(k)
                if inv and not inv.is_empty() then
                    return
                end
            end
            return revive_hack(ghost, prev, player)
        end
    else
        function fn(ghost, prev, player)
            local inv = prev.get_inventory(what)
            if not inv or inv.is_empty() then
                return revive_hack(ghost, prev, player)
            end
        end
    end
    return fn
end

function supports.transport_belt(ghost, prev, player)
    if not check_belt(prev, 2) then
        return
    end

    -- Can't read ghost wires, sooo...
    return revive_hack(ghost, prev)
end

function supports.underground_belt(ghost, prev, player)
    return check_belt(prev, 4)
end

function supports.splitter(ghost, prev, player)
    if not check_belt(prev, 8) then
        return
    end

    -- Can't read ghost config...
    return revive_hack(ghost, prev)
end

supports.container = forbid_inventory(defines.inventory.item_main)
supports.furnace = forbid_inventory({defines.inventory.furnace_result, defines.inventory.furnace_source})

--
--function supports.container(ghost, prev, player)
--    if prev.get_inventory(defines.inventory.item_main).is_empty() then
--        return revive_hack(ghost, prev)
--    end
--end

supports.logistic_container = supports.container
supports.tile = always
supports.straight_rail = always
supports.curved_rail = always
supports.rail_signal = revive_hack
supports.rail_chain_signal = revive_hack
supports.solar_panel = always
supports.accumulator = revive_hack
supports.furnace = revive_hack


function supports.inserter(ghost, prev, player)
    if prev.held_stack.valid_for_read then
        return
    end
    return revive_hack(ghost, prev)
end

for k, v in pairs(supports) do
    supports[k:gsub("_", "-")] = v
end


local function check_ghost(ghost, player)
    -- Make sure it's actually a ghost.
    if ghost.type ~= 'entity-ghost' and ghost.type ~= 'tile-ghost' then
        return
    end
    local fn = supports[ghost.ghost_type]
    if not fn then
        return
    end

    local prev

    if ghost.type == 'tile-ghost' then
        prev = ghost.surface.get_tile(ghost.position.x, ghost.position.y)
        if not prev or prev.name ~= ghost.ghost_name then return end
    else
        prev = ghost.surface.find_entities_filtered{
            position = ghost.position,
            name = ghost.ghost_name,
            force = ghost.force,
            limit = 1,
        }[1]
        if not (prev and prev.can_be_destroyed()) then
            return
        end
    end

    -- Some fast exit criteria
    if (
        not prev
        or prev.direction ~= ghost.direction
        or prev.position.x ~= ghost.position.x
        or prev.position.y ~= ghost.position.y
    ) then
        return
    end

    if not fn(ghost, prev, player) then
        return
    end

    prev.cancel_deconstruction(ghost.force, player)
    ghost.destroy()
end



script.on_event(defines.events.on_built_entity, function(event) check_ghost(event.created_entity, game.players[event.player_index]) end)
