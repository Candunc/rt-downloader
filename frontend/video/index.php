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

readfile("../require/header.html");
echo($results['title'] . PHP_EOL . $results['description'] );
readfile("../require/footer.html");
?>