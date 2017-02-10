struct FSOptions {
    let pathRelease: NSURL
    let pathManifest: NSURL
    let pathRemoteDir: NSURL
    let pathLocalDir: NSURL
    let pathUpload: NSURL

    let errorCode: Int

    // TODO
    /*
    init(jsOptions: Dictionary<String, String>?) {
        guard jsOptions != nil else {
            self.errorCode = 7
            return
        }
        self.pathManifest = jsOptions["pathManifest"]

        guard self.pathManifest = jsOptions["pathManifest"] else {

        }
    }
    */

}
