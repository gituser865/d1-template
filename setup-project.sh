#!/bin/bash

# Task Marketplace - Complete Setup Script
# This script creates the entire project structure with all files

set -e

PROJECT_NAME="task-marketplace"
echo "🚀 Creating Task Marketplace Project..."

# Create main directory
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create directory structure
mkdir -p backend/src/{config,controllers,middleware,models,routes,services}
mkdir -p frontend/{pages,components,store,utils,styles,public}
mkdir -p docs
mkdir -p .github/workflows
mkdir -p uploads

echo "📁 Project structure created..."

# ========================
# BACKEND FILES
# ========================

# backend/package.json
cat > backend/package.json << 'BACKEND_PACKAGE'
{
  "name": "task-marketplace-backend",
  "version": "1.0.0",
  "description": "Task Marketplace Backend API",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "dotenv": "^16.0.3",
    "mongoose": "^7.0.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.0",
    "cors": "^2.8.5",
    "multer": "^1.4.5-lts.1",
    "redis": "^4.6.5",
    "socket.io": "^4.5.4",
    "joi": "^17.9.1",
    "node-cron": "^3.0.2"
  },
  "devDependencies": {
    "nodemon": "^2.0.20",
    "jest": "^29.5.0"
  }
}
BACKEND_PACKAGE

# backend/.env.example
cat > backend/.env.example << 'ENV_FILE'
MONGODB_URI=mongodb://localhost:27017/task-marketplace
REDIS_URL=redis://localhost:6379
JWT_SECRET=your_jwt_secret_key_here_change_in_production
JWT_EXPIRE=7d
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_S3_BUCKET=your_bucket_name
AWS_REGION=us-east-1
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000
POINTS_TO_USD=0.01
MIN_TASK_COST=2
USE_S3=false
ENV_FILE

# backend/.gitignore
cat > backend/.gitignore << 'GITIGNORE'
node_modules/
.env
.env.local
.DS_Store
*.log
uploads/
dist/
.next/
GITIGNORE

# backend/server.js
cat > backend/server.js << 'BACKEND_SERVER'
const app = require('./src/app');
const http = require('http');
const socketIO = require('socket.io');
const connectDB = require('./src/config/database');

require('dotenv').config();

const PORT = process.env.PORT || 5000;

connectDB();

const server = http.createServer(app);

const io = socketIO(server, {
  cors: {
    origin: process.env.FRONTEND_URL,
    methods: ['GET', 'POST'],
  },
});

io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);

  socket.on('join-task', (taskId) => {
    socket.join(`task-${taskId}`);
  });

  socket.on('leave-task', (taskId) => {
    socket.leave(`task-${taskId}`);
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

app.use((req, res, next) => {
  req.io = io;
  next();
});

server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV}`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});
BACKEND_SERVER

# backend/src/app.js
cat > backend/src/app.js << 'BACKEND_APP'
const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Routes would be imported here
// const authRoutes = require('./routes/auth');
// app.use('/api/auth', authRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date() });
});

app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({
    message: err.message || 'Internal server error',
  });
});

module.exports = app;
BACKEND_APP

# backend/src/config/database.js
cat > backend/src/config/database.js << 'DATABASE_CONFIG'
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log(`✅ MongoDB connected: ${conn.connection.host}`);
    return conn;
  } catch (error) {
    console.error(`❌ MongoDB connection failed: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
DATABASE_CONFIG

# backend/src/config/redis.js
cat > backend/src/config/redis.js << 'REDIS_CONFIG'
const redis = require('redis');

const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
});

redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err);
});

redisClient.on('connect', () => {
  console.log('✅ Redis connected');
});

redisClient.connect().catch(console.error);

module.exports = redisClient;
REDIS_CONFIG

# backend/src/models/User.js
cat > backend/src/models/User.js << 'USER_MODEL'
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    walletAddress: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      match: /.+\@.+\..+/,
    },
    password: {
      type: String,
      required: true,
      minlength: 6,
      select: false,
    },
    firstName: String,
    lastName: String,
    bio: String,
    pointsBalance: {
      type: Number,
      default: 0,
    },
    role: {
      type: String,
      enum: ['user', 'creator', 'admin'],
      default: 'user',
    },
    status: {
      type: String,
      enum: ['active', 'suspended', 'banned'],
      default: 'active',
    },
  },
  { timestamps: true }
);

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

