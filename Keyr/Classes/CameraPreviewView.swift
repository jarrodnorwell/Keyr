//
//  CameraPreviewView.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import AVFoundation
import UIKit

class CameraPreviewView : UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer? { layer as? AVCaptureVideoPreviewLayer }
}
