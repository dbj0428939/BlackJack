import SwiftUI

struct BalanceBar: View {
    let balance: Double
    var showAddFunds: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                Text("$")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("\(Int(balance))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Button(action: showAddFunds) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .frame(maxWidth: 120) // Shorter width
    }
}