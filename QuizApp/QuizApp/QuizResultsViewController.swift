import UIKit
import Firebase
import FirebaseAuth

class QuizResultsViewController: UITableViewController {

    var quizResults: [QuizResult] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchQuizResults()
        
       


    }

    func fetchQuizResults() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Kullanıcı oturumu bulunamadı.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("quizResults")
            .order(by: "timestamp", descending: true)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Veriler alınamadı: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("Belge bulunamadı.")
                    return
                }

                self.quizResults = documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let category = data["category"] as? String,
                        let correctCount = data["correctCount"] as? Int,
                        let wrongCount = data["wrongCount"] as? Int,
                        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
                    else {
                        return nil
                    }

                    return QuizResult(category: category, correctCount: correctCount, wrongCount: wrongCount, timestamp: timestamp)
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quizResults.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuizResultCell", for: indexPath)
        let result = quizResults[indexPath.row]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy - HH:mm"

        cell.textLabel?.text = "\(result.category) - \(dateFormatter.string(from: result.timestamp))"
        cell.detailTextLabel?.text = "✅ Doğru: \(result.correctCount) | ❌ Yanlış: \(result.wrongCount)"
        
      
        return cell
    }

}
