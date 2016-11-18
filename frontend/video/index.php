<?php #Todo: Create the html template for this page.
function invalid() {
	http_response_code(400);
	echo('400 Bad Request');
	die();
}

if (!$_GET['v']) { invalid(); }

$hash = SQLite3::escapeString($_GET['v']);

$db = new SQLite3('/opt/rt-downloader/rt.sqlite3');

$results = $db->querySingle('SELECT * FROM Metadata WHERE hash IS "' . SQLite3::escapeString($hash) . '"', true);

if (!$results) { invalid(); }

# Below code is from http://stackoverflow.com/a/13009592/1687505
echo(preg_replace('/(<title>)(.*?)(<\/title>)/i', '$1' . $results['title'] . '$3', file_get_contents("../require/header.html")));
echo('<div class="video" style="margin: 2rem;"><div style="height:0.75rem;"></div><div class="ratio" style="background-image:url(\'' . $results['image'] . '\');"></div>' . PHP_EOL . '<div style="width: 90%;">br><h3>' . $results['title'] . '</h3><br><p>' . $results['description'] . '</p></div>' . PHP_EOL);
readfile("../require/footer.html");
?>