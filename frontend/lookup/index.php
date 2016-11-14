<?php
function invalid() {
	http_response_code(404);
//	echo('404: Couldn\'t find a video with that url.');
	die();
}
if (!$_GET['url'] || (substr_count(strtolower($_GET['url']),'roosterteeth.com') == 0)) { invalid(); }
$url = SQLite3::escapeString(strtolower($_GET['url'])); #I'm not sure whether repeating strtolower twice is worse than assigning a variable for two checks.

$db = new SQLite3('/opt/rt-downloader/rt.sqlite3');
$hash = $db->querySingle('SELECT hash FROM Metadata WHERE url IS "' . $url . '"');
if (!$hash) { invalid(); }

header('Location: https://rtdownloader.com/video/?v=' . $hash, true, 303);

?>