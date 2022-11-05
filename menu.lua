Menu = Object.extend(Object)

function Menu:new(text, fn, clr, clrHot) 
  
  self.text = text -- display text
  self.fn = fn -- function on click
  self.hot = false -- whether mouse is over or not
  
  if clr then
    self.colour = clr
    self.colourHot = clrHot
  else
    self.colour = {0.4, 0.4, 0.5, 1} -- default colour
    self.colourHot = {0.5, 0.5, 0.7, 1} -- default hot colour
  end
  
  self.width = 400
  self.height = 60  
end

function Menu:isHot(mausx, mausy, buttonPos)
  
  return mausx > buttonPos.x
      and mausx < buttonPos.x + self.width
      and mausy > buttonPos.y
      and mausy < buttonPos.y + self.height
      
end

function Menu:draw(buttonPos)
  
  if self.hot then
    love.graphics.setColor(unpack(self.colourHot))
  else love.graphics.setColor(unpack(self.colour)) end
  
  love.graphics.rectangle("fill", buttonPos.x, buttonPos.y, self.width, self.height)
  love.graphics.setColor(1,1,1)
  
  local fontHeight = menuFont:getHeight("A")
  love.graphics.printf(self.text, menuFont, buttonPos.x, buttonPos.y + self.height / 2 - fontHeight / 2, self.width, "center")
  
  return buttonPos
end

function Menu:getPos(index, totalCount)
  
  local wWidth = love.graphics.getWidth()
  local wHeight = love.graphics.getHeight()
  
  local spacing = (self.height + 20) * (index - 1)
  
  local buttonPos = {}
  buttonPos.x = wWidth / 2 - self.width / 2
  buttonPos.y = (wHeight / 2 - self.height / 2) + spacing - (totalCount / 2 * self.height)
  
  return buttonPos
  
end