//
//  GameScene.swift
//  PongBasic
//
//  Created by Chad on 3/11/20.
//  Copyright © 2020 Chad. All rights reserved.
//

import SpriteKit
import GameplayKit
import MultipeerConnectivity

class GameScene: SKScene {
    
    let randomNum:UInt32 = arc4random_uniform(200)
    
    var x_scale = CGFloat(1.0)
    var y_scale = CGFloat(1.0)
    
    ///initial ball velocity components
    var init_vel_x:Int = 0
    var init_vel_y:Int = 0
    
    var ball = SKSpriteNode()
    var player01 = SKSpriteNode()
    var player02 = SKSpriteNode()
    var scoreLabel = SKLabelNode()
    var player1score = 0
    var player2score = 0
    
    // holds a reference to our opponent and to our own paddle
    var myPlayer:SKSpriteNode? = nil
    var otherPlayer:SKSpriteNode? = nil
    
    // If true, our device is responsible for
    // communicating the ball's position;
    // otherwise, the ball position is determined
    // by the other device's communications.
    var ballControl = false
    
    // used for testing purposes...
    var auto_player = false
    
    // This object enables our peer-to-peer, two-player game communications
    var serviceMgr: GameServiceManager? = nil

    // Remember: this is called only once -
    // when the game scene becomes the active, visible scene
    override func didMove(to view: SKView)
    {
        serviceMgr = GameServiceManager()
        
        resetGame()
        
        // start advertising our peer while looking for other peers
        serviceMgr!.delegate = self
        serviceMgr!.startNewSession()
        serviceMgr!.beginBrowsingPeers()
    }
    
    func resetGame()
    {
        
        //setup our nodes according to what we built in the game scene editor
        ball = self.childNode(withName: "ball") as! SKSpriteNode
        player01 = self.childNode(withName: "player01") as! SKSpriteNode
        player02 = self.childNode(withName: "player02") as! SKSpriteNode
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        
        
        // set the initial y position of the paddles according to the screen height
        player01.position = CGPoint(x:player01.position.x, y:-((self.frame.height/2)-100))
        player02.position = CGPoint(x:player02.position.x, y:((self.frame.height/2)-100))
        
        
        // we do not want the ball to slow down during gameplay...
        
        /*
         Note: linearDamping is a property that reduces the body’s linear velocity.  It's used to simulate fluid or air friction forces on the body. The property must be a value between 0.0 and 1.0. The default value is 0.1. If the value is 0.0, no linear damping is applied to the object.
         */
        
        ball.physicsBody?.linearDamping=0
        
        /* angularDamping is a property that reduces the body’s rotational velocity.  It's used to simulate fluid or air friction forces on the body. The property must be a value between 0.0 and 1.0. The default value is 0.1. If the value is 0.0, no angular damping is applied to the object.
         */
        
        ball.physicsBody?.angularDamping=0
        
        
        // create a border around our frame
        let border = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        // we don't want the ball slowed when hitting the wall
        
        /*
         The friction property specifies the roughness of the surface of the physics body.  It's used to apply a frictional force to physics bodies in contact with this physics body. The property must be a value between 0.0 and 1.0. The default value is 0.2.
         */
        
        border.friction=0
        
        /*
         The restitution property determines the bounciness of the physics body.  It's used to determine how much energy the physics body loses when it bounces off another object. The property must be a value between 0.0 and 1.0. The default value is 0.2.
         
         */
        
        border.restitution = 1
        
        // We want the ball to bounce of the walls,
        // so set scene's border to this new border we created.
        self.physicsBody = border
        
    }
    
    // Randomly determine the staring velocity of the ball
    func determineBallVelocity ()
    {
        //
        
        let xInt:Int = Int(randomNum)
        
        var dir:Int = 0
        
        if (xInt<=100)
        {
            dir = -xInt
        }
        else
        {
            dir = 200-xInt
        }
        
        if abs(dir)<50
        {
            if (dir)<0
            {
                dir-=50
            }
            else
            {
                dir+=50
            }
        }
        
        let startDir:Int = Int(randomNum)
        
        if startDir<=100
        {
            init_vel_y = -dir
            init_vel_x = dir
        
        }
        else
        {
            init_vel_y = dir
            init_vel_x = -dir
            
        }
    }
    
