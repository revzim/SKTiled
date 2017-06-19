//
//  GameViewController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import UIKit
import SpriteKit


class GameViewControllerIOS: UIViewController {

    @IBOutlet weak var mapInfoLabel: UILabel!
    @IBOutlet weak var tileInfoLabel: UILabel!
    @IBOutlet weak var propertiesInfoLabel: UILabel!
    
    var demoFiles: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // load demo files from a propertly list
        demoFiles = loadDemoFiles("DemoFiles")

        let currentFilename = demoFiles.first!

        // Configure the view.
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true

        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        setupDebuggingLabels()
        
        /* create the game scene */
        let scene = SKTiledDemoScene(size: self.view.bounds.size)

        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .aspectFill

        //set up notification for scene to load the next file
        NotificationCenter.default.addObserver(self, selector: #selector(loadNextScene), name: NSNotification.Name(rawValue: "loadNextScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadPreviousScene), name: NSNotification.Name(rawValue: "loadPreviousScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabels), name: NSNotification.Name(rawValue: "updateDebugLabels"), object: nil)
        
        skView.presentScene(scene)
        scene.setup(tmxFile: currentFilename)
    }
    
    /**
     Set up the debugging labels.
     */
    func setupDebuggingLabels() {
        mapInfoLabel.text = "Map: "
        tileInfoLabel.text = "Tile: "
        propertiesInfoLabel.text = "Properties:"
    }

    @IBAction func fitButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
                let scene = view.scene as? SKTiledScene else { return }

        if let cameraNode = scene.cameraNode {
            cameraNode.fitToView(newSize: view.bounds.size)
        }
    }

    @IBAction func gridButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            tilemap.debugDraw = !tilemap.debugDraw
        }
    }

    @IBAction func objectsButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            let debugState = !tilemap.showObjects
            tilemap.showObjects = debugState
        }
    }

    @IBAction func nextButtonPressed(_ sender: Any) {
        loadNextScene()
    }

    /**
     Load the next tilemap scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    func loadNextScene(_ interval: TimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }
        
        var debugMode = false
        var showOverlay = true
        
        var currentFilename = demoFiles.first!
        if let currentScene = view.scene as? SKTiledDemoScene {
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
            }

            debugMode = currentScene.debugMode
            if let tilemap = currentScene.tilemap {
                debugMode = tilemap.debugDraw
                currentFilename = tilemap.name!
            }

            currentScene.removeFromParent()
            currentScene.removeAllActions()
        }

        view.presentScene(nil)

        var nextFilename = demoFiles.first!
        if let index = demoFiles.index(of: currentFilename) , index + 1 < demoFiles.count {
            nextFilename = demoFiles[index + 1]
        }
        
        let nextScene = SKTiledDemoScene(size: view.bounds.size)
        nextScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: interval)
        
        nextScene.debugMode = debugMode
        view.presentScene(nextScene, transition: transition)
        nextScene.setup(tmxFile: nextFilename)
        nextScene.cameraNode?.showOverlay = showOverlay
        nextScene.tilemap?.debugDraw = debugMode
    }

    /**
     Load the previous tilemap scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    func loadPreviousScene(_ interval: TimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }

        var debugMode = false
        var showOverlay = true
        
        var currentFilename = demoFiles.first!
        if let currentScene = view.scene as? SKTiledDemoScene {
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
            }
            
            debugMode = currentScene.debugMode
            if let tilemap = currentScene.tilemap {
                debugMode = tilemap.debugDraw
                currentFilename = tilemap.filename!
            }
            
            currentScene.removeFromParent()
            currentScene.removeAllActions()
        }

        view.presentScene(nil)

        var nextFilename = demoFiles.last!
        if let index = demoFiles.index(of: currentFilename), index > 0, index - 1 < demoFiles.count {
            nextFilename = demoFiles[index - 1]
        }

        let nextScene = SKTiledDemoScene(size: view.bounds.size)
        nextScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: interval)
        view.presentScene(nextScene, transition: transition)
        
        nextScene.setup(tmxFile: nextFilename)
        nextScene.cameraNode?.showOverlay = showOverlay
        nextScene.tilemap?.debugDraw = debugMode
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    /**
     Load TMX files from the property list.

     - returns: `[String]` array of tiled file names.
     */
    fileprivate func loadDemoFiles(_ filename: String) -> [String] {
        var result: [String] = []
        if let fileList = Bundle.main.path(forResource: filename, ofType: "plist"){
            if let data = NSArray(contentsOfFile: fileList) as? [String] {
                result = data
            }
        }
        return result
    }
    
    /**
     Update the debugging labels with scene information.
     
     - parameter notification: `Notification` notification.
     */
    func updateDebugLabels(notification: Notification) {
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.text = mapInfo as? String
        }
        
        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.text = tileInfo as? String
        }
        
        if let propertiesInfo = notification.userInfo!["propertiesInfo"] {
            propertiesInfoLabel.text = propertiesInfo as? String
        }
    }
}
