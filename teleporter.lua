-- teleporter.lua
local teleporter = {
    fps = 4,
    timeSinceLastFrame = 0,
    frameIndex = 1,
    entrance = { x = -999, y = -999, width = 16, height = 16, building = false, buildStartTime = 0 },
    exit = { x = -999, y = -999, width = 16, height = 16, building = false, buildStartTime = 0 },
    antiHold = false,
    buildTime = 0.5, 
    spritesEntr = {},
    spritesExit = {}
}

local utils = require("utils")
local fx = require("fx")

function teleporter.load()
    for i=0,3 do
        table.insert(teleporter.spritesEntr, love.graphics.newImage("assets/teleporter_entr_frames/tele_entr_frame_"..i..".png"))
        table.insert(teleporter.spritesExit, love.graphics.newImage("assets/teleporter_exit_frames/tele_exit_frame_"..i..".png"))
    end
end

function teleporter.update(dt, player)
    -- Input
    if love.keyboard.isDown("q") and not teleporter.antiHold then
        teleporter.entrance.x = player.x 
        teleporter.entrance.y = player.y
        teleporter.antiHold = true
        teleporter.entrance.building = true
        teleporter.entrance.buildStartTime = 0
        fx.spawn(player.x, player.y, {0,1,1}, 10, 50)
    end
    if love.keyboard.isDown("e") and not teleporter.antiHold then
        teleporter.exit.x = player.x
        teleporter.exit.y = player.y
        teleporter.antiHold = true
        teleporter.exit.building = true
        teleporter.exit.buildStartTime = 0
        fx.spawn(player.x, player.y, {1,0.5,0}, 10, 50)
    end
    if (not love.keyboard.isDown("q") and not love.keyboard.isDown("e")) then
        teleporter.antiHold = false
    end

    -- Building logic
    if teleporter.entrance.building then
        teleporter.entrance.buildStartTime = teleporter.entrance.buildStartTime + dt
        if teleporter.entrance.buildStartTime >= teleporter.buildTime then teleporter.entrance.building = false end
    end
    if teleporter.exit.building then
        teleporter.exit.buildStartTime = teleporter.exit.buildStartTime + dt
        if teleporter.exit.buildStartTime >= teleporter.buildTime then teleporter.exit.building = false end
    end

    -- Animation
    teleporter.timeSinceLastFrame = teleporter.timeSinceLastFrame + dt
    if teleporter.timeSinceLastFrame >= 1 / teleporter.fps then
        teleporter.frameIndex = (teleporter.frameIndex % 4) + 1
        teleporter.timeSinceLastFrame = 0
    end
end

function teleporter.teleportCheck(subject)
    if not subject then return end
    
    -- Countdown cooldown
    if subject.teleportCooldown and subject.teleportCooldown > 0 then
        return
    end

    if teleporter.entrance.building or teleporter.exit.building then return end
    
    local validEntrance = teleporter.entrance.x > -100
    local validExit = teleporter.exit.x > -100
    
    if not validEntrance or not validExit then return end

    -- Check Entry -> Exit
    if utils.checkTouch(subject, teleporter.entrance) then
        subject.x = teleporter.exit.x
        subject.y = teleporter.exit.y
        subject.teleportCooldown = 0.3 
        fx.spawn(subject.x, subject.y, {0, 1, 1}, 20, 100)
        fx.shake(3, 0.1)
    end
    
    -- Check Exit -> Entry (Two way)
    if utils.checkTouch(subject, teleporter.exit) then
        subject.x = teleporter.entrance.x
        subject.y = teleporter.entrance.y
        subject.teleportCooldown = 0.3
        fx.spawn(subject.x, subject.y, {1, 0.5, 0}, 20, 100)
        fx.shake(3, 0.1)
    end
end

function teleporter.draw()
    local fi = teleporter.frameIndex
    
    if teleporter.entrance.x > -100 then
        if teleporter.entrance.building then love.graphics.setColor(1,0,0,0.5) else love.graphics.setColor(1,1,1) end
        love.graphics.draw(teleporter.spritesEntr[fi], teleporter.entrance.x, teleporter.entrance.y)
    end
    
    if teleporter.exit.x > -100 then
        if teleporter.exit.building then love.graphics.setColor(1,0,0,0.5) else love.graphics.setColor(1,1,1) end
        love.graphics.draw(teleporter.spritesExit[fi], teleporter.exit.x, teleporter.exit.y)
    end
    
    -- Draw Link Line if both exist
    if teleporter.entrance.x > -100 and teleporter.exit.x > -100 then
        local alpha = 0.2 + (math.sin(love.timer.getTime() * 5) + 1) * 0.2
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.line(teleporter.entrance.x+8, teleporter.entrance.y+8, teleporter.exit.x+8, teleporter.exit.y+8)
    end
    love.graphics.setColor(1,1,1)
end

function teleporter.destroy()
    teleporter.entrance.x = -999
    teleporter.exit.x = -999
end

return teleporter