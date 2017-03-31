/*
 *
 *
 *
 */
class FSMain {

    fileprivate let fileSystem: FSFileSystem
    fileprivate let release: FSRelease
    fileprivate let manifest: FSManifest
    fileprivate var pluginResultCB: (Int) -> Void = { arg in }
    fileprivate let remoteDir: URL
    fileprivate let pathUpload: URL
    fileprivate let fsSession: FSSession
    fileprivate let reqParameter: Dictionary<String, String>?

    init(jsOptions: Dictionary<String,String>, reqParamater: Dictionary<String, String>?, pluginResultCB: @escaping (Int)->()) {
        self.reqParameter = reqParamater

        // setup filesystem (must be done, before something uses this singleton)
        self.fileSystem = FSFileSystem.Instance()
        self.fileSystem.setup(jsOptions["pathLocalDir"])

        self.remoteDir = URL(string: jsOptions["pathRemoteDir"]!)!
        self.pathUpload = URL(string: (jsOptions["pathUpload"])!)!

        self.release = FSRelease()
        self.manifest = FSManifest(manifestRemote: jsOptions["pathManifest"]!, pathLocal: self.fileSystem.pathRoot, parameter: reqParamater)
        self.fsSession = FSSession.Instance()
        self.fsSession.setCB(self.handleNetworkRequestsComplete)

        // CHECK IF ALREADY WORKING, IF NOT START
        func da(_ task: [URLSessionTask]) -> Void {
            if task.count == 0 {
                guard jsOptions["pathRelease"] != nil else {
                    self.manifest.loadAndCompare(comparedCB: handleLoadAndCompare)
                    return
                }
                self.release.isNewVersionAvailable(jsOptions["pathRelease"]!, completion: handleIsNewVersionAvailable)
            } else {
                print("[FileSync] info: already working wait until we are done")
            }
        }

        if #available(iOS 9.0, *) {
            self.fsSession.session?.getAllTasks(completionHandler: da)
        } else {
            print("[FileSync] IOS 8 is not supported")
        }
        // CHECK IF ALREADY WORKING, IF NOT START

        self.pluginResultCB = pluginResultCB
    }

    fileprivate func handleIsNewVersionAvailable(_ newRelease: Bool?, error: Int?) -> Void {
        print("[FileSync] newRelease: ", newRelease as Any)

        guard error == nil else {
            self.sendSuccessCB(error!)
            return
        }

        guard newRelease == true else {
            pluginResultCB(1)
            return
        }

        self.manifest.loadAndCompare(comparedCB: handleLoadAndCompare)
    }

    fileprivate func handleLoadAndCompare(_ filesToDownload: [AnyObject], filesToDelete: [String], filesToUpload: [String], error: Int?) -> Void {
        print("[FileSync] filesToDownload", filesToDownload.count)
        print("[FileSync] filesToDelete", filesToDelete.count)
        print("[FileSync] filesToUpload", filesToUpload.count)

        guard error == nil else {
            pluginResultCB(error!)
            return
        }

        // delete
        if filesToDelete.count > 0 {
            fileSystem.deleteFilesInRoot(files: filesToDelete)
        }

        // check if loader must be started
        if filesToUpload.count == 0 && filesToDownload.count == 0 {
            self.handleNetworkRequestsComplete(0);
        }

        // download
        if filesToDownload.count > 0 {
            self.fsSession.fsDownloader!.startDownloads(files: filesToDownload, remoteBaseUrl: self.remoteDir)
        }

        // upload
        if filesToUpload.count > 0 {
            self.fsSession.fsUploader!.startUploads(files: filesToUpload, pathLocal: self.fileSystem.pathRoot, pathUpload: self.pathUpload, optionalParams: self.reqParameter)
        }

    }

    fileprivate func handleNetworkRequestsComplete(_ result: Int) -> Void {
        self.manifest.saveNewManifest()
        self.release.setNewVersion()
        pluginResultCB(0)
    }

    fileprivate func sendErrorCB(_ error: Int) -> Void {
        print("[FileSync] error: ", error)
    }

    fileprivate func sendSuccessCB(_ status: Int) -> Void {
        print("[FileSync] status: ", status)
    }

}
