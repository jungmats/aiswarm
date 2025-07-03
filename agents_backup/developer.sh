#!/bin/bash

# Developer Agent - Generates actual working code

set -euo pipefail

TASK_CONTEXT_FILE="$1"

# Read task context
TASK_CONTEXT=$(cat "$TASK_CONTEXT_FILE")
AGENT_ID=$(echo "$TASK_CONTEXT" | jq -r '.agent_id')
TASK_ID=$(echo "$TASK_CONTEXT" | jq -r '.task_id')
DESCRIPTION=$(echo "$TASK_CONTEXT" | jq -r '.description')
WORKSPACE=$(echo "$TASK_CONTEXT" | jq -r '.workspace')
ARTIFACTS_DIR=$(echo "$TASK_CONTEXT" | jq -r '.session_artifacts')

echo "[$AGENT_ID] Starting development task: $TASK_ID"
echo "[$AGENT_ID] Description: $DESCRIPTION"

# Create artifacts and code directories
mkdir -p "$ARTIFACTS_DIR/code"
PROJECT_DIR="$ARTIFACTS_DIR/project"
mkdir -p "$PROJECT_DIR"

# Function to setup project structure and dependencies
setup_project_structure() {
    echo "[$AGENT_ID] Setting up project structure and dependencies"
    
    # Create backend directory structure
    mkdir -p "$PROJECT_DIR/backend/src"/{routes,models,services,middleware,config,utils}
    mkdir -p "$PROJECT_DIR/backend/src/controllers"
    mkdir -p "$PROJECT_DIR/backend/tests"
    
    # Create frontend directory structure  
    mkdir -p "$PROJECT_DIR/frontend/src"/{components,pages,services,hooks,types,store}
    mkdir -p "$PROJECT_DIR/frontend/public"
    
    # Create package.json for backend
    cat > "$PROJECT_DIR/backend/package.json" << 'EOF'
{
  "name": "task-management-backend",
  "version": "1.0.0",
  "description": "Task Management Application Backend",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "jest",
    "test:watch": "jest --watch"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.0",
    "pg": "^8.11.0",
    "redis": "^4.6.7",
    "socket.io": "^4.7.1",
    "multer": "^1.4.5-lts.1",
    "nodemailer": "^6.9.3",
    "joi": "^17.9.2",
    "morgan": "^1.10.0",
    "dotenv": "^16.1.4"
  },
  "devDependencies": {
    "nodemon": "^2.0.22",
    "jest": "^29.5.0",
    "supertest": "^6.3.3"
  }
}
EOF

    # Create package.json for frontend
    cat > "$PROJECT_DIR/frontend/package.json" << 'EOF'
{
  "name": "task-management-frontend",
  "version": "1.0.0",
  "description": "Task Management Application Frontend",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "jest",
    "test:watch": "jest --watch"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.11.2",
    "@reduxjs/toolkit": "^1.9.5",
    "react-redux": "^8.1.0",
    "@mui/material": "^5.13.4",
    "@mui/icons-material": "^5.13.4",
    "@emotion/react": "^11.11.1",
    "@emotion/styled": "^11.11.0",
    "axios": "^1.4.0",
    "socket.io-client": "^4.7.1",
    "react-hook-form": "^7.44.3",
    "date-fns": "^2.30.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.6",
    "@types/react-dom": "^18.2.4",
    "@vitejs/plugin-react": "^4.0.0",
    "typescript": "^5.0.2",
    "vite": "^4.3.9",
    "jest": "^29.5.0",
    "@testing-library/react": "^14.0.0",
    "@testing-library/jest-dom": "^5.16.5"
  }
}
EOF

    # Create environment files
    cat > "$PROJECT_DIR/backend/.env.example" << 'EOF'
PORT=5000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://username:password@localhost:5432/taskmanagement
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=taskmanagement
DATABASE_USER=username
DATABASE_PASSWORD=password

# Redis
REDIS_URL=redis://localhost:6379
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your-refresh-secret-key

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-email-password

# File Upload
UPLOAD_PATH=uploads
MAX_FILE_SIZE=5242880
EOF

    # Create Docker files
    cat > "$PROJECT_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: taskmanagement
      POSTGRES_USER: taskuser
      POSTGRES_PASSWORD: taskpass
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/database/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://taskuser:taskpass@db:5432/taskmanagement
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    volumes:
      - ./backend:/app
      - /app/node_modules

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules

