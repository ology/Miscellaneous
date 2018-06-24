// phantomjs next-soccer.js

var address = 'http://www.sportstats.com/soccer/matches/';
var path = 'next-soccer.html'

var fs = require('fs');

var webPage = require('webpage');
var page = webPage.create();

page.open(address, function (status) {
    if (status !== 'success') {
        console.log('Unable to load the address!');
    } else {
        var content = page.content;
        fs.write(path, content, 'w');
    }

    phantom.exit();
});
