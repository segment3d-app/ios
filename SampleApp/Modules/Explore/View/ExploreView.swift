//
//  ExploreView.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 24/03/24.
//

import SwiftUI

enum ActiveSheet: Identifiable {
    case chooseModel, picker, scanner, uploadForm, onTapImage
    
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
        case .onTapImage:
            return 4
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
    @State var currentAsset: Asset?
    @State var isLoading: Bool = false
    @State var currentAssetUrl: URL?
    
    init(viewModel: ExploreViewModel) {
        self.viewModel = viewModel
    }
    
    func openWindow(value: ModelIdentifier) {
        navigationPath.append(value)
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
        let filteredAssets = viewModel.assets.filter {
            viewModel.searchTerm.isEmpty || $0.title.localizedCaseInsensitiveContains(viewModel.searchTerm)
        }
        
        NavigationStack (path: $navigationPath) {
            ZStack{
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
                                                onTapImage: { asset in
                                                    currentAsset = asset
                                                    activeSheet = .onTapImage
                                                }
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
                    .navigationDestination(for: String.self) { destination in
                        if destination == "PCLRenderer", let chosenCloud = currentAssetUrl {
                            PointCloudSceneView(chosenCloud: chosenCloud)
                                .navigationTitle(currentAsset?.title ?? "")
                        } else if destination == "Saga" {
                            PhotoBrowserView(images: viewModel.sagaImage, assetId: currentAsset?.id ?? "", onSegment: { url in
                                isLoading = true
                                
                                print("is Loading", navigationPath)
                                if !navigationPath.isEmpty {
                                    navigationPath.removeLast()
                                }
                                
                                let pathName = url
                                print(pathName)
                                
                                guard !pathName.isEmpty else {
                                    viewModel.alertMessage = "Saga Segmentation is not generated yet"
                                    isLoading = false
                                    return
                                }
                                
                                guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                                    isLoading = false
                                    fatalError("Unable to access documents directory")
                                }
                                
                                let localFilePath = documentsDirectory.appendingPathComponent(url)
                                
                                isLoading = false
                                openWindow(value: ModelIdentifier.gaussianSplat(localFilePath))
                            })
                        }
                    }
                    .sheet(item: $activeSheet) { item in
                        switch item {
                        case .chooseModel:
                            VStack(alignment: .center, spacing: 20, content: {
                                Text("Choose Method")
                                    .font(.title2)
                                    .padding(.top, 20)
                                Button(action: {
                                    activeSheet = .picker
                                }, label: {
                                    Text("Upload Photos")
                                })
                                Button(action: {
                                    activeSheet = .scanner
                                }, label: {
                                    Text("Scan Using Lidar")
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
                        case .onTapImage:
                            VStack(alignment: .center, spacing: 20, content: {
                                Text("\(currentAsset?.title ?? "Choose Action")")
                                    .font(.title2)
                                    .padding(.top, 20)
                                Button(action: {
                                    activeSheet = nil
                                    isLoading = true
                                    guard let pathName = currentAsset?.pclUrl ?? currentAsset?.pclColmapUrl, !pathName.isEmpty else {
                                        viewModel.alertMessage = "Point Cloud is not generated yet"
                                        isLoading = false
                                        return
                                    }
                                    
                                    let storageUrl = Config.storageUrl
                                    
                                    guard !storageUrl.isEmpty, let remoteURL = URL(string: "\(storageUrl)\(pathName)") else {
                                        viewModel.alertMessage = "Invalid URL"
                                        isLoading = false
                                        return
                                    }
                                    
                                    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                                        isLoading = false
                                        fatalError("Unable to access documents directory")
                                    }
                                    
                                    let localFilePath = documentsDirectory.appendingPathComponent("test.ply")
                                    
                                    downloadFile(from: remoteURL, to: localFilePath) { error in
                                        if let error = error {
                                            print("Error downloading file: \(error)")
                                            currentAssetUrl = nil
                                            isLoading = false
                                        } else {
                                            print("File downloaded successfully")
                                            currentAssetUrl = localFilePath
                                            isLoading = false
                                            navigationPath.append("PCLRenderer")
                                        }
                                    }
                                }, label: {
                                    Text("View Point Cloud")
                                })
                                Button(action: {
                                    activeSheet = nil
                                    isLoading = true
                                    guard let pathName = currentAsset?.splatUrl, !pathName.isEmpty else {
                                        viewModel.alertMessage = "3D Gaussian Splatting is not generated yet"
                                        isLoading = false
                                        return
                                    }
                                    
                                    let storageUrl = Config.storageUrl
                                    
                                    guard !storageUrl.isEmpty, let remoteURL = URL(string: "\(storageUrl)\(pathName)") else {
                                        viewModel.alertMessage = "Invalid URL"
                                        isLoading = false
                                        return
                                    }
                                    
                                    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                                        isLoading = false
                                        fatalError("Unable to access documents directory")
                                    }
                                    
                                    let localFilePath = documentsDirectory.appendingPathComponent("test.ply")
                                    
                                    downloadFile(from: remoteURL, to: localFilePath) { error in
                                        if let error = error {
                                            print("Error downloading file: \(error)")
                                            currentAssetUrl = nil
                                            isLoading = false
                                        } else {
                                            print("File downloaded successfully")
                                            currentAssetUrl = localFilePath
                                            isLoading = false
                                            openWindow(value: ModelIdentifier.gaussianSplat(localFilePath))
                                        }
                                    }
                                }, label: {
                                    Text("View 3D Gaussian Splatting")
                                })
                                Button(action: {
                                    activeSheet = nil
                                    isLoading = true
                                    guard let pathName = currentAsset?.segmentedPclDirUrl, !pathName.isEmpty else {
                                        viewModel.alertMessage = "PTv3 Segmentation is not generated yet"
                                        isLoading = false
                                        return
                                    }
                                    
                                    let storageUrl = Config.storageUrl
                                    
                                    guard !storageUrl.isEmpty, let remoteURL = URL(string: "\(storageUrl)\(pathName)") else {
                                        viewModel.alertMessage = "Invalid URL"
                                        isLoading = false
                                        return
                                    }
                                    
                                    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                                        isLoading = false
                                        fatalError("Unable to access documents directory")
                                    }
                                    
                                    let localFilePath = documentsDirectory.appendingPathComponent("test.ply")
                                    
                                    downloadFile(from: remoteURL, to: localFilePath) { error in
                                        if let error = error {
                                            print("Error downloading file: \(error)")
                                            currentAssetUrl = nil
                                            isLoading = false
                                        } else {
                                            print("File downloaded successfully")
                                            currentAssetUrl = localFilePath
                                            isLoading = false
                                            navigationPath.append("PCLRenderer")
                                        }
                                    }
                                }, label: {
                                    Text("View PTv3 Segmentation")
                                })
                                Button(action: {
                                    activeSheet = nil
                                    isLoading = true
                                    guard let pathName = currentAsset?.segmentedSplatDirUrl, !pathName.isEmpty else {
                                        viewModel.alertMessage = "Saga Segmentation is not generated yet"
                                        isLoading = false
                                        return
                                    }
                                    viewModel.fetchSagaImage(assetDir: currentAsset?.segmentedSplatDirUrl ?? "", withLoading: true)
                                    isLoading = false
                                    navigationPath.append("Saga")
                                }, label: {
                                    Text("Segment Using Saga")
                                })
                            })
                            .readHeight()
                            .onPreferenceChange(HeightPreferenceKey.self) { height in
                                if let height {
                                    self.detentHeight = height
                                }
                            }
                            .presentationDetents([.height(self.detentHeight)])
                        }
                    }
                }
                
                if viewModel.isLoading || isLoading {
                    Color.white.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView()
                }
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
