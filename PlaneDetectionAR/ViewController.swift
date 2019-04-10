//
//  ViewController.swift
//  PlaneDetectionAR
//
//  Created by Ice on 29/3/2562 BE.
//  Copyright © 2562 Ice. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Firebase

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var switchDebug: UISwitch!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var numberOfObjects: UILabel!
    
    @IBOutlet weak var xPositionLabel: UILabel!
    @IBOutlet weak var yPositionLabel: UILabel!
    @IBOutlet weak var zPositionLabel: UILabel!
    
    private let plane: SCNNode? = nil
    var objLocation = [String : [String : String]]()
    var dataBaseRefer: DatabaseReference!
    var mapName: String = "Unknown"
    var numberTouch: Int = 0
    var allLocationArray = [Any]()
    var allLocationArray2 = [Any]()
    var configuration = ARWorldTrackingConfiguration()
    var QRlocationX: Double = 0.00
    var QRlocationY: Double = 0.00
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        // Create a new scene
        let scene = SCNScene()
        // Set the scene to the view
        sceneView.scene = scene
        switchDebug.isOn = false
        print("Map Name : \(mapName)")
        //setQRLocation()
        dataBaseRefer = Database.database().reference()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        //let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
        configuration.worldAlignment = .gravityAndHeading
        
        sceneView.delegate = self
        // Run the view's session
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
            camera.maximumExposure = 3
        }
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let location = touch?.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(location!, types: .featurePoint)
        
        if let hitTestResult = hitResults.first {
            let transform = hitTestResult.worldTransform
            let position = SCNVector3(x: transform.columns.3.x, y: transform.columns.3.y, z:transform.columns.3.z)
            
            let pyramid: SCNGeometry
            pyramid = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
            pyramid.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.9)
            
            //Save to Database Part
            numberTouch += 1
            numberOfObjects.text = "Number Of Objects : \(numberTouch)"
            
            let locationJSON: [String : Any] = [
                "x" : transform.columns.3.x,
                "y" : transform.columns.3.y,
                "z" : transform.columns.3.z ]
            
            let alllLocation: [String : Any] = ["\(numberTouch)" : locationJSON]
            
            allLocationArray2.append(locationJSON)
            allLocationArray.append(alllLocation)
            
            setPositionTextLabel(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
            
            let geometryNode = SCNNode(geometry: pyramid)
            geometryNode.position = position
            print("Object's Position : \(position)")
            geometryNode.scale = SCNVector3(x:0.1, y:0.1, z:0.1)
            
            sceneView.scene.rootNode.addChildNode(geometryNode)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    @IBAction func switchOnOff(_ sender: Any) {
        if switchDebug.isOn {
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
                                      ARSCNDebugOptions.showWorldOrigin]
            debugLabel.text = "Switch to Off Debug"
            sceneView.autoenablesDefaultLighting = true
            sceneView.showsStatistics = true
            print("on Debug")
        } else {
            sceneView.debugOptions = []
            debugLabel.text = "Switch to On Debug"
            sceneView.autoenablesDefaultLighting = false
            sceneView.showsStatistics = false
            print("off Debug")
        }
    }
    
    @IBAction func saveMap(_ sender: UIButton) {
        print("\(numberTouch)")
        showAlertWithTextField(controller: self, locationArray: allLocationArray2)
    }
    
    @IBAction func resetMap(_ sender: Any) {
        
        configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
        configuration.worldAlignment = .gravityAndHeading
        
        
        sceneView.session.pause()
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
                                  ARSCNDebugOptions.showWorldOrigin]
        
        numberTouch = 0
        numberOfObjects.text = "Number Of Objects : \(numberTouch)"
        setPositionTextLabel(x: 0.000, y: 0.000, z: 0.000)
        print("Reset Map")
        
    }
    
    @IBAction func loadMap(_ sender: UIButton) {
        print("Load Map")
        getData()
    }
    
    func showAlertWithTextField(controller: UIViewController, locationArray: Any) {
        let alertController = UIAlertController(title: "Set Map Name", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Save", style: .default) { (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                // operations
                print("Text ==>" + text)
                
                if text != "" {
                    self.dataBaseRefer.child("Object_Location").child("\(text)").setValue(self.allLocationArray2)
                }else {
                    print("Set Name Please ! ")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alertController.addTextField { (textField) in
            textField.placeholder = "Map Name"
        }
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        controller.present(alertController, animated: true, completion: nil)
    }
    
    func getData() {
   
        getModelPosition { (value) in
        
            value.forEach({ (data) in
                let pyramid: SCNGeometry
                pyramid = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
                pyramid.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.9)
                
//                let origin = SCNVector3Make(Float(data.x ?? 0), Float(data.y ?? 0), Float(data.z ?? 0))
//                let oo = simd_float4x4()
//                sceneView.session.setWorldOrigin(relativeTransform: origin)
                
                let geometryNode = SCNNode(geometry: pyramid)
                
                let calculatedX = data.x! //- self.QRlocationX
                let calculatedY = data.y! //- self.QRlocationY
                    
                geometryNode.position = SCNVector3Make(Float(calculatedX), Float(calculatedY), Float(data.z ?? 0))
               
                geometryNode.scale = SCNVector3(x:0.1, y:0.1, z:0.1)
                
                self.sceneView.scene.rootNode.addChildNode(geometryNode)
            })
        }
    }
    
    func getModelPosition(oNSuccess dataArray:@escaping (_ data:[ObjModel])->Void){
        self.dataBaseRefer = Database.database().reference()
        //self.dataBaseRefer.child("Object_Location").child("\(mapName)").observeSingleEvent(of: .value) { (dataSnap) in
        self.dataBaseRefer.child("Object_Location").child("hello").observeSingleEvent(of: .value) { (dataSnap) in
            let models = dataSnap.children.map({(data) -> ObjModel in
                    return  ObjModel(snap: data as! DataSnapshot)
                })
            dataArray(models)
        }
    }
    
    func setPositionTextLabel(x: Float,y: Float,z: Float){
        xPositionLabel.text = "X : \(x)"
        yPositionLabel.text = "Y : \(y)"
        zPositionLabel.text = "Z : \(z)"
    }
    
    func setQRLocation(){
        let arrayXY = mapName.components(separatedBy: " ")
        print(arrayXY)
        if arrayXY != [] {
            QRlocationX = Double(arrayXY[0])!
            QRlocationY = Double(arrayXY[1])!
        }
    }
    
}
