/*
 *
 *
 *
 */
class FileSystem {

    var pathRoot: NSURL = NSURL(string: "http://you-did-not-call-setup().com")!
    var pathManifest: NSURL = NSURL(string: "http://you-did-not-call-setup().com")!
    let fileManager: NSFileManager = NSFileManager.defaultManager()

    // singleton
    private init() {}
    internal static func Instance() -> FileSystem {
        return instance
    }
    static let instance : FileSystem = FileSystem()

    internal func setup(pathRoot: String?) -> Void {
        if (pathRoot == nil) {
            self.pathRoot = self.getDefaultRootPath()
        } else {
            self.pathRoot = NSURL(string: pathRoot!)!
        }
        self.pathManifest = self.pathRoot.URLByAppendingPathComponent("manifest.json")!
    }

    // path root
    private func getDefaultRootPath() -> NSURL {
        var documentsUrl = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)[0])
        documentsUrl = documentsUrl.URLByAppendingPathComponent("cordova-plugin-file-sync", isDirectory: true)!
        try! self.fileManager.createDirectoryAtPath(String(documentsUrl.path!), withIntermediateDirectories: true, attributes: nil)

        return documentsUrl
    }

    // Get the directory contents urls (including subfolders urls)
    internal func listFiles(path: NSURL) -> Void {
        do {
            let directoryContents = try self.fileManager.contentsOfDirectoryAtURL(path, includingPropertiesForKeys: nil, options: [])
            print(directoryContents)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    internal func moveToRoot(from: NSURL, relativeTo: String) -> Void {
        let to = self.pathRoot.URLByAppendingPathComponent(relativeTo, isDirectory: false)!
        moveFile(currentPath: from, targetPath: to)
    }

    internal func moveFile(currentPath currentPath: NSURL, targetPath: NSURL) {
        let parentPath = targetPath.URLByDeletingLastPathComponent!

        self.deleteFile(targetPath.path!)

        var isDirectory: ObjCBool = false
        if !fileManager.fileExistsAtPath(String(parentPath.path!), isDirectory:&isDirectory) {
            do {
                print("making dir at: ", String(parentPath.path!))
                try fileManager.createDirectoryAtPath(String(parentPath.path!), withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print("Error creating dirs: ", error.localizedDescription)
            }

            self.mv(currentPath, to: targetPath)
        }
        else if isDirectory {
            self.mv(currentPath, to: targetPath)
        }
        else {
            // Parent path exists and is a file, error handling
        }
    }

    private func mv(from: NSURL, to: NSURL) -> Bool {
        do {
            try fileManager.moveItemAtPath(from.path!, toPath: to.path!)
            return true
        }
        catch let error as NSError {
            print("Ooops! Something went wrong moving file: \(error)")
            return false
        }
    }

    internal func deleteFile(path: String) -> Bool {
        if(fileManager.fileExistsAtPath(path)) {
            do {
                try fileManager.removeItemAtPath(path)
                return true
            }
            catch {
                print("Ooops! Something went wrong: \(error)")
                return false
            }
        }
        return true
    }

    internal func deleteFilesInRoot(files: NSArray) -> Bool {
        for file in files {
            let deleteUrl = self.pathRoot.URLByAppendingPathComponent(file as! String)!
            self.deleteFile(deleteUrl.path!)
        }
        // TODO better error handling
        return true
    }

    internal func saveArrayToRoot(array: NSArray, to: NSURL) -> Bool {
        let array = [ "hello", "goodbye" ]
        let joined = array.joinWithSeparator("\n")
        do {
            try joined.writeToFile(to.path!, atomically: true, encoding: NSUTF8StringEncoding)
            return true
        } catch {
            // handle error
            return false
        }
    }

}