import Foundation

/// Signs up to the mailing list through the BridgeTech sign-up endpoint (an AWS Lambda),
/// which holds the Mailgun API key server-side. Apps must never talk to Mailgun directly.
final class SignUpService {

    enum SignUpOutcome {
        case newMember
        case existingMemberUpdated
    }

    let httpClient: HTTPClient
    let signUpURL: URL

    // MARK: Initialisation

    required init(httpClient: HTTPClient = HTTPClient(), signUpURL: URL) {
        self.httpClient = httpClient
        self.signUpURL = signUpURL
    }

    // MARK: Calls

    /// Adds the email to the list, or merges the app identifiers into an existing member.
    func signUp(email: String, appIdentifiers: Set<String>, withCompletion completion: @escaping (( Result<SignUpOutcome, Error>) -> Void)) {

        let body = ["email": email, "appIdentifiers": appIdentifiers.sorted()] as [String : Any]

        var request = URLRequest(url: signUpURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        catch {
            completion(.failure(error))
            return
        }

        httpClient.makeNetworkRequest(with: request, completion: { result in

            switch result {
            case .success((_, let response)):
                completion(.success(response.statusCode == 201 ? .newMember : .existingMemberUpdated))

            case .failure(let error):
                completion(.failure(error))
            }

        })
    }

}
