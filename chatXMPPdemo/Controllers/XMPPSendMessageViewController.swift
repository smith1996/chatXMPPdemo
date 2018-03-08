//
//  XMPPSendMessageViewController.swift
//  chatXMPPdemo
//
//  Created by Smith Huamani on 28/02/18.
//  Copyright © 2018 Smith Huamani. All rights reserved.
//

import UIKit
import XMPPFramework
import AVFoundation

class XMPPSendMessageViewController: UIViewController {

    @IBOutlet weak var tableViewMessage: UITableView!

    @IBOutlet weak var btnVoiceSend: UIButton!
    @IBOutlet weak var txtRecipient: UITextField!
    @IBOutlet weak var txtMessage: UITextField!

    var userJID = ""
    var passwordJID = ""
    
    var xmppOutgoingFileTransfer: XMPPOutgoingFileTransfer!

    var arrayUser: NSMutableArray = []
    var audioRecorder: AVAudioRecorder!
    var isRecording = false
    var nameFile = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        AudioManager.sharedInstance.setup()

        tableViewMessage.delegate = self
        tableViewMessage.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func validateAccount() {
        
        guard AppDelegate.sharedInstance.xmppStream.isConnected() else {
            
            do {
                try AppDelegate.sharedInstance.xmppStream.connect(withTimeout: XMPPStreamTimeoutNone)
            } catch let error as NSError {
                fatalError("Ocurrio un error en la conexion: " + error.description)
            }
            return
        }
        
        guard AppDelegate.sharedInstance.xmppStream.isAuthenticated() else {
            print("Ocurrio un error en la autenticacion")
            return
        }
        
    }
    
    @IBAction func btnSendMessagePressed() {
        
        validateAccount()
        
        if txtRecipient.text! != "" && txtMessage.text! != "" {
            
            let senderJID = XMPPJID(string: txtRecipient.text! + "@example.com")
            let message = XMPPMessage(type: "chat", to: senderJID)!
            
            message.addBody(txtMessage.text!)
            AppDelegate.sharedInstance.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
            AppDelegate.sharedInstance.xmppStream.send(message)
            
            txtRecipient.text = ""
            txtMessage.text = ""
        }
        
        txtRecipient.resignFirstResponder()

    }
    
    @IBAction func btnVoiceRecoderPressed() {
        
        validateAccount()

        if txtRecipient.text != "" && isRecording == false {
            
            nameFile = "Audio_" + UUID().uuidString + ".m4a"
            AudioManager.sharedInstance.startRecording(fileName: nameFile)
            isRecording = true
            btnVoiceSend.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        }
        
    }
    
    @IBAction func btnSendVoicePressed() {
        
        if isRecording {
            
            AudioManager.sharedInstance.finishRecording()
            isRecording = false
            btnVoiceSend.backgroundColor = #colorLiteral(red: 0.4211294055, green: 0.7796598077, blue: 0.9402769208, alpha: 1)
            txtRecipient.resignFirstResponder()
            
            sendingPathAudioTransferFile()
        }
        
    }
    
    func sendingPathAudioTransferFile() {
        
        //example: let nameFile = "Audio_" + UUID().uuidString + ".m4a"
        let fullPath = URL(fileURLWithPath: AudioManager.sharedInstance.searchDocumentsDirectory()).appendingPathComponent(nameFile)
        
        if !(xmppOutgoingFileTransfer != nil){
            
            xmppOutgoingFileTransfer = XMPPOutgoingFileTransfer(dispatchQueue: DispatchQueue.main)
            xmppOutgoingFileTransfer.activate(AppDelegate.sharedInstance.xmppStream)
            xmppOutgoingFileTransfer.disableDirectTransfers = false
            xmppOutgoingFileTransfer.disableIBB = false
            xmppOutgoingFileTransfer.disableSOCKS5 = false
            xmppOutgoingFileTransfer.addDelegate(self, delegateQueue: DispatchQueue.main)
        }
        
        do {
            
            let dataAudio = try Data(contentsOf: fullPath)
            let recipientJID = XMPPJID(string: txtRecipient.text! + "@example.com", resource: "mobile")
            xmppOutgoingFileTransfer?.blockSize = gl_int32_t(dataAudio.hashValue)
            print(dataAudio, nameFile, recipientJID!, xmppOutgoingFileTransfer.blockSize)
            try xmppOutgoingFileTransfer.send(dataAudio, named: nameFile, toRecipient: recipientJID, description: "AUDIO")
            
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        txtRecipient.text = ""
    }
    
}

extension XMPPSendMessageViewController: /*XMPPIncomingFileTransferDelegate, */XMPPOutgoingFileTransferDelegate {
    
