#!/bin/bash

# Backend Connectivity Verification Script
# Tests frontend-to-backend connectivity through all layers

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Travel Fleet - Backend Connectivity Verification            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test result
test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

echo "📋 Step 1: Checking Configuration Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check backend .env exists
if [ -f "$PROJECT_ROOT/backend/.env" ]; then
    echo "✅ Backend .env file exists"
    test_result 0 ".env file found"
else
    echo "❌ Backend .env file not found"
    test_result 1 ".env file missing"
fi

# Check .env has MONGO_URI with database name
if grep -q "travel-fleet" "$PROJECT_ROOT/backend/.env"; then
    echo "✅ MONGO_URI includes database name"
    test_result 0 "MONGO_URI database name"
else
    echo "❌ MONGO_URI missing database name 'travel-fleet'"
    test_result 1 "MONGO_URI database name"
fi

# Check .env has NODE_ENV
if grep -q "NODE_ENV=production" "$PROJECT_ROOT/backend/.env"; then
    echo "✅ NODE_ENV set to production"
    test_result 0 "NODE_ENV configured"
else
    echo "⚠️  NODE_ENV not set to production"
    test_result 1 "NODE_ENV production"
fi

# Check JWT_SECRET strength
if grep -q "JWT_SECRET=travel_fleet" "$PROJECT_ROOT/backend/.env"; then
    echo "✅ JWT_SECRET configured"
    test_result 0 "JWT_SECRET strength"
else
    echo "⚠️  JWT_SECRET might be weak"
fi

echo ""
echo "📋 Step 2: Checking Frontend Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if app_constants.dart has production URL
if grep -q "travel-fleet.onrender.com" "$PROJECT_ROOT/flutter_app/lib/core/constants/app_constants.dart"; then
    echo "✅ Production Render URL configured"
    test_result 0 "Render production URL"
else
    echo "❌ Render production URL not found"
    test_result 1 "Render production URL"
fi

# Check if API service uses app_constants
if grep -q "AppConstants.baseUrl" "$PROJECT_ROOT/flutter_app/lib/core/services/api_service.dart"; then
    echo "✅ API service uses AppConstants"
    test_result 0 "API service config"
else
    echo "❌ API service not using correct config"
    test_result 1 "API service config"
fi

echo ""
echo "📋 Step 3: Backend Server Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check server.js has CORS enabled
if grep -q "app.use(cors())" "$PROJECT_ROOT/backend/server.js"; then
    echo "✅ CORS enabled in backend"
    test_result 0 "CORS configuration"
else
    echo "❌ CORS not enabled"
    test_result 1 "CORS configuration"
fi

# Check health endpoint
if grep -q "/health" "$PROJECT_ROOT/backend/server.js"; then
    echo "✅ Health endpoint configured"
    test_result 0 "Health endpoint"
else
    echo "❌ Health endpoint missing"
    test_result 1 "Health endpoint"
fi

echo ""
echo "📋 Step 4: MongoDB Connection String"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Extract and display MONGO_URI
if [ -f "$PROJECT_ROOT/backend/.env" ]; then
    MONGO_URI=$(grep "MONGO_URI=" "$PROJECT_ROOT/backend/.env" | cut -d'=' -f2-)
    
    # Check for required parameters
    if [[ $MONGO_URI == *"retryWrites=true"* ]]; then
        echo "✅ retryWrites enabled"
        test_result 0 "retryWrites parameter"
    else
        echo "❌ retryWrites not enabled"
        test_result 1 "retryWrites parameter"
    fi
    
    if [[ $MONGO_URI == *"w=majority"* ]]; then
        echo "✅ Write concern set to majority"
        test_result 0 "Write concern majority"
    else
        echo "❌ Write concern not set"
        test_result 1 "Write concern majority"
    fi
    
    # Display connection string (without password)
    DISPLAY_URI=$(echo "$MONGO_URI" | sed 's/:.*@/:***@/')
    echo "Connection String: mongodb+srv://...@${DISPLAY_URI#*@}"
fi

echo ""
echo "📋 Step 5: Connectivity Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test local backend (if running)
echo -n "Testing local backend (http://localhost:5000/health)... "
if timeout 2 curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Running locally${NC}"
    test_result 0 "Local backend running"
else
    echo -e "${YELLOW}⚠️  Not running locally (expected if only Render deployed)${NC}"
fi

# Test Render production backend
echo -n "Testing Render backend (https://travel-fleet.onrender.com/health)... "
if timeout 5 curl -s -I https://travel-fleet.onrender.com/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Accessible${NC}"
    test_result 0 "Render backend accessible"
    
    # Try to get actual health response
    if response=$(timeout 5 curl -s https://travel-fleet.onrender.com/health 2>/dev/null); then
        echo "Response: $response"
    fi
else
    echo -e "${RED}❌ Not accessible or timing out${NC}"
    test_result 1 "Render backend accessible"
    echo "   Possible reasons:"
    echo "   - Backend not deployed on Render"
    echo "   - Backend not running"
    echo "   - Network connectivity issue"
    echo "   - Long startup time on Render (cold start)"
fi

echo ""
echo "📋 Step 6: Build Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if grep -q "compileSdk=34" "$PROJECT_ROOT/flutter_app/android/gradle.properties"; then
    echo "✅ Android SDK configured"
    test_result 0 "Android SDK"
else
    echo "⚠️  Check Android SDK configuration"
fi

if grep -q "flutter.sdk=" "$PROJECT_ROOT/flutter_app/android/local.properties"; then
    echo "✅ Flutter SDK path set"
    test_result 0 "Flutter SDK path"
else
    echo "❌ Flutter SDK path missing"
    test_result 1 "Flutter SDK path"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Test Summary                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All configuration checks passed!${NC}"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Start backend: cd backend && npm run dev"
    echo "   2. Run Flutter app: cd flutter_app && flutter run"
    echo "   3. Or build APK: flutter build apk --release"
else
    echo -e "${RED}❌ Some checks failed. Review above.${NC}"
    echo ""
    echo "📞 To debug:"
    echo "   1. Check backend .env file: cat backend/.env"
    echo "   2. Start local backend: npm run dev"
    echo "   3. Test health: curl http://localhost:5000/health"
    echo "   4. Check Render logs: Visit Render dashboard"
fi

echo ""
