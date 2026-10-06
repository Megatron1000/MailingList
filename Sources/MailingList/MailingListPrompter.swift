
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

    /// The BridgeTech sign-up endpoint (an AWS Lambda), which holds the Mailgun API key server-side.
    public static let defaultSignUpURL = URL(string: "https://soupcnr7p7.execute-api.us-east-1.amazonaws.com/prod/signup")!

    let suiteName: String
    let appIdentifier: String
    let appName: String
    let signUpURL: URL

    private let emailAddressKey = "emailAddress"
    private let supressMailingListPromptKey = "supressMailingListPrompt1"
    private let registeredAppIdentifiersKey = "registeredAppIdentifiers"
    
    private var mailingListPrompterCompletion: MailingListPrompterCompletion?
        
    private lazy var windowController: NSWindowController = {
        let storyboard = NSStoryboard(name: "MailingList" , bundle: .module)
        return (storyboard.instantiateInitialController() as? NSWindowController) ?? NSWindowController()
    }()
    
    lazy private var signUpService: SignUpService = {
        return SignUpService(signUpURL: self.signUpURL)
    }()
    
    lazy private var defaults: UserDefaults = {
        guard let defaults =  UserDefaults(suiteName: suiteName) else {
            assertionFailure("Unable to initialise user defaults with suite named: \(suiteName)")
            return .standard
        }
        return defaults
    }()
    
    // MARK: Initialisation
    
    public required init(suiteName: String, appIdentifier: String, appName: String, signUpURL: URL = MailingListPrompter.defaultSignUpURL) {
        self.suiteName = suiteName
        self.appIdentifier = appIdentifier
        self.appName = appName
        self.signUpURL = signUpURL
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

        guard registeredAppIdentifiers.contains(appIdentifier) == false else {
            mailingListPrompterCompletion?(.emailAndAppIdentifierAlreadyRegistered(email: email))
            return
        }

        signUpService.signUp(email: email, appIdentifiers: [appIdentifier]) { [weak self] result in

            switch result {
            case .success(_):
                self?.markAppIdentifierRegistered()
                self?.mailingListPrompterCompletion?(.registeredNewAppIdentifier(email: email))

            case .failure(let error):
                self?.mailingListPrompterCompletion?(.failed(email: email, error: error))

            }

        }

    }

    // Shared across apps via the suite, so each app only registers itself with the server once.
    private var registeredAppIdentifiers: Set<String> {
        return Set(defaults.stringArray(forKey: registeredAppIdentifiersKey) ?? [])
    }

    private func markAppIdentifierRegistered() {
        var identifiers = registeredAppIdentifiers
        identifiers.insert(appIdentifier)
        defaults.setValue(identifiers.sorted(), forKey: registeredAppIdentifiersKey)
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
            
            defaults.setValue(email, forKey: emailAddressKey)

            signUpService.signUp(email: email, appIdentifiers: [appIdentifier]) { [weak self] result in

                switch result {
                case .success(.newMember):
                    self?.markAppIdentifierRegistered()
                    self?.mailingListPrompterCompletion?(.signedUp(email: email))

                case .success(.existingMemberUpdated):
                    self?.markAppIdentifierRegistered()
                    self?.mailingListPrompterCompletion?(.registeredNewAppIdentifier(email: email))

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
