#!/bin/bash

# Unified Intelligent Agent Executor
# Executes any type of agent task using AI-powered analysis and generation

set -euo pipefail

TASK_CONTEXT_FILE="$1"

# Read task context
TASK_CONTEXT=$(cat "$TASK_CONTEXT_FILE")
AGENT_ID=$(echo "$TASK_CONTEXT" | jq -r '.agent_id')
TASK_ID=$(echo "$TASK_CONTEXT" | jq -r '.task_id')
DESCRIPTION=$(echo "$TASK_CONTEXT" | jq -r '.description')
AGENT_TYPE=$(echo "$TASK_CONTEXT" | jq -r '.agent_type // "general"')
WORKSPACE=$(echo "$TASK_CONTEXT" | jq -r '.workspace')
ARTIFACTS_DIR=$(echo "$TASK_CONTEXT" | jq -r '.session_artifacts')

echo "[$AGENT_ID] Starting $AGENT_TYPE task: $TASK_ID"
echo "[$AGENT_ID] Description: $DESCRIPTION"

# Create artifacts directory
mkdir -p "$ARTIFACTS_DIR"

# Function to load requirements analysis
load_requirements_analysis() {
    local analysis_file="$ARTIFACTS_DIR/analysis/requirements_analysis.json"
    if [[ -f "$analysis_file" ]]; then
        cat "$analysis_file"
    else
        echo "{\"requirements_summary\": {\"domain\": \"general\", \"complexity\": \"medium\"}}"
    fi
}

# Function to load agent capabilities
load_agent_capabilities() {
    local agent_type="$1"
    local agents_config="$2"
    
    if [[ -f "$agents_config" ]]; then
        jq -r ".agent_types.$agent_type // .agents.$agent_type // {}" "$agents_config" 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# Function to call Claude API for task execution
call_claude_api() {
    local prompt="$1"
    local max_tokens="${2:-4000}"
    
    if [[ -z "${CLAUDE_API_KEY:-}" ]]; then
        echo "[$AGENT_ID] ERROR: Claude API key is required but not found" >&2
        echo "[$AGENT_ID] Please set CLAUDE_API_KEY environment variable" >&2
        exit 1
    fi
    
    echo "[$AGENT_ID] Calling Claude API for intelligent task execution..."
    
    local response
    response=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
        -H "Authorization: Bearer $CLAUDE_API_KEY" \
        -H "Content-Type: application/json" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"claude-3-sonnet-20240229\",
            \"max_tokens\": $max_tokens,
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$prompt\"
            }]
        }")
    
    local api_text
    api_text=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)
    
    if [[ -z "$api_text" ]]; then
        echo "[$AGENT_ID] ERROR: Failed to get response from Claude API" >&2
        echo "[$AGENT_ID] Response: $response" >&2
        exit 1
    fi
    
    echo "$api_text"
}

# Function to create architecture artifacts
execute_architect_task() {
    local analysis="$1"
    local agent_capabilities="$2"
    
    local domain=$(echo "$analysis" | jq -r '.requirements_summary.domain')
    local complexity=$(echo "$analysis" | jq -r '.requirements_summary.complexity')
    local features=$(echo "$analysis" | jq -r '.extracted_features // []')
    local tech_stack=$(echo "$analysis" | jq -r '.recommended_stack // {}')
    
    echo "[$AGENT_ID] Executing architecture task for $domain domain with $complexity complexity"
    
    # Create AI prompt for architecture
    local prompt="You are a senior software architect. Create detailed architecture documentation for a $domain application with $complexity complexity.

Requirements Analysis:
- Domain: $domain
- Complexity: $complexity  
- Features: $(echo "$features" | jq -r 'join(", ")')
- Recommended Stack: $(echo "$tech_stack" | jq -c '.')

Task: $DESCRIPTION

Generate comprehensive architecture artifacts:

1. **System Architecture Document** (detailed markdown):
   - High-level architecture overview
   - Component breakdown and responsibilities
   - Data flow diagrams (in text/ascii format)
   - Security architecture
   - Scalability considerations
   - Performance requirements

2. **Database Schema** (complete SQL):
   - All tables with proper relationships
   - Indexes for performance
   - Constraints and validations
   - Sample data population scripts

3. **API Specification** (complete OpenAPI JSON):
   - All endpoints with full details
   - Request/response schemas
   - Authentication schemes
   - Error handling

4. **Technology Stack Decisions** (detailed JSON):
   - Justification for each technology choice
   - Alternative options considered
   - Integration points between technologies

Please provide complete, production-ready artifacts that developers can immediately use for implementation."
    
    # Generate AI-powered architecture
    local ai_response
    ai_response=$(call_claude_api "$prompt" 8000)
    
    echo "[$AGENT_ID] Processing AI-generated architecture artifacts"
    
    # Save the complete response
    echo "$ai_response" > "$ARTIFACTS_DIR/complete_architecture.md"
    
    # Create individual artifacts based on the response
    create_architecture_artifacts "$ai_response" "$domain" "$features" "$tech_stack"
}

