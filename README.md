# Agent Swarm Framework

A powerful bash-based agent swarm system that generates complete software applications via coordinated specialized agents. The system analyzes specifications and autonomously plans, designs, implements, tests, and documents applications through a multi-agent architecture.

## 🤖 **AI-Powered Intelligence**

**Current Implementation:** This framework features **intelligent requirements analysis and dynamic task planning** with AI-powered code generation. The system automatically detects application domains, complexity levels, and generates tailored solutions.

**AI Integration:** Built-in support for Claude API enables context-aware code generation for all application components including architecture, implementation, testing, documentation, and business analysis.

**Required AI Setup:**
```bash
# Set your Claude API key (REQUIRED)
export CLAUDE_API_KEY="sk-ant-api03-your-key-here"

# Run the system with AI-powered generation
./swarm_parallel.sh agents_enhanced.json my_spec.txt --parallel
```

**⚠️ Note:** Claude API key is mandatory. The framework relies entirely on AI-powered generation for optimal results.

## 🚀 Features

- **Intelligent Requirements Analysis** - Automatically detects application domain, complexity, and features
- **Universal Application Support** - Generates any type of application (e-commerce, project management, healthcare, etc.)
- **AI-Powered Code Generation** - Uses Claude API for context-aware, domain-specific code generation
- **Business Analysis & Market Research** - Comprehensive business feasibility, market analysis, and competitive assessment
- **Dynamic Task Planning** - Creates custom task plans based on requirements analysis
- **Unified Agent Architecture** - Single intelligent executor handles all agent types
- **Adaptive Technology Selection** - Recommends optimal tech stacks based on requirements
- **Domain-Specific Output** - Generates tailored code, tests, and documentation for detected domain
- **Comprehensive Logging** - Tracks all activities with full transparency
- **Production Ready** - Generates Docker configurations, tests, and deployment guides

## 📋 Prerequisites

- **Claude API Key** - Required for AI-powered generation
- **Bash 4.0+** (macOS/Linux)
- **jq** - JSON processor for parsing configurations
- **curl** - For API communication with Claude
- **chmod** - For setting executable permissions

### Install Prerequisites

**On macOS:**
```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install jq
brew install jq
```

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install jq
```

**On CentOS/RHEL:**
```bash
sudo yum install jq curl
```

**Get Claude API Key:**
1. Sign up at [Claude.ai](https://claude.ai) or [Anthropic Console](https://console.anthropic.com)
2. Generate an API key
3. Export it in your environment:
```bash
export CLAUDE_API_KEY="sk-ant-api03-your-key-here"
# Add to ~/.bashrc or ~/.zshrc for persistence
echo 'export CLAUDE_API_KEY="sk-ant-api03-your-key-here"' >> ~/.bashrc
```

## 🛠️ Installation

### 1. Clone or Download the Agent Swarm Framework

```bash
# Create project directory
mkdir my-agent-swarm
cd my-agent-swarm

# Download the framework files (or git clone if available)
# You'll need these files:
# - swarm_parallel.sh (main orchestration script)
# - lib/ (intelligent task planner, unified agent executor, logger)
# - agents/ (intelligent planner and unified agent executor)
```

### 2. Set Up Executable Permissions

```bash
# The framework automatically creates necessary directories (logs/, workspace/)
# Just ensure scripts are executable:
chmod +x swarm_parallel.sh
chmod +x agents/planner.sh  
chmod +x agents/agent_executor.sh
```

The framework structure should look like:
```
agent-swarm/
├── swarm_parallel.sh         # Main orchestration script (with parallel support)
├── swarm.sh                  # Alternative sequential-only script
├── lib/
│   ├── task_planner.sh       # Intelligent specification analysis & dynamic planning
│   ├── agent_executor.sh     # Agent coordination & execution
│   ├── parallel_executor.sh  # Parallel execution system
│   └── logger.sh            # Comprehensive activity logging
├── agents/
│   ├── planner.sh           # Intelligent requirements analyzer & task planner
│   └── agent_executor.sh    # Unified AI-powered agent executor
├── agents_enhanced.json     # Enhanced agent configuration with capabilities
├── logs/                   # Generated activity logs
└── workspace/              # Generated projects and artifacts
```

### 3. Verify Installation

```bash
# Test the framework
./swarm.sh
```

You should see the usage message:
```
Usage: ./swarm.sh <agents_config> <specification_file>

