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
        static let ApiScheme = "http"
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
    //Coordinates of entrances to known garages
    static let KnownGarages = [
        "Convention Center Garage": [[Keys.Latitude: 37.3296, Keys.Longitude: -121.8870],
                                     [Keys.Latitude: 37.328196, Keys.Longitude: -121.890135]],
        "Fourth Street Garage": [[Keys.Latitude: 37.33667, Keys.Longitude: -121.886645],
                                 [Keys.Latitude: 37.3361, Keys.Longitude: -121.8856]],
        "Second San Carlos Garage": [[Keys.Latitude: 37.3325, Keys.Longitude: -121.8862],
                                     [Keys.Latitude: 37.3329, Keys.Longitude: -121.8854]],
        "Third Street Garage": [[Keys.Latitude: 37.338072, Keys.Longitude: -121.889262],
                                [Keys.Latitude: 37.3374, Keys.Longitude: -121.890]],
        "City Hall Garage": [[Keys.Latitude: 37.3379, Keys.Longitude: -121.8848]],
        "Market San Pedro Square Garage": [[Keys.Latitude: 37.33595, Keys.Longitude: -121.8928 ],
                                           [Keys.Latitude: 37.3359, Keys.Longitude: -121.8934]]
        
        ] as [String : [[String:Double]]]

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
