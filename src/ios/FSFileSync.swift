import Foundation

/*
 *
 *
 *
 */

@objc(FileSync) class FileSync : CDVPlugin {

  func sync(command: CDVInvokedUrlCommand) {

    // result
    func handlerPluginResult(statusCode: Int) -> Void {
        var pluginResult: CDVPluginResult
        if (statusCode < 0) {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsInt: Int32(statusCode));
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsInt: Int32(statusCode));
        }
        self.commandDelegate.sendPluginResult(pluginResult, callbackId:command.callbackId);
    }

    // js options
    guard let plainOptions = command.arguments[0] as? Dictionary<String, String> else {
        handlerPluginResult(7) // mising options
        return
    }

    let reqParameter = command.arguments[1] as? Dictionary<String, String>
    print("[FileSync] ReqParameters", reqParameter )

    // whatever :P
    _ = FSMain(jsOptions: plainOptions, reqParamater: reqParameter, pluginResultCB: handlerPluginResult)
  }
}
