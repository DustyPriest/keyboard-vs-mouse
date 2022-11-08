io.stdout:setvbuf("no")

tick = require "tick"
Object = require "classic"
require "mouse"
require "player"
require "menu"
require "arrow"

ACTIVE_WORD = false

-- TODO: 
-- make font monospace DONE
-- choose game window size DONE
-- create character in center DONE
-- fill mouse sprite  & create random colour variation DONE
-- give background to words DONE
-- create arrow animation png to go over target mouse DONE
-- make letters larger/more visible somehow DONE
-- increase number of mice over time DONE
-- put in real wordlist
-- create miniboss word list
-- create a few gamemessages at key points
-- change background colour and general colour, background texture?
-- create death animation for mice (run back out of screen quickly, without letters beneath, or circle around) DONE
-- create sound effect for hitting, missing, destroying, dying
-- create menu class (properties: hovered (bool), function, colour, text, fontsize, ) DONE
    -- hovered property is a second check behind a gamePaused bool for whether clicking on menu should do anything DONE
-- create pause on esc. and minimize/unfocus DONE
-- keyboard support for menu, eh
-- make lose state with restart option
-- create scoring system and display
-- record high scores
-- check where "requires" should be put
-- check how to best declare and initiate local variables
-- create a life system! 3 lives, mice get bounced back when they hit you, a sound effect plays
-- create screenshake on hit taken
-- create main menu, move difficulty option there
-- separate into 3 word lists. normal: 2 - 6, large: 7 - 15, boss: 15+. Spawn normal always, large if on hard or on level 5+, boss 1 per level/5 on each 5th level, or every level from 10 if on hard.

local background = nil
local heart = nil

local livingMice = {}
local dyingMice = {}
local menus = {} 
local wWidth = nil -- int
local wHeight = nil -- int

local gameMsg = nil
local gameMsgOpacity = 0
local gameMsgClr = {1,1,1,1}

local gamePaused = false

local difficulty = 2
local level = 0

local levelDuration = 0
local spawnTimer = 0

local spawning = false
local spawner = nil

local lives = 3
local invuln = 0
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
  loadPlayerAnim()
  loadArrowAnim()
  background = love.graphics.newImage("floorboards.png")
  heart = love.graphics.newImage("heart.png")


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
      "Difficulty: Easy",
      menuDifficulty))
  table.insert(menus, Menu(
      "Exit",
      menuExit,
      {0.6, 0.3, 0.3, 1},
      {0.7, 0.4, 0.4, 1}))

  setGameMessage("Killer mice are attacking!\nArm yourself with a keyboard!")

--  spawnMice()

end

function love.update(dt)
  tick.update(dt)
  
  -- tabbing out
  if not love.window.hasFocus() then 
    gamePaused = true
  end
  
  -- update mice
  if not gamePaused then
    
    --spawn mice
--    if #livingMice == 0 and not spawning then spawnMice() end
--    -- time down level
--    levelDuration = levelDuration - dt
--    if levelDuration <= 0 and spawning then stopSpawning() end
    
    
    spawnMice(dt)
    
    if invuln > 0 then 
      invuln = invuln - dt
    end
    
    

    -- update mice
    for i,v in ipairs(livingMice) do
      if v:checkCollision(dt) and invuln <= 0 then -- not invulnerable and getting hit
        lives = lives - 1
        invuln = 3
      end
      v:update(dt)
    end
    for i,v in ipairs(dyingMice) do
      v:update(dt)
    end
    
    if ACTIVE_WORD then
      updateArrow(dt, livingMice[ACTIVE_WORD].x, livingMice[ACTIVE_WORD].y)
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
  -- love.graphics.setBackgroundColor(0.4, 0.4, 0.4)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(background)
  
  -- TODO: ABSTRACT DRAWING, DRAW
--    Draw game first, then menu
  
  -- draw player
  love.graphics.setColor(1,1,1,1)
  drawPlayer(lives)
  
  -- FOR TESTING: RED CIRCLE IN CENTER
--  love.graphics.setColor(1,0,0,1)
--  love.graphics.circle("fill", wWidth / 2, wHeight / 2, 5)
  
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
    -- red box for testing
