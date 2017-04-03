#!/bin/which lua
-- Example query from the server.
--[[
{
  "processed": "-1",
  "hash": "0b61190cc4ee9687641fada82b0fb5934e7cd1c6d5282b46c75dffa666f829a4",
  "sponsor": "0",
  "channelUrl": "roosterteeth.com",
  "slug": "rt-podcast-2016-403-8-dfh7a",
  "showName": "Rooster Teeth Podcast",
  "title": "Gavin Free Can’t Say No - #403",
  "caption": "RT Discusses Not Responding to Emails",
  "description": "Join Gus Sorola, Gavin Free, Barbara Dunkelman, Burnie Burns, and special guest Zachary Levi as they discuss not responding to emails, Snapchat spectacles, the NES Classic Edition, and more on this week's RT Podcast! This episode originally aired on November 22, 2016, sponsored by Blue Apron (http://cook.ba/2dXsUgf), NatureBox (http://bit.ly/2fMco6d), Squarespace (http://bit.ly/2f0G0xM)",
  "image": "//s3.amazonaws.com/cdn.roosterteeth.com/uploads/images/b7496d76-7187-4c47-88ab-8823aff2766c/original/2013912-1479834119230-rtp403_-_THUMB.jpg",
  "imageMedium": "//s3.amazonaws.com/cdn.roosterteeth.com/uploads/images/b7496d76-7187-4c47-88ab-8823aff2766c/md/2013912-1479834119230-rtp403_-_THUMB.jpg",
  "releaseDate": "2016-11-22"
}
]]

-- Allows the libraries to be in a seperate folder from the code
package.path = package.path .. ';libraries/?.lua'

config	= require("config")

json	= require("json")
shell	= require("shell")
socket	= require("socket")
network	= require("network")

file = io.open("log.txt","a")

function log(input)
	print(input)
	file:write(os.date("%F %T - ")..input.."\n")
end

function exit()
	file:close()
	os.exit()
end

input = json.decode(network.get(config["remote_url"].."?action=getdownload"))
if input["error"] ~= nil then
	log("Cannot process video: '"..input["error"].."'")
	exit()
end

log("Downloading video '"..input["title"].."'")

shell.execute("/usr/local/bin/youtube-dl -u \""..config["username"].."\" -p \""..config["password"].."\" -o \""..input["hash"].."_temp.mp4\" \"https://"..input["channelUrl"].."/episode/"..input["slug"].."\"")

if input["showName"] == "RT Animated Adventures" then
	--"Custom" optimization. Because of the video's style, it can be compressed much more.
	shell.execute("ffmpeg -i \""..input["hash"].."_temp.mp4\" -c:v libx264 -crf 18 -preset slow  -c:a copy \""..input["hash"]..".mp4\"")
else
	--From http://superuser.com/a/522853/607043, need to look more into optimization.
	shell.execute("ffmpeg -i \""..input["hash"].."_temp.mp4\" -c:v libx264 -crf 22 -preset medium  -c:a copy \""..input["hash"]..".mp4\"")
end

--These variables are used for the formatting of the output.
size = shell.execute("du --block-size=MB \""..input["hash"]..".mp4\"")
info = shell.execute("avprobe -hide_banner \""..input["hash"]..".mp4\"")
info_int = string.find(info,"Duration: ")

output = {
	url = (config["local_url"].."/"..input["hash"]..".mp4")
	hash = input["hash"]
	size = string.sub(size,1,(string.find(size,"MB")-1))
	length = string.sub(info,info_int+10,(string.find(info,",",info_int)-4))
}

exec("rm \""..input["hash"].."_temp.mp4\"; mv \""..input["hash"]..".mp4 "..config["www_dir"].."/\"")
network.post(config["remote_url"].."?action=download_complete",json.encode(output))

exit()