#!/bin/bash

# Enhanced Task Planning System - Uses intelligent planner agent for dynamic analysis

source "${SCRIPT_DIR}/lib/logger.sh"

TASK_PLAN_FILE="${SESSION_WORKSPACE}/task_plan.json"

# Parse specification file and create intelligent task breakdown
plan_tasks() {
    local spec_file="$1"
    local agents_config="$2"
    
    log_info "PLANNER" "Starting intelligent task planning analysis"
    log_info "PLANNER" "Input spec: $spec_file"
    log_info "PLANNER" "Input agents: $agents_config"
    
    # Check if planner agent exists
    if [[ -f "${SCRIPT_DIR}/agents/planner.sh" ]]; then
        log_info "PLANNER" "Using intelligent planner agent for dynamic analysis"
        use_intelligent_planner "$spec_file" "$agents_config"
    else
        log_info "PLANNER" "Falling back to static task planning"
        use_static_planner "$spec_file" "$agents_config"
    fi
    
    log_info "PLANNER" "Task plan created: $TASK_PLAN_FILE"
    echo -e "${GREEN}✅ Task planning completed${NC}" | tee -a "$MAIN_LOG"
}

# Use intelligent planner agent for dynamic task creation
use_intelligent_planner() {
    local spec_file="$1"
    local agents_config="$2"
    
    log_info "PLANNER" "Invoking intelligent planner agent"
    
    # Create task context for planner agent
    local planner_context_file="${SESSION_WORKSPACE}/planner_context.json"
    cat > "$planner_context_file" << EOF
{
    "agent_id": "planner_$(date +%s)",
    "task_id": "plan_intelligent",
    "description": "Analyze requirements and create dynamic task plan",
    "workspace": "$SESSION_WORKSPACE",
    "session_artifacts": "$SESSION_WORKSPACE/artifacts",
    "requirements_file": "$spec_file",
    "agents_config": "$agents_config"
}
EOF
    
    # Create artifacts directory
    mkdir -p "$SESSION_WORKSPACE/artifacts"
    
    # Execute planner agent
    log_info "PLANNER" "Executing intelligent planner agent"
    if "${SCRIPT_DIR}/agents/planner.sh" "$planner_context_file"; then
        # Use the dynamically generated task plan
        local dynamic_plan="$SESSION_WORKSPACE/artifacts/plans/dynamic_task_plan.json"
        if [[ -f "$dynamic_plan" ]]; then
            log_info "PLANNER" "Using dynamically generated task plan"
            cp "$dynamic_plan" "$TASK_PLAN_FILE"
        else
            log_warn "PLANNER" "Dynamic plan not found, falling back to static planning"
            use_static_planner "$spec_file" "$agents_config"
        fi
    else
        log_error "PLANNER" "Intelligent planner failed, falling back to static planning"
        use_static_planner "$spec_file" "$agents_config"
    fi
}

# Fallback static planner (original implementation)
use_static_planner() {
    local spec_file="$1"
    local agents_config="$2"
    
    log_info "PLANNER" "Using static task planning"
    
    # Read and analyze specification
    local spec_content
    spec_content=$(cat "$spec_file")
    
    log_info "PLANNER" "Analyzing specification content (${#spec_content} chars)"
    
    # Extract key information from specification
    local app_purpose app_features app_constraints app_requirements
    app_purpose=$(extract_section "$spec_content" "PURPOSE\\|DESCRIPTION")
    app_features=$(extract_section "$spec_content" "FEATURES\\|FUNCTIONALITY")
    app_constraints=$(extract_section "$spec_content" "CONSTRAINTS\\|TECHNICAL")
    app_requirements=$(extract_section "$spec_content" "REQUIREMENTS\\|SPECS")
    
    # Create initial task breakdown
    create_task_breakdown "$app_purpose" "$app_features" "$app_constraints" "$app_requirements" "$agents_config"
}

# Extract sections from specification text
extract_section() {
    local content="$1"
    local pattern="$2"
    
    echo "$content" | grep -i -A 20 "$pattern" | head -20 || echo "Not specified"
}

