Mouse = Object.extend(Object)
require "word"

local mouseColours = {
  {80/255, 52/255, 34/255}, -- Brown
  {80/255, 80/255, 80/255}, -- Black/Grey
  {1,1,1} -- White / default
  }


function Mouse:new()
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
    
    -- random of three colours
    self.colour = mouseColours[love.math.random(1, #mouseColours)]
    
    self.speed = 30
    self.radius = 20
    self.angle = math.atan2(400 - self.y, 600 - self.x)   -- angle to face center
    
    self.word = Word()
    
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
  
  if not self.word.isDead then
  -- move towards center of the screen
    self.x = self.x + self.speed * vec.x / vec.dist * dt
    self.y = self.y + self.speed * vec.y / vec.dist * dt
  else
    -- dead: run away quickly
    self.x = self.x + self.speed * 20 * -vec.x / vec.dist * dt
    self.y = self.y + self.speed * 20 * -vec.y / vec.dist * dt
  end
end

function Mouse:draw()
  -- draw current frame of animation (frames are 32/32, scaled 2x)
  love.graphics.setColor(unpack(self.colour))
  if not self.word.isDead then
    love.graphics.draw(mouseAnim, mouseFrames[math.floor(self.currentFrame)],self.x, self.y, self.angle, 2, 2, 16, 16)
  else
    love.graphics.draw(mouseAnim, mouseFrames[math.floor(self.currentFrame)],self.x, self.y, self.angle - math.pi, 2, 2, 16, 16)
  end
  love.graphics.setColor(1,1,1)
  
  -- draw letters
  if not self.word.isDead then
    local letterWidth = 11
    for i,v in ipairs(self.word.letters) do
      local letterx = self.x + (10 * (i - 1)) - (#self.word.letters * letterWidth / 2) --- mouse pos + letter spacing - centering
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
  
  local frame_side = 32
  local width = mouseAnim:getWidth()
  local height = mouseAnim:getHeight()
  
  for i=0,3 do
    table.insert(mouseFrames, love.graphics.newQuad(1 + i * (frame_side + 2), 1, frame_side, frame_side, width, height)) -- 1px & 2px adjustments to avoid borders
  end
  
end