volumes:
  postgres_data:
EOF

    # Create backend Dockerfile
    cat > "$PROJECT_DIR/backend/Dockerfile" << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 5000

CMD ["npm", "run", "dev"]
EOF

    # Create frontend Dockerfile
    cat > "$PROJECT_DIR/frontend/Dockerfile" << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]
EOF

    # Copy database schema from artifacts
    mkdir -p "$PROJECT_DIR/backend/database"
    if [[ -f "$ARTIFACTS_DIR/database_schema.sql" ]]; then
        cp "$ARTIFACTS_DIR/database_schema.sql" "$PROJECT_DIR/backend/database/schema.sql"
    fi

    echo "[$AGENT_ID] Project structure and dependencies setup completed"
}

# Function to implement data layer
implement_data_layer() {
    echo "[$AGENT_ID] Implementing data layer and models"
    
    # Create database connection
    cat > "$PROJECT_DIR/backend/src/config/database.js" << 'EOF'
const { Pool } = require('pg');
const redis = require('redis');

// PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

// Redis connection
const redisClient = redis.createClient({
  url: process.env.REDIS_URL,
});

redisClient.on('error', (err) => {
  console.error('Redis error:', err);
});

redisClient.connect();

module.exports = {
  db: pool,
  redis: redisClient,
};
EOF

    # Create User model
    cat > "$PROJECT_DIR/backend/src/models/User.js" << 'EOF'
const { db } = require('../config/database');
const bcrypt = require('bcryptjs');

class User {
  static async create({ email, password, firstName, lastName, role = 'member' }) {
    const hashedPassword = await bcrypt.hash(password, 12);
    
    const query = `
      INSERT INTO users (email, password_hash, first_name, last_name, role)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, email, first_name, last_name, role, created_at
    `;
    
    const result = await db.query(query, [email, hashedPassword, firstName, lastName, role]);
    return result.rows[0];
  }

  static async findByEmail(email) {
    const query = 'SELECT * FROM users WHERE email = $1 AND is_active = true';
    const result = await db.query(query, [email]);
    return result.rows[0];
  }

  static async findById(id) {
    const query = 'SELECT id, email, first_name, last_name, role, avatar_url, last_login, created_at FROM users WHERE id = $1 AND is_active = true';
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  static async updateProfile(id, updates) {
    const fields = Object.keys(updates);
    const values = Object.values(updates);
    const setClause = fields.map((field, index) => `${field} = $${index + 2}`).join(', ');
    
    const query = `
      UPDATE users 
      SET ${setClause}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING id, email, first_name, last_name, role, avatar_url
    `;
    
    const result = await db.query(query, [id, ...values]);
    return result.rows[0];
  }

  static async verifyPassword(plainPassword, hashedPassword) {
    return bcrypt.compare(plainPassword, hashedPassword);
  }

  static async updateLastLogin(id) {
    const query = 'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1';
    await db.query(query, [id]);
  }
}

module.exports = User;
EOF

    # Create Project model
    cat > "$PROJECT_DIR/backend/src/models/Project.js" << 'EOF'
const { db } = require('../config/database');

class Project {
  static async create({ name, description, ownerId, startDate, endDate }) {
    const query = `
      INSERT INTO projects (name, description, owner_id, start_date, end_date)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    
    const result = await db.query(query, [name, description, ownerId, startDate, endDate]);
    return result.rows[0];
  }

  static async findByUserId(userId, { page = 1, limit = 10, status } = {}) {
    const offset = (page - 1) * limit;
    let query = `
      SELECT p.*, u.first_name || ' ' || u.last_name as owner_name,
             COUNT(DISTINCT pm.user_id) as member_count,
             COUNT(DISTINCT t.id) as task_count
      FROM projects p
      LEFT JOIN users u ON p.owner_id = u.id
      LEFT JOIN project_members pm ON p.id = pm.project_id
      LEFT JOIN tasks t ON p.id = t.project_id
      WHERE (p.owner_id = $1 OR p.id IN (
        SELECT project_id FROM project_members WHERE user_id = $1
      ))
    `;
    
    const params = [userId];
    
    if (status) {
      query += ` AND p.status = $${params.length + 1}`;
      params.push(status);
    }
    
    query += `
      GROUP BY p.id, u.first_name, u.last_name
      ORDER BY p.created_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;
    
    params.push(limit, offset);
    
    const result = await db.query(query, params);
    return result.rows;
  }

  static async findById(id) {
    const query = `
      SELECT p.*, u.first_name || ' ' || u.last_name as owner_name
      FROM projects p
      LEFT JOIN users u ON p.owner_id = u.id
      WHERE p.id = $1
    `;
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  static async update(id, updates) {
    const fields = Object.keys(updates);
    const values = Object.values(updates);
    const setClause = fields.map((field, index) => `${field} = $${index + 2}`).join(', ');
    
    const query = `
      UPDATE projects 
      SET ${setClause}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;
    
    const result = await db.query(query, [id, ...values]);
    return result.rows[0];
  }

  static async delete(id) {
    const query = 'DELETE FROM projects WHERE id = $1';
    await db.query(query, [id]);
  }

  static async addMember(projectId, userId, role = 'member') {
    const query = `
      INSERT INTO project_members (project_id, user_id, role)
      VALUES ($1, $2, $3)
      ON CONFLICT (project_id, user_id) DO UPDATE SET role = $3
      RETURNING *
    `;
    
    const result = await db.query(query, [projectId, userId, role]);
    return result.rows[0];
  }

  static async removeMember(projectId, userId) {
    const query = 'DELETE FROM project_members WHERE project_id = $1 AND user_id = $2';
    await db.query(query, [projectId, userId]);
  }

  static async getMembers(projectId) {
    const query = `
      SELECT u.id, u.email, u.first_name, u.last_name, u.avatar_url, pm.role, pm.joined_at
      FROM users u
      JOIN project_members pm ON u.id = pm.user_id
      WHERE pm.project_id = $1
      ORDER BY pm.joined_at
    `;
    
    const result = await db.query(query, [projectId]);
    return result.rows;
  }
}

module.exports = Project;
EOF

    # Create Task model
    cat > "$PROJECT_DIR/backend/src/models/Task.js" << 'EOF'
const { db } = require('../config/database');

class Task {
  static async create({
    title,
    description,
    projectId,
    assigneeId,
    creatorId,
    priority = 'medium',
    dueDate,
    estimatedHours
  }) {
    const query = `
      INSERT INTO tasks (title, description, project_id, assignee_id, creator_id, priority, due_date, estimated_hours)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `;
    
    const result = await db.query(query, [
      title, description, projectId, assigneeId, creatorId, priority, dueDate, estimatedHours
    ]);
    return result.rows[0];
  }

  static async findByProjectId(projectId, filters = {}) {
    let query = `
      SELECT t.*, 
             u1.first_name || ' ' || u1.last_name as assignee_name,
             u2.first_name || ' ' || u2.last_name as creator_name,
             COUNT(tc.id) as comment_count,
             COUNT(ta.id) as attachment_count
      FROM tasks t
      LEFT JOIN users u1 ON t.assignee_id = u1.id
      LEFT JOIN users u2 ON t.creator_id = u2.id
      LEFT JOIN task_comments tc ON t.id = tc.task_id
      LEFT JOIN task_attachments ta ON t.id = ta.task_id
      WHERE t.project_id = $1
    `;
    
    const params = [projectId];
    
    if (filters.status) {
      query += ` AND t.status = $${params.length + 1}`;
      params.push(filters.status);
    }
    
    if (filters.assignee) {
      query += ` AND t.assignee_id = $${params.length + 1}`;
      params.push(filters.assignee);
    }
    
    if (filters.priority) {
      query += ` AND t.priority = $${params.length + 1}`;
      params.push(filters.priority);
    }
    
    query += `
      GROUP BY t.id, u1.first_name, u1.last_name, u2.first_name, u2.last_name
      ORDER BY t.created_at DESC
    `;
    
    const result = await db.query(query, params);
    return result.rows;
  }

  static async findById(id) {
    const query = `
      SELECT t.*, 
             u1.first_name || ' ' || u1.last_name as assignee_name,
             u2.first_name || ' ' || u2.last_name as creator_name,
             p.name as project_name
      FROM tasks t
      LEFT JOIN users u1 ON t.assignee_id = u1.id
      LEFT JOIN users u2 ON t.creator_id = u2.id
      LEFT JOIN projects p ON t.project_id = p.id
      WHERE t.id = $1
    `;
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  static async update(id, updates) {
    const fields = Object.keys(updates);
    const values = Object.values(updates);
    const setClause = fields.map((field, index) => `${field} = $${index + 2}`).join(', ');
    
    const query = `
      UPDATE tasks 
      SET ${setClause}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;
    
    const result = await db.query(query, [id, ...values]);
    return result.rows[0];
  }

  static async delete(id) {
    const query = 'DELETE FROM tasks WHERE id = $1';
    await db.query(query, [id]);
  }

  static async addComment(taskId, userId, content) {
    const query = `
      INSERT INTO task_comments (task_id, user_id, content)
      VALUES ($1, $2, $3)
      RETURNING *
    `;
    
    const result = await db.query(query, [taskId, userId, content]);
    return result.rows[0];
  }

  static async getComments(taskId) {
    const query = `
      SELECT tc.*, u.first_name || ' ' || u.last_name as user_name, u.avatar_url
      FROM task_comments tc
      JOIN users u ON tc.user_id = u.id
      WHERE tc.task_id = $1
      ORDER BY tc.created_at ASC
    `;
    
    const result = await db.query(query, [taskId]);
    return result.rows;
  }
}

module.exports = Task;
EOF

    echo "[$AGENT_ID] Data layer implementation completed"
}

# Function to implement business logic
implement_business_logic() {
    echo "[$AGENT_ID] Implementing core business logic"
    
    # Create authentication service
    cat > "$PROJECT_DIR/backend/src/services/authService.js" << 'EOF'
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { redis } = require('../config/database');

class AuthService {
  static generateTokens(user) {
    const payload = {
      id: user.id,
      email: user.email,
      role: user.role
    };

    const accessToken = jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN || '15m'
    });

    const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
      expiresIn: '7d'
    });

    return { accessToken, refreshToken };
  }

  static async register({ email, password, firstName, lastName }) {
    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      throw new Error('User with this email already exists');
    }

    // Create user
    const user = await User.create({ email, password, firstName, lastName });
    
    // Generate tokens
    const tokens = this.generateTokens(user);
    
    // Store refresh token in Redis
    await redis.setEx(`refresh_token:${user.id}`, 7 * 24 * 60 * 60, tokens.refreshToken);

    return { user, tokens };
  }

  static async login({ email, password }) {
    // Find user
    const user = await User.findByEmail(email);
    if (!user) {
      throw new Error('Invalid credentials');
    }

    // Verify password
    const isValidPassword = await User.verifyPassword(password, user.password_hash);
    if (!isValidPassword) {
      throw new Error('Invalid credentials');
    }

    // Update last login
    await User.updateLastLogin(user.id);

    // Generate tokens
    const tokens = this.generateTokens(user);
    
    // Store refresh token in Redis
    await redis.setEx(`refresh_token:${user.id}`, 7 * 24 * 60 * 60, tokens.refreshToken);

    // Remove password from response
    delete user.password_hash;

    return { user, tokens };
  }

  static async refreshToken(refreshToken) {
    try {
      const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
      
      // Check if refresh token exists in Redis
      const storedToken = await redis.get(`refresh_token:${decoded.id}`);
      if (storedToken !== refreshToken) {
        throw new Error('Invalid refresh token');
      }

      // Get updated user data
      const user = await User.findById(decoded.id);
      if (!user) {
        throw new Error('User not found');
      }

      // Generate new tokens
      const tokens = this.generateTokens(user);
      
      // Update stored refresh token
      await redis.setEx(`refresh_token:${user.id}`, 7 * 24 * 60 * 60, tokens.refreshToken);

      return { user, tokens };
    } catch (error) {
      throw new Error('Invalid refresh token');
    }
  }

  static async logout(userId) {
    // Remove refresh token from Redis
    await redis.del(`refresh_token:${userId}`);
  }

  static verifyAccessToken(token) {
    return jwt.verify(token, process.env.JWT_SECRET);
  }
}

