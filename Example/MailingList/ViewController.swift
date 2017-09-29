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
    
    let mailingListPrompter = MailingListPrompter(suiteName: "com.bridgetech.mailinglist",
                                                  apiKey: "key-8394b3e3e9ae7586abc1ff93d95451d1",
                                                  domain: "mailgun.bridgetech.io",
                                                  bundleIdentifier: Bundle.main.bundleIdentifier!)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mailingListPrompter.showPromptIfNecessary()
                
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

