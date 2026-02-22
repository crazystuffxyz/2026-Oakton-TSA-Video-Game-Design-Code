-- pulsedevice.lua
-- framework - love2d
-- i know it looks like a gun, but no its not. a gun is a weapon, this is a mobility tool. 
-- fires harmless projectiles that launch the player towards them on impact
local pulsedevice = {
    power = 10,
    projectiles = {},
    speed = 500,
    lastBlastEvent = 0,
    onCooldown = false,
    cooldownTime = .625, -- in seconds
    timeOfLastUse = 0,
    holdTime = 0, -- for future use if i want to add charge up or something
    maxHoldTime = 1.5, -- max charge
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
pulsedevice.hitspots = {} -- for debug drawing where projectiles hit
-- m1 to launch btw
-- literally soldiers rocket jumping from tf2, replaces jumping in this game
-- player can control direction when launched, but not speed (not final) - note: they can now :)
function pulsedevice.load()
    love.graphics.setDefaultFilter("nearest", "nearest") -- necessary for pixel art to not be blurry
end
function pulsedevice.update(dt)
    pulsedevice.lastBlastEvent = pulsedevice.lastBlastEvent + dt
    if pulsedevice.lastBlastEvent <= .3 then
        player.blasting = true
    end
    local mousex, mousey = love.mouse.getPosition()
    local scale = (scaleScreen or 1)
    mousex = mousex / scale
    mousey = mousey / scale
    local playerCenterX = player.x + player.width / 2
    local playerCenterY = player.y + player.height / 2
    if love.mouse.isDown(1) and not pulsedevice.onCooldown then
        pulsedevice.holdTime = math.max(.5, math.min(pulsedevice.holdTime + dt, pulsedevice.maxHoldTime))
    end
    if not love.mouse.isDown(1) and pulsedevice.holdTime > 0 then
        local vector = utils.vector({x = playerCenterX, y = playerCenterY}, {x = mousex, y = mousey})
        local unitVector = utils.unitVector(vector)
        print("mousepos = ", mousex, mousey, "playerpos = ", playerCenterX, playerCenterY)
        print("vector = ", vector.x, vector.y, "unitv = ", unitVector.x, unitVector.y, "angle=", utils.angleOfVector(vector))
        local projectileSprite = pulsedevice.projectileSprites[1]
        local projectilew = projectileSprite:getWidth()
        local projectile = {
            x = playerCenterX,
            y = playerCenterY,
            xv = unitVector.x * pulsedevice.speed /(6 * pulsedevice.holdTime), -- the longer u hold it the slower
            yv = unitVector.y * pulsedevice.speed /(6 * pulsedevice.holdTime), -- + strategy
            angle = utils.angleOfVector(vector),
            width = 1,
            height = 1, -- so it doesnt hit really high if aimed at feet (plan to make this on the vector side later)
            holdTime = pulsedevice.holdTime,
            teleported = false, -- projectiles can only be tp once to prevent particle accelerators
        }
        table.insert(pulsedevice.projectiles, projectile)
        pulsedevice.onCooldown = true
        pulsedevice.timeOfLastUse = 0
        pulsedevice.holdTime = 0
    end
    pulsedevice.timeOfLastUse = pulsedevice.timeOfLastUse + dt
    if pulsedevice.onCooldown and pulsedevice.timeOfLastUse >= pulsedevice.cooldownTime then
        pulsedevice.onCooldown = false
    end
    for i, projectile in ipairs(pulsedevice.projectiles) do
        teleporter.teleportCheck(projectile) -- attempt teleportation for projectiles too
        projectile.x = projectile.x + projectile.xv * dt
        projectile.y = projectile.y + projectile.yv * dt
        if utils.checkTouchWithTileMap(projectile, map).touchingTile then
            --logic
            player.blasting = true
            local vector = utils.vector({x = projectile.x, y = projectile.y}, {x = playerCenterX, y = playerCenterY})
            local vectorMagnitude = math.max(utils.magnitude(vector), 35) -- require a min distance to avoid very powerful launches
            local launchStrength = math.min(200, 6000 / (vectorMagnitude/2)) -- reduce strength falloff the /2
            local unitVector = utils.unitVector(vector)
            player.xv = player.xv + unitVector.x * launchStrength * projectile.holdTime * 3-- just because
            player.yv = player.yv + unitVector.y * launchStrength * projectile.holdTime * 3.5 -- make it stronger vertically to counteract gravity better
            --remove
            table.insert(pulsedevice.hitspots, {x = projectile.x, y = projectile.y})
            table.remove(pulsedevice.projectiles, i)
            pulsedevice.lastBlastEvent = 0
        end
    end
end
function pulsedevice.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", player.x + 18, player.y, 6, 20, -1) -- charge bar frame, just a visual indicator of how long u held it
    love.graphics.rectangle("fill", player.x + 18, player.y, 6, 20 * (pulsedevice.holdTime / pulsedevice.maxHoldTime), -1) -- charge bar fill
    -- the pulse device shall point to ze cursour!
    local mousex, mousey = love.mouse.getPosition()
    local scale = (scaleScreen or 1)
    mousex = mousex / scale
    mousey = mousey / scale
    local playerCenterX = player.x + player.width / 2
    local playerCenterY = player.y + player.height / 2
    local vector = utils.vector({x = playerCenterX, y = playerCenterY}, {x = mousex, y = mousey})
    local angle = utils.angleOfVector(vector)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(pulsedevice.pulseDeviceSprites[1], playerCenterX, playerCenterY, angle, .5, .5, pulsedevice.pulseDeviceSprites[1]:getWidth()/2, pulsedevice.pulseDeviceSprites[1]:getHeight()/2)
    love.graphics.setColor(1, 1, 1, 1) -- reset
    --draw the projectiles:
    for i, projectile in ipairs(pulsedevice.projectiles) do

        love.graphics.draw(pulsedevice.projectileSprites[1], projectile.x, projectile.y, projectile.angle, 1, 1)
        -- api for love.graphics.draw(image, x, y, r, sx, sy, ox, oy, kx, ky)
    end
    -- draw rectangle at hitspots for debug
    for i, hitspot in ipairs(pulsedevice.hitspots) do
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", hitspot.x - 1, hitspot.y - 1, 2, 2)
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
