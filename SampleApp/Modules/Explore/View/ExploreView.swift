//
//  ExploreView.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 24/03/24.
//

import SwiftUI

enum ActiveSheet: Identifiable {
    case chooseModel, picker, scanner, uploadForm
    
    var id: Int {
        switch self {
        case .chooseModel:
            return 0
        case .picker:
            return 1
        case .scanner:
            return 2
        case .uploadForm:
            return 3
        }
    }
}

enum UploadType: Identifiable {
    case lidar, non_lidar
    
    var id: String {
        switch self {
        case .lidar:
            return "lidar"
        case .non_lidar:
            return "non_lidar"
        }
    }
}

struct ExploreView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @State private var activeSheet: ActiveSheet?
    @State private var pathFile: String?
    @State private var uploadType: UploadType?
    @State private var navigationPath = NavigationPath()
    @State var detentHeight: CGFloat = 0
    
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
                                activeSheet = .chooseModel
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
                    case .chooseModel:
                        VStack(alignment: .center, spacing: 20, content: {
                            Text("Choose Model")
                                .font(.title2)
                                .padding(.top, 20)
                            Button(action: {
                                activeSheet = .picker
                            }, label: {
                                Text("3D Gaussian Splatting")
                            })
                            Button(action: {
                                activeSheet = .scanner
                            }, label: {
                                Text("3D Point Cloud")
                            })
                        })
                        .readHeight()
                        .onPreferenceChange(HeightPreferenceKey.self) { height in
                            if let height {
                                self.detentHeight = height
                            }
                        }
                        .presentationDetents([.height(self.detentHeight)])
                    case .picker:
                        ExploreFilePickerView(
                            pickerResult: $viewModel.mediaItems,
                            isPresented: Binding<Bool>(
                                get: { self.activeSheet == .picker },
                                set: { _ in }
                            ),
                            selectionLimit: 50,
                            onDone: { pickedMedia in
                                activeSheet = viewModel.onMediaPick(pickedMedia: pickedMedia)
                            }
                        )
                    case .scanner:
                        ScannerWrapper(onDone: { path in
                            DispatchQueue.main.async {
                                viewModel.images = getImages(forDirectory: "\(path)/data")
                                activeSheet = .uploadForm
                                pathFile = path
                                uploadType = .lidar
                            }
                        })
                            .edgesIgnoringSafeArea(.all)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    case .uploadForm:
                        if uploadType == .lidar {
                            let pclUrl: URL = getPointCloud(forDirectory: pathFile!)!
                            ExploreFileUploaderFormView(images: viewModel.images, pclUrl: pclUrl) {
                                viewModel.fetchAssets()
                                activeSheet = nil
                            }
                        } else {
                            ExploreFileUploaderFormView(images: viewModel.images) {
                                viewModel.fetchAssets()
                                activeSheet = nil
                            }
                        }
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

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

private struct ReadHeightModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
    }

    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}

extension View {
    func readHeight() -> some View {
        self
            .modifier(ReadHeightModifier())
    }
}

#Preview {
    ExploreView(viewModel: ExploreViewModel(isMyAssetOnly: false))
}
