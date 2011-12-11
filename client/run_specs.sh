#!/bin/bash
export NODE_PATH=.:spec:/usr/lib/node_modules
/usr/lib/node_modules/jasmine-node/bin/jasmine-node --coffee spec
