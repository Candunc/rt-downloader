<?php
function invalid() {
	http_response_code(404);
	echo('404: Couldn\'t find a video with that url.');
	safe_close();
	die();
}

function safe_close() {
	if (isset($result)) { mysqli_free_result($result); }
	if (isset($db)) { mysqli_close($db); }
}

if (!$_GET['url'] || (substr_count(strtolower($_GET['url']),'roosterteeth.com') == 0)) { invalid(); }
$base = strtolower($_GET['url']);

#From http://stackoverflow.com/a/1361752/1687505
$pos = strrpos($base, '/');
$id = $pos === false ? $url : substr($base, $pos + 1);

$config = (array)include('../require/config.php');
$db = mysqli_connect($config['sql_addr'],$config['sql_user'],$config['sql_pass'],'rtdownloader');

$result = mysqli_query($db, 'SELECT hash FROM Metadata WHERE slug="' . mysqli_real_escape_string($db, strtolower($id)) . '"');
if (mysqli_num_rows($result) == 0 ) { invalid(); }

$hash = mysqli_fetch_object($result)->hash;

header('Location: https://rtdownloader.com/video/?v=' . $hash, true, 303);

safe_close();
?>