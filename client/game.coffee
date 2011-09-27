$ ->  
  window.server = new ReversiEngine()
  window.client = new ReversiClient(server, "#game_container", "#game_info", 400, 400)
  button = $("#game_button")
  button.html("Restart Game")
  client.start()
  
  client.bind "finished", ->
    button.html("Start Game")

  button.click (ev) ->
    switch client.state 
      when "idle"
        client.start()
        button.html("Restart Game")
      when "playing"
        client.start()
