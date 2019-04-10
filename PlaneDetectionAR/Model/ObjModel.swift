//
//  ObjModel.swift
//  PlaneDetectionAR
//
//  Created by Ice on 1/4/2562 BE.
//  Copyright © 2562 Ice. All rights reserved.
//

import Foundation
import Firebase

struct ObjModel {
    var x: Double?
    var y: Double?
    var z: Double?
    
    init(snap: DataSnapshot) {
        //let key = snap.key
        self.x = snap.childSnapshot(forPath: "x").value as? Double
        self.y = snap.childSnapshot(forPath: "y").value as? Double
        self.z = snap.childSnapshot(forPath: "z").value as? Double
    }
}
