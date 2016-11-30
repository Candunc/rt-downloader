#!/bin/which lua
if _VERSION ~= "Lua 5.3" then
	print("Possible incompatibility detected, using ".._VERSION..", expected Lua 5.3.\nDid you build from source?")
end

require("config")

json	= require("json")
lsha2	= require("lsha2")

socket	= require("socket")
http	= require("socket.http")
https	= require("ssl.https")
ltn12	= require("ltn12")

local driver = require("luasql.mysql")
local env = driver.mysql()
conn,err = env:connect("rtdownloader",config["sql_user"],config["sql_pass"],config["sql_addr"],config["sql_port"])
if err ~= nil then
	print(err)
	os.exit()
end

--For MySQL, I'm using varbinary as I can store Unicode characters in it (EASILY) without it being bastardized by the engine.
conn:execute("CREATE TABLE IF NOT EXISTS Metadata (processed tinyint SIGNED DEFAULT 0, hash char(64) NOT NULL, sponsor tinyint, channelUrl varchar(32), slug varchar(100), showName varchar(100), title varbinary(800), caption varbinary(4000), description varbinary(4000), image varchar(200), imageMedium varchar(200), releaseDate char(10), unique(hash))")

conn:execute("CREATE TABLE IF NOT EXISTS Storage (locked TINYINT SIGNED DEFAULT 0, hash CHAR(64) NOT NULL, added CHAR(19) NOT NULL, node VARCHAR(32), url VARCHAR(200), size VARCHAR(6), timeout CHAR(19), UNIQUE(hash) )")

function hash(input)
	local t = string.lower(string.gsub(string.gsub(input,"%s",""),"%W","")) --Strips spaces and non-alphanumeric characters. Part of "standardizing" the string.
	return lsha2.hash256(t) --Return sha256 hash of above string.
end

function wget(url)
	--The following if statement _does_ add some overhead, but it allows for both http and https calls to be processed.
	local protocol = string.sub(url,1,5)
	if protocol == "https" then
		local output = {}
		https.request{url=url,sink=ltn12.sink.table(output),headers={USER_AGENT="luasec/0.6.1 (rt-downloader)"},protocol="tlsv1_2"}

		return table.concat(output)
	elseif protocol == "http:" then
		local output = {}
		http.request{url=url,sink=ltn12.sink.table(output),headers={USER_AGENT="luasocket/3.0 (rt-downloader)"}}

		return table.concat(output)
	else
		log("Error fetching url '"..url.."', ignoring")
		return "" --Empty string returned rather than nil
	end
end

function Metadata_prepare(input)
	if input["isPremium"] == true then
		input["sponsor"] = 1 -- We store boolean values as base2 because of sqlite limitations on boolean values.
	else
		input["sponsor"] = 0
	end

	input["description"] = string.gsub(input["description"],"[\n]+", "\n")

	input["hash"] = hash(input["title"])
	input["releaseDate"] = string.sub(input["releaseDate"],1,10)

	return input
end

function ScrapeNew_Helper(id,page)
	page = page or 1 --Backwards compatibility (Since this was originally used for _new_ pages only.)
	log("Getting page "..page.." with site id of "..id)
	local input = json.decode(wget("http://roosterteeth.com/api/internal/episodes/recent?channel="..id.."&page="..page.."&limit=24"))
	if input == nil or input["data"] == nil or input["data"][1] == nil then
		return false --The RT Website doesn't actually return an error when asking for an 'empty' page, so this will hopefully stop it from getting out of control.
	else
		for _,value in ipairs(input["data"]) do

			--sigh. It's almost not worth it to escape.
			local v = {}
			for key,value in pairs(Metadata_prepare(value["attributes"])) do
				v[key] = conn:escape(tostring(value))
			end

			-- I didn't do this by hand (Thankfully I can replace all 12 values with the right crap in one command). Hopefully it still, uh, works.
			_,err = conn:execute("INSERT IGNORE INTO Metadata(hash, sponsor, channelUrl, slug, showName, title, caption, description, image, imageMedium, releaseDate) VALUES(\""..v["hash"].."\", \""..v["sponsor"].."\", \""..v["channelUrl"].."\", \""..v["slug"].."\", \""..v["showName"].."\", \""..v["title"].."\", \""..v["caption"].."\", \""..v["description"].."\", \""..v["image"].."\", \""..v["imageMedium"].."\", \""..v["releaseDate"].."\")")
			if err ~= nil then
				log(err)
			end
		end
		return true
	end
end

function ScrapeArchive(id)
	-- WARNING. This will produce a lot of I/O and network requests. It is _NOT_ a good idea to DOS the RT website.
	--Assumes that there is nothing in the database whatsoever beyond the first page.
	log("Scraping all pages. This may take a while.")
	count = 2
	math.randomseed(os.time())
	while ScrapeNew_Helper(id,count) do
		count = (count+1)
		socket.sleep(1.3+(math.random(5,55)/100)) --Small delay, might take >5 minutes to do a single website. Reduces the load on the RT servers, so it can't be _that_ bad.
	end
end

function ScrapeNew()
	local input = {RoosterTeeth=0; TheKnow=2;}
	--RoosterTeeth=0; AchievementHunter=1; TheKnow=2; FunHaus=3; 4=???; ScrewAttack=5; CowChop=6; 7=???; GameAttack=8; <9 Does not exist as of 2016-11-15.
	for site,id in pairs(input) do
		ScrapeNew_Helper(id)
	end
end

function Update()
	log("Update functionality not implemented. Exiting...")
	os.exit()
end

function CleanDB()
	--Any maintanance scripts for the database belong here. Recommended running every four hours.

	--This statement cleans any video that has been set to process, however hasn't returned after four hours. 
	conn:execute("UPDATE Storage SET locked=0,node=NULL,url=NULL,size=NULL,timeout=NULL WHERE locked=-1 AND timeout < DATE_SUB(NOW(), INTERVAL 4 HOUR)")
end

--INSERT INTO Storage(hash,added,timeout) VALUES("0b61190cc4ee9687641fada82b0fb5934e7cd1c6d5282b46c75dffa666f829a4",NOW(),DATE_ADD(NOW(), INTERVAL 4 HOUR))
function log(input)
	if verbose then --Same as verbose == true
		print(input)
	end

	--So errors can go to both stdout and logfile
	if logging then
		logfile:write(os.date("%F %T - ")..input.."\n")
	end
end

--Used to get command line arguments, work in progress.
for id,value in ipairs(arg) do
	if value == "--cron" then
		ScrapeNew()

	elseif value == "--archive" then
		local a = tonumber(arg[id+1])
		if a ~= nil then
			ScrapeArchive(a)
		else
			print(arg[id+1].." is not a valid target to scrape.")
		end

	elseif value == "--update" then
		logging = true
		update()

		conn:close()
		os.exit()

	elseif value == "--log" then
		logging = true
		logfile = io.open("/opt/rt-downloader/log.txt","a")

	elseif value == "-v" then
		verbose = true
	end
end

if logging then
	logfile:close()
end

conn:close()