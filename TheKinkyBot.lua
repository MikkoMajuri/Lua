--[[ TheKinkyBot in Telegram - by mikma 2016, http://www.kinky.fi, mikko.majuri@gmail.com ]]

dofile("config.lua")

local admins = config.admins
local groups = config.groups
local commands = config.commands
local token = config.token

local emojitable = { "\xF0\x9F\x98\x81", "\xF0\x9F\x98\x82", "\xF0\x9F\x98\x83", "\xF0\x9F\x98\x8B", "\xF0\x9F\x98\x8D", "\xF0\x9F\x98\x9C", "\xF0\x9F\x98\x9D", "\xF0\x9F\x98\xA8", "\xF0\x9F\x98\xAD", "\xF0\x9F\x98\xB7", }

-- create and configure new bot with set token
local bot, extension = require("lua-bot-api").configure(token)

-- 
local function logprint(name,msg,id)
	local admin = " "
	if admins[id] then
		admin = " Admin "
	end
	io.write(os.date("%x %X") .. admin .. name .. ": " .. msg .."\n")
end

-- override onMessageReceive function so it does what we want
extension.onTextReceive = function (msg)
	local log = false
	if msg.text == "/start" then
 		bot.sendMessage(msg.from.id, "Hello there 👋\nMy name is " .. bot.first_name)
	elseif msg.text == "ping" then
		bot.sendMessage(msg.chat.id, "pong!")
	else
		if admins[msg.from.id] then
			local command = msg.text:match("!(%S*)") -- check text after '!"
			if commands[command] then -- is 'command' in the allwed list ?
				local n = os.tmpname () -- get a temporary file name
				os.execute (msg.text:sub(2) .. " > ".. n) -- remove ! from msg.text, execute a command
				local temptext = ""
				logprint(msg.from.username,msg.text,msg.from.id)
				for line in io.lines (n) do -- display output
					temptext = temptext .. line .. "\n"
				end
				bot.sendMessage(msg.chat.id, "`"..temptext.."`", "Markdown") -- Send as Markdown
				os.remove (n) -- remove temporary file
			else
				--print("Wrong command")
			end
		end
	end

	-- predefined group goodness goes here
	if groups[msg.chat.id] then

	end		
end

-- override onPhotoReceive as well
extension.onPhotoReceive = function (msg)
	--print("Photo received!")
	--bot.sendMessage(msg.chat.id, "Nice photo! It dimensions are " .. msg.photo[1].width .. "x" .. msg.photo[1].height)
	
	-- The following script will check pictures from two id's, does a random 1-10, if 5 = prints a random emoji from table.
	if msg.from.id == 205271900 or msg.from.id == 241962837 then
		math.randomseed( os.time() )
		local random = math.random(1,10)
		if random == 5 then -- random 5 from 1-10
			logprint(msg.from.username," <- Random emoji replied to picture",msg.from.id)
                        local randomemoji = math.random(1,#emojitable)
                        bot.sendMessage(msg.chat.id, emojitable[randomemoji])
		end
	end
end

-- This runs the internal update and callback handler
-- you can even override run()
extension.run()