userSchema.methods.comparePassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
USER_MODEL

# backend/src/models/Task.js
cat > backend/src/models/Task.js << 'TASK_MODEL'
const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema(
  {
    creatorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: String,
    type: {
      type: String,
      enum: ['website_visit', 'like_post', 'retweet_post', 'follow_account', 'other'],
    },
    submissionType: {
      type: String,
      enum: ['image', 'text', 'link'],
    },
    slotsTotal: Number,
    slotsAvailable: Number,
    amountPerTask: {
      type: Number,
      min: 2,
    },
    status: {
      type: String,
      enum: ['draft', 'pending_admin_approval', 'live', 'completed', 'rejected', 'closed'],
      default: 'draft',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Task', taskSchema);
TASK_MODEL

# backend/src/models/TaskSubmission.js
cat > backend/src/models/TaskSubmission.js << 'SUBMISSION_MODEL'
const mongoose = require('mongoose');

const taskSubmissionSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Task',
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    submissionData: String,
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
    },
    pointsAwarded: Number,
    reviewDeadline: Date,
  },
  { timestamps: true }
);

module.exports = mongoose.model('TaskSubmission', taskSubmissionSchema);
SUBMISSION_MODEL

# backend/src/models/Transaction.js
cat > backend/src/models/Transaction.js << 'TRANSACTION_MODEL'
const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    type: {
      type: String,
      enum: ['earn', 'spend', 'deposit', 'withdraw', 'refund'],
    },
    amount: Number,
    description: String,
  },
  { timestamps: true }
);

module.exports = mongoose.model('Transaction', transactionSchema);
TRANSACTION_MODEL

# backend/src/middleware/auth.js
cat > backend/src/middleware/auth.js << 'AUTH_MIDDLEWARE'
const jwt = require('jsonwebtoken');
const User = require('../models/User');

exports.protect = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      return res.status(401).json({ message: 'Not authorized' });
    }
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = await User.findById(decoded.id);
    next();
  } catch (error) {
    res.status(401).json({ message: 'Not authorized' });
  }
};

exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    next();
  };
};
AUTH_MIDDLEWARE

# backend/src/routes/auth.js
cat > backend/src/routes/auth.js << 'AUTH_ROUTES'
const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

router.post('/register', async (req, res) => {
  try {
    const { walletAddress, email, password } = req.body;
    
    let user = await User.findOne({ $or: [{ walletAddress }, { email }] });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }

    user = await User.create({
      walletAddress: walletAddress.toLowerCase(),
      email: email.toLowerCase(),
      password,
    });

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRE,
    });

    res.status(201).json({ success: true, token, user });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { walletAddress, password } = req.body;
    
    const user = await User.findOne({ walletAddress: walletAddress.toLowerCase() }).select('+password');

    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRE,
    });

    res.json({ success: true, token, user });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
AUTH_ROUTES

echo "✅ Backend files created..."

# ========================
# FRONTEND FILES
# ========================

# frontend/package.json
cat > frontend/package.json << 'FRONTEND_PACKAGE'
{
  "name": "task-marketplace-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^13.4.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "@mui/material": "^5.12.0",
    "@mui/icons-material": "^5.12.0",
    "@emotion/react": "^11.11.0",
    "@emotion/styled": "^11.11.0",
    "axios": "^1.3.4",
    "zustand": "^4.3.6",
    "react-hook-form": "^7.43.8",
    "react-toastify": "^9.1.2"
  }
}
FRONTEND_PACKAGE

# frontend/.env.local.example
cat > frontend/.env.local.example << 'FRONTEND_ENV'
NEXT_PUBLIC_API_URL=http://localhost:5000/api
FRONTEND_ENV

# frontend/pages/_app.tsx
cat > frontend/pages/_app.tsx << 'FRONTEND_APP'
import React from 'react';
import { CssBaseline, ThemeProvider, createTheme } from '@mui/material';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

