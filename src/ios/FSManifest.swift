/*
 *
 *
 *
 */
class FSManifest {

    fileprivate let fsJson = FSJson()

    fileprivate var pathManifestRemote: String
    fileprivate var pathLocal: URL
    fileprivate var pathManifestLocal: URL
    fileprivate var pathManifestLocalTemp : URL
    fileprivate var parameter: Dictionary<String, String>?

    fileprivate var filesToDownload: [AnyObject] = []
    fileprivate var filesToDelete: [String] = []
    fileprivate var filesToUpload: [String] = []

    init(manifestRemote: String, pathLocal: URL, parameter: Dictionary<String, String>?) {
        self.pathLocal = pathLocal
        self.pathManifestRemote = manifestRemote
        self.pathManifestLocal = URL(fileURLWithPath: pathLocal.path + "/manifest.json")
        self.pathManifestLocalTemp = URL(fileURLWithPath: pathLocal.path + "/temp-manifest.json")
        self.parameter = parameter
    }

    internal func loadAndCompare(comparedCB: @escaping ([AnyObject], [String], [String], Int?) -> Void) {
        // after we have got the manifest, we finnaly can compare
        self.loadRemoteManifest() { (remoteManifest: [AnyObject]?, error: Int?) -> () in

            var localManifest = self.loadLocalManifest()
            if localManifest == nil {
                localManifest = [];
            }

            // don't even start comparing, just return empty arrs with an error
            if error != nil || remoteManifest == nil {
                comparedCB(self.filesToDownload, self.filesToDelete, self.filesToUpload, error)
            } else {
                print("Missing remote or ")
                self.compareManifest(remoteManifest: remoteManifest!, localManifest: localManifest!);
                comparedCB(self.filesToDownload, self.filesToDelete, self.filesToUpload, nil)
            }
        }

    }

    fileprivate func loadRemoteManifest(_ loadedRemoteManifestCB: @escaping ([AnyObject]?, Int?) -> Void) {
        fsJson.getJson(url: self.pathManifestRemote, parameter: self.parameter) { (data, response, error) -> () in
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
            try? data!.write(to: (self.pathManifestLocalTemp as NSURL).filePathURL!, options: [.atomic])
            loadedRemoteManifestCB(arr, nil)
        }
    }

    internal func saveNewManifest() -> Void {
        FSFileSystem.Instance().moveToRoot(from: self.pathManifestLocalTemp, relativeTo: "manifest.json")
    }

    fileprivate func loadLocalManifest() -> [AnyObject]? {
        let JSONData = try? Data(contentsOf: self.pathManifestLocal)

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

    fileprivate func findNewLocalFiles(localFiles: [String], localManifest: [AnyObject]?) -> [String] {

        guard localManifest != nil else {
            return localFiles
        }

        var newLocalFiles: [String] = []
        for localFile in localFiles {
            var found = false

            for oldFile in localManifest! {
                if oldFile["file"] as? String == localFile {
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

    fileprivate func findNewRemoteFiles(remoteManifest: [AnyObject], localManifest: [AnyObject]?) -> [AnyObject] {
        guard localManifest != nil else {
            return remoteManifest
        }

        var newRemoteFiles:[AnyObject] = []

        for newFile in remoteManifest {
            var found = false

            for oldFile in localManifest! {
                if oldFile["file"] as! String == newFile["file"] as! String {
                    found = true
                    break
                }
            }

            if !found {
                newRemoteFiles.append(newFile)
                print("[FileSync] file added on remote ", newFile)
            }
        }

        return newRemoteFiles
    }

    fileprivate func findChangedAndDeletedFiles (remoteManifest: [AnyObject], localManifest: [AnyObject]?) -> ([AnyObject], [String]) {
        let deletedFiles: [String] = []
        let changedFiles: [AnyObject] = []

        guard localManifest != nil else {
            return (changedFiles, deletedFiles)
        }

        // find files deleted or changed on remote
        for oldFile in localManifest!{
            var isDeleted = true

            for newFile in remoteManifest {
                if oldFile["file"] as! String == newFile["file"] as! String {
                    isDeleted = false
                    if oldFile["hash"] as! String != newFile["hash"] as! String {
                        self.filesToDownload.append(newFile)
                        print("[FileSync] file change on remote", newFile)
                    }
                    break
                }
            }

            if isDeleted {
                self.filesToDelete.append(oldFile["file"] as! String)
                print("[FileSync] file deleted on remote", oldFile)
            }
        }

        return (changedFiles, deletedFiles)
    }

    fileprivate func getLocalFiles() -> [String] {
        var localFiles: [String] = [];

        let enumerator:FileManager.DirectoryEnumerator = FileManager.default.enumerator(at: self.pathLocal, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey], options: .skipsHiddenFiles, errorHandler: nil)!
        while let element = enumerator.nextObject() as? URL {
            do {
                // holy shit -> check if is directory.. isn't there an easier way?
                var rsrc: AnyObject?
                try (element as NSURL).getResourceValue(&rsrc, forKey: URLResourceKey.isDirectoryKey)
                if let number = rsrc as? NSNumber {
                    if number == 0 {
                        var subpath = element.path.replacingOccurrences(of: self.pathLocal.path, with: "")
                        subpath = subpath.replacingOccurrences(of: "/private", with: "")
                        subpath = String(subpath.characters.dropFirst())
                        if (subpath != "manifest.json" && subpath != "temp-manifest.json") {
                            localFiles.append(subpath)
                        }
                    }
                }

            } catch {
                print("[FileSync] error getting resourceValues", error)
            }
        }
        return localFiles
    }

    fileprivate func compareManifest(remoteManifest: [AnyObject], localManifest: [AnyObject]) {

        let localFiles = getLocalFiles()
        let newLocalFiles = findNewLocalFiles(localFiles: localFiles, localManifest: localManifest)
        let newRemoteFiles = findNewRemoteFiles(remoteManifest: remoteManifest, localManifest: localManifest)
        let (changedFiles, deletedFiles) = findChangedAndDeletedFiles(remoteManifest: remoteManifest, localManifest: localManifest)

        // better return than passing to global
        self.filesToUpload.append(contentsOf: newLocalFiles)
        self.filesToDelete.append(contentsOf: deletedFiles)
        self.filesToDownload.append(contentsOf: newRemoteFiles)
        self.filesToDownload.append(contentsOf: changedFiles)
    }
}
