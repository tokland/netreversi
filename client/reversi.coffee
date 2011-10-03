_ = require 'underscore_extensions'
_.extend(global, _.slice(_, ["map", "zip", "flatten", "takeWhile", "mash"]))

class exports.ReversiEngine
  SIZE: 8
  
  START_PIECES:
    black: [[3, 4], [4, 3]]
    white: [[3, 3], [4, 4]]
    
  AXIS_INCREMENTS: [
    [+0, +1], [+0, -1], # Y-axis
    [+1, +0], [-1, +0], # X-axis
    [+1, +1], [+1, -1], [-1, +1], [-1, -1] # 4-diagonals
  ]

  constructor: (options = {}) ->
    @options = _(options).defaults
      size: @SIZE
      start_pieces: @START_PIECES
    @init()

  getStateNextTurn: (state) ->
    player_turn = @getOtherPlayer(state.player_turn)
    next_player_turn = if @canPlayerMove(state.pieces, player_turn)
      player_turn
    else
      player_turn2 = @getOtherPlayer(player_turn)
      if @canPlayerMove(state.pieces, player_turn2) then player_turn2 else null
    _(state).merge
      player_turn: next_player_turn
      player_moves: @validMovesForPlayer(state.pieces, next_player_turn)  

  canPlayerMove: (pieces, player) ->
    _(@validMovesForPlayer(pieces, player)).isNotEmpty()

  getOtherPlayer: (player) ->
    if player == "black" then "white" else "black"

  getPositionToPlayer: (pieces, player) ->
    black = mash([pos, "black"] for pos in pieces.black)
    white = mash([pos, "white"] for pos in pieces.white)
    _(black).merge(white)

  traverseSquares: (player, [x, y], pos2player) ->
    other_player = @getOtherPlayer(player)
    size = @options.size
    for [dx, dy] in @AXIS_INCREMENTS
      xs = (if dx == 0 then _(x).repeat(size) else [x+dx..(if dx > 0 then size-1 else 0)])
      ys = (if dy == 0 then _(y).repeat(size) else [y+dy..(if dy > 0 then size-1 else 0)])
      if pos2player[[xs[0], ys[0]]] == other_player
        cs = takeWhile(zip(xs, ys), (pos) -> pos2player[pos] == other_player)
        [last_x, last_y] = _(cs).last()
        if pos2player[[last_x+dx, last_y+dy]] == player
          {squares: cs, pos: [x, y]}

  validMovesForPlayer: (pieces, player) ->
    return [] unless player
    pos2player = @getPositionToPlayer(pieces, player)
    squares = for x in [0...8]
      for y in [0...8]
        if not pos2player[[x, y]]
          @traverseSquares(player, [x, y], pos2player)
    _(squares).chain().flatten().compact().pluck("pos").value()

  flippedPiecesOnMove: (pieces, player, pos) ->
    return [] unless player
    pos2player = @getPositionToPlayer(pieces, player)
    squares = @traverseSquares(player, pos, pos2player)
    _(squares).chain().compact().pluck("squares").flatten1().uniqWith(_.isEqual).value()

  setNewState: (new_state) ->
    @state = new_state

  ## Public methods

  getCurrentState: ->
    @state

  init: ->
    @setNewState @getStateNextTurn
      pieces: @options.start_pieces
      player_turn: null
    
  move: (pos) ->
    player = @state.player_turn
    player2 = @getOtherPlayer(player)
    flipped_pieces = @flippedPiecesOnMove(@state.pieces, player, pos)
    return false if _(flipped_pieces).isEmpty()
    pieces_player = @state.pieces[@state.player_turn].concat([pos], flipped_pieces)
    pieces_player2 = (p for p in @state.pieces[player2] when not _(flipped_pieces).containsObject(p))
    new_pieces = mash([[player, pieces_player], [player2, pieces_player2]])
    new_state = @setNewState(@getStateNextTurn(_(@state).merge(pieces: new_pieces)))
    {new_state: new_state, flipped_pieces: flipped_pieces}

class ReversiSocketIOServer
  # use socket.io

class exports.ReversiClient
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

  constructor: (server, container, width, height, options = {}) ->
    @options = _(options).defaults
    @server = server
    @size = @SIZE
    @colors = @COLORS
    @width = width
    @height = height
    @paper = Raphael(container, width, height)
    @state = "idle"
    @events = $(new Object())
    @paper_set = @paper.set()

  getOtherPlayer: (player) ->
    if player == "black" then "white" else "black"

  update: (state, flipped_pieces) ->
    @draw(state, flipped_pieces)
    @events.trigger("move", state)
    if not state.player_turn
      @events.trigger("finished", state)
      @state = "idle"

  draw: (state, flipped_pieces) ->
    @paper_set.remove()
    @paper_set = @paper.set()
    squares = flatten(@draw_board(state.player_turn, state.player_moves))    
    @paper_set.push.apply(@paper_set, squares)
    
    for player in ["black", "white"]
      for pos in state.pieces[player]
        was_flipped = _(flipped_pieces || []).containsObject(pos)
        piece = @draw_piece(player, pos, was_flipped)
        @paper_set.push(piece)
      
  draw_board: (current_player, hoverable_squares) ->
    [step_x, step_y] = [@width / @size, @height / @size]
    for x in [0...@size]
      for y in [0...@size]
        with_move = _(hoverable_squares).containsObject([x, y])
        rect = @paper.rect(x * step_x, y * step_y, @width / @size, @height / @size)
        square_with_move_color = @colors.square_with_move[current_player]
        rect.attr(fill: @colors.square, stroke: @colors.square_lines)
        if with_move
          rect.animate(fill: square_with_move_color, stroke: @colors.square_lines, 400)
          do (rect, x, y) =>
            rect.mouseover =>
              rect.attr(fill: @colors.square_hovered)
            rect.mouseout =>
              rect.attr(fill: square_with_move_color)
            rect.mousedown =>
              if response = @server.move([x, y])
                @update(response.new_state, response.flipped_pieces) 
        rect

  draw_piece: (player, [x, y], flip_effect) ->
    [step_x, step_y] = [@width / @size, @height / @size]
    [paper_x, paper_y] = [(x * step_x) + (step_x/2), (y * step_y) + (step_y/2)]
    [rx, ry] = [(step_x/2) * 0.8, (step_y/2) * 0.8]
    other_player = @getOtherPlayer(player)
    color = (if flip_effect then @colors.players[other_player] else @colors.players[player])
    piece = @paper.ellipse(paper_x, paper_y, rx, ry)
    piece.attr("fill": color, "stroke-opacity": 0)
    if flip_effect 
      attr = (if player == "white" then "rx" else "ry")
      piece.animate mash([[attr, 0]]), 250, =>
        piece.attr(fill: @colors.players[player])
        piece.animate(mash([[attr, rx]]), 250, "backOut")
    piece

  start: ->
    @state = "playing"
    @update(@server.init(), [])

  abort: ->
    @server.init()
    @state = "idle"
    @paper.clear()
    @paper_set = @paper.set()

  bind: (name, callback) ->
    @events.bind(name, _.bind(callback, this))
