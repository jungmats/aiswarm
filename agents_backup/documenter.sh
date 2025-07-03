#!/bin/bash

# Documenter Agent - Generates comprehensive documentation

set -euo pipefail

TASK_CONTEXT_FILE="$1"

# Read task context
TASK_CONTEXT=$(cat "$TASK_CONTEXT_FILE")
AGENT_ID=$(echo "$TASK_CONTEXT" | jq -r '.agent_id')
TASK_ID=$(echo "$TASK_CONTEXT" | jq -r '.task_id')
DESCRIPTION=$(echo "$TASK_CONTEXT" | jq -r '.description')
WORKSPACE=$(echo "$TASK_CONTEXT" | jq -r '.workspace')
ARTIFACTS_DIR=$(echo "$TASK_CONTEXT" | jq -r '.session_artifacts')

echo "[$AGENT_ID] Starting documentation task: $TASK_ID"
echo "[$AGENT_ID] Description: $DESCRIPTION"

# Create documentation directories
PROJECT_DIR="$ARTIFACTS_DIR/project"
mkdir -p "$PROJECT_DIR/docs"/{technical,user,deployment,api}

# Function to create technical documentation
create_technical_docs() {
    echo "[$AGENT_ID] Creating technical documentation"
    
    # Main README
    cat > "$PROJECT_DIR/README.md" << 'EOF'
# Task Management Application

A modern, scalable task management application built with Node.js, React, and PostgreSQL.

## Features

- **User Authentication & Authorization** - Secure JWT-based authentication
- **Project Management** - Create and manage projects with team collaboration
- **Task Management** - Comprehensive task tracking with assignments and priorities
- **Real-time Collaboration** - Live updates using WebSocket connections
- **File Attachments** - Upload and share files on tasks
- **Time Tracking** - Track time spent on tasks
- **Dashboard & Analytics** - Project overview and progress tracking
- **Mobile Responsive** - Works seamlessly on desktop and mobile devices

## Technology Stack

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL with Redis caching
- **Authentication**: JWT tokens
- **Real-time**: Socket.io
- **File Upload**: Multer
- **Email**: Nodemailer

### Frontend
- **Framework**: React 18 with TypeScript
- **State Management**: Redux Toolkit
- **UI Components**: Material-UI
- **Build Tool**: Vite
- **Testing**: Jest + React Testing Library

### Infrastructure
- **Containerization**: Docker & Docker Compose
- **Database**: PostgreSQL 15
- **Caching**: Redis 7
- **Web Server**: Nginx (production)

## Quick Start

### Prerequisites
- Node.js 18+
- Docker & Docker Compose
- PostgreSQL 15 (if not using Docker)
- Redis 7 (if not using Docker)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd task-management-app
   ```

2. **Setup environment variables**
   ```bash
   cp backend/.env.example backend/.env
   # Edit backend/.env with your configuration
   ```

3. **Start with Docker Compose (Recommended)**
   ```bash
   docker-compose up -d
   ```

4. **Or start manually**
   ```bash
   # Start backend
   cd backend
   npm install
   npm run dev

   # Start frontend (in another terminal)
   cd frontend
   npm install
   npm run dev
   ```

5. **Access the application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000
   - API Health: http://localhost:5000/health

## Project Structure

```
├── backend/                 # Node.js backend
│   ├── src/
│   │   ├── controllers/     # Request handlers
│   │   ├── models/          # Database models
│   │   ├── services/        # Business logic
│   │   ├── middleware/      # Custom middleware
│   │   ├── routes/          # API routes
│   │   ├── config/          # Configuration
│   │   └── utils/           # Utility functions
│   ├── tests/               # Backend tests
│   ├── database/            # Database schemas
│   └── uploads/             # File uploads
├── frontend/                # React frontend
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── pages/           # Page components
│   │   ├── services/        # API services
│   │   ├── store/           # Redux store
│   │   ├── hooks/           # Custom hooks
│   │   └── types/           # TypeScript types
│   └── public/              # Static assets
├── docs/                    # Documentation
├── docker-compose.yml       # Docker services
└── README.md               # This file
```

## API Documentation

The API follows RESTful conventions with JSON responses. All endpoints require authentication except for registration and login.

### Base URL
```
http://localhost:5000/api/v1
```

### Authentication
Include JWT token in Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

See [API Documentation](docs/api/README.md) for detailed endpoint documentation.

## Development

### Backend Development
```bash
cd backend
npm run dev          # Start development server
npm test             # Run tests
npm run test:watch   # Run tests in watch mode
```

### Frontend Development
```bash
cd frontend
npm run dev          # Start development server
npm test             # Run tests
npm run build        # Build for production
```

### Database Management
```bash
# Run migrations
npm run db:migrate

# Seed database
npm run db:seed

# Reset database
npm run db:reset
```

## Testing

### Backend Tests
```bash
cd backend
npm test                    # Run all tests
npm run test:unit          # Run unit tests
npm run test:integration   # Run integration tests
npm run test:coverage      # Run with coverage
```

### Frontend Tests
```bash
cd frontend
npm test                   # Run all tests
npm run test:watch        # Run in watch mode
npm run test:coverage     # Run with coverage
```

## Deployment

See [Deployment Guide](docs/deployment/README.md) for production deployment instructions.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- Create an issue for bug reports or feature requests
- Check the [documentation](docs/) for detailed guides
- Review the [API documentation](docs/api/) for integration help
EOF

    # Technical architecture documentation
    cat > "$PROJECT_DIR/docs/technical/ARCHITECTURE.md" << 'EOF'
# Technical Architecture

## Overview

The Task Management Application follows a modern three-tier architecture with clear separation of concerns:

1. **Presentation Layer** - React frontend with TypeScript
2. **Application Layer** - Node.js REST API with Express.js
3. **Data Layer** - PostgreSQL database with Redis caching

## System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React App     │    │   Express API   │    │   PostgreSQL    │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │     Redis       │
                       │   (Caching)     │
                       └─────────────────┘
```

## Backend Architecture

### Layered Architecture Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Controllers │  │ Middleware  │  │   Routes    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Services   │  │ Validators  │  │   Utils     │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Data Access Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Models    │  │ Repositories│  │   Config    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

#### Controllers
- Handle HTTP requests and responses
- Input validation and sanitization
- Error handling and status codes
- Delegate business logic to services

#### Services
- Contain business logic and rules
- Orchestrate data operations
- Handle complex workflows
- Ensure data consistency

#### Models
- Direct database interaction
- SQL query building
- Data transformation
- Connection management

#### Middleware
- Authentication and authorization
- Request/response logging
- Error handling
- Rate limiting
- CORS handling

### Authentication & Authorization

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Client    │    │   Server    │    │   Database  │
│             │    │             │    │             │
│ 1. Login    │───►│ 2. Verify   │───►│ 3. User     │
│             │    │             │    │   Query     │
│             │    │ 4. Generate │◄───│             │
│             │◄───│   JWT       │    │             │
│ 5. Store    │    │             │    │             │
│   Token     │    │             │    │             │
│             │    │             │    │             │
│ 6. API Req  │───►│ 7. Verify   │    │             │
│   + Token   │    │   JWT       │    │             │
│             │◄───│ 8. Response │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

### Real-time Communication

Socket.io is used for real-time features:

- Task updates and notifications
- Project collaboration
- User presence indicators
- Live comment streams

## Frontend Architecture

### Component Architecture

```
App
├── Layout
│   ├── Header
│   ├── Sidebar
│   └── Footer
├── Pages
│   ├── Dashboard
│   ├── Projects
│   ├── ProjectDetail
│   └── TaskDetail
└── Components
    ├── TaskCard
    ├── ProjectCard
    ├── UserAvatar
    └── Common UI
```

### State Management

Redux Toolkit with slices:

- **Auth Slice** - User authentication state
- **Projects Slice** - Project data and operations
- **Tasks Slice** - Task management state
- **UI Slice** - UI state and preferences

### Data Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Component   │───►│   Action    │───►│   Reducer   │
└─────────────┘    └─────────────┘    └─────────────┘
       ▲                                      │
       │                                      ▼
┌─────────────┐                      ┌─────────────┐
│    Store    │◄─────────────────────│   State     │
└─────────────┘                      └─────────────┘
```

## Database Design

### Entity Relationship Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Users    │◄────│   Projects  │────►│ProjectMembers│
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │
       │                   │
       ▼                   ▼
┌─────────────┐     ┌─────────────┐
│    Tasks    │────►│   Comments  │
└─────────────┘     └─────────────┘
       │
       ▼
┌─────────────┐
│Attachments  │
└─────────────┘
```

### Indexing Strategy

Critical indexes for performance:

```sql
-- User lookup
CREATE INDEX idx_users_email ON users(email);

-- Project queries
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_project_members_project ON project_members(project_id);

-- Task queries
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
```

## Caching Strategy

Redis is used for:

- **Session Management** - JWT refresh tokens
- **Frequently Accessed Data** - User profiles, project lists
- **Real-time Data** - Active users, notifications
- **Rate Limiting** - API request throttling

### Cache Patterns

1. **Cache-Aside** - For user profiles and project data
2. **Write-Through** - For critical updates
3. **Time-based Expiration** - For temporary data

## Security Measures

### Authentication
- JWT tokens with short expiration
- Refresh token rotation
- Secure password hashing (bcrypt)

### Authorization
- Role-based access control (RBAC)
- Resource-level permissions
- Project membership validation

### Data Protection
- Input validation and sanitization
- SQL injection prevention
- XSS protection
- CSRF protection
- HTTPS enforcement

### API Security
- Rate limiting
- Request size limits
- CORS configuration
- Security headers (Helmet.js)

## Performance Optimizations

### Backend
- Database connection pooling
- Query optimization with indexes
- Redis caching for frequent queries
- Asynchronous processing
- Compression middleware

### Frontend
- Code splitting with React.lazy
- Memoization for expensive calculations
- Virtual scrolling for large lists
- Optimistic updates
- Image optimization

### Database
- Proper indexing strategy
- Query optimization
- Connection pooling
- Read replicas (for scaling)

## Monitoring & Logging

### Application Logging
- Structured logging with timestamps
- Error tracking and alerts
- Performance metrics
- User activity logging

### Health Checks
- Database connectivity
- Redis connectivity
- External service health
- Resource utilization

## Scalability Considerations

### Horizontal Scaling
- Stateless application design
- Load balancer ready
- Database read replicas
- Redis clustering

### Performance Bottlenecks
- Database query optimization
- Caching strategy refinement
- API endpoint optimization
- Frontend bundle optimization

## Development Workflow

### Code Organization
- Feature-based folder structure
- Clear separation of concerns
- Consistent naming conventions
- Comprehensive error handling

### Testing Strategy
- Unit tests for business logic
- Integration tests for API endpoints
- Component tests for React components
- End-to-end tests for user workflows

### CI/CD Pipeline
- Automated testing
- Code quality checks
- Security scanning
- Automated deployment
EOF

    echo "[$AGENT_ID] Technical documentation created"
}

