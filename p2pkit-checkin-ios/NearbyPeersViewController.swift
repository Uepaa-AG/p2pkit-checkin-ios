//
//  NearbyPeersViewController.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import UIKit
import SpriteKit

class NearbyPeersViewController: UIViewController, DLGraphSceneDelegate {
    
    @IBOutlet var graphView: DLForcedGraphView!
    @IBOutlet weak var selfAnchorView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    let guestManager = GuestManager.sharedManager
    var graphScene: DLGraphScene!
    
    var ownNode: SKShapeNode?
    var nearbyGuestIds = Dictionary<UInt, String>()
    var guestNodes = Dictionary<String, SKShapeNode>()
    var nextNodeIndex: UInt = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.graphScene = self.graphView.graphScene
        self.graphScene.delegate = self
        self.headerLabel.backgroundColor = UIColor.white
        self.headerLabel.textColor = Helpers.defaultColor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // create own node
        let edge = DLEdge(i: 0, j: 0)
        edge?.repulsion = 1100.0
        edge?.attraction = 0.07
        self.graphScene.add(edge)
        
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.setPositionForOwnNode()
    }
    
    // MARK: - Node Handling
    
    func connectToOperatorController() {
        
        // create guest nodes
        for guest: Guest in self.guestManager.getNearbyGuests() {
            self.addNodeForGuest(guest)
        }
        
        OperatorController.sharedController.nearbyGuestsController = self
    }
    
    func addNodeForGuest(_ guest: Guest) {
        
        if (nearbyGuestIds.values.contains(guest.guestId)) {
            return;
        }
        
        nearbyGuestIds[nextNodeIndex] = guest.guestId
        
        let edge = DLEdge(i: 0, j: nextNodeIndex)
        edge?.repulsion = self.repulsionForProximityStrength(guest.proximityStrength)
        edge?.attraction = self.attractionForProximityStrength(guest.proximityStrength)
        
        edge?.unknownConnection = (guest.proximityStrength == .unknown)
        edge?.immediateConnection = (guest.proximityStrength == .immediate)
        
        self.graphScene.add(edge)
        nextNodeIndex += 1
    }
    
    func updateNodeForGuest(_ guest: Guest) {
        
        for (index, guestId) in self.nearbyGuestIds {
            
            if guestId == guest.guestId {
                
                let edge = DLEdge(i: 0, j: index)
                edge?.repulsion = self.repulsionForProximityStrength(guest.proximityStrength)
                edge?.attraction = self.attractionForProximityStrength(guest.proximityStrength)
                edge?.unknownConnection = (guest.proximityStrength == .unknown)
                edge?.immediateConnection = (guest.proximityStrength == .immediate)
                self.graphScene.update(edge)
                
                if let node = self.guestNodes[guestId] {
                    
                    if node.name != guest.name {
                        node.name = guest.name
                    }
                    
                    self.updateLabelForNode(node)
                }
            }
        }
        
        self.updateStrokesForAllNodes()
    }
    
    func removeNodeForGuest(_ guest: Guest) {
        
        for (index, guestId) in self.nearbyGuestIds {
            
            if guestId == guest.guestId {
                
                let edge = DLEdge(i: 0, j: index)
                self.graphScene.remove(edge)
                
                self.nearbyGuestIds.removeValue(forKey: index)
                self.guestNodes.removeValue(forKey: guestId)
            }
        }
        
        self.updateStrokesForAllNodes()
    }
    
    func removeNodesForAllPeers() {
        
        for (index, _) in self.nearbyGuestIds {
            let edge = DLEdge(i: 0, j: index)
            self.graphScene.remove(edge)
        }
        
        self.nearbyGuestIds.removeAll()
        self.guestNodes.removeAll()
        
        self.updateStrokesForAllNodes()
    }
    
    // MARK: - DLGraphSceneDelegate
    
    func configureVertex(_ vertex: SKShapeNode!, at index: UInt) {
        
        if index == 0 {
            
            var transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            vertex.path = vertex.path?.mutableCopy(using: &transform)
            
            let newBody = SKPhysicsBody.init(circleOfRadius: vertex.frame.size.width/2)

            if let phisicalBody = vertex.physicsBody {
                 newBody.mass = phisicalBody.mass
            }
    
            newBody.allowsRotation = false
            newBody.isDynamic = false
            newBody.affectedByGravity = false
            vertex.physicsBody = newBody
            vertex.fillColor = Helpers.defaultColor()
            
            ownNode = vertex
            
            DispatchQueue.main.async(execute: { 
                
                self.setPositionForOwnNode()
                self.connectToOperatorController();
            })
            
        }
        else {
            
            let guestId = nearbyGuestIds[index]!
            if let guest = guestManager.getNearbyGuest(guestId) {
                
                vertex.fillColor = Helpers.nearbyColor()
                
                vertex.name = guest.name
                self.updateLabelForNode(vertex)
                
                guestNodes[guestId] = vertex
            }
            
        }
        
        vertex.lineWidth = 2.0
        self.updateStrokesForAllNodes()
    }
    
    func tap(onVertex vertex: SKNode!, at index: UInt) {
        // nothing to do here
    }
    
    // MARK: - Helpers
    
    fileprivate func setPositionForOwnNode() {
        self.ownNode?.position = CGPoint(x: self.selfAnchorView.frame.midX, y: self.graphView.frame.size.height - self.selfAnchorView.frame.midY)
    }
    
    fileprivate func updateLabelForNode(_ node: SKShapeNode!) {
        
        if node.name != nil {
            
            self.removeLabelForNode(node)
            
            let labelText = node.name
            
            let label = SKLabelNode.init(text: labelText)
            label.text = labelText
            label.name = "label"
            label.fontName = "HelveticaNeue-Regular"
            label.fontColor = UIColor.white
            label.verticalAlignmentMode = .center
            
            let scalingFactor = min(node.frame.size.width / label.frame.width, node.frame.size.height / label.frame.height)
            label.fontSize *= scalingFactor
            label.fontSize *= 0.75
            label.fontSize = max(min(label.fontSize, 18.0), 8.0)
            label.position = CGPoint(x: 0, y: 0)

            node.addChild(label)
        }
    }
    
    fileprivate func removeLabelForNode(_ node: SKShapeNode!) {
        
        for child: SKNode in node.children {
            if child.name == "label" {
                child.removeFromParent()
            }
        }
    }
    
    fileprivate func updateStrokesForAllNodes() {
        
        let highlightColor = Helpers.defaultColor()
        var hasImmediatePeers = false
        
        for (_, guestId) in self.nearbyGuestIds {
            
            if let guest = self.guestManager.getNearbyGuest(guestId) {
            
                if let node = self.guestNodes[guestId] {
                    
                    if guest.proximityStrength == .immediate {
                        node.strokeColor = highlightColor
                        hasImmediatePeers = true
                    }
                    else {
                        node.strokeColor = node.fillColor
                    }
                }
            }
        }
        
        ownNode?.strokeColor = (hasImmediatePeers ? highlightColor : ownNode!.fillColor)
  
    }
    
    fileprivate func repulsionForProximityStrength(_ proximityStrength: PPKProximityStrength) -> CGFloat {
        
        switch proximityStrength {
        case .extremelyWeak:
            return 2500.0
        case .weak:
            return 2000.0
        case .medium:
            return 1500.0
        case .strong:
            return 1100.0
        case .immediate:
            return 700.0
        default:
            return 1500.0
        }
    }
    
    fileprivate func attractionForProximityStrength(_ proximityStrength: PPKProximityStrength) -> CGFloat {
        
        switch proximityStrength {
        case .extremelyWeak:
            return 0.025
        case .weak:
            return 0.03
        case .medium:
            return 0.05
        case .strong:
            return 0.07
        case .immediate:
            return 0.12
        default:
            return 0.05
        }
    }
}
