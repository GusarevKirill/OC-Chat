--local stp = loadfile("/home/stp/stp.lua")()
local stp = require("stp")
local logging = require("logging")
local configLib = require("config")
local comp = require("computer")
--------------------------------
local config = configLib.TableParser("./settings.cfg")
--------------------------------
-- Config --
--local remoteAddress = "d6eea981-44ed-4440-9781-9fb79b6c7740"
--local port = 82
local remoteAddress = config:get("remoteAddress")
local port = config:get("port")
--------------------------------
local listenerId
local logger = logging.getLogger("chat.log")
--------------------------------
local function fromRemoteHostMessageHandler(eventName, thisAddr, remoteAddr, localPort, distance, data)
  local displayPattern = "%.3s: %s"
  local messageText = data
  local displayText = displayPattern:format(remoteAddr, messageText)
  print(displayText)
  logger:info("Received new message | " .. displayText)
end

local function sendMessage(messageText)
  local success = stp.send(remoteAddress, port, messageText)
  if success then
    comp.beep(nil, 0)
    logger:info(("Message \"%s\" has been sent successfully"):format(messageText))
  else
    comp.beep(nil, 1)
    logger:error(("Message \"%s\" was not sent"):format(messageText))
  end
end
--------------------------------
print("STP CHAT v0.0.1")
logger:info("App launched")
listenerId = stp.listen(port, fromRemoteHostMessageHandler)

while true do
  local inputMessage = io.read()
  logger:info("Attempting to send message...")
  sendMessage(inputMessage)
  logger:info("The attempt has ended")
end