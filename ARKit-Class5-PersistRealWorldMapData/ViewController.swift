//
//  ViewController.swift
//  ARKit-Class5-PersistRealWorldMapData
//
//  Created by apple on 11/05/19.
//  Copyright © 2019 appsmall. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("worldMapURL")
        }
        catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    
    
    // MARK:- VIEW CONTROLLER LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTapGesture(_:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetTrackingConfiguration()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sceneView.session.pause()
    }
    
    @objc func didReceiveTapGesture(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        guard let hitTestResult = sceneView.hitTest(location, types: [.featurePoint, .estimatedHorizontalPlane]).first  else { return }
        let anchor = ARAnchor(transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: anchor)
    }
    
    
    // MARK:- CORE FUNCTIONS
    
    // Saving World Map Data
    func archive(worldMap: ARWorldMap) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: worldMapURL, options: .atomic)
    }

    func setLabel(text: String) {
        messageLabel.text = text
    }
    
    func generateSphereNode() -> SCNNode {
        let sphere = SCNSphere(radius: 0.05)
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position.y += Float(sphere.radius)
        return sphereNode
    }
    
    func resetTrackingConfiguration(with worldMap: ARWorldMap? = nil) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        
        if let worldMap = worldMap {
            // The state from a previous AR session to attempt to resume with this session configuration.
            configuration.initialWorldMap = worldMap
            setLabel(text: "Found saved world map.")
        }
        else {
            setLabel(text: "Move camera around to map your surrounding space.")
        }
        
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
    }
    
    // Retrieving World Map Data
    func retrieveWorldMapData(from url: URL) -> Data? {
        do {
            return try Data(contentsOf: self.worldMapURL)
        } catch {
            self.setLabel(text: "Error retrieving world map data.")
            return nil
        }
    }
    
    func unarchive(worldMapData data: Data) -> ARWorldMap? {
        guard let worldMapObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) else { return nil }
        //guard let unarchievedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data), let worldMap = unarchievedObject else { return nil }
        return worldMapObject
    }
    
    
    // MARK:- IBACTIONS
    @IBAction func loadBtnPressed(_ sender: UIBarButtonItem) {
        guard let worldMapData = retrieveWorldMapData(from: worldMapURL), let worldMap = unarchive(worldMapData: worldMapData) else {
            return
        }
        
        resetTrackingConfiguration(with: worldMap)
    }
    
    @IBAction func reloadBtnPressed(_ sender: UIBarButtonItem) {
        resetTrackingConfiguration()
    }
    
    @IBAction func saveBtnPressed(_ sender: UIBarButtonItem) {
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            if let err = error {
                print("Error getting current world map")
                print(err.localizedDescription)
                return self.setLabel(text: "Error getting current world map")
            }
            
            if let worldMap = worldMap {
                do {
                    try self.archive(worldMap: worldMap)
                    DispatchQueue.main.async {
                        self.setLabel(text: "World map is saved.")
                    }
                }
                catch {
                    fatalError("Error saving world map: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        let sphereNode = generateSphereNode()
        DispatchQueue.main.async {
            node.addChildNode(sphereNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }
}
