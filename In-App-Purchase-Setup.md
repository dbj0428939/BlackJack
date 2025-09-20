# In-App Purchase Setup Guide

## Overview
This guide will help you set up in-app purchases for the SpadeBet BlackJack app to allow users to buy chips.

## 1. App Store Connect Setup

### Step 1: Create In-App Purchase Products
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to **Features** → **In-App Purchases**
4. Click **+** to create new products
5. Create the following products:

| Product ID | Reference Name | Display Name | Description | Price |
|------------|----------------|--------------|-------------|-------|
| `com.spadebet.blackjack.chips.5000` | Starter Pack | Starter Pack | 5,000 chips to get you started | $1.99 |
| `com.spadebet.blackjack.chips.30000` | Value Pack | Value Pack | 30,000 chips for great value | $4.99 |
| `com.spadebet.blackjack.chips.100000` | Deluxe Pack | Deluxe Pack | 100,000 chips for serious players | $14.99 |
| `com.spadebet.blackjack.chips.200000` | Premium Pack | Premium Pack | 200,000 chips for premium gaming | $24.99 |
| `com.spadebet.blackjack.chips.500000` | Elite Pack | Elite Pack | 500,000 chips for elite players | $49.99 |
| `com.spadebet.blackjack.chips.1200000` | Ultimate Pack | Ultimate Pack | 1,200,000 chips for ultimate gaming | $99.99 |

### Step 2: Product Configuration
- **Type**: Non-Consumable (chips are permanent)
- **Family Sharing**: Disabled (optional)
- **Review Information**: Add screenshots and description for each product

## 2. Xcode Configuration

### Step 1: Add StoreKit Framework
1. Open your Xcode project
2. Select your target
3. Go to **Build Phases** → **Link Binary With Libraries**
4. Add `StoreKit.framework`

### Step 2: Add StoreKit Configuration File
1. The `Configuration.storekit` file is already included in the project
2. This file is used for testing in-app purchases in the simulator
3. To use it:
   - Go to **Product** → **Scheme** → **Edit Scheme**
   - Select **Run** → **Options**
   - Set **StoreKit Configuration** to `Configuration.storekit`

### Step 3: Enable In-App Purchases
1. Go to **Signing & Capabilities**
2. Add **In-App Purchase** capability

## 3. Testing

### Simulator Testing
1. Use the StoreKit configuration file for testing
2. Run the app in the simulator
3. Go to **Add Funds** → Select any purchase option
4. The purchase will be simulated

### Sandbox Testing
1. Create a sandbox tester account in App Store Connect
2. Sign out of your Apple ID on the device
3. Sign in with the sandbox tester account
4. Test purchases in the app

## 4. Code Implementation

The following files have been implemented:

### StoreManager.swift
- Handles all StoreKit operations
- Manages product loading and purchases
- Provides purchase result handling

### GameView.swift Updates
- Integrated StoreManager
- Added purchase notification handling
- Updated EnhancedAddFundsView with real StoreKit integration

### Key Features
- ✅ Real-time product loading from App Store
- ✅ Dynamic pricing display
- ✅ Purchase verification and completion
- ✅ Error handling and user feedback
- ✅ Restore purchases functionality
- ✅ Loading states and progress indicators

## 5. Production Deployment

### Before Submitting to App Store
1. Ensure all products are approved in App Store Connect
2. Test with sandbox accounts
3. Verify purchase flows work correctly
4. Test restore purchases functionality

### App Store Review
1. Provide clear descriptions of what users get
2. Include screenshots of the purchase flow
3. Ensure compliance with App Store guidelines
4. Test thoroughly before submission

## 6. Troubleshooting

### Common Issues
- **Products not loading**: Check product IDs match exactly
- **Purchase fails**: Verify App Store Connect configuration
- **Sandbox issues**: Ensure using sandbox tester account
- **Verification fails**: Check receipt validation logic

### Debug Tips
- Use console logs to track purchase flow
- Test with different product configurations
- Verify network connectivity
- Check App Store Connect status

## 7. Revenue Optimization

### Pricing Strategy
- Start with lower prices for testing
- A/B test different price points
- Consider regional pricing
- Monitor conversion rates

### User Experience
- Clear value proposition
- Smooth purchase flow
- Immediate feedback
- Easy restore process

## Support
For technical issues, refer to:
- [Apple StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [StoreKit Testing Guide](https://developer.apple.com/documentation/storekit/testing)
