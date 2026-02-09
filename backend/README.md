# RotNot Backend

Backend API for RotNot - Food Waste Management System

## Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Language**: TypeScript
- **Dev Tools**: nodemon, ts-node, ESLint, Prettier

## Prerequisites

- Node.js (v18 or higher)
- npm or yarn

## Getting Started

### Installation

```bash
# Install dependencies
npm install
```

### Environment Setup

```bash
# Copy the example environment file
cp .env.example .env

# Update the .env file with your configuration
```

### Development

```bash
# Run in development mode with hot reload
npm run dev

# Build the project
npm run build

# Run production build
npm start

# Seed database with sample data (⚠️ clears existing data!)
npm run seed

# Seed database in production
npm run seed:prod

# Lint code
npm run lint

# Format code
npm run format
```

### Database Seeding

The project includes a seed script to populate your database with sample data for testing and development.

**⚠️ Warning**: The seed script will delete all existing data before inserting sample data!

```bash
# Seed the database
npm run seed
```

For more details, see [SEEDING.md](./SEEDING.md)

## Project Structure

```
backend/
├── src/
│   ├── config/          # Configuration files
│   ├── controllers/     # Request handlers
│   ├── models/          # Data models
│   ├── routes/          # API routes
│   ├── middlewares/     # Custom middleware
│   ├── services/        # Business logic
│   ├── scripts/         # Database seeding & utilities
│   ├── utils/           # Utility functions
│   ├── types/           # TypeScript types/interfaces
│   ├── app.ts           # Express app setup
│   └── server.ts        # Server entry point
├── dist/                # Compiled JavaScript (generated)
├── .env                 # Environment variables (git-ignored)
├── .env.example         # Environment variables template
├── SEEDING.md           # Database seeding guide
├── tsconfig.json        # TypeScript configuration
├── nodemon.json         # Nodemon configuration
├── .eslintrc.json       # ESLint configuration
└── .prettierrc          # Prettier configuration
```

## API Endpoints

### Health Check

- **GET** `/api/health` - Check API health status

## Available Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build TypeScript to JavaScript
- `npm start` - Run production build
- `npm run seed` - Seed database with sample data (⚠️ clears existing data!)
- `npm run seed:prod` - Seed database in production mode
- `npm run lint` - Lint code with ESLint
- `npm run format` - Format code with Prettier

## Contributing

1. Create a feature branch
2. Make your changes
3. Run linting and formatting
4. Submit a pull request

## License

MIT
