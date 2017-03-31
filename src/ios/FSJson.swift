/*
 *
 *
 *
 */
class FSJson {

    fileprivate let sessionConfig: URLSessionConfiguration
    fileprivate let urlSession: URLSession

    init() {
        // prevent returning cache result, may not best for all requests
        self.sessionConfig = URLSessionConfiguration.default
        self.sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.urlSession = URLSession(configuration: self.sessionConfig)
    }

    // json, callback
    internal func getJson(url: String, parameter: Dictionary<String, String>?, completion: @escaping (Data?, URLResponse?, Error?)->()) -> Void {


        //-----------------------------------
        let request = NSMutableURLRequest(url: URL(string: url)!)

        if parameter != nil {
            request.encodeParameters(parameter!)
        }
        let task = self.urlSession.dataTask(with: request as URLRequest) { (data, response, error) in
            completion(data, response, error)
        }

        //let task = self.urlSession.dataTask(with: request, { data, response, error in
        //    completion(data, response, error)
        //})
        task.resume()
    }

    // try to parse json or return nil
    internal func parseJSONObj(JSONData: Data) -> ([String: Any]?, error: Error?) {
        var json: [String: Any] = [:]
        var parseError: Error?

        do {
            json = try JSONSerialization.jsonObject(with: JSONData, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
        } catch {
            parseError = error
        }
        return (json, parseError)
    }

    // try to parse json or return nil
    internal func parseJSONArr(_ JSONData: Data) -> ([AnyObject]?, error: Error?){
        var json: [AnyObject]?
        var parseError: Error?

        do {
            json = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as? [AnyObject]
        } catch {
            parseError = error
        }

        return (json, parseError)
    }

    // toJSON
    // https://code.tutsplus.com/tutorials/working-with-json-in-swift--cms-25335

}

extension NSMutableURLRequest {

    fileprivate func percentEscapeString(_ string: String) -> String {
        let characterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._* ")

        return string
            .addingPercentEncoding(withAllowedCharacters: characterSet)!
            .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
    }

    func encodeParameters(_ parameters: [String : String]) {
        httpMethod = "POST"

        httpBody = parameters
            .map { "\(percentEscapeString($0))=\(percentEscapeString($1))" }
            .joined(separator: "&")
            .data(using: String.Encoding.utf8)
    }
}
