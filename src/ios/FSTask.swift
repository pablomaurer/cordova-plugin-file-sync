class FSTask: NSObject {

    var url: URL
    var localPath: String = ""

    var isLoading = false
    var restarts = 0
    var error = false

    var progress: Float = 0.0

    var sessionTask: URLSessionTask?
    var resumeData: Data?

    internal func start() -> Void {
        self.isLoading = true;
        self.sessionTask!.resume()
    }

    internal func restart(_ sessionTask: URLSessionTask) -> Bool {
        if (self.restarts == 0) {
            self.restarts = self.restarts + 1
            self.isLoading = true;
            self.sessionTask = sessionTask
            self.sessionTask!.resume()
            return true
        } else {
            print("[FileSync] fs-task failed the second time, giving up.", self.sessionTask!.originalRequest!)
            return false
        }
    }

    init(url: URL, localPath: String, sessionTask: URLSessionTask) {
        self.url = url
        self.localPath = localPath
        self.sessionTask = sessionTask
    }
}
