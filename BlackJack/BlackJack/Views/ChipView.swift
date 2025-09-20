import SwiftUI

struct ChipView: View {
    let value: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Chip image based on value
                Image(chipImageName(for: value))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                
                // Value text overlay with black text and white outline
                Text("\(value)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .shadow(color: .white, radius: 0.5, x: 0, y: 0)
                    .shadow(color: .white, radius: 0.5, x: 0, y: 0)
                    .shadow(color: .white, radius: 0.5, x: 0, y: 0)
                    .shadow(color: .white, radius: 0.5, x: 0, y: 0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
    
    private func chipImageName(for value: Int) -> String {
        switch value {
        case 1: return "Chip1"
        case 10: return "Chip10"
        case 25: return "Chip25"
        case 50: return "Chip50"
        case 100: return "Chip100"
        case 1000: return "Chip1000"
        default: return "chip_red"
        }
    }
}

struct ChipView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            ChipView(value: 10) { }
            ChipView(value: 25) { }
            ChipView(value: 100) { }
        }
        .padding()
        .background(Color.green.opacity(0.3))
    }
}