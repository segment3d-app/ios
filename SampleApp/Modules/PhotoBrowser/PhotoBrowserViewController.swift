//
//  PhotoBrowserViewController.swift
//  MetalSplatter SampleApp
//
//  Created by I Made Indra Mahaarta on 21/05/24.
//

import UIKit

enum Status {
    case none, didClickSegment, did
}

final class PhotoBrowserViewController: UIViewController {
    var images: [String]!
    var x: CGFloat = 0
    var y: CGFloat = 0
    var index: Int = 0
    
    init(images: [String]) {
        self.images = images
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var label: UILabel = {
        let label = UILabel()
        label.text = "Click object on the Photo to be segment3d"
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var page: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = UIScreen.main.bounds.size
        layout.minimumLineSpacing = 0
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.register(PhotoBrowserCellViewController.self, forCellWithReuseIdentifier: "PhotoBrowserCellViewController")
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        view.addSubview(label)
        view.addSubview(page)
        
        page.text = "Images \(index + 1)/\(images.count)"
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            page.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            page.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    func resetCoordinatesAndLabel(_ at: Int) {
        x = 0
        y = 0
        label.text = "Click object on the Photo to be segment3d"
        index = at
    }
}

extension PhotoBrowserViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoBrowserCellViewController", for: indexPath) as! PhotoBrowserCellViewController
        let imageUrl = images[indexPath.item]
        cell.configure(with: imageUrl, at: indexPath.item, delegate: self)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Handle cell selection if needed
    }
    
    // Update index when scrolling ends
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        if let indexPath = collectionView.indexPathForItem(at: visiblePoint) {
            index = indexPath.item
            page.text = "Images \(index + 1)/\(images.count)"
        }
    }
}

final class PhotoBrowserCellViewController: UICollectionViewCell {
    
    private var delegate: PhotoBrowserViewController?
    private var index: Int = 0
    private var imageUrl: String?
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let overlayView = DotOverlay()
    
    private let label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private static let imageCache = NSCache<NSString, UIImage>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(overlayView)
        contentView.addSubview(label) // Add the label here
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20), // Define the constant value
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with imageUrl: String, at idx: Int, delegate: PhotoBrowserViewController) {
        self.index = idx
        self.delegate = delegate
        self.imageUrl = imageUrl
        if let cachedImage = PhotoBrowserCellViewController.imageCache.object(forKey: imageUrl as NSString) {
            self.imageView.image = cachedImage
        } else {
            self.imageView.image = nil
            downloadImage(from: imageUrl)
        }
    }
    
    private func downloadImage(from urlString: String) {
        guard let url = URL(string: "\(Config.storageUrl)\(urlString)") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data, let image = UIImage(data: data), error == nil else { return }
            
            PhotoBrowserCellViewController.imageCache.setObject(image, forKey: urlString as NSString)
            
            DispatchQueue.main.async {
                if self.imageUrl == urlString {
                    self.imageView.image = image
                }
            }
        }
        
        task.resume()
    }
    
    @objc private func didTapImage(_ gestureRecognizer: UITapGestureRecognizer) {
        let tapLocation = gestureRecognizer.location(in: imageView)
        if let image = imageView.image {
            let imageSize = image.size
            let imageViewSize = imageView.bounds.size
            
            let imageViewAspectRatio = imageViewSize.width / imageViewSize.height
            let imageAspectRatio = imageSize.width / imageSize.height
            
            var scale: CGFloat
            var xOffset: CGFloat = 0.0
            var yOffset: CGFloat = 0.0
            
            if imageAspectRatio > imageViewAspectRatio {
                scale = imageViewSize.width / imageSize.width
                yOffset = (imageViewSize.height - imageSize.height * scale) / 2.0
            } else {
                scale = imageViewSize.height / imageSize.height
                xOffset = (imageViewSize.width - imageSize.width * scale) / 2.0
            }
            
            let relativeX = (tapLocation.x - xOffset) / scale
            let relativeY = (tapLocation.y - yOffset) / scale
            
            let normalizedX = relativeX * 1024 / imageSize.width
            let normalizedY = relativeY * 1024 / imageSize.height
            
            if relativeX >= 0 && relativeX <= imageSize.width && relativeY >= 0 && relativeY <= imageSize.height {
                print("Normalized coordinates: (\(normalizedX), \(normalizedY))")
                print("Tapped photo index: \(index)")
                
                let imageViewX = relativeX * scale + xOffset
                let imageViewY = relativeY * scale + yOffset
                overlayView.setDot(at: CGPoint(x: imageViewX, y: imageViewY))
                delegate?.x = normalizedX
                delegate?.y = normalizedY
                delegate?.index = index
                let formattedX = String(format: "%.1f", normalizedX)
                let formattedY = String(format: "%.1f", normalizedY)
                delegate?.label.text = "Coordinate: (\(formattedX), \(formattedY))"
            } else {
                print("Tap is outside the image bounds")
                overlayView.setDot(at: .zero)
            }
        }
    }
    
}
