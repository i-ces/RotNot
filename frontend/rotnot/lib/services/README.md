# API Service Usage Guide

## Backend Connection Setup

Your Flutter frontend is now connected to your Node.js/Express backend!

### Backend Configuration
- **Backend URL**: `http://localhost:3000/api`
- **CORS**: Enabled for all origins (development mode)
- **Available Routes**: See backend/src/routes/

### Frontend Configuration

#### Platform-Specific URLs
The backend URL varies by platform:

1. **Android Emulator**: `http://10.0.2.2:3000/api`
   - Android emulator uses special IP `10.0.2.2` to access host machine's localhost

2. **iOS Simulator**: `http://localhost:3000/api`
   - iOS simulator can access localhost directly

3. **Physical Device**: `http://YOUR_COMPUTER_IP:3000/api`
   - Find your computer's IP address:
     - Windows: Run `ipconfig` in terminal, look for IPv4 Address
     - Mac/Linux: Run `ifconfig` or `ip addr`
   - Example: `http://192.168.1.5:3000/api`

4. **Web**: `http://localhost:3000/api`

### Using the API Service

#### 1. Import the service
```dart
import 'package:rotnot/services/api_service.dart';
```

#### 2. Create an instance
```dart
final apiService = ApiService();
```

#### 3. Make API calls

**Health Check:**
```dart
try {
  final health = await apiService.checkHealth();
  print('Backend is healthy: $health');
} catch (e) {
  print('Error: $e');
}
```

**Get Food Items:**
```dart
try {
  final foodItems = await apiService.getFoodItems();
  setState(() {
    _foodItems = foodItems;
  });
} catch (e) {
  print('Error loading food items: $e');
}
```

**Create Food Item:**
```dart
try {
  final newFood = await apiService.createFoodItem({
    'name': 'Apple',
    'category': 'fruit',
    'quantity': 5,
    'expiryDate': '2026-02-15',
  });
  print('Created: $newFood');
} catch (e) {
  print('Error creating food item: $e');
}
```

**User Profile:**
```dart
try {
  // You need to save auth token first after login
  await apiService.saveToken('your_firebase_token_here');
  
  final profile = await apiService.getUserProfile();
  print('User profile: $profile');
} catch (e) {
  print('Error: $e');
}
```

### Starting the Backend

1. Navigate to backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies (if not already done):
   ```bash
   npm install
   ```

3. Start the server:
   ```bash
   npm run dev
   ```

4. Verify it's running:
   - You should see: "🚀 RotNot API server running on port 3000"
   - Test health check: http://localhost:3000/api/health

### Troubleshooting

**Connection Refused:**
- Make sure backend is running (`npm run dev` in backend folder)
- Check if MongoDB is running
- Verify you're using the correct URL for your platform

**CORS Errors:**
- Backend is configured to accept all origins in development
- If you see CORS errors, check backend/.env has `CORS_ORIGIN=*`

**401 Unauthorized:**
- Protected routes require authentication
- Make sure to save the token: `await apiService.saveToken(token)`

**Network Error:**
- Check your firewall isn't blocking the connection
- For physical devices, ensure phone and computer are on same network
