//
//  MPCManager.swift
//  MPCRevisited
//
//  Created by Fernando Augusto de Marins on 20/07/16.
//  Copyright © 2016 Appcoda. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol MPCManagerDelegate {
    func foundPeer()
    func lostPeer()
    func invitationWasReceived(fromPeer: String)
    func connectedWithPeer(peerID: MCPeerID)
}

class MPCManager:  NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    var session: MCSession!
    var peer: MCPeerID!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    var invitationHandler: ((Bool, MCSession!) -> Void)!
    
    var delegate: MPCManagerDelegate?
    
    override init() {
        super.init()
        
        peer = MCPeerID(displayName: UIDevice.currentDevice().name)
        
        session = MCSession(peer: peer)
        session.delegate = self
        
        // The second one is a value that can’t be changed after the initialization, 
        // and it regards the service type that the browser should browse for. 
        // In simple words, it uniquely identifies the application among others 
        // so the MPC knows what to search for, and the same service type value
        // must be set to the advertiser as well (you’ll see that in just a second)
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "appcoda-mpc")
        browser.delegate = self
        
        // If you change serviceType in browser please change it here, as well
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "appcoda-mpc")
        advertiser.delegate = self
    }
    
    // The first and most important action we must take, is to add the found 
    // peer in the foundPeers array. Later, we are going to use this array as 
    // the datasource of the tableview in the ViewController class, where we 
    // will list all the found peers. So, once we do so, we make a call to the 
    // foundPeer delegate method of the MPCManagerDelegate protocol. This delegate 
    // method will be implemented in the ViewController class (in the next part), 
    // and in there we’ll reload the tableview data so the newly found peer to be displayed to the user
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        foundPeers.append(peerID)
        
        delegate?.foundPeer()
    }
    
    // No much to say here, as the code explains itself pretty well I think. 
    // At first we locate the peer that was lost in the foundPeers array, and 
    // then we remove it. After having done so and the peer is no longer in our 
    // “list”, we must notify the ViewController class so it updates the tableview
    // with the displayed peers. For that reason, we call the lostPeer delegate 
    // method, in which later during its implementation we’ll reload the tableview data
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        for (index, aPeer) in foundPeers.enumerate() {
            if aPeer == peerID {
                foundPeers.removeAtIndex(index)
                break
            }
        }
        
        delegate?.lostPeer()
    }
    
    // Displaying errors
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print(error.localizedDescription)
    }

}
