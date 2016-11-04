<?php #Todo: Create the html template for this page.
#$hash = SQLite3::escapeString($_GET['v']);
$hash = 'd56ee6a6e5f7bed12cac96b4ab89bf0730aa4f624432b272c20b2e509c69d2c0';
#We should check if the hash exists, and if not redirect to 404 page.

$db = new SQLite3('rt.sqlite3');

$table = $db->querySingle('SELECT site FROM Metadata WHERE hash IS "' . $hash . '"'); #Because we keep all the data in a site-specific table, we have to lookup the site...
if (!$table) {
	echo('404 error goes here.');
	die();
}
$results = $db->querySingle('SELECT * FROM ' . $table . ' WHERE hash IS "' . SQLite3::escapeString($hash) . '"', true); #Be careful when using the description. If you ECHO it straight we have the potential for XSS.
var_dump($results);
?>