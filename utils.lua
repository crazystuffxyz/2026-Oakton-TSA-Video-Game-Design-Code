-- utils.lua
-- framework - love2d

local utils = {}

function utils.isNaN(v)
    return type(v) == "number" and v ~= v
end

function utils.vector(obj1, obj2) 
    return {x = obj2.x - obj1.x, y = obj2.y - obj1.y}
end

function utils.magnitude(vector)
    return math.sqrt(vector.x^2 + vector.y^2)
end

function utils.unitVector(vector)
    local magnitude = utils.magnitude(vector)
    if magnitude == 0 then return {x = 0, y = 0} end
    return {x = vector.x / magnitude, y = vector.y / magnitude}
end

function utils.angleOfVector(vector)
    return math.atan2(vector.y, vector.x)
end

function utils.checkTouch(obj1, obj2)
    if not (obj1.x and obj1.y and obj2.x and obj2.y) then return false end
    
    local w1 = obj1.width or 0
    local h1 = obj1.height or 0
    local w2 = obj2.width or 0
    local h2 = obj2.height or 0

    return obj1.x < obj2.x + w2 and
           obj1.x + w1 > obj2.x and
           obj1.y < obj2.y + h2 and
           obj1.y + h1 > obj2.y
end

function utils.checkTouchWithTileMap(obj1, map, axisToCorrect)
    local returnTable = {
        touchingTile = false,
        isOnGround = false,
        headHitting = false,
        wallToLeft = false,
        wallToRight = false,
        isTouchingWinTile = false,
        isTouchingSpikeTile = false,
        isTouchingLadder = false,
        isWallSliding = false 
    }
    
    local tileDim = map.metadata.tileDimensions
    
    -- Optimization: Only check tiles around the player
    local startCol = math.floor(obj1.x / tileDim) - 1
    local endCol = math.floor((obj1.x + obj1.width) / tileDim) + 2
    local startRow = math.floor(obj1.y / tileDim) - 1
    local endRow = math.floor((obj1.y + obj1.height) / tileDim) + 2

    -- Clamp bounds
    startCol = math.max(1, startCol)
    startRow = math.max(1, startRow)
    endCol = math.min(#map.data[1], endCol)
    endRow = math.min(#map.data, endRow)

    for row = startRow, endRow do
        for col = startCol, endCol do
            local tileID = map.data[row][col]
            local tile = {
                x = (col - 1) * tileDim,
                y = (row - 1) * tileDim,
                width = tileDim,
                height = tileDim
            }

            if tileID == 8 then -- Spike
                -- Shrink hitbox of spike slightly to be forgiving
                local spikeHitbox = {x=tile.x+4, y=tile.y+4, width=8, height=8}
                if utils.checkTouch(obj1, spikeHitbox) then
                    returnTable.isTouchingSpikeTile = true
                end
            elseif tileID == 6 then -- Win
                if utils.checkTouch(obj1, tile) then
                    returnTable.isTouchingWinTile = true
                end
            elseif tileID == 4 then -- Ladder
                if utils.checkTouch(obj1, tile) then
                    returnTable.isTouchingLadder = true
                end
            end
            
            -- Solid blocks: 2 (Floating), 3 (Floor), 5 (Wall), 7 (Barrier)
            if tileID == 2 or tileID == 3 or tileID == 5 or tileID == 7 then
                 if utils.checkTouch(obj1, tile) then
                    returnTable.touchingTile = true
                    
                    local overlapX, overlapY
                    local pCenterX = obj1.x + obj1.width/2
                    local tCenterX = tile.x + tile.width/2
                    local pCenterY = obj1.y + obj1.height/2
                    local tCenterY = tile.y + tile.height/2
                    
                    local dx = tCenterX - pCenterX
                    local dy = tCenterY - pCenterY
                    
                    local combinedHalfWidths = (obj1.width + tile.width) / 2
                    local combinedHalfHeights = (obj1.height + tile.height) / 2
                    
                    if math.abs(dx) < combinedHalfWidths and math.abs(dy) < combinedHalfHeights then
                        overlapX = combinedHalfWidths - math.abs(dx)
                        overlapY = combinedHalfHeights - math.abs(dy)
                        
                        if axisToCorrect == "x" then
                             if overlapX < overlapY or overlapY > 2 then -- Biased towards X resolution
                                if dx > 0 then -- Tile is to the right
                                    obj1.x = obj1.x - overlapX
                                    returnTable.wallToRight = true
                                else
                                    obj1.x = obj1.x + overlapX
                                    returnTable.wallToLeft = true
                                end
                            end
                        elseif axisToCorrect == "y" then
                            -- Only correct Y if X is relatively resolved
                             if overlapY <= overlapX or overlapX > 0.5 then
                                if dy > 0 then -- Tile is below
                                    obj1.y = obj1.y - overlapY
                                    returnTable.isOnGround = true
                                else
                                    obj1.y = obj1.y + overlapY
                                    returnTable.headHitting = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return returnTable
end

return utils