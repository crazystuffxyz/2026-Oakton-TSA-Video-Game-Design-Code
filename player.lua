-- player.lua
-- framework - love2d
local player = {
    x = 160,
    y = 32,
    width = 12,
    height = 14, 
    xv = 0, -- xvelocity
    yv = 0,
    gravityStrength = 900,
    velocitySlowdownRate = 500,
    isOnGround = false,
    isWallSliding = false,
    headHitting = false, -- if true sets yvelo to 0
    isRunning = false,
    isFacingLeft = false, -- mainly used for drawing sprites.
    wallToLeft = false,
    wallToRight = false,
    accel = 256,
    horizontalTerminalVelo = 120,
    verticalTerminalVelo = 1200,
    alive = true,
    jumpInput = false,
    jumpPower = 1200,
    sprites = {
        (function() local img = love.graphics.newImage("assets/player.png"); img:setFilter("nearest", "nearest"); return img end)(), -- idle
        (function() local img = love.graphics.newImage("assets/runframe1.png"); img:setFilter("nearest", "nearest"); return img end)(), -- runframe 1
        (function() local img = love.graphics.newImage("assets/runframe2.png"); img:setFilter("nearest", "nearest"); return img end)(), -- runframe 2
    },
    lastClipEvent = 1,
    blasting = false, -- temporarily ignores terminalvelos
    timeSinceBlast = 0,
    blastHorizontalTerminalVelo = 200,
    blastVerticalTerminalVelo = 355,
    deathCount = 0,
}
local teleporter = require("teleporter")
local utils = require("utils")
local map = require("map")
function player.load()
    love.window.setTitle("TSA PROJECT: Pulse Man")
    -- setDefaultFilter handled globally in main.lua
end

