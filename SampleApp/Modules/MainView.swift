//
//  MainView.swift
//  MetalSplatter SampleApp
//
//  Created by I Made Indra Mahaarta on 19/04/24.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel = LoginViewModel()
    
    var body: some View {
        if viewModel.isAuthenticated {
            dashboardView
        } else {
            LoginScreen(viewModel: viewModel)
        }
    }
    
    @ViewBuilder
    var dashboardView: some View {
        TabView {
            ExploreView(viewModel: ExploreViewModel(isMyAssetOnly: false))
                .tabItem {
                    Label(
                        title: { Text("Explore") },
                        icon: { Image(systemName: "globe")
                    }
                )
            }
            ExploreView(viewModel: ExploreViewModel(isMyAssetOnly: true))
                .tabItem {
                    Label(
                        title: { Text("Capture") },
                        icon: { Image(systemName: "camera")
                    }
                )
            }
            ProfileView(authViewModel: viewModel)
                .tabItem {
                    Label(
                        title: { Text("Profile") },
                        icon: { Image(systemName: "person.circle") }
                    )
                }
            }
    }
}

#Preview {
    MainView()
}

