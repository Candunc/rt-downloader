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

if (!$_GET['v']) { invalid(); }

$config = (array)include('../require/config.php');
$db = mysqli_connect($config['sql_addr'],$config['sql_user'],$config['sql_pass'],'rtdownloader');

$result = mysqli_query($db, 'SELECT * FROM Metadata WHERE hash="' . mysqli_escape_string($db, $_GET['v']) . '"');

if (mysqli_num_rows($result) == 0) { invalid(); }

$value = mysqli_fetch_array($result, MYSQLI_ASSOC);

# Below code is from http://stackoverflow.com/a/13009592/1687505
echo(preg_replace('/(<title>)(.*?)(<\/title>)/i', '$1' . $value['title'] . '$3', file_get_contents("../require/header.html")));
echo('<div class="video" style="margin: 2rem;"><div style="height:0.75rem;"></div><div class="ratio" style="background-image:url(\'' . $value['image'] . '\');"></div>' . PHP_EOL . '<div style="width: 90%;"><br><h3>' . $value['title'] . '</h3><br><p>' . $value['description'] . '</p><br><br>' . PHP_EOL);

#Catch if sponsor potentially doesn't exist.
if ($value['sponsor'] != 0) {
	echo('<p>This video is not available yet! Please check back on ' . $value['releaseDate'] . '.</p></div>' . PHP_EOL);
	#Maybe have an estimated amount of hours here?
} else {
#	Disabled as it isn't yet implemented.
#	if (0 == $db->querySingle('SELECT processed FROM Metadata WHERE hash IS "' . $hash . '"')) { 
#		echo('<p>Sorry, this video hasn't been processed yet. <a href="https://rtdownloader.com/api?action=addtoqueue&hash=' . $hash . '">Click here</a> to attempt to manually load the video.</p></div>');
#	} else {
#		$video = $db->querySingle('SELECT * FROM Storage WHERE hash IS "' . $hash . '"', true);
#		if (!$video) {
			echo('<p>This video is not available, however it is being processed by one of our nodes. Please check back later.</p></div>' . PHP_EOL);		
#		} else {
#			#Download button goes here, along with video data (IE Filesize, estimated time to download, ext.)
#		}
#	}
}
readfile("../require/footer.html");

safe_close();
?>
