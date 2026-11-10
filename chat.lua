--local stp = loadfile("/home/stp/stp.lua")()
local stp = require("stp")
local logging = require("logging")
local configLib = require("config")
local comp = require("computer")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local unicode = require("unicode")
--local event = require"event"
--------------------------------
local title, chat, messageInput, sendBtn, exitBtn  -- Объявление виджетов, чтобы они были видны в колбэках
local config = configLib.TableParser("./settings.cfg")
local GuiApp = GUI.application()
--------------------------------
-- Config --
--local remoteAddress = "d6eea981-44ed-4440-9781-9fb79b6c7740"
--local port = 82
local remoteAddress = config:get("remoteAddress")
local port = config:get("port")
local BG = 0x2D2D2D
local titleText = "STP Chat v0.2.0"
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

local function fromRemoteHostMessageHandlerForGui(eventName, thisAddr, remoteAddr, localPort, distance, data)
  logger:debug("fromRemoteHostMessageHandlerForGui CALLED")
  local displayPattern = "%.3s: %s"
  local messageText = data
  local displayText = displayPattern:format(remoteAddr, messageText)
  logger:debug("Trying to insert a line into `chat.lines` TextBox")
  local ok, err = pcall(function() table.insert(chat.lines, displayText) end)
  if not ok then
    logger:error("An exception occurred in `fromRemoteHostMessageHandlerForGui` (on table.insert):\n" .. err)
    return
  end
  --GuiApp:draw(true)  -- Перерисовываем TextBox, чтобы отобразить новые сообщения
  chat:draw()
  buffer.drawChanges()
  logger:info("Received new message | " .. displayText)
  logger:debug("fromRemoteHostMessageHandlerForGui CALL FINISHING")
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
--print("STP CHAT v0.1.0")
--logger:info("App launched")
--listenerId = stp.listen(port, fromRemoteHostMessageHandler)

--while true do
--  local inputMessage = io.read()
--  logger:info("Attempting to send message...")
--  sendMessage(inputMessage)
--  logger:info("The attempt has ended")
--end

title = GuiApp:addChild(GUI.label(GuiApp.width / 2 - unicode.len(titleText) / 2, 1, unicode.len(titleText), 1, 0xFFFFFF, titleText))
chat = GuiApp:addChild(GUI.textBox(2, 2, GuiApp.width - 2, GuiApp.height - 20 - 2, BG + 0x222222, 0xFFDDDD, {}, 1, 1, 1))
messageInput = GuiApp:addChild(GUI.input(2, GuiApp.height - 5, 100, 3, 0xEEEEEE, 0x000000, 0xB0B0B0, 0xFFFFFF, 0x000000))
--messageInput.historyEnabled = true
sendBtn = GuiApp:addChild(GUI.roundedButton(1 + messageInput.x + messageInput.width + 3, GuiApp.height - 5, 10, 3, 0xEEEEEE, 0x444444, 0x880000, 0xFFFFFF, "Send"))
exitBtn = GuiApp:addChild(GUI.button(152, 47, 6, 3, 0xFFFFFF, 0x444444, 0x880000, 0xBB4444, "Exit"))

exitBtn.onTouch = function()
  GuiApp:stop()
  logger:info("App exited")
end

sendBtn.onTouch = function()
  sendMessage(messageInput.text)
end

logger:info("App launched")

--listenerId = stp.listen(port, fromRemoteHostMessageHandlerForGui)
local ok, err = pcall(function() stp.listen(port, fromRemoteHostMessageHandlerForGui) end)
if ok then
  logger:debug("stp.listen CALLED SUCCESSFULLY | OK")
else
  logger:debug("stp.listen CALLED UNSUCCESSFULLY | Exception:\n" .. err)
end
--event.listen("touch", function() comp.beep(800, 1) os.fasd() comp.beep(1600, 1) end)

buffer.clear(BG)
GuiApp:draw(true)
GuiApp:start()
