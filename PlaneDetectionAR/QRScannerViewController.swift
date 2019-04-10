//
//  QRScannerViewController.swift
//  PlaneDetectionAR
//
//  Created by Ice on 2/4/2562 BE.
//  Copyright © 2562 Ice. All rights reserved.
//

import UIKit
import AVFoundation

protocol QRScannerPermissionViewControllerDelegate: class {
    func dismissPermissionView(_ qrScannerPermissionViewController: QRScannerViewController)
    func cameraPermissionGranted(_ qrScannerPermissionViewController: QRScannerViewController)
}

class QRScannerViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var codeLabel: UILabel!
    
    weak var delegate: QRScannerPermissionViewControllerDelegate?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureSession: AVCaptureSession?
    private var detectedString: String?
    
    private enum ScannerState {
        case startscanning
        case stopscanning
        case codeDetected(mapName: String?)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        performAllowAction()
        captureSession = AVCaptureSession()
        setupCameraView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        transition(to: .startscanning)
    }
    
    private func performAllowAction() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            // If the user has not yet been asked for camera access, ask for permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let strongSelf = self else { return }
                if granted {
                    DispatchQueue.main.async {
                        strongSelf.delegate?.cameraPermissionGranted(strongSelf)
                    }
                }
            }
            
        } else if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
            // If the user has previously denied access, go to app's settings
            if let url = URL(string:UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(url) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
        }
    }
    
    func setupCameraView() {
        
        let captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            codeLabel.text = "Fail Scanning"
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
            
        } else {
            codeLabel.text = "Fail Scanning"
            return
        }
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.frame = cameraView.layer.bounds
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        if let videoPreviewLayer = videoPreviewLayer {
            cameraView.layer.addSublayer(videoPreviewLayer)
        }
        self.captureSession = captureSession
    }
    
    func showMapAlert(controller: UIViewController, mapName: String) {
        let alert = UIAlertController(title: "Map Details", message: "Map Name : \(mapName)", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { _ in
            self.transition(to: .startscanning)
        }))
        alert.addAction(UIAlertAction(title: "Go", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
            weak var arVC = self.storyboard?.instantiateViewController(withIdentifier: "arVC") as? ViewController
            arVC?.mapName = mapName
            self.navigationController?.pushViewController( arVC!, animated: true)
        }))
        controller.present(alert, animated: true, completion: nil)
    }

    private func transition(to state: ScannerState) {
        switch state {
        case .startscanning:
            captureSession?.startRunning()
        case .stopscanning:
            captureSession?.stopRunning()
        case .codeDetected(let mapName):
            print("Code Detected !")
            showMapAlert(controller: self, mapName: mapName!)
        }
    }
    
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        transition(to: .stopscanning)
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            detectedString = stringValue
            codeLabel.text = detectedString
            transition(to: .codeDetected(mapName: detectedString!))
            
        }
    }
}
