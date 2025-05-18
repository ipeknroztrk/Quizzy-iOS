import UIKit

class CategoryCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
           super.awakeFromNib()
           imageView.contentMode = .scaleAspectFill
           imageView.clipsToBounds = true
       }
}
