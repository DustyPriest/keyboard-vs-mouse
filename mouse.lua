Mouse = Object.extend(Object)
require "word"

local mouseAnim = nil
local mouseFrames = nil



local mouseColours = {
  {80/255, 52/255, 34/255}, -- Brown
  {80/255, 80/255, 80/255}, -- Black/Grey
  {1,1,1} -- White / default
  }


function Mouse:new(difficulty, level, boss)
    -- random position on edge of screen
    if love.math.random() > 0.5 then
      -- xpos first, so ypos will be off screen
      self.x = love.math.random(0,1200)
      -- ypos either top or bottom
      if love.math.random() > 0.5 then
        self.y = -50
      else
        self.y = 850
      end
    else
      --ypos first, so xpos will be off screen
      self.y = love.math.random(0,800)
      -- xpos either top or bottom
      if love.math.random() > 0.5 then
        self.x = -50
      else
        self.x = 1250
      end
    end
    
    self.word = Word(difficulty, level, boss)
    
    self.speed = 75 - #self.word.letters * 4

    -- random of three colours
    self.colour = mouseColours[love.math.random(1, #mouseColours)]
      
      
    self.cd = 0
    

    
    self.angle = math.atan2(400 - self.y, 600 - self.x)   -- angle to face center
    self.currentFrame = 1
    
end

function Mouse:update(dt)
  -- prepare vector relative to center of screen
  local vec = {}
  vec.y = 400 - self.y
  vec.x = 600 - self.x
  vec.dist = math.sqrt(vec.x * vec.x + vec.y * vec.y)
  
  -- update animation frame
  self.currentFrame = self.currentFrame + self.speed/5 * dt
  if self.currentFrame >= 5 then
    self.currentFrame = 1
  end
  
  if not self.word.isDead and self.cd <= 0 then
  -- move towards center of the screen
    self.x = self.x + self.speed * vec.x / vec.dist * dt
    self.y = self.y + self.speed * vec.y / vec.dist * dt
  elseif not self.word.isDead and self.cd > 0 then
    -- recoil after hitting player
    self.x = self.x - 600 * vec.x / vec.dist * dt
    self.y = self.y - 600 * vec.y / vec.dist * dt
  else
    -- dead: run away quickly
    self.x = self.x + 600 * -vec.x / vec.dist * dt
    self.y = self.y + 600 * -vec.y / vec.dist * dt
  end
end

function Mouse:draw()
  -- draw current frame of animation (frames are 32/32, scaled 1.2x)
  love.graphics.setColor(unpack(self.colour))
  if not self.word.isDead then
    love.graphics.draw(mouseAnim, mouseFrames[math.floor(self.currentFrame)],self.x, self.y, self.angle, 1.2, 1.2, 16, 16)
  else
    love.graphics.draw(mouseAnim, mouseFrames[math.floor(self.currentFrame)],self.x, self.y, self.angle - math.pi, 1, 1, 16, 16)
  end
  love.graphics.setColor(1,1,1)
--  FOR TESTING: draw red circle in center of image
--  love.graphics.setColor(1,0,0)
--  love.graphics.circle("fill",self.x, self.y,5)
  
  -- draw letters
  if not self.word.isDead then
    local letterWidth = 11
    for i,v in ipairs(self.word.letters) do
      local letterx = self.x + (10 * (i - 1)) - (#self.word.letters * letterWidth / 2) --- mouse pos + letter spacing - centering
      local bgStartMod = 0
      local bgEndMod = 0
      if i == 1 then bgStartMod = 3 
      elseif i == #self.word.letters then bgEndMod = 4
      end
      love.graphics.setColor(0,0,0,0.5) -- transparent background
      love.graphics.rectangle("fill", letterx - bgStartMod, self.y + 30, 10 + bgStartMod + bgEndMod, 32)
      love.graphics.setColor(unpack(v.typed))
      love.graphics.print(v.ch, mouseFont, letterx, self.y + 30) -- draw letter
      love.graphics.line(letterx + 2, self.y + 55, letterx + 9, self.y + 55) -- draw underline
      -- love.graphics.setColor(1,1,1)
    end
  end
  
end

function loadMouseAnim()
  -- mouse animation: 4 32x32 frames each with 1px transparent border
  mouseAnim = love.graphics.newImage("mouse-anim.png")

  mouseFrames = {}

  local mouseFrameSide = 32
  local width = mouseAnim:getWidth()
  local height = mouseAnim:getHeight()
  
  for i=0,3 do
    table.insert(mouseFrames, love.graphics.newQuad(1 + i * (mouseFrameSide + 2), 1, mouseFrameSide, mouseFrameSide, width, height)) -- 1px & 2px adjustments to avoid borders
  end
  
end

function Mouse:checkCollision(dt)
  -- check if mouse is touching player
  -- depends on final decision for sizes of mice and player
  local pLeft = 1200 / 2 - 72 / 2
  local pRight = 1200 / 2 + 72 / 2
  local pTop = 800 / 2 - 64 / 2
  local pBottom = 800 / 2 + 64 / 2
  
  -- TODO: move to mouse object? to sort out sizing
  
  local mLeft = self.x
  local mRight = self.x + 32 -- double radius to equal right side, doesn't work properly with circle
  local mTop = self.y
  local mBottom = self.y + 32
  
  -- store boolean of if overlapping or not and not already on cooldown, return later after updating mouse
  local result = mRight > pLeft 
      and mLeft < pRight
      and mBottom > pTop
      and mTop < pBottom
      and self.cd <= 0
      
  if result then
    self.cd = 0.5
  else self.cd = self.cd - dt end

  return result
end

