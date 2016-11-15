<?php
readfile("../require/header.html");
$videos = json_decode(file_get_contents("/opt/rt-download/frontpage.json"),true);
foreach ($videos as $key => $value) {
	$a = ('<a id="' . (string)$key . '" href="video.php?v=' . $value["hash"] . '">'); #Modified to have two <a> tags, so that only the image and the text is clickable. Hopefully duplicate IDs for identical tags won't, you know, break everything.
	echo('<div class="col-lg-4 col-md-6 video">' . $a . '<div class="ratio" style="background-image:url(\'https:' . $value["image"] . '\');"></div></a> ' . $a '<p class="card-text">' . $value["name"] . '</p></a></div>' . PHP_EOL);
readfile("../require/footer.html");
?>