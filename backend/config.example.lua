config = {
	logfile = "";

	--Acceptible options: mysql. Maybe we can add support for other databases if required.
	database = "mysql";
	
	--Only applicable if using MariaDB/MySQL
	sql_name = "rtdownloader";
	sql_user = "";
	sql_pass = "";
	sql_addr = "127.0.0.1";
	sql_port = "3306";
}

return config