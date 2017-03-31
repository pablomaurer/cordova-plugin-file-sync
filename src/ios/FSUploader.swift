/*
 * holy crap stuff -> http://stackoverflow.com/questions/26162616/upload-image-with-parameters-in-swift
 *
 */
import MobileCoreServices

class FSUploader: FSLoader {

    internal func startUploads(files: [String], pathLocal: URL, pathUpload: URL, optionalParams: Dictionary<String, String>?) {

        for item in files {
            let item = item
            let localFilePath = URL(fileURLWithPath: pathLocal.path + "/" + item)

            var params = [
                "subpath" : item
            ]

            if optionalParams != nil {
                params.update(optionalParams!)
            }

            // create task
            let boundary = generateBoundaryString()
            let request = NSMutableURLRequest(url: pathUpload)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            let data = createBodyWithParameters(params, filePathKey: "file_content", pathFile: localFilePath, boundary: boundary)
            request.httpBody = data
            let task = self.session.uploadTask(withStreamedRequest: request as URLRequest)
            task.taskDescription = "upload"
            let fsTask = FSTask(url: localFilePath, localPath: item, sessionTask: task)
            fsTask.start()
            self.startedTask.append(fsTask)
        }
    }

    // BODY
    fileprivate func createBodyWithParameters(_ parameters: [String: String]?, filePathKey: String?, pathFile: URL, boundary: String) -> Data {
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
        guard let data = try? Data(contentsOf: pathFile) else {
            print("[FileSync] could not get data of file", pathFile)
            return body as Data
        }
        let mimetype = mimeTypeForPath(pathFile.path)

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        // end for each file

        body.appendString("--\(boundary)--\r\n")
        return body as Data
    }


    // MIME
    fileprivate func mimeTypeForPath(_ path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream";
    }

    // BOUNDRY
    fileprivate func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }

}

// UTF8 HELPER
extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}

// DICT HELPER http://stackoverflow.com/questions/24051904/how-do-you-add-a-dictionary-of-items-into-another-dictionary
extension Dictionary {
    mutating func update(_ other:Dictionary) {
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
