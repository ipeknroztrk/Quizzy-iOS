import UIKit
import Firebase
import FirebaseAuth

class QuizViewController: UIViewController {

    // MARK: - UI Bağlantıları
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var questionCounterLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!

    @IBOutlet weak var optionAButton: UIButton!
    @IBOutlet weak var optionBButton: UIButton!
    @IBOutlet weak var optionCButton: UIButton!
    @IBOutlet weak var optionDButton: UIButton!
    
    @IBOutlet weak var categoryLabel: UILabel!


    // MARK: - Properties
    var selectedCategory: String?
    var questions: [QuizQuestion] = []
    var currentQuestionIndex: Int = 0

    var correctCount: Int = 0
    var wrongCount: Int = 0

    var timer: Timer?
    var timeRemaining: Int = 30

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchQuestionsForCategory()
        
        categoryLabel.text = "Kategori: \(selectedCategory ?? "-")"

        
       
    }

    // MARK: - Firestore'dan Soru Çekme
    func fetchQuestionsForCategory() {
        guard let selectedCategory = selectedCategory else { return }

        let db = Firestore.firestore()
        db.collection("quizzes")
            .whereField("category", isEqualTo: selectedCategory)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Quiz belgesi hatası: \(error.localizedDescription)")
                    return
                }

                guard let quizDocument = snapshot?.documents.first else {
                    print("Kategoriye ait quiz bulunamadı.")
                    return
                }

                let quizID = quizDocument.documentID
                db.collection("quizzes")
                    .document(quizID)
                    .collection("questions")
                    .getDocuments { questionSnapshot, error in
                        if let error = error {
                            print("Soru çekme hatası: \(error.localizedDescription)")
                            return
                        }

                        guard let documents = questionSnapshot?.documents else { return }

                        self.questions = documents.compactMap { doc in
                            guard
                                let questionText = doc.data()["questionText"] as? String,
                                let correctAnswer = doc.data()["correctAnswer"] as? String,
                                let options = doc.data()["options"] as? [String]
                            else {
                                return nil
                            }

                            return QuizQuestion(question: questionText, options: options, correctAnswer: correctAnswer)
                        }

                        DispatchQueue.main.async {
                            self.loadNextQuestion()
                        }
                    }
            }
    }

    // MARK: - Soru Yükleme
    func loadNextQuestion() {
        resetButtonColors()

        guard currentQuestionIndex < questions.count else {
            saveQuizResultToFirestore() // 🔁 KAYDETME BURADA
            showFinalScore()
            return
        }

        let current = questions[currentQuestionIndex]

        questionLabel.text = current.question
        optionAButton.setTitle(current.options[0], for: .normal)
        optionBButton.setTitle(current.options[1], for: .normal)
        optionCButton.setTitle(current.options[2], for: .normal)
        optionDButton.setTitle(current.options[3], for: .normal)

        questionCounterLabel.text = "Soru \(currentQuestionIndex + 1)/\(questions.count)"
        startTimer()
    }

    // MARK: - Timer
    func startTimer() {
        timeRemaining = 30
        timerLabel.text = "\(timeRemaining)"
        timerLabel.textColor = .label
        progressView.progress = 1.0

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 1
            self.timerLabel.text = "\(self.timeRemaining)"

            if self.timeRemaining <= 5 {
                self.timerLabel.textColor = .systemRed
            } else {
                self.timerLabel.textColor = .label
            }

            let progress = Float(self.timeRemaining) / 30.0
            self.progressView.progress = progress

            if self.timeRemaining <= 0 {
                self.timer?.invalidate()
                self.markAnswer(selected: nil)
            }
        }
    }

    // MARK: - Cevap Kontrol
    @IBAction func optionButtonTapped(_ sender: UIButton) {
        timer?.invalidate()
        markAnswer(selected: sender)
    }

    func markAnswer(selected: UIButton?) {
        let correctAnswer = questions[currentQuestionIndex].correctAnswer
        let buttons = [optionAButton, optionBButton, optionCButton, optionDButton]

        for button in buttons {
            if button?.currentTitle == correctAnswer {
                button?.backgroundColor = .systemGreen
            } else if button == selected {
                button?.backgroundColor = .systemRed
            }
            button?.isEnabled = false
        }

        if let selected = selected, selected.currentTitle == correctAnswer {
            correctCount += 1
        } else {
            wrongCount += 1
        }

        currentQuestionIndex += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.loadNextQuestion()
        }
    }

    func resetButtonColors() {
        let buttons = [optionAButton, optionBButton, optionCButton, optionDButton]
        for button in buttons {
            button?.backgroundColor = .systemGray6
            button?.isEnabled = true
            button?.layer.cornerRadius = 12
            button?.layer.masksToBounds = true
        }
    }

    // MARK: - Sonuç Gösterimi
    func showFinalScore() {
        let alert = UIAlertController(
            title: "Quiz Bitti!",
            message: "✅ Doğru: \(correctCount)\n❌ Yanlış: \(wrongCount)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Sonuçları Gör", style: .default, handler: { _ in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let resultsVC = storyboard.instantiateViewController(withIdentifier: "QuizResultsVC") as? QuizResultsViewController {
                self.navigationController?.pushViewController(resultsVC, animated: true)
            }
        }))

        present(alert, animated: true)
    }

    // MARK: - Firestore’a Quiz Sonucu Kaydet
    func saveQuizResultToFirestore() {
        guard let selectedCategory = selectedCategory else { return }
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Giriş yapmış kullanıcı yok!")
            return
        }

        let db = Firestore.firestore()
        let data: [String: Any] = [
            "category": selectedCategory,
            "correctCount": correctCount,
            "wrongCount": wrongCount,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("users")
            .document(userID)
            .collection("quizResults")
            .addDocument(data: data) { error in
                if let error = error {
                    print("Sonuç kaydedilemedi: \(error.localizedDescription)")
                } else {
                    print("Quiz sonucu başarıyla Firestore'a kaydedildi.")
                }
            }
    }
}
