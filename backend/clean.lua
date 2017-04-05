#!/bin/which lua

local config	= require("config")
local driver	= require("luasql.mysql")

local env = driver.mysql()
conn,err = env:connect("rtdownloader",config["sql_user"],config["sql_pass"],config["sql_addr"],config["sql_port"])
if err ~= nil then
	print(err)
	os.exit()
end

-- This file exists as something to call to cleanup the storage database and to perform other maintainance tasks.
-- It is recommended to run it every four hours.

conn:execute("UPDATE Storage SET locked=0,node=NULL,url=NULL,size=NULL,timeout=NULL WHERE locked=-1 AND timeout < DATE_SUB(NOW(), INTERVAL 4 HOUR)")

conn:close()