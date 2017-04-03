/*
 *
 *
 *
 */
class FSFileSystem {

    var pathRoot: URL = URL(string: "http://you-did-not-call-setup().com")!
    var pathManifest: URL = URL(string: "http://you-did-not-call-setup().com")!
    let fileManager = FileManager.default

    // singleton
    fileprivate init() {}
    static let instance: FSFileSystem = FSFileSystem()
    static func Instance() -> FSFileSystem {
        return instance
    }

    internal func setup(pathRoot: String?) -> Void {
        if (pathRoot == nil) {
            self.pathRoot = self.getDefaultRootPath()
        } else {
            self.pathRoot = URL(string: pathRoot!)!
        }
        self.pathManifest = self.pathRoot.appendingPathComponent("manifest.json")
    }

    // path root
    fileprivate func getDefaultRootPath() -> URL {
        var documentsUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0])
        documentsUrl = documentsUrl.appendingPathComponent("cordova-plugin-file-sync", isDirectory: true)
        try! self.fileManager.createDirectory(atPath: String(documentsUrl.path), withIntermediateDirectories: true, attributes: nil)

        return documentsUrl
    }

    // Get the directory contents urls (including subfolders urls)
    internal func listFiles(path: URL) -> Void {
        do {
            let directoryContents = try self.fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [])
        } catch let error as NSError {
            print("[FileSync]", error.localizedDescription)
        }
    }

    internal func moveToRoot(from: URL, relativeTo: String) -> Void {
        let to = self.pathRoot.appendingPathComponent(relativeTo, isDirectory: false)
        moveFile(currentPath: from, targetPath: to)
    }

    internal func moveFile(currentPath: URL, targetPath: URL) {
        let parentPath = targetPath.deletingLastPathComponent()

        self.deleteFile(path: targetPath.path)

        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: String(parentPath.path), isDirectory:&isDirectory) {
            do {
                print("[FileSync] making dir at: ", parentPath.path)
                try fileManager.createDirectory(atPath: parentPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("[FileSync] Error creating dirs: ", error.localizedDescription)
            }

            self.mv(from: currentPath, to: targetPath)
        }
        else if isDirectory.boolValue {
            self.mv(from: currentPath, to: targetPath)
        }
        else {
            // Parent path exists and is a file, error handling
        }
    }

    fileprivate func mv(from: URL, to: URL) -> Bool {
        do {
            try fileManager.moveItem(atPath: from.path, toPath: to.path)
            return true
        }
        catch let error {
            print("[FileSync] Ooops! Something went wrong moving file: \(error)")
            return false
        }
    }

    internal func deleteFile(path: String) -> Bool {
        if(fileManager.fileExists(atPath: path)) {
            do {
                try fileManager.removeItem(atPath: path)
                return true
            }
            catch {
                print("[FileSync] Ooops! Something went wrong: \(error)")
                return false
            }
        }
        return true
    }

    internal func deleteFilesInRoot(files: [String]) -> Bool {
        for file in files {
            let deleteUrl = self.pathRoot.appendingPathComponent(file)
            self.deleteFile(path: deleteUrl.path)
        }
        // TODO better error handling
        return true
    }

    internal func saveArrayToRoot(array: NSArray, to: NSURL) -> Bool {
        let array = [ "hello", "goodbye" ]
        let joined = array.joined(separator: "\n")
        do {
            try joined.write(toFile: to.path!, atomically: true, encoding: String.Encoding.utf8)
            return true
        } catch {
            // handle error
            return false
        }
    }

}