module.exports = AuthService;
EOF

    # Create project service
    cat > "$PROJECT_DIR/backend/src/services/projectService.js" << 'EOF'
const Project = require('../models/Project');

class ProjectService {
  static async createProject(userId, projectData) {
    const project = await Project.create({
      ...projectData,
      ownerId: userId
    });

    // Add creator as owner member
    await Project.addMember(project.id, userId, 'owner');

    return project;
  }

  static async getUserProjects(userId, filters = {}) {
    return Project.findByUserId(userId, filters);
  }

  static async getProjectById(projectId, userId) {
    const project = await Project.findById(projectId);
    if (!project) {
      throw new Error('Project not found');
    }

    // Check if user has access to project
    const hasAccess = await this.checkProjectAccess(projectId, userId);
    if (!hasAccess) {
      throw new Error('Access denied');
    }

    // Get project members
    const members = await Project.getMembers(projectId);
    project.members = members;

    return project;
  }

  static async updateProject(projectId, userId, updates) {
    // Check if user is project owner
    const project = await Project.findById(projectId);
    if (!project || project.owner_id !== userId) {
      throw new Error('Access denied');
    }

    return Project.update(projectId, updates);
  }

  static async deleteProject(projectId, userId) {
    // Check if user is project owner
    const project = await Project.findById(projectId);
    if (!project || project.owner_id !== userId) {
      throw new Error('Access denied');
    }

    await Project.delete(projectId);
  }

