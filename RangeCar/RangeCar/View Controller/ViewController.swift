//
//  ViewController.swift
//  RangeCar
//
//  Created by 양창엽 on 2018. 6. 3..
//  Copyright © 2018년 Yang-Chang-Yeop. All rights reserved.
//

import UIKit
import AVKit
import CoreML
import Vision
import CoreLocation

// MARK: - Enum
private enum WeatherState: Int {
    case SUN = 1
    case MIDDLE = 2
    case MCLOUD = 3
    case VCLOUD = 4
}

class ViewController: UIViewController {
    
    // MARK: - Outlet Variables
    @IBOutlet weak var previewLayer: UIView! {
        didSet {
            previewLayer.clipsToBounds = true
            previewLayer.layer.cornerRadius = 5
        }
    }
    @IBOutlet weak var detectionLabel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var informationView: UIView! {
        didSet {
            informationView.clipsToBounds = true
            informationView.layer.cornerRadius = 5
        }
    }
    @IBOutlet weak var detectionView: UIView! {
        didSet {
            detectionView.clipsToBounds = true
            detectionView.layer.cornerRadius = 5
        }
    }
    @IBOutlet weak var weatherImg: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dustLabel: UILabel!
    @IBOutlet weak var showIndicator: UIActivityIndicatorView!
    
    // MARK: - Variables
    private var bucket: (CarName: String, Check: Bool) = ("", true)
    private var currentCarData: (Location: CLLocation, Address: String) = (CLLocation(latitude: 0.0, longitude: 0.0), "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // CLLocation Manager Delegate
        MyLocation.myLocationInstance.locationManager.delegate = self
        
        let captureSession: AVCaptureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captrueDevice: AVCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captrueDevice) else {
            return
        }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let preview: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.layer.addSublayer(preview)
        preview.frame.size = previewLayer.bounds.size
        
        let dataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        captureSession.addOutput(dataOutput)
    }
    
    // MARK: - Method
    private func updateDustInformation() {
        
        ReceiveDustData.instance.group.enter()
        DispatchQueue.global(qos: .default).async(group: ReceiveDustData.instance.group, execute: {
            ReceiveDustData.instance.receiveDustData()
        })
        
        ReceiveDustData.instance.group.notify(queue: .main, execute: { [unowned self] in
            self.dustLabel.text = "미세먼지: \(ReceiveDustData.instance.result)㎍/㎥"
        })
    }
    private func updateWeatherInformation(nx: Int, ny: Int) {
        
        ReceiveWeatherData.weatherInstance.group.enter()
        DispatchQueue.global(qos: .userInteractive).async(group: ReceiveWeatherData.weatherInstance.group, execute: {
            ReceiveWeatherData.weatherInstance.receiveWeatherData(nx: nx, ny: ny)
        })
        
        ReceiveWeatherData.weatherInstance.group.notify(queue: .main, execute: { [unowned self] in
            let result = ReceiveWeatherData.weatherInstance.weatherResult
            self.weatherLabel.text = "온도: \(result.T3H)℃ | 습도: \(result.REH)% | 강수확률: \(result.POP)%"
            
            if let state: WeatherState = WeatherState(rawValue: ReceiveWeatherData.weatherInstance.weatherResult.SKY) {
                switch state {
                    case .SUN: self.weatherImg.image = #imageLiteral(resourceName: "sun")
                    case .MIDDLE: self.weatherImg.image = #imageLiteral(resourceName: "clouds_sun")
                    case .MCLOUD: self.weatherImg.image = #imageLiteral(resourceName: "cloud")
                    case .VCLOUD: self.weatherImg.image = #imageLiteral(resourceName: "vary_clouds")
                }
            }
            
            self.showIndicator.stopAnimating()
        })
    }
    private func updateLocationInformation(address: String) {
        
        DispatchQueue.main.async(execute: { [unowned self] in
            self.locationLabel.text = address
        })
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let resnetModel: VNCoreMLModel = try? VNCoreMLModel(for: CarRecognition().model) else { return }
        let request = VNCoreMLRequest(model: resnetModel, completionHandler: { [unowned self] (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            if let firstObservation = results.first {
                DispatchQueue.main.async {
                    
                    self.detectionLabel.text = firstObservation.identifier
                    
                    if firstObservation.confidence > 0.75 && self.bucket.Check {
                        self.bucket.Check = false
                        print("⌘ Car Model: \(firstObservation.identifier): \(firstObservation.confidence)")
                        
                        if !self.currentCarData.Address.isEmpty {
                            SendCarData.instance.sendCarData(link: "http://yeop9657.duckdns.org/Carinsert.php", latitude: self.currentCarData.Location.coordinate.latitude, longitude: self.currentCarData.Location.coordinate.longitude, name: firstObservation.identifier, address: self.currentCarData.Address)
                        }
                    }
                    
                    if self.bucket.CarName != firstObservation.identifier {
                        self.bucket.CarName = firstObservation.identifier
                        self.bucket.Check = true
                    }
                }
            }
        })
        
        DispatchQueue.global(qos: .userInteractive).async {
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        }
    }
}

// MARK: - CLLocationManagerDelegate Delegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocation = locations.first else {
            fatalError("Error, Not Operate Core Location.")
        }
        
        DispatchQueue.main.async(execute: { [unowned self] in

            // Update Weather Information
            let gridXY = MyLocation.myLocationInstance.convertGridXY(location: location)
            self.updateWeatherInformation(nx: gridXY.nx, ny: gridXY.ny)
            
            // Update Road Address Information
            self.currentCarData.Location = location
            self.currentCarData.Address = MyLocation.myLocationInstance.getCurrentAddress(location: location)
            self.updateLocationInformation(address: self.currentCarData.Address)
            
            // Update Dust Information
            self.updateDustInformation()
        })
    }
}
