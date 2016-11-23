<?php
function invalid() {
	http_response_code(400);
	echo('400 Bad Request');
	safe_close();
}

function safe_close() {
	#Although not closing databases when doing read-operations seems to be alright, we are doing write operations now.
	#Since we now have a number of workers writing to the same table, maybe we need to move to MariaDB.
	$queue->close();
	$db->close();
	die();
}

if (!isset($_GET['action'])) { invalid(); }
$action = $_GET['action'];


#We have a seperate database as to prevent locking from the main thread, plus we may have multiple threads reading/writing to this. 
$queue = new SQLite3('/opt/rt-downloader/api.sqlite3');
$queue->exec('CREATE TABLE IF NOT EXISTS Queue (hash char(64) NOT NULL, added char(19) DEFAULT CURRENT_TIMESTAMP, json varchar(2000), unique(hash))');
/*
TABLE Queue
hash	char(64)		See description in /backend/rt.lua; cross-{db,table} method reference to a certain video.
added 	char(19)		Timestamp in format YYYY-MM-DD HH:MM:SS
json	varchar(2000) 	JSON encoded value of row from the other database
*/

$db = new SQLite3('/opt/rt-downloader/rt.sqlite3');

if ($action == 'addtoqueue') {
	if (isset($_GET['hash'])) {
		$hash = SQLite3::escapeString($_GET['hash']);
		$data = $db->querySingle('SELECT * FROM Metadata WHERE hash IS "' . $hash . '"', true);
		if (isset($data) and $data['processed'] == 0) {
			#Attempt to avoid adding a video to our queue multiple times.
			$db->exec('UPDATE Metadata SET processed=1 WHERE hash IS ' . $hash);
			$queue->exec('INSERT INTO Queue(hash, json) VALUES(' $hash . ', ' . SQLite3::escapeString(json_encode($data)) . ')');
			header('Location: https://rtdownloader.com/video/?v=' . $hash, true, 303);
			safe_close();
		}
	}
} elseif ($action == 'download_start') {
	#Architecture assumes single node for downloads. We need to add some sort of timeout / locking mechanism.
	#This will _definitely_ break compatibility. Good thing this table is meant for temporary operations.
	echo($queue->querySingle('SELECT json FROM Queue ORDER BY added ASC LIMIT 1')); 
	safe_close();
} elseif ($action == 'download_complete') {
	if (isset($_GET['hash'] and isset($_GET['url']))) {
		#URL is base64 encoded because I'm too lazy to properly implement POST nor escaping special characters. 
		#If it's good enough for email, it's good enough for me!

		#Technically, url should be changed to data, and data will be a base64 encoded json encoded array with all associated data.
		$url = SQLite3::escapeString(base64_decode($_GET['url']));
		$db->exec('INSERT INTO Storage(hash,url) VALUES('..SQLite3::escapeString($_GET['hash']) . ', ' . $url);
		safe_close();
	}
}

http_response_code(500);
echo('500 Server couldn\'t handle request.');
safe_close();