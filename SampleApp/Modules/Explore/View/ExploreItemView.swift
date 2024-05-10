//
//  ExploreItemView.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 24/03/24.
//

import SwiftUI
import Foundation

struct ExploreItemView: View {
    @ObservedObject var viewModel: ExploreItemViewModel
    @State private var showLikeAnimation = false
    @State private var showUnlikeAnimation = false
    
    var openWindow: (ModelIdentifier) -> Void
    
    init(viewModel: ExploreItemViewModel, openWindow: @escaping (ModelIdentifier) -> Void) {
        self.viewModel = viewModel
        self.openWindow = openWindow
    }
    
    func downloadFile(from url: URL, to destination: URL, completion: @escaping (Error?) -> Void) {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: destination.path) {
            do {
                try fileManager.removeItem(at: destination)
            } catch {
                completion(error)
                return
            }
        }
        
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let localURL = localURL {
                do {
                    try FileManager.default.moveItem(at: localURL, to: destination)
                    completion(nil)
                } catch {
                    completion(error)
                }
            } else {
                completion(error)
            }
        }
        task.resume()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                AsyncImage(url: URL(string: (viewModel.asset.user.avatar))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                }
                VStack(alignment: .leading) {
                    Text(viewModel.asset.title)
                        .font(.headline)
                    Text("by \(viewModel.asset.user.name)")
                        .font(.subheadline)
                }
                Spacer()
                
                Button(action: {
                    // Action for button
                }) {
                    Image(systemName: "ellipsis")
                }
            }
            .padding([.top, .horizontal])
            
            ZStack {
                AsyncImage(url: URL(string: "\(Config.storageUrl)\(viewModel.asset.thumbnailUrl)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .frame(width: UIScreen.main.bounds.width - 36, height: UIScreen.main.bounds.width - 36)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .frame(width: UIScreen.main.bounds.width - 36, height: UIScreen.main.bounds.width - 36)
                        .clipped()
                }
                .gesture(
                    TapGesture(count:1)
                        .onEnded({
                            let remoteURL = URL(string: "https://storage.googleapis.com/segment3d-app/test.ply")!

                            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                                fatalError("Unable to access documents directory")
                            }

                            let localFilePath = documentsDirectory.appendingPathComponent("test.ply")
                            
                            downloadFile(from: remoteURL, to: localFilePath) { error in
                                if let error = error {
                                    print("Error downloading file: \(error)")
                                } else {
                                    print("File downloaded successfully")
                                    openWindow(ModelIdentifier.gaussianSplat(localFilePath))
                                }
                            }
                        })) //.gesture
                .highPriorityGesture(TapGesture(count:2)
                    .onEnded({
                        viewModel.likeAsset()
                        
                        withAnimation(Animation.easeInOut(duration: 0.6)) {
                            showLikeAnimation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            showLikeAnimation = false
                        }
                    }))
                
                if showLikeAnimation {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .scaleEffect(showLikeAnimation ? 5.0 : 1.0)
                }
                
                if showUnlikeAnimation {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                        .scaleEffect(showUnlikeAnimation ? 5.0 : 1.0)
                }
                
            }
            .frame(width: UIScreen.main.bounds.width - 36, height: UIScreen.main.bounds.width - 36)
            
            HStack {
                Button(action: {
                    if viewModel.asset.isLikedByMe {
                        viewModel.likeAsset(isLikeAction: false)
                        withAnimation(Animation.easeInOut(duration: 0.6)) {
                            showUnlikeAnimation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            showUnlikeAnimation = false
                        }
                    } else {
                        viewModel.likeAsset()
                        withAnimation(Animation.easeInOut(duration: 0.6)) {
                            showLikeAnimation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            showLikeAnimation = false
                        }
                    }
                }) {
                    Image(systemName: "\(viewModel.asset.isLikedByMe ? "heart.fill" : "heart")")
                }
                Text("\(viewModel.asset.likes) \(viewModel.asset.likes > 1 ? "likes" : "like")")
                    .font(.subheadline)
            }
            .padding()
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(lineWidth: 0.2)
        )
    }
}

#Preview {
    ExploreItemView(viewModel: ExploreItemViewModel(asset: Asset(
        id: "1",
        assetType: "video",
        assetUrl: "/files/assets/Doggo/source/Doggo .mp4",
        createdAt: "2024-03-24T20:49:01.31828Z",
        gaussianUrl: "https://example.com/gaussian-url",
        isLikedByMe: false,
        isPrivate: false,
        likes: 42,
        pointCloudUrl: "https://example.com/point-cloud-url",
        slug: "example-slug",
        status: "Active",
        thumbnailUrl: "https://example.com/thumbnail-url",
        title: "Example Asset",
        updatedAt: "2024-03-24T20:49:01.31828Z",
        user: User(
            avatar: "https://example.com/avatar-url",
            createdAt: "2024-03-24T20:49:01.31828Z",
            email: "user@example.com",
            id: "user-1",
            name: "John Doe",
            passwordChangedAt: "2024-03-24T20:49:01.31828Z",
            provider: "ExampleProvider",
            updatedAt: "2024-03-24T20:49:01.31828Z"
        )
    ))) { modelIdentifier in
        // action
    }
}