const theme = createTheme({
  palette: {
    primary: { main: '#667eea' },
    secondary: { main: '#764ba2' },
  },
});

function MyApp({ Component, pageProps }: any) {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Component {...pageProps} />
      <ToastContainer />
    </ThemeProvider>
  );
}

export default MyApp;
FRONTEND_APP

# frontend/pages/index.tsx
cat > frontend/pages/index.tsx << 'FRONTEND_HOME'
import React from 'react';
import { Box, Container, Typography, Button } from '@mui/material';

export default function Home() {
  return (
    <Container maxWidth="lg">
      <Box sx={{ textAlign: 'center', py: 8 }}>
        <Typography variant="h2" sx={{ mb: 2 }}>🎯 Task Marketplace</Typography>
        <Typography variant="h5" color="textSecondary" sx={{ mb: 4 }}>
          Earn points by completing simple tasks
        </Typography>
        <Box sx={{ display: 'flex', gap: 2, justifyContent: 'center' }}>
          <Button variant="contained" href="/auth/register" size="large">Register</Button>
          <Button variant="outlined" href="/auth/login" size="large">Login</Button>
        </Box>
      </Box>
    </Container>
  );
}
FRONTEND_HOME

# frontend/store/useStore.ts
cat > frontend/store/useStore.ts << 'STORE'
import create from 'zustand';

interface User {
  id: string;
  walletAddress: string;
  email: string;
  role: string;
}

interface Store {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  setUser: (user: User) => void;
  setToken: (token: string) => void;
  logout: () => void;
}

export const useStore = create<Store>((set) => ({
  user: null,
  token: null,
  isAuthenticated: false,
  setUser: (user: User) => set({ user, isAuthenticated: true }),
  setToken: (token: string) => set({ token }),
  logout: () => set({ user: null, token: null, isAuthenticated: false }),
}));
STORE

# frontend/utils/api.ts
cat > frontend/utils/api.ts << 'API_UTIL'
import axios from 'axios';
import { useStore } from '../store/useStore';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api',
});

api.interceptors.request.use((config) => {
  const token = useStore.getState().token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;
API_UTIL

echo "✅ Frontend files created..."

# ========================
# DOCKER FILES
# ========================

# docker-compose.yml
cat > docker-compose.yml << 'DOCKER_COMPOSE'
version: '3.8'

services:
  mongodb:
    image: mongo:5
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db

  redis:
    image: redis:7
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    depends_on:
      - mongodb
      - redis
    environment:
      MONGODB_URI: mongodb://mongodb:27017/task-marketplace
      REDIS_URL: redis://redis:6379
      JWT_SECRET: your_secret
      PORT: 5000

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend

volumes:
  mongodb_data:
  redis_data:
DOCKER_COMPOSE

# backend/Dockerfile
cat > backend/Dockerfile << 'BACKEND_DOCKERFILE'
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5000
CMD ["npm", "run", "dev"]
BACKEND_DOCKERFILE

# frontend/Dockerfile
cat > frontend/Dockerfile << 'FRONTEND_DOCKERFILE'
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]
FRONTEND_DOCKERFILE

echo "✅ Docker files created..."

# ========================
# GITHUB FILES
# ========================

# .github/workflows/ci.yml
cat > .github/workflows/ci.yml << 'GITHUB_CI'
name: CI

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '16'
      - run: cd backend && npm install
      - run: cd frontend && npm install
      - run: cd frontend && npm run build
GITHUB_CI

echo "✅ GitHub files created..."

# ========================
# ROOT FILES
# ========================

# .gitignore
cat > .gitignore << 'ROOT_GITIGNORE'
node_modules/
.env
.env.local
.DS_Store
*.log
dist/
.next/
.vercel/
uploads/
ROOT_GITIGNORE

# README.md
cat > README.md << 'README'
# 🎯 Task Marketplace

A blockchain-based task marketplace where users earn points by completing simple tasks.

## 🚀 Quick Start

### Using Docker
```bash
docker-compose up --build