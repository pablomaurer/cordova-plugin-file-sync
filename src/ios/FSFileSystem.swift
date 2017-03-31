import Foundation

/*
 *
 *
 *
 */

@objc(FileSync) class FileSync : CDVPlugin {
    
    func sync(_ command: CDVInvokedUrlCommand) {
        
        // result
        func handlerPluginResult(_ statusCode: Int) -> Void {
            var pluginResult: CDVPluginResult
            if (statusCode < 0) {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: Int32(statusCode));
            } else {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Int32(statusCode));
            }
            self.commandDelegate.send(pluginResult, callbackId:command.callbackId);
        }
        
        // js options
        guard let plainOptions = command.arguments[0] as? Dictionary<String, String> else {
            handlerPluginResult(7) // mising options
            return
        }
        
        let reqParameter = command.arguments[1] as? Dictionary<String, String>
        print("[FileSync] ReqParameters", reqParameter! )
        
        // whatever :P
        _ = FSMain(jsOptions: plainOptions, reqParamater: reqParameter, pluginResultCB: handlerPluginResult)
    }
}
