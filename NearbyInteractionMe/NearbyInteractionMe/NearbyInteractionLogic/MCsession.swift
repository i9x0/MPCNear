//
//  MCsession.swift
//  NearbyInteractionMe
//
//  Created by Abu3abd on 25/07/1444 AH.
//

import Foundation
import MultipeerConnectivity
import NearbyInteraction

struct MPSessionConstants {
    static let kKeyIdentity: String = "identity"
}

class MPSession: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate  , ObservableObject {
    var peerDataHandler: ((Data, MCPeerID) -> Void)? // دالة استقبال التوكن
    var peerConnectedHandler: ((MCPeerID) -> Void)? // دالة اعطاء التوكن
    var peerDisconnectedHandler: ((MCPeerID) -> Void)? // دالة قطع اتصال mpc
    
    private let serviceString: String // نوع الخدمة, لكل بث نوع خدمة واحد لكل الأجهزة
    private let mcSession: MCSession
    private let localPeerID = MCPeerID(displayName: UIDevice.current.name) // ID للجهاز اللي مع المستخدم
    private let mcAdvertiser: MCNearbyServiceAdvertiser // يرسل service & perrID & discoveryInfo
    private let mcBrowser: MCNearbyServiceBrowser
    private let identityString: String
    private let maxNumPeers: Int

    init(service: String, identity: String, maxPeers: Int) {
        serviceString = service
        identityString = identity
        mcSession = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: localPeerID,
                                                 discoveryInfo: [MPSessionConstants.kKeyIdentity: identityString],
      // it can include additional information in the discoveryInfo dictionary that other devices can use to identify it and make informed decisions about connecting to it.
      //  an advertiser device could include information about the type of services it offers, the geographic location of the device, or any other relevant information that other devices should know before establishing a connection.
                                                 
                                                 serviceType: serviceString)
        mcBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceString) // هنا يسمع لأي بث ويقول مين انا اللي جالس اسمع
        // you specify the service type that it should search for.
        
        maxNumPeers = maxPeers

        super.init()
        mcSession.delegate = self
        mcAdvertiser.delegate = self
        mcBrowser.delegate = self
    }

   
    func start() {
        mcAdvertiser.startAdvertisingPeer()
        mcBrowser.startBrowsingForPeers()
    }

    func suspend() {
        mcAdvertiser.stopAdvertisingPeer()
        mcBrowser.stopBrowsingForPeers()
    }

    func invalidate() {
        suspend()
        mcSession.disconnect()
    }

    func sendDataToAllPeers(data: Data) {
        sendData(data: data, peers: mcSession.connectedPeers, mode: .reliable)
    }

    func sendData(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode) {
        do {
            try mcSession.send(data, toPeers: peers, with: mode)
        } catch let error {
            NSLog("Error sending data: \(error)")
        }
    }

    // دالة اعطاء التوكن
    private func peerConnected(peerID: MCPeerID) {
        if let handler = peerConnectedHandler {
            DispatchQueue.main.async {
                handler(peerID)
            }
        }
        if mcSession.connectedPeers.count == maxNumPeers {
            self.suspend()
        }
    }
