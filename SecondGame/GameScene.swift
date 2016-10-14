


import SpriteKit

//Physics categories, to be used for handling collision later
struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Asteroid   : UInt32 = 0b1       // 1
    static let Projectile: UInt32 = 0b10      // 2
    static let Player: UInt32 = 0b11        //3
}


//-------------------------------------------------------------------------------------------------
//Bunch of vector math copied from ray wenderlich's tutorial

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

//-------------------------------------------------------------------------------------------------


class playerSpriteNode: SKSpriteNode{
    var lives = 5
    
}



class GameScene: SKScene, SKPhysicsContactDelegate {
    
        let player = playerSpriteNode(imageNamed: "Spaceship")
        let scoreboard = SKLabelNode()
        let shieldbar = SKSpriteNode(imageNamed: "shield4")
        var score = 0
    
//-------------------------------------------------------------------------------------------------
    func addPlayer(){
        //add the player to the scene


        player.physicsBody = SKPhysicsBody (rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Asteroid
        player.physicsBody?.collisionBitMask = PhysicsCategory.None
        player.physicsBody?.usesPreciseCollisionDetection = true
        
        //Define the player's position
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        player.zPosition = 100
        //add player to the scene after ensuring it has the right sprite texture
        player.run(SKAction.setTexture(SKTexture(imageNamed: "Spaceship")))
        addChild(player)
        
        //create and add the shield bar to the scene
        shieldbar.texture = SKTexture(imageNamed: "shield4")
        shieldbar.position = CGPoint(x: shieldbar.size.width , y: shieldbar.size.height + 5)
        shieldbar.zPosition = -1
        addChild(shieldbar)
        
        //create and add the scoreboard to the scene
        scoreboard.text = "Score: 000"
        scoreboard.position = CGPoint(x: size.width * 0.9 - scoreboard.frame.size.width/2, y: size.height * 0.9)
        
        scoreboard.fontColor = UIColor.red

        addChild(scoreboard)
        
        
    }
    
//-------------------------------------------------------------------------------------------------
    //Things to do to set up  the initial view
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        


        //Set background
        backgroundColor = SKColor.black


        addPlayer()
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(addAsteroid), SKAction.wait(forDuration: 1.0)])))
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(addStar), SKAction.wait(forDuration: 0.1)])))
        
    }
    
//-------------------------------------------------------------------------------------------------
    func addStar() {
        let star = SKSpriteNode(imageNamed: "star")
        
        let randomY = random(min: star.size.height/2, max: size.height - star.size.height/2)
        star.position = CGPoint(x: size.width + star.size.width/2, y: randomY)
        addChild(star)
        
        
        let actionMove = SKAction.move(to: CGPoint(x: -star.size.width/2, y: randomY), duration: TimeInterval(10.0))
        let actionMoveDone = SKAction.removeFromParent()
        star.zPosition = -100
        star.run(SKAction.sequence([actionMove, actionMoveDone]))
        
    }

