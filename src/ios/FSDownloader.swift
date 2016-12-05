/*
 *
 *
 */
class Downloader: NSObject, NSURLSessionDownloadDelegate {

    // http://stackoverflow.com/questions/40920912/why-previous-finish-of-download-fires-after-stop-app-and-running-again?noredirect=1#comment69055651_40920912
    private var sessionConfig: NSURLSessionConfiguration? = nil
    private var session: NSURLSession? = nil

    private var finishedDownloads: [FSDownload] = []
    private var startedDownloads: [FSDownload] = []
    private var cb: (result: Int) -> Void = { arg in }

    // ---------------------
    // singleton
    // ---------------------
    private override init() {}

    internal static func Instance() -> Downloader {
        return instance
    }
    static let instance : Downloader = Downloader()

    internal func setup() {
        // launch when done in background
        self.sessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.amanninformatik.ner.backgroundLoader")
        self.sessionConfig!.sessionSendsLaunchEvents = true
        self.session = NSURLSession(configuration: self.sessionConfig!, delegate: self, delegateQueue: nil)
    }

    // ---------------------
    // handle download events
    // ---------------------
    //is called once the download is complete
    internal func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {

        let index = self.getIndexOfActiveDownload(downloadTask)
        print("[FileSync] active downloads", self.startedDownloads.count)

        // move finished downloads
        if index != nil {
            let download = self.startedDownloads[index!]
            FileSystem.Instance().moveToRoot(location, relativeTo: download.localPath)

            self.finishedDownloads.append(download)
            self.startedDownloads.removeAtIndex(index!)
        } else {
            print("[FileSync] fs-download not found in list", downloadTask.originalRequest!)
            print("[FileSync] fs-download list", self.startedDownloads)
        }

        if self.startedDownloads.count < 4 {
            print("[FileSync] fs-download list", self.startedDownloads)
        }

        // finished all downloads
        if self.startedDownloads.count == 0 {

            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setValue(false, forKey: "working")
            defaults.synchronize()

            self.cb(result: 0)
            print("[FileSync] Crazy shit, we finished downloading all files")
        }
    }

    //this is to track progress
    internal func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    }

    // if there is an error during download this will be called
    internal func URLSession(session: NSURLSession, downloadTask: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if(error != nil)
        {
            // failed download should also be removed from active downloads
            let index = getIndexOfActiveDownload(downloadTask)

            if index != nil {
                let failedDownload = self.startedDownloads[index!]
                self.startedDownloads.removeAtIndex(index!)

                // restart one time
                if failedDownload.restart == 0 {
                    failedDownload.restart = 1
                    failedDownload.downloadTask = self.session!.downloadTaskWithURL(failedDownload.url)
                    failedDownload.downloadTask!.resume()
                    self.startedDownloads.append(failedDownload)
                }

            } else {
                print("[FileSync] fs-download failed not found in list", downloadTask.originalRequest!)
            }

            print("[FileSync] Download completed with error: \(error!.localizedDescription)");
            print("[FileSync] Download completet with error", downloadTask.originalRequest!)
        }
    }

    // ---------------------
    // create, find downloads
    // ---------------------
    // get index of active download
    private func getIndexOfActiveDownload(task: NSURLSessionTask) -> Int? {
        for (index, startedDownload) in self.startedDownloads.enumerate() {
            if startedDownload.downloadTask?.taskIdentifier == task.taskIdentifier {
                return index
            }
        }
        return nil
    }

    // download all files
    internal func downloadMultiple(files: NSMutableArray, remoteBaseUrl: NSURL, completion: (result: Int)->()) -> Void {
        self.cb = completion

        for item in files {
            let downloadUrl = remoteBaseUrl.URLByAppendingPathComponent(item["file"] as! String)!

            let download = FSDownload(url: downloadUrl)
            download.isDownloading = true
            download.localPath = item["file"] as! String
            download.downloadTask = self.session!.downloadTaskWithURL(downloadUrl)
            download.downloadTask!.resume()
            self.startedDownloads.append(download)
        }
    }

    // check hash, to enshure correct loading
}