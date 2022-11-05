Word = Object.extend(Object)

TYPED = {240/255, 45/255, 255/255}
UNTYPED = {1,1,1}

local wordList = {}

for line in love.filesystem.lines("word-list-l5.txt") do
  table.insert(wordList, line)
end

function Word:new()
  self.letters = selectWord()
  
  self.isDead = false
  
end

function selectWord()
    local testWord = wordList[love.math.random(1,#wordList)]
    
    local ltrs = {}
    
    for i = 1, #testWord do
      table.insert(ltrs, {
          typed=UNTYPED,
          ch=testWord:sub(i,i)
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
