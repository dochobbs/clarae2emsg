import SwiftUI
import SharedMessaging

struct ChatView: View {
    let conversation: ConversationWithMetadata
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    init(conversation: ConversationWithMetadata) {
        self.conversation = conversation
        self._viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == viewModel.currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }

            // Input Bar
            Divider()

            HStack(spacing: 12) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .lineLimit(1...5)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty || viewModel.isSending)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.otherUser.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMessages()
            await viewModel.subscribeToNewMessages()
            await viewModel.markAsRead()
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""

        Task {
            await viewModel.sendMessage(text)
        }
    }
}

struct MessageBubble: View {
    let message: DecryptedMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(18)

                HStack(spacing: 4) {
                    Text(message.sentAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if isFromCurrentUser {
                        statusIcon
                    }
                }
            }

            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .delivered:
            Image(systemName: "checkmark.circle")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .read:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - View Model

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [DecryptedMessage] = []
    @Published var isSending = false

    let conversation: ConversationWithMetadata
    let currentUserId: UUID
    private let messagingService: MessagingService

    init(conversation: ConversationWithMetadata) {
        self.conversation = conversation
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        self.messagingService = MessagingService(deviceId: deviceId)

        // Get current user ID (in production, get from auth state)
        self.currentUserId = conversation.conversation.parentId
    }

    func loadMessages() async {
        do {
            messages = try await messagingService.fetchMessages(conversationId: conversation.id)
        } catch {
            print("Error loading messages: \(error)")
        }
    }

    func sendMessage(_ content: String) async {
        isSending = true
        defer { isSending = false }

        do {
            let _ = try await messagingService.sendMessage(
                content: content,
                conversationId: conversation.id,
                senderId: currentUserId,
                recipientId: conversation.otherUser.id
            )

            // Reload messages
            await loadMessages()
        } catch {
            print("Error sending message: \(error)")
        }
    }

    func subscribeToNewMessages() async {
        do {
            try await messagingService.subscribeToConversation(conversationId: conversation.id) { [weak self] message in
                guard let self = self else { return }

                Task { @MainActor in
                    // Add message if not already present
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.messages.append(message)

                        // Mark as delivered if we're the recipient
                        if message.recipientId == self.currentUserId {
                            try? await self.messagingService.markMessageAsDelivered(messageId: message.id)
                        }
                    }
                }
            }
        } catch {
            print("Error subscribing to messages: \(error)")
        }
    }

    func markAsRead() async {
        do {
            try await messagingService.resetUnreadCount(
                conversationId: conversation.id,
                userId: currentUserId
            )

            // Mark all unread messages as read
            for message in messages where message.recipientId == currentUserId && message.status != .read {
                try? await messagingService.markMessageAsRead(messageId: message.id)
            }
        } catch {
            print("Error marking as read: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        ChatView(conversation: ConversationWithMetadata(
            conversation: Conversation(
                parentId: UUID(),
                providerId: UUID()
            ),
            metadata: nil,
            otherUser: Profile(
                id: UUID(),
                userType: .provider,
                fullName: "Dr. Smith",
                email: "smith@example.com"
            )
        ))
    }
}
