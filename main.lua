io.stdout:setvbuf("no")

tick = require "tick"
Object = require "classic"
require "mouse"
require "menu"

ACTIVE_WORD = false

-- TODO: 
-- make font monospace DONE
-- choose game window size DONE
-- create character in center
-- fill mouse sprite  & create random colour variation DONE
-- give background to typed letters?
-- create arrow animation png to go over target mouse
-- make letters larger/more visible somehow DONE
-- increase number of mice over time DONE
-- put in real wordlist
-- create miniboss word list
-- create a few gamemessages at key points
-- change background colour and general colour, background texture?
-- create death animation for mice (run back out of screen quickly, without letters beneath, or circle around) DONE
-- create sound effect for hitting, missing, destroying, dying
-- create menu class (properties: hovered (bool), function, colour, text, fontsize, )
    -- hovered property is a second check behind a gamePaused bool for whether clicking on menu should do anything
-- create pause on esc. and minimize/unfocus DONE
-- keyboard support for menu
-- make lose state with restart option
-- create scoring system and display
-- record high scores
-- check where "requires" should be put
-- check how to best declare and initiate local variables
-- create a life system! 3 lives, mice get bounced back when they hit you, a sound effect plays, either the screen shakes or the player does

local livingMice = {}
local dyingMice = {}
local menus = {} 
local wWidth = nil -- int
local wHeight = nil -- int

local gameMsg = nil
local gameMsgOpacity = 0
local gameMsgClr = {1,1,1}

local gamePaused = false

local difficulty = 1
local level = 0
local levelDuration = 0
local spawning = false
local spawner = nil
local score = 0

-- CALLBACKS

function love.load()
  mouseFont = love.graphics.setNewFont("RobotoMono-Medium.ttf", 18)
  menuFont = love.graphics.setNewFont("RobotoMono-Medium.ttf", 24)
  messageFont = love.graphics.setNewFont("RobotoMono-Medium.ttf", 32)
  -- TODO: Implement mini bosses
  bossFont = love.graphics.setNewFont("RobotoMono-Medium.ttf", 22)
  -- math.randomseed( os.time() ) not necessary when using love.math.random
  
  
  wWidth = love.graphics.getWidth()
  wHeight = love.graphics.getHeight()
  
  loadMouseAnim()


  -- TODO: APPLY DIFFICULTY SCALING
  -- set mice to spawn starting every 1 second
  --tick.recur(function() table.insert(livingMice, Mouse()) end, 1)
  
  -- Load menus
  table.insert(menus, Menu(
      "Resume",
      menuResume))
  table.insert(menus, Menu(
      "Restart",
      menuRestart))
  table.insert(menus, Menu(
      "Difficulty: Normal",
      menuDifficulty))
  table.insert(menus, Menu(
      "Exit",
      menuExit,
      {0.6, 0.3, 0.3, 1},
      {0.7, 0.4, 0.4, 1}))

  setGameMessage("Killer mice are coming for your keyboard.\nFend them off!")

  spawnMice()

end

