/*
 *
 *
 *
 */
class FSRelease {

    internal var releaseLocal: String = ""
    internal var releaseRemote: String = ""
    internal let fsJson = FSJson()

    fileprivate let defaults = UserDefaults.standard

    // compare versions
    internal func compareVersion(_ remoteVersion: String) -> Bool {
        if let localVersion = defaults.string(forKey: "localVersion") {
            return localVersion != remoteVersion
        }
        print("[FileSync] no local version, so the new version is allright")
        return true
    }

    // set new version
    internal func setNewVersion() -> Void {
        defaults.setValue(self.releaseRemote, forKey: "localVersion")
        defaults.synchronize()
    }

    // check version available
    internal func isNewVersionAvailable(_ url: String, completion: @escaping (Bool?, Int?) -> Void) {
        fsJson.getJson(url: url, parameter: nil) { (data, response, error) -> () in

            // error getting json
            guard error == nil else {
                completion(nil, -1)
                return
            }

            // parsing json
            let(result, error) = self.fsJson.parseJSONObj(JSONData: data!)

            // error parsing json
            guard error == nil else {
                completion(nil, -2)
                return
            }

            self.releaseRemote = result!["release"] as! String
            let isNew = self.compareVersion(self.releaseRemote)
            completion(isNew, nil)
        }
    }
}
