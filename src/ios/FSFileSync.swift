import Foundation

/*
 *
 *
 *
 */

@objc(FileSync) class FileSync : CDVPlugin {
  func sync(command: CDVInvokedUrlCommand) {

    let jsOptions =  command.arguments[0] as? NSDictionary;

    func handlerPluginResult(statusCode: Int) -> Void {
        var pluginResult: CDVPluginResult
        if (statusCode < 0) {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsInt: Int32(statusCode));
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsInt: Int32(statusCode));
        }
        self.commandDelegate.sendPluginResult(pluginResult, callbackId:command.callbackId);
    }


    // whatever :P
    var main:Main? = Main(jsOptions: jsOptions!, pluginResultCB: handlerPluginResult)
    main = nil
  }
}