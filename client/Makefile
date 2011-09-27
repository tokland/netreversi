build: game.js reversi.js

game.js: game.coffee
	coffee -c game.coffee

reversi.js: reversi.coffee
	coffee -c -b reversi.coffee

test: build
	NODE_PATH=.:spec:/usr/lib/node_modules \
	  /usr/lib/node_modules/jasmine-node/bin/jasmine-node --coffee spec
