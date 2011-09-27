build: game reversi

game: game.js
	coffee -c -b game.coffee

reversi: reversi.js
	coffee -c -b reversi.coffee

test: build
	NODE_PATH=.:spec:/usr/lib/node_modules \
	  /usr/lib/node_modules/jasmine-node/bin/jasmine-node --coffee spec
