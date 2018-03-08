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

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let username = XMPPJID(string: txtUserJID.text! + "@example.com", resource: "mobile")!
        let password = txtPasswordJID.text!
        AppDelegate.sharedInstance.prepareStreamAndLogInWithJID(jid: username, password: password)
    }
}

