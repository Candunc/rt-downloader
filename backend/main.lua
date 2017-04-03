#!/bin/which lua
if _VERSION ~= "Lua 5.3" then
	print("Possible incompatibility detected, using ".._VERSION..", expected Lua 5.3.\nDid you build from source?")
end

local config	= require("config")
local scrape	= require("scrape")

--Used to get command line arguments, work in progress.
for id,value in ipairs(arg) do
	if value == "--cron" then
		scrape.newVideos()

	elseif value == "--archive" then
		--Todo: Add support for sites using the name instead of the number.
		local a = tonumber(arg[id+1])
		if a ~= nil then
			scrape.allVideos(a)
		else
			print(arg[id+1].." is not a valid target to scrape.")
		end
	end
end

scrape.destroy()