class window.ReversiServer

class window.ReversiEngine
  START_PIECES:
    black: [[3, 4], [4, 3]]
    white: [[3, 3], [4, 4]]

  AXIS_INCREMENTS: [
    [0, +1], [0, -1], # Y-axis
    [+1, 0], [-1, 0], # X-axis
    [+1, +1], [+1, -1], [-1, +1], [-1, -1] # 4-diagonals
  ]

  constructor: (options) ->
    @options = _(options).defaults({})
    @init()

  isValidMove: (player, [x, y]) ->
    _(@validMovesForPlayer(player)).containsObject([x, y])

  canPlayerMove: (player) ->
    not _(@validMovesForPlayer(player)).isEmpty()

  getOtherPlayer: (player) ->
    if player == "black" then "white" else "black"

  nextTurn: ->
    if not @finished
      player1 = @player_turn
      @player_turn = @getOtherPlayer(@player_turn)
      if not @canPlayerMove(@player_turn)
        @player_turn = player1
        if not @canPlayerMove(@player_turn)
          @finished = true

  getPosition2Player: (player) ->
    white = _(@pieces.white).mash((pos) -> [pos, "white"])
    black = _(@pieces.black).mash((pos) -> [pos, "black"])
    _.merge(white, black)

  traverseBoard: (player, [x, dx], [y, dy], pos2player, callback) ->
    other_player = @getOtherPlayer(player)
    xs = if dx == 0 then _(x).repeat(8) else [x+dx..(if dx > 0 then 7 else 0)]
    ys = if dy == 0 then _(y).repeat(8) else [y+dy..(if dy > 0 then 7 else 0)]
    if pos2player[[xs[0], ys[0]]] == other_player
      cs = _.takeWhile(_.zip(xs, ys), ([x2, y2]) -> pos2player[[x2, y2]] == other_player)
      [last_x, last_y]  = _.last(cs)
      if pos2player[[last_x+dx, last_y+dy]] == player
        callback(cs, [x, y])

  validMovesForPlayer: (player) ->
    pos2player = @getPosition2Player(player)
    xs = _([0...8]).map (x) =>
      _([0...8]).map (y) =>
        if not pos2player[[x, y]]
          _(@AXIS_INCREMENTS).map ([dx, dy]) =>
            @traverseBoard(player, [x, dx], [y, dy], pos2player, (cs, [x, y]) -> [x, y])
    _(xs).chain().flatten1().flatten1().compact().value()

  flippedPiecesOnMove: (player, [x, y]) ->
    pos2player = @getPosition2Player(player)
    xs = _(@AXIS_INCREMENTS).map ([dx, dy]) =>
      @traverseBoard(player, [x, dx], [y, dy], pos2player, (cs, [x, y]) -> cs)
    _(xs).chain().flatten1().compact().uniqWith(_.isEqual).value()

  ## Public methods

  init: ->
    @finished = false
    @player_turn = null
    @pieces = _.clone(ReversiEngine::START_PIECES)
    @nextTurn()
    @getCurrentState()

  abort: ->
    @init()

  getCurrentState: ->
    state =
      pieces: @pieces,
      player_turn: (if @finished then false else @player_turn),
      player_moves: (if @finished then [] else @validMovesForPlayer(@player_turn)),

  move: ([x, y]) ->
    if not @isValidMove(@player_turn, [x, y])
      return false
    other_player = @getOtherPlayer(@player_turn)
    flipped_pieces = @flippedPiecesOnMove(@player_turn, [x, y])
    @pieces[other_player] = _(@pieces[other_player]).reject ([x2, y2]) ->
      _(flipped_pieces).containsObject([x2, y2])
    @pieces[@player_turn] = @pieces[@player_turn].concat([[x, y]]).concat(flipped_pieces)
    @nextTurn()
    @getCurrentState()

class ReversiClient
  SIZE: 8
  COLORS:
    square: "#090"
    square_with_move:
      black: "#162"
      white: "#3A5"
    square_hovered: "#3A5"
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
    @options = _(options).defaults({})
    @state = "idle"
    @events = $(new Object())
    @paper_set = @paper.set()

  draw: (state) ->
    @paper_set.remove()
    @paper_set = @paper.set()
    @paper_set.push.apply(@paper_set, _.flatten(@draw_board(state.player_turn, state.player_moves)))
    for player in ["black", "white"]
      for [x, y] in state.pieces[player]
        @paper_set.push(@draw_piece(player, [x, y]))
    @updateGameInfo(state)

  update: (state) ->
    if not state
      return
    if not state.player_turn
      @events.trigger("finished")
      @state = "idle"
    @draw(state)
    @updateGameInfo(state)

  draw_board: (current_player, hoverable_squares) ->
    step_x = @width / @size
    step_y = @height / @size
    for x in [0...@size]
      for y in [0...@size]
        with_move = _(hoverable_squares).containsObject([x, y])
        rect = @paper.rect(x * step_x, y * step_y, @width / @size, @height / @size)
        square_with_move = @colors.square_with_move[current_player]
        fill = if with_move then square_with_move else @colors.square
        rect.attr(fill: fill, stroke: @colors.square_lines)
        if with_move
          do (rect, x, y) =>
            rect.mouseover =>
              rect.attr(fill: @colors.square_hovered)
            rect.mouseout =>
              rect.attr(fill: square_with_move)
            rect.mousedown =>
              @update(@server.move([x, y]))
        rect

  draw_piece: (player, [x, y]) ->
    step_x = @width / @size
    step_y = @height / @size
    paper_x = (x * step_x) + (step_x/2)
    paper_y = (y * step_y) + (step_y/2)
    color = @colors.players[player]
    @paper.circle(paper_x, paper_y, (step_x/2) * 0.8).attr(fill: color, stroke: color)

  updateGameInfo: (state) ->
    state = @server.getCurrentState()
    turn_info = if state.player_turn then "Turn: <b>#{state.player_turn}</b>" else "Game finished"
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
    @events.bind(name, _.bind(callback, this))

$ ->
  window.server = new ReversiEngine()
  window.client = new ReversiClient(server, "#game_container", "#game_info", 400, 400)
  client.start()
  $("#game_button").html("Abort Game")

  client.bind "finished", ->
    $("#game_button").html("Start Game")

  $("#game_button").click (ev) ->
    if client.state == "idle"
      client.start()
      $(this).html("Abort Game")
    else if client.state == "playing"
      client.abort()
      client.start()