  static async addProjectMember(projectId, userId, targetUserId, role = 'member') {
    // Check if user has permission to add members
    const hasPermission = await this.checkProjectPermission(projectId, userId, ['owner', 'manager']);
    if (!hasPermission) {
      throw new Error('Access denied');
    }

    return Project.addMember(projectId, targetUserId, role);
  }

  static async removeProjectMember(projectId, userId, targetUserId) {
    // Check if user has permission to remove members
    const hasPermission = await this.checkProjectPermission(projectId, userId, ['owner', 'manager']);
    if (!hasPermission) {
      throw new Error('Access denied');
    }

    await Project.removeMember(projectId, targetUserId);
  }

  static async checkProjectAccess(projectId, userId) {
    const members = await Project.getMembers(projectId);
    return members.some(member => member.id === userId);
  }

  static async checkProjectPermission(projectId, userId, allowedRoles) {
    const members = await Project.getMembers(projectId);
    const userMember = members.find(member => member.id === userId);
    
    return userMember && allowedRoles.includes(userMember.role);
  }
}

module.exports = ProjectService;
EOF

    # Create task service
    cat > "$PROJECT_DIR/backend/src/services/taskService.js" << 'EOF'
const Task = require('../models/Task');
const ProjectService = require('./projectService');

class TaskService {
  static async createTask(userId, taskData) {
    // Check if user has access to project
    const hasAccess = await ProjectService.checkProjectAccess(taskData.projectId, userId);
    if (!hasAccess) {
      throw new Error('Access denied');
    }

    return Task.create({
      ...taskData,
      creatorId: userId
    });
  }

