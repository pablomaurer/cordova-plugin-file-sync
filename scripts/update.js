#!/usr/bin/env node

// runs the script `manifest.json` and if the manifest did change it will update the version property in the file you specified

// arg3: path of manifest -> default current dir
// arg4: path of updateFile -> default release.json with property release
// arg5: property for release -> defaults to release (also make it as a option in native plugin)

var lib = {
    path: path.require('path')
};

var paths = {
    dirCompare: process.argv[3] || lib.path.dirname(),
    dirSave: process.argv[4] || lib.path.dirname()
};