--    love.graphics.setColor(1,0,0)
--    love.graphics.rectangle("line", livingMice[ACTIVE_WORD].x - 32, livingMice[ACTIVE_WORD].y - 32, 64, 64) 
    
    drawArrow(livingMice[ACTIVE_WORD].x, livingMice[ACTIVE_WORD].y)
    
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
  love.graphics.setColor(0,0,0,0.5)
  love.graphics.rectangle("fill", wWidth - mouseFont:getWidth("Score") - 15, 5, mouseFont:getWidth("Score") + 10, mouseFont:getHeight("A") + 1) 
  love.graphics.rectangle("fill", wWidth - mouseFont:getWidth(commaValue(score)) - 15, 10 + mouseFont:getHeight("A"), mouseFont:getWidth(commaValue(score)) + 10, mouseFont:getHeight("A") + 1) 
  
  love.graphics.setColor(1,1,1,1)
  love.graphics.printf("Score", mouseFont, 0, 5, wWidth - 10, "right")
  love.graphics.printf(commaValue(score), mouseFont, 0, 10 + mouseFont:getHeight("A"), wWidth - 10, "right")
  
  -- level
  love.graphics.setColor(0,0,0,0.5)
  love.graphics.rectangle("fill", wWidth - mouseFont:getWidth("Level") - 15, wHeight - mouseFont:getHeight("A") * 2 - 10, mouseFont:getWidth("Level") + 10, mouseFont:getHeight("A") + 1) 
  love.graphics.rectangle("fill", wWidth - mouseFont:getWidth(level) - 15, wHeight - mouseFont:getHeight("A") - 5, mouseFont:getWidth(level) + 10, mouseFont:getHeight("A") + 1) 
  
  love.graphics.setColor(1,1,1,1)
  love.graphics.printf("Level", mouseFont, 0, wHeight - mouseFont:getHeight("A") * 2 - 10, wWidth - 10, "right")
  love.graphics.printf(level, mouseFont, 0, wHeight - mouseFont:getHeight("A") - 5, wWidth - 10, "right")
  
  -- lives
  for i=1,3 do
    if i > lives then love.graphics.setColor(0.5,0.5,0.5,0.3) end -- lost lives
    love.graphics.draw(heart, wWidth / 2 + 36 * (i - 2), 5, 0, 1, 1, 17, 0)
  end
  
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
  if button == 1 and gamePaused then -- left click
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



function menuResume()
    if gamePaused then 
      gamePaused = false
      
    else 
      gamePaused = true 
    
    end
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
  
  setGameMessage("Killer mice are attacking!\nFend them off!")
  gamePaused = false
  
  
end

function menuDifficulty(menu)
  if difficulty == 1 then
    difficulty = 2
    menu.text = "Difficulty: Easy"
  elseif difficulty == 2 then
    difficulty = 3
    menu.text = "Difficulty: Normal"
  else 
    difficulty = 1
    menu.text = "Difficulty: Hard"
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

function spawnMice(dt)
  if #livingMice == 0 and levelDuration <= 0 then -- all mice defeated, start next level
    level = level + 1
    
    -- level title every 5 levels
    if level % 5 == 0 and gameMsgOpacity <= 0 then
      setGameMessage("Level: " .. level, {0.2, 0.6, 0.6})
    end
    
    levelDuration = 10 + level / 2
    spawning = true
    if level % 5 == 0 then -- spawn 1 boss mouse per 5 levels every 5 levels
      for i=1, level / 5 do
        table.insert(livingMice, Mouse(true))
      end
    end
  end

  if levelDuration > 0 and spawning then -- mid-level
    if spawnTimer <= 0 then -- ready to spawn mouse
      table.insert(livingMice, Mouse(false))
      spawnTimer = difficultyMod(level)
    else -- not ready to spawn mouse
      spawnTimer = spawnTimer - dt
    end
  end
  
  levelDuration = levelDuration - dt
  
end

function difficultyMod(level)
--  local mod = nil
  if     difficulty == 1 then return (50 / (level + 10)) + 2 -- mod =  11 - (0.15 * level) -- easy
  elseif difficulty == 2 then return (50 / (level + 10)) + 1 -- mod =  7  - (0.15 * level) -- normal
  else                        return (50 / (level + 15)) + 0.5  --mod = 4  - (0.15 * level) -- hard
  end
--  return (1 / (level + 2)) * mod
end

--function spawnMice()
--  spawning = true
--  level = level + 1
--  levelDuration = 10 + level / 2
  
--  if level % 10 == 0 then
--    setGameMessage("Level: " .. level, {0.2, 0.6, 0.6})
--  end
  
--  local difficultyMod = nil
  
--  if     difficulty == 1 then difficultyMod = 11 - (0.15 * level)
--  elseif difficulty == 2 then difficultyMod = 7  - (0.15 * level)
--  else                        difficultyMod = 4  - (0.15 * level)
--  end

--  local spawnInterval = 1 --(1 / (level + 2)) * difficultyMod
  
--  spawner = tick.recur(function() table.insert(livingMice, Mouse()) end, spawnInterval)

--end

--function stopSpawning()
--  spawning = false
--  if spawner then 
--    spawner:stop() 
--  end
    
  
--end