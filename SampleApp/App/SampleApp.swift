import SwiftUI
import GoogleSignIn
import ARKit

@main
struct SampleApp: App {
    var body: some Scene {
        WindowGroup("Segment3d_App", id: "main") {
//            MainView().onAppear {
//                if !ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
//                    print("ga support cok")
//                }
//            }
            ScannerWrapper()
                .edgesIgnoringSafeArea(.all)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
    }
}