  static async getProjectTasks(projectId, userId, filters = {}) {
    // Check if user has access to project
    const hasAccess = await ProjectService.checkProjectAccess(projectId, userId);
    if (!hasAccess) {
      throw new Error('Access denied');
    }

    return Task.findByProjectId(projectId, filters);
  }

  static async getTaskById(taskId, userId) {
    const task = await Task.findById(taskId);
    if (!task) {
      throw new Error('Task not found');
    }

    // Check if user has access to project
    const hasAccess = await ProjectService.checkProjectAccess(task.project_id, userId);
    if (!hasAccess) {
      throw new Error('Access denied');
    }

    // Get task comments
    const comments = await Task.getComments(taskId);
    task.comments = comments;

    return task;
  }

  static async updateTask(taskId, userId, updates) {
    const task = await Task.findById(taskId);
    if (!task) {
      throw new Error('Task not found');
    }

    // Check if user has access to project
    const hasAccess = await ProjectService.checkProjectAccess(task.project_id, userId);
    if (!hasAccess) {
      throw new Error('Access denied');
    }

    return Task.update(taskId, updates);
  }

  static async deleteTask(taskId, userId) {
    const task = await Task.findById(taskId);
    if (!task) {
      throw new Error('Task not found');
    }

    // Check if user has permission (creator or project owner/manager)
    const hasPermission = task.creator_id === userId || 
      await ProjectService.checkProjectPermission(task.project_id, userId, ['owner', 'manager']);
    
    if (!hasPermission) {
      throw new Error('Access denied');
    }

    await Task.delete(taskId);
  }

