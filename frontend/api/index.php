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

function single_query($l_db,$l_query) {
	#Weird variable names to try and avoid conflict with other variables. l_ represents local in this case.
	$l_result = mysqli_query($l_db, $l_query);
	$l_rows = mysqli_num_rows($l_result);
	if ($l_rows == 0) {
		$l_data = ""
	} else {
		$l_data = mysqli_fetch_array($l_result, MYSQLI_ASSOC);
	}
	mysqli_free_result($l_result);

	#If number of rows is zero we return an empty string instead of the expected data.
	return array('rows' => $l_rows, 'row' => $l_data);
}

if (!isset($_GET['action']) || !isset($_GET['hash'])) { invalid(); }

$config = (array)include('../require/config.php');
$db = mysqli_connect($config['sql_addr'],$config['sql_user'],$config['sql_pass'],'rtdownloader');

$action = $_GET['action'];
$hash = mysqli_escape_string($db,$_GET['hash']);

if ($action == 'addtoqueue') {	
	$data = single_query($db,'SELECT * FROM Metadata WHERE hash="' . $hash . '"');
	if ($data['rows'] != 0 and $data['row']['processed'] == 0) {
		mysqli_query('UPDATE Metadata SET processed=-1 WHERE hash="' . $hash . '"');
		mysqli_query('INSERT INTO Storage(hash,added) VALUES(' $hash . ', NOW() )');
		header('Location: https://rtdownloader.com/video/?v=' . $hash, true, 303);
		safe_close();
		die();
	}

} elseif ($action == 'download_start') {
	$data = single_query($db,'SELECT * FROM Storage WHERE locked=0 ORDER BY added ASC LIMIT 1');
	if ($data['rows'] != 0) {
		#Is it possible to do an SQL injection from an SQL column?
		mysqli_query($db,'UPDATE Storage SET locked=1 WHERE HASH="' . mysqli_escape_string($db,$data['rows']['hash']) . '"')
		echo(json_encode($data['rows']);
	} else {
		echo('{"error":"no videos found"}');
	}
	safe_close();
	die();

} elseif ($action == 'download_complete') {
	# Not actually implemented yet.
}


http_response_code(500);
echo('500 Server couldn\'t handle request.');
safe_close();