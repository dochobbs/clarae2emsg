import SwiftUI
import SharedMessaging

struct ConversationListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ConversationListViewModel()
    @State private var showingNewConversation = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.conversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(role: .destructive, action: {
                            Task {
                                await authViewModel.signOut()
                            }
                        }) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewConversation = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewConversation) {
                NewConversationView(onSelect: { provider in
                    Task {
                        if let profile = authViewModel.currentProfile {
                            await viewModel.createConversation(
                                parentId: profile.id,
                                providerId: provider.id
                            )
                        }
                    }
                    showingNewConversation = false
                })
            }
            .task {
                if let profile = authViewModel.currentProfile {
                    await viewModel.loadConversations(for: profile.id, userType: profile.userType)
                }
            }
            .refreshable {
                if let profile = authViewModel.currentProfile {
                    await viewModel.loadConversations(for: profile.id, userType: profile.userType)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Conversations")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start a new conversation with a provider")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showingNewConversation = true }) {
                Text("New Message")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }

    private var conversationList: some View {
        List(viewModel.conversations) { item in
            NavigationLink(destination: ChatView(conversation: item)) {
                ConversationRow(conversation: item)
            }
        }
        .listStyle(.plain)
    }
}

struct ConversationRow: View {
    let conversation: ConversationWithMetadata

    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(conversation.otherUser.fullName.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.fullName)
                        .font(.headline)

                    Spacer()

                    if let metadata = conversation.metadata,
                       let lastMessageDate = metadata.lastMessageAt {
                        Text(lastMessageDate, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text(conversation.otherUser.userType == .provider ? "Provider" : "Parent")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let metadata = conversation.metadata {
                        let unreadCount = metadata.parentUnreadCount
                        if unreadCount > 0 {
                            Text("\(unreadCount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct NewConversationView: View {
    @StateObject private var viewModel = NewConversationViewModel()
    let onSelect: (Profile) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List(viewModel.providers) { provider in
                        Button(action: {
                            onSelect(provider)
                            dismiss()
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(provider.fullName.prefix(1).uppercased())
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    )

                                VStack(alignment: .leading) {
                                    Text(provider.fullName)
                                        .font(.headline)
                                    Text(provider.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadProviders()
            }
        }
    }
}

// MARK: - View Models

@MainActor
class ConversationListViewModel: ObservableObject {
    @Published var conversations: [ConversationWithMetadata] = []
    @Published var isLoading = false

    private let messagingService: MessagingService

    init() {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        self.messagingService = MessagingService(deviceId: deviceId)
    }

    func loadConversations(for userId: UUID, userType: UserType) async {
        isLoading = true
        defer { isLoading = false }

        do {
            conversations = try await messagingService.fetchConversations(for: userId, userType: userType)
        } catch {
            print("Error loading conversations: \(error)")
        }
    }

    func createConversation(parentId: UUID, providerId: UUID) async {
        do {
            _ = try await messagingService.createConversation(parentId: parentId, providerId: providerId)
            // Reload conversations
            await loadConversations(for: parentId, userType: .parent)
        } catch {
            print("Error creating conversation: \(error)")
        }
    }
}

@MainActor
class NewConversationViewModel: ObservableObject {
    @Published var providers: [Profile] = []
    @Published var isLoading = false

    func loadProviders() async {
        isLoading = true
        defer { isLoading = false }

        do {
            providers = try await SupabaseClient.shared.fetchAllProfiles(userType: .provider)
        } catch {
            print("Error loading providers: \(error)")
        }
    }
}

#Preview {
    ConversationListView()
        .environmentObject(AuthViewModel(userType: .parent))
}
