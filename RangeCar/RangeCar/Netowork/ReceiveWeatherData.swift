//
//  ReceiveWeatherData.swift
//  LazyHUE
//
//  Created by 양창엽 on 2018. 6. 3..
//  Copyright © 2018년 Yang-Chang-Yeop. All rights reserved.
//

import Alamofire

public class ReceiveWeatherData: NSObject {
    
    // MARK: Variables
    private let currentDate: Date = Date()
    internal static let weatherInstance: ReceiveWeatherData = ReceiveWeatherData()
    internal var group: DispatchGroup = DispatchGroup()
    internal var weatherResult: (T3H: Int, POP: Int, REH: Int, SKY: Int) = (0, 0, 0, 0)
    private let serviceKey: String = "C2d%2FZz%2BaNt0m7s5ShL8GDXiwNqTXE3XETIIaRJDoSxvWxWm929sMakv3t6ZBz28U8cdE0N74NQkIAC1ppwaknw%3D%3D"
    
    // MARK: Method
    private override init() {}
    private func splitDate(type: Bool) -> String {
        
        let dateformatter: DateFormatter = DateFormatter()
        dateformatter.dateFormat = (type ? "yyyyMMdd" : "hhmm")
        
        return dateformatter.string(from: currentDate)
    }
    internal func receiveWeatherData(nx: Int, ny: Int) {
        
        guard let url: URL = URL(string: "http://newsky2.kma.go.kr/service/SecndSrtpdFrcstInfoService2/ForecastSpaceData?serviceKey=\(serviceKey)&base_date=\(splitDate(type: true))&base_time=\(splitDate(type: false))&nx=\(nx)&ny=\(ny)&numOfRows=10&pageSize=10&pageNo=1&startPage=1&_type=json") else {
            fatalError("Error, Unvild Korea Meteorological Administration URL.")
        }
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON(completionHandler: {
            [unowned self] response in
            
            guard response.result.isSuccess else {
                self.group.leave()
                fatalError("Error, Not Receive Data From Korea Meteorological Administration Server.")
            }
            
            switch (response.response?.statusCode) {
                case .none:
                    self.group.leave()
                    print("Error, Not Receive Data From Korea Meteorological Administration Server.")
                case .some(_):
                    guard let result = response.result.value, let json = result as? NSDictionary else { break }
                    guard let head = json["response"] as? [String:Any], let body = head["body"] as? [String:Any] else { break }
                    guard let item = body["items"] as? [String:Any], let collection = item["item"] as? [[String:Any]] else { break }
                    
                    for item in collection {
                        let category = item["category"] as? String
                        switch category {
                            case "REH": self.weatherResult.REH = item["fcstValue"] as! Int
                            case "T3H": self.weatherResult.T3H = item["fcstValue"] as! Int
                            case "POP": self.weatherResult.POP = item["fcstValue"] as! Int
                            case "SKY": self.weatherResult.SKY = item["fcstValue"] as! Int
                            default: break
                        }
                    }
                self.group.leave()
            }
        })
    }
}
