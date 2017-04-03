local network = {}
network["VERSION"] = "0.0.1"

local http  = require("socket.http")
local https = require("ssl.https")
local ltn12 = require("ltn12")

-- Seperate function to avoid code duplication
function getProtocol(url)
	-- Grab the first five characters, containing (hopefully) the URL's scheme and seperation characters
	return (string.sub(1,5))
end

function network.get(url)
	local output = {}
	local protocol = getProtocol(url)
	if protocol == "https" then
		https.request{url=url,sink=ltn12.sink.table(output),headers={USER_AGENT="luasec/0.6.1 (rt-downloader)"},protocol="tlsv1_2"}
	elseif protocol == "http:" then
		http.request{url=url,sink=ltn12.sink.table(output),headers={USER_AGENT="luasocket/3.0 (rt-downloader)"}}
	else
		-- TODO: Handle invalid schemes
		return ""
	end

	return table.concat(output)
end

function network.post(url,body)
	local output = {}
	local protocol = getProtocol(url)
	if protocol == "https" then
		https.request{method="POST",url=url,source=ltn12.source.string(body),sink=ltn12.sink.table(output),headers={USER_AGENT="luasec/0.6.1 (rt-downloader)",["content-type"]="text/plain",["content-length"]=tostring(#body)},protocol="tlsv1_2"}
	elseif protocl == "http:" then
		http.request{method="POST",url=url,source=ltn12.source.string(body),sink=ltn12.sink.table(output),headers={USER_AGENT="luasocket/3.0 (rt-downloader)",["content-type"]="text/plain",["content-length"]=tostring(#body)}}
	else
		-- TODO: Handle invalid schemes
		return ""
	end

	return table.concat(output)
end

return network