/*
 *
 *
 *
 */
class Main {

    private let fileSystem: FileSystem
    private let release: Release
    private let manifest: Manifest
    private var pluginResultCB: (statusCode: Int) -> Void = { arg in }
    private let remoteDir: NSURL
    private var working: Bool


    init(jsOptions: NSDictionary, pluginResultCB: (result: Int)->()) {

        // load status
        let defaults = NSUserDefaults.standardUserDefaults()
        self.working =  defaults.boolForKey("working")
        print("[FileSync] already working (may needs to handle all done background threads, before starting again)", self.working)

        // setup filesystem (must be done, before something uses this singleton)
        self.fileSystem = FileSystem.Instance()
        self.fileSystem.setup(jsOptions["pathLocalDir"] as? String)

        self.remoteDir = NSURL(string: jsOptions["pathRemoteDir"] as! String)!

        self.release = Release()
        self.manifest = Manifest(manifestRemote: jsOptions["pathManifest"] as! String, manifestLocal: self.fileSystem.pathRoot)

        // else session will not be setup, and outstanding background tasks will not finish.
        Downloader.Instance().setup()

        if !self.working {
            self.release.isNewVersionAvailable(jsOptions["pathRelease"] as! String, completion: handleIsNewVersionAvailable)
        } else { }

        self.pluginResultCB = pluginResultCB
        // TODO: instead casting options here, parse them as struct? for better error handling where you also could throw option xy not set
    }

    private func handleIsNewVersionAvailable(newRelease: Bool?, error: Int?) -> Void {
        if ((error) != nil) {
            self.sendSuccessCB(error!)
        } else {
            print("[FileSync] newRelease: ", newRelease!)
            if newRelease! {
                self.manifest.loadAndCompare(handleLoadAndCompare)
            } else {
                pluginResultCB(statusCode: 1)
            }
        }
    }

    private func handleLoadAndCompare(filesToDownload: NSMutableArray, filesToDelete: NSMutableArray, filesToUpload: NSMutableArray, error: Int?) -> Void {
        print("[FileSync] filesToDownload", filesToDownload.count)
        print("[FileSync] filesToDelete", filesToDelete.count)
        print("[FileSync] filesToUpload", filesToUpload.count)

        guard error == nil else {
            pluginResultCB(statusCode: error!)
            return
        }

        if filesToUpload.count > 0 || filesToDownload.count > 0 {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setValue(true, forKey: "working")
            defaults.synchronize()
        }

        // delete
        if filesToDelete.count > 0 {
            fileSystem.deleteFilesInRoot(filesToDelete)
        }

        // download
        if filesToDownload.count > 0 {
            Downloader.Instance().downloadMultiple(filesToDownload, remoteBaseUrl: self.remoteDir, completion: self.handleDownloadComplete)
        } else {
            self.handleDownloadComplete(0)
        }

        // to be able to catch all errors, i can't do everything here
        // have to first download, in downloadHandler start delete, and start upload, in uploadHandler call finally pluginCallback

        // upload
        if filesToUpload.count > 0 {
            // TODO: uploader class -> first check if you can save to this location
        }

    }

    private func handleDownloadComplete(result: Int) -> Void {
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