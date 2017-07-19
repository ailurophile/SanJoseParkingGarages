//
//  Junar.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 5/4/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation

class JunarClient: NSObject{
    struct Constants{
        //MARK: URLs
        static let ApiScheme = "https"
        static let ApiHost = "api.data.sanjoseca.gov"
        static let SessionPath = "/api/v2/datastreams/PARKI-GARAG-DATA/data.ajson/"
        static let HTTPMethod = "GET"
        
    }
    //MARK: Parameter Keys
    struct ParameterKeys {
        static let APIKey = "auth_key"
        static let GarageKey = "result"
    }
    //MARK: Parameter Values
    struct ParameterValues {
        static let APIKey = "f3313e775ed0dbb3cc053ab1d1aafa07504d586c"
    }


    //MARK: Networking methods
    //Build URL
    func getURL()-> URL {
        var components = URLComponents()
        components.scheme = Constants.ApiScheme
        components.host = Constants.ApiHost
        components.path = Constants.SessionPath
        components.queryItems = [URLQueryItem(name: ParameterKeys.APIKey, value: ParameterValues.APIKey)]
        return components.url!
    }
    //Request parking space data from API
    func queryJunar( completionHandlerForQuery: @escaping ( _ results: Any?, _ error: NSError?) -> Void){
        let url = getURL()
        let request = URLRequest(url: url)
        let session = URLSession.shared
        var task = session.dataTask(with: request as URLRequest) { data, response, error in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForQuery(nil, NSError(domain: "makeRequest", code: 1, userInfo: userInfo))
            }
            if error != nil {
                sendError((error?.localizedDescription)!)
                return
            }
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else{
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            guard  statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned status code: \(HTTPURLResponse.localizedString(forStatusCode:statusCode))")
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
//            print(NSString(data: data, encoding: String.Encoding.utf8.rawValue)!)
            
            
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForQuery)
            
        }
        task.resume()
    }

    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> JunarClient {
        struct Singleton {
            static var sharedInstance = JunarClient()
        }
        return Singleton.sharedInstance
    }
}
