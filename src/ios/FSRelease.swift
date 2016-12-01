/*
 *
 *
 *
 */
class Release {

    internal var releaseLocal: String = ""
    internal var releaseRemote: String = ""
    internal let web = Web()

    private let defaults = NSUserDefaults.standardUserDefaults()

    // compare versions
    internal func compareVersion(remoteVersion: String) -> Bool {
        if let localVersion = defaults.stringForKey("localVersion") {
            return localVersion != remoteVersion
        }
        print("no local version, so the new version is allright")
        return true
    }

    // set new version
    internal func setNewVersion() -> Void {
        defaults.setValue(self.releaseRemote, forKey: "localVersion")
        defaults.synchronize()
    }

    // check version available
    internal func isNewVersionAvailable(url: String, completion: (available: Bool?, error: Int?) -> Void) {

        web.getJson(url) { (data, response, error) -> () in

            // error getting json
            guard error == nil else {
                completion(available: nil, error: -1)
                return
            }

            // parsing json
            let(result, error) = self.web.parseJSONObj(data!)

            // error parsing json
            guard error == nil else {
                completion(available: nil, error: -2)
                return
            }

            self.releaseRemote = result!["release"] as! String
            let isNew = self.compareVersion(self.releaseRemote)
            completion(available: isNew, error: nil)
        }
    }
}