Arguments:
  agents_config      - JSON file defining available agents and their roles
  specification_file - Text file describing the target application
```

## 📖 Quick Start Guide

### Step 1: Use Enhanced Agent Configuration

The framework includes `agents_enhanced.json` with intelligent agent definitions:

```json
{
  "agent_types": {
    "planner": {
      "name": "Intelligent Planner",
      "description": "Analyzes requirements and creates dynamic task plans",
      "capabilities": ["Requirements analysis", "Domain detection", "Task planning", "Agent assignment"],
      "specializations": {
        "domains": ["ecommerce", "project_management", "healthcare", "fintech", "social_platform"],
        "complexity_levels": ["low", "medium", "high"],
        "architectures": ["monolith", "microservices", "serverless"]
      }
    },
    "architect": {
      "name": "System Architect", 
      "description": "Designs system architecture with domain-specific expertise",
      "capabilities": ["System design", "Technology selection", "Security architecture"],
      "specializations": {
        "patterns": ["mvc", "microservices", "event_driven"],
        "databases": ["postgresql", "mongodb", "redis"],
        "cloud_platforms": ["aws", "gcp", "azure", "docker"]
      }
    },
    "developer": {
      "name": "Software Developer",
      "description": "Implements code with AI-powered generation", 
      "capabilities": ["Code implementation", "API development", "Authentication systems"],
      "specializations": {
        "languages": ["javascript", "typescript", "python"],
        "frameworks": ["react", "express", "fastapi"],
        "features": ["authentication", "payments", "real_time", "file_upload"]
      }
    },
    "tester": {
      "name": "Quality Assurance Tester",
      "description": "Creates comprehensive test suites adapted to application domain",
      "capabilities": ["Unit testing", "Integration testing", "E2E testing", "Performance testing"],
      "specializations": {
        "frameworks": ["jest", "cypress", "selenium", "playwright"]
      }
    },
    "documenter": {
      "name": "Technical Documenter",
      "description": "Creates documentation tailored to application domain",
      "capabilities": ["Technical docs", "User guides", "API documentation", "Deployment guides"],
      "specializations": {
        "formats": ["markdown", "html", "interactive"]
      }
    },
    "business_analyst": {
      "name": "Business Analyst",
      "description": "Analyzes market potential, business risks, and feasibility",
      "capabilities": ["Market research", "Competitive analysis", "Business model validation", "ROI analysis"],
      "specializations": {
        "domains": ["ecommerce", "fintech", "healthcare", "saas"],
        "methodologies": ["swot_analysis", "business_model_canvas", "lean_canvas"]
      }
    }
  },
  "execution_settings": {
    "max_parallel_agents": 4,
    "intelligent_planning": true,
    "dynamic_agent_assignment": true,
    "adaptive_task_creation": true
  },
  "planning_settings": {
    "enable_domain_detection": true,
    "enable_complexity_analysis": true,
    "enable_tech_stack_recommendation": true
  }
}
```

### Step 2: Write Application Specification

Create `my_app_spec.txt` describing your desired application:

```
APPLICATION SPECIFICATION

PURPOSE:
Create a [describe your application - e.g., "blog management system", "inventory tracker", "event scheduler"]

FEATURES:
- [List key features]
- [Feature 2] 
- [Feature 3]
- [etc.]

TECHNICAL REQUIREMENTS:
- Web-based application accessible via modern browsers
- RESTful API for frontend-backend communication
- Database support for persistent data storage
- User authentication and authorization
- Responsive design supporting desktop and mobile devices

TECHNICAL CONSTRAINTS:
- Must support at least [X] concurrent users
- Response time should be under [X] seconds
- Must comply with basic security best practices
- Cross-browser compatibility (Chrome, Firefox, Safari, Edge)

USE CASES:
1. [Describe main user workflows]
2. [Use case 2]
3. [Use case 3]

PERFORMANCE REQUIREMENTS:
- Page load time: < 3 seconds
- API response time: < 2 seconds
- 99.5% uptime availability

