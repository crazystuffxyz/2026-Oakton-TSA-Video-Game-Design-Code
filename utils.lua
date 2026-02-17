-- utils.lua
-- framework - love2d

local utils = {}
function utils.isNaN(checkVal) -- Not used, might be useful
    return checkVal ~= checkVal
end
function utils.scale(vector, factor) -- scales vector
    return {
        vector.x * factor, vector.y*factor
    }
end
function utils.vector(obj1, obj2) -- REMEMBER: object 1 is the initial point and object 2 is the final point, order matters here
    return {x = obj2.x - obj1.x, y = obj2.y - obj1.y}
end -- vector = magnitude + direction (essentially a glorified line segment that starts from the origin)
function utils.magnitude(vector) -- ripoff pythagorean theorem (length of vector)
    return math.sqrt(vector.x^2 + vector.y^2)
end
function utils.unitVector(vector) -- turns vector into a vector with magnitude 1 (the unit vector)
    local magnitude = utils.magnitude(vector)
    if magnitude == 0 then return {x = 0, y = 0} end
    return {x = vector.x / magnitude, y = vector.y / magnitude}
end
function utils.angleOfVector(vector) -- gets angle of vector
    return math.atan2(vector.y, vector.x)
end
function utils.checkTouch(obj1, obj2) -- basic AABB collision
    if not (obj1.x and obj1.y) then
        error("double check obj1 parameter") -- error() halts the program if not wrapped in pcall (powerful but less necessary in local games that dont have to deal with (inherently unreliable) data sending)
    end
    if not (obj2.x and obj2.y) then
        error("double check obj2 parameter")
    end
    if (obj1.width == nil or obj1.height == nil) then print("obj1 in checkTouch is missing width or height, using 0") end
    if (obj2.width == nil or obj2.height == nil) then print("obj2 in checkTouch is missing width or height, using 0") end
    return obj1.x < obj2.x + (obj2.width or 0) and -- this one checks if the left side of obj1 is to the left of the right sid of obj2
        obj1.y < obj2.y + (obj2.height or 0) and   -- this one checks if the top side of obj1 is above the bottom side of obj2
        obj2.x < obj1.x + (obj1.width or 0) and    -- this one checks if the right side of obj1 is to the right of the left side of obj2
        obj2.y < obj1.y + (obj1.height or 0)       -- this one checks if the bottom side of obj1 is below the top side of obj2
end

function utils.checkTouchWithTileMap(obj1, map, axisToCorrect) -- obj1 is intended for player, could break if smth else please program it to support any object with x,y,width,height
    local returnTable = {
        touchingTile = false,
        isOnGround = false,
        isWallSliding = false,
        headHitting = false,
        wallToLeft = false,
        wallToRight = false,
        isTouchingWinTile = false,
        isTouchingSpikeTile = false,
    }
    local tileDim = map.metadata.tileDimensions -- tile is square
    for row = 1, #map do
        for col = 1, #map[row] do
            if map[row][col] == 8 then -- ZESPIKETILE - the stuff medics touch at 99% ubercharge
                local spikeTile = {
                    x = (col - 1) * tileDim,
                    y = (row - 1) * tileDim,
                    width = tileDim,
                    height = tileDim,
                }
                if utils.checkTouch(obj1, spikeTile) then
                    returnTable.isTouchingSpikeTile = true -- we only want it to do something if PLAYER touches it, not projectiles
                end
            end
            if map[row][col] == 6 then -- WINTILE
                local winTile = {
                    x = (col - 1) * tileDim,
                    y = (row - 1) * tileDim,
                    width = tileDim,
                    height = tileDim,
                }
                if utils.checkTouch(obj1, winTile) then
                    returnTable.isTouchingWinTile = true -- we only want it to do something if player touches it, not projectiles
                end
            end
            if map[row][col] ~= 1 and map[row][col] ~= 6 and map[row][col] ~= 8 then -- if not air or win tile or spike tile
                local tile = {
                    x = (col - 1) * tileDim, -- gets xpos of current tile to check
                    y = (row - 1) * tileDim, -- ypos
                    width = tileDim, -- tile is square, so width = height = tileDim
                    height = tileDim,
                }
                if utils.checkTouch(obj1, tile) then
                    -- note: it works!!! yippeeeeeeee!!! idk how it works but it works now and doesnt jitter so who cares
                    returnTable.touchingTile = true
                    local objLeft = obj1.x
                    local objRight = obj1.x + (obj1.width or 0)
                    local objTop = obj1.y
                    local objBottom = obj1.y + (obj1.height or 0)
                    local tileLeft = tile.x
                    local tileRight = tile.x + tile.width
                    local tileTop = tile.y
                    local tileBottom = tile.y + tile.height
                    local overlapX = math.min(objRight, tileRight) - math.max(objLeft, tileLeft) -- horiz overlap, the math.min gets the rightmost left edge, math.max gets the leftmost right edge and is for no negative overlap (cause distance) basically it gives how much they overlap in x
                    local overlapY = math.min(objBottom, tileBottom) - math.max(objTop, tileTop) -- basically the above but for y
                    -- normal update logic for table:
                    -- need make the isOnGround not be affected when i touch side
                    -- i think i need correct x first lol
                    if objBottom <= tileTop and objRight > tileLeft and objLeft < tileRight then
                        returnTable.isOnGround = true
                    end
                    -- however we only correct the axises one at a time!
                    if axisToCorrect == "x" then
                        --correct it (hopefully it doesnt jitter)
                        if obj1.xv > 0 then -- if going right, push to left
                            obj1.x = obj1.x - overlapX
                            returnTable.wallToRight = true
                        elseif obj1.xv < 0 then -- if going left, push to right
                            obj1.x = obj1.x + overlapX
                            returnTable.wallToLeft = true
                        end
                    elseif axisToCorrect == "y" then
                        if obj1.yv > 0 then -- if going down, push up
                            obj1.y = obj1.y - overlapY
                            returnTable.isOnGround = true
                        elseif obj1.yv < 0 then -- if going up, push down
                            obj1.y = obj1.y + overlapY
                            returnTable.headHitting = true
                        end
                    else
                        print("axis to correct was not specified, will not correct")
                    end
                end
            end
        end
    end
    return returnTable
end

return utils

