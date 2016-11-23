<?php
function invalid() {
	http_response_code(404);
	echo('404: Couldn\'t find a video with that url.');
	die();
}

if (!$_GET['url'] || (substr_count(strtolower($_GET['url']),'roosterteeth.com') == 0)) { invalid(); }
$base = strtolower($_GET['url']);

#From http://stackoverflow.com/a/1361752/1687505
$pos = strrpos($base, '/');
$id = $pos === false ? $url : substr($base, $pos + 1);

$url = SQLite3::escapeString(strtolower($id)); 

$db = new SQLite3('/opt/rt-downloader/rt.sqlite3');
$hash = $db->querySingle('SELECT hash FROM Metadata WHERE slug IS "' . $url . '"');
if (!$hash) { invalid(); }

$db->close();

header('Location: https://rtdownloader.com/video/?v=' . $hash, true, 303);

?>