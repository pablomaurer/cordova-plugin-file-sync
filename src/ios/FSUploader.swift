/*
 * holy crap stuff -> http://stackoverflow.com/questions/26162616/upload-image-with-parameters-in-swift
 *
 */
import MobileCoreServices

class FSUploader: FSLoader {

    internal func startUploads(files: NSMutableArray, pathLocal: NSURL, pathUpload: NSURL, optionalParams: Dictionary<String, String>?) {

        for item in files {
            let item = item as! String
            let localFilePath = NSURL(fileURLWithPath: pathLocal.path! + item)

            var params = [
                "subpath" : item
            ]

            if optionalParams != nil {
                params.update(optionalParams!)
            }

            // create task
            let boundary = generateBoundaryString()
            let request = NSMutableURLRequest(URL: pathUpload)
            request.HTTPMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            let data = createBodyWithParameters(params, filePathKey: "file_content", pathFile: localFilePath, boundary: boundary)
            request.HTTPBody = data
            let task = self.session.uploadTaskWithStreamedRequest(request)
            task.taskDescription = "upload"
            let fsTask = FSTask(url: localFilePath, localPath: item, sessionTask: task)
            fsTask.start()
            self.startedTask.append(fsTask)
        }
    }

    // BODY
    private func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, pathFile: NSURL, boundary: String) -> NSData {
        let body = NSMutableData()

        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }

        // for each file
        let filename = pathFile.lastPathComponent
        guard let data = NSData(contentsOfURL: pathFile) else {
            print("[FileSync] could not get data of file", pathFile)
            return body
        }
        let mimetype = mimeTypeForPath(pathFile.path!)

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename!)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.appendData(data)
        body.appendString("\r\n")
        // end for each file

        body.appendString("--\(boundary)--\r\n")
        return body
    }


    // MIME
    private func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream";
    }

    // BOUNDRY
    private func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }

}

// UTF8 HELPER
extension NSMutableData {
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}

// DICT HELPER http://stackoverflow.com/questions/24051904/how-do-you-add-a-dictionary-of-items-into-another-dictionary
extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

/*
// CHECK HTTP STATUS -> example using without delegate -> Change all to this style?
let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: data) { data, response, error in
    guard error == nil && data != nil else {                                                          // check for fundamental networking error
        print("FSFS error=\(error)")
        return
    }

    if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
        print("FSFS statusCode should be 200, but is \(httpStatus.statusCode)")
        print("FSFS response = \(response)")
    }

    let responseString = String(data: data!, encoding: NSUTF8StringEncoding)
    print("FSFS responseString = \(responseString)")
}
task.resume()
*/
