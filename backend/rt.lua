#!/bin/which lua
sqlite3 = require("lsqlite3")
db = sqlite3.open("rt.sqlite3") --Open a local file read/write, doesn't have to exist.

-- Table is MetaData because it contains basic information about a video;
db:exec("CREATE TABLE IF NOT EXISTS Metadata (processed INTEGER DEFAULT 0, name varchar(100) NOT NULL, time char(10) NOT NULL, show varchar(100) NOT NULL, url varchar(2048) NOT NULL, image varchar(2048) NOT NULL, hash char(64) NOT NULL, UNIQUE(name, show, url, image, hash))")
--Unique term stolen from here: http://stackoverflow.com/a/19343100/1687505

db:exec("CREATE TABLE IF NOT EXISTS RoosterTeeth (hash char(64) NOT NULL, time char(10) NOT NULL, title varchar(100) NOT NULL, show varchar(100) NOT NULL, description varchar(500) NOT NULL, season varchar(10) NOT NULL, UNIQUE(hash,title,show,description))")

--[[
Table: MetaData
processed boolean	--True if the video has been indexed (All data downloaded) and stored in another table.
hash char(64)		--SHA256sum encoded in ascii
name varchar(100)	--Assuming that title lengths are sane, and short. Based on youtube max title langth.
show varchar(100)	--Because Rooster Teeth is split up into sub channels, it is useful to grab the show name as well.
img  varchar(200)
url  varchar(200)	--Hopefully 200 characters will be long enough. 2048 is the maximum length, however most if not all will be shorter than that. 

Table: [SITE NAME]
hash 		char(64)
time 		char(10)		--Publication date (FOR SPONSORS) in the format yyyy-mm-dd
title		varchar(100)
show		varchar(100)
description varchar(1000)	--RWBY has 600 character descriptions, so it had to be upped from 500.
season		varchar(10)
]]

-- Todo:
--	[DONE] Create a sqlite3 database (Mentioned above for column types)
--	[DONE] Feed scraped results into mentioned sqlite table, checking for duplicates.
--	[DONE] Creating jobs to scrape additional metadata for the videos. 
--	[DONE] Move SHA256sum to a luarock compatible version, rather than rely on the OS command.
--
--	For the sqlite3 database, as the front-end is a READ ONLY implementation, should we load it into a RAMDisk and occasionally check for updates?

json = require("json")
http = require("socket.http")
-- We have both luasocket and luasec installed, however we will be using http for development purposes.
lsha2 = require("lsha2")

--[[ Old hash function. Kept for debug purposes.
function hash(input)
	input = string.lower(string.gsub(string.gsub(input,"%s",""),"%W",""))
	--So, what this does is 'standardize' the string. It strips the spaces, and removes all non-alphanumeric characters. 
	--It also converts all the letters to lowercase so typos are less likely to cause duplicated metadata.
	local handle = io.popen("echo \""..input.."\" | sha256sum")
	local out = string.sub(handle:read("*a"),1,64)
	handle:close()
	return out
end]]
function hash(input)
	local t = string.gsub(string.gsub(input,"%s",""),"%W","") --Strips spaces and non-alphanumeric characters. Part of "standardizing" the string.
	return lsha2.hash256(t) --Return sha256 hash of above string. 
end

function wget(url)
	--One line statement. Wow. Such savings.
	return (http.request(url))
end

function ScrapeNew()
	--Web scraper to get latest episodes to add to local database.
	--Grabs the _FIRST PAGE_ or 24 most recent videos from the recently added page.
	--Returns a table with the following datasets: name, url, image url, and finally a hash of the name for cross-table referencing.

	local data = wget("http://roosterteeth.com/episode/recently-added")

	local out = string.sub(data,(string.find(data,"<!-- =============== BEGIN PAGE BODY =============== -->",1,true)),(string.find(data,"<!-- =============== BEGIN FOOTER =============== -->",1,true)))
	-- Need to use plain searches as there are some special characters.
	local count = 0
--	local db = {} Used in development purposes. Returns a table that was converted into JSON for development purposes.
	--Prepared statement for SQL. Will be executed once for every single item. 
	local statement = db:prepare("INSERT OR IGNORE INTO Metadata(name, time, show, url, image, hash) VALUES(:name, :time, :show, :url, :image, :hash)")
	-- OR IGNORE -> Ignore duplicates. Corresponds to the unique term on line 7.
	out = string.gsub(out,"<li>","\029") -- Ascii Decimal 029 = group seperator ascii. Chosen as no sane webpage would have control ascii embedded.
	for value in string.gmatch(out,"[^\029]+") do
		if count ~= 0 and count < 25 then
			local a = string.find(value,"<a href=\"",1,true)+9
			url = string.sub(value,a,(string.find(value,"\">",a,true)-1))

			local b = string.find(value,"<img src=\"",1,true)+10 --Used twice, easier to cache value
			if string.find(value,"\" alt=") == nil then
				img = string.sub(value,b,(string.find(value,"\">",b,true)-1)) --Used to set search for end of phrase starting at beginning of phrase.
			else
				img = string.sub(value,b,(string.find(value,"\" alt=",b,true)-1))
			end

			local c = string.find(value,"<p class=\"name\">")+16
			name = string.sub(value,c,(string.find(value,"</p>",c,true)-1))

			local i = string.find(img,"-",(string.find(img,"md")),true)
			time = string.sub(img,i+1,i+10) --Timestamp is in milliseconds. Change "20" to "23" to include millisecond precision.
			statement:bind_names({name=name;time=time;show="Rooster Teeth";url=url;image=img;hash=hash(name);})
			local val = statement:step() 
			if val ~= 101 then
				print("Something went wrong... "..val)
			end
			statement:reset()

--			db[count] = {name=name;url=url;img=img;hash=hash(name)} --> Super creative naming scheme.
		end
		count = (count+1)
	end
--	return db
end

function ScrapeVideo(hash)
	for entry in db:nrows("SELECT * FROM Metadata where hash IS \""..hash.."\"") do --Yes. Potential for SQL Injection. Spooky.
		local raw = wget(entry["url"])

		local a = string.find(raw,"<div id=\"others-you-like-carousel-comment\">",1,true)+49
		local data = string.sub(raw,a,string.find(raw,"-->",a,true)-1)

		local statement = db:prepare("INSERT OR IGNORE INTO RoosterTeeth(hash, time, title, show, description, season) VALUES(:hash, :time, :title, :show, :description, :season)")
		for key,value in ipairs(json.decode(data)) do 
			if value["url"] == entry["url"] then
				statement:bind_names({hash=entry["hash"];time=string.sub(value["sponsor_golive_at"],1,10);title=value["title"];show=value["season"]["show"]["name"];description=value["description"];season=value["season"]["title"];})
				local val = statement:step() 
				if val ~= 101 then
					print("Something went wrong... "..val)
				end
				statement:reset()
			end
		end

		db:exec("UPDATE MetaData SET processed=1 WHERE hash is \""..hash.."\"")
	end
end

ScrapeNew()
for a in db:nrows("SELECT * FROM Metadata where processed IS 0;") do
	ScrapeVideo(a["hash"])
end

db:close()