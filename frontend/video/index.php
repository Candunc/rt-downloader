<?php #Todo: Create the html template for this page.
function invalid() {
	http_response_code(400);
	echo('400 Bad Request');
	die();
}

if (!$_GET['v']) { invalid(); }

$hash = SQLite3::escapeString($_GET['v']);

$db = new SQLite3('/opt/rt-downloader/rt.sqlite3');

$results = $db->querySingle('SELECT * FROM Metadata WHERE hash IS "' . $hash . '"', true);

if (!$results) { invalid(); }

# Below code is from http://stackoverflow.com/a/13009592/1687505
echo(preg_replace('/(<title>)(.*?)(<\/title>)/i', '$1' . $results['title'] . '$3', file_get_contents("../require/header.html")));
echo('<div class="video" style="margin: 2rem;"><div style="height:0.75rem;"></div><div class="ratio" style="background-image:url(\'' . $results['image'] . '\');"></div>' . PHP_EOL . '<div style="width: 90%;">br><h3>' . $results['title'] . '</h3><br><p>' . $results['description'] . '</p><br><br>' . PHP_EOL);

#Catch if sponsor potentially doesn't exist.
if ($results['sponsor'] != 0) {
	echo('<p>This video is not available yet! Please check back on ' . $results['releaseDate'] . '.</p></div>' . PHP_EOL);
	#Maybe have an estimated amount of hours here?
} else {
	/* Disabled as it isn't yet implemented.
	$video = $db->querySingle('SELECT * FROM Storage WHERE hash IS "' . $hash . '"', true);
	*/
	if (!$video) {
		echo('<p>Sorry, we don\'t have this video in our database yet. <a href="#">Click here</a> to attempt to manually load the video.</a></p></div>');
	} else {
		#Download button goes here, along with video data (IE Filesize, estimated time to download, ext.)
	}
}
readfile("../require/footer.html");
?>