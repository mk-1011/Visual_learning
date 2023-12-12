//
//  ViewController.swift
//  Object_integration
//
//  Created by Manasa Kallam on 02/03/23.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var player: AVPlayer?
    var videoNode: SKVideoNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        // Check for a folder called "ARImages" Resource Group in the Assets Folder
        if let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "ARImages", bundle: Bundle.main) {
            
            // Set the images to track
            configuration.trackingImages = trackedImages
            configuration.maximumNumberOfTrackedImages = 1
        }
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        // Stop the player and remove the video node from the scene
        player?.pause()
        videoNode?.removeFromParent()
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // Check if the anchor is of type ARImageAnchor
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        // Get the detected image name
        guard let imageName = imageAnchor.referenceImage.name else { return }
        
        // Use the image name to find the corresponding video file
        guard let fileUrlString = Bundle.main.path(forResource: imageName, ofType: "mp4") else { return }
        
        // Stop the previous player and remove the previous video node
        player?.pause()
        videoNode?.removeFromParent()
        
        let videoItem = AVPlayerItem(url: URL(fileURLWithPath: fileUrlString))
        
        player = AVPlayer(playerItem: videoItem)
        videoNode = SKVideoNode(avPlayer: player!)
        
        player?.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: nil) { (notification) in
            self.player?.seek(to: CMTime.zero)
            self.player?.play()
            print("Looping Video")
        }
        
        let videoScene = SKScene(size: CGSize(width: 480, height: 360))
        videoNode?.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
        videoNode?.yScale = -1.0
        videoScene.addChild(videoNode!)
        
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        plane.firstMaterial?.diffuse.contents = videoScene
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        node.addChildNode(planeNode)
    }
}
