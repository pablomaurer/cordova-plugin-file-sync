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

class FSSession: NSObject, URLSessionTaskDelegate, URLSessionDelegate, URLSessionDownloadDelegate {

    var sessionConfig: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "com.amanninformatik.ner.backgroundLoader")
    var session: Foundation.URLSession? = nil

    var fsDownloader: FSDownloader? = nil
    var fsUploader: FSUploader? = nil
    var cb: (Int) -> Void = { arg in }

    fileprivate override init() {
        super.init()
        self.sessionConfig.sessionSendsLaunchEvents = true
        self.session = Foundation.URLSession(configuration: self.sessionConfig, delegate: self, delegateQueue: nil)

        self.fsDownloader = FSDownloader(session: self.session!)
        self.fsUploader = FSUploader(session: self.session!)
    }

    internal static func Instance() -> FSSession {
        return instance
    }
    static let instance: FSSession = FSSession()

    internal func setCB(_ completion: @escaping (Int)->()) -> Void {
        self.cb = completion
    }

    // DID FINISH IN BACKGROUND
    internal func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("[FileSync] finished tasks while in background")
    }

    // UPLOAD / DOWNLOAD FINISH
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        guard let type = task.taskDescription else {
            print("[FileSync] ERROR: we used task.taskDescription to know if its a down- or upload but it's missing")
            return
        }

        if type == "download" {
            self.fsDownloader!.handleComplete(task: task, error: error)
        } else if type == "upload" {
            self.fsUploader!.handleComplete(task: task, error: error)
        }

        if (self.fsUploader?.startedTask.count)! == 0 && (self.fsDownloader?.startedTask.count)! == 0 {
            self.cb(0)
        }

    }

    // DOWNLOAD FINISH
    internal func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.fsDownloader!.handleDownloadFinished(downloadTask: downloadTask, downloadLocation: location)
    }

    // DOWNLOAD PROGRESS
    internal func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // not needed, counting files should be enough
    }

    // UPLOAD PROGRESS
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        // not needed, counting files should be enough
    }
}