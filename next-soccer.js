// phantomjs next-soccer.js [yyyymmdd]

var system = require('system');
var args = system.args;

var date;

if (args.length === 1) {
    date = ''
} else {
    args.forEach(function(arg, i) {
        date = arg
    });
}

var address = 'http://www.sportstats.com/soccer/matches/' + date;

var path = 'next-soccer.html';

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
