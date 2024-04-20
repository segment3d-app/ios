import SwiftUI
import GoogleSignInSwift
import GoogleSignIn

struct LoginScreen: View {
    @ObservedObject var viewModel: LoginViewModel
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 12) {
                
                Image("firebase-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .padding(.bottom)
                
                VStack(alignment: .center) {
                    Text("Welcome back!")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Use your account to continue")
                }
                .padding(.bottom)
                
                VStack(spacing: 12) {
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .padding(.bottom)
                    }
                    
                    SGInputTextField(text: $viewModel.email, title: "Email", placeholder: "Enter your email address")
                    
                    SGInputTextField(text: $viewModel.password, title: "Password", placeholder: "Enter your password", isSecuredPassword: true)
                    Button(action: viewModel.login) {
                        Text("Sign in")
                            .fontWeight(.medium)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                    
                    Text("Or continue with")
                        .padding(.vertical)
                    
                    Button(action: handleSignInButton) {
                        HStack {
                            Spacer()
                            Image("google")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            Text("Sign in with Google")
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(4)
                        .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                    }
                    .frame(height: 40)
                    .foregroundColor(.black)
                    
                }
                
                Spacer()
                
                NavigationLink {
                    RegisterView(viewModel: viewModel)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    HStack {
                        Text("Don't have an account?")
                        Text("Sign Up")
                            .fontWeight(.bold)
                    }
                }
            }
            .safeAreaPadding()
            .onAppear(perform: {
                viewModel.clearData()
            })
        }
    }
    
    func handleSignInButton() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        guard let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
    
        let config = GIDConfiguration(clientID: Config.googleClientId)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Error during Google Sign-In: \(error.localizedDescription)")
                return
            }
            guard let user = result?.user else {
                print("Error during Google Sign-In: user not defined")
                return
            }
        
            
            let accessToken = user.accessToken.tokenString
            viewModel.loginUsingGoogle(accessToken: accessToken)
        }
    }
}

#Preview {
    LoginScreen(viewModel: LoginViewModel())
}
