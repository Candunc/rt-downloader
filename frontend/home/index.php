<?php
$config = (array)include('../require/config.php');
$db = mysqli_connect($config['sql_addr'],$config['sql_user'],$config['sql_pass'],'rtdownloader');

if ( !isset($_GET['page']) ) {
	$page = 0;
} else {
	if ( is_numeric($_GET['page']) ) {
		#Technically, we have a potential for SQL injection, however casting to an int _should_ force anything into 'meaningless' numbers.
		$page = ((int)$_GET['page'] * 24);
	} else {
		$page = 0;
	}
}

if ( !isset($_GET['site']) ) {
	$query = 'SELECT * FROM ( SELECT * FROM Metadata ORDER BY releaseDate DESC LIMIT 24 OFFSET ' . $page . ' ) T1 ORDER BY releaseDate DESC';
} else {
	$query = 'SELECT * FROM ( SELECT * FROM Metadata WHERE channelUrl="' . mysqli_real_escape_string($db,$_GET['site']) . '" ORDER BY releaseDate DESC LIMIT 24 OFFSET ' . $page . ' ) T1 ORDER BY releaseDate DESC';
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
#echo('<div class="row"> <a href="https://rtdownloader.com/home/?site=roosterteeth.com"> <div class="col-md-2"> <p>Rooster Teeth</p> </div> </a> <a href="https://rtdownloader.com/home/?site=theknow.roosterteeth.com"> <div class="col-md-2"> <p>The Know</p> </div> </a> </div>' . PHP_EOL);

$count = 0;

while ( $value = mysqli_fetch_array($result, MYSQLI_ASSOC) ) {
	$a = ('<a id="' . (string)($count++) . '" href="https://rtdownloader.com/video/?v=' . $value["hash"] . '">');
	echo('<div class="col-xl-3 col-lg-4 col-md-6 video">' . $a . '<div class="ratio" style="background-image:url(\'https:' . $value["imageMedium"] . '\');"></div><p class="card-text">' . $value["showName"] . ': ' . $value['title'] . '</p></a></div>' . PHP_EOL);
}
readfile("../require/footer.html");

mysqli_free_result($result);
mysqli_close($db);
?>