var exec = require('cordova/exec');

exports.sync = function(arg0, success, error) {
    exec(success, error, "FileSync", "sync", [arg0]);
};
