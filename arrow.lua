
local arrowAnim = nil
local arrowAnimFrames = nil

local arrowFrameWidth = nil
local arrowFrameHeight = nil

local currentFrame = nil

local angle = nil

function drawArrow(x, y)
  love.graphics.setColor(1,1,1,1)
  
  love.graphics.draw(arrowAnim, arrowAnimFrames[math.floor(currentFrame)], x - 30, y - 30, angle - math.pi/2, 1.5, 1.5, 7, 5.5)
  love.graphics.draw(arrowAnim, arrowAnimFrames[math.floor(currentFrame)], x + 30, y - 30, angle, 1.5, 1.5, 7, 5.5)
end

function updateArrow(dt, x, y)
  currentFrame = currentFrame + dt * 8
  if currentFrame >= 7 then
    currentFrame = 1
  end
  
  angle = math.atan2(x, x - 30, y, y - 30)
  
end

function loadArrowAnim()
  -- arrow animation: 6 14x11 frames 
  arrowAnim = love.graphics.newImage("target-arrows.png")
  
  arrowAnimFrames = {}
  
  arrowFrameWidth = 14
  arrowFrameHeight = 11
  local width = arrowAnim:getWidth()
  local height = arrowAnim:getHeight()
  
  for i=0,5 do
    table.insert(arrowAnimFrames, love.graphics.newQuad(1 + i * (arrowFrameWidth + 2), 1, arrowFrameWidth, arrowFrameHeight, width, height))
  end
  
  currentFrame = 1
  
end