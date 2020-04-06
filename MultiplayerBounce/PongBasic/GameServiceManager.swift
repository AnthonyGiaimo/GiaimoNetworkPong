//
//  ConnectionManager.swift
//  MultiPeer
//
//  Created by Chad on 3/6/20.
//  Copyright © 2020 Chad Mello. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import SpriteKit

// Code that uses our PeerServiceManager object must be ready to handle this protocol.
protocol GameServiceManagerDelegate: AnyObject
{
    func gameInvite(manager : GameServiceManager, fromPeerID: MCPeerID)->Bool
    
    func lostConnection(manager : GameServiceManager, peerID: MCPeerID)
    
    // triggered when a peer disconnects, connects, or loses connection
    func connectedDevicesChanged(manager : GameServiceManager, connectedDevices: [String])
    
    // triggered when information about the ball's position comes in
    func ballPositionMsg(manager : GameServiceManager, peerID: MCPeerID, info: GameMessage)
    
    // triggered when information about the opponent's position comes in
    func playerPositionMsg(manager : GameServiceManager, peerID: MCPeerID, info: GameMessage)
    
    func deviceDimensions(manager : GameServiceManager, peerID: MCPeerID, info: GameMessage)
    
    // Other things to consider...
    /*
    func ballTouch(manager : PeerServiceManager, peerID: MCPeerID, info: GameMessage)
    func gameStart(manager : PeerServiceManager, peerID: MCPeerID)
    func gameEnd(manager : PeerServiceManager, peerID: MCPeerID)
    func scoreChange(manager : PeerServiceManager, pScore: Int, peerID: MCPeerID)
 */
    
}

// Our class that wraps and simplifies peer-to-peer communications.
// Here we must inherit from a basic NSObject in order to handle
// the delegate protocols related to MultipeerConnectivity
class GameServiceManager:NSObject
{
    weak var delegate: GameServiceManagerDelegate?
    private let PeerServiceType = "camP-services"
    private var serviceAdvertiser : MCNearbyServiceAdvertiser!
    private var serviceBrowser : MCNearbyServiceBrowser?
    var peers:[MCPeerID] = []
    
    public let myPeerId = MCPeerID(displayName: UIDevice.current.name + String(Int.random(in: 1..<1000000)))
    public var invitedToGame=false
    
    // Making optional here so that the (annoying) compiler exception
    // "Property 'self.serviceBrowser' not initialized at super.init call"
    // goes away.  Just Apple (again) asserting its Nazi-like tendencies
    // on developers.
    var session : MCSession?
    
    override init()
    {
        super.init()
    }
    
    public func startNewSession()
    {
        /* The MCNearbyServiceAdvertiser class publishes an advertisement
         for a specific service that your app provides through the Multipeer Connectivity
         framework and notifies its delegate about invitations from nearby peers.*/
        
        self.session = MCSession(peer: self.myPeerId,
                                securityIdentity: nil,
                                encryptionPreference: .required)
        
        self.session?.delegate = self
        
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: self.myPeerId,
                                                           discoveryInfo: nil,
                                                           serviceType: self.PeerServiceType)
        
        self.serviceAdvertiser.delegate = self
        
