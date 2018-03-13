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

class XMPPSendMessageViewController: UIViewController, XMPPStreamCustomDelegate, UITableViewDelegate, UITableViewDataSource  {

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
        AppDelegate.sharedInstance.xmppStreamCustom = self
        
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
            AppDelegate.sharedInstance.xmppStream.send(message)
        }
        txtRecipient.resignFirstResponder()
        txtMessage.text = ""
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
        
        let fullPath = URL(fileURLWithPath: AudioManager.sharedInstance.searchDocumentsDirectory()).appendingPathComponent(nameFile)
        
        if (xmppOutgoingFileTransfer != nil){
            xmppOutgoingFileTransfer.deactivate()
            xmppOutgoingFileTransfer = nil
        }
        
        xmppOutgoingFileTransfer = XMPPOutgoingFileTransfer(dispatchQueue: DispatchQueue.main)
        xmppOutgoingFileTransfer.activate(AppDelegate.sharedInstance.xmppStream)
//        xmppOutgoingFileTransfer.disableIBB = false
//        xmppOutgoingFileTransfer.disableSOCKS5 = true
        xmppOutgoingFileTransfer.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        do {

            let dataAudio = try Data(contentsOf: fullPath)
            let recipientJID = XMPPJID(string: txtRecipient.text! + "@example.com", resource: "mobile")
            try xmppOutgoingFileTransfer.send(dataAudio, named: nameFile, toRecipient: recipientJID, description: "AUDIO")

        } catch let error {
            fatalError(error.localizedDescription)
        }
        
    }
    
    // DELEGATE XMPPSTREAM RECEIVE MESSAGE
    func didReceiveMessage(user: StructUser) {
        arrayUser.add(user)
        self.tableViewMessage.reloadData()
    }
    
    // DELEGATE TABLE VIEWS
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

extension XMPPSendMessageViewController: XMPPOutgoingFileTransferDelegate {
    
    //DELEGATE OUTGOING
    func xmppOutgoingFileTransfer(_ sender: XMPPOutgoingFileTransfer!, didFailWithError error: Error!) {
        print("Outgoing file transfer failed with error:", error)
    }
    
    func xmppOutgoingFileTransferDidSucceed(_ sender: XMPPOutgoingFileTransfer!) {
        print("File transfer successful.", sender)
    }
}

extension XMPPSendMessageViewController: XMPPMessageCellDelegate {
    
    func btnPlayAudioPressed(indexRow: Int) {
        
        let data = arrayUser[indexRow] as! StructUser
        let urlAudio = URL(string: data.message)!
        AudioManager.sharedInstance.playAudio(url: urlAudio)
    }
    
}