# Function to create user documentation
create_user_docs() {
    echo "[$AGENT_ID] Creating user documentation"
    
    # User guide
    cat > "$PROJECT_DIR/docs/user/USER_GUIDE.md" << 'EOF'
# User Guide

Welcome to the Task Management Application! This guide will help you get started and make the most of all the features available.

## Getting Started

### Creating an Account

1. **Visit the Application** - Navigate to the application URL
2. **Click "Sign Up"** - On the login page, click the "Don't have an account? Sign Up" link
3. **Fill the Registration Form**:
   - Enter your email address
   - Choose a strong password (minimum 8 characters)
   - Enter your first and last name
4. **Click "Register"** - Submit the form to create your account
5. **Automatic Login** - You'll be automatically logged in and redirected to the dashboard

### Logging In

1. **Enter Credentials** - Use your email and password
2. **Click "Sign In"** - Submit the login form
3. **Dashboard Access** - You'll be redirected to your personal dashboard

## Dashboard Overview

The dashboard is your central hub showing:

- **Project Summary** - Overview of all your projects
- **Recent Tasks** - Tasks recently assigned to you or updated
- **Activity Feed** - Recent project and task activities
- **Quick Actions** - Shortcuts to create new projects or tasks

## Managing Projects

### Creating a New Project

1. **Navigate to Projects** - Click "Projects" in the sidebar
2. **Click "New Project"** - Use the create button
3. **Fill Project Details**:
   - **Name** - Give your project a descriptive name
   - **Description** - Optional detailed description
   - **Start Date** - Optional project start date
   - **End Date** - Optional project deadline
4. **Save Project** - Click "Create Project"

### Managing Project Members

1. **Open Project** - Click on a project card
2. **Go to Members Tab** - Switch to the members section
3. **Invite Members**:
   - Click "Invite Member"
   - Enter their email address
   - Select their role (Member, Manager, or Owner)
   - Send invitation
4. **Manage Roles**:
   - **Owner** - Full project control (you)
   - **Manager** - Can add/remove members and manage tasks
   - **Member** - Can create and manage assigned tasks

### Project Settings

Access project settings to:
- Edit project details
- Change project status (Active, Completed, Archived)
- Manage member permissions
- Delete project (Owner only)

## Managing Tasks

### Creating Tasks

1. **Open Project** - Navigate to the desired project
2. **Click "New Task"** - Use the create task button
3. **Fill Task Details**:
   - **Title** - Clear, descriptive task name
   - **Description** - Detailed task requirements
   - **Assignee** - Select a project member
   - **Priority** - Low, Medium, High, or Urgent
   - **Due Date** - Optional deadline
   - **Estimated Hours** - Time estimate for completion

### Task Statuses

Tasks progress through these statuses:
- **To Do** - Newly created, not started
- **In Progress** - Currently being worked on
- **Review** - Completed, awaiting review
- **Done** - Completed and approved

### Task Management Features

#### Comments
- Add comments to discuss task details
- Tag team members with @mentions
- View comment history
- Real-time comment notifications

#### File Attachments
- Upload files related to the task
- Support for documents, images, and other file types
- Download attachments anytime
- File version history

#### Time Tracking
- Log time spent on tasks
- Track actual vs. estimated hours
- Generate time reports
- Monitor productivity metrics

### Task Filtering and Search

Find tasks quickly using:
- **Status Filter** - Filter by task status
- **Assignee Filter** - Show tasks for specific team members
- **Priority Filter** - Filter by priority level
- **Search** - Search task titles and descriptions
- **Date Range** - Filter by due dates

## Collaboration Features

### Real-time Updates

The application provides real-time collaboration:
- **Live Notifications** - Instant updates on task changes
- **Activity Feed** - See what team members are working on
- **Presence Indicators** - Know who's online
- **Auto-refresh** - Content updates automatically

### Notifications

Stay informed with notifications for:
- Task assignments
- Comment mentions
- Due date reminders
- Project updates
- Status changes

### Team Communication

Effective team communication through:
- **Task Comments** - Discuss specific tasks
- **Project Activity** - Track all project changes
- **File Sharing** - Share documents and resources
- **@Mentions** - Get someone's attention

## Personal Productivity

### My Tasks View

Access your personal task list:
1. **Click "My Tasks"** - In the sidebar or dashboard
2. **View All Assigned Tasks** - Across all projects
3. **Sort and Filter** - Organize by priority, due date, or project
4. **Update Status** - Mark progress on your tasks

### Time Management

Optimize your productivity:
- **Set Realistic Estimates** - Help with planning
- **Track Actual Time** - Improve future estimates
- **Review Reports** - Analyze your productivity patterns
- **Set Priorities** - Focus on high-impact tasks

### Workload Balance

Monitor your workload:
- **Task Count per Project** - See distribution
- **Due Date Overview** - Manage deadlines
- **Priority Balance** - Ensure important tasks get attention
- **Time Allocation** - Track where you spend time

## Reporting and Analytics

### Project Reports

Generate reports to track:
- **Task Completion Rates** - Project progress metrics
- **Team Performance** - Individual and team productivity
- **Time Analysis** - Actual vs. estimated time
- **Milestone Progress** - Key project deliverables

### Personal Analytics

Track your individual performance:
- **Completed Tasks** - Your productivity metrics
- **Time Tracking** - Where you spend your time
- **Efficiency Trends** - Improvement over time
- **Goal Achievement** - Meeting deadlines and estimates

## Mobile Usage

The application is mobile-responsive:
- **Responsive Design** - Works on phones and tablets
- **Touch-Friendly** - Optimized for touch interactions
- **Offline Support** - Basic functionality without internet
- **Push Notifications** - Stay updated on mobile

## Tips for Success

### Best Practices

1. **Clear Task Titles** - Be specific and actionable
2. **Detailed Descriptions** - Include all necessary information
3. **Regular Updates** - Keep task status current
4. **Realistic Estimates** - Improve planning accuracy
5. **Active Communication** - Use comments effectively

### Team Collaboration

1. **Regular Check-ins** - Review project progress
2. **Clear Responsibilities** - Assign tasks to specific people
3. **Documentation** - Keep important information in task descriptions
4. **Feedback Culture** - Use comments for constructive feedback
5. **Consistent Updates** - Maintain current task statuses

### Project Organization

1. **Logical Structure** - Organize tasks by feature or phase
2. **Priority Management** - Keep high-priority tasks visible
3. **Milestone Tracking** - Use due dates for key deliverables
4. **Resource Planning** - Balance workload across team members
5. **Regular Reviews** - Assess and adjust project scope

## Troubleshooting

### Common Issues

**Login Problems**
- Check email and password
- Ensure caps lock is off
- Try password reset if needed

**Performance Issues**
- Check internet connection
- Refresh the browser
- Clear browser cache

**Notification Problems**
- Check browser notification settings
- Verify email notification preferences
- Check spam/junk folder for emails

**File Upload Issues**
- Check file size limits (5MB max)
- Verify file format is supported
- Try a different browser

### Getting Help

If you need assistance:
1. **Check this User Guide** - Most questions are answered here
2. **Contact Support** - Use the help button in the application
3. **Report Bugs** - Use the feedback feature for issues
4. **Feature Requests** - Suggest improvements through feedback

## Keyboard Shortcuts

Speed up your workflow with shortcuts:
- **Ctrl/Cmd + N** - Create new task
- **Ctrl/Cmd + P** - Create new project
- **Ctrl/Cmd + /** - Open search
- **Ctrl/Cmd + Enter** - Submit forms
- **Esc** - Close modals/dialogs

Enjoy using the Task Management Application to boost your team's productivity!
EOF

    # API documentation
    cat > "$PROJECT_DIR/docs/api/README.md" << 'EOF'
# API Documentation

This document provides comprehensive information about the Task Management Application REST API.

## Base Information

- **Base URL**: `http://localhost:5000/api/v1`
- **Authentication**: Bearer JWT tokens
- **Content-Type**: `application/json`
- **Rate Limiting**: 100 requests per minute per IP

## Authentication

All API endpoints except registration and login require authentication using JWT tokens.

### Headers
```http
Authorization: Bearer <your-jwt-token>
Content-Type: application/json
```

### Token Lifecycle
- **Access Token**: 15 minutes expiration
- **Refresh Token**: 7 days expiration
- **Auto-refresh**: Use refresh token to get new access token

## Endpoints

### Authentication

#### Register User
```http
POST /auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response (201):**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "member"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Login User
```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "member"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Refresh Token
```http
POST /auth/refresh
```

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Logout
```http
POST /auth/logout
```

### Users

#### Get Current User Profile
```http
GET /users/profile
```

**Response (200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": "member",
  "avatarUrl": "https://example.com/avatar.jpg",
  "lastLogin": "2024-01-01T12:00:00Z"
}
```

#### Update User Profile
```http
PUT /users/profile
```

**Request Body:**
```json
{
  "firstName": "John",
  "lastName": "Smith",
  "avatarUrl": "https://example.com/new-avatar.jpg"
}
```

### Projects

#### Get User Projects
```http
GET /projects?page=1&limit=10&status=active
```

**Query Parameters:**
- `page` (number): Page number (default: 1)
- `limit` (number): Items per page (default: 10)
- `status` (string): Filter by status (active|completed|archived)

**Response (200):**
```json
{
  "projects": [
    {
      "id": 1,
      "name": "Website Redesign",
      "description": "Update company website",
      "status": "active",
      "owner": {
        "id": 1,
        "name": "John Doe"
      },
      "memberCount": 5,
      "taskCount": 23,
      "createdAt": "2024-01-01T12:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "pages": 3
  }
}
```

#### Create Project
```http
POST /projects
```

**Request Body:**
```json
{
  "name": "New Project",
  "description": "Project description",
  "startDate": "2024-01-01",
  "endDate": "2024-06-30"
}
```

#### Get Project Details
```http
GET /projects/:id
```

#### Update Project
```http
PUT /projects/:id
```

#### Delete Project
```http
DELETE /projects/:id
```

### Tasks

#### Get Project Tasks
```http
GET /projects/:projectId/tasks?status=todo&assignee=1&priority=high
```

**Query Parameters:**
- `status` (string): Filter by status
- `assignee` (number): Filter by assignee user ID
- `priority` (string): Filter by priority
- `page` (number): Page number
- `limit` (number): Items per page

#### Create Task
```http
POST /projects/:projectId/tasks
```

**Request Body:**
```json
{
  "title": "New Task",
  "description": "Task description",
  "assigneeId": 2,
  "priority": "medium",
  "dueDate": "2024-01-20T12:00:00Z",
  "estimatedHours": 4
}
```

#### Get Task Details
```http
GET /tasks/:id
```

#### Update Task
```http
PUT /tasks/:id
```

#### Delete Task
```http
DELETE /tasks/:id
```

### Comments

#### Add Task Comment
```http
POST /tasks/:taskId/comments
```

**Request Body:**
```json
{
  "content": "This looks great! Just a few minor adjustments needed."
}
```

### File Uploads

#### Upload Task Attachment
```http
POST /tasks/:taskId/attachments
```

**Request:** `multipart/form-data`
- `file`: File to upload

**Response (201):**
```json
{
  "success": true,
  "attachment": {
    "id": 1,
    "filename": "generated_filename.pdf",
    "originalFilename": "requirements.pdf",
    "fileSize": 1048576,
    "mimeType": "application/pdf",
    "uploadedBy": {
      "id": 1,
      "name": "John Doe"
    },
    "createdAt": "2024-01-10T14:30:00Z"
  }
}
```

## WebSocket Events

The application uses Socket.io for real-time features.

### Connection
```javascript
const socket = io('http://localhost:5000');

// Authenticate after connection
socket.emit('authenticate', { token: 'your-jwt-token' });
```

### Project Events
```javascript
// Join project room
socket.emit('join-project', projectId);

// Listen for project updates
socket.on('project:updated', (data) => {
  console.log('Project updated:', data);
});

// Leave project room
socket.emit('leave-project', projectId);
```

### Task Events
```javascript
// Listen for task updates
socket.on('task:updated', (data) => {
  console.log('Task updated:', data);
});

// Listen for new comments
socket.on('task:comment:new', (data) => {
  console.log('New comment:', data);
});
```

### User Events
```javascript
// Listen for user status updates
socket.on('user:status', (data) => {
  console.log('User status:', data);
});
```

## Error Handling

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": [
      {
        "field": "email",
        "message": "Email is required"
      }
    ]
  }
}
```

### Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `VALIDATION_ERROR` | 400 | Request validation failed |
| `UNAUTHORIZED` | 401 | Authentication required |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource conflict |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

## Rate Limiting

- **Limit**: 100 requests per minute per IP address
- **Headers**: Rate limit information in response headers
- **Response**: 429 status code when limit exceeded

## Pagination

Endpoints supporting pagination include:
```json
{
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 100,
    "pages": 10,
    "hasNext": true,
    "hasPrev": false
  }
}
```

## Example Usage

### JavaScript/Node.js
```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: 'http://localhost:5000/api/v1',
  headers: {
    'Content-Type': 'application/json'
  }
});

// Login
const login = async (email, password) => {
  const response = await api.post('/auth/login', { email, password });
  const { token } = response.data;
  
  // Set authorization header for future requests
  api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  
  return response.data;
};

// Create project
const createProject = async (projectData) => {
  const response = await api.post('/projects', projectData);
  return response.data;
};
```

### Python
```python
import requests

class TaskAPI:
    def __init__(self, base_url='http://localhost:5000/api/v1'):
        self.base_url = base_url
        self.token = None
    
    def login(self, email, password):
        response = requests.post(f'{self.base_url}/auth/login', 
                               json={'email': email, 'password': password})
        data = response.json()
        self.token = data['token']
        return data
    
    def get_headers(self):
        return {'Authorization': f'Bearer {self.token}'}
    
    def create_project(self, project_data):
        response = requests.post(f'{self.base_url}/projects',
                               json=project_data,
                               headers=self.get_headers())
        return response.json()
```

For more examples and detailed integration guides, see the [Integration Examples](examples/) directory.
EOF

    echo "[$AGENT_ID] User documentation created"
}

# Function to create deployment guide
create_deployment_guide() {
    echo "[$AGENT_ID] Creating deployment guide"
    
    # Deployment documentation
    cat > "$PROJECT_DIR/docs/deployment/README.md" << 'EOF'
# Deployment Guide

This guide covers deploying the Task Management Application to production environments.

## Quick Start

For a rapid production deployment using Docker:

```bash
# Clone and setup
git clone <repository-url>
cd task-management-app

# Configure environment
cp backend/.env.example backend/.env
# Edit backend/.env with production values

# Deploy with Docker Compose
docker-compose -f docker-compose.prod.yml up -d
```

## Environment Setup

### Prerequisites

- **Server**: Linux (Ubuntu 20.04+ recommended)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **Domain**: For SSL certificates
- **Email Service**: For notifications (Optional)

### System Requirements

**Minimum:**
- 2 CPU cores
- 4GB RAM  
- 20GB disk space
- 100 Mbps network

**Recommended:**
- 4+ CPU cores
- 8GB+ RAM
- 50GB+ SSD storage
- 1 Gbps network

## Production Configuration

### Environment Variables

Create production `.env` file:

```bash
# Application
NODE_ENV=production
PORT=5000
CLIENT_URL=https://yourdomain.com

# Database
DATABASE_URL=postgresql://taskuser:secure_password@localhost:5432/taskmanagement
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=taskmanagement
DATABASE_USER=taskuser
DATABASE_PASSWORD=secure_password

# Redis
REDIS_URL=redis://localhost:6379
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT Secrets (Generate secure random strings)
JWT_SECRET=your-super-secure-jwt-secret-key-min-32-chars
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=your-super-secure-refresh-secret-key-min-32-chars

# Email (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# File Upload
UPLOAD_PATH=/app/uploads
MAX_FILE_SIZE=5242880

# Security
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=100

# Monitoring
LOG_LEVEL=info
```

### Security Configuration

**Generate Secure Secrets:**
```bash
# Generate JWT secrets
openssl rand -base64 32

# Generate database password
openssl rand -base64 24
```

## Docker Deployment

### Production Docker Compose

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_DB: taskmanagement
      POSTGRES_USER: taskuser
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/database/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - app-network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    restart: always
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://taskuser:${DATABASE_PASSWORD}@db:5432/taskmanagement
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    volumes:
      - uploads:/app/uploads
    networks:
      - app-network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
    restart: always
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
      - uploads:/var/www/uploads
    depends_on:
      - backend
      - frontend
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:
  uploads:

networks:
  app-network:
    driver: bridge
```

### Production Dockerfiles

**Backend (`backend/Dockerfile.prod`):**
```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodeuser -u 1001

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --chown=nodeuser:nodejs . .

USER nodeuser

EXPOSE 5000

CMD ["npm", "start"]
```

**Frontend (`frontend/Dockerfile.prod`):**
```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine AS production

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

## Manual Deployment

### Server Setup

**1. Update System:**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git nginx postgresql redis-server
```

**2. Install Node.js:**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

**3. Install PM2:**
```bash
sudo npm install -g pm2
```

### Database Setup

**1. Configure PostgreSQL:**
```bash
sudo -u postgres psql

CREATE USER taskuser WITH PASSWORD 'secure_password';
CREATE DATABASE taskmanagement OWNER taskuser;
GRANT ALL PRIVILEGES ON DATABASE taskmanagement TO taskuser;
\q
```

**2. Import Schema:**
```bash
psql -U taskuser -d taskmanagement -f backend/database/schema.sql
```

### Application Deployment

**1. Clone Repository:**
```bash
git clone <repository-url>
cd task-management-app
```

**2. Setup Backend:**
```bash
cd backend
npm install --production
cp .env.example .env
# Edit .env with production values
```

**3. Setup Frontend:**
```bash
cd ../frontend
npm install
npm run build
```

**4. Configure PM2:**
```bash
# Create ecosystem file
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'task-management-api',
    script: './src/server.js',
    cwd: './backend',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

# Start application
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

## Web Server Configuration

### Nginx Configuration

Create `/etc/nginx/sites-available/taskmanagement`:

```nginx
# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

# Upstream backend
upstream backend {
    server localhost:5000;
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Frontend
    location / {
        root /var/www/taskmanagement/frontend/dist;
        try_files $uri $uri/ /index.html;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API Routes
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Login Rate Limiting
    location /api/v1/auth/login {
        limit_req zone=login burst=5 nodelay;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Socket.io
    location /socket.io/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # File Uploads
    location /uploads/ {
        alias /var/www/taskmanagement/uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
```

**Enable Site:**
```bash
sudo ln -s /etc/nginx/sites-available/taskmanagement /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## SSL Certificate

### Using Let's Encrypt (Recommended)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Auto-renewal
sudo crontab -e
# Add line: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Using Custom Certificate

```bash
# Copy certificates
sudo mkdir -p /etc/nginx/ssl
sudo cp your-cert.pem /etc/nginx/ssl/
sudo cp your-key.pem /etc/nginx/ssl/
sudo chmod 600 /etc/nginx/ssl/*
```

## Monitoring & Logging

### Application Monitoring

**PM2 Monitoring:**
```bash
# Monitor processes
pm2 monit

# View logs
pm2 logs

# Restart application
pm2 restart all

# Reload with zero downtime
pm2 reload all
```

### System Monitoring

**Install monitoring tools:**
```bash
sudo apt install htop iotop nethogs
```

**Log management:**
```bash
# Rotate logs
sudo apt install logrotate

# Create logrotate config
sudo cat > /etc/logrotate.d/taskmanagement << 'EOF'
/var/log/taskmanagement/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload nginx
    endscript
}
EOF
```

## Backup Strategy

### Database Backup

**Automated backup script:**
```bash
#!/bin/bash
# /usr/local/bin/backup-db.sh

BACKUP_DIR="/var/backups/taskmanagement"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="taskmanagement"
DB_USER="taskuser"

mkdir -p $BACKUP_DIR

# Create backup
pg_dump -U $DB_USER -h localhost $DB_NAME | gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

# Keep only last 30 days
find $BACKUP_DIR -name "db_backup_*.sql.gz" -mtime +30 -delete

echo "Database backup completed: db_backup_$DATE.sql.gz"
```

**Schedule backup:**
```bash
sudo crontab -e
# Add line: 0 2 * * * /usr/local/bin/backup-db.sh
```

### File Backup

```bash
# Backup uploads directory
rsync -av /var/www/taskmanagement/uploads/ /var/backups/taskmanagement/uploads/
```

## Performance Optimization

### Database Optimization

```sql
-- Analyze and optimize
ANALYZE;
VACUUM;

-- Add additional indexes if needed
CREATE INDEX CONCURRENTLY idx_tasks_created_at ON tasks(created_at);
CREATE INDEX CONCURRENTLY idx_projects_updated_at ON projects(updated_at);
```

### Application Optimization

**PM2 Configuration:**
```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'task-management-api',
    script: './src/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    max_memory_restart: '500M',
    node_args: '--max-old-space-size=512',
    env: {
      NODE_ENV: 'production'
    }
  }]
};
```

### System Optimization

```bash
# Optimize system limits
echo "fs.file-max = 65536" >> /etc/sysctl.conf
echo "net.core.somaxconn = 65536" >> /etc/sysctl.conf
sysctl -p

# Optimize nginx worker processes
# Edit /etc/nginx/nginx.conf
worker_processes auto;
worker_connections 1024;
```

## Security Hardening

### Firewall Configuration

```bash
# Configure UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### Application Security

**1. Regular Updates:**
```bash
# Create update script
#!/bin/bash
# /usr/local/bin/update-app.sh

cd /var/www/taskmanagement
git pull origin main
cd backend && npm audit fix
cd ../frontend && npm audit fix && npm run build
pm2 reload all
```

**2. Security Monitoring:**
```bash
# Install fail2ban
sudo apt install fail2ban

# Configure for nginx
sudo cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled = true

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
logpath = /var/log/nginx/error.log
findtime = 600
bantime = 7200
maxretry = 10
EOF
```

## Troubleshooting

### Common Issues

**Application won't start:**
```bash
# Check logs
pm2 logs
journalctl -u nginx
tail -f /var/log/postgresql/postgresql-13-main.log
```

**Database connection issues:**
```bash
# Test connection
psql -U taskuser -h localhost -d taskmanagement

# Check PostgreSQL status
sudo systemctl status postgresql
```

**High memory usage:**
```bash
# Monitor memory
free -h
ps aux --sort=-%mem | head

# Restart if needed
pm2 restart all
```

### Health Checks

**Create health check script:**
```bash
#!/bin/bash
# /usr/local/bin/health-check.sh

# Check API health
curl -f http://localhost:5000/health || exit 1

# Check database
pg_isready -U taskuser -h localhost -d taskmanagement || exit 1

# Check Redis
redis-cli ping || exit 1

echo "All services healthy"
```

## Maintenance

### Regular Tasks

**Daily:**
- Monitor application logs
- Check system resources
- Verify backup completion

**Weekly:**
- Update system packages
- Review security logs
- Analyze performance metrics

**Monthly:**
- Update application dependencies
- Review and rotate logs
- Security audit

### Update Procedure

```bash
# 1. Backup current version
tar -czf backup-$(date +%Y%m%d).tar.gz /var/www/taskmanagement

# 2. Update code
cd /var/www/taskmanagement
git pull origin main

# 3. Update dependencies
cd backend && npm install --production
cd ../frontend && npm install && npm run build

# 4. Run migrations (if any)
npm run db:migrate

# 5. Restart application
pm2 reload all

# 6. Verify deployment
curl http://localhost:5000/health
```

This deployment guide provides a comprehensive foundation for running the Task Management Application in production. Adjust configurations based on your specific infrastructure requirements and security policies.
EOF

    echo "[$AGENT_ID] Deployment guide created"
}

# Execute based on task type
case "$TASK_ID" in
    "docs_001")
        create_technical_docs
        ;;
    "docs_002")
        create_user_docs
        ;;
    "docs_003")
        create_deployment_guide
        ;;
    *)
        echo "[$AGENT_ID] Unknown documentation task: $TASK_ID"
        exit 1
        ;;
esac

echo "[$AGENT_ID] Documentation task completed successfully"