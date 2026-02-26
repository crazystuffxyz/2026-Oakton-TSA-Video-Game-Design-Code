-- fx.lua
local fx = {
    particles = {},
    shakeTime = 0,
    shakeMag = 0
}

function fx.update(dt)
    if fx.shakeTime > 0 then
        fx.shakeTime = fx.shakeTime - dt
        if fx.shakeTime < 0 then fx.shakeMag = 0 end
    end
    for i = #fx.particles, 1, -1 do
        local p = fx.particles[i]
        p.x = p.x + p.xv * dt
        p.y = p.y + p.yv * dt
        p.life = p.life - dt
        p.xv = p.xv * 0.9 -- friction
        p.yv = p.yv * 0.9
        
        -- Gravity for dust
        if p.type == "dust" then
            p.yv = p.yv - 100 * dt -- Float up
        elseif p.type == "debris" then
             p.yv = p.yv + 500 * dt -- Gravity
        end

        if p.life <= 0 then
            table.remove(fx.particles, i)
        end
    end
end

function fx.draw()
    for i, p in ipairs(fx.particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.life / p.maxLife)
        if p.type == "square" or p.type == "debris" then
            love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
        else
            love.graphics.circle("fill", p.x, p.y, p.size/2)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function fx.spawn(x, y, color, count, speed)
    for i=1, count do
        local angle = math.random() * math.pi * 2
        local spd = math.random() * speed
        table.insert(fx.particles, {
            x = x, y = y,
            xv = math.cos(angle) * spd,
            yv = math.sin(angle) * spd,
            color = color,
            life = math.random(0.4, 0.8),
            maxLife = 0.8,
            size = math.random(2, 4),
            type = "debris"
        })
    end
end

function fx.dust(x, y)
    for i=1, 5 do
        table.insert(fx.particles, {
            x = x + math.random(-5, 5),
            y = y,
            xv = (math.random() - 0.5) * 20,
            yv = -math.random(10, 30),
            color = {0.8, 0.8, 0.8},
            life = math.random(0.3, 0.6),
            maxLife = 0.6,
            size = math.random(2, 3),
            type = "dust"
        })
    end
end

function fx.sparkle(x, y, color)
    table.insert(fx.particles, {
        x = x, y = y,
        xv = (math.random() - 0.5) * 20,
        yv = (math.random() - 0.5) * 20,
        color = color,
        life = 0.5,
        maxLife = 0.5,
        size = 2,
        type = "circle"
    })
end

function fx.trail(x, y, color, size)
    table.insert(fx.particles, {
        x = x, y = y,
        xv = 0, yv = 0,
        color = color,
        life = 0.15,
        maxLife = 0.15,
        size = size,
        type = "circle"
    })
end

function fx.shake(mag, time)
    if mag > fx.shakeMag then
        fx.shakeMag = mag
        fx.shakeTime = time
    end
end

function fx.applyShake()
    if fx.shakeTime > 0 then
        local dx = (math.random() * 2 - 1) * fx.shakeMag
        local dy = (math.random() * 2 - 1) * fx.shakeMag
        love.graphics.translate(dx, dy)
    end
end

return fx