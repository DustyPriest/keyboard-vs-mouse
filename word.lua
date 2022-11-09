Word = Object.extend(Object)

TYPED = {75/255, 255/255, 6/255, 1}
UNTYPED = {1,1,1,1}

local shortWordList = {}
local longWordList = {}
local bossWordList = {}

for line in love.filesystem.lines("short-word-list.txt") do
  table.insert(shortWordList, line)
end

for line in love.filesystem.lines("long-word-list.txt") do
  table.insert(longWordList, line)
end

for line in love.filesystem.lines("boss-word-list.txt") do
  table.insert(bossWordList, line)
end

function Word:new(difficulty, level, boss)
  self.letters = selectWord(difficulty, level, boss)
  
  self.isDead = false
  
end

-- Spawn normal always, large if on hard or on level 5+, boss 1 per level/5 on each 5th level, or every level from 10 if on hard.
function selectWord(difficulty, level, boss)
  local newWord = nil
  if boss then -- call to spawn boss mouse
    newWord = bossWordList[love.math.random(1,#bossWordList)]
  elseif level > 5 or difficulty == 3 then -- 50/50 short or long word 
    local rand = love.math.random(1,2)
    if rand == 1 then newWord = shortWordList[love.math.random(1,#shortWordList)]
    else newWord = longWordList[love.math.random(1,#longWordList)]end
  else -- default always spawn normal word
    newWord = shortWordList[love.math.random(1,#shortWordList)]
  end
    
  local ltrs = {}
  
  for i = 1, #newWord do
    table.insert(ltrs, {
        typed=UNTYPED,
        ch=newWord:sub(i,i)
        })
  end
  
  return ltrs
end

function Word:assessState()
  local wordCompleted = true
  -- look for untyped letters
  for i,v in ipairs(self.letters) do
    if v.typed == UNTYPED then
      wordCompleted = false
      break
    end
  end
  
  if wordCompleted then
    self.isDead = true
    return true
  end
  
  return false

end
