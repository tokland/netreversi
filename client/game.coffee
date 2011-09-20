class ReversiServer
  constructor: (options) ->
    @options = options
    @player_turn = "black"
    @pieces =
      black: [[3, 4], [4, 3]]
      white: [[3, 3], [4, 4], [4, 5]]

  getCurrentState: ->
    state =
      game_finished: @isGameFinished(),
      pieces: @pieces,
      player_turn: @player_turn,
      player_moves: @validMovesForPlayer(@player_turn),

  isValidMove: (player, x, y) ->
    _(@validMovesForPlayer(player)).containsObject([x, y])

  isGameFinished: ->
    _(@validMovesForPlayer(@player_turn)).isEmpty()

  getOtherPlayer: (player) ->
    if player == "white" then "black" else "white"

  validMovesForPlayer: (player) ->
    white = _(@pieces.white).mash((pos) -> [pos, "white"])
    black = _(@pieces.black).mash((pos) -> [pos, "black"])
    pos2player = _.merge(white, black)
    other_player = @getOtherPlayer(player)

    xs = _([0...8]).map (x) ->
      _([0...8]).map (y) ->
        if pos2player[[x, y]]
          return
        permutations = [[0, +1], [0, -1], [+1, 0], [-1, 0], [+1, +1], [+1, -1], [-1, +1], [-1, -1]]
        _(permutations).map ([dx, dy]) ->
          xs = if dx == 0 then _(x).repeat(8) else [x+dx..(if dx > 0 then 7 else 0)]
          ys = if dy == 0 then _(y).repeat(8) else [y+dy..(if dy > 0 then 7 else 0)]
          if pos2player[[xs[0], ys[0]]] != other_player
            return
          [x2, y2] = _(_(xs).zip(ys)).detect ([x2, y2]) ->
            pos2player[[x2, y2]] != other_player
          if pos2player[[x2, y2]] == player
            {x: x, y: y}

    _(xs).chain().flatten().compact().map((p) -> [p.x, p.y]).value()

  move: (x, y) ->
    if not @isValidMove(@player_turn, x, y)
      return false
    @pieces[@player_turn].push([x, y])
    # TODO: update flipping pieces for both players
    @player_turn = @getOtherPlayer(@player_turn)
    @getCurrentState()

class ReversiClient
  constructor: (server, container, width, height, options) ->
    @server = server
    @container = $(container)
    @width = width
    @height = height
    @paper = Raphael(container, width, height)
    @size = 8
    @colors =
      square: "#090"
      square_hovered: "#3A5"
      square_lines: "#333"
      players:
        black: "#000"
        white: "#FFF"

  draw: (state) ->
    @draw_board(state.player_turn, state.player_moves)
    for player in ["black", "white"]
      for [x, y] in state.pieces[player]
        @draw_piece(player, x, y)

  draw_board: (current_player, hoverable_squares) ->
    step_x = @width / @size
    step_y = @height / @size
    for x in _.range(0, @size)
      for y in _.range(0, @size)
        rect = @paper.rect(x * step_x, y * step_y, @width / @size, @height / @size)
        rect.attr(fill: @colors.square, stroke: @colors.square_lines)
        do (rect, x, y) =>
          if _(hoverable_squares).containsObject([x, y])
            rect.mouseover =>
              rect.attr(fill: @colors.square_hovered)
            rect.mouseout =>
              rect.attr(fill: @colors.square)
            rect.mousedown =>
              new_state = @server.move(x, y)
              if new_state
                @draw(new_state)
                @updateGameInfo(new_state)
                @state = new_state

  draw_piece: (player, board_x, board_y) ->
    step_x = @width / @size
    step_y = @height / @size
    x = (board_x * step_x) + (step_x/2)
    y = (board_y * step_y) + (step_y/2)
    color = @colors.players[player]
    @paper.circle(x, y, (step_x/2) * 0.8).attr(fill: color, stroke: color)

  updateGameInfo: (state) ->
    state = @server.getCurrentState()
    $("#game_info").html("""
      Turn: #{state.player_turn}.
      Player black: #{state.pieces.black.length},
      Player white: #{state.pieces.white.length}""")

$ ->
  window.server = new ReversiServer
  state = server.getCurrentState()
  console.log("state", state)
  client = new ReversiClient(server, "game_container", 400, 400)
  client.draw(state)
  client.updateGameInfo(state)
