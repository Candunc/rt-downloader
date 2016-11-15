#!/bin/which lua
sqlite3 = require("lsqlite3")
db = sqlite3.open("rt.sqlite3") --Open a local file read/write, doesn't have to exist.

-- Table is MetaData because it contains basic information about a video;
db:exec("CREATE TABLE IF NOT EXISTS Metadata (processed int default 0, hash char(64) NOT NULL, sponsor int, channelUrl varchar(32), slug varchar(100), showName varchar(100), title varchar(200), caption varchar(1000), description varchar(1000), image varchar(200), imageMedium varchar(200), releaseDate char(10), unique(hash))")

--[[ Disabled as rewrite of main code is underway. 
for _,value in ipairs({"RoosterTeeth";"TheKnow";}) do --Starting small with a whole TWO tables. Insert the following into the table to enable: "AchievementHunter";"Funhaus";"ScrewAttack";"GameAttack";"CowChop";
	db:exec("CREATE TABLE IF NOT EXISTS "..value.." (hash char(64) NOT NULL, time char(10), release char(10), sponsor INTEGER, title varchar(100) NOT NULL, show varchar(100) NOT NULL, description varchar(500), season varchar(10), UNIQUE(hash,title,description))")
end]]

--[[
Table: Metadata **NEW** with updates to the RoosterTeeth site this table has been completely changed. Good thing we're not in production.
processed	int				Base2 Boolean (0,1); 1 if data has been scraped from the respective webpage.
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


The following table will likely have to be redone.

Table: [SITE NAME]
hash 		char(64)
time 		char(10)		--Publication date (FOR SPONSORS) in the format yyyy-mm-dd
release		char(10)		--**NEW** Publication date for non-sponsor accounts (Not public). NOTE: If this is the same as time, then it is sponsor only content.
sponsor		boolean			--**NEW** Checks if the video is restricted to sponsors.
title		varchar(100)
show		varchar(100)
description varchar(1000)	--RWBY has 600+ character descriptions, so it had to be upped from 500.
season		varchar(10)
]]

require("socket")
json = require("json")
http = require("socket.http")
https = require("ssl.https")
lsha2 = require("lsha2")

function hash(input)
	local t = string.lower(string.gsub(string.gsub(input,"%s",""),"%W","")) --Strips spaces and non-alphanumeric characters. Part of "standardizing" the string.
	return lsha2.hash256(t) --Return sha256 hash of above string.
end

function wget(url)
	--One line statement. Wow. Such savings.
	return (http.request(url))
end

function swget(url) --Added for https support. Not currently required as https is a lot harder to process compared to http.
	return (https.request(url))
end

function ScrapeNew_Helper(id)
	local input = json.decode(wget("http://roosterteeth.com/api/internal/episodes/recent?channel="..id.."&page=1&limit=24"))
	local statement = db:prepare("INSERT OR IGNORE INTO Metadata(hash, sponsor, channelUrl, slug, showName, title, caption, description, image, imageMedium, releaseDate) VALUES(:hash, :sponsor, :channelUrl, :slug, :showName, :title, :caption, :description, :image, :imageMedium, :releaseDate)")

	for _,value in ipairs(input["data"]) do
		if value["attributes"]["isPremium"] == true then
			value["attributes"]["sponsor"] = 1 -- We store boolean values as base2 because of sqlite limitations on boolean values.
		else
			value["attributes"]["sponsor"] = 0
		end

		value["attributes"]["description"] = string.gsub(value["attributes"]["description"],"[\n]+", "\n")

		value["attributes"]["hash"] = hash(value["attributes"]["title"])
		value["attributes"]["releaseDate"] = string.sub(value["attributes"]["releaseDate"],1,10)

		statement:bind_names(value["attributes"])
		local val = statement:step() 
		if val ~= 101 then
			print("Something went wrong... "..val)
			print(db:errcode(),db:errmsg())
			os.exit()
		end
		statement:reset()
	end
end

function ScrapeArchive() -- WARNING. This will produce a lot of I/O and network requests. It is _NOT_ a good idea to DOS the RT website.

end

function ScrapeNew()
	local input = {RoosterTeeth=0;}
	--RoosterTeeth=0; AchievementHunter=1; TheKnow=2; FunHaus=3; 4=???; ScrewAttack=5; CowChop=6; 7=???; GameAttack=8; <9 Does not exist as of 2016-11-15.
	for site,id in pairs(input) do
		ScrapeNew_Helper(id)
	end
end

function ScrapeVideo(hash,site)
	for entry in db:nrows("SELECT * FROM Metadata where hash IS \""..hash.."\"") do --Yes. Potential for SQL Injection. Spooky.
		log("Working on video: "..hash)
		local raw = wget(entry["url"])

		local a = string.find(raw,"<div id=\"others-you-like-carousel-comment\">",1,true)+49
		local data = string.sub(raw,a,string.find(raw,"-->",a,true)-1)

		local statement = db:prepare("INSERT OR IGNORE INTO "..site.."(hash, time, release, sponsor, title, show, description, season) VALUES(:hash, :time, :release, :sponsor, :title, :show, :description, :season)")
		for key,value in ipairs(json.decode(data)) do 
			if value["url"] == entry["url"] then
				description = value["description"]
				description = string.gsub(description,"[\n]+", "\n")

				--This only proves that it is sponsor-only content when scraped. Need to check it after a specfified time.
				--Perhaps something like "IF release == [today's date] AND sponsor == 1 " check if it's still sponsored & update.
				if value["star"] == true then
					sponsor=1
				else
					sponsor=0
				end

				statement:bind_names({hash=entry["hash"];time=string.sub(value["sponsor_golive_at"],1,10);release=string.sub(value["member_golive_at"],1,10);sponsor=sponsor;title=value["title"];show=value["season"]["show"]["name"];description=description;season=value["season"]["title"];})
				local val = statement:step() 
				if val ~= 101 then
					print("Something went wrong... "..val)
					print(db:errcode(),db:errmsg())
				end
				statement:reset()
				break
			end
		end

		db:exec("UPDATE Metadata SET processed=1 WHERE hash is \""..hash.."\"")
	end
end

function UpdateFrontend()
	local output = {}
	local count = 0
	for entry in db:nrows("SELECT * FROM ( SELECT * FROM Metadata ORDER BY releaseDate DESC LIMIT 12 ) T1 ORDER BY releaseDate DESC") do
		count = (count+1)
		output[count] = entry
	end

	local file = io.open("frontpage.json","w")
	file:write(json.encode(output))
	file:close()
end

function log(input) --Rather than printing directly to stdout, add ability to disable informative text.
	if verbose == true then
		print(input)
	end
end

verbose = true -- global variable, we're going to enable it for development purposes.

--[[ 
--Used to get command line arguments, work in progress.
for _,value in ipairs(arg) do
	if value == "-v" then
		verbose = true
	end
end]]

ScrapeNew()
--[[ Disabled as code is being rewritten.
for a in db:nrows("SELECT * FROM Metadata WHERE processed IS 0;") do
	ScrapeVideo(a["hash"],a["site"])
end
]]
UpdateFrontend()

db:close()