// دالة قطع الاتصال
    private func peerDisconnected(peerID: MCPeerID) {
        if let handler = peerDisconnectedHandler {
            DispatchQueue.main.async {
                handler(peerID)
            }
        }

        if mcSession.connectedPeers.count < maxNumPeers {
            self.start()
        }
    }

    // دالة تشيك عن حالة الاتصال سيتم تفعليها عن انشا اتصال
     func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("state : is connected")
            peerConnected(peerID: peerID)
        case .notConnected:
            print("state : is notconnected")
            peerDisconnected(peerID: peerID)
        case .connecting:
            print("state : is connecting")
            break
        @unknown default:
            fatalError("Unhandled MCSessionState")
        }
    }

     func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let handler = peerDataHandler {
            DispatchQueue.main.async {
                handler(data, peerID)
            }
        }
    }

 

    // MARK: - `MCNearbyServiceBrowserDelegate`.
    
    internal func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard let identityValue = info?[MPSessionConstants.kKeyIdentity] else {
            return
        }
        if identityValue == identityString && mcSession.connectedPeers.count < maxNumPeers {
            browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
        }
    }

     

    // MARK: - `MCNearbyServiceAdvertiserDelegate`.
     func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                             didReceiveInvitationFromPeer peerID: MCPeerID,
                             withContext context: Data?,
                             invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Accept the invitation only if the number of peers is less than the maximum.
        if self.mcSession.connectedPeers.count < maxNumPeers {
            invitationHandler(true, mcSession)
        }
    }
    
    
    
    
    
    
    
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    
     func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

     func session(_ session: MCSession,
                          didStartReceivingResourceWithName resourceName: String,
                          fromPeer peerID: MCPeerID,
                          with progress: Progress) {}

     func session(_ session: MCSession,
                          didFinishReceivingResourceWithName resourceName: String,
                          fromPeer peerID: MCPeerID,
                          at localURL: URL?,
                          withError error: Error?) {}
}


/// class nearby

class MPNSession : NSObject, NISessionDelegate, ObservableObject{
    enum DistanceDirectionState {
           case closeUpInFOV, notCloseUpInFOV, outOfFOV, unknown
       }
    @Published var deviseName : String?
    @Published var details : String?
    @Published var distanceN : String?
    @Published var diractionN : String?
    @Published var monky : String?
    let nearbyDistanceThreshold: Float = 0.3
        var session: NISession?
        var peerDiscoveryToken: NIDiscoveryToken?
        var currentDistanceDirectionState: DistanceDirectionState = .unknown
        var mpc: MPSession?
        var connectedPeer: MCPeerID?
        var sharedTokenWithPeer = false
        var peerDisplayName: String?
    
    override init(){
        super.init()
        startup()
        
    }
    func startup() {
           // Create the NISession.
           print("dubug 1")
           session = NISession()
           print("debug : \(String(describing: session))")
           // Set the delegate.
           session?.delegate = self
           print("dubug 2")
           // Because the session is new, reset the token-shared flag.
           sharedTokenWithPeer = false
           print("debug : \(String(describing: session))")
           // If `connectedPeer` exists, share the discovery token, if needed.
           if connectedPeer != nil && mpc != nil {
               print("dubug 3 \(String(describing: mpc))   \n \(String(describing: connectedPeer))")
               if let myToken = session?.discoveryToken {
                   print("debug 4 \(myToken)")
                   print( "Initializing ...")
   //                if !sharedTokenWithPeer { // ممكن الغيه
                       shareMyDiscoveryToken(token: myToken)
   //                }
                   guard let peerToken = peerDiscoveryToken else {
                       return
                   }
                   print("dubug 5 \(peerToken)")
                   let config = NINearbyPeerConfiguration(peerToken: peerToken)
                   print("dubug 6 \(config)")
                   session?.run(config)
               } else {
                   fatalError("Unable to get self discovery token, is this session invalidated?")
               }
           } else {
               print( "Discovering Peer ...")
               startupMPC()
               
               // Set the display state.
               currentDistanceDirectionState = .unknown
           }
       }
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
            guard let peerToken = peerDiscoveryToken else {
                fatalError("don't have peer token")
            }
            // الجهاز الثاني
            print("dubug 7 \(peerToken)")
            // Find the right peer.
            let peerObj = nearbyObjects.first { (obj) -> Bool in
                return obj.discoveryToken == peerToken
            }
            // peerobj have distance and diraction
            print("dubug 8 \(String(describing: peerObj))")
            guard let nearbyObjectUpdate = peerObj else {
                return
            }

