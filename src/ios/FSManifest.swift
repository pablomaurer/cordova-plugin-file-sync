/*
 *
 *
 *
 */
class FSManifest {

    private let fsJson = FSJson()

    private var pathManifestRemote: String
    private var pathLocal: NSURL
    private var pathManifestLocal: NSURL
    private var pathManifestLocalTemp : NSURL
    private var parameter: Dictionary<String, String>?

    private var filesToDownload: NSMutableArray = []
    private var filesToDelete: NSMutableArray = []
    private var filesToUpload: NSMutableArray = []

    init(manifestRemote: String, pathLocal: NSURL, parameter: Dictionary<String, String>?) {
        self.pathLocal = pathLocal
        self.pathManifestRemote = manifestRemote
        self.pathManifestLocal = pathLocal.URLByAppendingPathComponent("manifest.json")!
        self.pathManifestLocalTemp = NSURL(fileURLWithPath: pathLocal.path! + "temp-manifest.json")
        self.parameter = parameter
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
        fsJson.getJson(self.pathManifestRemote, parameter: self.parameter) { (data, response, error) -> () in
            // error getting json
            guard error == nil else {
                loadedRemoteManifestCB(nil, -3)
                return
            }

            // parsing json
            let(arr, error) = self.fsJson.parseJSONArr(data!)


            // error parsing json
            guard error == nil else {
                loadedRemoteManifestCB(nil, -4)
                return
            }

            // final success callback :)
            data!.writeToURL(self.pathManifestLocalTemp.filePathURL!, atomically: true)
            loadedRemoteManifestCB(arr, nil)
        }
    }

    internal func saveNewManifest() -> Void {
        FSFileSystem.Instance().moveToRoot(self.pathManifestLocalTemp, relativeTo: "manifest.json")
    }

    private func loadLocalManifest() -> NSArray? {
        let JSONData = NSData(contentsOfURL: self.pathManifestLocal)

        // read of manifest returned nil, empty file or what?
        guard JSONData != nil else {
            return nil
        }

        let (JSONArr, error) = fsJson.parseJSONArr(JSONData!)

        // error parsing json
        guard error == nil else {
            return nil
        }

        return JSONArr
    }

    private func findNewLocalFiles(localFiles: [String], localManifest: NSArray?) -> [String] {
        guard localManifest != nil else {
            return localFiles
        }

        var newLocalFiles: [String] = []
        for localFile in localFiles {
            var found = false

            for oldFile in localManifest! {
                if oldFile["file"] as! String == localFile {
                    found = true
                    break
                }
            }

            if !found {
                newLocalFiles.append(localFile)
                print("[FileSync] found new upload ", localFile)
            }
        }

        return newLocalFiles
    }

    private func findNewRemoteFiles(remoteManifest: NSArray, localManifest: NSArray?) -> NSMutableArray {
        guard localManifest != nil else {
            return remoteManifest as! NSMutableArray
        }

        let newRemoteFiles: NSMutableArray = []

        for newFile in remoteManifest {
            var found = false

            for oldFile in localManifest! {
                if oldFile["file"] as! String == newFile["file"] as! String {
                    found = true
                    break
                }
            }

            if !found {
                newRemoteFiles.addObject(newFile)
                print("[FileSync] file added on remote ", newFile)
            }
        }

        return newRemoteFiles
    }

    private func findChangedAndDeletedFiles (remoteManifest: NSArray, localManifest: NSArray?) -> (NSMutableArray, NSMutableArray) {
        let deletedFiles: NSMutableArray = []
        let changedFiles: NSMutableArray = []

        guard localManifest != nil else {
            return (changedFiles, deletedFiles)
        }

        // find files deleted or changed on remote
        for oldFile in localManifest! {
            var isDeleted = true

            for newFile in remoteManifest {
                if oldFile["file"] as! String == newFile["file"] as! String {
                    isDeleted = false
                    if oldFile["hash"] as! String != newFile["hash"] as! String {
                        self.filesToDownload.addObject(newFile)
                        print("[FileSync] file change on remote", newFile)
                    }
                    break
                }
            }

            if isDeleted {
                self.filesToDelete.addObject(oldFile["file"] as! String)
                print("[FileSync] file deleted on remote", oldFile)
            }
        }

        return (changedFiles, deletedFiles)
    }

    private func getLocalFiles() -> [String] {
        var localFiles: [String] = [];

        // sample file for uploading
        let content = "text file content"
        _ = try? content.writeToFile(self.pathLocal.path! + "/test.txt", atomically: true, encoding: NSUTF8StringEncoding)
        print("sample file saved under", self.pathLocal.path! + "/test.txt")

        let enumerator:NSDirectoryEnumerator = NSFileManager.defaultManager().enumeratorAtURL(self.pathLocal, includingPropertiesForKeys: [NSURLIsDirectoryKey], options: .SkipsHiddenFiles, errorHandler: nil)!
        while let element = enumerator.nextObject() as? NSURL {
            do {
                // holy shit -> check if is directory.. isn't there an easier way?
                var rsrc: AnyObject?
                try element.getResourceValue(&rsrc, forKey: NSURLIsDirectoryKey)
                if let number = rsrc as? NSNumber {
                    if number == 0 {
                        var subpath = element.path?.stringByReplacingOccurrencesOfString(self.pathLocal.path!, withString: "")
                        subpath = subpath!.stringByReplacingOccurrencesOfString("/private", withString: "")
                        print("[FileSync] subpathsubpathsubpath", subpath)
                        localFiles.append(subpath!)
                    }
                }

            } catch {
                print("[FileSync] error getting resourceValues", error)
            }
        }
        return localFiles
    }

    private func compareManifest(remoteManifest: NSArray?, localManifest: NSArray?) {
        // perf
        guard remoteManifest != localManifest else {
            print("remote and local manifest are identical, skip to only find uploads")
            let localFiles = getLocalFiles()
            let newLocalFiles = findNewLocalFiles(localFiles, localManifest: localManifest)
            self.filesToUpload.addObjectsFromArray(newLocalFiles as [AnyObject])
            return
        }

        let localFiles = getLocalFiles()
        let newLocalFiles = findNewLocalFiles(localFiles, localManifest: localManifest)
        let newRemoteFiles = findNewRemoteFiles(remoteManifest!, localManifest: localManifest)
        let (changedFiles, deletedFiles) = findChangedAndDeletedFiles(remoteManifest!, localManifest: localManifest)

        // better return than passing to global
        self.filesToUpload.addObjectsFromArray(newLocalFiles as [AnyObject])
        self.filesToDelete.addObjectsFromArray(deletedFiles as [AnyObject])
        self.filesToDownload.addObjectsFromArray(newRemoteFiles as [AnyObject])
        self.filesToDownload.addObjectsFromArray(changedFiles as [AnyObject])
    }
}
