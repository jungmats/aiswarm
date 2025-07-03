#!/bin/bash

# Architect Agent - System design and architecture decisions

set -euo pipefail

TASK_CONTEXT_FILE="$1"

# Read task context
TASK_CONTEXT=$(cat "$TASK_CONTEXT_FILE")
AGENT_ID=$(echo "$TASK_CONTEXT" | jq -r '.agent_id')
TASK_ID=$(echo "$TASK_CONTEXT" | jq -r '.task_id')
DESCRIPTION=$(echo "$TASK_CONTEXT" | jq -r '.description')
WORKSPACE=$(echo "$TASK_CONTEXT" | jq -r '.workspace')
ARTIFACTS_DIR=$(echo "$TASK_CONTEXT" | jq -r '.session_artifacts')

echo "[$AGENT_ID] Starting architectural task: $TASK_ID"
echo "[$AGENT_ID] Description: $DESCRIPTION"

# Create artifacts directory
mkdir -p "$ARTIFACTS_DIR"

# Function to create system architecture
create_system_architecture() {
    cat > "$ARTIFACTS_DIR/system_architecture.md" << 'EOF'
# System Architecture Document

## Overview
Task management web application with modern, scalable architecture.

## Technology Stack

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL with Redis for caching
- **Authentication**: JWT with refresh tokens
- **Real-time**: Socket.io for WebSocket connections
- **File Storage**: AWS S3 or local file system
- **Email**: Nodemailer with SMTP

### Frontend
- **Framework**: React 18 with TypeScript
- **State Management**: Redux Toolkit
- **UI Library**: Material-UI or Tailwind CSS
- **Real-time**: Socket.io-client
- **Build Tool**: Vite
- **Testing**: Jest + React Testing Library

### Infrastructure
- **Containerization**: Docker
- **Process Management**: PM2
- **Reverse Proxy**: Nginx
- **Monitoring**: Basic logging and health checks

## Architecture Patterns

### Layered Architecture
1. **Presentation Layer** (React Frontend)
2. **API Layer** (Express.js REST endpoints)
3. **Business Logic Layer** (Service classes)
4. **Data Access Layer** (Repository pattern)
5. **Database Layer** (PostgreSQL)

### Key Components
- Authentication Service
- Project Management Service  
- Task Management Service
- Notification Service
- File Management Service
- Reporting Service

## Scalability Considerations
- Horizontal scaling with load balancer
- Database connection pooling
- Redis caching for frequently accessed data
- CDN for static assets
- Asynchronous processing for heavy operations

## Security Architecture
- JWT-based authentication
- Role-based authorization (RBAC)
- Input validation and sanitization
- SQL injection prevention with parameterized queries
- HTTPS encryption
- CORS configuration
- Rate limiting

## Performance Optimization
- Database indexing strategy
- Query optimization
- Caching strategy (Redis)
- Lazy loading for frontend
- Image optimization
- Minification and compression
EOF

    cat > "$ARTIFACTS_DIR/tech_stack_decisions.json" << 'EOF'
{
  "backend": {
    "runtime": "Node.js 18+",
    "framework": "Express.js",
    "database": "PostgreSQL",
    "cache": "Redis", 
    "authentication": "JWT",
    "real_time": "Socket.io",
    "file_storage": "Local/S3",
    "email": "Nodemailer"
  },
  "frontend": {
    "framework": "React 18",
    "language": "TypeScript",
    "state_management": "Redux Toolkit",
    "ui_library": "Material-UI",
    "build_tool": "Vite",
    "testing": "Jest + RTL"
  },
  "infrastructure": {
    "containerization": "Docker",
    "process_manager": "PM2",
    "web_server": "Nginx",
    "monitoring": "Basic logging"
  },
  "rationale": {
    "node_js": "JavaScript ecosystem, good for real-time features",
    "postgresql": "ACID compliance, complex queries, scalability",
    "react": "Component reusability, large ecosystem, team expertise",
    "typescript": "Type safety, better developer experience",
    "redis": "Fast caching, session storage, real-time features"
  }
}
EOF
}

# Function to create data models
create_data_models() {
    cat > "$ARTIFACTS_DIR/data_models.md" << 'EOF'
# Data Models and Schema Design

## Core Entities

### User
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) DEFAULT 'member',
    avatar_url VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Project
```sql
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id INTEGER REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'active',
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Task
```sql
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    assignee_id INTEGER REFERENCES users(id),
    creator_id INTEGER REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'todo',
    priority VARCHAR(50) DEFAULT 'medium',
    due_date TIMESTAMP,
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Project Membership
```sql
CREATE TABLE project_members (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, user_id)
);
```

### Task Comments
```sql
CREATE TABLE task_comments (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### File Attachments
```sql
CREATE TABLE task_attachments (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    uploaded_by INTEGER REFERENCES users(id),
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    file_path VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Time Tracking
```sql
CREATE TABLE time_entries (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_minutes INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Indexes for Performance

```sql
-- User indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);

-- Project indexes  
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_projects_status ON projects(status);

-- Task indexes
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

-- Project member indexes
CREATE INDEX idx_project_members_project ON project_members(project_id);
CREATE INDEX idx_project_members_user ON project_members(user_id);

