//
//  QRScannerController.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import AVKit
import Foundation
import UIKit

class QRScannerController : UIViewController {
    var session: AVCaptureSession = .init()
    var device: AVCaptureDevice? = .systemPreferredCamera
    var input: AVCaptureDeviceInput? = nil
    var output: AVCaptureMetadataOutput? = nil
    
    var sessionQueue: DispatchQueue = .init(label: "com.antique.Keyr.session")
    
    var codeFoundHandler: ((String) -> Void)? = nil
    
    override func loadView() {
        view = CameraPreviewView()
        if let view = view as? CameraPreviewView, let videoPreviewLayer = view.videoPreviewLayer {
            videoPreviewLayer.session = session
            videoPreviewLayer.videoGravity = .resizeAspectFill
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        guard let device else {
            return
        }
        
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            do {
                try self.setupCaptureSessionInput(with: device)
            } catch {
                print(error.localizedDescription)
            }
            
            self.setupCaptureSessionOutput()

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
    
    func setupCaptureSessionInput(with device: AVCaptureDevice) throws {
        input = try .init(device: device)
        guard let input, session.canAddInput(input) else {
            return
        }
        
        session.addInput(input)
    }
    
    func setupCaptureSessionOutput() {
        output = .init()
        guard let output else {
            return
        }
        
        guard session.canAddOutput(output) else {
            return
        }
        
        session.addOutput(output)
        
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
    }
}

extension QRScannerController : AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let codeFoundHandler, let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let string: String = metadata.stringValue else {
            return
        }
        
        print(string)
        
        sessionQueue.async {
            self.session.stopRunning()
            DispatchQueue.main.async {
                codeFoundHandler(string)
            }
        }
    }
}
