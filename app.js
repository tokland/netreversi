var express = require('express')
, sio = require('socket.io');

app = express.createServer();

app.listen(3030, function() {
    var addr = app.address();
    console.log('    app listening on http://' + addr.address + ':' + addr.port);
});

var io = sio.listen(app);
var clients = {};
var players = 0;
var maxRow = 8;
var maxColumn = 8;
var maxIndex = maxRow * maxColumn;
var board = new Array(maxIndex);

io.sockets.on('connection', function(socket) {
    socket.on('request-game', onRequest);
    socket.on('clicked', handleClick);
});

// API Functions
/** Request to play a game
*
* @param: {string} Unique identifier of the client.
*
* @returns: {integer} Current number of players that requested a game.
*/
function onRequest(client_id) {
    if (players == 2) {
	// startNewGame
    } else {
	players += 1;
	clients[client_id] = socket.client_id = client_id;
    }
};

/** Process
*
* @param: {integer, integer} Position
*
* @returns: {integer} Current number of players that requested a game.
*/
function handleClick(x, y) {
    if (is_valid_move(x, y)) {
	;
    } else {
	io.sockets.emit('not-valid-move')
    }
};


// Intern functions
function is_valid_move(x, y) {
    true;
};

function index(column, row) {
    return column + (row * maxColumn);
};

function startNewGame() {
    //Delete blocks from previous game
    for (var i=0; i < maxIndex; i++) {
	if (board[i] !=null)
	    board[i].destroy();
    }

    //Initialize Board
    board = new Array(maxIndex);
    for (var column = 0; column < maxColumn; column++) {
	for (var row = 0;  row < maxRow; row++) {
	    board[index(column, row)] = null;
	}
    }
};

function victoryCheck() {
}