# Function to execute development tasks
execute_developer_task() {
    local analysis="$1"
    local agent_capabilities="$2"
    
    local domain=$(echo "$analysis" | jq -r '.requirements_summary.domain')
    local complexity=$(echo "$analysis" | jq -r '.requirements_summary.complexity')
    local features=$(echo "$analysis" | jq -r '.extracted_features // []')
    local tech_stack=$(echo "$analysis" | jq -r '.recommended_stack // {}')
    
    echo "[$AGENT_ID] Executing development task for $domain domain"
    
    # Create AI prompt for development
    local prompt="You are a senior full-stack developer. Generate complete, production-ready code for a $domain application.

Context:
- Domain: $domain
- Complexity: $complexity
- Features: $(echo "$features" | jq -r 'join(", ")')
- Tech Stack: $(echo "$tech_stack" | jq -c '.')

Task: $DESCRIPTION

Generate a complete, working application with these specific deliverables:

1. **Project Structure** - Complete directory layout with all necessary files
2. **Backend Implementation** - Full API server with:
   - All endpoints for $domain functionality
   - Database models and relationships
   - Authentication and middleware
   - Error handling and validation
   - Configuration files
   
3. **Frontend Implementation** - Complete client application with:
   - All UI components for $domain workflows
   - State management and API integration
   - Responsive design and styling
   - Routing and navigation
   
4. **Database Layer** - Complete data persistence with:
   - Schema creation scripts
   - Migrations and seed data
   - Query optimization
   
5. **DevOps Configuration** - Production deployment setup:
   - Docker containers and compose files
   - Environment configuration
   - Build and deployment scripts

6. **Testing Setup** - Comprehensive test suites
7. **Documentation** - API docs and setup instructions

Focus specifically on $domain best practices and ensure all $features are fully implemented. Provide complete, runnable code that can be deployed immediately."
    
    # Generate AI-powered code
    local ai_response
    ai_response=$(call_claude_api "$prompt" 12000)
    
    echo "[$AGENT_ID] Processing AI-generated code implementation"
    
    # Save the complete response
    echo "$ai_response" > "$ARTIFACTS_DIR/complete_implementation.md"
    
    # Create project artifacts based on the response
    create_implementation_artifacts "$ai_response" "$domain" "$features" "$tech_stack"
}

