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
		$l_data = "";
	} else {
		$l_data = mysqli_fetch_array($l_result, MYSQLI_ASSOC);
	}
	mysqli_free_result($l_result);

	#If number of rows is zero we return an empty string instead of the expected data.
	return array('rows' => $l_rows, 'output' => $l_data);
}


if (!isset($_GET['action']) ) { invalid(); }

$config = (array)include('../require/config.php');
$db = mysqli_connect($config['sql_addr'],$config['sql_user'],$config['sql_pass'],'rtdownloader');

$action = $_GET['action'];

if ($action == 'addtoqueue') {
	#a hash is only required for this function at the moment.
	if ( isset($_GET['hash']) ) {
		$hash = mysqli_escape_string($db,$_GET['hash']);
		$data = single_query($db,'SELECT * FROM Metadata WHERE hash="' . $hash . '"');
		if ($data['rows'] != 0 and $data['output']['processed'] == 0) {
			mysqli_query($db,'UPDATE Metadata SET processed=-1 WHERE hash="' . $hash . '"');
			mysqli_query($db,'INSERT INTO Storage(hash,added) VALUES("' . $hash . '", NOW() )');
			header('Location: https://rtdownloader.com/video/?v=' . $hash, true, 303);
			safe_close();
			die();
		}
	}

#Note: Past here is API functions. We're no longer using invalid() to indicate a bad response, as the clients are looking for a json encoded error.
} elseif ($action == 'getdownload') {
	# Malicious queries can be made against this address, so in future interations we need to limit one {client,ip address} to one reservation.

	#Three SQL Queries are executed, two read & one write. Can (and should) this be simplified?
	$data = single_query($db,'SELECT hash FROM Storage WHERE locked=0 ORDER BY added ASC LIMIT 1');
	if ($data['rows'] != 0) {
		$hash = mysqli_escape_string($db,$data['output']['hash']);
		#Is it possible to do an SQL injection from an SQL column?

		mysqli_query($db,'UPDATE Storage SET locked=1,timeout=DATE_ADD(NOW(), INTERVAL 4 HOUR) WHERE HASH="' . $hash . '"');

		#Reuse variable b/c we only needed it for the hash previously
		$data = single_query($db,'SELECT * FROM Metadata WHERE HASH="' . $hash . '"');

		echo(json_encode($data['output']));
	} else {
		echo('{"error":"no videos found"}');
	}
	safe_close();
	die();

} elseif ($action == 'download_complete') {
	if (isset($HTTP_RAW_POST_DATA)) {
		$data = json_decode($HTTP_RAW_POST_DATA,true);
		$node = mysqli_escape_string( substr($_SERVER['HTTP_CLIENT_IP']?:($_SERVER['HTTP_X_FORWARDE‌​D_FOR']?:$_SERVER['REMOTE_ADDR']), 1, 40) );
		#Not trusting the node to specify domain yet.

		# I mean... it is better than nested IF statements, right?
		if (isset($data) && isset($data['hash']) && isset($data['url']) && isset($data['length']) && isset($data['size']) ) {
			mysqli_query($db,'UPDATE Storage SET locked=-1,url="' . mysqli_escape_string($db,$data['url']) . '",node="' . $node . '",length="' . mysqli_escape_string($db,$data['length']) . '",size="' . mysqli_escape_string($db,$data['size']) . '" WHERE hash=' . mysqli_escape_string($data['hash']));
		} else {
			echo('{"error":"malformed post"}');
		}
		safe_close();
		die();
	}
	# Camel Case because fuck consistancy.
} elseif ($action == 'getLatest') {
	# This is an API for a personal project. I mean, I'm scraping it anyways, right?

	#Copy/Pasta from home/index.php file
	$output = array();
	$result = mysqli_query($db, 'SELECT * FROM ( SELECT * FROM Metadata WHERE channelUrl="roosterteeth.com" ORDER BY releaseDate DESC LIMIT 24 ) T1 ORDER BY releaseDate DESC');
	$count = 0;
	while ( $value = mysqli_fetch_array($result, MYSQLI_ASSOC) ) {
		$output[++$count] = $value;
	}
	echo(json_encode($output));
}


http_response_code(500);
echo('500 Server couldn\'t handle request.');
safe_close();