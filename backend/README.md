# RotNot Backend

## Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Language**: TypeScript
- **Dev Tools**: nodemon, ts-node, ESLint, Prettier

## Prerequisites

- Node.js (v18 or higher)
- npm or yarn

## Project Structure

```
backend/
├── src/
│   ├── config/              # Configuration files (db, firebase)
│   ├── controllers/         # Request handlers
│   │   ├── donation.controller.ts
│   │   ├── food.controller.ts
│   │   ├── foodBank.controller.ts
│   │   ├── foodDetection.controller.ts
│   │   ├── health.controller.ts
│   │   ├── protected.controller.ts
│   │   └── userProfile.controller.ts
│   ├── models/              # Mongoose schemas
│   │   ├── donatedFood.model.ts
│   │   ├── donation.model.ts
│   │   ├── foodBank.model.ts
│   │   ├── foodItem.model.ts
│   │   └── userProfile.model.ts
│   ├── routes/              # API route definitions
│   │   ├── donation.routes.ts
│   │   ├── food.routes.ts
│   │   ├── foodBank.routes.ts
│   │   ├── foodDetection.routes.ts
│   │   ├── protected.routes.ts
│   │   ├── user.routes.ts
│   │   └── index.ts
│   ├── middlewares/         # Custom middleware
│   │   ├── auth.ts          # Firebase auth
│   │   ├── errorHandler.ts
│   │   └── notFound.ts
│   ├── services/            # Business logic
│   │   └── expiry.service.ts
│   ├── scripts/             # Database utilities
│   │   ├── clearData.ts
│   │   ├── seed.ts
│   │   └── seedFoodBanks.ts
│   ├── utils/               # Helper functions
│   │   └── logger.ts
│   ├── types/               # TypeScript types
│   ├── app.ts               # Express app setup
│   └── server.ts            # Server entry point
├── package.json
├── tsconfig.json
└── nodemon.json
```
