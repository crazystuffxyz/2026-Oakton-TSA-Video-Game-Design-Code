-- camera.lua
local camera = {
    x = 0,
    y = 0,
    scale = 2, 
    smoother = 10,
    lookAheadX = 0,
    lookAheadY = 0
}

function camera.load()
end

function camera.update(dt, targetX, targetY, mapWidth, mapHeight, screenWidth, screenHeight)
    -- Lookahead based on mouse position relative to center
    local mx, my = love.mouse.getPosition()
    local cx, cy = screenWidth / 2, screenHeight / 2
    
    local dx = (mx - cx) / screenWidth
    local dy = (my - cy) / screenHeight
    
    camera.lookAheadX = camera.lookAheadX + (dx * 100 - camera.lookAheadX) * 2 * dt
    camera.lookAheadY = camera.lookAheadY + (dy * 100 - camera.lookAheadY) * 2 * dt

    local tx = targetX - (screenWidth / camera.scale) / 2 + camera.lookAheadX
    local ty = targetY - (screenHeight / camera.scale) / 2 + camera.lookAheadY
    
    -- Bounds checking
    if mapWidth * 16 > screenWidth / camera.scale then
        tx = math.max(0, math.min(tx, mapWidth * 16 - screenWidth / camera.scale))
    else
        tx = -(screenWidth / camera.scale - mapWidth * 16) / 2
    end
    
    if mapHeight * 16 > screenHeight / camera.scale then
        ty = math.max(0, math.min(ty, mapHeight * 16 - screenHeight / camera.scale))
    else
        ty = -(screenHeight / camera.scale - mapHeight * 16) / 2
    end

    camera.x = camera.x + (tx - camera.x) * camera.smoother * dt
    camera.y = camera.y + (ty - camera.y) * camera.smoother * dt
end

function camera.set()
    love.graphics.push()
    love.graphics.scale(camera.scale, camera.scale)
    love.graphics.translate(-camera.x, -camera.y)
end

function camera.unset()
    love.graphics.pop()
end

function camera.getMouseWorldPos()
    local mx, my = love.mouse.getPosition()
    return (mx / camera.scale) + camera.x, (my / camera.scale) + camera.y
end

return camera