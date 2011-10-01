should = require 'should'
helper = require 'helper'
game = require 'reversi'

describe "ReversiEngine", ->
  describe "init", ->
    it "starts with black turn", ->
      engine = new game.ReversiEngine
      engine.getCurrentState().player_turn.should.equal "black"
   
    it "restarts pieces on board", ->
      engine = new game.ReversiEngine      
      engine.move([4, 3])
      engine.init()
      engine.getCurrentState().pieces.should.eql
        black: [[3, 4], [4, 3]]
        white: [[3, 3], [4, 4]] 
   
  describe "getOtherPlayer", ->
    it "turns black to white, and everything to black", -> 
      engine = helper.createEngine()
      engine.getOtherPlayer(null).should.equal "black"
      engine.getOtherPlayer("black").should.equal "white"
      engine.getOtherPlayer("white").should.equal "black"

  describe "processNextTurn", ->
    it "turns black to white", ->
      engine = new game.ReversiEngine
      state = engine.getCurrentState()
      state.player_turn.should.equal "black"
      engine.processNextTurn(state).player_turn.should.equal "white"

    it "should skip player with turn if she cannot move", ->      
      engine = helper.createEngine("""
         01234567
        0--------
        1--------
        2--------
        3---XXOOX
        4--------
        5--------
        6--------
        7--------""")
      engine.getCurrentState().player_turn.should.equal "white"

  describe "canPlayerMove", ->
    it -> 
      engine1 = helper.createEngine("""
         01234567
        0--------
        1--------
        2--------
        3---XO---
        4---OX---
        5--------
        6--------
        7--------""")
      engine1.canPlayerMove(engine1.getCurrentState().pieces, "black").should.be.true
      engine1.canPlayerMove(engine1.getCurrentState().pieces, "white").should.be.true

      engine2 = helper.createEngine("""
         01234567
        0-----XXX
        1--------
        2--OOOOXO
        3--------
        4----XXX-
        5--------
        6--------
        7--------""")
      engine2.canPlayerMove(engine1.getCurrentState().pieces, "black").should.be.true
      engine2.canPlayerMove(engine1.getCurrentState().pieces, "white").should.be.false    
    
  describe "validMovesForPlayer", ->
    it -> 
      engine1 = helper.createEngine("""
         01234567
        0--------
        1--------
        2--------
        3---XO---
        4---OX---
        5--------
        6--------
        7--------""")
      engine1.validMovesForPlayer(engine1.getCurrentState().pieces, "black").should.eql(
        [[2, 4], [3, 5], [4, 2], [5, 3]])
      engine1.validMovesForPlayer(engine1.getCurrentState().pieces, "white").should.eql(
        [[2, 3], [3, 2], [4, 5], [5, 4]])
        
      engine2 = helper.createEngine("""
         01234567
        0--------
        1--------
        2--------
        3---XOO-O
        4---O----
        5---X----
        6----O---
        7--------""")
      engine2.validMovesForPlayer(engine2.getCurrentState().pieces, "black").
        should.eql([[5, 7], [6, 3]])
      engine2.validMovesForPlayer(engine2.getCurrentState().pieces, "white").
        should.eql([[2, 3], [2, 4], [3, 2], [3, 6]])

  describe "flippedPiecesOnMove", ->
    it -> 
      engine1 = helper.createEngine("""
         01234567
        0--------
        1--------
        2--------
        3---XO---
        4---OX---
        5--------
        6--------
        7--------""")
      engine1.flippedPiecesOnMove(engine1.pieces, "black", [5, 2]).should.be.empty
      engine1.flippedPiecesOnMove(engine1.pieces, "black", [4, 2]).should.eql([[4, 3]])
      engine1.flippedPiecesOnMove(engine1.pieces, "white", [2, 3]).should.eql([[3, 3]])
        
      engine2 = helper.createEngine("""
         01234567
        0--------
        1-----X--
        2-----O--
        3---XO-OX
        4-----O--
        5-----X--
        6--------
        7--------""")
      engine2.flippedPiecesOnMove(engine2.pieces, "black", [5, 3]).
        should.eql([[5, 4], [5, 2], [6, 3], [4, 3]])
      engine1.flippedPiecesOnMove(engine1.pieces, "white", [2, 3]).
        should.eql([[3, 3]])
 
  describe "getCurrentState", ->
    it "returns info about pieces, player_turn and moved for current player", ->
      engine = helper.createEngine("""
         01234567
        0--------
        1-X------
        2-XO-----
        3--------
        4--------
        5--------
        6--------
        7--------""")    
      engine.getCurrentState().should.eql
        pieces:
          black: [[1, 1], [1, 2]]
          white: [[2, 2]]
        player_turn: "black"
        player_moves: [[3, 2], [3, 3]]
      
  describe "move", ->
    it -> 
      engine1 = helper.createEngine("""
         01234567
        0--------
        1--------
        2--------
        3---XO---
        4---OX---
        5--------
        6--------
        7--------""")
      engine1.move([4, 2]).should.eql
        pieces:
          black: [[3, 3], [4, 4], [4, 2], [4, 3]]
          white: [[3, 4]]
        player_turn: "white"
        player_moves: [[3, 2], [5, 2], [5, 4]]
        flipped_pieces: [[4,3]]

      engine2 = helper.createEngine("""
         01234567
        0--------
        1-O------
        2--------
        3-XOO----
        4--------
        5--------
        6--------
        7--------""")
      engine2.move([4, 3]).should.eql
        pieces:
          black: [[1, 3], [4, 3],[3, 3], [2, 3]]
          white: [[1, 1]]
        player_turn: null
        player_moves: []
        flipped_pieces: [[3, 3], [2, 3]]
