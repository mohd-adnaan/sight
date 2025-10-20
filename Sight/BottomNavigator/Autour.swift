import SwiftUI

struct Autour: View {
    var body: some View {
        ZStack {
            Color.customMintGreen
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Image(systemName: "arrow.turn.right.up")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
                
                Text("Autour")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
            }
        }
    }
}

// Custom Color extension
extension Color {
    static let customMintGreen = Color(UIColor.systemBackground)

}

// Preview Provider
struct Autour_Previews: PreviewProvider {
    static var previews: some View {
        Autour()
    }
}
