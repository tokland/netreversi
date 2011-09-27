should = require 'should'
game = require '../reversi'

describe "ReversiEngine", ->
  describe "init", ->
    it "starts with black turn", ->
      engine = new game.ReversiEngine
      engine.player_turn.should.equal "black"

  describe "processNextTurn", ->
    it "turns black turn to white", ->
      engine = new game.ReversiEngine
      engine.player_turn.should.equal "black"
      engine.processNextTurn()
      engine.player_turn.should.equal "white"
      engine.processNextTurn()
      engine.player_turn.should.equal "black"