-- Comment indexes
CREATE INDEX idx_task_comments_task ON task_comments(task_id);
CREATE INDEX idx_task_comments_created ON task_comments(created_at);

-- Attachment indexes
CREATE INDEX idx_task_attachments_task ON task_attachments(task_id);

-- Time entry indexes
CREATE INDEX idx_time_entries_task ON time_entries(task_id);
CREATE INDEX idx_time_entries_user ON time_entries(user_id);
```

## Data Validation Rules

- Email must be valid format and unique
- Password must be at least 8 characters with hash
- Task status: 'todo', 'in_progress', 'review', 'done'
- Task priority: 'low', 'medium', 'high', 'urgent'
- User roles: 'admin', 'manager', 'member'
- Project roles: 'owner', 'manager', 'member'
EOF

    cat > "$ARTIFACTS_DIR/database_schema.sql" << 'EOF'
-- Task Management Application Database Schema

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('admin', 'manager', 'member')),
    avatar_url VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Projects table
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id INTEGER REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Project members table
CREATE TABLE project_members (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('owner', 'manager', 'member')),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, user_id)
);

-- Tasks table
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    assignee_id INTEGER REFERENCES users(id),
    creator_id INTEGER REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'review', 'done')),
    priority VARCHAR(50) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    due_date TIMESTAMP,
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Task comments table
CREATE TABLE task_comments (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Task attachments table
CREATE TABLE task_attachments (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    uploaded_by INTEGER REFERENCES users(id),
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    file_path VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Time tracking table
CREATE TABLE time_entries (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_minutes INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    is_read BOOLEAN DEFAULT false,
    related_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_project_members_project ON project_members(project_id);
CREATE INDEX idx_project_members_user ON project_members(user_id);
CREATE INDEX idx_task_comments_task ON task_comments(task_id);
CREATE INDEX idx_task_attachments_task ON task_attachments(task_id);
CREATE INDEX idx_time_entries_task ON time_entries(task_id);
CREATE INDEX idx_time_entries_user ON time_entries(user_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read);
EOF
}

# Function to create API specifications
create_api_specifications() {
    cat > "$ARTIFACTS_DIR/api_specification.md" << 'EOF'
# REST API Specification

## Base Configuration
- **Base URL**: `/api/v1`
- **Authentication**: Bearer JWT tokens
- **Content-Type**: `application/json`
- **Rate Limiting**: 100 requests per minute per IP

## Authentication Endpoints

### POST /auth/register
Register new user account
```json
Request:
{
  "email": "user@example.com",
  "password": "securePassword123",
  "firstName": "John", 
  "lastName": "Doe"
}

Response (201):
{
  "success": true,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "member"
  },
  "token": "jwt_token_here"
}
```

### POST /auth/login
Authenticate user and receive token
```json
Request:
{
  "email": "user@example.com",
  "password": "securePassword123"
}

Response (200):
{
  "success": true,
  "user": { /* user object */ },
  "token": "jwt_token_here",
  "refreshToken": "refresh_token_here"
}
```

## User Endpoints

### GET /users/profile
Get current user profile

### PUT /users/profile
Update user profile

## Project Endpoints

### GET /projects
Get user's projects with pagination

### POST /projects
Create new project

### GET /projects/:id
Get project details

### PUT /projects/:id
Update project

### DELETE /projects/:id
Delete project

## Task Endpoints

### GET /projects/:projectId/tasks
Get tasks for a project

### POST /projects/:projectId/tasks
Create new task

### GET /tasks/:id
Get task details

### PUT /tasks/:id
Update task

## WebSocket Events

### Real-time Events
- task:updated
- task:comment:new
- project:updated
- user:status

## Error Responses

### Common Error Codes
- VALIDATION_ERROR (400)
- UNAUTHORIZED (401)
- FORBIDDEN (403)
- NOT_FOUND (404)
- INTERNAL_ERROR (500)
EOF
}

# Function for generic architecture tasks
create_generic_architecture() {
    cat > "$ARTIFACTS_DIR/${TASK_ID}_output.md" << EOF
# Architecture Output - $TASK_ID

**Agent:** $AGENT_ID
**Task:** $DESCRIPTION
**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Architecture Analysis

Based on the task requirements, this component focuses on:
- System design principles
- Technology selection rationale  
- Performance and scalability considerations
- Security architecture
- Integration patterns

## Recommendations

[Specific architectural recommendations would be generated here based on the task context]

## Next Steps

1. Review architectural decisions with stakeholders
2. Validate technology choices against requirements
3. Create detailed technical specifications
4. Plan implementation phases

## Dependencies

- Input from requirements analysis
- Technology stack approval
- Infrastructure planning
EOF
}

# Execute based on task type
case "$TASK_ID" in
    "arch_001")
        echo "[$AGENT_ID] Creating system architecture"
        create_system_architecture
        ;;
    "arch_002")
        echo "[$AGENT_ID] Designing data models and schema"
        create_data_models
        ;;
    "arch_003")
        echo "[$AGENT_ID] Defining API specifications"
        create_api_specifications
        ;;
    *)
        echo "[$AGENT_ID] Handling generic architecture task"
        create_generic_architecture
        ;;
esac

echo "[$AGENT_ID] Architecture task completed successfully"