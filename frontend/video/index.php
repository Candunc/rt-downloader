<?php #Todo: Create the html template for this page.
function invalid() {
	http_response_code(400);
	echo('400 Bad Request');
	die();
}

if (!$_GET['v']) { invalid(); }

$hash = SQLite3::escapeString($_GET['v']);

$db = new SQLite3('/opt/rt-downloader/rt.sqlite3');

$table = $db->querySingle('SELECT site FROM Metadata WHERE hash IS "' . $hash . '"'); #Because we keep all the data in a site-specific table, we have to lookup the site...
if (!$table) { invalid(); }

$results = $db->querySingle('SELECT * FROM ' . $table . ' WHERE hash IS "' . SQLite3::escapeString($hash) . '"', true); #Be careful when using the description. If you ECHO it straight we have the potential for XSS.
#var_dump($results);

readfile("../require/header.html");
echo($results['title'] . PHP_EOL . strip_tags($results['description'],'<a>') );
readfile("../require/footer.html");
?>