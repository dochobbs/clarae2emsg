import SwiftUI
import SharedMessaging
import UserNotifications

@main
struct ParentAppApp: App {
    @StateObject private var authViewModel = AuthViewModel(userType: .parent)

    init() {
        // Configure Supabase
        SupabaseClient.shared.configure(
            supabaseURL: "YOUR_SUPABASE_URL",
            supabaseKey: "YOUR_SUPABASE_ANON_KEY"
        )

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
