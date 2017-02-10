/*
 *
 *
 *
 */
class FSMain {

    private let fileSystem: FSFileSystem
    private let release: FSRelease
    private let manifest: FSManifest
    private var pluginResultCB: (statusCode: Int) -> Void = { arg in }
    private let remoteDir: NSURL
    private let pathUpload: NSURL
    private let fsSession: FSSession
    private let reqParameter: Dictionary<String, String>?

    init(jsOptions: Dictionary<String,String>, reqParamater: Dictionary<String, String>?, pluginResultCB: (result: Int)->()) {
        self.reqParameter = reqParamater

        // setup filesystem (must be done, before something uses this singleton)
        self.fileSystem = FSFileSystem.Instance()
        self.fileSystem.setup(jsOptions["pathLocalDir"])

        self.remoteDir = NSURL(string: jsOptions["pathRemoteDir"]!)!
        self.pathUpload = NSURL(string: (jsOptions["pathUpload"])!)!

        self.release = FSRelease()
        self.manifest = FSManifest(manifestRemote: jsOptions["pathManifest"]!, pathLocal: self.fileSystem.pathRoot, parameter: reqParamater)
        self.fsSession = FSSession.Instance()
        self.fsSession.setCB(self.handleNetworkRequestsComplete)

        // CHECK IF ALREADY WORKING, IF NOT START
        func da(task: [NSURLSessionTask]) -> Void {
            if task.count == 0 {
                guard jsOptions["pathRelease"] != nil else {
                    self.manifest.loadAndCompare(handleLoadAndCompare)
                    return
                }
                self.release.isNewVersionAvailable(jsOptions["pathRelease"]!, completion: handleIsNewVersionAvailable)
            } else {
                print("[FileSync] info: already working wait until we are done")
            }
        }

        if #available(iOS 9.0, *) {
            self.fsSession.session?.getAllTasksWithCompletionHandler(da)
        } else {
            print("[FileSync] IOS 8 is not supported")
        }
        // CHECK IF ALREADY WORKING, IF NOT START

        self.pluginResultCB = pluginResultCB
    }

    private func handleIsNewVersionAvailable(newRelease: Bool?, error: Int?) -> Void {
        print("[FileSync] newRelease: ", newRelease)

        guard error == nil else {
            self.sendSuccessCB(error!)
            return
        }

        guard newRelease == true else {
            pluginResultCB(statusCode: 1)
            return
        }

        self.manifest.loadAndCompare(handleLoadAndCompare)
    }

    private func handleLoadAndCompare(filesToDownload: NSMutableArray, filesToDelete: NSMutableArray, filesToUpload: NSMutableArray, error: Int?) -> Void {
        print("[FileSync] filesToDownload", filesToDownload.count)
        print("[FileSync] filesToDelete", filesToDelete.count)
        print("[FileSync] filesToUpload", filesToUpload.count)

        guard error == nil else {
            pluginResultCB(statusCode: error!)
            return
        }

        // delete
        if filesToDelete.count > 0 {
            fileSystem.deleteFilesInRoot(filesToDelete)
        }

        // check if loader must be started
        if filesToUpload.count == 0 && filesToDownload.count == 0 {
            self.handleNetworkRequestsComplete(0);
        }

        // download
        if filesToDownload.count > 0 {
            self.fsSession.fsDownloader!.startDownloads(filesToDownload, remoteBaseUrl: self.remoteDir)
        }

        // upload
        if filesToUpload.count > 0 {
            self.fsSession.fsUploader!.startUploads(filesToUpload, pathLocal: self.fileSystem.pathRoot, pathUpload: self.pathUpload, optionalParams: self.reqParameter)
        }

    }

    private func handleNetworkRequestsComplete(result: Int) -> Void {
        self.manifest.saveNewManifest()
        self.release.setNewVersion()
        pluginResultCB(statusCode: 0)
    }

    private func sendErrorCB(error: Int) -> Void {
        print("[FileSync] error: ", error)
    }

    private func sendSuccessCB(status: Int) -> Void {
        print("[FileSync] status: ", status)
    }

}
