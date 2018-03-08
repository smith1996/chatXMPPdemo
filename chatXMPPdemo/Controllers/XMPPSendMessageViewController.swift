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
    
    let xmppRosterStorage = XMPPRosterCoreDataStorage()
    var xmppRoster: XMPPRoster!
    var stream: XMPPStream!
    var xmppIncomingFileTransfer: XMPPIncomingFileTransfer!
    var fileTransfer: XMPPOutgoingFileTransfer!

    var arrayUser: NSMutableArray = []
    
    var audioRecorder: AVAudioRecorder!
    var isRecording = false
    var nameFile = ""
    var status = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        xmppRoster = XMPPRoster(rosterStorage: xmppRosterStorage)

        stream = AppDelegate.sharedInstance.setupXMPP()
        stream.myJID = XMPPJID(string: userJID, resource: "mobile")
        stream.addDelegate(self, delegateQueue: DispatchQueue.main)
        connectServer()

        xmppRoster.activate(stream)

        AudioManager.sharedInstance.setup()

        tableViewMessage.delegate = self
        tableViewMessage.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func connectServer() {
        if !stream.isConnected() {
            
            do {
                try stream.connect(withTimeout: XMPPStreamTimeoutNone)
                
            } catch let fecthErrpr as NSError {
                print("Ocurrio un error en la conexion", fecthErrpr.description)
            }
        }
    }

    @IBAction func btnSendMessagePressed() {
        
//        guard AppDelegate.sharedInstance.xmppStream.isConnected() else {
//
//            do {
//                try AppDelegate.sharedInstance.xmppStream.connect(withTimeout: XMPPStreamTimeoutNone)
//            } catch let error as NSError {
//                fatalError("Ocurrio un error en la conexion: " + error.description)
//            }
//            return
//        }
//
//        guard AppDelegate.sharedInstance.xmppStream.isAuthenticated() else {
//            fatalError("Ocurrio un error en autenticacion")
//            return
//        }
//
//        let senderJID = XMPPJID(string: txtRecipient.text! + "@example.com")
//        let msg = XMPPMessage(type: "chat", to: senderJID)!
//
//        msg.addBody(txtMessage.text!)
//        stream.send(msg)
//
//        txtRecipient.text = ""
//        txtMessage.text = ""
//        txtRecipient.resignFirstResponder()
        
        if !stream.isConnected() {

            do {
                try stream.connect(withTimeout: XMPPStreamTimeoutNone)

            } catch let fecthErrpr as NSError {
                print("Ocurrio un error en la conexion", fecthErrpr.description)
            }
        } else {

            print("Esta conectado el usuario")
            let senderJID = XMPPJID(string: txtRecipient.text! + "@example.com")
            let msg = XMPPMessage(type: "chat", to: senderJID)!

            msg.addBody(txtMessage.text!)
            stream.send(msg)

            txtRecipient.text = ""
            txtMessage.text = ""
            txtRecipient.resignFirstResponder()

        }
    }
    
    @IBAction func btnVoiceRecoderPressed() {
//        print("TAB 1")
        
        if txtRecipient.text != "" && isRecording == false {
//            print("Empezar a grabar")
            nameFile = "Audio_" + UUID().uuidString + ".m4a"
            AudioManager.sharedInstance.startRecording(fileName: nameFile)
            isRecording = true
            btnVoiceSend.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        }
        
    }
    
    @IBAction func btnSendVoicePressed() {
        
        if isRecording {
//            print("Parar grabaradora")
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

        if !stream.isConnected() {
            
            do {
                try stream.connect(withTimeout: XMPPStreamTimeoutNone)
                
            } catch let fecthErrpr as NSError {
                print("Ocurrio un error en la conexion", fecthErrpr.description)
            }
        } else {
            
            print("Esta conectado el usuario - AUDIO DE VOZ")
            setupInconmingFileTransfer()
            
            if !(fileTransfer != nil){
                fileTransfer = XMPPOutgoingFileTransfer(dispatchQueue: DispatchQueue.main)
                fileTransfer?.activate(stream)
                fileTransfer?.disableDirectTransfers = false
                fileTransfer?.disableIBB = false
                fileTransfer?.disableSOCKS5 = false
                fileTransfer?.addDelegate(self, delegateQueue: DispatchQueue.main)
            }
            
            do {
                
                let dataAudio = try Data(contentsOf: fullPath)
                let recipientJID = XMPPJID(string: txtRecipient.text! + "@example.com", resource: "mobile")
                fileTransfer?.blockSize = gl_int32_t(dataAudio.hashValue)
                print(dataAudio, nameFile, recipientJID!)
                try fileTransfer?.send(dataAudio, named: nameFile, toRecipient: recipientJID, description: "AUDIO")
                
            } catch let error {
                fatalError(error.localizedDescription)
            }
            
            txtRecipient.text = ""
        }
    }
    
    func setupInconmingFileTransfer() {
        
        xmppIncomingFileTransfer = XMPPIncomingFileTransfer()
        xmppIncomingFileTransfer?.disableDirectTransfers = false
        xmppIncomingFileTransfer?.disableIBB = false
        xmppIncomingFileTransfer?.disableSOCKS5 = false
        xmppIncomingFileTransfer?.activate(stream)
        xmppIncomingFileTransfer?.addDelegate(self, delegateQueue: DispatchQueue.main)
    
    }

}

