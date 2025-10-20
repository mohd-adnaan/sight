import SwiftUI
import AVFoundation
import UIKit
import AVKit

enum AnimationState {
    case compress
    case expand
    case normal
}

struct ContentView: View {
    @State private var isShowingSideMenu = false
    @State private var animationState: AnimationState = .normal
    @State private var done: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    init() {
        // Configure the tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = UIColor.white
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.black
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.blue
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    func calculateScale() -> CGFloat {
        switch animationState {
        case .compress:
            return 0.3
        case .expand:
            return 0.5
        case .normal:
            return 0.3
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if !done {
                    VStack {
                        let logoAssetName = (colorScheme == .dark) ? "dark_mode_logoName" : "light_mode_logoName"
                        Image(logoAssetName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(calculateScale())
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        animationState = .compress
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            animationState = .expand
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                animationState = .normal
                                                done = true
                                            }
                                        }
                                    }
                                }
                            }
                        Spacer()
                        if let videoURL = Bundle.main.url(forResource: "srlLogo", withExtension: "mp4") {
                            VideoPlayerView(videoURL: videoURL)
                                .frame(height: 140)
                                .background(Color(UIColor.systemBackground))
                        } else {
                            Text("Video not found.")
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                    
                } else {
                    MainContentView(isShowingSideMenu: $isShowingSideMenu)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
    
// Custom Video Player using AVPlayerViewController
struct VideoPlayerView: UIViewControllerRepresentable {
    let videoURL: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        
        playerViewController.view.backgroundColor = UIColor.systemBackground // Set the background color of the video player
        playerViewController.player = player
        player.play() // Auto-play on view appear
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}


struct MainContentView: View {
    @Binding var isShowingSideMenu: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                let logoAssetName = (colorScheme == .dark) ? "dark_mode_logoName" : "light_mode_logoName"
                Image(logoAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                TabView {
                    
                    StoryboardViewBus()
                        .edgesIgnoringSafeArea(.top)
                        .tabItem {
                        Image(systemName: "bus")
                        Text("Bus")
                    }
                    
                    StoryboardViewDoor()
                        .edgesIgnoringSafeArea(.top)
                        .tabItem {
                        Image(systemName: "door.left.hand.open")
                        Text("Door")
                    }
                   
                    
                    StoryboardViewImageClassification()
                        .edgesIgnoringSafeArea(.top)
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Identify")
                            }
                    
                    StoryboardViewSegmentation()
                        .edgesIgnoringSafeArea(.top)
                        .tabItem {
                            Image(systemName: "arrow.triangle.merge")
                            Text("Crossway")
                            }
 
                    // New Room tab
                    StoryboardViewRoom()
                        .edgesIgnoringSafeArea(.top)
                        .tabItem {
                            Image(systemName: "house")
                            Text("Room")
                        }
                    
//                    StoryboardViewCybsGuidance()
//                        .edgesIgnoringSafeArea(.top)
//                        .tabItem {
//                            Image(systemName: "arrow.triangle.turn.up.right.diamond")
//                            Text("CybsGuidance")
//                            }
                    
                            }
                    .frame(maxHeight: .infinity)
                               }
            
                if isShowingSideMenu {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                isShowingSideMenu = false
                            }
                        }
                }
                
                // Sidebar navigation menu
                if isShowingSideMenu {
                    SidebarMenuView(isShowingSideMenu: $isShowingSideMenu)
                        .frame(width: 250)
                        .transition(.move(edge: .leading))
                }
                
                // Button to toggle the side menu
                Button(action: {
                    withAnimation {
                        isShowingSideMenu.toggle()
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                        .imageScale(.large)
                        .padding()
                }
            }
        }
    }


struct SidebarMenuView: View {
    @Binding var isShowingSideMenu: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Group {
                
                NavigationLink(destination: StoryboardViewCybsGuidance()) {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond")
                            .imageScale(.large)
                        Spacer()
                        Text("CybsGuidance")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                
                NavigationLink(destination: StoryboardViewText()) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .imageScale(.large)
                        Spacer()
                        Text("Text")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()

                
                NavigationLink(destination: AboutScreen()) {
                    HStack {
                        Image(systemName: "person.fill")
                            .imageScale(.large)
                        Spacer()
                        Text("About")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()

                NavigationLink(destination: TermAndConditionView()) {
                    HStack {
                        Image(systemName: "doc.plaintext.fill")
                            .imageScale(.large)
                        Spacer()
                        Text("Terms and Conditions")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()

                NavigationLink(destination: SupportScreen()) {
                    HStack {
                        Image(systemName: "lifepreserver.fill")
                            .imageScale(.large)
                        Spacer()
                        Text("Support")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                
            }
            
            Spacer()

            VStack {
                Image("mcgill-university-logo-png-transparent-cropped")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                Text("Design and develop by SRL")
                    .font(.caption)
                    .foregroundColor(.black)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray)
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            withAnimation {
                isShowingSideMenu = false
            }
        }
    }
}

struct StoryboardViewBus: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Bus", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "Bus")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
          // Implement this method if you need to update the view controller in response to SwiftUI updates.
      }
  }

struct StoryboardViewDoor: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Door", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "Door")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
          // Implement this method if you need to update the view controller in response to SwiftUI updates.
      }
  }


struct StoryboardViewImageClassification: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "ImageClassification", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ImageClassification")
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Optionally update the view controller here
    }
}

struct StoryBoardViewTextDetectionCoreML: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "TextDetectionCoreML", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "TextDetectionCoreML")
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Optionally update the view controller here
    }

    typealias UIViewControllerType = UIViewController
}


struct StoryboardViewCybsGuidance: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "CybsGuidance", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier:"CybsGuidance")
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Optionally update the view controller here
    }
}

struct StoryboardViewText: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Text", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "Text")
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Optionally update the view controller here
    }
}

struct StoryboardViewSegmentation: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "ImageSegmentation", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ImageSegmentation")
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Optionally update the view controller here
    }
}

// New wrapper for the Room storyboard
struct StoryboardViewRoom: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Room", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "Room")
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Optionally update the view controller here
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