function love.update(dt)
  tick.update(dt)
  
  -- tabbing out
  if not love.window.hasFocus() then --
    gamePaused = true
  end
  
  -- update mice
  if not gamePaused then
    
    --spawn mice
    if #livingMice == 0 and not spawning then spawnMice() end
    -- time down level
    levelDuration = levelDuration - dt
    if levelDuration <= 0 and spawning then stopSpawning() end
    
    
    
    -- update mice
    for i,v in ipairs(livingMice) do
      v:update(dt)
    end
    for i,v in ipairs(dyingMice) do
      v:update(dt)
    end
  end
  
  -- update menus
  -- if game paused then render menu
  if gamePaused then
    local mausx, mausy = love.mouse.getPosition()
    
    for i,v in ipairs(menus) do
      v.hot = v:isHot(mausx, mausy, v:getPos(i, #menus))
    end
  end
  
  -- update game message
  if gameMsgOpacity > 0 and not gamePaused then
    gameMsgOpacity = gameMsgOpacity -  dt / ((gameMsgOpacity * 10) + 1)
  end
    
  -- check for lose condition
  
end

function love.draw()
  -- light grey background for testing
  love.graphics.setBackgroundColor(0.4, 0.4, 0.4)
  
  -- TODO: ABSTRACT DRAWING, DRAW
--    Draw game first, then menu
  
  -- draw player
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle("fill", 585, 385, 30, 30)
  
  -- draw mice
  -- Change to for loop starting from end of table, so that the oldest mice render on top
  for i,v in ipairs(livingMice) do
    v:draw()
  end
  for i,v in ipairs(dyingMice) do
    v:draw()
  end
  
  -- draw target over active mouse
  if ACTIVE_WORD then
    love.graphics.setColor(1,0,0)
    love.graphics.rectangle("line", livingMice[ACTIVE_WORD].x - 32, livingMice[ACTIVE_WORD].y - 32, 64, 64) -- 32 and 64 bc mouse size is scaled up 2x
    love.graphics.setColor(1,1,1)
  end
  
  if gameMsgOpacity > 0 then drawGameMessage() end
  
  
  -- gane menus
  if gamePaused then
    love.graphics.setColor(0,0,0,0.3) -- transparent backdrop
    love.graphics.rectangle("fill", 0, 0, wWidth, wHeight)
    
    for i,v in ipairs(menus) do
      v:draw(v:getPos(i, #menus))
    end
  end
  
  -- score
  love.graphics.setColor(1,1,1,1)
  love.graphics.printf("Score", mouseFont, 0, 5, wWidth - 10, "right")
  love.graphics.printf(commaValue(score), mouseFont, 0, 10 + mouseFont:getHeight("A"), wWidth - 10, "right")
  -- level
  love.graphics.printf("Level", mouseFont, 0, wHeight - mouseFont:getHeight("A") * 2 - 10, wWidth - 10, "right")
  love.graphics.printf(level, mouseFont, 0, wHeight - mouseFont:getHeight("A") - 10, wWidth - 10, "right")
  
end

function love.keypressed(key, scancode)
  
  -- TODO: ONLY IF GAME NOT PAUSED
  ucode = scancode:byte()
  -- alpha key pressed
  
  if key == "escape" then
    menuResume()
  end
  
  if ((ucode > 64 and ucode < 91) or (ucode > 96 and ucode < 123)) and not gamePaused then
    if ACTIVE_WORD then -- continue current word
      attackActiveWord(key)
      
    else checkWords(key) -- look for new word to start typing
    end
  end
  
end

function love.mousepressed(mausx, mausy, button, istouch, presses)
  if button == 1 then -- left click
    for i,menu in ipairs(menus) do -- look for hot menu
      if menu.hot then
        menu:fn() -- execute menu and return
        return
      end
    end
  end
end

-- FUNCTIONS

function checkWords(key)
  -- iterate through mice
  for i,v in ipairs(livingMice) do
    -- check first letter of each word, set to active word and attack if match
    if v.word.letters[1].ch == key and not v.word.isDead then
      --v.word.isActive = true
      ACTIVE_WORD = i
      attackActiveWord(key)
      break
    end
  end
end

function attackActiveWord(key)
  -- iterate through letters in active word
  local wordCompleted = false
  for i,v in ipairs(livingMice[ACTIVE_WORD].word.letters) do
    if v.typed == UNTYPED and v.ch == key then-- untyped and matching letter; set to typed and check for finished word
      v.typed = TYPED
      wordCompleted = livingMice[ACTIVE_WORD].word:assessState()
      break
    elseif v.typed == UNTYPED and v.ch ~= key then break -- incorrect letter, stop checking
    end
  end
  
  if wordCompleted then
    score = score + 200
    deleteActiveWord()
  end
end

function deleteActiveWord()

  table.insert(dyingMice, table.remove(livingMice, ACTIVE_WORD))
  
  local dyingMouseIdx = #dyingMice -- remember position of dying mouse
  ACTIVE_WORD = false
  
  tick.delay(function() table.remove(dyingMice, dyingMouseIdx) end, 2) -- IS 2 SECONDS ENOUGH / TOO MUCH BEFORE DELETING
end

local function checkCollision(mouse)
  -- check if mouse is touching player
  -- depends on final decision for sizes of mice and player
  local pLeft = wWidth / 2 - 15
  local pRight = wWidth / 2 + 15
  local pTop = wHeight / 2 - 15
  local pBottom = wHeight / 2 + 15
  
  -- TODO: move to mouse object? to sort out sizing
  
  local mLeft = mouse.x
  local mRight = mouse.x + 40 -- double radius to equal right side, doesn't work properly with circle
  local mTop = mouse.y
  local mBottom = mouse.y + 40
  
  -- return boolean of if overlapping or not
  return  mRight > pLeft 
      and mLeft < pRight
      and mBottom > pTop
      and mTop < pBottom
end

function menuResume()
    if gamePaused then 
      gamePaused = false
      
    else gamePaused = true end
end

function menuExit(menu)
  
  if menu.quitting == true then
    love.event.quit(0)
  else
    menu.quitting = true
    menu.text = "Press again to exit game"
    tick.delay(function() 
        menu.quitting = false
        menu.text = "Exit"
        end, 2)
  end
end

function menuRestart()
  
  livingMice = {}
  dyingMice = {}
  
  -- save score first!!
  score = 0
  level = 0
  levelDuration = 0
  stopSpawning()
--  lives = 3
  
  setGameMessage("Killer mice are coming for your keyboard.\nFend them off!")
  gamePaused = false
  
  
end

function menuDifficulty(menu)
  if difficulty == 1 then
    difficulty = 2
    menu.text = "Difficulty: Hard"
  elseif difficulty == 2 then
    difficulty = 3
    menu.text = "Difficulty: Very Hard"
  else 
    difficulty = 1
    menu.text = "Difficulty: Normal"
  end
end

function drawGameMessage()
  love.graphics.setColor(gameMsgClr[1], gameMsgClr[2], gameMsgClr[3], gameMsgOpacity)
  love.graphics.printf(gameMsg, messageFont, wWidth / 4, 0 + 50, wWidth / 2, "center")
end

function setGameMessage(msg, rgb)
  gameMsg = msg
  gameMsgOpacity = 1
  if rgb then gameMsgClr = rgb end
end

function commaValue(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

function spawnMice()
  spawning = true
  level = level + 1
  levelDuration = 10 + level / 2
  
  if level % 10 == 0 then
    setGameMessage("Level: " .. level, {0.2, 0.6, 0.6})
  end
  
  local difficultyMod = nil
  
  if     difficulty == 1 then difficultyMod = 11 - (0.15 * difficulty)
  elseif difficulty == 2 then difficultyMod = 7  - (0.15 * difficulty)
  else                        difficultyMod = 4  - (0.15 * difficulty)
  end

  local spawnInterval = 1 --(1 / (level + 2)) * difficultyMod
  
  spawner = tick.recur(function() table.insert(livingMice, Mouse()) end, spawnInterval)

end

function stopSpawning()
  spawning = false
  if spawner then 
    spawner:stop() 
  end
    
  
end