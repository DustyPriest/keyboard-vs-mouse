Word = Object.extend(Object)

TYPED = {r=240/255, g=45/255, b=255/255}
UNTYPED = {r=1,g=1,b=1}

local wordList = {}

for line in love.filesystem.lines("word-list.txt") do
  table.insert(wordList, line)
end

function Word:new()
  self.letters = selectWord()
  
  self.isActive = false
  
end

function selectWord()
    testWord = wordList[math.random(1,#wordList)]
    
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
    return true
  end
  
  return false

end
