Mouse = Object.extend(Object)
require "word"


function Mouse:new()
    -- random position on edge of screen
    if math.random() > 0.5 then
      -- xpos first, so ypos will be off screen
      self.x = math.random(0,800)
      -- ypos either top or bottom
      if math.random() > 0.5 then
        self.y = 0
      else
        self.y = 600
      end
    else
      --ypos first, so xpos will be off screen
      self.y = math.random(0,600)
      -- xpos either top or bottom
      if math.random() > 0.5 then
        self.x = 0
      else
        self.x = 800
      end
    end
    
    self.speed = 30
    self.radius = 20
    self.word = Word()
    
end

function Mouse:update(dt)
  -- move towards center of the screen
  local vec = {}
  vec.y = 300 - self.y
  vec.x = 400 - self.x
  vec.dist = math.sqrt(vec.x * vec.x + vec.y * vec.y)
  
  self.x = self.x + self.speed * vec.x / vec.dist * dt
  self.y = self.y + self.speed * vec.y / vec.dist * dt
  
end

function Mouse:draw()
  love.graphics.circle("fill", self.x, self.y, self.radius)
  for i,v in ipairs(self.word.letters) do
    love.graphics.setColor(v.typed.r, v.typed.g, v.typed.b)
    love.graphics.print(v.ch, self.x + (10 * i) - (#self.word.letters * 6), self.y + 30)
    love.graphics.setColor(1,1,1)
  end
  
end