# Function to execute testing tasks
execute_tester_task() {
    local analysis="$1"
    local agent_capabilities="$2"
    
    local domain=$(echo "$analysis" | jq -r '.requirements_summary.domain')
    local complexity=$(echo "$analysis" | jq -r '.requirements_summary.complexity')
    local features=$(echo "$analysis" | jq -r '.extracted_features // []')
    local tech_stack=$(echo "$analysis" | jq -r '.recommended_stack // {}')
    
    echo "[$AGENT_ID] Executing testing task for $domain domain"
    
    local prompt="You are a senior QA engineer. Create comprehensive test suites for a $domain application with $complexity complexity.

Context:
- Domain: $domain
- Complexity: $complexity
- Features: $(echo "$features" | jq -r 'join(", ")')
- Tech Stack: $(echo "$tech_stack" | jq -c '.')

Task: $DESCRIPTION

Generate complete, production-ready test suites including:

1. **Unit Tests** - Comprehensive business logic testing:
   - All core $domain functionality
   - Edge cases and error scenarios
   - Mock data and fixtures
   - Test utilities and helpers

2. **Integration Tests** - API and system integration:
   - All API endpoints with various scenarios
   - Database integration tests
   - Third-party service mocking
   - Authentication and authorization tests

3. **End-to-End Tests** - Complete user workflows:
   - Critical $domain user journeys
   - Cross-browser compatibility
   - Mobile responsiveness testing
   - Performance assertions

4. **Performance Tests** - Load and stress testing:
   - API response time benchmarks
   - Concurrent user simulations
   - Database query optimization tests
   - Memory and resource usage tests

5. **Test Configuration** - Complete testing setup:
   - Test environment configuration
   - CI/CD pipeline integration
   - Coverage reporting setup
   - Test data management

Focus specifically on $domain test scenarios, edge cases, and quality gates appropriate for $complexity applications. Provide complete, runnable test suites with proper configuration."
    
    # Generate AI-powered tests
    local ai_response
    ai_response=$(call_claude_api "$prompt" 8000)
    
    echo "[$AGENT_ID] Processing AI-generated test suites"
    
    # Save the complete response
    echo "$ai_response" > "$ARTIFACTS_DIR/complete_test_suites.md"
    
    # Create test artifacts based on the response
    create_testing_artifacts "$ai_response" "$domain" "$features" "$tech_stack"
}

# Function to execute documentation tasks
execute_documenter_task() {
    local analysis="$1"
    local agent_capabilities="$2"
    
    local domain=$(echo "$analysis" | jq -r '.requirements_summary.domain')
    local complexity=$(echo "$analysis" | jq -r '.requirements_summary.complexity')
    local features=$(echo "$analysis" | jq -r '.extracted_features // []')
    local tech_stack=$(echo "$analysis" | jq -r '.recommended_stack // {}')
    
    echo "[$AGENT_ID] Executing documentation task for $domain domain"
    
    local prompt="You are a technical documentation specialist. Create comprehensive, professional documentation for a $domain application with $complexity complexity.

Context:
- Domain: $domain
- Complexity: $complexity
- Features: $(echo "$features" | jq -r 'join(", ")')
- Tech Stack: $(echo "$tech_stack" | jq -c '.')

Task: $DESCRIPTION

Generate complete documentation suite including:

1. **Technical Documentation** - For developers and architects:
   - System architecture overview
   - Database schema documentation
   - API reference with examples
   - Code structure and conventions
   - Development setup instructions
   - Security implementation details

2. **User Documentation** - For end users:
   - Getting started guide
   - Feature walkthrough with screenshots
   - $domain-specific workflows and best practices
   - FAQ and common issues
   - User account management
   - Advanced feature guides

3. **Operations Documentation** - For deployment and maintenance:
   - Installation and deployment guide
   - Environment configuration
   - Monitoring and logging setup
   - Backup and recovery procedures
   - Performance tuning guide
   - Troubleshooting manual

4. **Integration Documentation** - For third-party developers:
   - API integration guide
   - SDK documentation (if applicable)
   - Webhook configuration
   - Authentication and authorization
   - Rate limiting and best practices

Focus specifically on $domain workflows, industry best practices, and provide clear, actionable guidance for all user types. Include practical examples and real-world scenarios."
    
    # Generate AI-powered documentation
    local ai_response
    ai_response=$(call_claude_api "$prompt" 10000)
    
    echo "[$AGENT_ID] Processing AI-generated documentation"
    
    # Save the complete response
    echo "$ai_response" > "$ARTIFACTS_DIR/complete_documentation.md"
    
    # Create documentation artifacts based on the response
    create_documentation_artifacts "$ai_response" "$domain" "$features" "$tech_stack"
}

