
import AppKit

final public class MailingListPrompter {
    
    public enum MailingListPromptResult {
        case signedUp(email: String)
        case registeredNewAppIdentifier(email: String)
        case emailAndAppIdentifierAlreadyRegistered(email: String)
        case failed(email: String, error: Error)
        case didntSignUp
        case suppressed
    }
    
    public typealias MailingListPrompterCompletion = ((MailingListPromptResult) -> ())
    
    let suiteName: String
    let apiKey: String
    let domain: String
    let appIdentifier: String
    let appName: String
    
    private let emailAddressKey = "emailAddress"
    private let supressMailingListPromptKey = "supressMailingListPrompt1"
    
    private var mailingListPrompterCompletion: MailingListPrompterCompletion?
        
    private lazy var windowController: NSWindowController = {
        let storyboard = NSStoryboard(name: "MailingList" , bundle: .module)
        return (storyboard.instantiateInitialController() as? NSWindowController) ?? NSWindowController()
    }()
    
    lazy private var mailingListService: MailGunService = {
        return MailGunService(apiKey: self.apiKey, domain: self.domain)
    }()
    
    lazy private var defaults: UserDefaults = {
        guard let defaults =  UserDefaults(suiteName: suiteName) else {
            assertionFailure("Unable to initialise user defaults with suite named: \(suiteName)")
            return .standard
        }
        return defaults
    }()
    
    // MARK: Initialisation
    
    public required init(suiteName: String, apiKey: String, domain: String, appIdentifier: String, appName: String) {
        self.suiteName = suiteName
        self.apiKey = apiKey
        self.domain = domain
        self.appIdentifier = appIdentifier
        self.appName = appName
    }
    
    public func showPromptIfNecessary(completion: @escaping MailingListPrompterCompletion) {
        
        mailingListPrompterCompletion = completion
        
        if CommandLine.arguments.contains("-force-show-mailing-list") {
            showSignUpWindow()
            return
        }
        
        if let existingEmail = defaults.string(forKey: emailAddressKey) {
            addAppIdentifier(toEmail: existingEmail)
        }
        else if defaults.bool(forKey: supressMailingListPromptKey) != true {
            showSignUpWindow()
        }
        else {
            mailingListPrompterCompletion?(.suppressed)
        }
        
    }
    
    private func showSignUpWindow() {
        guard
            let viewController = (windowController.contentViewController as? SignUpPromptViewController) else {
            assertionFailure("Unexpected view controller type")
            return
        }
        viewController.delegate = self
        viewController.appName = appName
        
        windowController.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func addAppIdentifier(toEmail email: String) {
        
        mailingListService.getMember(forEmail: email) { [weak self] result in
            
            switch result {
            case .success(let member):
                self?.addAppIdentifier(toMember: member)
                
            case .failure(let error):
                self?.mailingListPrompterCompletion?(.failed(email: email, error: error))
                
            }
            
        }
        
    }
    
    private func addAppIdentifier(toMember member: Member) {
        
        if member.appIdentifiers.contains(appIdentifier) == false {
            
            var newIdentifiers = member.appIdentifiers
            newIdentifiers.insert(appIdentifier)
            
            let updatedMember = Member(address: member.address, appIdentifiers: newIdentifiers)
            
            mailingListService.updateMember(updatedMember, withCompletion: { [weak self] result in
                
                switch result {
                case .success():
                    self?.mailingListPrompterCompletion?(.registeredNewAppIdentifier(email: member.address))
                    
                case .failure(let error):
                    self?.mailingListPrompterCompletion?(.failed(email: member.address, error: error))
                    
                }
                
            })
        }
        else {
            mailingListPrompterCompletion?(.emailAndAppIdentifierAlreadyRegistered(email: member.address))
        }
    }
    
}

extension MailingListPrompter: SignUpPromptViewControllerDelegate {
    
    func signUpPromptViewController(signUpPromptViewController: SignUpPromptViewController, didFinishedWithState state: SignUpPromptViewController.SignUpState) {
        
        switch state {
        case .didSignUp(let email):
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            guard NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) else {
                print("Email doesn't appear to be valid: \(email)")
                return
            }
            
            let member = Member(address: email, appIdentifiers: Set([appIdentifier]))
            defaults.setValue(email, forKey: emailAddressKey)
            
            mailingListService.addMember(member) { [weak self] result in
                
                switch result {
                case .success():
                    self?.mailingListPrompterCompletion?(.signedUp(email: email))
                    
                case .failure(let error):
                    self?.mailingListPrompterCompletion?(.failed(email: email, error: error))
                    
                }
                
            }
            
        case .dismissed(let suppressedFuturePrompts):
            
            if suppressedFuturePrompts {
                defaults.setValue(true, forKey: supressMailingListPromptKey)
            }
            
            if defaults.value(forKey: emailAddressKey) == nil {
                mailingListPrompterCompletion?(.didntSignUp)
            }
            
        }
        
    }
    
    
    
}
