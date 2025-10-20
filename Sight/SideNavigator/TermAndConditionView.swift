import SwiftUI

struct TermAndConditionView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Terms and Privacy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Terms of Use")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    
                    Text("By using the Sight app, you agree to the following terms and conditions:")
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(termsOfUse, id: \.self) { term in
                            TermListItem(term: term)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Divider()
                        .padding(.vertical, 20)
                    
                    Text("Privacy Policy")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                    
                    Text("The Sight app collects and stores certain data about your use of the app, such as your location, the time and date of your use, and the pages you visit.")
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(privacyPolicy, id: \.self) { policy in
                            TermListItem(term: policy)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Text("By using the Sight app, you agree to the terms and conditions set forth above.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            }
        }
        .background(Color.white)
    }
}

struct TermListItem: View {
    var term: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(Color.gray)
            Text(term)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

let termsOfUse = [
    "You are solely responsible for your use of the app and for any consequences of such use.",
    "You agree not to use the app for any illegal or unauthorized purposes.",
    "You agree not to interfere with the operation of the app or the servers that host the app.",
    "You agree to indemnify and hold harmless the developers of the Sight app from any and all claims arising from your use of the app."
]

let privacyPolicy = [
    "The Sight app uses this data to improve the app and to provide you with personalized content.",
    "You can opt-out of data collection by disabling location services on your device.",
    "The Sight app does not share your data with any third parties."
]

struct TermAndConditionView_Previews: PreviewProvider {
    static var previews: some View {
        TermAndConditionView()
    }
}
