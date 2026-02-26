-- pulsedevice.lua
local pulsedevice = {
    power = 10,
    projectiles = {},
    speed = 800,
    lastBlastEvent = 0,
    onCooldown = false,
    cooldownTime = .6, 
    timeOfLastUse = 0,
    holdTime = 0, 
    maxHoldTime = 1.0,
    pulseDeviceSprites = {
        love.graphics.newImage("assets/pulsedeviceframe_1.png"),
    },
    projectileSprites = {
        love.graphics.newImage("assets/projectile.png"),
    },
}
local utils = require("utils")
local player = require("player")
local map = require("map")
local teleporter = require("teleporter")
local fx = require("fx")
local camera = require("camera")

pulsedevice.hitspots = {} 

function pulsedevice.load()
    love.graphics.setDefaultFilter("nearest", "nearest") 
end

function pulsedevice.update(dt)
    pulsedevice.lastBlastEvent = pulsedevice.lastBlastEvent + dt
    if pulsedevice.lastBlastEvent <= .3 then
        player.blasting = true
    end
    
    local mousex, mousey = camera.getMouseWorldPos()
    
    local playerCenterX = player.x + player.width / 2
    local playerCenterY = player.y + player.height / 2
    
    -- Charging
    if love.mouse.isDown(1) and not pulsedevice.onCooldown then
        pulsedevice.holdTime = math.max(.2, math.min(pulsedevice.holdTime + dt, pulsedevice.maxHoldTime))
        player.isCharging = true 
        player.startSquash(1 + (pulsedevice.holdTime * 0.1), 1 - (pulsedevice.holdTime * 0.1))
    else
        player.isCharging = false
    end
    
    -- Fire
    if not love.mouse.isDown(1) and pulsedevice.holdTime > 0 then
        local vector = utils.vector({x = playerCenterX, y = playerCenterY}, {x = mousex, y = mousey})
        local unitVector = utils.unitVector(vector)
        local angle = utils.angleOfVector(vector)
        
        local chargeFactor = math.max(1, pulsedevice.holdTime * 2) 
        local projSpeed = pulsedevice.speed
        local projSize = 4 + (pulsedevice.holdTime * 8)
        
        local projectile = {
            x = playerCenterX,
            y = playerCenterY,
            xv = unitVector.x * projSpeed,
            yv = unitVector.y * projSpeed,
            angle = angle,
            width = projSize,
            height = projSize,
            holdTime = pulsedevice.holdTime,
            teleportCooldown = 0
        }
        table.insert(pulsedevice.projectiles, projectile)
        pulsedevice.onCooldown = true
        pulsedevice.timeOfLastUse = 0
        pulsedevice.holdTime = 0
        
        -- Recoil slightly
        player.xv = player.xv - unitVector.x * 60
        player.yv = player.yv - unitVector.y * 60
        
        fx.shake(1, 0.1)
    end
    
    pulsedevice.timeOfLastUse = pulsedevice.timeOfLastUse + dt
    if pulsedevice.onCooldown and pulsedevice.timeOfLastUse >= pulsedevice.cooldownTime then
        pulsedevice.onCooldown = false
    end
    
    -- Update Projectiles
    for i = #pulsedevice.projectiles, 1, -1 do
        local projectile = pulsedevice.projectiles[i]
        
        -- Projectile cooldown for teleporter
        projectile.teleportCooldown = math.max(0, (projectile.teleportCooldown or 0) - dt)
        
        teleporter.teleportCheck(projectile) 
        
        projectile.x = projectile.x + projectile.xv * dt
        projectile.y = projectile.y + projectile.yv * dt
        
        -- Trail effect
        fx.trail(projectile.x, projectile.y, {1, 0.5 + projectile.holdTime*0.5, 0}, projectile.width * 0.8)
        
        if math.random() > 0.5 then
            fx.sparkle(projectile.x, projectile.y, {1, 0.5, 0})
        end

        local touch = utils.checkTouchWithTileMap(projectile, map)
        if touch.touchingTile then
            player.blasting = true
            local vector = utils.vector({x = projectile.x, y = projectile.y}, {x = playerCenterX, y = playerCenterY})
            local dist = utils.magnitude(vector)
            
            -- Knockback physics
            local launchStrength = 400 + (projectile.holdTime * 800)
            local falloff = math.max(0.1, 1 - (dist / 180)) 
            
            local unitVector = utils.unitVector(vector)
            
            player.xv = player.xv + unitVector.x * launchStrength * falloff
            player.yv = player.yv + unitVector.y * launchStrength * falloff * 1.3 -- Vertical bias
            
            -- Cap velocity
            local maxV = 1000
            if player.xv > maxV then player.xv = maxV end
            if player.xv < -maxV then player.xv = -maxV end
            if player.yv > maxV then player.yv = maxV end
            if player.yv < -maxV then player.yv = -maxV end

            player.startSquash(0.5, 1.5) 

            fx.spawn(projectile.x, projectile.y, {1, 0.5, 0}, 25 + projectile.holdTime*10, 200)
            fx.shake(8 * projectile.holdTime, 0.3)
            
            table.insert(pulsedevice.hitspots, {x = projectile.x, y = projectile.y, life=1})
            table.remove(pulsedevice.projectiles, i)
            pulsedevice.lastBlastEvent = 0
        end
    end
    
    for i = #pulsedevice.hitspots, 1, -1 do
        pulsedevice.hitspots[i].life = pulsedevice.hitspots[i].life - dt
        if pulsedevice.hitspots[i].life <= 0 then
            table.remove(pulsedevice.hitspots, i)
        end
    end
