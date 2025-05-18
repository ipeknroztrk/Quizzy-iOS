import UIKit
import FirebaseAuth
import Firebase

class LoginViewController: UIViewController {

    
    @IBOutlet weak var emailTextField: UITextField!
    
    
    @IBOutlet weak var passwordTextField: UITextField!

    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Hata", message: "Lütfen tüm alanları doldurun.")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.showAlert(title: "Giriş Hatası", message: error.localizedDescription)
                return
            }

            self.showAlert(title: "Başarılı", message: "Giriş yapıldı ✅") {
                           DispatchQueue.main.async {
                               let storyboard = UIStoryboard(name: "Main", bundle: nil)
                               // Storyboard ID'sini kullanarak EntrySelectionViewController'ı başlatıyoruz
                               if let entrySelectionVC = storyboard.instantiateViewController(withIdentifier: "EntrySelectionVC") as? EntrySelectionViewController {
                                   self.navigationController?.pushViewController(entrySelectionVC, animated: true)
                               }
                           }
                       }
                   }
               }
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Placeholder renklerini beyaz yap
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [.foregroundColor: UIColor.white]
        )

        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Şifre",
            attributes: [.foregroundColor: UIColor.white]
        )

       
       
    }
}
