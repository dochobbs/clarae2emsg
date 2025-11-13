import SwiftUI
import SharedMessaging

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                ConversationListView()
            } else {
                AuthView()
            }
        }
        .onAppear {
            Task {
                await authViewModel.checkAuthStatus()
            }
        }
    }
}

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var fullName = ""
    @State private var email = ""
    @State private var showingProfileSetup = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo/Title
                VStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Secure Parent Messaging")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("End-to-end encrypted communication")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)

                Spacer()

                // Sign In Button
                Button(action: {
                    Task {
                        await authViewModel.signInWithApple()
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title3)
                        Text("Sign in with Apple")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                if authViewModel.isLoading {
                    ProgressView()
                }

                if let error = authViewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                Text("Your messages are encrypted end-to-end")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .sheet(isPresented: $showingProfileSetup) {
                ProfileSetupView(fullName: $fullName, email: $email) {
                    Task {
                        await authViewModel.createProfile(fullName: fullName, email: email)
                    }
                }
            }
            .onChange(of: authViewModel.needsProfileSetup) { needs in
                showingProfileSetup = needs
            }
        }
    }
}

struct ProfileSetupView: View {
    @Binding var fullName: String
    @Binding var email: String
    let onComplete: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section {
                    Button("Complete Setup") {
                        onComplete()
                    }
                    .disabled(fullName.isEmpty || email.isEmpty)
                }
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel(userType: .parent))
}