//-------------------------------------------------------------------------------------------------
//Helper functions for asteroid behavior
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
//-------------------------------------------------------------------------------------------------
//Add an asteroid to the scene and set up its properties
    func addAsteroid(){
        
        //create sprite
        let asteroid = SKSpriteNode(imageNamed: "asteroid")
        
        //Setup hitbox and physics properties
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.size.width/2)
        asteroid.physicsBody?.isDynamic = true
        asteroid.physicsBody?.affectedByGravity = true
        asteroid.physicsBody?.categoryBitMask = PhysicsCategory.Asteroid
        asteroid.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
        asteroid.physicsBody?.collisionBitMask = PhysicsCategory.None
        asteroid.physicsBody?.usesPreciseCollisionDetection = true
        
        //Calculate initial spawn position: min and max are both half offscreen
        let actualY = random(min: asteroid.size.height/2, max: size.height - asteroid.size.height/2)
       // let actualY = player.position.y
        //place asteroid along right edge, with y coordinate as above
        asteroid.position = CGPoint(x: size.width + asteroid.size.width/2, y: actualY)
        
        //add to scene
        addChild(asteroid)
        
        //determine asteroid speed (make it random)
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        //create actions
        //Move: moves the thing across the screen from its starting position to the end of the screen in duration
        //defined above
        let actionMove = SKAction.move(to: CGPoint(x: -asteroid.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        //despawns the asteroid
        let actionMoveDone = SKAction.removeFromParent()
        
        

        asteroid.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        
    }
    
    func shoot(){
        let laser = SKSpriteNode(imageNamed: "laser")
        //set sprite location
        laser.position = player.position
        
        //makes sure it's behind the ship (all others have default 0 for zposition)
        laser.zPosition = -1
        
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        laser.physicsBody?.isDynamic = true
        laser.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        laser.physicsBody?.affectedByGravity = false
        laser.physicsBody?.contactTestBitMask = PhysicsCategory.Asteroid
        laser.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        
        
        
        
        addChild(laser)
        
        let actionMove = SKAction.move(to: CGPoint(x: size.width + laser.size.width/2, y:player.position.y), duration: 1.0)
        let actionDone = SKAction.removeFromParent()
        
        laser.run(SKAction.sequence([actionMove, actionDone]))
        

        
    }
//-------------------------------------------------------------------------------------------------
//Handle touches

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touchPosition :CGPoint = touches.first!.location(in: view)
      
        //if touch is on the second third of the screen, fire a laser
        if(touchPosition.x >= size.width/3){
            //create sprite

            if(player.lives > 0){
                shoot()
               
            }else {
                player.lives = 5
                sleep(UInt32(1.0))
                removeAllChildren()
                addPlayer()
            }
                }
        
    
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(player.lives > 0){
            var touchPosition :CGPoint = touches.first!.location(in: view)
        
            if(touchPosition.x < size.width/3){
            
                touchPosition = (scene?.convertPoint(fromView: touchPosition))!
                if(touchPosition.x < player.size.width/2){
                    touchPosition.x += player.size.width/2
                }
                if(touchPosition.y < player.size.height/2){
                    touchPosition.y += player.size.height/2
                }else if(touchPosition.y > size.height - player.size.height/2){
                    touchPosition.y -= player.size.height/2
                }
                
                let length = abs(CGFloat(hypotf(Float(touchPosition.x - player.position.x), Float(touchPosition.y - player.position.y))))
                let speed = 500.0
            
                //offset player sprite from the user's finger so he can see the ship
                player.run(SKAction.move(to: CGPoint(x: touchPosition.x + 30, y: touchPosition.y), duration: Double(length)/speed))
            }
        }

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(player.lives > 0){
            var touchPosition :CGPoint = touches.first!.location(in: view)
        
            if(touchPosition.x < size.width/3){
        
                touchPosition = (scene?.convertPoint(fromView: touchPosition))!
                if(touchPosition.x < player.size.width/2){
                touchPosition.x += player.size.width/2
                }
                if(touchPosition.y < player.size.height/2){
                    touchPosition.y += player.size.height/2
                }else if(touchPosition.y > size.height - player.size.height/2){
                    touchPosition.y -= player.size.height/2
                }
            
                let length = abs(CGFloat(hypotf(Float(touchPosition.x - player.position.x), Float(touchPosition.y - player.position.y))))
                let speed = 500.0
            
            //offset player sprite from user's finger so she can see the ship
            player.run(SKAction.move(to: CGPoint(x: touchPosition.x + 30, y: touchPosition.y), duration: Double(length)/speed))
            
            }
        
            
        }

    }
    
//-------------------------------------------------------------------------------------------------
//set collision behavior for asteroids
    func projectileDidCollideWithAsteroid(asteroid: SKSpriteNode, projectile: SKSpriteNode){
        print("hit")
    
        projectile.removeFromParent()
        
        let texture1 = SKTexture(imageNamed:"explosion")
        
        asteroid.texture = texture1
       
        asteroid.run(SKAction.sequence([SKAction.move(to: asteroid.position, duration: 0), SKAction.removeFromParent()]))
        
        score(interval: 100)

    
    }

//-------------------------------------------------------------------------------------------------
//sets scoring behavior
    func score(interval: Int){
        score += interval
        scoreboard.text = "Score: \(score)"
        
        scoreboard.position = CGPoint(x: size.width * 0.9 - scoreboard.frame.size.width/2, y: size.height * 0.9)
        //if(score % 1000 == 0 && player.lives < 5){
        //player.lives += 1
        //}
        
    }
    
//-------------------------------------------------------------------------------------------------
    
