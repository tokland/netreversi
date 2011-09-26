_([
  "map", "merge", "zip", "clone", "takeWhile", "last", "reject"
  "defaults", "containsObject", "isNotEmpty", "mash", "repeat"
  "flatten", "flatten1", "bind", "isEqual", "isEmpty", "uniqWith"
]).each((method) -> this[method] = _[method])

class ReversiEngine
  START_PIECES:
    black: [[3, 4], [4, 3]]
    white: [[3, 3], [4, 4]]

  AXIS_INCREMENTS: [
    [+0, +1], [+0, -1], # Y-axis
    [+1, +0], [-1, +0], # X-axis
    [+1, +1], [+1, -1], [-1, +1], [-1, -1] # 4-diagonals
  ]

  constructor: (options) ->
    @options = defaults(options, {})
    @init()

  processNextTurn: ->
    return if @finished
    player_turn = @getOtherPlayer(@player_turn)
    if not @canPlayerMove(player_turn)
      player_turn = @getOtherPlayer(player_turn)
      if not @canPlayerMove(player_turn)
        @finished = true
        player_turn = null
    @player_turn = player_turn

  canPlayerMove: (player) ->
    isNotEmpty(@validMovesForPlayer(@pieces, player))

  getOtherPlayer: (player) ->
    if player == "black" then "white" else "black"

  getPositionToPlayer: (pieces, player) ->
    black = mash([pos, "black"] for pos in pieces.black)
    white = mash([pos, "white"] for pos in pieces.white)
    merge(black, white)

  traverseSquares: (player, [x, y], pos2player) ->
    other_player = @getOtherPlayer(player)
    for [dx, dy] in @AXIS_INCREMENTS
      xs = (if dx == 0 then repeat(x, 8) else [x+dx..(if dx > 0 then 7 else 0)])
      ys = (if dy == 0 then repeat(y, 8) else [y+dy..(if dy > 0 then 7 else 0)])
      if pos2player[[xs[0], ys[0]]] == other_player
        cs = takeWhile(zip(xs, ys), (pos) -> pos2player[pos] == other_player)
        [last_x, last_y] = last(cs)
        if pos2player[[last_x+dx, last_y+dy]] == player
          {squares: cs, pos: [x, y]}

  validMovesForPlayer: (pieces, player) ->
    return [] unless player
    pos2player = @getPositionToPlayer(@pieces, player)
    squares = for x in [0...8]
      for y in [0...8]
        if not pos2player[[x, y]]
          @traverseSquares(player, [x, y], pos2player)
    _(squares).chain().flatten1().flatten1().compact().pluck("pos").value()

  flippedPiecesOnMove: (pieces, player, [x, y]) ->
    return [] unless player
    pos2player = @getPositionToPlayer(pieces, player)
    squares = @traverseSquares(player, [x, y], pos2player)
    _(squares).chain().compact().pluck("squares").flatten1().uniqWith(isEqual).value()

  ## Public methods

  init: ->
    @finished = false
    @player_turn = null
    @pieces = clone(ReversiEngine::START_PIECES)
    @processNextTurn()
    @getCurrentState()

  abort: ->
    @init()

  getCurrentState: ->
    state =
      pieces: @pieces
      player_turn: @player_turn
      player_moves: @validMovesForPlayer(@pieces, @player_turn)

  move: ([x, y]) ->
    flipped_pieces = @flippedPiecesOnMove(@pieces, @player_turn, [x, y])
    return false if isEmpty(flipped_pieces)
    other_player = @getOtherPlayer(@player_turn)
    @pieces[other_player] = 
      (p for p in @pieces[other_player] when not _(flipped_pieces).containsObject(p))
    @pieces[@player_turn] = @pieces[@player_turn].concat([[x, y]], flipped_pieces)
    @processNextTurn()
    merge(@getCurrentState(), {flipped_pieces: flipped_pieces})


class ReversiSocketIOServer extends ReversiEngine
  # use socket.io

class ReversiClient
  SIZE: 8
  COLORS:
    square: "#090"
    square_with_move:
      black: "#162"
      white: "#3A5"
    square_hovered: "#5C6"
    square_lines: "#333"
    players:
      black: "#000"
      white: "#FFF"

  constructor: (server, container, info_container, width, height, options) ->
    @server = server
    @size = ReversiClient::SIZE
    @colors = ReversiClient::COLORS
    @container = $(container)
    @info_container = $(info_container)
    @width = width
    @height = height
    @paper = Raphael(@container.get(0), width, height)
    @options = defaults(options, {})
    @state = "idle"
    @events = $(new Object())
    @paper_set = @paper.set()

  getOtherPlayer: (player) ->
    if player == "black" then "white" else "black"

  update: (state) ->
    @draw(state)
    @updateGameInfo(state)
    if not state.player_turn
      @events.trigger("finished")
      @state = "idle"

  draw: (state) ->
    @paper_set.remove()
    @paper_set = @paper.set()
    squares = flatten(@draw_board(state.player_turn, state.player_moves))    
    @paper_set.push.apply(@paper_set, squares)
    
    for player in ["black", "white"]
      for pos in state.pieces[player]
        is_flipped = _(state.flipped_pieces || []).containsObject(pos)
        piece = @draw_piece(player, pos, is_flipped)
        @paper_set.push(piece)
      
    @updateGameInfo(state)

  draw_board: (current_player, hoverable_squares) ->
    step_x = @width / @size
    step_y = @height / @size
    for x in [0...@size]
      for y in [0...@size]
        with_move = _(hoverable_squares).containsObject([x, y])
        rect = @paper.rect(x * step_x, y * step_y, @width / @size, @height / @size)
        square_with_move_color = @colors.square_with_move[current_player]
        fill = if with_move then square_with_move_color else @colors.square
        rect.attr(fill: fill, stroke: @colors.square_lines)
        if with_move
          do (rect, x, y) =>
            rect.mouseover =>
              rect.attr(fill: @colors.square_hovered)
            rect.mouseout =>
              rect.attr(fill: square_with_move_color)
            rect.mousedown =>
              @update(@server.move([x, y]))
        rect

  draw_piece: (player, [x, y], flip_effect) ->
    [step_x, step_y] = [@width / @size, @height / @size]
    [paper_x, paper_y] = [(x * step_x) + (step_x/2), (y * step_y) + (step_y/2)]
    [rx, ry] = [(step_x/2) * 0.8, (step_y/2) * 0.8]
    other_player = @getOtherPlayer(player)
    color = (if flip_effect then @colors.players[other_player] else @colors.players[player])
    piece = @paper.ellipse(paper_x, paper_y, rx, ry)
    piece.attr(fill: color, "stroke-opacity": 0)
    if flip_effect 
      attr = (if player == "white" then "rx" else "ry")
      piece.animate mash([[attr, 0]]), 200, =>
        piece.attr(fill: @colors.players[player])
        piece.animate mash([[attr, rx]]), 200
    piece

  updateGameInfo: (state) ->
    state = @server.getCurrentState()
    turn_info = (if state.player_turn then "Turn: <b>#{state.player_turn}</b>" else "Finished")
    @info_container.html("""
      #{turn_info}.
      Player black: <b>#{state.pieces.black.length}</b>,
      Player white: <b>#{state.pieces.white.length}</b>""")

  start: ->
    @state = "playing"
    server_state = @server.init()
    @draw(server_state)

  abort: ->
    @server.abort()
    @state = "idle"
    @info_container.html("")
    @paper.clear()
    @paper_set = @paper.set()

  bind: (name, callback) ->
    @events.bind(name, bind(callback, this))

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
