import SwiftUI

struct IntersectionCrossing: View {
    var body: some View {
        ZStack {
            Color.sunsetOrange
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Image(systemName: "figure.walk")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .foregroundColor(.white)
                
                Text("Intersection Crossing")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
    }
}

// Custom Color extension
extension Color {
    static let sunsetOrange = Color(red: 0.98, green: 0.75, blue: 0.45)
}

#Preview {
    IntersectionCrossing()
}
