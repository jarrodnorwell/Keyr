//
//  CameraAccess.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import AVKit

actor CameraAccess {
    var authorised: Bool = false
    var status: AVAuthorizationStatus = .notDetermined
    
    func checkAuthorisationStatus() {
        status = AVCaptureDevice.authorizationStatus(for: .video)
        authorised = status == .authorized
    }
    
    func authorise() async -> Bool {
        authorised = await AVCaptureDevice.requestAccess(for: .video)
        return authorised
    }
}
