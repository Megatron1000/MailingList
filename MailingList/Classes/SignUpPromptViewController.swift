//
//  ViewController.swift
//  MailingList
//
//  Created by Mark Bridges on 28/09/2017.
//  Copyright © 2017 Mark Bridges. All rights reserved.
//

import Cocoa

protocol SignUpPromptViewControllerDelegate: class {
    func signUpPromptViewController(signUpPromptViewController: SignUpPromptViewController, didEnterEmail email: String)
}

class SignUpPromptViewController: NSViewController {

    @IBOutlet private var emailAddressTextField: NSTextField? {
        didSet {
            emailAddressTextField?.delegate = self
        }
    }
    
    weak var delegate: SignUpPromptViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

}

extension SignUpPromptViewController: NSTextFieldDelegate {
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        
//        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
//        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluateWithObject(candidate)
        
        delegate?.signUpPromptViewController(signUpPromptViewController: self, didEnterEmail: emailAddressTextField?.stringValue ?? "")
    }
}