  static async addTaskComment(taskId, userId, content) {
    const task = await Task.findById(taskId);
    if (!task) {
      throw new Error('Task not found');
    }

    // Check if user has access to project
    const hasAccess = await ProjectService.checkProjectAccess(task.project_id, userId);
    if (!hasAccess) {
      throw new Error('Access denied');
    }

    return Task.addComment(taskId, userId, content);
  }
}

module.exports = TaskService;
EOF

    echo "[$AGENT_ID] Business logic implementation completed"
}

# Function to implement API endpoints
implement_api_endpoints() {
    echo "[$AGENT_ID] Implementing API endpoints"
    
    # Create authentication middleware
    cat > "$PROJECT_DIR/backend/src/middleware/auth.js" << 'EOF'
const AuthService = require('../services/authService');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        error: { code: 'UNAUTHORIZED', message: 'Access token required' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = AuthService.verifyAccessToken(token);
    
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ 
      success: false, 
      error: { code: 'UNAUTHORIZED', message: 'Invalid or expired token' }
    });
  }
};

module.exports = { authenticate };
EOF

    # Create validation middleware
    cat > "$PROJECT_DIR/backend/src/middleware/validation.js" << 'EOF'
const Joi = require('joi');

const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details: error.details.map(detail => ({
            field: detail.path.join('.'),
            message: detail.message
          }))
        }
      });
    }
    next();
  };
};

// Validation schemas
const schemas = {
  register: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(8).required(),
    firstName: Joi.string().required(),
    lastName: Joi.string().required()
  }),

  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  }),

  createProject: Joi.object({
    name: Joi.string().required(),
    description: Joi.string().allow(''),
    startDate: Joi.date().allow(null),
    endDate: Joi.date().allow(null)
  }),

  createTask: Joi.object({
    title: Joi.string().required(),
    description: Joi.string().allow(''),
    projectId: Joi.number().required(),
    assigneeId: Joi.number().allow(null),
    priority: Joi.string().valid('low', 'medium', 'high', 'urgent').default('medium'),
    dueDate: Joi.date().allow(null),
    estimatedHours: Joi.number().allow(null)
  }),

  addComment: Joi.object({
    content: Joi.string().required()
  })
};

module.exports = { validate, schemas };
EOF

    # Create auth controller
    cat > "$PROJECT_DIR/backend/src/controllers/authController.js" << 'EOF'
const AuthService = require('../services/authService');

class AuthController {
  static async register(req, res) {
    try {
      const result = await AuthService.register(req.body);
      
      res.status(201).json({
        success: true,
        user: result.user,
        token: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        error: {
          code: 'REGISTRATION_ERROR',
          message: error.message
        }
      });
    }
  }

  static async login(req, res) {
    try {
      const result = await AuthService.login(req.body);
      
      res.json({
        success: true,
        user: result.user,
        token: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken
      });
    } catch (error) {
      res.status(401).json({
        success: false,
        error: {
          code: 'LOGIN_ERROR',
          message: error.message
        }
      });
    }
  }

  static async refreshToken(req, res) {
    try {
      const { refreshToken } = req.body;
      const result = await AuthService.refreshToken(refreshToken);
      
      res.json({
        success: true,
        user: result.user,
        token: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken
      });
    } catch (error) {
      res.status(401).json({
        success: false,
        error: {
          code: 'REFRESH_ERROR',
          message: error.message
        }
      });
    }
  }

  static async logout(req, res) {
    try {
      await AuthService.logout(req.user.id);
      
      res.json({
        success: true,
        message: 'Logged out successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: {
          code: 'LOGOUT_ERROR',
          message: error.message
        }
      });
    }
  }
}

module.exports = AuthController;
EOF

    # Create auth routes
    cat > "$PROJECT_DIR/backend/src/routes/auth.js" << 'EOF'
