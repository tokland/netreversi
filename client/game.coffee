$ = require 'jquery'

$ ->
  exports.server = new ReversiEngine()
  exports.client = new ReversiClient(server, "game_container", 400, 400)
  button = $("#game_button")
  button.html("Restart Game")
  
  client.bind "finished", (ev, state) ->
    button.html("Start Game")

  client.bind "move", (ev, state) ->
    player = state.player_turn
    turn_info = (if player then "Turn: <b>#{player}</b>" else "Finished")
    $("#game_info").html("""
      #{turn_info}.
      Black: <b>#{state.pieces.black.length}</b> -
      White: <b>#{state.pieces.white.length}</b>""")    

  button.click (ev) ->
    switch client.state 
      when "idle"
        client.start()
        button.html("Restart Game")
      when "playing"
        client.start()

  client.start()
