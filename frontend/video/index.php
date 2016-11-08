<?php #Todo: Create the html template for this page.
function invalid() {
	http_response_code(400);
	echo('400 Bad Request');
	die();
}

if (!$_GET['v']) { invalid(); }

#$hash = SQLite3::escapeString($_GET['v']);
$hash = 'd56ee6a6e5f7bed12cac96b4ab89bf0730aa4f624432b272c20b2e509c69d2c0';

$db = new SQLite3('rt.sqlite3');

$table = $db->querySingle('SELECT site FROM Metadata WHERE hash IS "' . $hash . '"'); #Because we keep all the data in a site-specific table, we have to lookup the site...
if (!$table) { invalid(); }

$results = $db->querySingle('SELECT * FROM ' . $table . ' WHERE hash IS "' . SQLite3::escapeString($hash) . '"', true); #Be careful when using the description. If you ECHO it straight we have the potential for XSS.
var_dump($results);
?>