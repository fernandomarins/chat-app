//
//  ChatViewController.swift
//  MPCRevisited
//
//  Created by Gabriel Theodoropoulos on 11/1/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var txtChat: UITextField!
    @IBOutlet weak var tblChat: UITableView!
    
    var messagesArray: [Dictionary<String, String>] = []
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tblChat.delegate = self
        tblChat.dataSource = self
        
        tblChat.estimatedRowHeight = 60.0
        tblChat.rowHeight = UITableViewAutomaticDimension

        txtChat.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.handleMPCReceivedDataWithNotification(_:)), name: "receivedMPCDataNotification", object: nil)
    }
    
    // MARK: IBAction method implementation
    @IBAction func endChat(sender: AnyObject) {
        let messageDictionary: [String: String] = ["message": "_end_chat_"]
        if appDelegate.mpcManager.sendData(dictionaryWithData: messageDictionary, toPeer: appDelegate.mpcManager.session.connectedPeers[0] as MCPeerID) {
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.appDelegate.mpcManager.session.disconnect()
            })
        }
    }
    
    // MARK: UITableView related method implementation
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArray.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("idCell")! as UITableViewCell
        
        let currentMessage = messagesArray[indexPath.row] as Dictionary<String, String>
        
        if let sender = currentMessage["sender"] {
            var senderLabelText: String
            var senderColor: UIColor
            
            if sender == "self"{
                senderLabelText = "I said:"
                senderColor = UIColor.purpleColor()
            }
            else{
                senderLabelText = sender + " said:"
                senderColor = UIColor.orangeColor()
            }
            
            cell.detailTextLabel?.text = senderLabelText
            cell.detailTextLabel?.textColor = senderColor
        }
        
        if let message = currentMessage["message"] {
            cell.textLabel?.text = message
        }
        
        return cell
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        let messageDictionary: [String: String] = ["message": textField.text!]
        
        if appDelegate.mpcManager.sendData(dictionaryWithData: messageDictionary, toPeer: appDelegate.mpcManager.session.connectedPeers[0] as MCPeerID) {
            
            let dictionary: [String: String] = ["sender": "self", "message": textField.text!]
            messagesArray.append(dictionary)
            
            updateTableview()
            
        } else {
            
            print("Could not send data")
            
        }
        
        textField.text = ""
        
        return true
    }
    
    func updateTableview(){
        tblChat.reloadData()
        
        if tblChat.contentSize.height > tblChat.frame.size.height {
            tblChat.scrollToRowAtIndexPath(NSIndexPath(forRow: messagesArray.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
    }
    
    func handleMPCReceivedDataWithNotification(notification: NSNotification) {
        // Get the dictionary containing the data and the source peer from the notification.
        let receivedDataDictionary = notification.object as! Dictionary<String, AnyObject>
        
        // "Extract" the data and the source peer from the received dictionary.
        let data = receivedDataDictionary["data"] as? NSData
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
        
        // Convert the data (NSData) into a Dictionary object.
        let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! Dictionary<String, String>
        
        // Check if there's an entry with the "message" key.
        if let message = dataDictionary["message"] {
            // Make sure that the message is other than "_end_chat_".
            if message != "_end_chat_"{
                // Create a new dictionary and set the sender and the received message to it.
                let messageDictionary: [String: String] = ["sender": fromPeer.displayName, "message": message]
                
                // Add this dictionary to the messagesArray array.
                messagesArray.append(messageDictionary)
                
                // Reload the tableview data and scroll to the bottom using the main thread.
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.updateTableview()
                })
            }
            else {
                // In this case an "_end_chat_" message was received.
                // Show an alert view to the user.
                let alert = UIAlertController(title: "", message: "\(fromPeer.displayName) ended this chat.", preferredStyle: UIAlertControllerStyle.Alert)
                
                let doneAction: UIAlertAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
                    self.appDelegate.mpcManager.session.disconnect()
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                
                alert.addAction(doneAction)
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.presentViewController(alert, animated: true, completion: nil)
                })
            }
        }
    }
    
}
