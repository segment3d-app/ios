//
//  ExploreView.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 24/03/24.
//

import SwiftUI

enum ActiveSheet: Identifiable {
    case picker, uploadForm
    
    var id: Int {
        switch self {
        case .picker:
            return 0
        case .uploadForm:
            return 1
        }
    }
}

struct ExploreView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @State private var activeSheet: ActiveSheet?
    @State private var navigationPath = NavigationPath()
    
    init(viewModel: ExploreViewModel) {
        self.viewModel = viewModel
    }
    
    func openWindow(value: ModelIdentifier) {
        navigationPath.append(value)
    }
    
    var body: some View {
        let filteredAssets = viewModel.assets.filter {
            viewModel.searchTerm.isEmpty || $0.title.localizedCaseInsensitiveContains(viewModel.searchTerm)
        }
        
        NavigationStack (path: $navigationPath) {
            if !viewModel.isLoading {
                ZStack{
                    VStack {
                        if (viewModel.assets.isEmpty) {
                            Image("asset-empty")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: UIScreen.main.bounds.width - 40)
                                .padding(.horizontal)
                                .edgesIgnoringSafeArea(.all)
                            Text("There is no assets yet")
                                .font(.title3)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            Text("You can make your asset first!")
                        } else {
                            ScrollView {
                                LazyVStack {
                                    ForEach(filteredAssets) { asset in
                                        ExploreItemView(
                                            viewModel: ExploreItemViewModel(asset: asset),
                                            openWindow: openWindow
                                        )
                                        .padding(.vertical, 4.5)
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }
                    }
                    .navigationTitle(viewModel.isMyAssetOnly ? "Capture" : "Expore")
                    .searchable(text: $viewModel.searchTerm, prompt: Text("Search Asset"))
                    
                    // Floating Button
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                activeSheet = .picker
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.blue)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .padding()
                        }
                    }
                }
                .navigationDestination(for: ModelIdentifier.self) { modelIdentifier in
                    MetalKitSceneView(modelIdentifier: modelIdentifier)
                        .navigationTitle(modelIdentifier.description)
                }
                .sheet(item: $activeSheet) { item in
                    switch item {
                    case .picker:
                        ExploreFilePickerView(
                            pickerResult: $viewModel.mediaItems,
                            isPresented: Binding<Bool>(
                                get: { self.activeSheet == .picker },
                                set: { _ in }
                            ),
                            selectionLimit: 20,
                            onDone: { pickedMedia in
                                activeSheet = viewModel.onMediaPick(pickedMedia: pickedMedia)
                            }
                        )
                        
                    case .uploadForm:
                        ExploreFileUploaderFormView(videoURL: viewModel.videoURL, images: viewModel.images, onDone: {
                            viewModel.fetchAssets()
                            activeSheet = nil
                        })
                    }
                }
            } else {
                Text("Loading...")
            }
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { viewModel.alertMessage != nil },
            set: { _ in viewModel.alertMessage = nil }
        ), presenting: viewModel.alertMessage) { _ in
            Button("OK", role: .cancel) {
                viewModel.alertMessage = ""
            }
        } message: { message in
            Text(message)
        }
        .refreshable {
            viewModel.fetchAssets(withLoading: false)
        }
    }
}

#Preview {
    ExploreView(viewModel: ExploreViewModel(isMyAssetOnly: false))
}
