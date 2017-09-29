import Cocoa

public class MailingListPrompter {
    
    let suiteName: String
    let apiKey: String
    let domain: String
    let bundleIdentifier: String
    
    private let emailAddressKey = "emailAddress"
    
    lazy private var mailingListService: MailGunService = {
        return MailGunService(apiKey: self.apiKey, domain: self.domain)
    }()
    
    lazy private var defaults: UserDefaults = {
        guard let defaults =  UserDefaults(suiteName: suiteName) else {
            fatalError("Unabled to initialise user defaults with suite named: \(suiteName)")
        }
        return defaults
    }()
    
    // MARK: Initialisation
    
    public required init(suiteName: String, apiKey: String, domain: String, bundleIdentifier: String) {
        self.suiteName = suiteName
        self.apiKey = apiKey
        self.domain = domain
        self.bundleIdentifier = bundleIdentifier
    }
    
    public func showPromptIfNecessary() {
        
        if let existingEmail = defaults.string(forKey: emailAddressKey) {
            addBundleIdentifier(toEmail: existingEmail)
        }
        else {
            
            let storyboard = NSStoryboard(name: NSStoryboard.Name("MailingList") , bundle: Bundle(for: MailingListPrompter.self))
            let windowController = storyboard.instantiateInitialController() as! NSWindowController
            (windowController.contentViewController as! SignUpPromptViewController).delegate = self
            
            windowController.window?.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
        }
        
    }
    
    private func addBundleIdentifier(toEmail email: String) {
        
        let bundleIdentifier = self.bundleIdentifier
        
        mailingListService.getMember(forEmail: email) { [weak self] result in
            
            switch result {
            case .success(let member):
                self?.addBundleIdentifier(toMember: member)
                
            case .failure(let error):
                break
                
            }
            
        }
        
    }
    
    private func addBundleIdentifier(toMember member: Member) {
        
        if member.bundleIdentifiers.contains(bundleIdentifier) == false {
            
            var newIdentifiers = member.bundleIdentifiers
            newIdentifiers.insert(bundleIdentifier)
            
            let updatedMember = Member(address: member.address, bundleIdentifiers: newIdentifiers)
            
            mailingListService.updateMember(updatedMember, withCompletion: { result in
                
                switch result {
                case .success():
                    break
                    
                case .failure(let error):
                    break
                    
                }
                
            })
        }
    }
    
}

extension MailingListPrompter: SignUpPromptViewControllerDelegate {
    
    func signUpPromptViewController(signUpPromptViewController: SignUpPromptViewController, didEnterEmail email: String) {
        
        let member = Member(address: email, bundleIdentifiers: Set([bundleIdentifier]))
        defaults.setValue(email, forKey: emailAddressKey)
        
        mailingListService.addMember(member) { result in
            
            switch result {
            case .success():
                break
                
            case .failure(let error):
                break
                
            }
            
        }
        
    }
    
}
