class FSDownload: NSObject {

    var url: NSURL
    var localPath: String = ""

    var isDownloading = false
    var restart = 0
    var error = false

    var progress: Float = 0.0

    var downloadTask: NSURLSessionDownloadTask?
    var resumeData: NSData?

    init(url: NSURL) {
        self.url = url
    }
}