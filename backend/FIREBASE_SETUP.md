# Firebase Admin SDK Setup Guide

## Overview

Firebase Admin SDK is configured for backend authentication verification. The setup allows you to verify Firebase ID tokens sent from your frontend application.

## Getting Firebase Credentials

### Step 1: Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)

### Step 2: Generate Service Account Key
1. Click on **Project Settings** (gear icon)
2. Navigate to **Service Accounts** tab
3. Click **Generate New Private Key**
4. Download the JSON file

### Step 3: Extract Credentials
Open the downloaded JSON file and extract these values:
- `project_id` → `FIREBASE_PROJECT_ID`
- `private_key` → `FIREBASE_PRIVATE_KEY`
- `client_email` → `FIREBASE_CLIENT_EMAIL`

### Step 4: Configure Environment Variables
Update your `.env` file:

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYourPrivateKeyHere\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
```

**Important Notes:**
- Keep the private key in quotes
- Ensure newlines are escaped as `\n`
- Never commit the `.env` file to version control

## Using Firebase Authentication

### Protecting Routes

Use the `verifyFirebaseToken` middleware to protect routes:

```typescript
import { Router } from 'express';
import { verifyFirebaseToken } from '../middlewares/auth';
import { getProtectedData } from '../controllers/example.controller';

const router = Router();

// Protected route - requires Firebase authentication
router.get('/protected', verifyFirebaseToken, getProtectedData);

export default router;
```

### Accessing User Info in Controllers

Once authenticated, user information is available in `req.user`:

```typescript
import { Request, Response } from 'express';

export const getProtectedData = (req: Request, res: Response) => {
  const user = req.user; // { uid, email, emailVerified, name, picture }
  
  res.json({
    success: true,
    message: `Hello ${user?.name || 'User'}`,
    userId: user?.uid,
  });
};
```

### Optional Authentication

For routes that work for both authenticated and unauthenticated users:

```typescript
import { optionalFirebaseAuth } from '../middlewares/auth';

// This route works with or without authentication
router.get('/public-or-private', optionalFirebaseAuth, controller);
```

## Frontend Integration

Your frontend should send the Firebase ID token in the Authorization header:

```javascript
// Get the ID token from Firebase Auth
const idToken = await firebase.auth().currentUser.getIdToken();

// Send request with token
const response = await fetch('http://localhost:3000/api/protected', {
  headers: {
    'Authorization': `Bearer ${idToken}`
  }
});
```

## Available Exports

From `config/firebase.ts`:
- `default` - Firebase Admin instance
- `auth` - Firebase Auth service
- `firestore` - Firestore database service
- `storage` - Firebase Storage service

## Error Handling

The middleware handles common authentication errors:
- Expired tokens
- Revoked tokens
- Invalid tokens
- Missing tokens

All errors are properly formatted and sent through the error handling middleware.

## Testing

To test authentication:
1. Set up Firebase credentials in `.env`
2. Create a test user in Firebase Console
3. Generate an ID token from your frontend
4. Send requests with the token in the Authorization header

## Security Best Practices

✅ **DO:**
- Store credentials in environment variables
- Use HTTPS in production
- Validate Firebase tokens on every protected route
- Check token expiration

❌ **DON'T:**
- Commit service account keys to version control
- Share private keys publicly
- Accept tokens from untrusted sources
- Skip token verification on sensitive routes
