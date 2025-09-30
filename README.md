# 🎰 SpadeBet

A premium iOS Blackjack game built with SwiftUI featuring authentic casino gameplay, in-app purchases, and modern UI design.

![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green.svg)
![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)

## ✨ Features

### 🎮 Core Gameplay
- **Authentic Blackjack Rules** - Professional dealer AI following standard casino rules
- **Split Hands** - Split pairs and play multiple hands simultaneously
- **Insurance Betting** - Take insurance when dealer shows an Ace
- **Double Down** - Double your bet and receive exactly one more card
- **Hit/Stand** - Standard blackjack actions with smooth animations

### 💰 Monetization
- **Free to Play** - Start with $2,000 in free chips
- **Watch Ads** - Earn 50 free chips by watching short advertisements
- **In-App Purchases** - 6 different chip packages ranging from $1.99 to $99.99
- **No Subscription** - One-time purchases only

### 🎨 User Experience
- **Modern SwiftUI Interface** - Clean, intuitive design with smooth animations
- **Casino Atmosphere** - Gold and black theme with authentic sound effects
- **Card Animations** - Realistic card dealing with flip animations
- **Statistics Tracking** - Monitor your wins, losses, and overall performance
- **Data Persistence** - Your progress is automatically saved

### ⚙️ Customization
- **Dealer Speed Settings** - Adjust how fast the dealer reveals cards
- **Sound Controls** - Toggle sound effects on/off
- **Settings Management** - Customize your gaming experience

## 📱 Screenshots

*Screenshots will be added here showing the main menu, gameplay, and in-app purchase screens*

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 18.0 or later
- macOS 14.0 or later (for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/SpadeBet.git
   cd SpadeBet
   ```

2. **Open in Xcode**
   ```bash
   open BlackJack/BlackJack.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Configuration

#### In-App Purchases Setup
1. Open `Configuration.storekit` in Xcode
2. Configure the 6 product IDs:
   - `com.spadebet.blackjack.chips.5000` - Starter Pack ($1.99)
   - `com.spadebet.blackjack.chips.30000` - Value Pack ($4.99)
   - `com.spadebet.blackjack.chips.200000` - Premium Pack ($24.99)
   - `com.spadebet.blackjack.chips.500000` - Elite Pack ($49.99)
   - `com.spadebet.blackjack.chips.1200000` - Ultimate Pack ($99.99)
   - `com.spadebet.blackjack.chips.100000` - Deluxe Pack ($14.99)

3. Set up corresponding products in App Store Connect

## 🏗️ Architecture

### Project Structure
```
BlackJack/
├── Models/
│   ├── BlackjackGame.swift      # Core game logic
│   ├── Card.swift              # Card model
│   ├── Deck.swift              # Deck management
│   ├── Hand.swift              # Hand logic
│   ├── GameState.swift         # Game state management
│   ├── StoreManager.swift      # In-app purchase handling
│   ├── SoundManager.swift      # Audio management
│   └── SplitGameManager.swift  # Split hand logic
├── Views/
│   ├── ContentView.swift       # Main app container
│   ├── MainMenuView.swift      # Main menu screen
│   ├── GameView.swift          # Gameplay screen
│   ├── SettingsView.swift      # Settings screen
│   ├── StatsView.swift         # Statistics screen
│   └── AddFundsView.swift      # In-app purchase screen
└── Assets.xcassets/            # App icons and images
```

### Key Components

#### Game Logic (`BlackjackGame.swift`)
- Handles all blackjack rules and game flow
- Manages dealer AI and decision making
- Processes player actions (hit, stand, double down, split, insurance)

#### State Management (`GameState.swift`)
- Manages player balance and betting
- Handles data persistence with UserDefaults
- Tracks game statistics

#### In-App Purchases (`StoreManager.swift`)
- Integrates with StoreKit 2
- Handles product loading and purchase processing
- Manages purchase validation and error handling

#### UI Components
- **SwiftUI Views** - Modern, declarative UI
- **Custom Animations** - Smooth card dealing and transitions
- **Responsive Design** - Adapts to different iPhone sizes

## 🎯 Game Rules

### Standard Blackjack Rules
- **Objective**: Get as close to 21 as possible without going over
- **Card Values**: 
  - Number cards: Face value
  - Face cards (J, Q, K): 10 points
  - Ace: 1 or 11 points (player's choice)
- **Blackjack**: 21 with exactly 2 cards (Ace + 10-value card)
- **Dealer**: Must hit on 16 or less, stand on 17 or more

### Special Actions
- **Split**: Split pairs into two separate hands
- **Double Down**: Double your bet and receive exactly one more card
- **Insurance**: Bet half your original bet when dealer shows an Ace

## 💡 Development

### Adding New Features
1. Create new Swift files in appropriate directories
2. Follow existing code patterns and naming conventions
3. Update this README with new features
4. Test thoroughly on multiple device sizes

### Code Style
- Use SwiftUI best practices
- Follow MVVM architecture pattern
- Keep views focused and reusable
- Add comments for complex logic

### Testing
- Unit tests for game logic
- UI tests for critical user flows
- Test on multiple device sizes
- Verify in-app purchase functionality

## 📊 Analytics & Metrics

The app tracks the following metrics:
- Games played
- Games won/lost
- Total chips earned/spent
- In-app purchase conversion rates
- Ad view completion rates

## 🔒 Privacy & Security

- **Data Storage**: All data stored locally using UserDefaults
- **No Personal Information**: No user data is collected or transmitted
- **In-App Purchases**: Processed securely through Apple's StoreKit
- **Ad Integration**: Uses Apple's AdKit framework

## 🚀 Deployment

### App Store Submission
1. Update version number in Xcode
2. Archive the app
3. Upload to App Store Connect
4. Configure app metadata
5. Submit for review

### Version History
- **v1.0** - Initial release with core blackjack gameplay
- **v1.1** - Added in-app purchases and ad integration
- **v1.2** - Enhanced UI animations and sound effects

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


## 👨‍💻 Author

**David Johnson**
- GitHub: [@dbj0428939](https://github.com/dbj0428939)
- Email: david.b.johnson.dev@gmail.com

## 🙏 Acknowledgments

- **Icons8** - Chip icons and graphics
- **Mixkit** - Sound effects and audio
- **Apple** - SwiftUI framework and StoreKit
- **Blackjack Community** - Game rules and inspiration

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/YOUR_USERNAME/SpadeBet/issues) page
2. Create a new issue with detailed information
3. Contact the developer directly

---

**Made with ❤️ using SwiftUI**

*Enjoy playing SpadeBet! 🎰*
