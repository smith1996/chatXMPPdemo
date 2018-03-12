//
//  AppDelegate.swift
//  chatXMPPdemo
//
//  Created by Smith Huamani on 28/02/18.
//  Copyright © 2018 Smith Huamani. All rights reserved.
//

import UIKit
import XMPPFramework
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let sharedInstance = AppDelegate()
    
    var window: UIWindow?
    
    var xmppStream:XMPPStream!
    var xmppRoster:XMPPRoster!
    var xmppRosterStorage:XMPPRosterMemoryStorage!
    var xmppIncomingFileTransfer:XMPPIncomingFileTransfer!
    
    var password:String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        IQKeyboardManager.sharedManager().enable = true

        return true
    }
    
    func prepareStreamAndLogInWithJID(jid:XMPPJID, password:String){
        
        print("Preparing the stream and logging in as " + jid.full())
        xmppStream = XMPPStream()
        xmppStream.hostName = "192.168.1.159"
        xmppStream.hostPort = 5222
        xmppStream.startTLSPolicy = .allowed
        xmppStream.myJID = jid


        xmppRosterStorage = XMPPRosterMemoryStorage()
        xmppRoster = XMPPRoster(rosterStorage: xmppRosterStorage)
        xmppRoster.autoFetchRoster = true
        
        xmppIncomingFileTransfer = XMPPIncomingFileTransfer()
        xmppIncomingFileTransfer.disableIBB = false
        xmppIncomingFileTransfer.disableSOCKS5 = false
        
        // Activate all modules
        xmppRoster.activate(xmppStream)
        xmppIncomingFileTransfer.activate(xmppStream)
        
        // Add ourselves as delegate to necessary methods
        xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppIncomingFileTransfer.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        self.password = password
        connect()
    }
    
    func connect() {
        
        //TRUE = cuando esta desconectado && FALSE = esta conectado
        guard xmppStream.isDisconnected() else {
            print("La sesion esta desconectado")
            return
        }
        
        do {
            try xmppStream.connect(withTimeout: XMPPStreamTimeoutNone)//30
            
        } catch let error as NSError {
            fatalError("Error connecting: " + error.debugDescription)
        }
    }
    
    deinit {
        print("----------------------- PRINTEO DE INIT - REMOVER TODO LOS OBJECTOS DE XMPP -----------------------")
        self.tearDownStream()
    }
    
    func tearDownStream(){
        
        xmppStream.removeDelegate(self)
        xmppIncomingFileTransfer.removeDelegate(self)
        xmppRoster.deactivate()
        xmppIncomingFileTransfer.deactivate()
        xmppStream.disconnect()
        xmppStream = nil
        xmppRoster = nil
        xmppRosterStorage = nil
        xmppIncomingFileTransfer = nil
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

extension AppDelegate: XMPPStreamDelegate, XMPPIncomingFileTransferDelegate {
    
    //DELEGATE STREAM
    func xmppStreamDidConnect(_ sender: XMPPStream) {
        print("Connected successfully.")
        print("Logging in as " + sender.myJID.full())
        do {
            try xmppStream.authenticate(withPassword: password)
        } catch let error as NSError  {
            fatalError("Error authenticating: " + error.debugDescription);
        }
    }
    
    func xmppStreamDidRegister(_ sender: XMPPStream!) {
        print("registered !!")
        
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        print("Authenticated successfully.")
        let presence = XMPPPresence()
//        let domain = xmppStream.myJID.domain
//
//        if domain == "@example.com" {
//            let priority = DDXMLElement.element(withName: "", stringValue: "24") as! DDXMLElement
//            presence?.addChild(priority)
//        }
        xmppStream.send(presence)

        print(xmppStream.isConnecting(), "ESTADO DE CONNECTING DEL STREAM")
        print(xmppStream.isAuthenticating(), "ESTADO DE AUTHENTICATING DEL STREAM")
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
        fatalError("Stream disconnected with error: " + error.debugDescription)
    }
    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: XMLElement) {
        fatalError("Authentication failed with error: " + error.debugDescription)
    }
    
    
    //DELEGATE INCOMINGFILETRANSFER
    func xmppIncomingFileTransfer(_ sender: XMPPIncomingFileTransfer, didFailWithError error: Error?) {
        fatalError("Incoming file transfer failed with error: " + error.debugDescription)
    }
    
    func xmppIncomingFileTransfer(_ sender: XMPPIncomingFileTransfer, didReceiveSIOffer offer: XMPPIQ) {
        print("Incoming file transfer did receive SI offer. Accepting...")
//        sender.acceptSIOffer(offer)
        sender.autoAcceptFileTransfers = true
        let data = offer.parseData(offer.name)
        
        print(data?.base64EncodedString() as Any)
    }
    
    func xmppIncomingFileTransfer(_ sender: XMPPIncomingFileTransfer, didSucceedWith data: Data, named name: String) {
        
        print("Incoming file transfer did succeed.")
        let paths: [Any] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let fullPath = URL(fileURLWithPath: paths.last as! String).appendingPathComponent(name)
        do {
            try
                data.write(to: fullPath, options: [])
        } catch let error as NSError  {
            fatalError("Could not sendFile \(error), \(error.userInfo)")
        }
        print("Data was written to the path: " + fullPath.absoluteString)
    }
    
}