# Function to execute business analyst tasks
execute_business_analyst_task() {
    local analysis="$1"
    local agent_capabilities="$2"
    
    local domain=$(echo "$analysis" | jq -r '.requirements_summary.domain')
    local complexity=$(echo "$analysis" | jq -r '.requirements_summary.complexity')
    local features=$(echo "$analysis" | jq -r '.extracted_features // []')
    local tech_stack=$(echo "$analysis" | jq -r '.recommended_stack // {}')
    
    echo "[$AGENT_ID] Executing business analysis task for $domain domain"
    
    # Create AI prompt for business analysis
    local prompt="You are a senior business analyst and market researcher. Conduct comprehensive business analysis for a $domain application with $complexity complexity.

Context:
- Domain: $domain
- Complexity: $complexity  
- Features: $(echo "$features" | jq -r 'join(", ")')
- Recommended Stack: $(echo "$tech_stack" | jq -c '.')

Task: $DESCRIPTION

Provide detailed business analysis including:

1. **Market Analysis** - Deep market research:
   - Total addressable market (TAM) sizing for $domain
   - Target customer segments and personas
   - Market trends and growth projections
   - Geographic opportunities and constraints
   - Regulatory landscape and compliance requirements

2. **Competitive Analysis** - Comprehensive competitor assessment:
   - Direct and indirect competitors in $domain space
   - Competitive strengths and weaknesses analysis
   - Market positioning opportunities
   - Pricing analysis and benchmarking
   - Feature gap analysis and differentiation opportunities

3. **Business Model Design** - Strategic business framework:
   - Revenue stream recommendations (subscription, freemium, marketplace, etc.)
   - Pricing strategy with tier recommendations
   - Customer acquisition and retention strategies
   - Partnership and distribution channel opportunities
   - Monetization timeline and scaling approach

4. **Financial Projections** - Detailed financial modeling:
   - 3-year revenue and expense projections
   - Customer acquisition cost (CAC) and lifetime value (LTV) analysis
   - Break-even analysis and cash flow projections
   - Funding requirements and investment scenarios
   - Key financial metrics and KPIs

5. **Risk Assessment** - Comprehensive risk analysis:
   - Market risks (competition, adoption, regulation)
   - Technical risks (scalability, security, integration)
   - Financial risks (funding, cash flow, pricing)
   - Operational risks (team, execution, partnerships)
   - Mitigation strategies for each risk category

6. **Go-to-Market Strategy** - Launch and growth plan:
   - Product launch timeline and milestones
   - Marketing and customer acquisition strategy
   - Sales process and channel strategy
   - Partnership and integration opportunities
   - Success metrics and growth tracking

Focus specifically on $domain industry dynamics, proven business models, and actionable recommendations for immediate implementation and long-term success."
    
    # Generate AI-powered business analysis
    local ai_response
    ai_response=$(call_claude_api "$prompt" 12000)
    
    echo "[$AGENT_ID] Processing AI-generated business analysis"
    
    # Save the complete response
    echo "$ai_response" > "$ARTIFACTS_DIR/complete_business_analysis.md"
    
    # Create business analysis artifacts based on the response
    create_business_analysis_artifacts "$ai_response" "$domain" "$features" "$tech_stack"
}

# AI-Based Artifact Creation Functions

# Architecture artifacts creation from AI response
create_architecture_artifacts() {
    local ai_response="$1"
    local domain="$2"
    local features="$3"
    local tech_stack="$4"
    
    echo "[$AGENT_ID] Creating architecture artifacts from AI response"
    
    # Create individual architecture files
    mkdir -p "$ARTIFACTS_DIR/architecture"
    
    # Extract different sections from AI response and save them
    # Note: This is a simplified approach - in a more sophisticated implementation,
    # we would parse the AI response to extract specific sections
    
    # Save tech stack decisions
    echo "$tech_stack" | jq '.' > "$ARTIFACTS_DIR/architecture/tech_stack_decisions.json"
    
    # Create a basic project structure based on the AI analysis
    mkdir -p "$ARTIFACTS_DIR/project"
    echo "[$AGENT_ID] Architecture artifacts created successfully"
}

