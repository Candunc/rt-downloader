const CDP = require('chrome-remote-interface');

var user = '';
var pass = '';

var m3u8_page = process.argv[2];

if (typeof m3u8_page == 'undefined') {
	console.log('No webpage specified; exiting...');
	process.exit();
}

CDP((client) => {
	const {Page, Runtime} = client;

	Page.enable();
	Page.navigate({url: 'https://roosterteeth.com/login'});

	Page.loadEventFired(() => {
		Runtime.evaluate({expression: 'document.location.href'}).then((result) => {
//			console.error(result.result.value);
			if (result.result.value == 'https://roosterteeth.com/login') {
				Runtime.evaluate({expression: 'var user = document.getElementById("username"); user.value="' + user + '"; let pass = document.getElementById("password"); pass.value="' + pass + '"; pass.form.submit();'});
			} else if (result.result.value == "http://roosterteeth.com/" || result.result.value == "https://roosterteeth.com/") {
				Page.navigate({url: m3u8_page});
			} else {
				Runtime.evaluate({expression: 'document.body.outerHTML'}).then((result) => {
					console.log(result.result.value);
					Page.navigate({url: "about:blank"});
					client.close();
				});
			}
		});
	});

}).on('error', (err) => {
	console.error('Cannot connect to browser:', err);
});