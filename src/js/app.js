App = {
     web3Provider: null,
     contracts: {},
     account: 0x0,
     loading: false,

     init: function() {
          return App.initWeb3();
     },

     initWeb3: function() {
       if (typeof web3 !== 'undefined') {
         App.web3Provider = web3.currentProvider;
         console.log("Uses metamask");
       } else {
        //  App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
         console.log("Metamask not FOUND!!!!");
         return;
       }
       web3 = new Web3(App.web3Provider);

       return App.initContract();
     },

     initContract: function() {
       $.getJSON('Game.json', function(artifact) {
         App.contracts.Game = TruffleContract(artifact);
         App.contracts.Game.setProvider(App.web3Provider);
         App.listenToEvents();
         return App.reloadMatches();
       })
     },

     reloadMatches: function() {
       if (App.loading) {
         return;
       }
       App.loading = true;

       var gameInstance;

       App.contracts.Game.deployed().then(function(instance){
         gameInstance = instance;
         return gameInstance.getPlayable();
       }).then(function(matchIds){
         $('#matchesRow').empty();
         for (var i = 0; i < matchIds.length; i++) {
           var matchId = matchIds[i];
           gameInstance.matches(matchId.toNumber()).then(function(match){
             App.displayMatch(match[0], match[1], match[2], match[3]);
           })
         }

         App.loading = false;
       }).catch(function(err) {
         console.log(err);
       })
     },

     displayMatch: function(id, name, date, stadium) {
       var matchRow = $('#matchesRow');

       var matchTemplate = $('#matchTemplate');
       matchTemplate.find('.panel-title').text(name);
       matchTemplate.find('.match-stadium').text(stadium);
       matchTemplate.find('.match-date').text(date);
       matchTemplate.find('.btn-play-0').attr("data-id", id.toNumber());
       matchTemplate.find('.btn-play-1').attr("data-id", id.toNumber());
       matchTemplate.find('.btn-play-2').attr("data-id", id.toNumber());

       matchRow.append(matchTemplate.html());
     },

     bet: function(_out) {
       App.contracts.Game.deployed().then(function(instance){
         var _id = $(event.target).data("id");
         return instance.placeBet(_id, _out, {from: App.account, value: web3.toWei(10, "ether"), gas: 500000});
       }).catch(function(err){
         console.log(err);
       })
     },

     listenToEvents: function() {
       App.contracts.Game.deployed().then(function(instance){
         instance.GameFinished({}, {}).watch(function(err, event){
           if (!err) {
             $("#events").append('<li class="list-group-item">' + 'Game finished: ' + event.args._matchName + '</li>');
           } else {
             console.log(err);
           }
         });

         instance.BetPlaced({}, {}).watch(function(err, event){
           if (!err) {
             $("#events").append('<li class="list-group-item">' + 'Bet placed by ' + event.args._player + ' on ' + event.args._matchName + '</li>');
           } else {
             console.log(err);
           }
         });
       })
     }
};

$(function() {
     $(window).load(function() {
          App.init();
     });
});
