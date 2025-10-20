import SwiftUI

struct AboutScreen: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    Image("logoName")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                    
                    Text("""
                        Project Details for the SRL:
                        
                        This Project Amish to leverage the benefits of smartphones, possibly carried on a neck-worn lanyard, or connected to external devices such as a head worn panoramic camera systems, to provide the navigation assistance for the visually impaired community.
                        
                        1. Safely guiding user during interaction crossing to avoid veering, which can be dangerous and stressful.
                        
                        2. Helping them navigate the last few meters to doorways they wish to enter and directing them to important points in the environment such as stairways and bus shelters
                        
                        3. Switching between different app services including navigation function such as those listed above and other services including OCR, product Identification and Environment Description, based on contextual information and personalisation.
                        
                        Our Proposed approach combines a machine learning strategy and leveraging existing image dataset, possibly augmented by crowdsourcing and iterative design of the feedback mechanisms. This is informed by our lab’s experience with sensor-based intersection crossing assistance systems.
                        """)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .foregroundColor(.black)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.leading)
                    
                    Link("For more information, visit: SRL McGill", destination: URL(string: "https://srl.mcgill.ca/projects/")!)
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .padding()
            }
            .navigationTitle("About")
            .background(Color(UIColor.systemBackground))
        }
    }
}

#Preview {
    AboutScreen()
}
