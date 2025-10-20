import SwiftUI

struct SupportScreen: View {
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Support")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Empowering the visually impaired with smart, seamless navigation and environment awareness through innovative smartphone and camera integration.")
                                .font(.body)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)

                            Text("For any technical support, contact:")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.black)

                            Text("SRL")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.black)

                            HStack {
                                Text("Email: ")
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)

                                Link("srl@mail.mcgill.ca", destination: URL(string: "mailto:srl@mail.mcgill.ca")!)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SupportScreen_Previews: PreviewProvider {
    static var previews: some View {
        SupportScreen()
    }
}
