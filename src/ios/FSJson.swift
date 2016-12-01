/*
 *
 *
 *
 */
class Web {

    private let sessionConfig: NSURLSessionConfiguration
    private let urlSession: NSURLSession

    init() {
        // prevent returning cache result, may not best for all requests
        // TODO test with IOS9 due: http://stackoverflow.com/questions/30324394/prevent-nsurlsession-from-caching-responses?noredirect=1&lq=1
        self.sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.sessionConfig.requestCachePolicy = .ReloadIgnoringLocalCacheData
        self.urlSession = NSURLSession(configuration: self.sessionConfig)
    }

    // json, callback, returns null
    internal func getJson(url: String, completion: (data: NSData?, response: NSURLResponse?, error: NSError?)->()) -> Void {
        self.urlSession.dataTaskWithURL(NSURL(string: url)!) { data, response, error in
            completion(data: data, response: response, error: error)
        }.resume()
    }

    // try to parse as array or dictionary
    internal func parseJSON(JSONData: NSData) -> Void {
        print("NOT ANYMORE IMPLENTED!")
        /*
        let jsonDictOrObj = self.parseJSONArr(JSONData)
        if jsonDictOrObj != nil {
            return jsonDictOrObj!
        } else {
            let jsonDictOrObj = self.parseJSONObj(JSONData)
            return jsonDictOrObj!
        }
         */
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

    // upload file


}