function player.update(dt)
    if love.keyboard.isDown("w") then
        player.jumpInput = true
    else
        player.jumpInput = false
    end
    if player.blasting then
        player.timeSinceBlast = player.timeSinceBlast + dt
        player.horizontalTerminalVelo = player.blastHorizontalTerminalVelo
        player.verticalTerminalVelo = player.blastVerticalTerminalVelo
    else
        player.horizontalTerminalVelo = 120
        player.verticalTerminalVelo = 200
    end
    player.lastClipEvent = player.lastClipEvent + dt
    player.x = player.x + player.xv * dt
    checkTouchResultsX = utils.checkTouchWithTileMap(player, map, "x") -- fix x
    if checkTouchResultsX.wallToLeft or checkTouchResultsX.wallToRight then
        player.xv = 0
    end
    if checkTouchResultsX.isOnGround then
        player.blasting = false -- if you blast into the ground, you stop blasting and return to normal terminal velocity
    end
    player.y = player.y + player.yv * dt
    checkTouchResultsY = utils.checkTouchWithTileMap(player, map, "y") -- fix y
    if checkTouchResultsY.headHitting or checkTouchResultsY.isOnGround then
        player.blasting = false
    end
    if player.jumpInput and checkTouchResultsY.isOnGround then
        player.yv = -player.jumpPower
    end
    if player.headHitting then
        if player.yv ~= 0 then
        end
        player.yv = 0
    end

    if player.x < 0 then
        player.x = map.playerStartX or 64
        player.y = map.playerStartY or 64
        player.lastClipEvent = 0
    end
    if player.y < 0 then
        player.x = map.playerStartX or 64
        player.y = map.playerStartY or 64
        player.lastClipEvent = 0
    end
    teleporter.teleportCheck(player) -- attempt teleportation
    local checkTouchResults = utils.checkTouchWithTileMap(player, map, "y")
    if checkTouchResults.isTouchingWinTile then
        teleporter.destroy()
        local puldev = package.loaded["pulsedevice"]
        if puldev and puldev.reset then
            puldev.reset()
        end

        print("winned level" .. tostring(map.metadata.currentLevel))
        map.metadata.currentLevel = map.metadata.currentLevel + 1

        for i = 1, #map.levels[map.metadata.currentLevel] do
            map.data[i] = map.levels[map.metadata.currentLevel][i] -- so it doesnt affect metadata... i should have put the map in its own table
                                                              -- but its far too tedious to chnge now, maybe if we have time
        end
        map.playerStartX = map.levels[map.metadata.currentLevel].playerStartX or 64
        map.playerStartY = map.levels[map.metadata.currentLevel].playerStartY or 64
        player.x = map.playerStartX or 64 -- sets player start pos for new level
        player.y = map.playerStartY or 64 -- 64 is default if not specified (top left corner, (5, 5) if u think of it as coords)
        -- level complete logic here later
    end
    if checkTouchResults.touchingTile then
        player.isOnGround = checkTouchResults.isOnGround
        player.headHitting = checkTouchResults.headHitting
        player.isWallSliding = checkTouchResults.isWallSliding
        player.wallToLeft = checkTouchResults.wallToLeft or false
        player.wallToRight = checkTouchResults.wallToRight or false
    else
        player.isOnGround = false
        player.headHitting = false
        player.isWallSliding = false
        player.wallToLeft = false
        player.wallToRight = false
    end
    if player.isOnGround then
        player.yv = 0 
    end
    if player.wallToLeft then
        player.xv = math.min(player.xv, 0)
    end
    if player.wallToRight then
        player.xv = math.max(player.xv, 0)
    end
    if not player.isOnGround then -- only apply gravity if not on ground, or else jittering due to overlap adjustment
        player.yv = math.min(player.yv + player.gravityStrength * dt, player.verticalTerminalVelo)
    end
    if player.isWallSliding then
        player.yv = math.min(player.yv, player.gravityStrength / 2) -- yo i figured out how op math.min is :)
    end
    if not false then -- unnecessary loop i forgor to delete, used to be not player.headHitting but was unnecessary and not the source of the bug like i thought, and im too lazy to delete it
        if love.keyboard.isDown("d") and not player.wallToRight and player.timeSinceBlast > 0.1 then -- and not wall to right removes jittering
            player.xv = math.min(player.xv + player.accel * dt, player.horizontalTerminalVelo)
            player.isFacingLeft = false
            player.isRunning = true
        elseif love.keyboard.isDown("a") and not player.wallToLeft and player.timeSinceBlast > 0.1 then
            player.xv = math.max(player.xv - player.accel * dt, -player.horizontalTerminalVelo)
            player.isFacingLeft = true
            player.isRunning = true
        else
            if player.xv > 0 then
                player.xv = math.max(player.xv - player.velocitySlowdownRate * dt, 0)
            elseif player.xv < 0 then
                player.xv = math.min(player.xv + player.velocitySlowdownRate * dt, 0)
            end
            player.isRunning = false
        end
    end
    if checkTouchResults.isTouchingSpikeTile then
        player.deathCount = (player.deathCount or 0) + 1
        player.x = map.playerStartX or 64 -- resets player to start pos for level
        player.y = map.playerStartY or 64
        player.xv = 0
        player.yv = 0
    end

    player.yv = math.min(player.yv, player.verticalTerminalVelo)
    player.yv = math.max(player.yv, -player.verticalTerminalVelo)
    player.xv = math.min(player.xv, player.horizontalTerminalVelo)
    player.xv = math.max(player.xv, -player.horizontalTerminalVelo)
    -- i hate printing tables in lua
    -- print(player.x, player.y, "xv ".. player.xv, "yv ".. player.yv, "isOnGround ".. tostring(player.isOnGround), "isWallSliding ".. tostring(player.isWallSliding), "wallToLeft ".. tostring(player.wallToLeft), "wallToRight ".. tostring(player.wallToRight))
    -- that line cause crash on my computer
end

function player.draw()
    if player.blasting then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("line", player.x, player.y, player.width, player.height)
    end
    love.graphics.setColor(1, 1, 1)
    if player.lastClipEvent <= 1 then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("Whoops, sorry about that!", player.x - 20, player.y - 20)
        love.graphics.setColor(1, 1, 1)
    end
    local sx = 1
    local offsetx = 0
    local spriteToDraw = player.sprites[1]
    local frameChangeRate = 3
    if player.isRunning then
        if math.floor(love.timer.getTime() * frameChangeRate) % 3 == 0 then
            spriteToDraw = player.sprites[2]
        else
            spriteToDraw = player.sprites[3]
        end
    end
    if player.isFacingLeft then
        sx = -1
        offsetx = player.width
    end
    love.graphics.draw(spriteToDraw, player.x + offsetx, player.y, 0, sx, 1)
end

return player
