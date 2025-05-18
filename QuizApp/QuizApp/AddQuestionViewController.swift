import UIKit
import Firebase

class AddQuestionViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: - Outlets
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var questionTextField: UITextField!
    @IBOutlet weak var optionATextField: UITextField!
    @IBOutlet weak var optionBTextField: UITextField!
    @IBOutlet weak var optionCTextField: UITextField!
    @IBOutlet weak var optionDTextField: UITextField!
    @IBOutlet weak var correctAnswerPicker: UIPickerView!

    // MARK: - Properties
    var quizId: String = ""
    var categories: [String] = []
    let correctAnswerOptions = ["A", "B", "C", "D"]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        correctAnswerPicker.delegate = self
        correctAnswerPicker.dataSource = self

        fetchCategoriesFromFirestore()
    }

    // MARK: - Firebase: Kategorileri Al
    func fetchCategoriesFromFirestore() {
        Firestore.firestore().collection("quizzes").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Kategori çekme hatası: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("❌ Quiz dökümanı yok.")
                return
            }

            var categorySet = Set<String>()
            for doc in documents {
                if let category = doc.data()["category"] as? String {
                    categorySet.insert(category)
                }
            }

            self.categories = Array(categorySet)

            DispatchQueue.main.async {
                self.categoryPicker.reloadAllComponents()
                if let firstCategory = self.categories.first {
                    self.categoryPicker.selectRow(0, inComponent: 0, animated: false)
                    self.fetchQuizId(for: firstCategory)
                }
            }
        }
    }

    // MARK: - Firebase: Seçilen Kategoriye Göre Quiz ID Al
    func fetchQuizId(for category: String) {
        let quizzesRef = Firestore.firestore().collection("quizzes")
        quizzesRef.whereField("category", isEqualTo: category).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Quiz ID alma hatası: \(error.localizedDescription)")
                return
            }

            guard let doc = snapshot?.documents.first else {
                print("❌ Bu kategori için quiz yok.")
                return
            }

            self.quizId = doc.documentID
            print("✅ Quiz ID bulundu: \(self.quizId)")
        }
    }

    // MARK: - Soru Kaydetme
    @IBAction func saveQuestionTapped(_ sender: UIButton) {
        guard !quizId.isEmpty else {
            showAlert(title: "Hata", message: "Lütfen önce kategori seçin.")
            return
        }

        guard let questionText = questionTextField.text,
              let a = optionATextField.text,
              let b = optionBTextField.text,
              let c = optionCTextField.text,
              let d = optionDTextField.text,
              !questionText.isEmpty, !a.isEmpty, !b.isEmpty, !c.isEmpty, !d.isEmpty else {
            showAlert(title: "Uyarı", message: "Lütfen tüm alanları doldurun.")
            return
        }

        let correctIndex = correctAnswerPicker.selectedRow(inComponent: 0)
        let correctAnswer = [a, b, c, d][correctIndex]

        let selectedCategoryIndex = categoryPicker.selectedRow(inComponent: 0)
        let selectedCategory = categories[safe: selectedCategoryIndex] ?? "Genel"

        let questionData: [String: Any] = [
            "questionText": questionText,
            "options": [a, b, c, d],
            "correctAnswer": correctAnswer,
            "category": selectedCategory
        ]

        Firestore.firestore()
            .collection("quizzes")
            .document(quizId)
            .collection("questions")
            .addDocument(data: questionData) { error in
                if let error = error {
                    self.showAlert(title: "Hata", message: "Soru eklenemedi: \(error.localizedDescription)")
                } else {
                    self.showAlert(
                        title: "✅ Başarılı",
                        message: "Soru başarıyla eklendi. Yeni bir soru daha eklemek ister misiniz?",
                        actionTitle: "Evet", cancelTitle: "Hayır") {
                        self.clearInputs()
                    }
                }
            }
    }

    // MARK: - Yardımcı Fonksiyonlar
    func clearInputs() {
        questionTextField.text = ""
        optionATextField.text = ""
        optionBTextField.text = ""
        optionCTextField.text = ""
        optionDTextField.text = ""
        correctAnswerPicker.selectRow(0, inComponent: 0, animated: true)
    }

    func showAlert(title: String, message: String, actionTitle: String = "Tamam", cancelTitle: String? = nil, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
            completion?()
        })

        if let cancel = cancelTitle {
            alert.addAction(UIAlertAction(title: cancel, style: .cancel))
        }

        present(alert, animated: true)
    }

    // MARK: - PickerView DataSource & Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerView == categoryPicker ? categories.count : correctAnswerOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        pickerView == categoryPicker ? categories[row] : correctAnswerOptions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == categoryPicker {
            let selectedCategory = categories[row]
            fetchQuizId(for: selectedCategory)
        }
    }
}

// MARK: - Güvenli Array Indexleme
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
