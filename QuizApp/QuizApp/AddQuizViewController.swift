import UIKit
import FirebaseFirestore
import FirebaseAuth

class AddQuizViewController: UIViewController {

    @IBOutlet weak var quizTitleTextField: UITextField!
    @IBOutlet weak var quizDescriptionTextField: UITextField!
    @IBOutlet weak var quizCategoryTextField: UITextField!
    @IBOutlet weak var imageURLTextField: UITextField!
    
    @IBOutlet weak var kategoriyeSoruEkleLabel: UILabel!// Image URL TextField ekliyoruz

    @IBAction func saveQuizButtonTapped(_ sender: UIButton) {
        guard let title = quizTitleTextField.text,
              let description = quizDescriptionTextField.text,
              let category = quizCategoryTextField.text,
              !title.isEmpty, !description.isEmpty, !category.isEmpty else {
            showAlert(title: "Hata", message: "Tüm alanları doldurun.")
            return
        }

        // Image URL'yi alıyoruz
        guard let imageURL = imageURLTextField.text, !imageURL.isEmpty else {
            showAlert(title: "Hata", message: "Lütfen bir image URL girin.")
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Hata", message: "Kullanıcı oturumu yok.")
            return
        }

        // Quiz verisini hazırlıyoruz
        let quizData: [String: Any] = [
            "title": title,
            "description": description,
            "category": category,
            "creatorId": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "imageURL": imageURL // Burada imageURL'yi ekliyoruz
        ]

        let quizCollection = Firestore.firestore().collection("quizzes")
        
        quizCollection.addDocument(data: quizData) { error in
            if let error = error {
                print("Kayıt hatası: \(error.localizedDescription)") // Hata mesajını yazdır
                self.showAlert(title: "Kayıt Hatası", message: error.localizedDescription)
            } else {
                print("Veri başarıyla eklendi.") // Başarı mesajı
                // Başarıyla eklenmişse veriyi çekelim
                quizCollection
                    .whereField("creatorId", isEqualTo: userId)
                    .order(by: "createdAt", descending: true)
                    .limit(to: 1)
                    .getDocuments { snapshot, err in
                        if let err = err {
                            print("ID alma hatası: \(err.localizedDescription)")
                        } else if let doc = snapshot?.documents.first {
                            let quizId = doc.documentID
                            DispatchQueue.main.async {
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                if let addQuestionVC = storyboard.instantiateViewController(withIdentifier: "AddQuestionVC") as? AddQuestionViewController {
                                    addQuestionVC.quizId = quizId
                                    self.navigationController?.pushViewController(addQuestionVC, animated: true)
                                }
                            }
                        }
                    }
                
                // Başarılı ekleme sonrası yeni kategori eklemek isteyip istemediğini soralım
                self.showAddNewCategoryAlert()
            }
        }
    }

    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            completion?()
        })
        present(alertVC, animated: true)
    }

    func showAddNewCategoryAlert() {
        let alert = UIAlertController(title: "Başarılı", message: "Quiz başarıyla eklendi. Yeni bir kategori eklemek ister misiniz?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Evet", style: .default, handler: { _ in
            // Yeni kategori ekleme işlemi yapılacak
            self.addNewCategory()
        }))
        
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }

    func addNewCategory() {
        // Kategori eklemek için yeni kategori adı alınacak
        let alert = UIAlertController(title: "Yeni Kategori", message: "Lütfen yeni kategori adını girin:", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Kategori Adı"
        }
        
        alert.addAction(UIAlertAction(title: "Ekle", style: .default, handler: { _ in
            if let categoryName = alert.textFields?.first?.text, !categoryName.isEmpty {
                self.saveCategoryToFirestore(categoryName: categoryName)
            } else {
                self.showAlert(title: "Hata", message: "Kategori adı boş olamaz.")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }

    func saveCategoryToFirestore(categoryName: String) {
        // Yeni kategoriyi Firestore'a kaydediyoruz
        Firestore.firestore().collection("categories").addDocument(data: ["name": categoryName]) { error in
            if let error = error {
                self.showAlert(title: "Kayıt Hatası", message: error.localizedDescription)
            } else {
                self.showAlert(title: "Başarılı", message: "Yeni kategori başarıyla eklendi.")
                // Kategori ekledikten sonra textfield'ları sıfırlıyoruz
                self.quizCategoryTextField.text = ""
            }
        }
    }
    @objc func kategoriyeSoruEkleTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let questionVC = storyboard.instantiateViewController(withIdentifier: "AddQuestionVC") as? AddQuestionViewController {
            self.navigationController?.pushViewController(questionVC, animated: true)
        }
    }

  
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fullText = "➕ İstediğin kategoriye soru ekle"
        let attributedText = NSMutableAttributedString(string: fullText)

        if let range = fullText.range(of: "soru ekle") {
            let nsRange = NSRange(range, in: fullText)
            attributedText.addAttributes([
                .foregroundColor: UIColor(red: 0.4, green: 0.0, blue: 0.6, alpha: 1.0), // Koyu mor
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: nsRange)
        }

        kategoriyeSoruEkleLabel.attributedText = attributedText
        kategoriyeSoruEkleLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(kategoriyeSoruEkleTapped))
        kategoriyeSoruEkleLabel.addGestureRecognizer(tapGesture)
    }


}