const express = require('express');
const AuthController = require('../controllers/authController');
const { validate, schemas } = require('../middleware/validation');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.post('/register', validate(schemas.register), AuthController.register);
router.post('/login', validate(schemas.login), AuthController.login);
router.post('/refresh', AuthController.refreshToken);
router.post('/logout', authenticate, AuthController.logout);

module.exports = router;
EOF

    # Create main server file
    cat > "$PROJECT_DIR/backend/src/server.js" << 'EOF'
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const http = require('http');
const socketIo = require('socket.io');

const authRoutes = require('./routes/auth');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: process.env.CLIENT_URL || "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/v1/auth', authRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join-project', (projectId) => {
    socket.join(`project-${projectId}`);
    console.log(`User ${socket.id} joined project ${projectId}`);
  });

  socket.on('leave-project', (projectId) => {
    socket.leave(`project-${projectId}`);
    console.log(`User ${socket.id} left project ${projectId}`);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Internal server error'
    }
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: 'Endpoint not found'
    }
  });
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = { app, io };
EOF

    echo "[$AGENT_ID] API endpoints implementation completed"
}

# Function to implement user interface
implement_user_interface() {
    echo "[$AGENT_ID] Implementing user interface"
    
    # Create Vite config
    cat > "$PROJECT_DIR/frontend/vite.config.ts" << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true
      }
    }
  }
})
EOF

    # Create main App component
    cat > "$PROJECT_DIR/frontend/src/App.tsx" << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { Provider } from 'react-redux';
import { store } from './store/store';

import Layout from './components/Layout/Layout';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Projects from './pages/Projects';
import ProjectDetail from './pages/ProjectDetail';
import TaskDetail from './pages/TaskDetail';
import ProtectedRoute from './components/ProtectedRoute';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

function App() {
  return (
    <Provider store={store}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Router>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
              <Route index element={<Navigate to="/dashboard" replace />} />
              <Route path="dashboard" element={<Dashboard />} />
              <Route path="projects" element={<Projects />} />
              <Route path="projects/:id" element={<ProjectDetail />} />
              <Route path="tasks/:id" element={<TaskDetail />} />
            </Route>
          </Routes>
        </Router>
      </ThemeProvider>
    </Provider>
  );
}

export default App;
EOF

    # Create main entry point
    cat > "$PROJECT_DIR/frontend/src/main.tsx" << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

    # Create Redux store
    cat > "$PROJECT_DIR/frontend/src/store/store.ts" << 'EOF'
import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import projectReducer from './slices/projectSlice';
import taskReducer from './slices/taskSlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    projects: projectReducer,
    tasks: taskReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
EOF

    # Create auth slice
    cat > "$PROJECT_DIR/frontend/src/store/slices/authSlice.ts" << 'EOF'
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import authService from '../../services/authService';

interface User {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  role: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  loading: boolean;
  error: string | null;
}

const initialState: AuthState = {
  user: null,
  token: localStorage.getItem('token'),
  loading: false,
  error: null,
};

export const login = createAsyncThunk(
  'auth/login',
  async ({ email, password }: { email: string; password: string }) => {
    const response = await authService.login(email, password);
    return response.data;
  }
);

export const register = createAsyncThunk(
  'auth/register',
  async (userData: { email: string; password: string; firstName: string; lastName: string }) => {
    const response = await authService.register(userData);
    return response.data;
  }
);

export const logout = createAsyncThunk('auth/logout', async () => {
  await authService.logout();
});

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    setCredentials: (state, action: PayloadAction<{ user: User; token: string }>) => {
      state.user = action.payload.user;
      state.token = action.payload.token;
      localStorage.setItem('token', action.payload.token);
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(login.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.loading = false;
        state.user = action.payload.user;
        state.token = action.payload.token;
        localStorage.setItem('token', action.payload.token);
      })
      .addCase(login.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Login failed';
      })
      .addCase(register.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(register.fulfilled, (state, action) => {
        state.loading = false;
        state.user = action.payload.user;
        state.token = action.payload.token;
        localStorage.setItem('token', action.payload.token);
      })
      .addCase(register.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Registration failed';
      })
      .addCase(logout.fulfilled, (state) => {
        state.user = null;
        state.token = null;
        localStorage.removeItem('token');
      });
  },
});

