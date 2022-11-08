Word = Object.extend(Object)

TYPED = {75/255, 255/255, 6/255, 1}
UNTYPED = {1,1,1,1}

local normalWordList = {}
local bossWordList = {}

for line in love.filesystem.lines("normal-word-list.txt") do
  table.insert(normalWordList, line)
end

for line in love.filesystem.lines("boss-word-list.txt") do
  table.insert(bossWordList, line)
end

function Word:new(boss)
  self.letters = selectWord(boss)
  
  self.isDead = false
  
end

function selectWord(boss)
  local newWord = {}
  if boss then
    newWord = bossWordList[love.math.random(1,#bossWordList)]
  else
    newWord = normalWordList[love.math.random(1,#normalWordList)]
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