# Implementation artifacts creation from AI response
create_implementation_artifacts() {
    local ai_response="$1"
    local domain="$2"
    local features="$3"
    local tech_stack="$4"
    
    echo "[$AGENT_ID] Creating implementation artifacts from AI response"
    
    # Create project directories
    mkdir -p "$ARTIFACTS_DIR/project"/{backend,frontend,docs,scripts}
    mkdir -p "$ARTIFACTS_DIR/project/backend"/{src,tests,config}
    mkdir -p "$ARTIFACTS_DIR/project/frontend"/{src,public,tests}
    
    # Save implementation details
    echo "# Implementation Guide" > "$ARTIFACTS_DIR/project/IMPLEMENTATION.md"
    echo "" >> "$ARTIFACTS_DIR/project/IMPLEMENTATION.md"
    echo "Generated for: $domain application" >> "$ARTIFACTS_DIR/project/IMPLEMENTATION.md"
    echo "Technology Stack: $(echo "$tech_stack" | jq -c '.')" >> "$ARTIFACTS_DIR/project/IMPLEMENTATION.md"
    echo "" >> "$ARTIFACTS_DIR/project/IMPLEMENTATION.md"
    echo "## AI-Generated Implementation Details" >> "$ARTIFACTS_DIR/project/IMPLEMENTATION.md"
    echo "Refer to complete_implementation.md for full details." >> "$ARTIFACTS_DIR/project/IMPLEMENTATION.md"
    
    echo "[$AGENT_ID] Implementation artifacts created successfully"
}

# Testing artifacts creation from AI response
create_testing_artifacts() {
    local ai_response="$1"
    local domain="$2"
    local features="$3"
    local tech_stack="$4"
    
    echo "[$AGENT_ID] Creating testing artifacts from AI response"
    
    # Create test directories
    mkdir -p "$ARTIFACTS_DIR/testing"/{unit,integration,e2e,performance}
    
    # Save test strategy
    echo "# Test Strategy for $domain Application" > "$ARTIFACTS_DIR/testing/test_strategy.md"
    echo "" >> "$ARTIFACTS_DIR/testing/test_strategy.md"
    echo "Domain: $domain" >> "$ARTIFACTS_DIR/testing/test_strategy.md"
    echo "Features: $(echo "$features" | jq -r 'join(", ")')" >> "$ARTIFACTS_DIR/testing/test_strategy.md"
    echo "" >> "$ARTIFACTS_DIR/testing/test_strategy.md"
    echo "## AI-Generated Test Suites" >> "$ARTIFACTS_DIR/testing/test_strategy.md"
    echo "Refer to complete_test_suites.md for full test implementation." >> "$ARTIFACTS_DIR/testing/test_strategy.md"
    
    echo "[$AGENT_ID] Testing artifacts created successfully"
}

# Documentation artifacts creation from AI response
create_documentation_artifacts() {
    local ai_response="$1"
    local domain="$2"
    local features="$3"
    local tech_stack="$4"
    
    echo "[$AGENT_ID] Creating documentation artifacts from AI response"
    
    # Create documentation directories
    mkdir -p "$ARTIFACTS_DIR/docs"/{technical,user,api,deployment}
    
    # Save documentation overview
    echo "# Documentation Suite for $domain Application" > "$ARTIFACTS_DIR/docs/README.md"
    echo "" >> "$ARTIFACTS_DIR/docs/README.md"
    echo "This directory contains comprehensive documentation generated for the $domain application." >> "$ARTIFACTS_DIR/docs/README.md"
    echo "" >> "$ARTIFACTS_DIR/docs/README.md"
    echo "## Documentation Types" >> "$ARTIFACTS_DIR/docs/README.md"
    echo "- **Technical**: Architecture, API, and development documentation" >> "$ARTIFACTS_DIR/docs/README.md"
    echo "- **User**: End-user guides and tutorials" >> "$ARTIFACTS_DIR/docs/README.md"
    echo "- **API**: Complete API reference and integration guides" >> "$ARTIFACTS_DIR/docs/README.md"
    echo "- **Deployment**: Installation and operations guides" >> "$ARTIFACTS_DIR/docs/README.md"
    echo "" >> "$ARTIFACTS_DIR/docs/README.md"
    echo "Refer to complete_documentation.md for the full AI-generated documentation." >> "$ARTIFACTS_DIR/docs/README.md"
    
    echo "[$AGENT_ID] Documentation artifacts created successfully"
}