extension XMPPSendMessageViewController: XMPPIncomingFileTransferDelegate, XMPPOutgoingFileTransferDelegate {
    
    //DELEGATE INCOMING
    func xmppIncomingFileTransfer(_ sender: XMPPIncomingFileTransfer!, didFailWithError error: Error!) {
        print("Incoming file transfer failed with error: ", error)
    }
    
    func xmppIncomingFileTransfer(_ sender: XMPPIncomingFileTransfer!, didReceiveSIOffer offer: XMPPIQ!) {
        
//        if status == true {
//
//            fileTransfer?.deactivate()
//            fileTransfer = nil
//        }
//
//        status = true
        print(xmppIncomingFileTransfer?.autoAcceptFileTransfers as Any, "STATUS DE FILE")
//        sender.autoAcceptFileTransfers = true
        print("Incoming file transfer did receive SI offer. Accepting...", offer)
        sender.acceptSIOffer(offer)
        xmppIncomingFileTransfer?.deactivate()
        fileTransfer?.deactivate()
    }
    
    func xmppIncomingFileTransfer(_ sender: XMPPIncomingFileTransfer!, didSucceedWith data: Data!, named name: String!) {
        print("Incoming file transfer did succeed.", data, name)
    }
    
    //DELEGATE OUTGOING
    func xmppOutgoingFileTransfer(_ sender: XMPPOutgoingFileTransfer!, didFailWithError error: Error!) {
        print("Outgoing file transfer failed with error:", error)
    }
    
    func xmppOutgoingFileTransferDidSucceed(_ sender: XMPPOutgoingFileTransfer!) {
        print("File transfer successful.", sender)
    }
    
//    func turnSocket(_ sender: TURNSocket!, didSucceed socket: GCDAsyncSocket!) {
//        print(socket)
//    }
//
//    func turnSocketDidFail(_ sender: TURNSocket!) {
//        print("TURN Connection failed!")
//        print(sender)
//    }
}

extension XMPPSendMessageViewController: XMPPStreamDelegate {
    
    func xmppStream(_ sender: XMPPStream!, willReceive iq: XMPPIQ!) -> XMPPIQ! {
//        print("Se desactiva el FILTE TRANSFER")

//        if status == true {
//            
//            fileTransfer?.deactivate()
//            fileTransfer = nil
//        }
        
        print("willReceive")
//        print(iq)
        return iq
    }
    
    func xmppStreamDidConnect(_ sender: XMPPStream!) {
        print("Connected")
        
        do {
            try sender.authenticate(withPassword: passwordJID)
        } catch {
            print("catch")
        }
        
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        print("Authenticate")
        sender.send(XMPPPresence())
        
    }
    
    func xmppStream(_ sender: XMPPStream!, socketDidConnect socket: GCDAsyncSocket!) {
        print(socket)
    }
    
    func xmppStreamWillConnect(_ sender: XMPPStream!) {
        print(sender, sender.description)
    }
    
    func xmppStream(_ sender: XMPPStream!, willSend iq: XMPPIQ!) -> XMPPIQ! {
        print("willSend")
//        print(iq)
        
        
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
        
//        let xmp = XMPPIQ(xmlString: iq.xmlString)
//        xmp.
        print(iq)
        return true
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceive message: XMPPMessage!) {
        print("didReceive message")
        print(message)
        var user: StructUser = StructUser()
        user.sender = String(describing: message.from()!).replacingOccurrences(of: "/mobile", with: "")
        user.recipient = String(describing: message.to()!).replacingOccurrences(of: "/mobile", with: "")
        user.message = String(describing: message.body()!)
        
        print(user.sender, user.recipient, user.message)

        arrayUser.add(user)
        
        self.tableViewMessage.reloadData()
    }

    func xmppStream(_ sender: XMPPStream!, didReceive presence: XMPPPresence!) {
        print(presence)

        let presentType = presence.type()
        let username = sender.myJID.user
        let presentFromUser = presence.from().user

        print(presentType!, username!, presentFromUser!)

//        if presentFromUser != username {
//
//            if presentType == "available" {
//
//                print("available")
//            }
//        } else if presentType == "subscribe" {
//            xmppRoster.subscribePresence(toUser: presence.from())
//        } else {
//            print("precent type: ", presentType)
//        }
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

//        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) else {
//            print("Error cell")
//        }

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
