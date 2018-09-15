//
//  ViewController.swift
//  MailingList
//
//  Created by Mark Bridges on 28/09/2017.
//  Copyright © 2017 Mark Bridges. All rights reserved.
//

import Cocoa
import MailingList

class ViewController: NSViewController {
    
    let mailingListPrompter = MailingListPrompter(suiteName: "the user default suite's identifier",
                                                  apiKey: "your mailgun api key",
                                                  domain: "the mailgun api",
                                                  appIdentifier: Bundle.main.bundleIdentifier!,
                                                  appName: Bundle.main.displayName!
                                                  )

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mailingListPrompter.showPromptIfNecessary(completion: { result in
            
            switch result {
                
            case .signedUp(let email):
                print(email)
                break
                
            case .registeredNewAppIdentifier(let email):
                print(email)
                break
                
            case .emailAndAppIdentifierAlreadyRegistered(let email):
                print(email)
                break
                
            case .failed(let email, let error):
                print(email)
                print(error)
                break
                
            case .didntSignUp:
                break
                
            case .suppressed:
                break
                
            }
            
        })
    }

}

