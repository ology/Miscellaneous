// phantomjs scrape.js

//var address = 'http://www.moe.gov.na/st_li_institutions.php';
var address = 'http://www.sportstats.com/soccer/matches/';

var webPage = require('webpage');
var page = webPage.create();

var fs = require('fs');
var path = 'scraped.html'

page.open(address, function (status) {
    if (status !== 'success') {
        console.log('Unable to load the address!');
        phantom.exit();
    } else {
//        window.setTimeout(function () {
            var content = page.content;
            fs.write(path,content,'w')
            phantom.exit();
//        }, 1000); // Change timeout as required to allow sufficient time 
    }
});
