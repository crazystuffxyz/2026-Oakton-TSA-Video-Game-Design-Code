-- player.lua
local player = {
    x = 160,
    y = 32,
    width = 12,
    height = 14, 
    xv = 0, 
    yv = 0,
    gravityStrength = 900,
    friction = 800,
    accel = 600,
    airAccel = 300,
    isOnGround = false,
    isOnLadder = false,
    isWallSliding = false,
    headHitting = false, 
    isRunning = false,
    isFacingLeft = false, 
    jumpInput = false,
    wasJumpInput = false,
    jumpBuffer = 0,
    coyoteTime = 0,
    jumpPower = 320,
    teleportCooldown = 0,
    scaleX = 1,
    scaleY = 1,
    wallJumpLock = 0,
    sprites = {
        love.graphics.newImage("assets/player.png"), -- idle
        love.graphics.newImage("assets/runframe1.png"), -- run1
        love.graphics.newImage("assets/runframe2.png"), -- run2
    },
    blasting = false, 
    timeSinceBlast = 0,
    deathCount = 0,
}
for _, s in ipairs(player.sprites) do s:setFilter("nearest","nearest") end

local teleporter = require("teleporter")
local utils = require("utils")
local map = require("map")
local fx = require("fx")

function player.load()
end

function player.startSquash(x, y)
    player.scaleX = x
    player.scaleY = y
end

function player.update(dt)
    -- Visual Squash Return
    player.scaleX = utils.isNaN(player.scaleX) and 1 or player.scaleX
    player.scaleY = utils.isNaN(player.scaleY) and 1 or player.scaleY
    player.scaleX = player.scaleX + (1 - player.scaleX) * 10 * dt
    player.scaleY = player.scaleY + (1 - player.scaleY) * 10 * dt

    -- Teleport Cooldown
    if player.teleportCooldown > 0 then
        player.teleportCooldown = player.teleportCooldown - dt
    end

    player.wallJumpLock = math.max(0, player.wallJumpLock - dt)

    -- Input
    if love.keyboard.isDown("w") or love.keyboard.isDown("space") then
        player.jumpInput = true
    else
        player.jumpInput = false
    end

    player.jumpBuffer = player.jumpBuffer - dt
    player.coyoteTime = player.coyoteTime - dt

    if player.jumpInput and not player.wasJumpInput then
        player.jumpBuffer = 0.15
    end
    
    local justPressedJump = player.jumpInput and not player.wasJumpInput
    player.wasJumpInput = player.jumpInput

    -- Blasting Logic
    if player.blasting then
        player.timeSinceBlast = player.timeSinceBlast + dt
        if player.timeSinceBlast > 0.5 and player.isOnGround then
            player.blasting = false
            player.timeSinceBlast = 0
        end
    end

    -- X Movement
    local moveDir = 0
    if love.keyboard.isDown("d") then moveDir = 1 end
    if love.keyboard.isDown("a") then moveDir = -1 end

    local currentAccel = player.isOnGround and player.accel or player.airAccel
    
    if moveDir ~= 0 then
        local applyDir = moveDir
        if player.wallJumpLock > 0 then
            applyDir = moveDir * 0.2
        end
        player.xv = player.xv + applyDir * currentAccel * dt
        player.isFacingLeft = (moveDir < 0)
        player.isRunning = true
    else
        player.isRunning = false
        local f = player.friction * dt
        if player.isOnLadder then f = f * 2 end 
        if player.wallJumpLock > 0 then f = f * 0.1 end
        if player.xv > 0 then
            player.xv = math.max(player.xv - f, 0)
        elseif player.xv < 0 then
            player.xv = math.min(player.xv + f, 0)
        end
    end

    -- Trail FX
    if player.isRunning and player.isOnGround and math.abs(player.xv) > 200 then
        if math.random() > 0.8 then
            fx.dust(player.x + player.width/2, player.y + player.height)
        end
    end

    -- Terminal Velocity
    local maxFall = 800
    local maxRun = player.blasting and 800 or 150
    player.xv = math.max(-maxRun, math.min(player.xv, maxRun))
    
    -- X Collision
    player.x = player.x + player.xv * dt
    local checkX = utils.checkTouchWithTileMap(player, map, "x")
    
    -- Wall Sliding / Jump
    local touchingWall = checkX.wallToLeft or checkX.wallToRight
    player.isWallSliding = touchingWall and not player.isOnGround and player.yv > 0 and not player.isOnLadder
    
    if player.isWallSliding then
        maxFall = 100 -- Slow fall
        if justPressedJump then
            player.yv = -player.jumpPower
            player.xv = checkX.wallToLeft and 400 or -400 -- Jump away from wall
            player.wallJumpLock = 0.25
            player.startSquash(0.7, 1.3)
            fx.dust(player.x, player.y)
        end
    end

    -- Physics Y
    if player.isOnLadder then
        player.yv = 0
        if love.keyboard.isDown("w") then player.yv = -100 end
        if love.keyboard.isDown("s") then player.yv = 100 end
        if justPressedJump then
            player.isOnLadder = false
            player.yv = -200
        end
    else
        player.yv = player.yv + player.gravityStrength * dt
    end
    
    player.yv = math.min(player.yv, maxFall)
    player.y = player.y + player.yv * dt
    
    local checkY = utils.checkTouchWithTileMap(player, map, "y")
    player.isOnGround = checkY.isOnGround
    player.headHitting = checkY.headHitting
    
    -- Ladder Check
    if checkY.isTouchingLadder then
        if love.keyboard.isDown("w") or love.keyboard.isDown("s") then
            player.isOnLadder = true
            player.blasting = false
        end
    else
        player.isOnLadder = false
    end
    
    if player.isOnGround then
        player.coyoteTime = 0.1
        player.blasting = false
        if player.yv > 0 then
            if player.yv > 200 then 
                player.startSquash(1.3, 0.7) 
                fx.dust(player.x + player.width/2, player.y + player.height)
            end
            player.yv = 0 
        end
    elseif player.headHitting and player.yv < 0 then
        player.yv = 0
    end

    -- Jump
    if player.jumpBuffer > 0 and player.coyoteTime > 0 and not player.isOnLadder then
        player.yv = -player.jumpPower
        player.jumpBuffer = 0
        player.coyoteTime = 0
        player.startSquash(0.7, 1.3)
        fx.dust(player.x + player.width/2, player.y + player.height)
    end

    -- Teleport & Level End
    teleporter.teleportCheck(player) 
    
    if checkY.isTouchingWinTile or checkX.isTouchingWinTile then
        map.nextLevel(player)
    end

    -- Spikes / Void
    if checkY.isTouchingSpikeTile or checkX.isTouchingSpikeTile or player.y > map.height * 16 + 100 then
        player.die()
    end
