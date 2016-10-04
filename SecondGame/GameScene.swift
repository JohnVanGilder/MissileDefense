


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
        let loser = SKLabelNode()
    
    
    
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
        //add player to the scene
        addChild(player)
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
//-------------------------------------------------------------------------------------------------
//Handle touches

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touchPosition :CGPoint = touches.first!.location(in: view)
      
        //if touch is on the second third of the screen, fire a laser
        if(touchPosition.x >= size.width/3){
            //create sprite

            if(player.lives > 0){
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
            }else {
                player.lives = 5
                sleep(UInt32(1.0))
                removeAllChildren()
                addPlayer()
            }
                }
        
    
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
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
            
            player.run(SKAction.move(to: CGPoint(x: touchPosition.x, y: touchPosition.y), duration: Double(length)/speed))
            
        }

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
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
            
            player.run(SKAction.move(to: CGPoint(x: touchPosition.x, y: touchPosition.y), duration: Double(length)/speed))
            
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

    
    
    }

//-------------------------------------------------------------------------------------------------
//set collision behavior for ship
    func asteroidDidCollideWithPlayer(asteroid: SKSpriteNode, player:playerSpriteNode){
        print("rip")
        
        let texture1 = SKTexture(imageNamed:"explosion")
        asteroid.texture = texture1
        asteroid.run(SKAction.sequence([SKAction.move(to: asteroid.position, duration: 0), SKAction.removeFromParent()]))
        player.lives -= 1
        if(player.lives == 0){
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
        player.removeFromParent()

        loser.text = "GAME OVER"
        loser.fontSize = 75
        loser.fontColor = SKColor.red
        let center = CGPoint(x: size.width/2, y: size.height/2)
        loser.position = center
        
        addChild(loser)
    }
}