export const { clearError, setCredentials } = authSlice.actions;
export default authSlice.reducer;
EOF

    # Create login page
    cat > "$PROJECT_DIR/frontend/src/pages/Login.tsx" << 'EOF'
import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAppDispatch, useAppSelector } from '../hooks/redux';
import { login, clearError } from '../store/slices/authSlice';
import {
  Container,
  Paper,
  TextField,
  Button,
  Typography,
  Box,
  Alert,
  CircularProgress,
} from '@mui/material';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { loading, error, user } = useAppSelector((state) => state.auth);

  useEffect(() => {
    if (user) {
      navigate('/dashboard');
    }
  }, [user, navigate]);

  useEffect(() => {
    return () => {
      dispatch(clearError());
    };
  }, [dispatch]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await dispatch(login({ email, password })).unwrap();
      navigate('/dashboard');
    } catch (err) {
      // Error is handled by the slice
    }
  };

  return (
    <Container component="main" maxWidth="xs">
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <Paper elevation={3} sx={{ padding: 4, width: '100%' }}>
          <Typography component="h1" variant="h4" align="center" gutterBottom>
            Task Manager
          </Typography>
          <Typography component="h2" variant="h5" align="center" gutterBottom>
            Sign In
          </Typography>
          
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1 }}>
            <TextField
              margin="normal"
              required
              fullWidth
              id="email"
              label="Email Address"
              name="email"
              autoComplete="email"
              autoFocus
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={loading}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              name="password"
              label="Password"
              type="password"
              id="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={loading}
            />
            <Button
              type="submit"
              fullWidth
              variant="contained"
              sx={{ mt: 3, mb: 2 }}
              disabled={loading}
            >
              {loading ? <CircularProgress size={24} /> : 'Sign In'}
            </Button>
            <Box textAlign="center">
              <Link to="/register">
                Don't have an account? Sign Up
              </Link>
            </Box>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
};

export default Login;
EOF

    # Create API service
    cat > "$PROJECT_DIR/frontend/src/services/authService.ts" << 'EOF'
import axios from 'axios';

const API_URL = '/api/v1/auth';

const authService = {
  async login(email: string, password: string) {
    return axios.post(`${API_URL}/login`, { email, password });
  },

  async register(userData: { email: string; password: string; firstName: string; lastName: string }) {
    return axios.post(`${API_URL}/register`, userData);
  },

  async logout() {
    const token = localStorage.getItem('token');
    if (token) {
      await axios.post(`${API_URL}/logout`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      });
    }
    localStorage.removeItem('token');
  },

  async refreshToken(refreshToken: string) {
    return axios.post(`${API_URL}/refresh`, { refreshToken });
  }
};

export default authService;
EOF

    # Create type definitions
    cat > "$PROJECT_DIR/frontend/src/types/index.ts" << 'EOF'
export interface User {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  role: string;
  avatarUrl?: string;
  lastLogin?: string;
  createdAt: string;
}

export interface Project {
  id: number;
  name: string;
  description?: string;
  ownerId: number;
  ownerName: string;
  status: 'active' | 'completed' | 'archived';
  startDate?: string;
  endDate?: string;
  memberCount: number;
  taskCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface Task {
  id: number;
  title: string;
  description?: string;
  projectId: number;
  projectName: string;
  assigneeId?: number;
  assigneeName?: string;
  creatorId: number;
  creatorName: string;
  status: 'todo' | 'in_progress' | 'review' | 'done';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  dueDate?: string;
  estimatedHours?: number;
  actualHours?: number;
  createdAt: string;
  updatedAt: string;
}

export interface Comment {
  id: number;
  taskId: number;
  userId: number;
  userName: string;
  content: string;
  createdAt: string;
  updatedAt: string;
}
EOF

    echo "[$AGENT_ID] User interface implementation completed"
}

# Execute based on task type
case "$TASK_ID" in
    "impl_001")
        setup_project_structure
        ;;
    "impl_002")
        implement_data_layer
        ;;
    "impl_003")
        implement_business_logic
        ;;
    "impl_004")
        implement_api_endpoints
        ;;
    "impl_005")
        implement_user_interface
        ;;
    *)
        echo "[$AGENT_ID] Unknown implementation task: $TASK_ID"
        exit 1
        ;;
esac

echo "[$AGENT_ID] Development task completed successfully"