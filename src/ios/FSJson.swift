/*
 *
 *
 *
 */
class FSJson {

    private let sessionConfig: NSURLSessionConfiguration
    private let urlSession: NSURLSession

    init() {
        // prevent returning cache result, may not best for all requests
        self.sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.sessionConfig.requestCachePolicy = .ReloadIgnoringLocalCacheData
        self.urlSession = NSURLSession(configuration: self.sessionConfig)
    }

    // json, callback
    internal func getJson(url: String, parameter: Dictionary<String, String>?, completion: (data: NSData?, response: NSURLResponse?, error: NSError?)->()) -> Void {
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)

        if parameter != nil {
            request.encodeParameters(parameter!)
        }

        let task = self.urlSession.dataTaskWithRequest(request) { data, response, error in
            completion(data: data, response: response, error: error)
        }
        task.resume()
    }

    // try to parse json or return nil
    internal func parseJSONObj(JSONData: NSData) -> (NSDictionary?, error: ErrorType?) {
        var json: NSDictionary?
        var parseError: ErrorType?

        do {
            json = try NSJSONSerialization.JSONObjectWithData(JSONData, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
        } catch {
            parseError = error
        }
        return (json, parseError)
    }

    // try to parse json or return nil
    internal func parseJSONArr(JSONData: NSData) -> (NSArray?, error: ErrorType?){
        var json: NSArray?
        var parseError: ErrorType?

        do {
            json = try NSJSONSerialization.JSONObjectWithData(JSONData, options: .MutableContainers) as? NSArray
        } catch {
            parseError = error
        }

        return (json, parseError)
    }

    // toJSON
    // https://code.tutsplus.com/tutorials/working-with-json-in-swift--cms-25335

}

extension NSMutableURLRequest {

    private func percentEscapeString(string: String) -> String {
        let characterSet = NSCharacterSet(charactersInString: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._* ")

        return string
            .stringByAddingPercentEncodingWithAllowedCharacters(characterSet)!
            .stringByReplacingOccurrencesOfString(" ", withString: "+", options: [], range: nil)
    }

    func encodeParameters(parameters: [String : String]) {
        HTTPMethod = "POST"

        HTTPBody = parameters
            .map { "\(percentEscapeString($0))=\(percentEscapeString($1))" }
            .joinWithSeparator("&")
            .dataUsingEncoding(NSUTF8StringEncoding)
    }
}