end

function player.die()
    fx.spawn(player.x + player.width/2, player.y + player.height/2, {1, 0, 0}, 40, 250)
    fx.shake(8, 0.4)
    player.deathCount = (player.deathCount or 0) + 1
    player.xv = 0
    player.yv = 0
    player.blasting = false
    player.isOnLadder = false
    teleporter.destroy()
    
    local pd = package.loaded["pulsedevice"]
    if pd then pd.reset() end
    
    map.resetLevel(player)
end

function player.draw()
    love.graphics.setColor(1, 1, 1)
    
    local spriteToDraw = player.sprites[1]
    if player.isRunning and player.isOnGround then
        if math.floor(love.timer.getTime() * 10) % 2 == 0 then
            spriteToDraw = player.sprites[2]
        else
            spriteToDraw = player.sprites[3]
        end
    end
    
    if player.isOnLadder then spriteToDraw = player.sprites[1] end -- Simple climb anim (idle)
    if not player.isOnGround and not player.isOnLadder then spriteToDraw = player.sprites[2] end

    local ox = player.width / 2
    local oy = player.height / 2
    local xx = player.x + ox
    local yy = player.y + oy

    local dir = player.isFacingLeft and -1 or 1
    
    love.graphics.draw(spriteToDraw, xx, yy, 0, dir * player.scaleX, player.scaleY, spriteToDraw:getWidth()/2, spriteToDraw:getHeight()/2)
end

return player