end

function pulsedevice.draw()
    love.graphics.setColor(1, 1, 1)
    for i, projectile in ipairs(pulsedevice.projectiles) do
        love.graphics.draw(pulsedevice.projectileSprites[1], projectile.x, projectile.y, projectile.angle, projectile.width/4, projectile.width/4, 4, 4)
    end

    local mousex, mousey = camera.getMouseWorldPos()
    local playerCenterX = player.x + player.width / 2
    local playerCenterY = player.y + player.height / 2
    local vector = utils.vector({x = playerCenterX, y = playerCenterY}, {x = mousex, y = mousey})
    local angle = utils.angleOfVector(vector)

    if not pulsedevice.onCooldown then
        -- Trajectory
        local alpha = 0.3 + (pulsedevice.holdTime / pulsedevice.maxHoldTime) * 0.7
        love.graphics.setColor(1, 0.2, 0.2, alpha)
        love.graphics.setLineWidth(1)
        love.graphics.line(playerCenterX, playerCenterY, playerCenterX + math.cos(angle)*80, playerCenterY + math.sin(angle)*80)
        
        -- Charge Bar
        if pulsedevice.holdTime > 0 then
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", player.x - 4, player.y - 10, 20, 4)
            love.graphics.setColor(1, 0.5, 0)
            love.graphics.rectangle("fill", player.x - 4, player.y - 10, 20 * (pulsedevice.holdTime/pulsedevice.maxHoldTime), 4)
        end
    end

    love.graphics.setColor(1, 1, 1)
    local dir = player.isFacingLeft and -1 or 1
    -- Flip the gun if facing left
    local gunAngle = angle
    local gunScaleY = 1
    if math.abs(angle) > math.pi/2 then gunScaleY = -1 end
    
    love.graphics.draw(pulsedevice.pulseDeviceSprites[1], playerCenterX, playerCenterY, gunAngle, 1, gunScaleY, 2, 5)

    -- Hits
    for i, hitspot in ipairs(pulsedevice.hitspots) do
        love.graphics.setColor(1, 0, 0, hitspot.life)
        love.graphics.circle("line", hitspot.x, hitspot.y, 15 * (1-hitspot.life))
    end
    love.graphics.setColor(1, 1, 1)
end

function pulsedevice.reset()
    pulsedevice.projectiles = {}
    pulsedevice.hitspots = {}
    pulsedevice.onCooldown = false
    pulsedevice.timeOfLastUse = 0
    pulsedevice.holdTime = 0
    pulsedevice.lastBlastEvent = 999
end

return pulsedevice