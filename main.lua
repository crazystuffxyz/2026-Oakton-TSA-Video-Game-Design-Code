-- main.lua 
-- framework - love2d
font = love.graphics.newFont("assets/pixelify_font/PixelifySans-VariableFont_wght.ttf", 32)
fontbutsmaller = love.graphics.newFont("assets/pixelify_font/PixelifySans-VariableFont_wght.ttf", 16)
 -- pixely font i found, licensed under open font license
scaleScreen = 2 -- game was too small ! DO NOT MAKE THIS LOCAL.  MOUSE LOGIC NEEDS THIS VALUE!!!!!!!!
local player = require("player") -- gets return of player.lua (which ofc is the player data and functions which i conveniently put in the list)
local utils = require("utils")
local map = require("map")
local pulsedevice = require("pulsedevice")
local teleporter = require("teleporter")
love.graphics.setDefaultFilter("nearest", "nearest") -- necessary for pixel art to not be blurry
function love.load()
    love.window.setMode(1024, 640, {resizable = false}) -- grid size, (0, 0) coord is top left
    player.load()
    teleporter.load()
    pulsedevice.load()
    love.graphics.setDefaultFilter("nearest", "nearest") -- necessary for pixel art to not be blurry
end


function love.update(dt)
    player.update(dt)  -- calls your player logic safely
    pulsedevice.update(dt)
    teleporter.update(dt, player)
end

function love.draw()
    font = love.graphics.newFont("assets/pixelify_font/PixelifySans-VariableFont_wght.ttf", 32)
    love.graphics.push()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.scale(scaleScreen, scaleScreen)
    love.graphics.clear(1,1,1)
    map.draw()
    teleporter.draw()
    player.draw()
    pulsedevice.draw()
    love.graphics.setFont(font)
    love.graphics.setColor(1,1,1)
        -- draw hitboxes of projectiles for debug
    for i, hitboxes in ipairs(pulsedevice.projectiles) do
        love.graphics.setColor(1,0,0)
        love.graphics.rectangle("line", hitboxes.x, hitboxes.y, hitboxes.width, hitboxes.height)
        love.graphics.setColor(1,1,1)
    end
    love.graphics.pop() -- resets text settings to the state when love.graphics.push() was ran
    -- random empty line
    love.graphics.setColor(.5,.5,.5)
    if map.metadata.currentLevel == 1 then
        love.graphics.print("Welcome to my platformer game!", 200, 200)
        love.graphics.setFont(fontbutsmaller)
        love.graphics.print("You can click to fire propulsion charges. \n Try firing one at your feet!", 500, 300)
        love.graphics.print("You can charge them, too! \n Try crossing this gap \n hint: You need more than 1 charge, \nand stronger charges are slower!!", 300, 400)
    end
    if map.metadata.currentLevel == 2 then
        love.graphics.print("Congrats on making it to part 2 of the tutorial! \n Now you shall learn about teleporters!", 200, 200)
        love.graphics.setFont(fontbutsmaller)
        love.graphics.print("Press Q to build a teleporter entrance, and E to build the exit. \n After a brief cooldown, they will be active! \n Try using them to beat this level! \n \n (Projectiles can only be teleported once)", 500, 300)
    end 
    love.graphics.setColor(0,0,0)
    love.graphics.setFond(fontbutsmaller)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Deaths: " .. tostring(player.deathCount or 0), 40, 40)
    love.graphics.setColor(1,1,1)
end

