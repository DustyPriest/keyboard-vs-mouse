
local wWidth = nil
local wHeight = nil

local playerAnim = nil
local playerFrames = nil
local frameWidth = nil
local frameHeight = nil

function loadPlayerAnim()
  
  wWidth = love.graphics.getWidth()
  wHeight = love.graphics.getHeight()

  -- player frames are 72x64 with 1px border
  playerAnim = love.graphics.newImage("player-combined.png")
  
  frameWidth = 72
  frameHeight = 64
  local width = playerAnim:getWidth()
  local height = playerAnim:getHeight()
  playerAnimFrames = {}
  
  for i=0,2 do
    table.insert(playerAnimFrames, love.graphics.newQuad(1 + i * (frameWidth + 2), 1, frameWidth, frameHeight, width, height))
  end
  
end

function drawPlayer(lives, invuln)
  if invuln > 0 then love.graphics.setColor(1,0.6,0.6,0.8) end
  -- draw player based on  lives left
  if lives > 1 then
    love.graphics.draw(playerAnim, playerAnimFrames[4 - lives], wWidth / 2, wHeight / 2,0,1,1,(frameWidth + 2) / 2, (frameHeight + 2) / 2)
  else
    love.graphics.draw(playerAnim, playerAnimFrames[3], wWidth / 2, wHeight / 2,0,1,1,(frameWidth + 2) / 2, (frameHeight + 2) / 2)
  end
end