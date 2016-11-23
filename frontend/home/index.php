<?php
readfile("../require/header.html");
$videos = json_decode(file_get_contents("/opt/rt-downloader/frontpage.json"),true);
if ( !isset($_GET['page']) || !isset($videos[$_GET['page']]) ) {
	$source = $videos['all'];
} else
	$source = $videos[$_GET['page']];
}

foreach ($source as $key => $value) {
	$a = ('<a id="' . (string)$key . '" href="https://rtdownloader.com/video/?v=' . $value["hash"] . '">');
	echo('<div class="col-xl-3 col-lg-4 col-md-6 video">' . $a . '<div class="ratio" style="background-image:url(\'https:' . $value["imageMedium"] . '\');"></div><p class="card-text">' . $value["showName"] . ': ' . $value['title'] . '</p></a></div>' . PHP_EOL);
}
readfile("../require/footer.html");
?>