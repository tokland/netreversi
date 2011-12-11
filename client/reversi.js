(function() {
  var ReversiSocketIOServer, _;

  _ = require('underscore_extensions');

  _(global).extend_from(_, ["map", "mash", "zip", "flatten", "takeWhile"]);

  exports.ReversiEngine = (function() {

    ReversiEngine.prototype.SIZE = 8;

    ReversiEngine.prototype.START_PIECES = {
      black: [[3, 4], [4, 3]],
      white: [[3, 3], [4, 4]]
    };

    ReversiEngine.prototype.AXIS_INCREMENTS = [[+0, +1], [+0, -1], [+1, +0], [-1, +0], [+1, +1], [+1, -1], [-1, +1], [-1, -1]];

    function ReversiEngine(options) {
      if (options == null) options = {};
      this.options = _(options).defaults({
        size: this.SIZE,
        start_pieces: this.START_PIECES
      });
      this.init();
    }

    ReversiEngine.prototype.getStateNextTurn = function(state) {
      var next_player_turn, player_turn, player_turn2;
      player_turn = this.getOtherPlayer(state.player_turn);
      next_player_turn = this.canPlayerMove(state.pieces, player_turn) ? player_turn : (player_turn2 = this.getOtherPlayer(player_turn), this.canPlayerMove(state.pieces, player_turn2) ? player_turn2 : null);
      return _(state).merge({
        player_turn: next_player_turn,
        player_moves: this.validMovesForPlayer(state.pieces, next_player_turn)
      });
    };

    ReversiEngine.prototype.canPlayerMove = function(pieces, player) {
      return _(this.validMovesForPlayer(pieces, player)).isNotEmpty();
    };

    ReversiEngine.prototype.getOtherPlayer = function(player) {
      if (player === "black") {
        return "white";
      } else {
        return "black";
      }
    };

    ReversiEngine.prototype.getPositionToPlayer = function(pieces, player) {
      var black, pos, white;
      black = mash((function() {
        var _i, _len, _ref, _results;
        _ref = pieces.black;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pos = _ref[_i];
          _results.push([pos, "black"]);
        }
        return _results;
      })());
      white = mash((function() {
        var _i, _len, _ref, _results;
        _ref = pieces.white;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pos = _ref[_i];
          _results.push([pos, "white"]);
        }
        return _results;
      })());
      return _(black).merge(white);
    };

    ReversiEngine.prototype.traverseSquares = function(player, _arg, pos2player) {
      var cs, dx, dy, last_x, last_y, other_player, size, x, xs, y, ys, _i, _j, _k, _len, _ref, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _results, _results2, _results3;
      x = _arg[0], y = _arg[1];
      other_player = this.getOtherPlayer(player);
      size = this.options.size;
      _ref = this.AXIS_INCREMENTS;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref2 = _ref[_i], dx = _ref2[0], dy = _ref2[1];
        xs = (dx === 0 ? _(x).repeat(size) : (function() {
          _results2 = [];
          for (var _j = _ref3 = x + dx, _ref4 = (dx > 0 ? size - 1 : 0); _ref3 <= _ref4 ? _j <= _ref4 : _j >= _ref4; _ref3 <= _ref4 ? _j++ : _j--){ _results2.push(_j); }
          return _results2;
        }).apply(this));
        ys = (dy === 0 ? _(y).repeat(size) : (function() {
          _results3 = [];
          for (var _k = _ref5 = y + dy, _ref6 = (dy > 0 ? size - 1 : 0); _ref5 <= _ref6 ? _k <= _ref6 : _k >= _ref6; _ref5 <= _ref6 ? _k++ : _k--){ _results3.push(_k); }
          return _results3;
        }).apply(this));
        if (pos2player[[xs[0], ys[0]]] === other_player) {
          cs = takeWhile(zip(xs, ys), function(pos) {
            return pos2player[pos] === other_player;
          });
          _ref7 = _(cs).last(), last_x = _ref7[0], last_y = _ref7[1];
          if (pos2player[[last_x + dx, last_y + dy]] === player) {
            _results.push({
              squares: cs,
              pos: [x, y]
            });
          } else {
            _results.push(void 0);
          }
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    ReversiEngine.prototype.validMovesForPlayer = function(pieces, player) {
      var pos2player, squares, x, y;
      if (!player) return [];
      pos2player = this.getPositionToPlayer(pieces, player);
      squares = (function() {
        var _results;
        _results = [];
        for (x = 0; x < 8; x++) {
          _results.push((function() {
            var _results2;
            _results2 = [];
            for (y = 0; y < 8; y++) {
              if (!pos2player[[x, y]]) {
                _results2.push(this.traverseSquares(player, [x, y], pos2player));
              } else {
                _results2.push(void 0);
              }
            }
            return _results2;
          }).call(this));
        }
        return _results;
      }).call(this);
      return _(squares).chain().flatten().compact().pluck("pos").value();
    };

    ReversiEngine.prototype.flippedPiecesOnMove = function(pieces, player, pos) {
      var pos2player, squares;
      if (!player) return [];
      pos2player = this.getPositionToPlayer(pieces, player);
      squares = this.traverseSquares(player, pos, pos2player);
      return _(squares).chain().compact().pluck("squares").flatten1().value();
    };

    ReversiEngine.prototype.setNewState = function(new_state) {
      return this.state = new_state;
    };

    ReversiEngine.prototype.getCurrentState = function() {
      return this.state;
    };

    ReversiEngine.prototype.init = function() {
      return this.setNewState(this.getStateNextTurn({
        pieces: this.options.start_pieces,
        player_turn: null
      }));
    };

    ReversiEngine.prototype.move = function(pos) {
      var flipped_pieces, new_pieces, new_state, p, pieces_player, pieces_player2, player, player2;
      player = this.state.player_turn;
      player2 = this.getOtherPlayer(player);
      flipped_pieces = this.flippedPiecesOnMove(this.state.pieces, player, pos);
      if (_(flipped_pieces).isEmpty()) return false;
      pieces_player = this.state.pieces[this.state.player_turn].concat([pos], flipped_pieces);
      pieces_player2 = (function() {
        var _i, _len, _ref, _results;
        _ref = this.state.pieces[player2];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          p = _ref[_i];
          if (!_(flipped_pieces).containsObject(p)) _results.push(p);
        }
        return _results;
      }).call(this);
      new_pieces = mash([[player, pieces_player], [player2, pieces_player2]]);
      new_state = this.setNewState(this.getStateNextTurn(_(this.state).merge({
        pieces: new_pieces
      })));
      return {
        new_state: new_state,
        flipped_pieces: flipped_pieces
      };
    };

    return ReversiEngine;
  })();

  ReversiSocketIOServer = (function() {

    function ReversiSocketIOServer() {}

    return ReversiSocketIOServer;
  })();

  exports.ReversiClient = (function() {

    ReversiClient.prototype.SIZE = 8;

    ReversiClient.prototype.COLORS = {
      square: "#090",
      square_with_move: {
        black: "#162",
        white: "#3A5"
      },
      square_hovered: "#5C6",
      square_lines: "#333",
      players: {
        black: "#000",
        white: "#FFF"
      }
    };

    function ReversiClient(server, container, width, height, options) {
      if (options == null) options = {};
      this.options = _(options).defaults;
      this.server = server;
      this.size = this.SIZE;
      this.colors = this.COLORS;
      this.width = width;
      this.height = height;
      this.paper = Raphael(container, width, height);
      this.events = $(new Object());
      this.paper_set = this.paper.set();
      this.state = "idle";
    }

    ReversiClient.prototype.getOtherPlayer = function(player) {
      if (player === "black") {
        return "white";
      } else {
        return "black";
      }
    };

    ReversiClient.prototype.update = function(state, flipped_pieces) {
      this.draw(state, flipped_pieces);
      this.events.trigger("move", state);
      if (!state.player_turn) {
        this.events.trigger("finished", state);
        return this.state = "idle";
      }
    };

    ReversiClient.prototype.draw = function(state, flipped_pieces) {
      var piece, player, pos, squares, was_flipped, _i, _len, _ref, _results;
      this.paper_set.remove();
      this.paper_set = this.paper.set();
      squares = this.draw_board(state.player_turn, state.player_moves);
      this.paper_set.push.apply(this.paper_set, flatten(squares));
      _ref = ["black", "white"];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        player = _ref[_i];
        _results.push((function() {
          var _j, _len2, _ref2, _results2;
          _ref2 = state.pieces[player];
          _results2 = [];
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            pos = _ref2[_j];
            was_flipped = _(flipped_pieces).containsObject(pos);
            piece = this.draw_piece(player, pos, was_flipped);
            _results2.push(this.paper_set.push(piece));
          }
          return _results2;
        }).call(this));
      }
      return _results;
    };

    ReversiClient.prototype.draw_board = function(current_player, hoverable_squares) {
      var rect, square_with_move_color, step_x, step_y, with_move, x, y, _ref, _ref2, _results;
      _ref = [this.width / this.size, this.height / this.size], step_x = _ref[0], step_y = _ref[1];
      _results = [];
      for (x = 0, _ref2 = this.size; 0 <= _ref2 ? x < _ref2 : x > _ref2; 0 <= _ref2 ? x++ : x--) {
        _results.push((function() {
          var _ref3, _results2,
            _this = this;
          _results2 = [];
          for (y = 0, _ref3 = this.size; 0 <= _ref3 ? y < _ref3 : y > _ref3; 0 <= _ref3 ? y++ : y--) {
            with_move = _(hoverable_squares).containsObject([x, y]);
            rect = this.paper.rect(x * step_x, y * step_y, this.width / this.size, this.height / this.size);
            square_with_move_color = this.colors.square_with_move[current_player];
            rect.attr({
              fill: this.colors.square,
              stroke: this.colors.square_lines
            });
            if (with_move) {
              rect.animate({
                fill: square_with_move_color,
                stroke: this.colors.square_lines
              }, 400);
              (function(rect, x, y) {
                rect.mouseover(function() {
                  return rect.attr({
                    fill: _this.colors.square_hovered
                  });
                });
                rect.mouseout(function() {
                  return rect.attr({
                    fill: square_with_move_color
                  });
                });
                return rect.mousedown(function() {
                  var response;
                  if (response = _this.server.move([x, y])) {
                    return _this.update(response.new_state, response.flipped_pieces);
                  }
                });
              })(rect, x, y);
            }
            _results2.push(rect);
          }
          return _results2;
        }).call(this));
      }
      return _results;
    };

    ReversiClient.prototype.draw_piece = function(player, _arg, flip_effect) {
      var attr, color, other_player, paper_x, paper_y, piece, rx, ry, step_x, step_y, x, y, _ref, _ref2, _ref3,
        _this = this;
      x = _arg[0], y = _arg[1];
      _ref = [this.width / this.size, this.height / this.size], step_x = _ref[0], step_y = _ref[1];
      _ref2 = [(x * step_x) + (step_x / 2), (y * step_y) + (step_y / 2)], paper_x = _ref2[0], paper_y = _ref2[1];
      _ref3 = [(step_x / 2) * 0.8, (step_y / 2) * 0.8], rx = _ref3[0], ry = _ref3[1];
      other_player = this.getOtherPlayer(player);
      color = (flip_effect ? this.colors.players[other_player] : this.colors.players[player]);
      piece = this.paper.ellipse(paper_x, paper_y, rx, ry);
      piece.attr({
        "fill": color,
        "stroke-opacity": 0
      });
      if (flip_effect) {
        attr = (player === "white" ? "rx" : "ry");
        piece.animate(mash([[attr, 0]]), 250, function() {
          piece.attr({
            fill: _this.colors.players[player]
          });
          return piece.animate(mash([[attr, rx]]), 250, "backOut");
        });
      }
      return piece;
    };

    ReversiClient.prototype.start = function() {
      this.state = "playing";
      return this.update(this.server.init(), []);
    };

    ReversiClient.prototype.bind = function(name, callback) {
      return this.events.bind(name, _.bind(callback, this));
    };

    return ReversiClient;
  })();
}).call(this);
