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


    init(jsOptions: NSDictionary, pluginResultCB: (result: Int)->()) {
        self.fileSystem = FileSystem.Instance()
        self.fileSystem.setup(jsOptions["pathLocalDir"] as? String)

        self.remoteDir = NSURL(string: jsOptions["pathRemoteDir"] as! String)!
        self.manifest = Manifest(manifestRemote: jsOptions["pathManifest"] as! String, manifestLocal: self.fileSystem.pathRoot)

        self.release = Release()
        self.release.isNewVersionAvailable(jsOptions["pathRelease"] as! String, completion: handleIsNewVersionAvailable)

        self.pluginResultCB = pluginResultCB
        // TODO: instead casting options here, parse them as struct? for better error handling where you also could throw option xy not set
    }

    private func handleIsNewVersionAvailable(newRelease: Bool?, error: Int?) -> Void {
        if ((error) != nil) {
            self.sendSuccessCB(error!)
        } else {
            print("newRelease: ", newRelease!)
            if newRelease! {
                self.manifest.loadAndCompare(handleLoadAndCompare)
            } else {
                pluginResultCB(statusCode: 1)
            }
        }
    }

    private func handleLoadAndCompare(filesToDownload: NSArray, filesToDelete: NSArray, filesToUpload: NSArray) -> Void {
        print("filesToDownload", filesToDownload.count)
        print("filesToDelete", filesToDelete.count)
        print("filesToUpload", filesToUpload.count)

        // download
        if filesToDownload.count > 0 {
            Downloader.Instance().downloadMultiple(filesToDownload, remoteBaseUrl: self.remoteDir, completion: self.handleDownloadComplete)
        }

        // to be able to catch all errors, i can't do everything here
        // have to first download, in downloadHandler start delete, and start upload, in uploadHandler call finally pluginCallback

        // delete
        if filesToDelete.count > 0 {
            fileSystem.deleteFilesInRoot(filesToDelete)
        }

        // upload
        if filesToUpload.count > 0 {
            // TODO: uploader class -> first check if you can save to this location
        }

    }

    private func handleDownloadComplete(result: Int) -> Void {

        // save new settings
        self.manifest.saveNewManifest()
        self.release.setNewVersion()
        pluginResultCB(statusCode: 0)
    }

    private func sendErrorCB(error: Int) -> Void {
        print("error: ", error)
    }

    private func sendSuccessCB(status: Int) -> Void {
        print("status: ", status)
    }

}