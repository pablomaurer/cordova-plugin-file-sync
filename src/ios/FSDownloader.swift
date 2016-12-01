/*
 *
 *
 */
class Downloader: NSObject, NSURLSessionDownloadDelegate {

    private let sessionConfig: NSURLSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.amanninformatik.ner.backgroundLoader")
    private var session: NSURLSession?

    private var filesToDownload: NSMutableArray = []
    private let startedDownloads: NSMutableArray = []
    private var cb: (result: Int) -> Void = { arg in }


    // singleton
    private override init() {}
    internal static func Instance() -> Downloader {
        return instance
    }
    static let instance : Downloader = Downloader()

    // init session only once
    private func getSession() -> NSURLSession {
        if (session != nil) {
            return self.session!
        } else {
            self.session = NSURLSession(configuration: self.sessionConfig, delegate: self, delegateQueue: nil)
            return self.session!
        }
    }

    //is called once the download is complete
    internal func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {

        // find matching manifestObject through finished downloadTask and use it to generate path
        let indexDownloadTask = self.startedDownloads.indexOfObjectIdenticalTo(downloadTask.originalRequest!)
        let listItem = self.filesToDownload.objectAtIndex(indexDownloadTask)

        // move file
        FileSystem.Instance().moveToRoot(location, relativeTo: listItem["file"] as! String)

        // remove downloadTask and matching item in filesToDownload to enshure the indexes of both array still matches
        self.startedDownloads.removeObjectAtIndex(indexDownloadTask)
        self.filesToDownload.removeObjectAtIndex(indexDownloadTask)
        print("Remaining Downloads: ", self.startedDownloads)

        // finished all downloads TODO: SEND CALLBACK
        if self.startedDownloads.count == 0 {
            self.cb(result: 0)
            print("Crazy shit, we finished downloading all files")
        }
    }

    //this is to track progress
    internal func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    }

    // if there is an error during download this will be called
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if(error != nil)
        {
            print("Download completed with error: \(error!.localizedDescription)");
        }
    }

    // download single
    internal func download(url: NSURL) -> Void {
        let session = self.getSession()
        let task = session.downloadTaskWithURL(url)
        self.startedDownloads.addObject(task.originalRequest!)
        // print("added new url to startedDownloads", self.startedDownloads)
        task.resume()
    }

    // download multiple
    internal func downloadMultiple(files: NSArray, remoteBaseUrl: NSURL, completion: (result: Int)->()) -> Void {
        self.filesToDownload = files as! NSMutableArray
        self.cb = completion

        for item in self.filesToDownload {
            self.download(remoteBaseUrl.URLByAppendingPathComponent(item["file"] as! String)!)
        }
    }

    // check hash, to enshure correct loading
}