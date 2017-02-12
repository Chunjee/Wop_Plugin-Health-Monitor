console.log("started");
var casper = require('casper').create();

var x = require('casper').selectXPath;
var fs = require('fs');

//read account.dat and split into account array
var data = fs.read('account.dat');
var account = data.split(" ");
console.log(account[3]);

casper.userAgent("Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.72 Safari/537.36");

var counter = 0

//Bet Ticket popup handler
casper.on('popup.loaded', function() {
    this.echo("popup list entries - "+this.popups.list());
    this.withPopup(/tvg/, function() {
        this.viewport(800,1000);
        //*[@id="bi[1][]"]
        //ALL: sa[1] 
        //this.thenClick(x('//*[@id="bi[1][]"]'));
        console.log('OUTPUT: Track- ' + this.fetchText('#btSummary_trackRace > div:nth-child(1)'));
        console.log('OUTPUT: Race- ' + this.fetchText('#btSummary_trackRace > div:nth-child(2)'));
        this.thenClick(x('//*[@id="sa[1]"]'));
        this.thenClick('#submitWager');
        // runner "3" bi[1][]
        counter++
        casper.capture('popup' + counter + '.png' );
        //console.log('OUTPUT Track -' + this.echo('#btSummary_trackRace'));
        //console.log('OUTPUT Message -' + this.echo('found #message_panel[1]'));
        console.log('OUTPUT: Message- ' + this.fetchText('#message_panel > p'));
        console.log('popup caught in screenshot','INFO');
    });
});

casper.start('http://tvg.com/optout');

casper.then(function () {
    //x-path     //*[@id="accountField"]
    this.sendKeys('#accountField',account[0]);
    this.sendKeys('#pinField',account[1]);
    //lets try clicking stuff
    casper.thenClick('.select2-choice');
    casper.sendKeys('#s2id_autogen1_search',account[2]);
    //this.sendKeys('.select2-choice','Oregon');
    //this.sendKeys(x('//*[@id="s2id_stateField"]/a'),'Oregon');
    console.log("filled out login");
});

casper.then(function () {
    casper.sendKeys('#s2id_autogen1_search',account[2])
    this.sendKeys('#s2id_autogen1_search', casper.page.event.key.Enter);
    casper.thenClick('#loginSubmit');
    console.log("clicked login");
});

casper.then(function () {
    this.echo( "Loaded: " + this.getTitle() );
    casper.capture('pic.png');
});

/*
casper.wait(1000, function () {
    console.log("waited 1 seconds after login");
    casper.capture('pictwo.png');
});
*/


casper.then(function () {
    //casper.thenClick(".btnBetNowTv");
    casper.thenClick("#btnTvIcon");
    console.log('clicked bet now');
    this.wait(6000, function () {
        console.log("waited 1 seconds after login");
    });
});


casper.waitForPopup("/tvg/", function() {
    //this.test.assertEquals(this.popups.length, 1);
    console.log('bet ticket is now active: ' + this.popups.length);
    casper.capture('pic.png');  
});


/*
casper.withPopup(/boxDarkGrayCurved/, function() {
    this.test.assertTitle('Bet Ticket');
    console.log('bet ticket is now active');
});
*/


casper.then(function () {
    console.log('reached end of script. EXIT');
    casper.exit();
});

casper.run();