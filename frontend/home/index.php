<?php
$config = (array)include('../require/config.php');
$db = mysqli_connect($config['sql_addr'],$config['sql_user'],$config['sql_pass'],'rtdownloader');


if ( !isset($_GET['page']) ) {
	$query = 'SELECT * FROM ( SELECT * FROM Metadata ORDER BY releaseDate DESC LIMIT 24 ) T1 ORDER BY releaseDate DESC';
} else {
	$query = 'SELECT * FROM ( SELECT * FROM Metadata WHERE channelUrl="' . mysqli_real_escape_string($_GET['page']) . '" ORDER BY releaseDate DESC LIMIT 24 ) T1 ORDER BY releaseDate DESC';
}

$result = mysqli_query($db, $query);

if (mysqli_num_rows($result) == 0 ) {
	#Return main page if query fails. It may be more efficient to do another call, but oh well.
	header('Location: https://rtdownloader.com/home/', true, 303);
	mysqli_free_result($result);
	mysqli_close($db);
	die();
}

readfile("../require/header.html");
$count = 0;
while ($value = mysqli_fetch_array($result, MYSQLI_ASSOC)) {
	$a = ('<a id="' . (string)($count++) . '" href="https://rtdownloader.com/video/?v=' . $value["hash"] . '">');
	echo('<div class="col-xl-3 col-lg-4 col-md-6 video">' . $a . '<div class="ratio" style="background-image:url(\'https:' . $value["imageMedium"] . '\');"></div><p class="card-text">' . $value["showName"] . ': ' . $value['title'] . '</p></a></div>' . PHP_EOL);

}
readfile("../require/footer.html");

mysqli_free_result($result);
mysqli_close($db);
?>