    //DELEGATE OUTGOING
    func xmppOutgoingFileTransfer(_ sender: XMPPOutgoingFileTransfer!, didFailWithError error: Error!) {
        print("Outgoing file transfer failed with error:", error)
    }
    
    func xmppOutgoingFileTransferDidSucceed(_ sender: XMPPOutgoingFileTransfer!) {
        print("File transfer successful.", sender)
    }
}

extension XMPPSendMessageViewController: XMPPStreamDelegate {
    
    func xmppStream(_ sender: XMPPStream!, willReceive iq: XMPPIQ!) -> XMPPIQ! {

        print("willReceive")
        return iq
    }
    
    func xmppStream(_ sender: XMPPStream!, socketDidConnect socket: GCDAsyncSocket!) {
        print(socket)
    }
    
    func xmppStreamWillConnect(_ sender: XMPPStream!) {
        print(sender, sender.description)
    }
    
    func xmppStream(_ sender: XMPPStream!, willSend iq: XMPPIQ!) -> XMPPIQ! {
        print("willSend")
        
        return iq
    }
    
    func xmppStream(_ sender: XMPPStream!, willSend message: XMPPMessage!) -> XMPPMessage! {
        print("willSend message")
        print(message)
        return message
    }
    
    func xmppStream(_ sender: XMPPStream!, willSend presence: XMPPPresence!) -> XMPPPresence! {
        print(presence)
        return presence
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceive iq: XMPPIQ!) -> Bool {
        print("didReceive - RECIBE EL XML DEL DESTINATARIO \(txtRecipient.text!)")
        print(iq)
        return true
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceive message: XMPPMessage!) {
        
        print("didReceive message")
        print(message)
        
        validateAccount()
        
        if AppDelegate.sharedInstance.xmppStream.myJID == message.from() {
            
            var user: StructUser = StructUser()
            user.sender = String(describing: message.from()!).replacingOccurrences(of: "/mobile", with: "")
            user.recipient = String(describing: message.to()!).replacingOccurrences(of: "/mobile", with: "")
            user.message = String(describing: message.body()!)
            
            print(user.sender, user.recipient, user.message)
            
            arrayUser.add(user)
            
            self.tableViewMessage.reloadData()
            
        }
        
    }

    func xmppStream(_ sender: XMPPStream!, didReceive presence: XMPPPresence!) {
        print(presence)
    }
    
    func xmppStream(_ sender: XMPPStream!, didSend message: XMPPMessage!) {
        
        print("didSend message")
        print(message)
    }
    
    func xmppStream(_ sender: XMPPStream!, didSend iq: XMPPIQ!) {
        
        print("didSend - ENVIA EL XML AL DESTINATARIO")
        print(iq)
        
    }
    
    func xmppStream(_ sender: XMPPStream!, didFailToSend iq: XMPPIQ!, error: Error!) {
        print(error, iq)
    }
    
    func xmppStream(_ sender: XMPPStream!, didFailToSend message: XMPPMessage!, error: Error!) {
        print(error, message)
    }
    
    func xmppStream(_ sender: XMPPStream!, didFailToSend presence: XMPPPresence!, error: Error!) {
        print(error, presence)
    }
}

extension XMPPSendMessageViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayUser.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! XMPPMessageCell
        configureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }

    func configureCell(cell: XMPPMessageCell, indexPath: IndexPath) {
        
        let user = arrayUser[indexPath.row] as! StructUser
        cell.messageCellDelegate = self
        cell.lblUser.text = user.sender
        if user.message.contains("file:///") || user.message.contains("m4a") {
            cell.lblMessage.isHidden = true
            cell.btnPlay.isHidden = false
        }else {
            cell.lblMessage.isHidden = false
            cell.btnPlay.isHidden = true
        }
        cell.lblMessage.text = user.message
        cell.btnPlay.tag = indexPath.row
        
    }

}

extension XMPPSendMessageViewController: XMPPMessageCellDelegate {
    
    func btnPlayAudioPressed(indexRow: Int) {
        
        let data = arrayUser[indexRow] as! StructUser
        let urlAudio = URL(string: data.message)!
        AudioManager.sharedInstance.playAudio(url: urlAudio)
    }
    
}
