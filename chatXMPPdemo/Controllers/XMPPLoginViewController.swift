//
//  ViewController.swift
//  chatXMPPdemo
//
//  Created by Smith Huamani on 28/02/18.
//  Copyright © 2018 Smith Huamani. All rights reserved.
//

import UIKit
import XMPPFramework

class XMPPLoginViewController: UIViewController {

    @IBOutlet weak var txtUserJID: UITextField!
    @IBOutlet weak var txtPasswordJID: UITextField!
    
    var stream: XMPPStream!

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        stream = AppDelegate.sharedInstance.setupXMPP()
        
    }

    @IBAction func btnLoginPressed() {

//        stream.myJID = XMPPJID(string: txtUserJID.text! + "@example.com", resource: "mobile")
//        stream.addDelegate(self, delegateQueue: DispatchQueue.main)

//        connectXMPP()
        
    }

    func connectXMPP() {
        
        if !stream.isConnected() {
            
            do {
                try stream.connect(withTimeout: XMPPStreamTimeoutNone)//XMPPStreamTimeoutNone
                
            } catch {
                print("Ocurrio un error en la conexion")
            }
        }else {
            
            print("Esta conectado el usuario")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let username = XMPPJID(string: txtUserJID.text! + "@example.com", resource: "mobile")!
        let password = txtPasswordJID.text!
        AppDelegate.sharedInstance.prepareStreamAndLogInWithJID(jid: username, password: password)
        
    }
}

extension XMPPLoginViewController: XMPPStreamDelegate {

    func xmppStreamWillConnect(_ sender: XMPPStream!) {
        print("Will Connect")
    }

    func xmppStreamConnectDidTimeout(_ sender: XMPPStream!) {
        print("time out: ")
    }

    func xmppStreamDidConnect(_ sender: XMPPStream!) {
        print("Connected")

        do {
            try sender.authenticate(withPassword: txtPasswordJID.text!)
        } catch {
            print("catch")
        }

    }
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        print("Authenticate")
        sender.send(XMPPPresence())
        
        let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "XMPPSendMessageViewController") as! XMPPSendMessageViewController
        vc.userJID = txtUserJID.text! + "@example.com"
        vc.passwordJID = txtPasswordJID.text!
        self.navigationController?.pushViewController(vc, animated: true)
        
    }


}