    //handle taps to the screen...
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // we just need to process any touch(es) we get
        for touch in touches
        {
            let location = touch.location(in: self)
            if ((myPlayer) != nil)
            {
                myPlayer!.run (SKAction.moveTo(x: location.x, duration: 0.01))
            }
        }
        do
               {
                   try serviceMgr!.send(player: myPlayer!)
               }
               catch
               {
                   
               }
        
    }
    
    // handle "dragging" of finger on screen
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
         if (myPlayer == nil)
         {
            return
         }
        
        // handles when user drags finger around on screen
        for touch in touches
        {
            let location = touch.location(in: self)
            myPlayer!.run (SKAction.moveTo(x: location.x, duration: 0.01))
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // handles when finger is lifted up
        do
        {
            try serviceMgr!.send(player: myPlayer!)
        }
        catch
        {
            
        }
    }
    
    // your game loop
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if player1score >= 9 {
            if self.myPlayer == player01 {
                ball.removeAllActions()
                scoreLabel.text = "YOU WON!"
                sleep(3)
            } else {
                ball.removeAllActions()
                scoreLabel.text = "YOU LOST!"
                sleep(3)
            }
            
        } else if player2score >= 9 {
            if self.myPlayer == player02 {
                ball.removeAllActions()
                ball.removeFromParent()
                scoreLabel.text = "YOU WON!"
                sleep(3)
            } else {
                ball.removeAllActions()
                ball.removeFromParent()
                scoreLabel.text = "YOU LOST!"
                sleep(3)
            }
            resetGame()
            
        } else {
        
            if auto_player // if auto-player is turned on...
            {
                if (myPlayer != nil)
                {
                    myPlayer?.run (SKAction.moveTo(x: ball.position.x, duration: 0.25))
                    do
                    {
                        try serviceMgr!.send(player: myPlayer!)
                    }
                    catch
                    {
                        //todo: log exception
                    }
                }
            }
            
            do
            {
                if (myPlayer != nil)
                {
                    if (ballControl) // if this device is responsible for sending ball's position...
                    {
                        // send the other device the ball's current position
                        try serviceMgr!.send(ball: ball)
                    }
                   
                }
            }
            catch
            {
                //todo: log exception
            }
            
            // Score
            if (ball.position.y < -(self.frame.height/2) + 30){
                print("Score top player")
                player2score += 1
                pointScored()
            } else if (ball.position.y > (self.frame.height/2) - 30) {
                print("Score bottom player")
                player1score += 1
                pointScored()
            }
        }
        
    }
    
    func pointScored() {
            ball.removeAllActions()
            ball.position.y = 0.0
            ball.position.x = 0.0
            sleep(2)
            determineBallVelocity()
            ball.physicsBody?.applyImpulse(CGVector(dx: init_vel_x, dy: init_vel_y))
            scoreLabel.text = String(player1score) + " : " + String(player2score)
            sleep(1)
    }
    
}

// handle incoming data from the game service manager
extension GameScene : GameServiceManagerDelegate {
    
    //Our device was invited to a game/match
    func gameInvite(manager : GameServiceManager, fromPeerID: MCPeerID)->Bool
    {
        //first, rest game
        self.resetGame()
        
        // now, accept invite
        return true
    }
    
    func lostConnection(manager : GameServiceManager, peerID: MCPeerID)
    {
        resetGame()
        
        serviceMgr!.startNewSession()
        serviceMgr!.beginBrowsingPeers()
        
    }
    
    // Here, we setup a scalar so that differences in screen size between devices
    // will not cause problems when it comes to reflecting the visual coordinates.
    func deviceDimensions(manager : GameServiceManager, peerID: MCPeerID, info: GameMessage)
    {
        // scale and adjust objects on screen
        print("scale information: \(info.data.x), \(info.data.y)")
        
        x_scale = self.frame.width/info.data.x
        y_scale = self.frame.height/info.data.y
        
        print("scale information: \(x_scale), \(y_scale)")
        
        player01.size.height = player01.size.height * y_scale
        player01.size.width = player01.size.width * x_scale
        
        player02.size.height = player02.size.height * y_scale
        player02.size.width = player02.size.width * x_scale
        
        ball.size.height = ball.size.height * y_scale
        ball.size.width = ball.size.width * x_scale
    }
    
    // here, we're receiving the ball's current position from the other device
    func ballPositionMsg(manager : GameServiceManager, peerID: MCPeerID, info: GameMessage) {
        print("ball position information.")
        
        // Remember: we're receiving this info on a background thread (async),
        // but we need to interact with the UI on the main thread.
        DispatchQueue.main.async { [unowned self] in
            
            self.ball.position = CGPoint(x: (info.data.x * self.x_scale),
                                         y: CGFloat(info.data.y * self.y_scale))
        }
    }
    
    // here, we're receiving our opponent's paddle position from the other device
    func playerPositionMsg(manager : GameServiceManager, peerID: MCPeerID, info: GameMessage) {
        print("player position information.")
        
        // Remember: we're receiving this info on a background thread (async),
        // but we need to interact with the UI on the main thread.
        DispatchQueue.main.async { [unowned self] in
            if (self.otherPlayer != nil)
            {
                self.otherPlayer!.position =  CGPoint(x: (info.data.x * self.x_scale),
                                                      y:-(self.myPlayer!.position.y))
            }
        }
    }
    
    func connectedDevicesChanged(manager: GameServiceManager, connectedDevices: [String])
    {
        if connectedDevices.count>=1
        {
            //**** START GAME ****
            
            print("Connected devices: \(connectedDevices.count)")
            
            
            if (manager.invitedToGame)
            {
                // This device was invited to a session;
                // therefore, we will be player 1, and we will also
                // be responsible for communicating the ball's
                // positional data throughout the duration of gameplay.
                self.myPlayer = player01
                
                // Our opponent (the other device)
                // will be player 2
                self.otherPlayer = player02
                ballControl = true
                
                
                /* do not worry about screen scaling for now...
                
                // inform the other device to scale according to this device's screen size
                do
                {
                    try self.serviceMgr!.send(frameLength:self.frame.size.width,
                                             frameHeight: self.frame.size.height)
                }
                catch
                {
                    //todo: log exception
                }
                */
            }
            else
            {
                // We (this device) are player 2
                myPlayer = player02
                
                // Our opponent (the other device) is player 1
                otherPlayer = player01
                
                // We are not responsible for communication ball's position
                // (the other device will send us the ball's positional data).
                ballControl=false
            }
            
            // Determine initial velocity of the ball
            
            self.determineBallVelocity()
            // set the ball in motion...
            ball.physicsBody?.applyImpulse(CGVector(dx: init_vel_x, dy: init_vel_y))
            
        }
         
        
    }
    
}
