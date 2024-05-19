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
    
    var onTapImage: (Asset) -> Void
    
    init(viewModel: ExploreItemViewModel, onTapImage: @escaping (Asset) -> Void) {
        self.viewModel = viewModel
        self.onTapImage = onTapImage
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
                            onTapImage(viewModel.asset)
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
        title: "Example Asset",
        slug: "example-slug",
        type: "lidar",
        thumbnailUrl: "https://example.com/thumbnail-url",
        photoDirUrl: "/files/assets/Doggo/source/Doggo .mp4",
        splatUrl: "https://example.com/splat-url",
        pclUrl: "https://example.com/pcl-url",
        pclColmapUrl: "https://example.com/pcl-colmap-url",
        segmentedPclDirUrl: "https://example.com/segmented-pcl-dir-url",
        segmentedSplatDirUrl: "https://example.com/segmented-splat-dir-url",
        status: "Active",
        createdAt: "2024-03-24T20:49:01.31828Z",
        updatedAt: "2024-03-24T20:49:01.31828Z",
        isPrivate: false,
        isLikedByMe: false,
        likes: 42,
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