# Business analysis artifacts creation from AI response
create_business_analysis_artifacts() {
    local ai_response="$1"
    local domain="$2"
    local features="$3"
    local tech_stack="$4"
    
    echo "[$AGENT_ID] Creating business analysis artifacts from AI response"
    
    # Create business analysis directories
    mkdir -p "$ARTIFACTS_DIR/business"/{market,financial,strategy,personas}
    
    # Save business analysis overview
    echo "# Business Analysis for $domain Application" > "$ARTIFACTS_DIR/business/README.md"
    echo "" >> "$ARTIFACTS_DIR/business/README.md"
    echo "This directory contains comprehensive business analysis for the $domain application." >> "$ARTIFACTS_DIR/business/README.md"
    echo "" >> "$ARTIFACTS_DIR/business/README.md"
    echo "## Analysis Components" >> "$ARTIFACTS_DIR/business/README.md"
    echo "- **Market**: Market research and competitive analysis" >> "$ARTIFACTS_DIR/business/README.md"
    echo "- **Financial**: Revenue projections and financial modeling" >> "$ARTIFACTS_DIR/business/README.md"
    echo "- **Strategy**: Go-to-market and business model recommendations" >> "$ARTIFACTS_DIR/business/README.md"
    echo "- **Personas**: Target user personas and market segmentation" >> "$ARTIFACTS_DIR/business/README.md"
    echo "" >> "$ARTIFACTS_DIR/business/README.md"
    echo "## Key Features Analyzed" >> "$ARTIFACTS_DIR/business/README.md"
    echo "$(echo "$features" | jq -r '.[] | "- " + .')" >> "$ARTIFACTS_DIR/business/README.md"
    echo "" >> "$ARTIFACTS_DIR/business/README.md"
    echo "Refer to complete_business_analysis.md for the full AI-generated analysis." >> "$ARTIFACTS_DIR/business/README.md"
    
    echo "[$AGENT_ID] Business analysis artifacts created successfully"
}

# Main execution logic
main() {
    echo "[$AGENT_ID] Unified agent executor starting"
    
    # Load requirements analysis
    local analysis
    analysis=$(load_requirements_analysis)
    
    # Load agent configuration (try to find config file)
    local agents_config=""
    for config_file in "$WORKSPACE/../agents_enhanced.json" "$WORKSPACE/../agents.json"; do
        if [[ -f "$config_file" ]]; then
            agents_config="$config_file"
            break
        fi
    done
    
    # Load agent capabilities
    local agent_capabilities
    agent_capabilities=$(load_agent_capabilities "$AGENT_TYPE" "$agents_config")
    
    echo "[$AGENT_ID] Loaded analysis for domain: $(echo "$analysis" | jq -r '.requirements_summary.domain')"
    echo "[$AGENT_ID] Agent capabilities: $(echo "$agent_capabilities" | jq -r '.name // "Unknown"')"
    
    # Execute based on agent type
    case "$AGENT_TYPE" in
        "architect")
            execute_architect_task "$analysis" "$agent_capabilities"
            ;;
        "developer")
            execute_developer_task "$analysis" "$agent_capabilities"
            ;;
        "tester")
            execute_tester_task "$analysis" "$agent_capabilities"
            ;;
        "documenter")
            execute_documenter_task "$analysis" "$agent_capabilities"
            ;;
        "business_analyst")
            execute_business_analyst_task "$analysis" "$agent_capabilities"
            ;;
        *)
            echo "[$AGENT_ID] Unknown agent type: $AGENT_TYPE, using general execution"
            execute_developer_task "$analysis" "$agent_capabilities"
            ;;
    esac
    
    echo "[$AGENT_ID] Task completed successfully"
}

# Execute main function
main