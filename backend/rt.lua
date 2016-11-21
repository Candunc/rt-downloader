#!/bin/which lua
sqlite3 = require("lsqlite3")
db = sqlite3.open("rt.sqlite3") --Open a local file read/write, doesn't have to exist.

-- Table is MetaData because it contains basic information about a video;
db:exec("CREATE TABLE IF NOT EXISTS Metadata (processed int default 0, hash char(64) NOT NULL, sponsor int, channelUrl varchar(32), slug varchar(100), showName varchar(100), title varchar(200), caption varchar(1000), description varchar(1000), image varchar(200), imageMedium varchar(200), releaseDate char(10), unique(hash))")

--[[
db:exec("CREATE TABLE IF NOT EXISTS Storage (hash char(64) NOT NULL, url varchar(100), unique(hash)")
]]

--[[
Table: Metadata **NEW** with updates to the RoosterTeeth site this table has been completely changed. Good thing we're not in production.
processed	int				Base2 Boolean (0,1); 1 if video has been downloaded (And therefore put into the Storage table.)
hash 		char(64)		hash of title, used for linking additional information across tables.

sponsor		int				Boolean, states if a title is restricted to sponsors or not.
channelUrl	varchar(32)		Base portion of the URL
slug		varchar(100)	Final portion of the URL; points to the webpage
showName	varchar(100)	The name of the show, IE "Rooster Teeth Podcast"
title		varchar(200)	The title of the episode
caption		varchar(1000)	Tagline of episode?
description	varchar(1000)	Plain (no HTML tags) description.
image		varchar(200)	Full resolution episode image
imageMedium	varchar(200)	Reduced resolution image (960px × 540px)
releaseDate char(10)		Time episode was added to website, eg "2016-11-15"


Table: Storage
hash	char(64)		Unique hash of title, inherited from Metadata.
url		varchar(100)	The url to the media (Allows for distribution of the videos)
???		???				Table is incomplete... not yet finished the implementation.
]]

json	= require("json")
lsha2	= require("lsha2")

socket	= require("socket")
http	= require("socket.http")
https	= require("ssl.https")

function hash(input)
	local t = string.lower(string.gsub(string.gsub(input,"%s",""),"%W","")) --Strips spaces and non-alphanumeric characters. Part of "standardizing" the string.
	return lsha2.hash256(t) --Return sha256 hash of above string.
end

function wget(url)
	--The following if statement _does_ add some overhead, but it allows for both http and https calls to be processed.
	local protocol = string.sub(url,1,5)
	if protocol == "https" then
		return (https.request(url))
	elseif protocol == "http:" then
		return (http.request(url))
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
		local statement = db:prepare("INSERT OR IGNORE INTO Metadata(hash, sponsor, channelUrl, slug, showName, title, caption, description, image, imageMedium, releaseDate) VALUES(:hash, :sponsor, :channelUrl, :slug, :showName, :title, :caption, :description, :image, :imageMedium, :releaseDate)")
		for _,value in ipairs(input["data"]) do
			statement:bind_names(Metadata_prepare(value["attributes"]))
			local val = statement:step() 
			if val ~= 101 then
				print("Something went wrong... "..val)
				print(db:errcode(),db:errmsg())
				os.exit()
			end
			statement:reset()
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
	local input = {RoosterTeeth=0;} 
	--RoosterTeeth=0; AchievementHunter=1; TheKnow=2; FunHaus=3; 4=???; ScrewAttack=5; CowChop=6; 7=???; GameAttack=8; <9 Does not exist as of 2016-11-15.
	for site,id in pairs(input) do
		ScrapeNew_Helper(id)
	end
end

function UpdateFrontend()
	--This function alone takes 60 ms to execute (Including program initialization overhead), so I doubt it's worth it to build in a function to ignore updates w/ no changes.
	local output = {}
	local count = 0
	for entry in db:nrows("SELECT * FROM ( SELECT * FROM Metadata ORDER BY releaseDate DESC LIMIT 24 ) T1 ORDER BY releaseDate DESC") do
		count = (count+1)
		output[count] = entry
	end

	local file = io.open("frontpage.json","w")
	file:write(json.encode(output))
	file:close()
end

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
		UpdateFrontend()

	elseif value == "--archive" then
		local a = tonumber(arg[id+1])
		if a ~= nil then
			ScrapeArchive(a)
		else
			print(arg[id+1].." is not a valid target to scrape.")
		end

	elseif value == "--log" then
		logging = true
		logfile = io.open("/opt/rt-downloader/log.txt","a")

	elseif value == "-v" then
		verbose = true

	else
		print("No arguments given, exiting...")
	end
end

if logging then
	logfile:close()
end

db:close()