var exec = require('cordova/exec');

exports.sync = function(arg0, arg1, success, error) {
    exec(success, error, "FileSync", "sync", [arg0, arg1]);
};
