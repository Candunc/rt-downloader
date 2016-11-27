<?php
function invalid() {
	http_response_code(400);
	echo('400 Bad Request');
	safe_close();
	die();
}

function safe_close() {
	if (isset($result)) { mysqli_free_result($result); }
	if (isset($db)) { mysqli_close($db); }
}

if (!isset($_GET['action'])) { invalid(); }
$action = $_GET['action'];

$config = (array)include('../require/config.php');
$db = mysqli_connect($config['sql_addr'],$config['sql_user'],$config['sql_pass'],'rtdownloader');


/*
if ($action == 'addtoqueue') {
	if (isset($_GET['hash'])) {
		$hash = mysqli_escape_string($db,$_GET['hash']);
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
*/

http_response_code(500);
echo('500 Server couldn\'t handle request.');
safe_close();