SECURITY REQUIREMENTS:
- Secure password storage (hashed)
- Protection against SQL injection
- HTTPS encryption for data transmission
- Input validation and sanitization
```

### Step 3: Run the Agent Swarm

Choose your execution mode:

**Intelligent Analysis + Sequential Execution:**
```bash
# Generate your application with intelligent planning (one agent at a time)
./swarm_parallel.sh agents_enhanced.json my_app_spec.txt --sequential
```

**Intelligent Analysis + Parallel Execution (Recommended):**
```bash
# Generate your application with intelligent planning (multiple agents simultaneously)  
./swarm_parallel.sh agents_enhanced.json my_app_spec.txt --parallel
```

**Execution Mode Comparison:**

| Mode | Speed | Resource Usage | Complexity | Best For |
|------|-------|----------------|------------|----------|
| **Sequential** | Standard | Low | Simple | Small projects, debugging |
| **Parallel** | Up to 3x faster | Higher | Advanced | Large projects, production |

### Step 4: Monitor Progress

Watch the real-time output showing:
- Intelligent specification analysis with domain detection
- Dynamic task planning based on detected requirements
- AI-powered agent execution with context-aware generation
- Real-time progress tracking with domain-specific insights

Example output:
```
🚀 Initializing Agent Swarm System
⚡ Parallel execution mode enabled
✅ Input files validated
📋 Analyzing specification and planning tasks...
[PLANNER] Starting intelligent task planning analysis
[PLANNER] Using intelligent planner agent for dynamic analysis
[planner_1234567] Domain detected: project_management
[planner_1234567] Complexity assessed: high
[planner_1234567] Features extracted: authentication, real_time, notifications
[planner_1234567] Tech stack recommended: Node.js/Express + React + PostgreSQL
[PLANNER] Dynamic task plan created with 15 domain-specific tasks
🤖 Executing agent swarm...
[architect_1234567] Using unified agent executor for architecture task
[developer_1234567] Using AI-powered code generation for project_management domain
[tester_1234567] Creating domain-specific test suites
...
🎉 Agent swarm execution completed!
```

### Step 5: Review Generated Application

Check the generated project:
```bash
# Navigate to generated project
cd workspace/artifacts/project

# View project structure
ls -la

# Backend (technology varies by domain/complexity)
cd backend
cat package.json
ls src/

# Frontend (React/Vue/Angular - varies by requirements)  
cd ../frontend
cat package.json
ls src/

# Business Analysis (NEW!)
cd ../business
ls -la  # market_analysis.json, business_model_canvas.json, etc.

# Documentation
cd ../docs
ls -la
```

## 🏗️ Example: Building a Blog Management System

Let's walk through creating a complete blog management system:

### 1. Create Blog Specification

```bash
cat > blog_spec.txt << 'EOF'
APPLICATION SPECIFICATION

PURPOSE:
Create a blog management system that allows users to create, edit, and publish blog posts with a clean, modern interface.

FEATURES:
- User registration and authentication
- Create, edit, delete blog posts
- Rich text editor for post content
- Categories and tags for organization
- Comment system for reader engagement
- User profiles and author pages
- Search functionality across posts
- Admin dashboard for content management
- SEO-friendly URLs and metadata
- Email notifications for comments

TECHNICAL REQUIREMENTS:
- Web-based application accessible via modern browsers
- RESTful API for frontend-backend communication
- Database support for persistent data storage
- User authentication with JWT tokens
- File upload for images and media
- Responsive design supporting desktop and mobile devices
- SEO optimization with meta tags

TECHNICAL CONSTRAINTS:
- Must support at least 1000 concurrent users
- Response time should be under 2 seconds for post loading
- Search results should return within 1 second
- Must comply with GDPR and basic security practices
- Cross-browser compatibility (Chrome, Firefox, Safari, Edge)

USE CASES:
1. Blogger registers account and creates first post
2. Reader discovers posts through search and categories
3. Engaged reader leaves comments on posts
4. Admin moderates content and manages users
5. Author updates existing posts and responds to comments

PERFORMANCE REQUIREMENTS:
- Page load time: < 3 seconds
- Search response time: < 1 second
- Image upload: < 10 seconds for 5MB files
- 99.9% uptime availability

