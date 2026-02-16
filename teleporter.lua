-- TELEPORTER GOIN UP!
-- teleporter.lua

-- we probably should have made a variable in each of the teles named isBuilt instead of relying on its position lol
-- i see how this could cause issues with, like, last second teles on destruction
local teleporter = {
    fps = 4,
    timeSinceLastFrame = 0,
    frameIndex = 1,
    entrance = { 
        x = -100, -- moves it off screen for neow
        y = -100, -- moves it off screen for neow
        width = 16,
        height = 16,
        building = false, -- if true, teleporter is in the process of being built and not functional
        buildStartTime = 0, -- time since player started building
        sprites = {
            love.graphics.newImage("assets/teleporter_entr_frames/tele_entr_frame_0.png"),
            love.graphics.newImage("assets/teleporter_entr_frames/tele_entr_frame_1.png"),
            love.graphics.newImage("assets/teleporter_entr_frames/tele_entr_frame_2.png"),
            love.graphics.newImage("assets/teleporter_entr_frames/tele_entr_frame_3.png"),
        },
    },
    exit = {
        x = -100,
        y = -100,
        width = 16,
        height = 16,
        building = false, -- if true, teleporter is in the process of being built and not functional
        buildStartTime = 0,
        sprites = {
            love.graphics.newImage("assets/teleporter_exit_frames/tele_exit_frame_0.png"),
            love.graphics.newImage("assets/teleporter_exit_frames/tele_exit_frame_1.png"),
            love.graphics.newImage("assets/teleporter_exit_frames/tele_exit_frame_2.png"),
            love.graphics.newImage("assets/teleporter_exit_frames/tele_exit_frame_3.png"),
        },
    },
    antiHold = false, -- if true, prevents game from mass building teles
    buildTime = 1.5, -- time from built to functional, draw a  red box around when building to show this?
}
local utils = require("utils")
function teleporter.load()
    love.graphics.setDefaultFilter("nearest", "nearest") -- necessary for pixel art to not be blurry
    
end
function teleporter.update(dt, player)
    if love.keyboard.isDown("q") and not teleporter.antiHold then
        -- teleporter goin up
        teleporter.entrance.x = player.x + 2 -- because the player is shorter than the tele by 2 pixels
        teleporter.entrance.y = player.y - 2 -- because the player is skinnier than the tele by 4 pixels
        teleporter.antiHold = true
        teleporter.entrance.building = true
        teleporter.entrance.buildStartTime = 0
    end
    if love.keyboard.isDown("e") and not teleporter.antiHold then
        -- teleporter goin up
        teleporter.exit.x = player.x + 2 -- same reason as entrance
        teleporter.exit.y = player.y - 2
        teleporter.exit.antiHold = true
        teleporter.exit.building = true
        teleporter.exit.buildStartTime = 0
    end
    if (not love.keyboard.isDown("q") and not love.keyboard.isDown("e")) then
        teleporter.antiHold = false
    end
    if teleporter.entrance.building then
        if teleporter.entrance.buildStartTime >= teleporter.buildTime then
            teleporter.entrance.building = false
        end
    end
    if teleporter.exit.building then
        if teleporter.exit.buildStartTime >= teleporter.buildTime then
            teleporter.exit.building = false
        end
    end
    teleporter.entrance.buildStartTime = teleporter.entrance.buildStartTime + dt
    teleporter.exit.buildStartTime = teleporter.exit.buildStartTime + dt

    teleporter.timeSinceLastFrame = teleporter.timeSinceLastFrame + dt
    if teleporter.timeSinceLastFrame >= 1 / teleporter.fps then
        teleporter.frameIndex = (teleporter.frameIndex % 4) + 1
        teleporter.timeSinceLastFrame = 0
    end
end
teleporter.teleportCheck = function(subject) -- do not use for map objects
    if utils.checkTouch(subject, teleporter.entrance) and teleporter.exit.x ~= -100 and teleporter.exit.y ~= -100 then
        print("teleporter.teleportCheck: subject touched entrance")
    else
        return false
    end
    if subject == nil then return false end
    if teleporter.entrance.building or teleporter.exit.building then
        return false
    end
    if subject.teleported == true then return false end -- projectiles can only be tp once
    if subject.teleported ~= nil then subject.teleported = true end
    if utils.checkTouch(subject, teleporter.entrance) and teleporter.exit.x ~= -100 and teleporter.exit.y ~= -100 then
        if teleporter.entrance.building or teleporter.exit.building then
            print("teleporter: attempted teleport while building, teleport cancelled")
            return false
        end
        local drawOffsetX = 0 -- if thing is facing left, make it tp to mid instead of right edge
        if subject.isFacingLeft then drawOffsetX = subject.width or 0 end
        subject.x = teleporter.exit.x + (teleporter.exit.width - (subject.width or 0)) / 2 - drawOffsetX
        subject.y = teleporter.exit.y + (teleporter.exit.height - (subject.height or 0)) / 2
        return true
    end
    return false
end
function teleporter.draw()
    -- draw entrance and exit if they are in use
    if teleporter.entrance.building then
        love.graphics.setColor(1, 0, 0) -- red tint if building
    else
        love.graphics.setColor(1, 1, 1) -- normal color if not building
    end
    local fi = teleporter.frameIndex or 1
    local entrSprite = teleporter.entrance.sprites[fi]
    local exitSprite = teleporter.exit.sprites[fi]
    print("teleporter.draw: frame", fi, "entr x,y", teleporter.entrance.x, teleporter.entrance.y, "entrSprite", entrSprite ~= nil)
    print("teleporter.draw: exit x,y", teleporter.exit.x, teleporter.exit.y, "exitSprite", exitSprite ~= nil)
    if entrSprite then love.graphics.draw(entrSprite, teleporter.entrance.x, teleporter.entrance.y) end

    if teleporter.exit.building then
        love.graphics.setColor(1, 0, 0) -- red tint if building
    else
        love.graphics.setColor(1, 1, 1) -- normal color if not building
    end
    if exitSprite then love.graphics.draw(exitSprite, teleporter.exit.x, teleporter.exit.y) end
    love.graphics.setColor(1, 1, 1) -- reset color
end

teleporter.destroy = function()
    teleporter.entrance.x = -100
    teleporter.entrance.y = -100
    teleporter.exit.x = -100
    teleporter.exit.y = -100
end

return teleporter
