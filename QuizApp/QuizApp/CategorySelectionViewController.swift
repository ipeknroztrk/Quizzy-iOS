import UIKit
import FirebaseFirestore
import SDWebImage

class CategorySelectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    var selectedCategory: String?

    var categories: [String] = []
    var categoryImageURLs: [String: String] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        fetchCategoriesFromFirestore()
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let spacing: CGFloat = 10
            layout.minimumLineSpacing = spacing
            layout.minimumInteritemSpacing = spacing
            layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        }
    }

    private func fetchCategoriesFromFirestore() {
        Firestore.firestore().collection("quizzes").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Quiz verisi çekme hatası: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("❌ Hiç quiz bulunamadı.")
                return
            }

            print("📦 Gelen Quiz Belgeleri Sayısı: \(documents.count)")
            
            var fetchedCategories: [String] = []
            var fetchedImageURLs: [String: String] = [:]

            for doc in documents {
                let data = doc.data()
                print("🔍 Document: \(data)")

                guard let categoryName = data["category"] as? String else {
                    print("⛔️ 'category' alanı eksik.")
                    continue
                }

                // imageURL veya imageUrl anahtarı kontrolü
                let imageUrl = data["imageURL"] as? String ?? data["imageUrl"] as? String ?? ""

                if !fetchedCategories.contains(categoryName) {
                    fetchedCategories.append(categoryName)
                    fetchedImageURLs[categoryName] = imageUrl
                }
            }

            self.categories = fetchedCategories
            self.categoryImageURLs = fetchedImageURLs

            print("✅ Yüklenen Kategoriler: \(self.categories)")
            print("🖼 Kategori Görselleri: \(self.categoryImageURLs)")

            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }


    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell

        let category = categories[indexPath.row]
        cell.titleLabel.text = category

        if let urlString = categoryImageURLs[category],
           let url = URL(string: urlString) {
            cell.imageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo"))
        } else {
            cell.imageView.image = UIImage(systemName: "photo")
        }

        cell.layer.cornerRadius = 12
        cell.layer.masksToBounds = false
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.1
        cell.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.layer.shadowRadius = 4

        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = categories[indexPath.row]

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let quizVC = storyboard.instantiateViewController(withIdentifier: "QuizVC") as? QuizViewController {
            quizVC.selectedCategory = category
            self.navigationController?.pushViewController(quizVC, animated: true)
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 10
        let totalSpacing = spacing * 3
        let width = (collectionView.bounds.width - totalSpacing) / 2
        return CGSize(width: width, height: 180)
    }
}