SECURITY REQUIREMENTS:
- Secure password storage with bcrypt
- Protection against SQL injection and XSS
- HTTPS encryption for all data transmission
- Input validation and sanitization
- Rate limiting for API endpoints
- CSRF protection for forms
EOF
```

### 2. Run the Agent Swarm

```bash
./swarm_parallel.sh agents_enhanced.json blog_spec.txt --parallel
```

### 3. What Gets Generated

The system will create:

**Backend Components:**
- User authentication system with JWT
- Blog post CRUD operations
- Comment management system
- Category and tag organization
- File upload for images
- Search functionality
- Admin panel APIs

**Frontend Components:**
- React blog interface with routing
- Rich text editor (likely TinyMCE/CKEditor integration)
- User registration/login forms
- Post creation and editing interface
- Comment sections
- Search and filtering
- Responsive design with Material-UI

**Database Schema:**
- Users table with authentication
- Posts table with content and metadata
- Categories and tags with relationships
- Comments with user associations
- File attachments table

**Testing Suite:**
- Unit tests for all API endpoints
- Component tests for React interface
- Integration tests for user workflows
- E2E tests for critical paths

**Documentation:**
- API documentation with endpoints
- User manual for bloggers
- Admin guide for content management
- Deployment instructions

### 4. Deploy Your Blog

```bash
cd workspace/artifacts/project

# Start with Docker
docker-compose up -d

# Or start manually
cd backend && npm install && npm run dev
cd frontend && npm install && npm run dev

# Access your blog
open http://localhost:3000
```

## ⚡ Parallel vs Sequential Execution

### Sequential Execution (`swarm.sh`)

**How it works:**
- Agents execute one task at a time
- Tasks processed in dependency order
- Single main process handles all execution
- Simpler logging and debugging

**Advantages:**
- Lower resource usage
- Easier to debug and monitor
- More predictable execution order
- Better for development and testing

**Use when:**
- Working on smaller applications
- Debugging agent behavior
- Limited system resources
- Learning the framework

### Parallel Execution (`swarm_parallel.sh`)

**How it works:**
- Multiple agents run simultaneously in background processes
- Up to 3 agents execute concurrently (configurable)
- Automatic dependency resolution prevents conflicts
- Real-time progress monitoring

**Advantages:**
- Up to 3x faster execution time
- Better resource utilization
- Efficient for large projects
- Production-ready performance

**Technical Details:**
```bash
# Each agent runs in its own background process
architect_12345 &    # PID 12345
developer_12346 &    # PID 12346  
tester_12347 &       # PID 12347

# Main process coordinates and monitors
# Dependencies automatically enforced
# Results collected asynchronously
```

**Configuration:**
```json
{
  "execution_settings": {
    "max_parallel_agents": 3,     // Max concurrent agents
    "task_timeout": "30m",        // Per-task timeout
    "retry_failed_tasks": true,   // Auto-retry on failure
    "max_retries": 2             // Retry limit
  }
}
```

**Use when:**
- Building complex applications
- Production deployments
- Time is critical
- System has sufficient resources

### Performance Comparison

**Example: Task Management App (15 tasks)**

| Mode | Execution Time | Resource Usage | Process Count |
|------|----------------|----------------|---------------|
| Sequential | ~45 seconds | 1 CPU core | 1 main process |
| Parallel | ~15 seconds | 3+ CPU cores | 1 main + 3 background |

**Task Dependencies Handled Automatically:**
```
Sequential:  arch_001 → arch_002 → arch_003 → impl_001 → ...
            
Parallel:    arch_001 (agent1)
            ├── arch_002 (agent2) [waits for arch_001]  
            └── arch_003 (agent3) [waits for arch_002]
             ↓
            impl_001, impl_002, impl_003 (parallel when ready)
```

## 🔧 Advanced Usage

### Custom Agent Types

Create new specialized agents by adding scripts to the `agents/` directory:

```bash
# Create custom agent
cat > agents/designer.sh << 'EOF'
#!/bin/bash
# Designer Agent - Creates UI/UX designs and wireframes

TASK_CONTEXT_FILE="$1"
# ... implementation
EOF

