(function() {
  var $;

  $ = require('jquery');

  $(function() {
    var button;
    exports.server = new ReversiEngine();
    exports.client = new ReversiClient(server, "game_container", 400, 400);
    button = $("#game_button");
    button.html("Restart Game");
    button.click(function(ev) {
      switch (client.state) {
        case "idle":
          client.start();
          return button.html("Restart Game");
        case "playing":
          return client.start();
      }
    });
    client.bind("finished", function(ev, state) {
      return button.html("Start Game");
    });
    client.bind("move", function(ev, state) {
      var player, turn_info;
      player = state.player_turn;
      turn_info = (player ? "Turn: <b>" + player + "</b>" : "Finished");
      return $("#game_info").html("" + turn_info + ".\nBlack: <b>" + state.pieces.black.length + "</b> -\nWhite: <b>" + state.pieces.white.length + "</b>");
    });
    return client.start();
  });

}).call(this);
