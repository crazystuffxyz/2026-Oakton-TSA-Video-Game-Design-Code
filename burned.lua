-- burned.lua
local burned = {
    monsters = {}
}
local utils = require("utils")

function burned.spawn(x, y)
    table.insert(burned.monsters, {
        x = x, 
        y = y, 
        spawnX = x,
        spawnY = y,
        width = 8, 
        height = 8, 
        speed = 50,
        active = true
    })
end

function burned.update(dt, player)
    for i = #burned.monsters, 1, -1 do
        local m = burned.monsters[i]
        if m.active then
            -- Hunt the player
            local px = player.x + player.width/2
            local py = player.y + player.height/2
            local mx = m.x + m.width/2
            local my = m.y + m.height/2
            
            local dx = px - mx
            local dy = py - my
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist > 0 then
                m.x = m.x + (dx/dist) * m.speed * dt
                m.y = m.y + (dy/dist) * m.speed * dt
            end
            
            -- Collision with player
            if player.stunTimer <= 0 and utils.checkTouch(player, m) then
                player.stunTimer = 0.75
                
                -- Visual effect
                local fx = require("fx")
                fx.spawn(player.x + player.width/2, player.y + player.height/2, {1, 0, 0}, 15, 150)
                fx.shake(5, 0.2)
                
                -- Hater respawns at finish line
                m.x = m.spawnX
                m.y = m.spawnY
            end
        end
    end
end

function burned.draw()
    for _, m in ipairs(burned.monsters) do
        -- Square pixel
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", m.x, m.y, m.width, m.height)
    end
    love.graphics.setColor(1, 1, 1)
end

function burned.reset()
    burned.monsters = {}
end

return burned