<!DOCTYPE html>
<html lang="en">
	<head>
		<!-- Required meta tags always come first -->
		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
		<meta http-equiv="x-ua-compatible" content="ie=edge">

		<!-- Bootstrap CSS -->
		<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-alpha.5/css/bootstrap.min.css" integrity="sha384-AysaV+vQoT3kOAXZkl02PThvDr8HYKPZhNT5h/CXfBThSRXQ6jW5DO2ekP5ViFdi" crossorigin="anonymous">
		<link href="album.css" rel="stylesheet">
	</head>
	<body style="background-color: #f7f7f7;">
		<nav class="navbar navbar-static-top navbar-dark bg-inverse">
			<a class="navbar-brand" href="#">RT Downloader</a>
			<ul class="nav navbar-nav">
				<li class="nav-item active">
					<a class="nav-link" href="https://rtdownloader.com/">Home <span class="sr-only">(current)</span></a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="https://rtdownloader.com/home">Videos</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="https://rtdownloader.com/about">About</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="https://rtdownloader.com/contact">Contact</a>
				</li>
		  </ul>
		</nav>

		<div class="container">
			<div class="row" style="padding-bottom: 1rem; background-color: #fff; color: #373a3c">
<?php #I totally forgot you could embed php in a webpage. Idiot.
$videos = json_decode(file_get_contents("frontpage.json"),true);
foreach ($videos as $key => $value) {
	echo('<a id="' . (string)$key . '" href="video.php?v=' . $value["hash"] . '"><div class="col-lg-4 col-md-6 video"><div class="ratio" style="background-image:url(\'https:' . $value["image"] . '\');"></div> <p class="card-text">' . $value["name"] . '</p></div></a>' . PHP_EOL); #Make the entire div clickable. Nothing could go wrong with that.
}
?>
			</div>
		</div>
		<div style="height: 3rem;"></div>

		<footer>
			<p class="small"> This is not endorsed by Rooster Teeth in any way. Rooster Teeth, Achievement Hunter, Funhaus, The Know, Screw Attack, Game Attack, and Cowchop are trade names or registered trademarks of Rooster Teeth Productions, LLC. &copy; Rooster Teeth Productions, LLC.</p>
		</footer>

		<!-- jQuery first, then Tether, then Bootstrap JS. -->
		<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js" integrity="sha384-3ceskX3iaEnIogmQchP8opvBy3Mi7Ce34nWjpBIwVTHfGYWQS9jwHDVRnpKKHJg7" crossorigin="anonymous"></script>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/tether/1.3.7/js/tether.min.js" integrity="sha384-XTs3FgkjiBgo8qjEjBk0tGmf3wPrWtA6coPfQDfFEY8AnYJwjalXCiosYRBIBZX8" crossorigin="anonymous"></script>
		<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-alpha.5/js/bootstrap.min.js" integrity="sha384-BLiI7JTZm+JWlgKa0M0kGRpJbF2J8q+qreVrKBC47e3K6BW78kGLrCkeRX6I9RoK" crossorigin="anonymous"></script>
	</body>
</html>