local supports = {}

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

local function revive_hack(ghost, prev)
    -- Can't read the configuration of some items to reapply it... so instantly destroy a deconstructed item
    -- and then revive the ghost instead.  This does not grant free materials since the deconstructed item would
    -- provide them.

    local hp = prev.health
    prev.destroy()
    local ent = select(2, ghost.revive())
    ent.health = hp
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

function supports.container(ghost, prev, player)
    if prev.get_inventory(defines.inventory.item_main).is_empty() then
        return revive_hack(ghost, prev)
    end
end

supports.logistic_container = supports.container
supports.tile = always
supports.straight_rail = always
supports.curved_rail = always
supports.rail_signal = revive_hack
supports.rail_chain_signal = revive_hack

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
