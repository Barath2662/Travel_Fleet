#!/bin/bash
# Travel Fleet - Quick Start Script

echo "============================================"
echo "   Travel Fleet - Quick Start Guide"
echo "============================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Choose what you want to do:${NC}"
echo ""
echo "1. Setup Backend"
echo "2. Setup Flutter App"
echo "3. Build APK"
echo "4. Run App (Debug)"
echo "5. Clean & Setup"
echo "6. Show Help"
echo ""
read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo -e "${YELLOW}Setting up Backend...${NC}"
        cd backend/
        echo "Installing dependencies..."
        npm install
        echo ""
        echo -e "${GREEN}✓ Backend setup complete!${NC}"
        echo "Next steps:"
        echo "1. Create .env file with your configuration"
        echo "2. Ensure MongoDB is running"
        echo "3. Run 'npm start' to start the server"
        ;;
    2)
        echo -e "${YELLOW}Setting up Flutter App...${NC}"
        cd flutter_app/
        echo "Getting Flutter dependencies..."
        flutter pub get
        echo -e "${GREEN}✓ Flutter setup complete!${NC}"
        echo "Next steps:"
        echo "1. Update API URL in lib/core/services/api_service.dart"
        echo "2. Connect your device/emulator"
        echo "3. Run 'flutter run' to start the app"
        ;;
    3)
        echo -e "${YELLOW}Building APK...${NC}"
        cd flutter_app/
        echo "Cleaning build directory..."
        flutter clean
        echo "Getting dependencies..."
        flutter pub get
        echo "Building release APK..."
        flutter build apk --release
        echo ""
        echo -e "${GREEN}✓ APK build complete!${NC}"
        echo "APK location: build/app/outputs/apk/release/app-release.apk"
        echo ""
        read -p "Install on device? (y/n) " install
        if [ "$install" = "y" ]; then
            flutter install
            echo -e "${GREEN}✓ App installed!${NC}"
        fi
        ;;
    4)
        echo -e "${YELLOW}Running Flutter App (Debug)...${NC}"
        cd flutter_app/
        echo "Make sure device/emulator is connected!"
        echo ""
        flutter run
        ;;
    5)
        echo -e "${YELLOW}Full Setup & Clean...${NC}"
        echo "Backend..."
        cd backend/
        npm install
        cd ../flutter_app/
        echo "Flutter..."
        flutter clean
        flutter pub get
        echo -e "${GREEN}✓ Full setup complete!${NC}"
        ;;
    6)
        echo -e "${BLUE}Travel Fleet - Complete Help${NC}"
        echo ""
        echo "Project Structure:"
        echo "  backend/          - Node.js Express server"
        echo "  flutter_app/      - Flutter mobile application"
        echo ""
        echo "Documentation:"
        echo "  BUILD_AND_SETUP_GUIDE.md        - Complete setup guide"
        echo "  ROLE_BASED_UI_IMPLEMENTATION.md - Role system documentation"
        echo "  IMPLEMENTATION_SUMMARY.md       - Summary of changes"
        echo ""
        echo "Getting Started:"
        echo "  1. Setup Backend: npm install && npm start"
        echo "  2. Setup Flutter: flutter pub get && flutter run"
        echo "  3. Build APK: flutter build apk --release"
        echo ""
        echo "Test Credentials:"
        echo "  Owner:    owner@example.com / password123"
        echo "  Employee: employee@example.com / password123"
        echo "  Driver:   driver@example.com / password123"
        echo ""
        echo "Key Features:"
        echo "  ✓ Role-based UI (Owner, Employee, Driver)"
        echo "  ✓ GPS tracking for drivers"
        echo "  ✓ Real-time earnings tracking"
        echo "  ✓ Light & Dark themes"
        echo "  ✓ Complete error handling"
        echo "  ✓ Input validation"
        echo ""
        echo "Configuration:"
        echo "  API URL: lib/core/config/app_config.dart"
        echo "  Backend: backend/.env"
        echo "  Theme: lib/core/theme/app_theme.dart"
        echo ""
        ;;
    *)
        echo "Invalid choice. Please run script again."
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"
