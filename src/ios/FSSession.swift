/**
 * background  http://stackoverflow.com/questions/40920912/why-previous-finish-of-download-fires-after-stop-app-and-running-again?noredirect=1#comment69055651_40920912
 *
 * main        https://developer.apple.com/reference/foundation/nsurlsessiondelegate
 * up/down     https://developer.apple.com/reference/foundation/nsurlsessiontaskdelegate
 * upload      https://developer.apple.com/reference/foundation/nsurlsessiondatadelegate
 * download    https://developer.apple.com/reference/foundation/nsurlsessiondownloaddelegate
 *
 * task        https://developer.apple.com/reference/foundation/nsurlsessiontask
 * upload      https://developer.apple.com/reference/foundation/nsurlsessionuploadtask
 * download
 *
 **/

class FSSession: NSObject, NSURLSessionTaskDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate {

    var sessionConfig: NSURLSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.amanninformatik.ner.backgroundLoader")
    var session: NSURLSession? = nil

    var fsDownloader: FSDownloader? = nil
    var fsUploader: FSUploader? = nil
    var cb: (result: Int) -> Void = { arg in }

    private override init() {
        super.init()
        self.sessionConfig.sessionSendsLaunchEvents = true
        self.session = NSURLSession(configuration: self.sessionConfig, delegate: self, delegateQueue: nil)

        self.fsDownloader = FSDownloader(session: self.session!)
        self.fsUploader = FSUploader(session: self.session!)
    }

    internal static func Instance() -> FSSession {
        return instance
    }
    static let instance: FSSession = FSSession()

    internal func setCB(completion: (result: Int)->()) -> Void {
        self.cb = completion
    }

    // DID FINISH IN BACKGROUND
    internal func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        print("[FileSync] finished tasks while in background")
    }

    // UPLOAD / DOWNLOAD FINISH
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {

        guard let type = task.taskDescription else {
            print("[FileSync] ERROR: we used task.taskDescription to know if its a down- or upload but it's missing")
            return
        }

        // print("finishid task", type)
        // print("finishid task", task.originalRequest?.URL)

        if type == "download" {
            self.fsDownloader!.handleComplete(task, error: error)
        } else if type == "upload" {
           self.fsUploader!.handleComplete(task, error: error)
        }

        print(self.fsUploader?.startedTask, self.fsDownloader?.startedTask)
        if (self.fsUploader?.startedTask.count)! == 0 && (self.fsDownloader?.startedTask.count)! == 0 {
            self.cb(result: 0)
        }

    }

    // DOWNLOAD FINISH
    internal func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        self.fsDownloader!.handleDownloadFinished(downloadTask, downloadLocation: location)
    }

    // DOWNLOAD PROGRESS
    internal func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // not needed, counting files should be enough
    }

    // UPLOAD PROGRESS
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        // not needed, counting files should be enough
    }
}
