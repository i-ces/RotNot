# Firebase Authentication Middleware Usage

## Overview

The `verifyFirebaseToken` middleware is configured and ready to protect your API routes.

## Features

✅ **RequestUser Interface**
```typescript
export interface RequestUser {
  uid: string;
  email?: string;
  name?: string;
}
```

✅ **RequestWithUser Interface**
```typescript
export interface RequestWithUser extends Request {
  user: RequestUser;
}
```

✅ **Middleware: verifyFirebaseToken**
- Reads Bearer token from Authorization header
- Verifies token using Firebase Admin SDK
- Attaches user info to `req.user`
- Returns 401 if token is missing or invalid
- Returns 500 if Firebase Admin is not initialized

## Setup Required

Before using protected routes, configure Firebase credentials in `.env`:

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
```

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed instructions.

## Example Routes

### Protected Route Example

```typescript
import { Router } from 'express';
import { verifyFirebaseToken } from '../middlewares/auth';

const router = Router();

router.get('/protected', verifyFirebaseToken, (req, res) => {
  // User info is available on req.user
  const { uid, email, name } = req.user!;
  
  res.json({
    success: true,
    message: `Welcome ${name}`,
    userId: uid,
  });
});
```

### Testing with cURL

```bash
# Without token (should return 401 or 500 if Firebase not configured)
curl http://localhost:3000/api/protected

# With valid Firebase token
curl http://localhost:3000/api/protected \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN"
```

### Frontend Integration

```javascript
// Get Firebase ID token
const user = firebase.auth().currentUser;
const idToken = await user.getIdToken();

// Make authenticated request
const response = await fetch('http://localhost:3000/api/protected', {
  headers: {
    'Authorization': `Bearer ${idToken}`,
    'Content-Type': 'application/json'
  }
});

const data = await response.json();
console.log(data);
```

## Available Endpoints

### Public Endpoints
- `GET /api/health` - Health check (no auth required)

### Protected Endpoints
- `GET /api/protected` - Example protected resource
- `GET /api/profile` - Get authenticated user's profile

## Error Responses

### 401 - No Token
```json
{
  "success": false,
  "message": "No token provided. Please provide a valid Firebase ID token."
}
```

### 401 - Invalid Token
```json
{
  "success": false,
  "message": "Invalid token. Please provide a valid Firebase ID token."
}
```

### 401 - Expired Token
```json
{
  "success": false,
  "message": "Token has expired. Please login again."
}
```

### 500 - Firebase Not Initialized
```json
{
  "success": false,
  "message": "Firebase Admin SDK is not initialized"
}
```

## Accessing User Info in Controllers

```typescript
import { Request, Response } from 'express';

export const myController = (req: Request, res: Response) => {
  // User is guaranteed to exist due to verifyFirebaseToken middleware
  const user = req.user!;
  
  console.log('User ID:', user.uid);
  console.log('Email:', user.email);
  console.log('Name:', user.name);
  
  res.json({ success: true, user });
};
```

## Optional Authentication

For routes that work with both authenticated and unauthenticated users:

```typescript
import { optionalFirebaseAuth } from '../middlewares/auth';

router.get('/public-or-private', optionalFirebaseAuth, (req, res) => {
  if (req.user) {
    // User is authenticated
    res.json({ message: `Hello ${req.user.name}` });
  } else {
    // User is not authenticated
    res.json({ message: 'Hello Guest' });
  }
});
```

## Implementation Files

- [middlewares/auth.ts](src/middlewares/auth.ts) - Middleware implementation
- [config/firebase.ts](src/config/firebase.ts) - Firebase Admin initialization
- [routes/protected.routes.ts](src/routes/protected.routes.ts) - Example protected routes
- [controllers/protected.controller.ts](src/controllers/protected.controller.ts) - Example controllers
