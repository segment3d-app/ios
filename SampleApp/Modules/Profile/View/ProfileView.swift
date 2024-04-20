//
//  ProfileView.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 24/03/24.
//

import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel = ProfileViewModel()
    @ObservedObject var authViewModel: LoginViewModel
    
    var body: some View {
            NavigationView {
                VStack {
                    if let user = viewModel.user {
                        if user.avatar.isEmpty {
                            Image(systemName: "person.circle")
                                .resizable()
                                .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                                .foregroundColor(.blue)
                                .frame(width: 125, height: 125)
                                .padding()
                        } else {
                            AsyncImage(url: URL(string: user.avatar) ) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 125, height: 125)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                            }
                            .foregroundColor(.blue)
                            .padding()
                            
                        }
                        VStack(alignment: .center, spacing: 12) {
                            Text(user.name)
                                .font(.title)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            Text(user.email)
                                .font(.title2)
                            Text("Member since \(Date(timeIntervalSince1970: IsoStringToTimeInterval(isoDateString: user.createdAt) ?? 0).formatted(date: .abbreviated, time: .omitted))")
                        }
                        
                        Button("Log out") {
                            authViewModel.logout()
                        }
                        .foregroundColor(.red)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding()
                        
                        Spacer()
                        
                    } else {
                        Text("Loading...")
                    }
                }
                .navigationTitle("Profile")
            }
        }
}

#Preview {
    ProfileView(authViewModel: LoginViewModel())
}
