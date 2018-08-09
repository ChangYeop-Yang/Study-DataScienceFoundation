//
//  ReceiveDustData.swift
//  RangeCar
//
//  Created by 양창엽 on 2018. 6. 4..
//  Copyright © 2018년 Yang-Chang-Yeop. All rights reserved.
//

import Alamofire

// MARK: Enum
private enum AdministrativeArea: String {
    case daegu = "대구광역시"
    case busan = "부산광역시"
    case seoul = "서울특별시"
    case incheon = "인천광역시"
    case gwangju = "광주광역시"
    case daejeon = "대전광역시"
    case ulsan = "울산광역시"
    case gyeonggi = "경기도"
    case gangwon = "강원도"
    case chungbuk = "충청북도"
    case chungnam = "충청남도"
    case jeonbuk = "전라북도"
    case jeonnam = "전라남도"
    case gyeongbuk = "경상북도"
    case gyeongnam = "경상남도"
    case jeju = "제주특별자치도"
    case sejong = "세종특별자치시"
}

class ReceiveDustData: NSObject {
    
    // MARK: - Variables
    internal var group: DispatchGroup = DispatchGroup()
    internal var result: String = ""
    private let serviceKey: String = "C2d%2FZz%2BaNt0m7s5ShL8GDXiwNqTXE3XETIIaRJDoSxvWxWm929sMakv3t6ZBz28U8cdE0N74NQkIAC1ppwaknw%3D%3D"
    internal static let instance: ReceiveDustData = ReceiveDustData()
    
    // MARK: - Method
    private override init() {}
    internal func receiveDustData(adminArea: String) {
        
        guard let link: URL = URL(string: "http://openapi.airkorea.or.kr/openapi/services/rest/ArpltnInforInqireSvc/getCtprvnMesureLIst?serviceKey=\(serviceKey)&numOfRows=10&pageSize=10&pageNo=1&startPage=1&itemCode=PM10&dataGubun=HOUR&searchCondition=MONTH(&_returnType=json") else {
            fatalError("Error, Not Vaild URL.")
        }

        Alamofire.request(link, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON(completionHandler: { [unowned self] response in
            
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
                guard let list = json["list"] as? [[String:Any]] else { break }
                
                if let item = list.first {
                    self.result = item["gyeongbuk"] as! String
                    
//                    if let roadType: AdministrativeArea = AdministrativeArea(rawValue: self.roadAddress) {
//                        switch roadType {
//                        case .daegu:    self.roadAddress = "daegu"
//                        case .busan:    self.roadAddress = "busan"
//                        case .seoul:    self.roadAddress = "seoul"
//                        case .incheon:  self.roadAddress = "incheon"
//                        case .gwangju:  self.roadAddress = "gwangju"
//                        case .daejeon:  self.roadAddress = "daejeon"
//                        case .ulsan:    self.roadAddress = "ulsan"
//                        case .gyeonggi: self.roadAddress = "gyeonggi"
//                        case .gangwon:  self.roadAddress = "gangwon"
//                        case .chungbuk: self.roadAddress = "chungbuk"
//                        case .chungnam: self.roadAddress = "chungnam"
//                        case .jeonbuk:  self.roadAddress = "jeonbuk"
//                        case .jeonnam:  self.roadAddress = "jeonnam"
//                        case .gyeongbuk:self.roadAddress = "gyeongbuk"
//                        case .gyeongnam:self.roadAddress = "gyeongnam"
//                        case .jeju:     self.roadAddress = "jeju"
//                        case .sejong:   self.roadAddress = "sejong"
//                        }
//                    }
                }
                
                self.group.leave()
            }
        })
    }
}
