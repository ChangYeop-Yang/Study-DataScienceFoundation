//
//  SendCarData.swift
//  RangeCar
//
//  Created by 양창엽 on 2018. 6. 4..
//  Copyright © 2018년 Yang-Chang-Yeop. All rights reserved.
//

import Alamofire

public class SendCarData: NSObject {
    
    // MARK: - Variables
    internal static let instance: SendCarData = SendCarData()
    
    // MARK: - Method
    private override init() {}
    internal func sendCarData(link: String, latitude: Double, longitude: Double, name: String, address: String) {
        
        DispatchQueue.global(qos: .default).async(execute: {
            
            let parameters: Parameters = ["LAT": latitude, "LONG": longitude, "CARNAME": name, "ADDRESS": address]
            
            Alamofire.request(link, method: .get, parameters: parameters, encoding: URLEncoding.default).responseString(completionHandler: { response in
                print(response)
            })
        })
    }
}
