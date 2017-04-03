-- Allows the libraries to be in a seperate folder from the code
package.path = package.path .. ';libraries/?.lua'

local scrape = {}

local config	= require("config")

local json		= require("json")
local lsha2		= require("lsha2")
local shell		= require("shell")
local driver	= require("luasql.mysql")
local socket	= require("socket")
local network	= require("network")

local env = driver.mysql()
conn,err = env:connect("rtdownloader",config["sql_user"],config["sql_pass"],config["sql_addr"],config["sql_port"])
if err ~= nil then
	print(err)
	os.exit()
end

--For MySQL, I'm using varbinary as I can store Unicode characters in it (EASILY) without it being bastardized by the engine.
conn:execute("CREATE TABLE IF NOT EXISTS Metadata (processed tinyint SIGNED DEFAULT 0, hash char(64) NOT NULL, sponsor tinyint, channelUrl varchar(32), slug varchar(100), showName varchar(100), title varbinary(800), caption varbinary(4000), description varbinary(4000), image varchar(200), imageMedium varchar(200), releaseDate char(10), m3u8URL varchar(200), unique(hash))")
conn:execute("CREATE TABLE IF NOT EXISTS Storage (locked TINYINT SIGNED DEFAULT 0, hash CHAR(64) NOT NULL, added CHAR(19) NOT NULL, node VARCHAR(32), url VARCHAR(200), size SMALLINT UNSIGNED, length CHAR(8), timeout CHAR(19), UNIQUE(hash) )")

-- Enable logging by default
if config["logfile"] == nil or config["logfile"] == "" then
	config["logfile"] = "./log.txt" -- "/opt/rt-downloader/log.txt"
end

local logfile,err = io.open(config["logfile"],"a")
if logfile == nil then
	local logfile,err = io.open("./log.txt","a")
	if logfile == nil then
		-- Close if we can't open the logfile
		print("Cannot open log file! Please check your config file.\n"..err)
		os.exit()
	end
end

-- We've removed the backwards compatibility check due to the refactoring
function getPage(id,page)
	log("Getting page "..page.." with site id of "..id.."\n")
	-- Limit is 24 as that matches the website call - Maybe they cache this result so take advantage of it
	local input = json.decode(network.get("http://roosterteeth.com/api/internal/episodes/recent?channel="..id.."&page="..page.."&limit=24"))
	if input == nil or input["data"] == nil or input["data"][1] == nil then
		return false --The RT Website doesn't actually return an error when asking for an 'empty' page, so this will hopefully stop it from getting out of control.
	else
		for _,value in ipairs(input["data"]) do
			local v = {}
			for key,value in pairs(prepareMetadata(value["attributes"])) do
				v[key] = conn:escape(tostring(value))
			end

			_,err = conn:execute(
				"INSERT IGNORE INTO Metadata(hash, sponsor, channelUrl, slug, showName, title, caption, description, image, imageMedium, releaseDate, m3u8URL) VALUES(\""..
				v["hash"]		.."\", \""..
				v["sponsor"]	.."\", \""..
				v["channelUrl"]	.."\", \""..
				v["slug"]		.."\", \""..
				v["showName"]	.."\", \""..
				v["title"]		.."\", \""..
				v["caption"]	.."\", \""..
				v["description"].."\", \""..
				v["image"]		.."\", \""..
				v["imageMedium"].."\", \""..
				v["releaseDate"].."\", \"".. 
				scrape.m3u8(
					"http://"..v["channelUrl"].."/episode/"..v["slug"]
				).."\")"
			)

			if err ~= nil then
				log:write(err.."\n")
			end
		end
		return true
	end
end

function hash(input)
	local t = string.lower(string.gsub(string.gsub(input,"%s",""),"%W","")) --Strips spaces and non-alphanumeric characters. Part of "standardizing" the string.
	return lsha2.hash256(t) --Return sha256 hash of above string.
end

function log(input)
	logfile:write(os.date("%F %T - ")..input.."\n")
end

function prepareMetadata(input)
	 -- We store boolean values as base2 because of sqlite limitations on boolean values.
	if input["isPremium"] == true then
		input["sponsor"] = 1
	else
		input["sponsor"] = 0
	end

	input["description"] = string.gsub(input["description"],"[\n]+", "\n")

	input["hash"] = hash(input["title"])
	input["releaseDate"] = string.sub(input["releaseDate"],1,10)

	return input
end


-- Public functions start here

function scrape.m3u8()
	-- This won't always succeed, either catch errors or force chromium to be running.
	-- Maybe on load start chromium, on end kill chromium?
	local webpage = shell.execute("node extractor.js \""..url.."\"")
	local _,pointA = string.find(webpage,"file: '",1,true)
	local   pointB = string.find(webpage,"'",start,true)

	return (string.sub(webpage,pointA,pointB))
end

function scrape.allVideos(id)
	log("Scraping all videos from id: "..id.."\nThis will take a while.")
	count = 2
	math.randomseed(os.time())
	while ScrapeNew_Helper(id,count) do
		count = (count+1)
		socket.sleep(1.3+(math.random(5,55)/100)) --Small delay, might take >5 minutes to do a single website. Reduces the load on the RT servers, so it can't be _that_ bad.
	end
end

function scrape.newVideos()
	local sites = {RoosterTeeth=0; AchievementHunter=1; TheKnow=2;}
	--RoosterTeeth=0; AchievementHunter=1; TheKnow=2; FunHaus=3; 4=???; ScrewAttack=5; CowChop=6; 7=???; GameAttack=8; <9 Does not exist as of 2016-11-15.

	for site,id in pairs(sites) do
		getPage(id,1)
	end
end

function scrape.destroy()
	conn:close()
	logfile:close()
end

return scrape