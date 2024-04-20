//
//  ExploreFileUploaderFormView.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 09/04/24.
//

import SwiftUI
import AVKit

struct ExploreFileUploaderFormView: View {
    @StateObject var viewModel: ExploreFileUploaderViewModel = ExploreFileUploaderViewModel()
    var videoURL: URL?
    var images: [UIImage]
    var onDone: () -> Void

    
    var body: some View {
        VStack(spacing: 20) {
            Text("Upload Asset")
                .font(.title2)
                .fontWeight(.bold)
            Group {
                if let videoURL = videoURL {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(height: 300)
                        .onAppear {
                            print("Video URL: \(videoURL)")
                            verifyVideoURL(videoURL)
                        }
                } else {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(images, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 300)
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 20) {
                SGInputTextField(text: $viewModel.title, title: "Title", placeholder: "Enter asset name")
                HStack (alignment: .top, spacing: 20) {
                    SGInputTextField(text: $viewModel.enteredTag, title: "Tag", placeholder: "Enter tag") { val in
                        viewModel.fetchTags(search: val, limit: 5)
                    }
                    SGInputSelectField(text: $viewModel.privacy, placeholder: "Select asset privacy", title: "Privacy", dropDownItem: ["Public", "Private"])
                }
                
                VStack(alignment: .leading) {
                    Text("Recomendation Tag")
                        .foregroundColor(Color(.darkGray))
                        .fontWeight(.semibold)
                        .font(.footnote)
                    if viewModel.recomendation.count > 0 {
                        WrappingHStack(tags: viewModel.recomendation) { tag in
                            Button(action: {
                                viewModel.addTag(tag: tag)
                            }) {
                                Text(tag)
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                                    .background(.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .font(.system(size: 14))
                            }
                        }
                    } else {
                        Text("-")
                            .font(.system(size: 14))
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Your Tag")
                        .foregroundColor(Color(.darkGray))
                        .fontWeight(.semibold)
                        .font(.footnote)
                    
                    if viewModel.tags.count > 0 {
                        WrappingHStack(tags: viewModel.tags) { tag in
                           Button(action: {
                               viewModel.removeTag(tag: tag)
                           }) {
                               Text(tag)
                                   .padding(.horizontal)
                                   .padding(.vertical, 5)
                                   .background(.gray)
                                   .foregroundColor(.white)
                                   .cornerRadius(10)
                                   .font(.system(size: 14))
                           }
                       }
                    } else {
                        Text("-")
                            .font(.system(size: 14))
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                let folderName = "assets/\(viewModel.title)/source"
                if let videoURL = videoURL {
                    viewModel.uploadFiles(folder: folderName, files: [videoURL]) {
                        onDone()
                    }
                } else if !images.isEmpty {
                    viewModel.uploadFiles(folder: folderName, files: viewModel.convertImagesToURL(images: images)) {
                        onDone()
                    }
                }
            }) {
                Text(viewModel.isLoading ? "Loading..." : "Upload")
                    .fontWeight(.medium)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            .disabled(viewModel.isLoading)
        }
        .padding()
    }
    
    private func verifyVideoURL(_ url: URL) {
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: nil) { (newURL) in
            do {
                let data = try Data(contentsOf: newURL)
                print("File size: \(data.count) bytes")
            } catch {
                print("Error reading video file: \(error)")
            }
        }
    }
}

struct WrappingHStack<Data, Content>: View where Data: RandomAccessCollection, Content: View, Data.Element: Hashable {
    var data: Data
    var content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = 0

    init(tags: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = tags
        self.content = content
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(data, id: \.self) { item in
                self.content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == data.last! {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        let result = height
                        if item == data.last! {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ height: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            DispatchQueue.main.async {
                height.wrappedValue = geometry.frame(in: .local).size.height
            }
            return .clear
        }
    }
}

#Preview {
    ExploreFileUploaderFormView(images: [], onDone: {})
}
