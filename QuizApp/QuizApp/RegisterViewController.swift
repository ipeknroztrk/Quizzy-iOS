import UIKit
import Firebase
import FirebaseAuth

class RegisterViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginLinkLabel: UILabel! // 👉 "Hesabın var mı? Giriş Yap" etiketi

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoginLabelTap()
        usernameTextField.attributedPlaceholder = NSAttributedString(
            string: "Kullanıcı Adı",
            attributes: [.foregroundColor: UIColor.white]
        )

        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [.foregroundColor: UIColor.white]
        )

        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Şifre",
            attributes: [.foregroundColor: UIColor.white]
        )

    }

    // MARK: - Kayıt İşlemi
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              let username = usernameTextField.text,
              !email.isEmpty, !password.isEmpty, !username.isEmpty else {
            showAlert(title: "Hata", message: "Tüm alanları doldurmalısınız!")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.showAlert(title: "Kayıt Hatası", message: error.localizedDescription)
                return
            }

            guard let uid = result?.user.uid else { return }

            let userData: [String: Any] = [
                "email": email,
                "username": username,
                "createdAt": FieldValue.serverTimestamp()
            ]

            Firestore.firestore().collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    self.showAlert(title: "Firestore Hatası", message: error.localizedDescription)
                } else {
                    self.showAlert(title: "Başarılı", message: "Kayıt başarıyla tamamlandı ✅") {
                        self.navigateToLogin()
                    }
                }
            }
        }
    }

    // MARK: - "Giriş Yap" Link Etkisi
    func setupLoginLabelTap() {
        let fullText = "Hesabın var mı? Giriş Yap"
            let attributedString = NSMutableAttributedString(string: fullText)

            let linkRange = (fullText as NSString).range(of: "Giriş Yap")

        let whiteColor = UIColor.white
        attributedString.addAttribute(.foregroundColor, value: whiteColor, range: linkRange)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: linkRange)


        loginLinkLabel.attributedText = attributedString
        loginLinkLabel.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(navigateToLogin))
        loginLinkLabel.addGestureRecognizer(tapGesture)
    }

    @objc func navigateToLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginViewController {
            self.navigationController?.pushViewController(loginVC, animated: true)
        }
    }

    // MARK: - Alert Göster
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true)
    }
}
