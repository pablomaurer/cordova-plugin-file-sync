/*
 *
 *
 *
 */
class Manifest {

    private let web = Web()

    private var pathManifestRemote: String
    private var pathManifestLocal: NSURL
    private var pathManifestLocalTemp : NSURL

    private var filesToDownload: NSMutableArray = []
    private var filesToDelete: NSMutableArray = []
    private var filesToUpload: NSMutableArray = []

    init(manifestRemote: String, manifestLocal: NSURL) {
        self.pathManifestRemote = manifestRemote
        self.pathManifestLocal = manifestLocal.URLByAppendingPathComponent("manifest.json")!
        self.pathManifestLocalTemp = manifestLocal.URLByAppendingPathComponent("temp-manifest.json")!
    }

    internal func loadAndCompare(comparedCB: (filesToDownload: NSMutableArray, filesToDelete: NSMutableArray, filesToUpload: NSMutableArray, error:Int?) -> Void) {
        // after we have got the manifest, we finnaly can compare
        self.loadRemoteManifest() { (remoteManifest: NSArray?, error: Int?) -> () in

            // don't even start comparing, just return empty arrs with an error
            if error != nil {
                comparedCB(filesToDownload: self.filesToDownload, filesToDelete: self.filesToDelete, filesToUpload: self.filesToUpload, error:error)
            } else {
                self.compareManifest(remoteManifest, localManifest: self.loadLocalManifest());
                comparedCB(filesToDownload: self.filesToDownload, filesToDelete: self.filesToDelete, filesToUpload: self.filesToUpload, error:nil)
            }
        }

    }

    private func loadRemoteManifest(loadedRemoteManifestCB: (NSArray?, Int?) -> Void) {
        web.getJson(self.pathManifestRemote) { (data, response, error) -> () in
            // error getting json
            guard error == nil else {
                loadedRemoteManifestCB(nil, -3)
                return
            }

            // parsing json
            let(arr, error) = self.web.parseJSONArr(data!)


            // error parsing json
            guard error == nil else {
                loadedRemoteManifestCB(nil, -4)
                return
            }

            // final success callback :)
            data!.writeToURL(self.pathManifestLocalTemp, atomically: true)
            loadedRemoteManifestCB(arr, nil)
        }
    }

    internal func saveNewManifest() -> Void {
        FileSystem.Instance().moveToRoot(self.pathManifestLocalTemp, relativeTo: "manifest.json")
    }

    private func loadLocalManifest() -> NSArray? {
        let JSONData = NSData(contentsOfURL: self.pathManifestLocal)

        // read of manifest returned nil, empty file or what?
        guard JSONData != nil else {
            return nil
        }

        let (JSONArr, error) = web.parseJSONArr(JSONData!)

        // error parsing json
        guard error == nil else {
            return nil
        }

        return JSONArr
    }

    // TODO RETURN TYPE
    private func compareManifest(remoteManifest: NSArray?, localManifest: NSArray?) -> Bool {
        // if no local manifest available, we never loaded something, so all are downloads
        guard localManifest != nil else {
            self.filesToDownload = remoteManifest as! NSMutableArray
            return true
        }

        // find files deleted or changed on remote
        for oldFile in localManifest! {
            var isDeleted = true

            for newFile in remoteManifest! {
                if oldFile["file"] as! String == newFile["file"] as! String {
                    isDeleted = false
                    if oldFile["hash"] as! String != newFile["hash"] as! String {
                        self.filesToDownload.addObject(newFile)
                        print("[FileSync] file change on remote", newFile)
                    }
                }
            }

            if isDeleted {
                self.filesToDelete.addObject(oldFile["file"] as! String)
                print("[FileSync] file deleted on remote", oldFile)
            }

        }

        // find new files on remote
        for newFile in remoteManifest! {
            var found = false

            for oldFile in localManifest! {
                if oldFile["file"] as! String == newFile["file"] as! String {
                    found = true
                    break
                }
            }

            if !found {
                self.filesToDownload.addObject(newFile)
                print("[FileSync] file added on remote ", newFile)
            }

        }

        // find local changes...

        return true
    }
}