            // Update the the state and visualizations.
            let nextState = getDistanceDirectionState(from: nearbyObjectUpdate)
            updateVisualization(from: currentDistanceDirectionState, to: nextState, with: nearbyObjectUpdate)
            currentDistanceDirectionState = nextState
            print("dubug 9 \(nextState)")
        }
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
           guard let peerToken = peerDiscoveryToken else {
               fatalError("don't have peer token")
           }
           print("dubug 10 \(peerToken)")
           // Find the right peer.
           let peerObj = nearbyObjects.first { (obj) -> Bool in
               return obj.discoveryToken == peerToken
           }
           print("dubug 11 \(String(describing: peerObj))")
           if peerObj == nil {
               return
           }

           currentDistanceDirectionState = .unknown

           switch reason {
           case .peerEnded:
               // The peer token is no longer valid.
               peerDiscoveryToken = nil
               
               // The peer stopped communicating, so invalidate the session because
               // it's finished.
               session.invalidate()
               
               // Restart the sequence to see if the peer comes back.
               startup()
               
               // Update the app's display.
               details = "Peer Ended"
           case .timeout:
               print("debug in time out section in reason switch")
               // The peer timed out, but the session is valid.
               // If the configuration is valid, run the session again.
               if let config = session.configuration {
                   session.run(config)
                   print("dubug 12 \(config)")}
              
               details = "Peer Timeout"
           default:
               fatalError("Unknown and unhandled NINearbyObject.RemovalReason")
           }
       }
    func sessionWasSuspended(_ session: NISession) {
            currentDistanceDirectionState = .unknown
        details = "Session suspended"
            print("dubug 13")
        }

        func sessionSuspensionEnded(_ session: NISession) {
            // Session suspension ended. The session can now be run again.
            if let config = self.session?.configuration {
                session.run(config)
                print("dubug 14 \(config)")
            } else {
                // Create a valid configuration.
                startup()
            }
            print("debug 15 \(String(describing: peerDisplayName))")
            
           deviseName = peerDisplayName
        }
    func session(_ session: NISession, didInvalidateWith error: Error) {
           currentDistanceDirectionState = .unknown

           // If the app lacks user approval for Nearby Interaction, present
           // an option to go to Settings where the user can update the access.
           print("debug 16 ")
           if case NIError.userDidNotAllow = error {
               print("debug 17 ")
               if #available(iOS 15.0, *) {
                   print("debug 18 ")
                   // In iOS 15.0, Settings persists Nearby Interaction access.
                   details =  "Nearby Interactions access required. You can change access for NIPeekaboo in Settings."
                   // Create an alert that directs the user to Settings.
                   let accessAlert = UIAlertController(title: "Access Required",
                                                       message: """
                                                       NIPeekaboo requires access to Nearby Interactions for this sample app.
                                                       Use this string to explain to users which functionality will be enabled if they change
                                                       Nearby Interactions access in Settings.
                                                       """,
                                                       preferredStyle: .alert)
                   accessAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                   accessAlert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: {_ in
                       // Send the user to the app's Settings to update Nearby Interactions access.
                       if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                           UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                       }
                   }))

                   // Display the alert.
                 //  print("debug 19 \(accessAlert) ")
                   //present(accessAlert, animated: true, completion: nil)
               } else {
                   // Before iOS 15.0, ask the user to restart the app so the
                   // framework can ask for Nearby Interaction access again.
                   print("debug 20 ")
                   details = "Nearby Interactions access required. Restart NIPeekaboo to allow access."
               }

               return
           }
           print("debug 21 ")
           // Recreate a valid session.
           startup()
       }
    func startupMPC() {
//        if mpc == nil { // ممكن الغيه بعد التأكد من اني احتاج اكثر من سيشن
            // Prevent Simulator from finding devices.
            #if targetEnvironment(simulator)
            mpc = MPSession(service: "nisample", identity: "com.example.apple-samplecode.simulator.peekaboo-nearbyinteraction", maxPeers: 4)
        print("debug 21.5 \(String(describing: mpc)) ")
            #else
            mpc = MPSession(service: "nisample", identity: "com.example.apple-samplecode.peekaboo-nearbyinteraction", maxPeers: 4)
        print("debug 22 \(String(describing: mpc)) ")
            #endif
            mpc?.peerConnectedHandler = connectedToPeer
        print("debug 23 \(String(describing: connectedPeer)) ")
            mpc?.peerDataHandler = dataReceivedHandler
        print("debug 24 \(String(describing: dataReceivedHandler)) ")
            mpc?.peerDisconnectedHandler = disconnectedFromPeer
        print("debug 25 \(String(describing: disconnectedFromPeer))")
//        }
        mpc?.invalidate()
        mpc?.start()
    }
    func connectedToPeer(peer: MCPeerID) {
            guard let myToken = session?.discoveryToken else {
                fatalError("Unexpectedly failed to initialize nearby interaction session.")
            }
    print("debug 26 \(myToken)")
    //        if connectedPeer != nil { // ممكن الغيه
    //            fatalError("Already connected to a peer.")
    //        }
    //        if !sharedTokenWithPeer {
                shareMyDiscoveryToken(token: myToken)
    //        }
    // الجاهز الثاني
            connectedPeer = peer
            print("debug 27 \(peer)")
            peerDisplayName = peer.displayName
            print("debug 28 \(String(describing: peerDisplayName))")

           
            deviseName = peerDisplayName
        }

        func disconnectedFromPeer(peer: MCPeerID) {
    //        if connectedPeer == peer {
                connectedPeer = nil
                sharedTokenWithPeer = false
    //        }
        }
    func dataReceivedHandler(data: Data, peer: MCPeerID) {
          guard let discoveryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
              fatalError("Unexpectedly failed to decode discovery token.")
          }
          // الجهاز الثاني
          print("debug 29 \(discoveryToken)")
          peerDidShareDiscoveryToken(peer: peer, token: discoveryToken)
      }

      func shareMyDiscoveryToken(token: NIDiscoveryToken) {
          guard let encodedData = try?  NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
              fatalError("Unexpectedly failed to encode discovery token.")
          }
          // الجهاز الثاني
          print("debug 30 \(encodedData)")
          mpc?.sendDataToAllPeers(data: encodedData)
          sharedTokenWithPeer = true
      }
    func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {

           // Create a configuration.
           // الجهاز الثاني
           peerDiscoveryToken = token
           print("debug 31 \(String(describing: peerDiscoveryToken))")
           let config = NINearbyPeerConfiguration(peerToken: token)
           print("debug 32 \(config)")
           // Run the session.
           session?.run(config)
       }

       // MARK: - Visualizations
       func isNearby(_ distance: Float) -> Bool {
           print("debug 33 \(distance < nearbyDistanceThreshold)")
           return distance < nearbyDistanceThreshold
       }

       func isPointingAt(_ angleRad: Float) -> Bool {
           print("debug 34 \(abs(angleRad.radiansToDegrees) <= 15)")
           // Consider the range -15 to +15 to be "pointing at".
           return abs(angleRad.radiansToDegrees) <= 15
       }
    func getDistanceDirectionState(from nearbyObject: NINearbyObject) -> DistanceDirectionState {
            if nearbyObject.distance == nil && nearbyObject.direction == nil {
                return .unknown
            }

            let isNearby = nearbyObject.distance.map(isNearby(_:)) ?? false
            let directionAvailable = nearbyObject.direction != nil

            if isNearby && directionAvailable {
                return .closeUpInFOV
            }

            if !isNearby && directionAvailable {
                return .notCloseUpInFOV
            }

            return .outOfFOV
        }
    private func animate(from currentState: DistanceDirectionState, to nextState: DistanceDirectionState, with peer: NINearbyObject) {
            let azimuth = peer.direction.map(azimuth(from:))
            let elevation = peer.direction.map(elevation(from:))
            
            print("debug 35 \(String(describing: azimuth))")
            print("debug 36 \(String(describing: elevation))")
            deviseName = peerDisplayName
            
            
            // If the app transitions from unavailable, present the app's display
            // and hide the user instructions.
        
//            if currentState == .unknown && nextState != .unknown {
//                monkeyLabel.alpha = 1.0
//                centerInformationLabel.alpha = 0.0
//                detailContainer.alpha = 1.0
//            }
//
//            if nextState == .unknown {
//                monkeyLabel.alpha = 0.0
//                centerInformationLabel.alpha = 1.0
//                detailContainer.alpha = 0.0
//            }
//
//            if nextState == .outOfFOV || nextState == .unknown {
//                detailAngleInfoView.alpha = 0.0
//            } else {
//                detailAngleInfoView.alpha = 1.0
//            }
            
            // Set the app's display based on peer state.
            switch nextState {
            case .closeUpInFOV:
                monky = "🙉"
            case .notCloseUpInFOV:
                monky = "🙈"
            case .outOfFOV:
                monky = "🙊"
            case .unknown:
                monky = ""
            }
         
            if peer.distance != nil {
                distanceN = String(format: "%0.2f m", peer.distance!)
                // المسافة
                print("debug 37 \(String(format: "%0.2f m", peer.distance!))")
            }
            
//            monky.transform = CGAffineTransform(rotationAngle: CGFloat(azimuth ?? 0.0))
            
            // Don't update visuals if the peer device is unavailable or out of the
            // U1 chip's field of view.
            if nextState == .outOfFOV || nextState == .unknown {
                return
            }
            // important
//            if elevation != nil {
//                if elevation! < 0 {
//                    detailDownArrow.alpha = 1.0
//                    detailUpArrow.alpha = 0.0
//                } else {
//                    detailDownArrow.alpha = 0.0
//                    detailUpArrow.alpha = 1.0
//                }
//
//                if isPointingAt(elevation!) {
//                    detailElevationLabel.alpha = 1.0
//                } else {
//                    detailElevationLabel.alpha = 0.5
//                }
//                detailElevationLabel.text = String(format: "% 3.0f°", elevation!.radiansToDegrees)
                // الاتجاه
                print("debug 38 \(String(format: "% 3.0f°", elevation!.radiansToDegrees))")
            }
            
