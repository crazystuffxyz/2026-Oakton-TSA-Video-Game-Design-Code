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

love.graphics.setDefaultFilter("nearest", "nearest")

local starfield = {}

function love.load()
    love.window.setMode(1024, 640, {resizable = true})
    love.window.setTitle("Pulse Man - RECHARGED")
    
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

function love.update(dt)
    if dt > 0.1 then dt = 0.1 end 
    
    map.levelTimer = map.levelTimer + dt
    map.totalTimer = map.totalTimer + dt
    
    player.update(dt)
    pulsedevice.update(dt)
    teleporter.update(dt, player)
    fx.update(dt)
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    camera.update(dt, player.x + player.width/2, player.y + player.height/2, map.width, map.height, screenW, screenH)
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
    
    camera.set()
        fx.applyShake()
        
        map.draw()
        teleporter.draw()
        player.draw()
        pulsedevice.draw()
        fx.draw()
    camera.unset()
    
    -- UI Layer
    love.graphics.setFont(font)
    love.graphics.setColor(1,1,1)
    
    -- HUD
    love.graphics.print("Level: " .. map.metadata.name, 20, 20)
    
    love.graphics.setFont(fontSmall)
    love.graphics.print("Deaths: " .. tostring(player.deathCount), 20, 60)
    love.graphics.print(string.format("Level Time: %.2f", map.levelTimer), 20, 80)
    love.graphics.print(string.format("Total Time: %.2f", map.totalTimer), 20, 100)
    
    -- Cooldown bar for teleporter maybe?
    if player.teleportCooldown > 0 then
        love.graphics.setColor(0, 1, 1)
        love.graphics.rectangle("fill", 20, 130, 50 * player.teleportCooldown, 5)
    end
    
    -- Tutorial Text
    local tutoText = map.metadata.name
    if map.currentLevel == 1 then
         love.graphics.print("Controls: WASD + Space", 400, 500)
    end
end