# Create comprehensive task breakdown
create_task_breakdown() {
    local purpose="$1"
    local features="$2"
    local constraints="$3"
    local requirements="$4"
    local agents_config="$5"
    
    log_info "PLANNER" "Creating task breakdown"
    
    # Read available agents
    local agents_json
    agents_json=$(cat "$agents_config")
    
    # Create task plan JSON
    cat > "$TASK_PLAN_FILE" << EOF
{
  "metadata": {
    "session_id": "$SESSION_ID",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "spec_analysis": {
      "purpose": "$(echo "$purpose" | tr '\n' ' ' | sed 's/"/\\"/g')",
      "features": "$(echo "$features" | tr '\n' ' ' | sed 's/"/\\"/g')",
      "constraints": "$(echo "$constraints" | tr '\n' ' ' | sed 's/"/\\"/g')",
      "requirements": "$(echo "$requirements" | tr '\n' ' ' | sed 's/"/\\"/g')"
    }
  },
  "phases": {
    "architecture": {
      "phase_id": "arch",
      "description": "System architecture and design decisions",
      "tasks": [
        {
          "task_id": "arch_001",
          "title": "Analyze requirements and define system architecture",
          "description": "Review specification and create high-level system architecture",
          "agent_type": "architect",
          "priority": "critical",
          "dependencies": [],
          "estimated_duration": "30m",
          "inputs": ["specification"],
          "outputs": ["architecture_document", "tech_stack_decisions"]
        },
        {
          "task_id": "arch_002", 
          "title": "Define data models and database schema",
          "description": "Design data structures and database schema based on requirements",
          "agent_type": "architect",
          "priority": "high",
          "dependencies": ["arch_001"],
          "estimated_duration": "20m",
          "inputs": ["architecture_document"],
          "outputs": ["data_models", "database_schema"]
        },
        {
          "task_id": "arch_003",
          "title": "Define API specifications and interfaces",
          "description": "Create API contracts and interface definitions",
          "agent_type": "architect", 
          "priority": "high",
          "dependencies": ["arch_002"],
          "estimated_duration": "25m",
          "inputs": ["data_models"],
          "outputs": ["api_specification"]
        }
      ]
    },
    "implementation": {
      "phase_id": "impl",
      "description": "Code implementation and development",
      "tasks": [
        {
          "task_id": "impl_001",
          "title": "Setup project structure and dependencies",
          "description": "Initialize project with proper structure and install dependencies",
          "agent_type": "developer",
          "priority": "critical",
          "dependencies": ["arch_001"],
          "estimated_duration": "15m",
          "inputs": ["architecture_document", "tech_stack_decisions"],
          "outputs": ["project_structure", "dependency_config"]
        },
        {
          "task_id": "impl_002",
          "title": "Implement data layer and models",
          "description": "Create database models and data access layer",
          "agent_type": "developer",
          "priority": "high", 
          "dependencies": ["impl_001", "arch_002"],
          "estimated_duration": "45m",
          "inputs": ["data_models", "database_schema"],
          "outputs": ["data_layer_code"]
        },
        {
          "task_id": "impl_003",
          "title": "Implement core business logic",
          "description": "Develop main application features and business logic",
          "agent_type": "developer",
          "priority": "critical",
          "dependencies": ["impl_002"],
          "estimated_duration": "60m",
          "inputs": ["data_layer_code", "api_specification"],
          "outputs": ["business_logic_code"]
        },
        {
          "task_id": "impl_004",
          "title": "Implement API endpoints",
          "description": "Create REST API endpoints based on specifications",
          "agent_type": "developer",
          "priority": "high",
          "dependencies": ["impl_003", "arch_003"],
          "estimated_duration": "40m",
          "inputs": ["business_logic_code", "api_specification"],
          "outputs": ["api_endpoints_code"]
        },
        {
          "task_id": "impl_005",
          "title": "Implement user interface",
          "description": "Create user interface components and views",
          "agent_type": "developer",
          "priority": "high",
          "dependencies": ["impl_004"],
          "estimated_duration": "50m",
          "inputs": ["api_endpoints_code"],
          "outputs": ["ui_code"]
        }
      ]
    },
    "testing": {
      "phase_id": "test",
      "description": "Testing and quality assurance",
      "tasks": [
        {
          "task_id": "test_001",
          "title": "Create unit tests for data layer",
          "description": "Write comprehensive unit tests for data models and access layer",
          "agent_type": "tester",
          "priority": "high",
          "dependencies": ["impl_002"],
          "estimated_duration": "30m",
          "inputs": ["data_layer_code"],
          "outputs": ["unit_tests_data"]
        },
        {
          "task_id": "test_002",
          "title": "Create unit tests for business logic",
          "description": "Write unit tests for core business logic functions",
          "agent_type": "tester",
          "priority": "high",
          "dependencies": ["impl_003"],
          "estimated_duration": "40m",
          "inputs": ["business_logic_code"],
          "outputs": ["unit_tests_logic"]
        },
        {
          "task_id": "test_003",
          "title": "Create API integration tests",
          "description": "Write integration tests for API endpoints",
          "agent_type": "tester",
          "priority": "high",
          "dependencies": ["impl_004"],
          "estimated_duration": "35m",
          "inputs": ["api_endpoints_code"],
          "outputs": ["integration_tests"]
        },
        {
          "task_id": "test_004",
          "title": "Create end-to-end tests",
          "description": "Write E2E tests covering main user workflows",
          "agent_type": "tester",
          "priority": "medium",
          "dependencies": ["impl_005"],
          "estimated_duration": "45m",
          "inputs": ["ui_code"],
          "outputs": ["e2e_tests"]
        }
      ]
    },
    "documentation": {
      "phase_id": "docs",
      "description": "Documentation and deployment guides",
      "tasks": [
        {
          "task_id": "docs_001",
          "title": "Create technical documentation",
          "description": "Write comprehensive technical documentation",
          "agent_type": "documenter",
          "priority": "medium",
          "dependencies": ["arch_003", "impl_005"],
          "estimated_duration": "30m",
          "inputs": ["architecture_document", "api_specification", "ui_code"],
          "outputs": ["technical_docs"]
        },
        {
          "task_id": "docs_002",
          "title": "Create user documentation",
          "description": "Write user guides and API documentation",
          "agent_type": "documenter",
          "priority": "medium",
          "dependencies": ["impl_005"],
          "estimated_duration": "25m",
          "inputs": ["ui_code", "api_specification"],
          "outputs": ["user_docs"]
        },
        {
          "task_id": "docs_003",
          "title": "Create deployment guide",
          "description": "Write deployment and setup instructions",
          "agent_type": "documenter",
          "priority": "low",
          "dependencies": ["test_004"],
          "estimated_duration": "20m",
          "inputs": ["project_structure", "dependency_config"],
          "outputs": ["deployment_guide"]
        }
      ]
    }
  },
  "execution_order": [
    "arch_001", "arch_002", "arch_003",
    "impl_001", "impl_002", "impl_003", "impl_004", "impl_005",
    "test_001", "test_002", "test_003", "test_004",
    "docs_001", "docs_002", "docs_003"
  ]
}
EOF
    
    log_info "PLANNER" "Task breakdown created with $(jq '.phases | to_entries | map(.value.tasks | length) | add' "$TASK_PLAN_FILE") total tasks"
}