//            if azimuth != nil {
//                if isPointingAt(azimuth!) {
//                    detailAzimuthLabel.alpha = 1.0
//                    detailLeftArrow.alpha = 0.25
//                    detailRightArrow.alpha = 0.25
//                } else {
//                    detailAzimuthLabel.alpha = 0.5
//                    if azimuth! < 0 {
//                        detailLeftArrow.alpha = 1.0
//                        detailRightArrow.alpha = 0.25
//                    } else {
//                        detailLeftArrow.alpha = 0.25
//                        detailRightArrow.alpha = 1.0
//                    }
//                }
//                detailAzimuthLabel.text = String(format: "% 3.0f°", azimuth!.radiansToDegrees)
//                // الاتجاه
//                print("debug 39 \(String(format: "% 3.0f°", azimuth!.radiansToDegrees))")
//
//            }
        
        
        func updateVisualization(from currentState: DistanceDirectionState, to nextState: DistanceDirectionState, with peer: NINearbyObject) {
            // Invoke haptics on "peekaboo" or on the first measurement.
            if currentState == .notCloseUpInFOV && nextState == .closeUpInFOV || currentState == .unknown {
                
            }

            // Animate into the next visuals.
            UIView.animate(withDuration: 0.3, animations: {
                self.animate(from: currentState, to: nextState, with: peer)
            })
        }
//    func updateInformationLabel(description: String) {
//            UIView.animate(withDuration: 0.3, animations: {
//                self.monkeyLabel.alpha = 0.0
//                self.detailContainer.alpha = 0.0
//                self.centerInformationLabel.alpha = 1.0
//                self.centerInformationLabel.text = description
//            })
//        }
}
