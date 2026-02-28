-- main.lua
-- framework - love2d
scaleScreen = 2 

local player = require("player")
local utils = require("utils")
local map = require("map")
local pulsedevice = require("pulsedevice")
local teleporter = require("teleporter")
local fx = require("fx")
local camera = require("camera")
local burned = require("burned")

love.graphics.setDefaultFilter("nearest", "nearest")

local starfield = {}
gameState = "menu" -- "menu", "tutorial", "playing", "ending", "gameover"

function love.load()
    love.window.setMode(1024, 640, {resizable = true})
    love.window.setTitle("Mobility Jumper")
    
    -- Load Assets safely
    font = love.graphics.newFont("assets/pixelify_font/PixelifySans-VariableFont_wght.ttf", 32)
    fontSmall = love.graphics.newFont("assets/pixelify_font/PixelifySans-VariableFont_wght.ttf", 16)
    
    map.load()
    player.load()
    teleporter.load()
    pulsedevice.load()
    camera.load()
    
    -- Init Player
    player.x = map.playerStartX
    player.y = map.playerStartY
    
    -- Generate Stars
    for i=1, 150 do
        table.insert(starfield, {
            x = math.random(0, 2000),
            y = math.random(0, 2000),
            size = math.random(1, 2),
            speed = math.random(1, 5) * 0.1,
            blinkTimer = math.random() * math.pi * 2
        })
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        if gameState == "menu" then
            gameState = "tutorial"
        elseif gameState == "tutorial" then
            gameState = "playing"
            map.totalTimer = 0
            player.deathCount = 0
            player.gems = 0
            map.currentLevel = 1
            map.timeLeft = 1 * 60 -- 1 minute for Level 1
            map.load()
            map.resetLevel(player)
            local pd = package.loaded["pulsedevice"]
            if pd then pd.reset() end
            local tp = package.loaded["teleporter"]
            if tp then tp.destroy() end
        elseif gameState == "ending" then
            gameState = "menu"
        elseif gameState == "gameover" then
            gameState = "menu"
        end
    end
end

