import Cocoa

public class MailingListPrompter {
    
    let suiteName: String
    let apiKey: String
    let domain: String
    let appIdentifier: String
    
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
    
    public required init(suiteName: String, apiKey: String, domain: String, appIdentifier: String) {
        self.suiteName = suiteName
        self.apiKey = apiKey
        self.domain = domain
        self.appIdentifier = appIdentifier
    }
    
    public func showPromptIfNecessary() {
        
        if let existingEmail = defaults.string(forKey: emailAddressKey) {
            addAppIdentifier(toEmail: existingEmail)
        }
        else {
        
            let storyboard = NSStoryboard(name: NSStoryboard.Name("MailingList") , bundle: Bundle(for: MailingListPrompter.self))
            let windowController = storyboard.instantiateInitialController() as! NSWindowController
            (windowController.contentViewController as! SignUpPromptViewController).delegate = self
            
            windowController.window?.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
        }
        
    }
    
    private func addAppIdentifier(toEmail email: String) {
        
        mailingListService.getMember(forEmail: email) { [weak self] result in
            
            switch result {
            case .success(let member):
                self?.addAppIdentifier(toMember: member)
                
            case .failure(let error):
                break
                
            }
            
        }
        
    }
    
    private func addAppIdentifier(toMember member: Member) {
        
        if member.appIdentifiers.contains(appIdentifier) == false {
            
            var newIdentifiers = member.appIdentifiers
            newIdentifiers.insert(appIdentifier)
            
            let updatedMember = Member(address: member.address, appIdentifiers: newIdentifiers)
            
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
        
        let member = Member(address: email, appIdentifiers: Set([appIdentifier]))
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
