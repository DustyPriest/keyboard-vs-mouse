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
-- put in real wordlist DONE
-- create miniboss word list DONE
-- create a few gamemessages at key points
-- change background colour and general colour, background texture? DONE
-- create death animation for mice (run back out of screen quickly, without letters beneath, or circle around) DONE
-- create sound effect for hitting, missing, destroying, dying
-- create menu class (properties: hovered (bool), function, colour, text, fontsize, ) DONE
    -- hovered property is a second check behind a gamePaused bool for whether clicking on menu should do anything DONE
-- create pause on esc. and minimize/unfocus DONE
-- make lose state with restart option DONE
-- create scoring system and display
-- record high scores
-- check where "requires" should be put
-- check how to best declare and initiate local variables
-- create a life system! 3 lives, mice get bounced back when they hit you DONE
-- create screenshake on hit taken
-- create main menu, move difficulty option there DONE
-- separate into 3 word lists. normal: 2 - 6, large: 7 - 15, boss: 15+. Spawn normal always, large if on hard or on level 5+, boss 1 per level/5 on each 5th level, or every level from 10 if on hard. DONE

local mainMenuBackground = nil
local background = nil
local heart = nil

local livingMice = {}
local dyingMice = {}

local wWidth = nil
local wHeight = nil 

local gameMsg = nil
local gameMsgOpacity = 0
local gameMsgClr = {1,1,1,1}

local escButton = nil

local difficulty = 2
local level = 0

local levelDuration = 0
local spawnTimer = 0

local spawning = false
local spawner = nil

local lives = 3
local invuln = 0
local score = 0

local pauseMenus = {} 
local gameOverMenus = {}
local mainMenus = {}

local gameMainMenu = true
local gamePaused = false
local gameOver = false

local stencilRadius = nil
local looneyPause = 1

-- CALLBACKS

function love.load()
  mouseFont = love.graphics.setNewFont("RobotoMono-Medium.ttf", 18)
  menuFont = love.graphics.setNewFont("RobotoMono-Medium.ttf", 24)
  titleFont = love.graphics.setNewFont("RobotoMono-Medium.ttf", 64)
  messageFont = love.graphics.setNewFont("RobotoMono-Medium.ttf", 32)
  -- TODO: Implement mini bosses
  bossFont = love.graphics.setNewFont("RobotoMono-Medium.ttf", 22)
  -- math.randomseed( os.time() ) not necessary when using love.math.random
  
  
  wWidth = love.graphics.getWidth()
  wHeight = love.graphics.getHeight()
  
  stencilRadius = wWidth / 1.5
  
  loadMouseAnim()
  loadPlayerAnim()
  loadArrowAnim()
  mainMenuBackground = love.graphics.newImage("cat-computer-main-menu.png")
  background = love.graphics.newImage("floorboards.png")
  heart = love.graphics.newImage("heart.png")

  escButton = {
    text = "ESC",
    hot = false,
    fn = menuResume,
    x = 0,
    y = 0,
    width = 45,
    height = 30
    }
  
  -- Load menus
  table.insert(pauseMenus, Menu(
      "Resume",
      menuResume))
  table.insert(pauseMenus, Menu(
      "Restart",
      menuRestart))
  table.insert(pauseMenus, Menu(
      "Main Menu",
      menuMainMenu))
--  table.insert(pauseMenus, Menu(
--      "Difficulty: Normal",
--      menuDifficulty))
  table.insert(pauseMenus, Menu(
      "Exit",
      menuExit,
      {0.6, 0.3, 0.3, 1},
      {0.7, 0.4, 0.4, 1}))

  table.insert(gameOverMenus, Menu(
      "Try Again", 
      menuRestart))
  table.insert(gameOverMenus, Menu(
      "Main Menu",
      menuMainMenu))
  table.insert(gameOverMenus, Menu(
      "Exit", 
      menuExit))
  
  table.insert(mainMenus, Menu(
      "Start Game",
      menuRestart))
  table.insert(mainMenus, Menu(
      "Difficulty: Normal",
      menuDifficulty))
  table.insert(mainMenus, Menu(
      "Exit",
      menuExit))
  
  delayShowMenus(mainMenus, 0.5)

--  spawnMice()

end

