import UIKit

class EntrySelectionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
       
       

       
    }

    @IBAction func addQuizTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addQuizVC = storyboard.instantiateViewController(withIdentifier: "AddQuizVC") as? AddQuizViewController {
            self.navigationController?.pushViewController(addQuizVC, animated: true)
        }
    }

    @IBAction func addQuestionTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addQuestionVC = storyboard.instantiateViewController(withIdentifier: "AddQuestionVC") as? AddQuestionViewController {
            self.navigationController?.pushViewController(addQuestionVC, animated: true)
        }
    }

    @IBAction func addCategorySelectionTapped(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addQuestionVC = storyboard.instantiateViewController(withIdentifier: "CategorySelectionVC") as? CategorySelectionViewController {
            self.navigationController?.pushViewController(addQuestionVC, animated: true)
        }
    }
    
    @IBAction func showQuizResultsTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let quizResultsVC = storyboard.instantiateViewController(withIdentifier: "QuizResultsVC") as? QuizResultsViewController {
            self.navigationController?.pushViewController(quizResultsVC, animated: true)
        } else {
            print("QuizResultsVC bulunamadı.")
        }
    }

}
