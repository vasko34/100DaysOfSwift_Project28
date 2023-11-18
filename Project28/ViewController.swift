import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    @IBOutlet var secret: UITextView!
    var password = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        password = KeychainWrapper.standard.string(forKey: "password") ?? ""
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
        
        title = "Nothing to see here"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveSecretMessage))
        navigationItem.rightBarButtonItem?.isHidden = true
    }
    
    @IBAction func authenticateTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "Please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            if password == "" {
                let ac1 = UIAlertController(title: "Create password:", message: nil, preferredStyle: .alert)
                ac1.addTextField()
                ac1.addAction(UIAlertAction(title: "Done", style: .default) { [weak self, weak ac1] _ in
                    if let textField1 = ac1?.textFields?[0].text {
                        let ac2 = UIAlertController(title: "Confirm password", message: nil, preferredStyle: .alert)
                        ac2.addTextField()
                        ac2.addAction(UIAlertAction(title: "Done", style: .default) { [weak self, weak ac2] _ in
                            if let textFiled2 = ac2?.textFields?[0].text {
                                if textField1 == textFiled2 {
                                    self?.password = textField1
                                    self?.unlockSecretMessage()
                                } else {
                                    let ac3 = UIAlertController(title: "Passwords didn't match", message: "Please try again.", preferredStyle: .alert)
                                    ac3.addAction(UIAlertAction(title: "OK", style: .default))
                                    self?.present(ac3, animated: true)
                                }
                            }
                        })
                        self?.present(ac2, animated: true)
                    }
                })
                present(ac1, animated: true)
            } else {
                let ac = UIAlertController(title: "Enter password:", message: nil, preferredStyle: .alert)
                ac.addTextField()
                ac.addAction(UIAlertAction(title: "Done", style: .default) { [weak self, weak ac] _ in
                    if let textField = ac?.textFields?[0].text {
                        if let password = self?.password {
                            if password == textField {
                                self?.unlockSecretMessage()
                            } else {
                                let ac3 = UIAlertController(title: "Wrong password!", message: nil, preferredStyle: .alert)
                                ac3.addAction(UIAlertAction(title: "OK", style: .default))
                                self?.present(ac3, animated: true)
                            }
                        }
                    }
                })
                present(ac, animated: true)
            }
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        secret.scrollRangeToVisible(secret.selectedRange)
    }
    
    @objc func saveSecretMessage() {
        guard !secret.isHidden else { return }
        
        KeychainWrapper.standard.set(secret.text, forKey: "secretMessage")
        KeychainWrapper.standard.set(password, forKey: "password")
        secret.resignFirstResponder()
        secret.isHidden = true
        navigationItem.rightBarButtonItem?.isHidden = true
        title = "Nothing to see here"
    }
    
    func unlockSecretMessage() {
        secret.isHidden = false
        navigationItem.rightBarButtonItem?.isHidden = false
        title = "Secret stuff"
        
        secret.text = KeychainWrapper.standard.string(forKey: "secretMessage") ?? ""
    }
}