chmod +x agents/designer.sh
```

Add to `agents.json`:
```json
{
  "agents": {
    "designer": {
      "name": "UI/UX Designer",
      "description": "Creates user interface designs and wireframes",
      "capabilities": ["Wireframe creation", "UI design", "UX optimization"]
    }
  }
}
```

### Complex Application Examples

**E-commerce Platform:**
```
PURPOSE: Create a full-featured e-commerce platform with product catalog, shopping cart, payment processing, and order management.

FEATURES:
- Product catalog with categories and search
- Shopping cart and checkout process  
- Payment integration (Stripe/PayPal)
- User accounts and order history
- Inventory management
- Admin dashboard for store management
- Product reviews and ratings
- Shipping calculator and tracking
```

**Project Management Tool:**
```
PURPOSE: Create a comprehensive project management tool similar to Jira/Trello with kanban boards, task tracking, and team collaboration.

FEATURES:
- Kanban board interface with drag-and-drop
- Sprint planning and backlog management
- Time tracking and reporting
- Team collaboration tools
- File attachments and comments
- Project templates and workflows
- Dashboard with analytics
- Integration APIs for external tools
```

**Learning Management System:**
```
PURPOSE: Create an online learning platform with courses, quizzes, progress tracking, and certification.

FEATURES:
- Course creation and management
- Video streaming and content delivery
- Quiz and assessment system
- Progress tracking and analytics
- Student enrollment management
- Certificate generation
- Discussion forums
- Mobile learning app
```

## 📊 Understanding the Output

### Generated Project Structure

The framework automatically adapts the project structure based on your application's domain and complexity. Here's what gets generated:

```
workspace/artifacts/project/
├── backend/              # API server (technology varies by domain/complexity)
│   ├── src/
│   │   ├── controllers/  # HTTP request handlers
│   │   ├── models/       # Database models
│   │   ├── services/     # Business logic
│   │   ├── middleware/   # Authentication, validation
│   │   ├── routes/       # API routing
│   │   └── config/       # Database, environment setup
│   ├── tests/            # Backend test suites
│   ├── package.json      # Dependencies and scripts
│   └── Dockerfile        # Container configuration
├── frontend/             # Client application (React, Vue, or others)
│   ├── src/
│   │   ├── components/   # Reusable UI components
│   │   ├── pages/        # Application pages
│   │   ├── services/     # API integration
│   │   ├── store/        # State management (varies by complexity)
│   │   └── types/        # Type definitions (if TypeScript)
│   ├── package.json      # Frontend dependencies
│   └── build.config.*    # Build configuration (Vite, Webpack, etc.)
├── business/             # Business analysis documents
│   ├── market_analysis.json      # Market research and analysis
│   ├── business_model_canvas.json # Business model framework
│   ├── risk_assessment.json      # Risk analysis and mitigation
│   └── user_personas.json        # Target user personas
├── docs/                 # Generated documentation
│   ├── technical/        # Architecture guides
│   ├── user/            # User manuals
│   ├── api/             # API documentation
│   └── deployment/      # Deployment guides
├── docker-compose.yml    # Multi-service deployment
└── README.md            # Project overview
```

### Technology Stack Flexibility

The framework **automatically selects the optimal technology stack** based on your application's domain, complexity, and scale requirements:

#### Backend Technologies
- **Low Complexity**: Node.js/Express with JavaScript
- **Medium Complexity**: Node.js/Express with TypeScript
- **High Complexity**: NestJS microservices or specialized frameworks
- **Alternative Stacks**: Python/FastAPI, Java/Spring, Go/Gin (domain-dependent)

#### Frontend Technologies
- **Simple Apps**: React with CSS
- **Medium Apps**: React with TypeScript + Material-UI/Tailwind
- **Complex Apps**: Next.js, Vue.js, or Angular with advanced state management
- **Analytics Apps**: React + D3.js/Chart.js for visualizations

#### Database Selection
- **Small Scale**: SQLite for simplicity
- **Medium/Large Scale**: PostgreSQL for reliability
- **Document Storage**: MongoDB for content-heavy applications
- **Analytics**: ClickHouse or specialized time-series databases
- **Search**: Elasticsearch for e-commerce and content platforms

#### Specialized Domain Technologies
- **E-commerce**: Stripe payments, inventory management, search engines
- **Real-time Apps**: Socket.io, WebSocket support, Redis caching
- **Healthcare**: HIPAA compliance, end-to-end encryption, audit logging
- **FinTech**: Advanced security, OAuth2, compliance frameworks
- **IoT**: MQTT messaging, InfluxDB time-series, Grafana monitoring

The system intelligently combines these technologies to create the perfect stack for your specific needs.

### Logging and Tracking

Monitor agent activities in the `logs/` directory:
```bash
# View main execution log
tail -f logs/swarm_*_main.log

