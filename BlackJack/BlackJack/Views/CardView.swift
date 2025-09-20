import SwiftUI
import Foundation

public struct CardView: View {
    public let card: Card
    var faceUp: Bool = true
    var rotationAngle: Double = 0 // New: rotation in degrees

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(faceUp ? Color.white : Color.gray)
                .shadow(radius: 4)
            if faceUp {
                VStack {
                    Text(card.rank.display)
                        .font(.title3)
                        .foregroundColor(.black)
                    Text(card.suit.rawValue)
                        .font(.caption)
                }
            } else {
                // Enhanced card back design
                ZStack {
                    // Base gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.9),  // Rich purple
                            Color(red: 0.2, green: 0.1, blue: 0.4).opacity(0.9),  // Deep purple
                            Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.9)   // Rich purple
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(6)
                    
                    // Decorative pattern overlay
                    VStack(spacing: 2) {
                        ForEach(0..<8, id: \.self) { row in
                            HStack(spacing: 2) {
                                ForEach(0..<5, id: \.self) { col in
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 3, height: 3)
                                }
                            }
                        }
                    }
                    .padding(8)
                    
                    // Central diamond pattern
                    ZStack {
                        // Outer diamond
                        Diamond()
                            .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), lineWidth: 1.2)  // Gold
                            .frame(width: 22, height: 22)
                        
                        // Inner diamond
                        Diamond()
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3))  // Gold
                            .frame(width: 15, height: 15)
                        
                        // Center dot
                        Circle()
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.9))  // Gold
                            .frame(width: 4, height: 4)
                    }
                    
                    // Corner decorations
                    VStack {
                        HStack {
                            cornerDecoration
                            Spacer()
                            cornerDecoration
                                .rotationEffect(.degrees(90))
                        }
                        Spacer()
                        HStack {
                            cornerDecoration
                                .rotationEffect(.degrees(270))
                            Spacer()
                            cornerDecoration
                                .rotationEffect(.degrees(180))
                        }
                    }
                    .padding(6)
                }
                .padding(2)
            }
        }
        .frame(width: 45, height: 68)
        .rotation3DEffect(
            .degrees(rotationAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
    }
}

    // Corner decoration helper
    private var cornerDecoration: some View {
        VStack(spacing: 1) {
            Rectangle()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6))  // Gold
                .frame(width: 8, height: 1)
            Rectangle()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6))  // Gold
                .frame(width: 6, height: 1)
            Rectangle()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6))  // Gold
                .frame(width: 4, height: 1)
        }
    }


// Diamond shape for the center decoration
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfWidth = rect.width / 2
        let halfHeight = rect.height / 2
        
        path.move(to: CGPoint(x: center.x, y: center.y - halfHeight))
        path.addLine(to: CGPoint(x: center.x + halfWidth, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + halfHeight))
        path.addLine(to: CGPoint(x: center.x - halfWidth, y: center.y))
        path.closeSubpath()
        
        return path
    }
}

// Navy color extension
extension Color {
    static let navy = Color(red: 0.0, green: 0.0, blue: 0.5)
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            CardView(card: Card(suit: .spades, rank: .ace), faceUp: true)
            CardView(card: Card(suit: .hearts, rank: .king), faceUp: false)
        }
    }
}
