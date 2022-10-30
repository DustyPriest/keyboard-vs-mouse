io.stdout:setvbuf("no")

ACTIVE_WORD = false

-- TODO: make font monospace
-- make game square shaped
-- create character in center
-- make lose state that restarts game
-- create scoring system and display
-- give background to typed letters?
-- make letters larger/more visible somehow
-- increase difficulty over time
-- change background colour and general colour
-- create death animation for mice
-- create sound effect for hitting, missing, destroying, dying

-- CALLBACKS

function love.load()
  tick = require "tick"
  Object = require "classic"
  require "mouse"
  math.randomseed( os.time() )
  
  mice = {}
  
  -- set mice to spawn starting every 1 second
  tick.recur(function() table.insert(mice, Mouse()) end, 1)

end

function love.update(dt)
  tick.update(dt)
  for i,v in ipairs(mice) do
    v:update(dt)
  end
end

function love.draw()
  
  -- draw mice
  for i,v in ipairs(mice) do
    v:draw()
  end
  
  -- draw target over active mouse
  if ACTIVE_WORD then
    love.graphics.setColor(1,0,0)
    love.graphics.circle("line", mice[ACTIVE_WORD].x, mice[ACTIVE_WORD].y, 25 )
    love.graphics.setColor(1,1,1)
  end
end

function love.keypressed(key, scancode)
  ucode = scancode:byte()
  -- FOR TESTING
  -- table.insert(mice, Mouse())
  -- alpha key pressed
  if (ucode > 64 and ucode < 91) or (ucode > 96 and ucode < 123) then
    if ACTIVE_WORD then -- continue current word
      attackActiveWord(key)
      
    else checkWords(key) -- look for new word to start typing
    end
  end
  
end

-- FUNCTIONS


function checkWords(key)
  -- iterate through mice
  for i,v in ipairs(mice) do
    -- check first letter of each word, set to active word and attack if match
    if v.word.letters[1].ch == key and not v.word.isDead then
      v.word.isActive = true
      ACTIVE_WORD = i
      attackActiveWord(key)
      break
    end
  end
end

function attackActiveWord(key)
  -- iterate through letters in active word
  local wordCompleted = false
  for i,v in ipairs(mice[ACTIVE_WORD].word.letters) do
    if v.typed == UNTYPED and v.ch == key then-- untyped and matching letter; set to typed and check for finished word
      v.typed = TYPED
      wordCompleted = mice[ACTIVE_WORD].word:assessState()
      break
    elseif v.typed == UNTYPED and v.ch ~= key then break -- incorrect letter, stop checking
    end
  end
  
  if wordCompleted then
    deleteActiveWord()
  end
end

function deleteActiveWord()
  table.remove(mice, ACTIVE_WORD)
  ACTIVE_WORD = false
end