//set collision behavior for ship
    func asteroidDidCollideWithPlayer(asteroid: SKSpriteNode, player:playerSpriteNode){
        print("rip")
        
        let texture1 = SKTexture(imageNamed:"explosion")
        asteroid.texture = texture1

        if(player.lives > 1){
            player.run(SKAction.sequence([SKAction.setTexture(SKTexture(imageNamed: "shieldship")), SKAction.wait(forDuration: 0.5), SKAction.setTexture(SKTexture(imageNamed: "Spaceship"))]))
        }
        
        asteroid.run(SKAction.sequence([SKAction.move(to: asteroid.position, duration: 0), SKAction.removeFromParent()]))
        player.lives -= 1
        
        if(player.lives == 4){
            shieldbar.texture = SKTexture(imageNamed: "shield3")
        }else if(player.lives == 3){
            shieldbar.texture = SKTexture(imageNamed: "shield2")
        }else if(player.lives == 2){
            shieldbar.texture = SKTexture(imageNamed: "shield1")
        }else if(player.lives == 1){
            shieldbar.removeFromParent()
        }else if(player.lives == 0){
            gameOver();
        }
        
        
    }
    
//-------------------------------------------------------------------------------------------------
//contact delegate method
    func didBegin(_ contact: SKPhysicsContact) {

        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if((firstBody.categoryBitMask == PhysicsCategory.Asteroid) &&
            (secondBody.categoryBitMask == PhysicsCategory.Player)){
            asteroidDidCollideWithPlayer(asteroid: firstBody.node as! SKSpriteNode, player: secondBody.node as! playerSpriteNode)
        }

        else if((firstBody.categoryBitMask == PhysicsCategory.Asteroid ) &&
            (secondBody.categoryBitMask == PhysicsCategory.Projectile)){
            projectileDidCollideWithAsteroid(asteroid: firstBody.node as! SKSpriteNode, projectile: secondBody.node as! SKSpriteNode)
            
        }
    }
    
//-------------------------------------------------------------------------------------------------
    func gameOver(){

        score = 0
        
        //Sets up the animation to break up the ship and explode
        let ship1 = SKSpriteNode(imageNamed: "spaceshipTopLeft")
        let ship2 = SKSpriteNode(imageNamed: "spaceshipTopRight")
        let ship3 = SKSpriteNode(imageNamed: "spaceshipBotLeft")
        let ship4 = SKSpriteNode(imageNamed: "spaceshipBotRight")

        //spawns the ship parts at the right place
        ship1.position = player.position
        ship2.position = CGPoint(x: player.position.x - 6, y: player.position.y - 1)
        ship3.position = CGPoint(x: player.position.x, y: player.position.y + 1)
        ship4.position = CGPoint(x: player.position.x - 1, y: player.position.y)
        

        addChild(ship1)
        addChild(ship2)
        addChild(ship3)
        addChild(ship4)
        
        //blows up the ship after making sure it's not moving
        player.removeAllActions()
        player.removeFromParent()
        let explosion = SKSpriteNode(imageNamed: "explosion")
        explosion.position = player.position
        addChild(explosion)
        explosion.run(SKAction.sequence([SKAction.setTexture(SKTexture(imageNamed: "explosion")),SKAction.scale(to: 0.2, duration: 0), SKAction.scale(by: 5, duration: 2), SKAction.removeFromParent()]))

        //plays the animation of the ship breaking up and exploding
        ship1.run(SKAction.sequence([SKAction.move(by: CGVector(dx: random(min:20, max: 100), dy: random(min:20, max: 100)), duration: 4), SKAction.setTexture(SKTexture(imageNamed: "explosion")), SKAction.wait(forDuration: 0.2), SKAction.removeFromParent()]))
        ship2.run(SKAction.sequence([SKAction.move(by: CGVector(dx: -1 * random(min:20, max: 100), dy: random(min:20, max: 100)), duration: 3), SKAction.setTexture(SKTexture(imageNamed: "explosion")), SKAction.wait(forDuration: 0.2), SKAction.removeFromParent()]))
        ship3.run(SKAction.sequence([SKAction.move(by: CGVector(dx: -1 * random(min:20, max: 100), dy: -1 * random(min:20, max: 100)), duration: 3.5), SKAction.setTexture(SKTexture(imageNamed: "explosion")), SKAction.wait(forDuration: 0.2), SKAction.removeFromParent()]))
        ship4.run(SKAction.sequence([SKAction.move(by: CGVector(dx: random(min:20, max: 100), dy: -1 * random(min:20, max: 100)), duration: 3), SKAction.setTexture(SKTexture(imageNamed: "explosion")), SKAction.wait(forDuration: 0.2), SKAction.removeFromParent()]))
        

        
        let loser = SKLabelNode()
        loser.text = "GAME OVER"
        loser.fontSize = 75
        loser.fontColor = SKColor.red
        let center = CGPoint(x: size.width/2, y: size.height/2)
        loser.position = center
        
        addChild(loser)
    }
}
