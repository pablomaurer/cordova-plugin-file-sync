#!/usr/bin/env node

// creates the manifest file
// based on https://github.com/nordnet/cordova-hot-code-push-cli/blob/master/src/context.js

// arg3: dir to compare -> default current dir
// arg4: where to save manifest -> default current dir

var lib = {
    path: path.require('path')
};

var paths = {
    dirCompare: process.argv[3] || lib.path.dirname(),
    dirSave: process.argv[4] || lib.path.dirname()
};