# Monitor agent activities
tail -f logs/swarm_*_agents.log

# Track task completion
tail -f logs/swarm_*_tasks.log
```

### Task Execution Flow

The system follows this comprehensive workflow:
1. **Analysis Phase** - Parse specification and extract requirements
2. **Business Analysis Phase** - Market research, competitive analysis, and feasibility assessment
3. **Planning Phase** - Break down into coordinated tasks with optimal agent assignments
4. **Architecture Phase** - Design system architecture and data models
5. **Implementation Phase** - Generate working code for backend and frontend
6. **Testing Phase** - Create comprehensive test suites
7. **Documentation Phase** - Generate user guides and technical docs

Each phase is intelligently adapted based on your application's domain, complexity, and scale requirements.

## 🔍 Troubleshooting

### Common Issues

**Permission Denied:**
```bash
chmod +x swarm.sh agents/*.sh
```

**jq Command Not Found:**
```bash
# macOS
brew install jq

# Ubuntu
sudo apt install jq
```

**Task Failures:**
Check the logs for specific error messages:
```bash
cat logs/swarm_*_main.log | grep ERROR
```

**Empty Output:**
Verify your specification file has sufficient detail (recommended 1000+ characters).

### Debug Mode

Run with verbose logging:
```bash
export LOG_LEVEL=debug
./swarm.sh agents.json my_spec.txt
```

## 🤝 Contributing

### Extending the Framework

1. **Add New Agent Types** - Create scripts in `agents/` directory
2. **Enhance Task Planning** - Modify `lib/task_planner.sh` for new task types
3. **Improve Code Generation** - Extend agent capabilities with better templates
4. **Add New Technologies** - Update agents to support additional frameworks

### Customization Examples

**Add Python/Django Support:**
```bash
# Modify agents/developer.sh to include Django templates
# Add Python-specific models and API generation
```

**Add Vue.js Frontend Option:**
```bash
# Create agents/vue_developer.sh
# Add Vue.js project templates and components
```

**Add Microservices Architecture:**
```bash
# Modify task_planner.sh to create multiple service tasks
# Update architect.sh for microservices patterns
```

## 📚 Resources

- **Generated Documentation** - Each project includes comprehensive docs
- **Example Applications** - Check `workspace/artifacts/` for examples
- **Agent Logs** - Review `logs/` for execution details
- **Task Plans** - Examine `workspace/task_plan.json` for planning insights

## 🚀 Getting Started Checklist

- [ ] Install prerequisites (bash, jq, curl)
- [ ] **Get Claude API key from Anthropic (REQUIRED)**
- [ ] **Set Claude API key: `export CLAUDE_API_KEY="your-key"`**
- [ ] Download/clone the agent swarm framework  
- [ ] Set executable permissions on scripts
- [ ] Use included `agents_enhanced.json` configuration (or customize)
- [ ] Write your application specification for ANY domain
- [ ] Run `./swarm_parallel.sh agents_enhanced.json your_spec.txt --parallel`
- [ ] Review generated domain-specific project in `workspace/artifacts/project/`
- [ ] Deploy with Docker or manually install dependencies
- [ ] Customize and extend the generated application

## 🌟 **Universal Application Generation**

The Agent Swarm Framework automatically detects your application domain and generates tailored solutions:

- **E-commerce** → Product catalogs, shopping carts, payment integration
- **Project Management** → Task tracking, team collaboration, dashboards  
- **Healthcare** → Patient management, appointment scheduling, compliance
- **Social Media** → User profiles, messaging, real-time features
- **FinTech** → Account management, transactions, security
- **IoT** → Device monitoring, data collection, automation
- **And ANY other domain** you specify in your requirements

---

**The Agent Swarm Framework transforms ANY idea into working software through intelligent AI agents. Start building your next application today!**