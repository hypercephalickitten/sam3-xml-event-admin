local players = {}

-- a switch function, taken from http://lua-users.org/wiki/SwitchStatement 
local function switch(table)
  table.case = function (self, x)
    local f = self[x] or self.default
    if f then
      if type(f) == "function" then
        f(x, self)
      else
        error("case "..tostring(x).." not a function")
      end
    end
  end
  return table
end

-- get tag name, attributes and text from single XML elements, adapted from http://lua-users.org/wiki/LuaXml
local function processXML(string)
  local table = {}
  local i, close, tag, attributes, x
  local k, j = 1, 1
  while true do
    i, j, close, tag, attributes, x = string.find(string, "<(%/?)([%w:]+)(.-)(%/?)>", k)
    if not i then break end
    local text = string.sub(string, k, i-1)
    if close == "/" then
       table["text"] = string.lower(text)
    end
    if close == "" then
       table["tag"] = tag
       local i, attr, value
       local k, j = 1, 1
       while true do
          i, j, attr, value = string.find(attributes, "%s(%w+)=\"(.-)\"", k)
          if not i then break end
          table[attr] = string.lower(value)
       k = j+1
       end
    end
    k = j+1
  end
  return table
end

-- players can be banned/kicked by in-game id or steamid
local function playerAction(command, target)
  local i
  -- check for in-game id (two digits at the most), see gamListPlayers
  if string.len(target) <= 2 and string.find(target, "%d%d?") then
    if command == "ban" then
      print("Kicking and banning player with index " .. target) 
      gamBanByIndex(target)
      gamKickByIndex(target)
    elseif command == "kick" then
      print("Kicking player with index " .. target) 
      gamKickByIndex(target)
    end 
  -- else, assume player name
  else
    for key, value in pairs(players) do
      i = string.find(value, target)
      if i then
        if command == "ban" then
          print("Kicking and banning " .. value .. "with id " .. key)
          gamBanByName(value)
          gamKickByName(value)
          break
        elseif command == "kick" then
          print("Kicking " .. value .. "with id " .. key)
          gamKickByName(value)
          break
        end
      end
    end
    if not i then
      print("No such player")
    end
  end
end

-- handle arguments for .restart command
local function gameAction(target)
  local action = {
    ["map"]    = function () samRestartMap() end,
    ["game"]   = function () gamRestartGame() end,
    ["server"] = function () gamRestartServer() end,
  } 
  action[target]()
end

-- parse chat commands
local function processChat(event)
  local table = {}
  local i
  -- playerid should be in admin list
  i = string.find(globals.ser_strAdminList, event["playerid"])
  if i ~= nil then
    print("Authenticated as " .. event["playerid"])
    local i, x, command, target
    -- check for command and argument
    i, x, command, target = string.find(event["text"], "(%.%w+)%s+(.+)")
    table["command"] = command
    table["target"]  = target
    -- check for single command
    if table["command"] == nil then
       i, x, command = string.find(event["text"], "(%.%w+)")
       table["command"] = command
    end

    -- valid commands    
    local action = switch {
      [".kick"] = function () playerAction("kick", table["target"]) end,
      [".ban"]  = function () playerAction("ban", table["target"]) end,
      
      [".pass"] = function () samVotePass() end,
      [".fail"] = function () samVoteFail() end,

      [".nextmap"] = function () samNextMap() end,
      [".restart"] = function () gameAction(table["target"]) end,
      [".start"]   = function () gamStart() end,
      [".stop"]    = function () gamStop() end,
      [".pause"]   = function () samPauseGame() end,
     
      default = function () end,
    }

    action:case(table["command"])
  end
end

-- event handling
RunHandled(
  function()
    WaitForever()
  end,
      
  OnEvery(CustomEvent("XML_Log")),
    function(XMLEvent)
      local Line  = XMLEvent:GetLine()
      local event = processXML(Line)

      local action = switch {
        -- add player to players table
        ["playerjoined"] = function () players[event["playerid"]] = event["player"] end,
        -- remove player from players table
        ["playerleft"] = function () players[event["playerid"]] = nil end,
        -- process chat events, ignore admin say()
        ["chat"] = function () if event["playerid"] ~= "[admin]" then processChat(event) end end,
        
        default = function () end,
      }
      
      action:case(event["tag"])
    end
)
