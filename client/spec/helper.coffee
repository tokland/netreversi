game = require '../reversi'
_ = require 'underscore_extensions'

exports.createEngine = (string_board) ->
  new game.ReversiEngine(start_pieces: string_board && toPieces(string_board))
  
toPieces = (string_board) ->
  lines = string_board.replace(/[^-XO\n]/g, '').split("\n")
  matrix = for row, y in _.compact(lines)
    for piece, x in row when piece in ["X", "O"]
      {player: {X: "black", O: "white"}[piece], pos: [x, y]}
  _(matrix).chain().flatten().compact().groupBy((x) -> x.player).
    mash((array, player) -> [player, _(array).pluck("pos")]).value()
