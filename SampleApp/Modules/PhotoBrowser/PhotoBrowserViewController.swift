//
//  PhotoBrowserViewController.swift
//  MetalSplatter SampleApp
//
//  Created by I Made Indra Mahaarta on 21/05/24.
//

import UIKit
import Foundation
import UniformTypeIdentifiers

enum Status {
    case none, didClickSegment, did
}

protocol PhotoBrowserDelegate: AnyObject {
    func didSelectCoordinates(x: CGFloat, y: CGFloat, index: Int)
}

struct SegmentSagaResponse: Codable {
    let url: String
    let message: String
}

final class PhotoBrowserViewController: UIViewController {
    var images: [String]!
    var assetId: String!
    var onSegment: (_ url: String) -> Void
    var x: CGFloat = 0
    var y: CGFloat = 0
    var index: Int = 0
    var url: String = ""
    
    init(images: [String], assetId: String, onSegment: @escaping (_ url: String) -> Void) {
        self.images = images
        self.assetId = assetId
        self.onSegment = onSegment
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
    
    func currentDateTimeString() -> String {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter.string(from: currentDateTime)
    }
    
    var segmentButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Segment Using SAGA"
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = .systemBlue
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    @objc func segmentButtonClicked() {
        if url.isEmpty {
            var payload: [String: Any] = [
                "url": images[index],
                "x": Int(x),
                "y": Int(y),
                "uniqueIdentifier": currentDateTimeString()
            ]
            
            guard let url = URL(string: "\(Config.apiUrl)/assets/saga/segment/\(assetId!)") else {
                print("Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
            request.addValue("Bearer \(getToken())", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    
                    if let error = error {
                        print("Error upload asset: \(error.localizedDescription)")
                        self?.showAlert(message: "Error Segment Using Saga: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = data else {
                        print("No data returned from server")
                        self?.showAlert(message: "No data returned from server")
                        return
                    }
                    
                    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                        self?.showAlert(message: "Error with the response, unexpected status code")
                        return
                    }
                    
                    if let decodedResponse = try? JSONDecoder().decode(SegmentSagaResponse.self, from: data) {
                        self?.url = decodedResponse.url
                        self?.segmentButton.setTitle("View Segmentation", for: .normal)
                        self?.segmentButton.configuration?.baseBackgroundColor = .systemGreen
                    } else {
                        self?.showAlert(message: "Failed to decode JSON")
                    }
                }
            }.resume()
        } else {
            guard let url = URL(string: "\(Config.storageUrl)\(url)") else {
                print("Invalid URL")
                return
            }
            
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("Unable to access documents directory")
            }
            
            let localFilePath = documentsDirectory.appendingPathComponent("test.ply")
            
            downloadFile(from: url, to: localFilePath) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error downloading file: \(error.localizedDescription)")
                    self.showAlert(message: "File is not generated yet")
                } else {
                    print("File downloaded successfully")
                    self.onSegment("test.ply")
                }
            }
        }
    }
    
    func downloadFile(from url: URL, to destination: URL, completion: @escaping (Error?) -> Void) {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: destination.path) {
            do {
                try fileManager.removeItem(at: destination)
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }
        }
        
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusError = NSError(domain: "DownloadErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "File does not exist at the URL"])
                DispatchQueue.main.async {
                    completion(statusError)
                }
                return
            }
            
            if let localURL = localURL {
                do {
                    try FileManager.default.moveItem(at: localURL, to: destination)
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            } else {
                let unknownError = NSError(domain: "DownloadErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
                DispatchQueue.main.async {
                    completion(unknownError)
                }
            }
        }
        task.resume()
    }

    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func getToken() -> String {
        return UserDefaults.standard.string(forKey: "jwt") ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        view.addSubview(label)
        view.addSubview(page)
        view.addSubview(segmentButton)
        
        segmentButton.addTarget(self, action: #selector(segmentButtonClicked), for: .touchUpInside)
        
        page.text = "Images \(index + 1)/\(images.count)"
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            
            page.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            page.bottomAnchor.constraint(equalTo: segmentButton.topAnchor, constant: -20),
            
            segmentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
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
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
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
                overlayView.setDot(at: .zero)
            }
        }
    }
    
}