        self.serviceAdvertiser.startAdvertisingPeer()
        
    }
    
    public func beginBrowsingPeers()
    {
        /* A MCNearbyServiceBrowser searches (by service type) for services
         offered by nearby devices using infrastructure Wi-Fi, peer-to-peer Wi-Fi,
         and Bluetooth (in iOS) or Ethernet (in macOS and tvOS),
         and provides the ability to easily invite those devices to a
         Multipeer Connectivity session */

        self.serviceBrowser = MCNearbyServiceBrowser(peer: self.myPeerId,
                                                     serviceType: self.PeerServiceType)
        self.serviceBrowser?.delegate = self
        self.serviceBrowser?.startBrowsingForPeers()
    }

    // send dimensions of our device screen to the other device
    public func send(frameLength: CGFloat, frameHeight:CGFloat) throws //, prevPos:CGPoint) throws
    {
        let data = CGPoint(x:frameLength, y:frameHeight)
        
        let message = GameMessage(msgType: "dimensions",
                                  data: data)
        
        //serialize the message to JSON in preparation for sending.
        let payload = try JSONEncoder().encode(message)
        
        // send off the message
        try self.session?.send(payload,
                               toPeers: session!.connectedPeers,
                               with: .reliable)
    }
    
    // send player data to other device
    public func send(player: SKSpriteNode) throws //, prevPos:CGPoint) throws
    {
        
        let message = GameMessage(msgType: "player",
                                  data: player.position)
        
        //serialize the message to JSON in preparation for sending.
        let payload = try JSONEncoder().encode(message)
        
        // send off the message
        try self.session?.send(payload,
                               toPeers: session!.connectedPeers,
                               with: .reliable)
    }
    
    // send ball data to other device
    public func send(ball: SKSpriteNode) throws //, prevPos:CGPoint) throws
    {

        let message = GameMessage(msgType: "ball",
                                  data: ball.position)
        
        //serialize the message to JSON in preparation for sending.
        let payload = try JSONEncoder().encode(message)
        
        // send off the JSON message
        try self.session?.send(payload,
                               toPeers: session!.connectedPeers,
                               with: .reliable)
    }
    
}

extension GameServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error)
    {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    // Here, if we find a peer nearby, we will invite that peer to join our session.
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?)
    {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        invitedToGame = false
        browser.invitePeer(peerID, to: self.session!, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID)
    {
        NSLog("%@", "lostPeer: \(peerID)")
        self.delegate?.lostConnection(manager: self, peerID: peerID)
    }
}

extension GameServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error)
    {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
        
    }
    
    // Here, we're receiving an invite to join a session.
    
    //Note: @escaping simply means that the invitationHandler closure is "escaping" the body -
    //      in other words, it will be called in an async fashion sometime later, after the calling
    //      function has already returned.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void)
    {
        
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        
        // keep track of available peers
        if !peers.contains(peerID)
        {
            peers.append(peerID)
        }
        
        // If we're accepting the invite,
        // then we will assume that the other device
        // will handle game start and ball position data
        
        var acceptInv = false
        
        acceptInv = (self.delegate?.gameInvite(manager: self, fromPeerID: peerID))!
        invitedToGame = acceptInv
        
        // Accept the invitation to join the game (join session)
        invitationHandler(acceptInv, self.session)
    }

}

extension GameServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState)
    {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")
    
        self.delegate?.connectedDevicesChanged(manager: self,
             connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    // Handle incoming GameMessage
    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID)
    {
        // Here, we're expecting JSON (text format) that
        // contains the game message...
        NSLog("%@", "didReceiveData: \(data)")
        
        // Deserialize the message from JSON and perform
        // actions according to the message type.
        if let message = try? JSONDecoder().decode(GameMessage.self, from: data)
        {
            NSLog("Incoming message: \(message.msgType)")
            switch message.msgType
            {
                case "ball":
                    NSLog("Ball position.")
                    self.delegate?.ballPositionMsg(manager: self,
                                                   peerID: peerID,
                                                   info: message)
                case "player":
                    NSLog("Player position.")
                    self.delegate?.playerPositionMsg(manager: self,
                                                     peerID: peerID,
                                                     info: message)
                case "dimensions":
                    self.delegate?.deviceDimensions(manager: self,
                                                     peerID: peerID,
                                                     info: message)
                default:
                    NSLog("Invalid message.")
            }
        }
    }
    
    // Here, we can handle real-time streaming; we're not doing anything with streams here.
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID)
    {
        NSLog("%@", "didReceiveStream")
    }
    
    // We can essentially convey progress related to a long-running data transfer, including canceling
    // the transmission, and conveying other details about the ongoing process.
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, with progress: Progress)
    {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    //Here, we can indicate that the transfer of some resource is now finished.
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?)
    {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
}
