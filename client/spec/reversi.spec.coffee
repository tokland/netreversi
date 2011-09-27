should = require 'should'
helper = require 'helper'
require 'underscore'
require 'underscore_extensions'

game = require '../reversi'
console.log 1, game.ReversiEngine

describe "ReversiEngine", ->
  describe "init", ->
    it "starts with black turn", ->
      engine = new game.ReversiEngine
      engine.player_turn.should.equal "black"
   
    it "restarts pieces on board", ->
      engine = new game.ReversiEngine      
      engine.move([4, 3])
      engine.init()
      engine.getCurrentState().pieces.should.eql
        black: [[3, 4], [4, 3]]
        white: [[3, 3], [4, 4]] 
   
  describe "getOtherPlayer", ->
    engine = helper.createEngine()
    engine.getOtherPlayer("null").should.equal "black"
    engine.getOtherPlayer("black").should.equal "white"
    engine.getOtherPlayer("white").should.equal "black"

  describe "processNextTurn", ->
    it "turns black turn to white", ->
      engine = new game.ReversiEngine
      engine.player_turn.should.equal "black"
      engine.processNextTurn()
      engine.player_turn.should.equal "white"
      engine.processNextTurn()
      engine.player_turn.should.equal "black"

    it "should skip player with turn if she cannot move", ->      
      engine = helper.createEngine("""
        --------
        --------
        --------
        ---XXOOX
        --------
        --------
        --------
        --------""")
      engine.player_turn.should.equal "white"

  describe "canPlayerMove", ->
    engine1 = helper.createEngine("""
      --------
      --------
      --------
      ---XO---
      ---OX---
      --------
      --------
      --------""")
    engine1.canPlayerMove("black").should.be.true
    engine1.canPlayerMove("white").should.be.true

    engine2 = helper.createEngine("""
      -----XXX
      --------
      --OOOOXO
      --------
      ----XXX-
      --------
      --------
      --------""")
    engine2.canPlayerMove("black").should.be.true
    engine2.canPlayerMove("white").should.be.false    
    
  describe "validMovesForPlayer", ->
    engine1 = helper.createEngine("""
      --------
      --------
      --------
      ---XO---
      ---OX---
      --------
      --------
      --------""")
    engine1.validMovesForPlayer(engine1.pieces, "black").should.eql(
      [[2, 4], [3, 5], [4, 2], [5, 3]])
    engine1.validMovesForPlayer(engine1.pieces, "white").should.eql(
      [[2, 3], [3, 2], [4, 5], [5, 4]])
      
    engine2 = helper.createEngine("""
      --------
      --------
      --------
      ---XOO-O
      ---O----
      ---X----
      ----O---
      --------""")
    engine2.validMovesForPlayer(engine2.pieces, "black").
      should.eql([[5, 7], [6, 3]])
    engine2.validMovesForPlayer(engine2.pieces, "white").
      should.eql([[2, 3], [2, 4], [3, 2], [3, 6]])

  describe "flippedPiecesOnMove", ->
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
      
  describe "move", ->
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