function love.update(dt)
  tick.update(dt)
  
  if not gameMainMenu then
    -- lose state check before updating mouse position etc.
    if lives == 0 and not gameOver then
      gameOver = true
      delayShowMenus(gameOverMenus, 7)
    end
    
    if gameOver and stencilRadius > 0 then -- looney tunes effect
      if stencilRadius > 60 or looneyPause <= 0 then
        stencilRadius = stencilRadius - dt * 200
      elseif looneyPause > 0 then
        looneyPause = looneyPause - dt / 2.5
      end
    end
    
    -- tabbing out
    if not love.window.hasFocus() and not gameOver then 
      gamePaused = true
    end
    
    -- update mice
    if not gamePaused and not gameOver then
      --spawn mice
      spawnMice(dt)
      
      if invuln > 0 then 
        invuln = invuln - dt
      end
      
      

      -- update mice
      for i,v in ipairs(livingMice) do
        if v:checkCollision(dt) and invuln <= 0 then -- not invulnerable and getting hit
          lives = lives - 1
          invuln = 2
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
    -- if game paused then render menu, assess mouse position
    local mausx, mausy = love.mouse.getPosition()
    if gamePaused and not gameOver then
      for i,v in ipairs(pauseMenus) do
        v.hot = v:isHot(mausx, mausy, v:getPos(i, #pauseMenus))
      end
      escButton.hot = escButtonIsHot(mausx, mausy)
    elseif gameOver then
      for i,menu in ipairs(gameOverMenus) do
        if menu.show then
          menu.hot = menu:isHot(mausx, mausy, menu:getPos(i, #gameOverMenus))
        end
      end
    else 
      escButton.hot = escButtonIsHot(mausx, mausy)
    end
    
    -- update game message
    if gameMsgOpacity > 0 and not gamePaused and not gameOver then
      gameMsgOpacity = gameMsgOpacity -  dt / ((gameMsgOpacity * 10) + 1)
    end
  else -- game main menu open
      
      -- assess mouse position
      local mausx, mausy = love.mouse.getPosition()
      for i,menu in ipairs(mainMenus) do
        if menu.show then
          menu.hot = menu:isHot(mausx, mausy, menu:getPos(i, #mainMenus))
        end
      end
  
  end
  
  
end

function love.draw()
  
  if not gameMainMenu then
    -- background tile
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(background)
    
    -- TODO: ABSTRACT DRAWING, DRAW
  --    Draw game first, then menu
    
    -- draw player
    love.graphics.setColor(1,1,1,1)
    drawPlayer(lives, invuln)
    
    
    -- draw mice
    -- Change to for loop starting from end of table, so that the oldest mice render on top?
    for i,v in ipairs(livingMice) do
      pcall(v.draw, v)
    end
    for i,v in ipairs(dyingMice) do
      pcall(v.draw, v)
    end
    
    -- draw target over active mouse
    if ACTIVE_WORD then
      -- red box for testing
  --    love.graphics.setColor(1,0,0)
  --    love.graphics.rectangle("line", livingMice[ACTIVE_WORD].x - 32, livingMice[ACTIVE_WORD].y - 32, 64, 64) 
      
      drawArrow(livingMice[ACTIVE_WORD].x, livingMice[ACTIVE_WORD].y)
      
    end
    
    -- game announcement
    if gameMsgOpacity > 0 then drawGameMessage() end
    
    -- pause menus
    if gamePaused and not gameOver then
      love.graphics.setColor(0,0,0,0.7) -- transparent backdrop
      love.graphics.rectangle("fill", 0, 0, wWidth, wHeight)
      
      for i,v in ipairs(pauseMenus) do
        v:draw(v:getPos(i, #pauseMenus))
      end
    end
    
    -- score in corner
    if not gameOver then
      love.graphics.setColor(0,0,0,0.5)
      love.graphics.rectangle("fill", wWidth - mouseFont:getWidth("Score") - 15, 5, mouseFont:getWidth("Score") + 10, mouseFont:getHeight("A") + 1) 
      love.graphics.rectangle("fill", wWidth - mouseFont:getWidth(commaValue(score)) - 15, 10 + mouseFont:getHeight("A"), mouseFont:getWidth(commaValue(score)) + 10, mouseFont:getHeight("A") + 1) 
      
      love.graphics.setColor(1,1,1,1)
      love.graphics.printf("Score", mouseFont, 0, 5, wWidth - 10, "right")
      love.graphics.printf(commaValue(score), mouseFont, 0, 10 + mouseFont:getHeight("A"), wWidth - 10, "right")
      
      -- level in corner
      love.graphics.setColor(0,0,0,0.5)
      love.graphics.rectangle("fill", wWidth - mouseFont:getWidth("Level") - 15, wHeight - mouseFont:getHeight("A") * 2 - 10, mouseFont:getWidth("Level") + 10, mouseFont:getHeight("A") + 1) 
      love.graphics.rectangle("fill", wWidth - mouseFont:getWidth(level) - 15, wHeight - mouseFont:getHeight("A") - 5, mouseFont:getWidth(level) + 10, mouseFont:getHeight("A") + 1) 
      
      love.graphics.setColor(1,1,1,1)
      love.graphics.printf("Level", mouseFont, 0, wHeight - mouseFont:getHeight("A") * 2 - 10, wWidth - 10, "right")
      love.graphics.printf(level, mouseFont, 0, wHeight - mouseFont:getHeight("A") - 5, wWidth - 10, "right")
    
      -- lives in top middle
      for i=1,3 do
        if i > lives then love.graphics.setColor(0.5,0.5,0.5,0.3) end -- lost lives
        love.graphics.draw(heart, wWidth / 2 + 36 * (i - 2), 5, 0, 1, 1, 17, 0)
      end
      
      -- esc button
      if escButton.hot then
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.rectangle("fill", 0, 0, escButton.width, escButton.height)
        love.graphics.setColor(0,0,0,1)
        love.graphics.printf(escButton.text, mouseFont, 0, 2, escButton.width, "center")
      else 
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle("fill", 0, 0, escButton.width, escButton.height)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(escButton.text, mouseFont, 0, 2, escButton.width, "center")
      end
      
      
    end
    
    -- game over screen
    if gameOver then
      -- backdrop with stencil for looney tunes effect
      love.graphics.setColor(0,0,0,0.85)
      love.graphics.stencil(gameOverStencil, "replace", 1)
      love.graphics.setStencilTest("less", 1)
      love.graphics.rectangle("fill", -10, -10, wWidth + 10, wHeight + 10)
      love.graphics.setStencilTest()
      
      -- YOU LOSE
      love.graphics.setColor(1, 0.1, 0.1, 1 - looneyPause)
      love.graphics.printf("YOU LOSE", titleFont, 0, 50, wWidth, "center")
      
      -- score
      if looneyPause < 0 then 
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("SCORE: " .. commaValue(score), menuFont, 0, 180, wWidth, "center")
      end
      
      -- menus
      for i,menu in ipairs(gameOverMenus) do
        if menu.show then
          menu:draw(menu:getPos(i, #gameOverMenus))
        end
      end
    end
  else -- game main menu open
    love.graphics.setColor(1,1,1,1)
    love.graphics.setBackgroundColor(1,0.8,1,1) -- TODO: fiddle with the main menu background colour
    love.graphics.draw(mainMenuBackground)
    
    -- title
    love.graphics.printf("KEYBOARD VS. MOUSE", titleFont, 0, 130, wWidth, "center")
    -- by me :)
    love.graphics.setColor(0.7,0.7,0.7,1)
    love.graphics.printf("by DustyPriest", mouseFont, 0, 130 + titleFont:getHeight(A), wWidth, "center")
    
    -- menu options
    for i,menu in ipairs(mainMenus) do
      if menu.show then
        menu:draw(menu:getPos(i, #mainMenus))
      end
    end
    
  end
  
end

function love.keypressed(key, scancode)
  
  ucode = scancode:byte()
  -- alpha key pressed
  
  if key == "escape" and not gameOver then
    menuResume()
  end
  
  if ((ucode > 64 and ucode < 91) or (ucode > 96 and ucode < 123)) and not gamePaused and not gameOver then
    if ACTIVE_WORD then -- continue current word
      attackActiveWord(key)
      
    else checkWords(key) -- look for new word to start typing
    end
  end
  
end

function love.mousepressed(mausx, mausy, button, istouch, presses)
  if button == 1 and gamePaused then -- left click
    for i,menu in ipairs(pauseMenus) do -- look for hot menu
      if menu.hot then
        menu:fn() -- execute menu and return
        return
      end
    end
    if escButton.hot then 
      escButton.fn() 
      return
    end
  elseif button == 1 and gameOver then
    for i,menu in ipairs(gameOverMenus) do -- look for hot menu
      if menu.hot then
        menu:fn() -- execute menu and return
        return
      end
    end
  elseif button == 1 and gameMainMenu then
    for i,menu in ipairs(mainMenus) do -- look for hot menu
      if menu.hot then
        menu:fn() -- execute menu and return
        return
      end
    end
  else
    if escButton.hot then 
      escButton.fn() 
      return
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
  local wordLen = nil
  for i,v in ipairs(livingMice[ACTIVE_WORD].word.letters) do
    if v.typed == UNTYPED and v.ch == key then-- untyped and matching letter; set to typed and check for finished word
      v.typed = TYPED
      wordCompleted = livingMice[ACTIVE_WORD].word:assessState()
      wordLen = #livingMice[ACTIVE_WORD].word.letters
      break
    elseif v.typed == UNTYPED and v.ch ~= key then break -- incorrect letter, stop checking
    end
  end
  
  if wordCompleted then
    local diffMod = nil
    if difficulty == 1 then diffMod = 1
    elseif difficulty == 2 then diffMod = 1.2
    elseif difficulty == 3 then diffMod = 1.4 end
    score = score + math.floor(math.log(level) + 1 * wordLen * 5 * diffMod)
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
  
  -- TODO: save score first!!
  score = 0
  level = 0
  levelDuration = 0
  lives = 3
  
  setGameMessage("Killer mice are attacking!\nFend them off!")
  gamePaused = false
  gameOver = false
  gameMainMenu = false
  
  
end

function menuDifficulty(menu)
  if difficulty == 1 then
    difficulty = 2
    menu.text = "Difficulty: Normal"
  elseif difficulty == 2 then
    difficulty = 3
    menu.text = "Difficulty: Hard"
  else 
    difficulty = 1
    menu.text = "Difficulty: Easy"
  end
end

function menuMainMenu()
  gameMainMenu = true
  gamePaused = false
  gameOver = false
end

function drawGameMessage()
  love.graphics.setColor(gameMsgClr[1], gameMsgClr[2], gameMsgClr[3], gameMsgOpacity)
  love.graphics.printf(gameMsg, messageFont, wWidth / 4, 0 + 75, wWidth / 2, "center")
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
      setGameMessage("Level: " .. level, {1,1,0})
    end
    
    levelDuration = 20 + level / 2
    spawning = true
    if level % 5 == 0 then -- spawn 1 boss mouse per 5 levels every 5 levels
      for i=1, level / 5 do
        table.insert(livingMice, Mouse(difficulty, level, true ))
      end
    end
  end

  if levelDuration > 0 and spawning then -- mid-level
    if spawnTimer <= 0 then -- ready to spawn mouse
      table.insert(livingMice, Mouse(difficulty, level, false ))
      spawnTimer = difficultyMod(level)
    else -- not ready to spawn mouse
      spawnTimer = spawnTimer - dt
    end
  end
  
  levelDuration = levelDuration - dt
  
end

function difficultyMod(level)
--  local mod = nil
  if     difficulty == 1 then return (50 / (level + 10)) + 3 --2 -- mod =  11 - (0.15 * level) -- easy
  elseif difficulty == 2 then return (50 / (level + 10)) + 1 -- mod =  7  - (0.15 * level) -- normal
  else                        return (50 / (level + 15)) -- + 0.5  --mod = 4  - (0.15 * level) -- hard
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

function delayShowMenus(menuList, initDelay)
  tick.delay(function()  menuList[1].show = true  end, initDelay)
      :after(function() menuList[2].show = true end, 0.75)
      :after(function() menuList[3].show = true end, 0.75)
  
end

function gameOverStencil()
  if stencilRadius > 0 then
    love.graphics.circle("fill", wWidth / 2, wHeight / 2, stencilRadius)
  end
end

function escButtonIsHot(mausx, mausy)
  return mausx > 0
      and mausx < escButton.width
      and mausy > 0
      and mausy < escButton.height
  
end