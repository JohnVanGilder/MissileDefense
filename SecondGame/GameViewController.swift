//
//  GameViewController.swift
//  SecondGame
//
//  Created by John Van Gilder on 10/3/16.
//  Copyright © 2016 John Van Gilder. All rights reserved.
//

import UIKit
import SpriteKit


class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = GameScene(size: view.bounds.size)
        let skView = view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
    

}
