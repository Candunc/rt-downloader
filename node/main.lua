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

-- A lot of this code is going to be blatant copy/paste from the backend. However, I don't believe it is worth it to make a unified library.

		  require("config")
json	= require("json")
socket	= require("socket")
http	= require("socket.http")
https	= require("ssl.https")
ltn12	= require("ltn12")

file = io.open("log.txt","a")

function wget(url)
	local protocol = string.sub(url,1,5)
	if protocol == "https" then
		local output = {}
		https.request{url=url,sink=ltn12.sink.table(output),headers={USER_AGENT="luasec/0.6.1 (rtdownloader)"},protocol="tlsv1_2"}

		return table.concat(output)
	elseif protocol == "http:" then
		local output = {}
		http.request{url=url,sink=ltn12.sink.table(output),headers={USER_AGENT="luasocket/3.0 (rtdownloader)"}}

		return table.concat(output)
	else
		log("Error fetching url '"..url.."', ignoring")
		return ""
	end
end

function post(url,body)
	local protocol = string.sub(url,1,5)
	if protocol == "https" then
		local output = {}
		https.request{method="POST",url=url,source=ltn12.source.string(body),sink=ltn12.sink.table(output),headers={USER_AGENT="luasec/0.6.1 (rt-downloader)",["content-type"]="text/plain",["content-length"]=tostring(#body)},protocol="tlsv1_2"}

		return table.concat(output)
	elseif protocol == "http:" then
		local output = {}
		http.request{method="POST",url=url,source=ltn12.source.string(body),sink=ltn12.sink.table(output),headers={USER_AGENT="luasocket/3.0 (rt-downloader)",["content-type"]="text/plain",["content-length"]=tostring(#body)}}

		return table.concat(output)
	else
		log("Error fetching url '"..url.."', ignoring")
		return ""
	end
end

function exec(command)
--	Execute command but throw away all output. We shouldn't need it as the program should be blocked while execution takes place.
	os.execute(command.." /dev/null 2>/dev/null")
end

function log(input)
	print(input)
	file:write(os.date("%F %T - ")..input.."\n")
end

function exit()
	file:close()
	os.exit()
end

input = json.decode(wget(config["remote_url"].."?action=getdownload"))
if input["error"] ~= nil then
	log("Cannot process video: '"..input["error"].."'")
	exit()
end

log("Downloading video '"..input["title"].."'")

exec("/usr/local/bin/youtube-dl -u \""..config["username"].."\" -p \""..config["password"].."\" -o \""..input["hash"].."_temp.mp4\" \"https://"..input["channelUrl"].."/episode/"..input["slug"].."\"")

--From http://superuser.com/a/522853/607043, need to look more into optimization.
exec("ffmpeg -i \""..input["hash"].."_temp.mp4\" -c:v libx264 -crf 18 -preset medium  -c:a copy \""..input["hash"]..".mp4\"")
exec("rm \""..input["hash"]..".mp4\"")

--Now here is where we report the completed video to the frontend.

exit()