function love.update(dt)
    if dt > 0.1 then dt = 0.1 end 
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    camera.update(dt, player.x + player.width/2, player.y + player.height/2, map.width, map.height, screenW, screenH)
    fx.update(dt)

    if gameState == "playing" then
        map.levelTimer = map.levelTimer + dt
        map.totalTimer = map.totalTimer + dt
        map.timeLeft = map.timeLeft - dt

        if map.timeLeft <= 0 then
            gameState = "gameover"
            local pd = package.loaded["pulsedevice"]
            if pd then pd.reset() end
            local tp = package.loaded["teleporter"]
            if tp then tp.destroy() end
            return
        end
        
        player.update(dt)
        pulsedevice.update(dt)
        teleporter.update(dt, player)
        burned.update(dt, player)
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1) -- Deep Space
    
    local t = love.timer.getTime()
    -- Draw Stars (Parallax)
    for _, star in ipairs(starfield) do
        local px = (star.x - camera.x * star.speed) % (love.graphics.getWidth() / camera.scale + 200)
        local py = (star.y - camera.y * star.speed) % (love.graphics.getHeight() / camera.scale + 200)
        
        local alpha = 0.5 + math.sin(t * 2 + star.blinkTimer) * 0.5
        love.graphics.setColor(1, 1, 1, alpha)
        
        love.graphics.rectangle("fill", px * camera.scale, py * camera.scale, star.size, star.size)
    end
    
    if gameState == "playing" then
        camera.set()
            fx.applyShake()
            
            map.draw()
            teleporter.draw()
            player.draw()
            burned.draw()
            pulsedevice.draw()
            fx.draw()
        camera.unset()
        
        -- UI Layer
        if font and fontSmall then
            love.graphics.setFont(font)
            love.graphics.setColor(1,1,1)
            
            -- HUD
            love.graphics.print("Level: " .. (map.metadata and map.metadata.name or ""), 20, 20)
            
            love.graphics.setFont(fontSmall)
            love.graphics.print("Deaths: " .. tostring(player.deathCount), 20, 60)
            love.graphics.print("Level Gems: " .. tostring(map.levelGemsCollected) .. " / " .. tostring(map.totalGems), 20, 80)
            love.graphics.print("Total Gems: " .. tostring(player.gems), 20, 100)
            love.graphics.print(string.format("Level Time: %.2f", map.levelTimer), 20, 120)
            love.graphics.print(string.format("Total Time: %.2f", map.totalTimer), 20, 140)

            -- Timer UI
            local timeColor = {1, 1, 1}
            if map.timeLeft < 10 then
                timeColor = {1, 0, 0}
            elseif map.timeLeft < 30 then
                timeColor = {1, 1, 0}
            end
            love.graphics.setColor(timeColor[1], timeColor[2], timeColor[3])
            local mins = math.max(0, math.floor(map.timeLeft / 60))
            local secs = math.max(0, math.floor(map.timeLeft % 60))
            love.graphics.print(string.format("Time Left: %d:%02d", mins, secs), 20, 160)
            love.graphics.setColor(1, 1, 1)
            
            -- Cooldown bar for teleporter maybe?
            if player.teleportCooldown > 0 then
                love.graphics.setColor(0, 1, 1)
                love.graphics.rectangle("fill", 20, 190, 50 * player.teleportCooldown, 5)
            end
            
            -- Tutorial Text
            if map.currentLevel == 1 then
                 love.graphics.print("Controls: WASD to move/jump, R to reset", 400, 500)
            end
        end

    elseif gameState == "menu" then
        if font and fontSmall then
            love.graphics.setFont(font)
            love.graphics.setColor(1, 1, 1)
            local title = "Pulse Man - RECHARGED"
            local titleW = font:getWidth(title)
            love.graphics.print(title, love.graphics.getWidth()/2 - titleW/2, love.graphics.getHeight()/3)
            
            love.graphics.setFont(fontSmall)
            local msg = "Click anywhere to Start"
            local msgW = fontSmall:getWidth(msg)
            love.graphics.setColor(0, 1, 1, 0.5 + math.sin(love.timer.getTime()*4)*0.5)
            love.graphics.print(msg, love.graphics.getWidth()/2 - msgW/2, love.graphics.getHeight()/2)
        end
        
    elseif gameState == "tutorial" then
        if font and fontSmall then
            love.graphics.setFont(font)
            love.graphics.setColor(1, 1, 1)
            local title = "TUTORIAL"
            local titleW = font:getWidth(title)
            love.graphics.print(title, love.graphics.getWidth()/2 - titleW/2, 100)
            
            love.graphics.setFont(fontSmall)
            local lines = {
                "A / D : Move Left / Right",
                "W / Space : Jump",
                "Hold Left Click : Charge Pulse",
                "Release Left Click : Fire Pulse to break walls or blast jump!",
                "Q : Place Teleporter Entrance",
                "E : Place Teleporter Exit",
                "Walk into Teleporter to travel instantly (0.5s cooldown)",
                "R : Restart Level",
                "",
                "Collect ALL GEMS to unlock the exit door (!)",
                "Avoid spikes and bottomless pits!",
                "Beware the 'Burned' who complain every time you hit something.",
                "Watch your Timer! Every second wasted will never be restored.",
                "",
                "Click anywhere to Play"
            }
            for i, line in ipairs(lines) do
                local w = fontSmall:getWidth(line)
                love.graphics.print(line, love.graphics.getWidth()/2 - w/2, 160 + i * 25)
            end
        end

    elseif gameState == "gameover" then
        if font and fontSmall then
            love.graphics.setFont(font)
            love.graphics.setColor(1, 0.2, 0.2)
            local title = "OUT OF TIME"
            local titleW = font:getWidth(title)
            love.graphics.print(title, love.graphics.getWidth()/2 - titleW/2, love.graphics.getHeight()/3)
            
            love.graphics.setFont(fontSmall)
            love.graphics.setColor(1, 1, 1)
            local msg1 = "Every second wasted will never be restored..."
            local msg1W = fontSmall:getWidth(msg1)
            love.graphics.print(msg1, love.graphics.getWidth()/2 - msg1W/2, love.graphics.getHeight()/2)

            local msg2 = "Click anywhere to return to Menu"
            local msg2W = fontSmall:getWidth(msg2)
            love.graphics.print(msg2, love.graphics.getWidth()/2 - msg2W/2, love.graphics.getHeight()/2 + 40)
        end
        
    elseif gameState == "ending" then
        if font and fontSmall then
            love.graphics.setFont(font)
            love.graphics.setColor(1, 1, 1)
            local title = "YOU WIN!"
            local titleW = font:getWidth(title)
            love.graphics.print(title, love.graphics.getWidth()/2 - titleW/2, 100)
            
            love.graphics.setFont(fontSmall)
            local stats = {
                "Total Time: " .. string.format("%.2f", map.totalTimer) .. " seconds",
                "Total Deaths: " .. tostring(player.deathCount),
                "Total Gems Collected: " .. tostring(player.gems),
                "",
                "Click anywhere to Play Again"
            }
            for i, line in ipairs(stats) do
                local w = fontSmall:getWidth(line)
                love.graphics.print(line, love.graphics.getWidth()/2 - w/2, 200 + i * 30)
            end
        end
    end
end