<?php #Todo: Create the html template for this page.
#$hash = SQLite3::escapeString($_GET['v']);
$hash = 'd56ee6a6e5f7bed12cac96b4ab89bf0730aa4f624432b272c20b2e509c69d2c0';
#We should check if the hash exists, and if not redirect to 404 page.

$db = new SQLite3('rt.sqlite3');

$table = SQLite3::escapeString($db->querySingle('SELECT site FROM Metadata WHERE hash IS "' . $hash . '"')); #Because we keep all the data in a site-specific table, we have to lookup the site...
$results = $db->querySingle('SELECT * FROM ' . $table . ' WHERE hash IS "' . $hash . '"', true);
var_dump($results);
?>