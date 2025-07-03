#!/bin/bash

# Planner Agent - Intelligent Requirements Analysis and Task Planning
# Analyzes any requirements document and creates dynamic task plans

set -euo pipefail

TASK_CONTEXT_FILE="$1"

# Read task context
TASK_CONTEXT=$(cat "$TASK_CONTEXT_FILE")
AGENT_ID=$(echo "$TASK_CONTEXT" | jq -r '.agent_id')
TASK_ID=$(echo "$TASK_CONTEXT" | jq -r '.task_id')
DESCRIPTION=$(echo "$TASK_CONTEXT" | jq -r '.description')
WORKSPACE=$(echo "$TASK_CONTEXT" | jq -r '.workspace')
ARTIFACTS_DIR=$(echo "$TASK_CONTEXT" | jq -r '.session_artifacts')
REQUIREMENTS_FILE=$(echo "$TASK_CONTEXT" | jq -r '.requirements_file // empty')
AGENTS_CONFIG=$(echo "$TASK_CONTEXT" | jq -r '.agents_config // empty')

echo "[$AGENT_ID] Starting intelligent planning task: $TASK_ID"
echo "[$AGENT_ID] Description: $DESCRIPTION"

# Create analysis directories
mkdir -p "$ARTIFACTS_DIR/analysis"
mkdir -p "$ARTIFACTS_DIR/plans"

# Function to analyze requirements document
analyze_requirements() {
    local requirements_file="$1"
    local analysis_file="$ARTIFACTS_DIR/analysis/requirements_analysis.json"
    
    echo "[$AGENT_ID] Analyzing requirements document: $requirements_file"
    
    # Read and process requirements
    local requirements_content
    requirements_content=$(cat "$requirements_file")
    
    # Detect application domain and complexity
    local domain complexity scale architecture_style
    domain=$(detect_application_domain "$requirements_content")
    complexity=$(assess_complexity "$requirements_content")
    scale=$(determine_scale "$requirements_content")
    architecture_style=$(recommend_architecture "$requirements_content" "$complexity" "$scale")
    
    # Extract key features and constraints
    local features constraints technical_requirements
    features=$(extract_features "$requirements_content")
    constraints=$(extract_constraints "$requirements_content")
    technical_requirements=$(extract_technical_requirements "$requirements_content")
    
    # Create comprehensive analysis
    cat > "$analysis_file" << EOF
{
  "analysis_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "requirements_summary": {
    "domain": "$domain",
    "complexity": "$complexity",
    "scale": "$scale",
    "architecture_style": "$architecture_style"
  },
  "extracted_features": $features,
  "technical_constraints": $constraints,
  "technical_requirements": $technical_requirements,
  "recommended_stack": $(recommend_tech_stack "$domain" "$complexity" "$scale"),
  "estimated_effort": $(estimate_development_effort "$features" "$complexity"),
  "risk_factors": $(identify_risk_factors "$requirements_content")
}
EOF
    
    echo "[$AGENT_ID] Requirements analysis completed: $analysis_file"
    echo "$analysis_file"
}

# Function to detect application domain
detect_application_domain() {
    local content="$1"
    local domain="general"
    
    # Check for domain-specific keywords
    if echo "$content" | grep -qi -E "(e-commerce|shop|cart|payment|product|inventory)"; then
        domain="ecommerce"
    elif echo "$content" | grep -qi -E "(blog|content|cms|article|post|publication)"; then
        domain="content_management"
    elif echo "$content" | grep -qi -E "(task|project|kanban|scrum|ticket|issue|workflow)"; then
        domain="project_management"
    elif echo "$content" | grep -qi -E "(social|chat|message|friend|follow|like|share)"; then
        domain="social_platform"
    elif echo "$content" | grep -qi -E "(learn|course|education|student|teacher|quiz|exam)"; then
        domain="learning_management"
    elif echo "$content" | grep -qi -E "(finance|bank|transaction|account|payment|wallet)"; then
        domain="fintech"
    elif echo "$content" | grep -qi -E "(health|medical|patient|doctor|appointment|clinic)"; then
        domain="healthcare"
    elif echo "$content" | grep -qi -E "(iot|sensor|device|monitor|automation|smart)"; then
        domain="iot"
    elif echo "$content" | grep -qi -E "(api|service|microservice|integration|webhook)"; then
        domain="api_platform"
    elif echo "$content" | grep -qi -E "(analytics|dashboard|report|metric|visualization|chart)"; then
        domain="analytics"
    fi
    
    echo "$domain"
}

# Function to assess complexity
assess_complexity() {
    local content="$1"
    local complexity="medium"
    
    # Count complexity indicators
    local complexity_score=0
    
    # User management complexity
    if echo "$content" | grep -qi -E "(auth|login|register|permission|role)"; then
        ((complexity_score += 1))
    fi
    
    # Data complexity
    if echo "$content" | grep -qi -E "(database|model|relation|schema|sql)"; then
        ((complexity_score += 1))
    fi
    
    # Real-time features
    if echo "$content" | grep -qi -E "(real-time|websocket|notification|live|instant)"; then
        ((complexity_score += 2))
    fi
    
    # Integration complexity
    if echo "$content" | grep -qi -E "(api|integration|third-party|webhook|external)"; then
        ((complexity_score += 1))
    fi
    
    # File handling
    if echo "$content" | grep -qi -E "(upload|file|image|document|storage)"; then
        ((complexity_score += 1))
    fi
    
    # Payment processing
    if echo "$content" | grep -qi -E "(payment|stripe|paypal|transaction|billing)"; then
        ((complexity_score += 2))
    fi
    
    # Mobile support
    if echo "$content" | grep -qi -E "(mobile|responsive|app|ios|android)"; then
        ((complexity_score += 1))
    fi
    
    # Determine complexity level
    if [[ $complexity_score -ge 6 ]]; then
        complexity="high"
    elif [[ $complexity_score -le 2 ]]; then
        complexity="low"
    fi
    
    echo "$complexity"
}

# Function to determine scale requirements
determine_scale() {
    local content="$1"
    local scale="small"
    
    # Look for scale indicators
    if echo "$content" | grep -qi -E "([0-9]+k|[0-9]+,000|thousand.*user)"; then
        scale="medium"
    elif echo "$content" | grep -qi -E "([0-9]+m|[0-9]+,000,000|million.*user|enterprise|large.*scale)"; then
        scale="large"
    elif echo "$content" | grep -qi -E "(concurrent.*[1-9][0-9][0-9]+|[1-9][0-9][0-9]+.*concurrent)"; then
        scale="medium"
    elif echo "$content" | grep -qi -E "(concurrent.*[1-9][0-9]+|[1-9][0-9]+.*concurrent)"; then
        scale="small"
    fi
    
    echo "$scale"
}

# Function to recommend architecture style
recommend_architecture() {
    local content="$1"
    local complexity="$2"
    local scale="$3"
    local architecture="monolith"
    
    # Microservices indicators
    if [[ "$complexity" == "high" && "$scale" == "large" ]]; then
        architecture="microservices"
    elif echo "$content" | grep -qi -E "(microservice|service.*oriented|distributed|api.*gateway)"; then
        architecture="microservices"
    elif echo "$content" | grep -qi -E "(serverless|lambda|function.*service|faas)"; then
        architecture="serverless"
    elif [[ "$scale" == "medium" && "$complexity" == "high" ]]; then
        architecture="modular_monolith"
    fi
    
    echo "$architecture"
}

# Function to extract features
extract_features() {
    local content="$1"
    
    # Create feature array
    local features='[]'
    
    # Common features detection
    local feature_patterns=(
        "authentication:auth|login|register|signin|signup"
        "user_management:user.*manage|profile|account"
        "dashboard:dashboard|overview|analytics"
        "search:search|filter|query"
        "notifications:notification|alert|email|sms"
        "file_upload:upload|file|attachment|image"
        "comments:comment|discussion|feedback"
        "real_time:real.*time|live|websocket|instant"
        "reporting:report|analytics|chart|graph"
        "api:api|rest|graphql|endpoint"
        "mobile:mobile|responsive|app"
        "payment:payment|billing|transaction|stripe"
        "social:social|share|like|follow"
        "workflow:workflow|approval|process"
        "scheduling:schedule|calendar|appointment"
        "messaging:message|chat|conversation"
        "integration:integration|webhook|third.*party"
        "backup:backup|export|import|data.*transfer"
        "security:security|encrypt|secure|permission"
        "monitoring:monitor|log|track|audit"
    )
    
    for pattern in "${feature_patterns[@]}"; do
        local feature_name="${pattern%%:*}"
        local regex="${pattern##*:}"
        if echo "$content" | grep -qi -E "$regex"; then
            features=$(echo "$features" | jq ". + [\"$feature_name\"]")
        fi
    done
    
    echo "$features"
}

# Function to extract constraints
extract_constraints() {
    local content="$1"
    
    local constraints='{}'
    
    # Performance constraints
    if echo "$content" | grep -qi -E "([0-9]+.*second|response.*time|performance)"; then
        local response_time
        response_time=$(echo "$content" | grep -oi -E "[0-9]+.*second" | head -1 || echo "2 seconds")
        constraints=$(echo "$constraints" | jq ". + {\"max_response_time\": \"$response_time\"}")
    fi
    
    # Concurrent users
    if echo "$content" | grep -qi -E "(concurrent.*[0-9]+|[0-9]+.*concurrent)"; then
        local concurrent_users
        concurrent_users=$(echo "$content" | grep -oi -E "[0-9]+" | head -1 || echo "100")
        constraints=$(echo "$constraints" | jq ". + {\"concurrent_users\": $concurrent_users}")
    fi
    
    # Browser compatibility
    if echo "$content" | grep -qi -E "(browser|chrome|firefox|safari|edge)"; then
        constraints=$(echo "$constraints" | jq ". + {\"browser_compatibility\": true}")
    fi
    
    # Security requirements
    if echo "$content" | grep -qi -E "(gdpr|security|encrypt|compliance)"; then
        constraints=$(echo "$constraints" | jq ". + {\"security_compliance\": true}")
    fi
    
    echo "$constraints"
}

# Function to extract technical requirements
extract_technical_requirements() {
    local content="$1"
    
    local tech_reqs='{}'
    
    # Database requirements
    if echo "$content" | grep -qi -E "(database|sql|nosql|postgres|mongo)"; then
        tech_reqs=$(echo "$tech_reqs" | jq ". + {\"database_required\": true}")
    fi
    
    # Real-time requirements
    if echo "$content" | grep -qi -E "(real.*time|websocket|live|instant)"; then
        tech_reqs=$(echo "$tech_reqs" | jq ". + {\"real_time_features\": true}")
    fi
    
    # File storage
    if echo "$content" | grep -qi -E "(upload|file|storage|image|document)"; then
        tech_reqs=$(echo "$tech_reqs" | jq ". + {\"file_storage\": true}")
    fi
    
    # Email system
    if echo "$content" | grep -qi -E "(email|notification|smtp|mail)"; then
        tech_reqs=$(echo "$tech_reqs" | jq ". + {\"email_system\": true}")
    fi
    
    # Caching
    if echo "$content" | grep -qi -E "(cache|redis|performance|fast)"; then
        tech_reqs=$(echo "$tech_reqs" | jq ". + {\"caching_required\": true}")
    fi
    
    echo "$tech_reqs"
}

# Function to recommend tech stack
recommend_tech_stack() {
    local domain="$1"
    local complexity="$2" 
    local scale="$3"
    
    local stack='{}'
    
    # Backend selection based on complexity and scale
    case "$complexity" in
        "low")
            if [[ "$scale" == "small" ]]; then
                stack=$(echo "$stack" | jq ". + {\"backend\": \"express\", \"language\": \"javascript\"}")
            else
                stack=$(echo "$stack" | jq ". + {\"backend\": \"express\", \"language\": \"typescript\"}")
            fi
            ;;
        "medium")
            stack=$(echo "$stack" | jq ". + {\"backend\": \"express\", \"language\": \"typescript\"}")
            ;;
        "high")
            if [[ "$scale" == "large" ]]; then
                stack=$(echo "$stack" | jq ". + {\"backend\": \"microservices\", \"language\": \"typescript\", \"framework\": \"nestjs\"}")
            else
                stack=$(echo "$stack" | jq ". + {\"backend\": \"express\", \"language\": \"typescript\"}")
            fi
            ;;
    esac
    
    # Database selection based on domain and scale
    case "$domain" in
        "analytics"|"iot")
            stack=$(echo "$stack" | jq ". + {\"database\": \"postgresql\", \"analytics_db\": \"clickhouse\"}")
            ;;
        "social_platform"|"content_management")
            if [[ "$scale" == "large" ]]; then
                stack=$(echo "$stack" | jq ". + {\"database\": \"postgresql\", \"document_store\": \"mongodb\"}")
            else
                stack=$(echo "$stack" | jq ". + {\"database\": \"postgresql\"}")
            fi
            ;;
        "ecommerce")
            stack=$(echo "$stack" | jq ". + {\"database\": \"postgresql\", \"search_engine\": \"elasticsearch\"}")
            ;;
        *)
            if [[ "$scale" == "small" && "$complexity" == "low" ]]; then
                stack=$(echo "$stack" | jq ". + {\"database\": \"sqlite\"}")
            else
                stack=$(echo "$stack" | jq ". + {\"database\": \"postgresql\"}")
            fi
            ;;
    esac
    
    # Frontend selection based on complexity and domain
    case "$complexity" in
        "low")
            stack=$(echo "$stack" | jq ". + {\"frontend\": \"react\", \"styling\": \"css\"}")
            ;;
        "medium")
            if [[ "$domain" == "analytics" ]]; then
                stack=$(echo "$stack" | jq ". + {\"frontend\": \"react_typescript\", \"charts\": \"recharts\", \"styling\": \"tailwind\"}")
            else
                stack=$(echo "$stack" | jq ". + {\"frontend\": \"react_typescript\", \"styling\": \"material_ui\"}")
            fi
            ;;
        "high")
            case "$domain" in
                "ecommerce")
                    stack=$(echo "$stack" | jq ". + {\"frontend\": \"next_js\", \"styling\": \"tailwind\", \"state\": \"zustand\"}")
                    ;;
                "social_platform")
                    stack=$(echo "$stack" | jq ". + {\"frontend\": \"react_typescript\", \"real_time\": \"socket_io_client\", \"styling\": \"chakra_ui\"}")
                    ;;
                *)
                    stack=$(echo "$stack" | jq ". + {\"frontend\": \"react_typescript\", \"state\": \"redux_toolkit\", \"styling\": \"material_ui\"}")
                    ;;
            esac
            ;;
    esac
    
    # Caching and performance based on scale
    case "$scale" in
        "small")
            # No additional caching for small scale
            ;;
        "medium")
            stack=$(echo "$stack" | jq ". + {\"cache\": \"redis\"}")
            ;;
        "large")
            stack=$(echo "$stack" | jq ". + {\"cache\": \"redis\", \"queue\": \"bullmq\", \"cdn\": \"cloudflare\"}")
            ;;
    esac
    
    # Domain-specific technology additions
    case "$domain" in
        "ecommerce")
            stack=$(echo "$stack" | jq ". + {\"payment\": \"stripe\", \"inventory\": \"warehouse_management\", \"email\": \"sendgrid\"}")
            if [[ "$scale" != "small" ]]; then
                stack=$(echo "$stack" | jq ". + {\"search\": \"elasticsearch\"}")
            fi
            ;;
        "social_platform")
            stack=$(echo "$stack" | jq ". + {\"real_time\": \"socket_io\", \"file_storage\": \"aws_s3\", \"notifications\": \"push_notifications\"}")
            ;;
        "analytics")
            stack=$(echo "$stack" | jq ". + {\"visualization\": \"d3_js\", \"data_processing\": \"pandas\", \"api_analytics\": \"mixpanel\"}")
            ;;
        "fintech")
            stack=$(echo "$stack" | jq ". + {\"security\": \"oauth2\", \"encryption\": \"bcrypt\", \"compliance\": \"audit_logging\", \"payment\": \"stripe_connect\"}")
            ;;
        "healthcare")
            stack=$(echo "$stack" | jq ". + {\"security\": \"hipaa_compliance\", \"encryption\": \"end_to_end\", \"audit\": \"comprehensive_logging\"}")
            ;;
        "iot")
            stack=$(echo "$stack" | jq ". + {\"messaging\": \"mqtt\", \"time_series\": \"influxdb\", \"monitoring\": \"grafana\"}")
            ;;
        "learning_management")
            stack=$(echo "$stack" | jq ". + {\"video\": \"video_streaming\", \"progress_tracking\": \"xapi\", \"assessment\": \"quiz_engine\"}")
            ;;
        "project_management")
            stack=$(echo "$stack" | jq ". + {\"real_time\": \"socket_io\", \"file_sharing\": \"file_upload\", \"notifications\": \"email_websocket\"}")
            ;;
    esac
    
    # Development and deployment tools
    if [[ "$complexity" == "high" || "$scale" == "large" ]]; then
        stack=$(echo "$stack" | jq ". + {\"containerization\": \"docker\", \"orchestration\": \"docker_compose\", \"monitoring\": \"prometheus\"}")
    else
        stack=$(echo "$stack" | jq ". + {\"containerization\": \"docker\"}")
    fi
    
    # Testing strategy based on complexity
    case "$complexity" in
        "low")
            stack=$(echo "$stack" | jq ". + {\"testing\": \"jest\"}")
            ;;
        "medium")
            stack=$(echo "$stack" | jq ". + {\"testing\": \"jest\", \"e2e\": \"cypress\"}")
            ;;
        "high")
            stack=$(echo "$stack" | jq ". + {\"testing\": \"jest\", \"e2e\": \"playwright\", \"api_testing\": \"supertest\"}")
            ;;
    esac
    
    echo "$stack"
}

# Function to estimate development effort
estimate_development_effort() {
    local features="$1"
    local complexity="$2"
    
    local feature_count
    feature_count=$(echo "$features" | jq 'length')
    
    local base_hours=40
    local complexity_multiplier=1
    
    case "$complexity" in
        "low") complexity_multiplier=1 ;;
        "medium") complexity_multiplier=2 ;;
        "high") complexity_multiplier=3 ;;
    esac
    
    # Calculate without bc dependency
    local feature_hours=$((feature_count * 8))
    local total_hours=$((base_hours + (feature_hours * complexity_multiplier)))
    local total_days=$((total_hours / 8))
    
    echo "{\"estimated_hours\": $total_hours, \"estimated_days\": $total_days}"
}

# Function to identify risk factors
identify_risk_factors() {
    local content="$1"
    
    local risks='[]'
    
    # High complexity risks
    if echo "$content" | grep -qi -E "(real.*time|websocket)"; then
        risks=$(echo "$risks" | jq ". + [\"real_time_complexity\"]")
    fi
    
    if echo "$content" | grep -qi -E "(payment|financial|money)"; then
        risks=$(echo "$risks" | jq ". + [\"financial_data_security\"]")
    fi
    
    if echo "$content" | grep -qi -E "(scale|million|concurrent.*[0-9]{3,})"; then
        risks=$(echo "$risks" | jq ". + [\"scalability_challenges\"]")
    fi
    
    if echo "$content" | grep -qi -E "(integration|third.*party|api.*external)"; then
        risks=$(echo "$risks" | jq ". + [\"external_dependencies\"]")
    fi
    
    echo "$risks"
}

# Function to create dynamic task plan
create_dynamic_task_plan() {
    local analysis_file="$1"
    local agents_config="$2"
    local task_plan_file="$ARTIFACTS_DIR/plans/dynamic_task_plan.json"
    
    echo "[$AGENT_ID] Creating dynamic task plan based on analysis"
    
    # Read analysis results
    local analysis
    analysis=$(cat "$analysis_file")
    
    # Extract key information
    local domain complexity feature_count
    domain=$(echo "$analysis" | jq -r '.requirements_summary.domain')
    complexity=$(echo "$analysis" | jq -r '.requirements_summary.complexity')
    feature_count=$(echo "$analysis" | jq '.extracted_features | length')
    
    # Create simplified dynamic task plan
    cat > "$task_plan_file" << EOF
{
  "metadata": {
    "session_id": "${SESSION_ID:-dynamic}",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "planner_agent": "$AGENT_ID",
    "analysis_summary": {
      "domain": "$domain",
      "complexity": "$complexity",
      "total_features": $feature_count
    }
  },
  "phases": {
    "business_analysis": {
      "phase_id": "business",
      "description": "Business feasibility and market analysis",
      "tasks": [
        {
          "task_id": "biz_001",
          "title": "Market research and competitive analysis for $domain",
          "description": "Analyze market size, competition, and opportunities for $domain application",
          "agent_type": "business_analyst",
          "priority": "high",
          "dependencies": [],
          "estimated_duration": "45m",
          "inputs": ["requirements_document"],
          "outputs": ["market_analysis", "competitive_landscape"]
        },
        {
          "task_id": "biz_002", 
          "title": "Business model and monetization strategy",
          "description": "Define business model, revenue streams, and monetization approach for $domain",
          "agent_type": "business_analyst",
          "priority": "high",
          "dependencies": ["biz_001"],
          "estimated_duration": "30m",
          "inputs": ["market_analysis"],
          "outputs": ["business_model", "monetization_strategy"]
        },
        {
          "task_id": "biz_003",
          "title": "Risk assessment and feasibility analysis",
          "description": "Identify business and technical risks, validate feasibility for $domain application",
          "agent_type": "business_analyst",
          "priority": "medium",
          "dependencies": ["biz_002"],
          "estimated_duration": "25m",
          "inputs": ["business_model", "requirements_analysis"],
          "outputs": ["risk_assessment", "feasibility_report"]
        }
      ]
    },
    "architecture": {
      "phase_id": "arch",
      "description": "System architecture and design decisions",
      "tasks": [
        {
          "task_id": "arch_001",
          "title": "Define system architecture for $domain application",
          "description": "Create high-level system architecture optimized for $domain with $complexity complexity",
          "agent_type": "architect",
          "priority": "high",
          "dependencies": ["biz_003"],
          "estimated_duration": "30m",
          "inputs": ["requirements_analysis", "feasibility_report"],
          "outputs": ["system_architecture", "tech_stack_decisions"]
        },
        {
          "task_id": "arch_002",
          "title": "Design domain-specific data models",
          "description": "Design data models and database schema for $domain application",
          "agent_type": "architect",
          "priority": "high",
          "dependencies": ["arch_001"],
          "estimated_duration": "25m",
          "inputs": ["system_architecture"],
          "outputs": ["data_models", "database_schema"]
        },
        {
          "task_id": "arch_003",
          "title": "Define API specifications",
          "description": "Create API contracts tailored for $domain functionality",
          "agent_type": "architect",
          "priority": "high",
          "dependencies": ["arch_002"],
          "estimated_duration": "20m",
          "inputs": ["data_models"],
          "outputs": ["api_specification"]
        }
      ]
    },
    "implementation": {
      "phase_id": "impl",
      "description": "Feature implementation based on detected requirements",
      "tasks": [
        {
          "task_id": "impl_001",
          "title": "Setup project structure",
          "description": "Initialize project with structure optimized for $domain applications",
          "agent_type": "developer",
          "priority": "high",
          "dependencies": ["arch_001"],
          "estimated_duration": "15m",
          "inputs": ["system_architecture"],
          "outputs": ["project_structure"]
        },
        {
          "task_id": "impl_002",
          "title": "Implement data layer",
          "description": "Create data access layer with domain-specific models",
          "agent_type": "developer",
          "priority": "high",
          "dependencies": ["impl_001", "arch_002"],
          "estimated_duration": "30m",
          "inputs": ["data_models", "database_schema"],
          "outputs": ["data_layer"]
        },
        {
          "task_id": "impl_003",
          "title": "Implement core business logic",
          "description": "Develop $domain-specific business logic and features",
          "agent_type": "developer",
          "priority": "high",
          "dependencies": ["impl_002"],
          "estimated_duration": "45m",
          "inputs": ["data_layer"],
          "outputs": ["business_logic"]
        },
        {
          "task_id": "impl_004",
          "title": "Implement API endpoints",
          "description": "Create REST API endpoints for $domain functionality",
          "agent_type": "developer",
          "priority": "high",
          "dependencies": ["impl_003", "arch_003"],
          "estimated_duration": "35m",
          "inputs": ["business_logic", "api_specification"],
          "outputs": ["api_endpoints"]
        },
        {
          "task_id": "impl_005",
          "title": "Implement user interface",
          "description": "Create UI optimized for $domain workflows",
          "agent_type": "developer",
          "priority": "high",
          "dependencies": ["impl_004"],
          "estimated_duration": "40m",
          "inputs": ["api_endpoints"],
          "outputs": ["user_interface"]
        }
      ]
    },
    "testing": {
      "phase_id": "test",
      "description": "Comprehensive testing for $complexity complexity application",
      "tasks": [
        {
          "task_id": "test_001",
          "title": "Create unit tests",
          "description": "Write unit tests covering $domain business logic",
          "agent_type": "tester",
          "priority": "high",
          "dependencies": ["impl_003"],
          "estimated_duration": "30m",
          "inputs": ["business_logic"],
          "outputs": ["unit_tests"]
        },
        {
          "task_id": "test_002",
          "title": "Create integration tests",
          "description": "Write integration tests for $domain API endpoints",
          "agent_type": "tester",
          "priority": "high",
          "dependencies": ["impl_004"],
          "estimated_duration": "35m",
          "inputs": ["api_endpoints"],
          "outputs": ["integration_tests"]
        },
        {
          "task_id": "test_003",
          "title": "Create end-to-end tests",
          "description": "Write E2E tests for $domain user workflows",
          "agent_type": "tester",
          "priority": "medium",
          "dependencies": ["impl_005"],
          "estimated_duration": "30m",
          "inputs": ["user_interface"],
          "outputs": ["e2e_tests"]
        }
      ]
    },
    "documentation": {
      "phase_id": "docs",
      "description": "Documentation for $domain application",
      "tasks": [
        {
          "task_id": "docs_001",
          "title": "Create technical documentation",
          "description": "Write technical docs for $domain application architecture",
          "agent_type": "documenter",
          "priority": "medium",
          "dependencies": ["arch_003"],
          "estimated_duration": "25m",
          "inputs": ["system_architecture", "api_specification"],
          "outputs": ["technical_docs"]
        },
        {
          "task_id": "docs_002",
          "title": "Create user documentation",
          "description": "Write user guides for $domain workflows",
          "agent_type": "documenter",
          "priority": "medium",
          "dependencies": ["impl_005"],
          "estimated_duration": "20m",
          "inputs": ["user_interface"],
          "outputs": ["user_docs"]
        },
        {
          "task_id": "docs_003",
          "title": "Create deployment guide",
          "description": "Write deployment instructions for $domain application",
          "agent_type": "documenter",
          "priority": "low",
          "dependencies": ["test_003"],
          "estimated_duration": "15m",
          "inputs": ["project_structure"],
          "outputs": ["deployment_guide"]
        }
      ]
    }
  },
  "execution_order": [
    "biz_001", "biz_002", "biz_003",
    "arch_001", "arch_002", "arch_003",
    "impl_001", "impl_002", "impl_003", "impl_004", "impl_005", 
    "test_001", "test_002", "test_003",
    "docs_001", "docs_002", "docs_003"
  ],
  "agent_assignments": {
    "business_analyst": "business_analyst",
    "architect": "architect",
    "developer": "developer", 
    "tester": "tester",
    "documenter": "documenter"
  }
}
EOF
    
    echo "[$AGENT_ID] Dynamic task plan created: $task_plan_file"
    echo "$task_plan_file"
}

# Function to create planning phase
create_planning_phase() {
    local task_plan="$1"
    local analysis="$2"
    
    echo "$task_plan" | jq '.phases.planning = {
        "phase_id": "planning",
        "description": "Requirements analysis and project planning",
        "tasks": [
            {
                "task_id": "plan_001",
                "title": "Deep requirements analysis",
                "description": "Analyze requirements and create detailed project specification",
                "agent_type": "analyst",
                "priority": "high",
                "dependencies": [],
                "estimated_duration": "20m",
                "inputs": ["requirements_document"],
                "outputs": ["detailed_specification", "feature_breakdown"]
            },
            {
                "task_id": "plan_002", 
                "title": "Technical feasibility assessment",
                "description": "Assess technical feasibility and identify potential challenges",
                "agent_type": "architect",
                "priority": "high",
                "dependencies": ["plan_001"],
                "estimated_duration": "15m",
                "inputs": ["detailed_specification"],
                "outputs": ["feasibility_report", "risk_assessment"]
            }
        ]
    }'
}

# Function to create architecture phase
create_architecture_phase() {
    local task_plan="$1"
    local analysis="$2"
    local tech_stack="$3"
    
    echo "$task_plan" | jq '.phases.architecture = {
        "phase_id": "architecture",
        "description": "System architecture and design decisions",
        "tasks": [
            {
                "task_id": "arch_001",
                "title": "Define system architecture",
                "description": "Create high-level system architecture based on requirements",
                "agent_type": "architect",
                "priority": "high",
                "dependencies": ["plan_002"],
                "estimated_duration": "30m",
                "inputs": ["detailed_specification", "feasibility_report"],
                "outputs": ["system_architecture", "component_diagram"]
            },
            {
                "task_id": "arch_002",
                "title": "Design data models",
                "description": "Design database schema and data models",
                "agent_type": "architect",
                "priority": "high", 
                "dependencies": ["arch_001"],
                "estimated_duration": "25m",
                "inputs": ["system_architecture"],
                "outputs": ["data_models", "database_schema"]
            },
            {
                "task_id": "arch_003",
                "title": "Define API specifications",
                "description": "Create API contracts and interface definitions",
                "agent_type": "architect",
                "priority": "high",
                "dependencies": ["arch_002"],
                "estimated_duration": "20m",
                "inputs": ["data_models"],
                "outputs": ["api_specification"]
            }
        ]
    }'
}

# Function to create implementation phases
create_implementation_phases() {
    local task_plan="$1"
    local features="$2"
    local tech_stack="$3"
    
    # Start with basic implementation tasks
    task_plan=$(echo "$task_plan" | jq '.phases.implementation = {
        "phase_id": "implementation",
        "description": "Core application development",
        "tasks": [
            {
                "task_id": "impl_001",
                "title": "Setup project structure",
                "description": "Initialize project with proper structure and dependencies",
                "agent_type": "developer",
                "priority": "high",
                "dependencies": ["arch_001"],
                "estimated_duration": "15m",
                "inputs": ["system_architecture"],
                "outputs": ["project_structure"]
            },
            {
                "task_id": "impl_002",
                "title": "Implement data layer",
                "description": "Create database models and data access layer",
                "agent_type": "developer",
                "priority": "high",
                "dependencies": ["impl_001", "arch_002"],
                "estimated_duration": "30m",
                "inputs": ["data_models", "database_schema"],
                "outputs": ["data_layer"]
            },
            {
                "task_id": "impl_003",
                "title": "Implement core business logic",
                "description": "Develop main application features and business logic",
                "agent_type": "developer",
                "priority": "high",
                "dependencies": ["impl_002"],
                "estimated_duration": "45m",
                "inputs": ["data_layer"],
                "outputs": ["business_logic"]
            }
        ]
    }')
    
    # Add feature-specific implementation tasks
    local feature_list
    feature_list=$(echo "$features" | jq -r '.[]')
    local task_counter=4
    
    while IFS= read -r feature; do
        if [[ -n "$feature" ]]; then
            local task_id="impl_$(printf "%03d" $task_counter)"
            local feature_task
            feature_task=$(create_feature_implementation_task "$task_id" "$feature")
            task_plan=$(echo "$task_plan" | jq ".phases.implementation.tasks += [$feature_task]")
            ((task_counter++))
        fi
    done <<< "$feature_list"
    
    echo "$task_plan"
}

# Function to create feature-specific implementation task
create_feature_implementation_task() {
    local task_id="$1"
    local feature="$2"
    
    local title description duration
    
    case "$feature" in
        "authentication")
            title="Implement user authentication"
            description="Create user registration, login, and authentication system"
            duration="40m"
            ;;
        "user_management")
            title="Implement user management"
            description="Create user profile management and administration features"
            duration="30m"
            ;;
        "dashboard")
            title="Implement dashboard"
            description="Create main dashboard with overview and analytics"
            duration="35m"
            ;;
        "search")
            title="Implement search functionality"
            description="Create search and filtering capabilities"
            duration="25m"
            ;;
        "notifications")
            title="Implement notification system"
            description="Create notification delivery and management system"
            duration="30m"
            ;;
        "file_upload")
            title="Implement file upload"
            description="Create file upload and storage functionality"
            duration="25m"
            ;;
        "real_time")
            title="Implement real-time features"
            description="Create websocket connections and real-time updates"
            duration="40m"
            ;;
        "payment")
            title="Implement payment processing"
            description="Integrate payment gateway and transaction handling"
            duration="45m"
            ;;
        *)
            title="Implement $feature"
            description="Implement $feature functionality"
            duration="30m"
            ;;
    esac
    
    jq -n --arg id "$task_id" --arg title "$title" --arg desc "$description" --arg dur "$duration" '{
        "task_id": $id,
        "title": $title,
        "description": $desc,
        "agent_type": "developer",
        "priority": "medium",
        "dependencies": ["impl_003"],
        "estimated_duration": $dur,
        "inputs": ["business_logic"],
        "outputs": [($title | ascii_downcase | gsub(" "; "_"))]
    }'
}

# Function to create testing phase
create_testing_phase() {
    local task_plan="$1"
    local features="$2"
    local complexity="$3"
    
    echo "$task_plan" | jq '.phases.testing = {
        "phase_id": "testing",
        "description": "Quality assurance and testing",
        "tasks": [
            {
                "task_id": "test_001",
                "title": "Create unit tests",
                "description": "Write comprehensive unit tests for all components",
                "agent_type": "tester",
                "priority": "high",
                "dependencies": ["impl_003"],
                "estimated_duration": "40m",
                "inputs": ["business_logic"],
                "outputs": ["unit_tests"]
            },
            {
                "task_id": "test_002",
                "title": "Create integration tests",
                "description": "Write integration tests for API endpoints and workflows",
                "agent_type": "tester", 
                "priority": "high",
                "dependencies": ["test_001"],
                "estimated_duration": "35m",
                "inputs": ["business_logic", "api_specification"],
                "outputs": ["integration_tests"]
            },
            {
                "task_id": "test_003",
                "title": "Create end-to-end tests",
                "description": "Write E2E tests covering main user workflows",
                "agent_type": "tester",
                "priority": "medium",
                "dependencies": ["test_002"],
                "estimated_duration": "30m",
                "inputs": ["integration_tests"],
                "outputs": ["e2e_tests"]
            }
        ]
    }'
}

# Function to create deployment phase
create_deployment_phase() {
    local task_plan="$1"
    local tech_stack="$2"
    
    echo "$task_plan" | jq '.phases.deployment = {
        "phase_id": "deployment",
        "description": "Deployment configuration and setup",
        "tasks": [
            {
                "task_id": "deploy_001",
                "title": "Create deployment configuration",
                "description": "Create Docker and deployment configurations",
                "agent_type": "devops",
                "priority": "medium",
                "dependencies": ["test_003"],
                "estimated_duration": "25m",
                "inputs": ["project_structure"],
                "outputs": ["deployment_config"]
            },
            {
                "task_id": "deploy_002",
                "title": "Setup CI/CD pipeline",
                "description": "Configure continuous integration and deployment",
                "agent_type": "devops",
                "priority": "low",
                "dependencies": ["deploy_001"],
                "estimated_duration": "30m",
                "inputs": ["deployment_config"],
                "outputs": ["cicd_pipeline"]
            }
        ]
    }'
}

# Function to create documentation phase
create_documentation_phase() {
    local task_plan="$1"
    local domain="$2"
    
    echo "$task_plan" | jq '.phases.documentation = {
        "phase_id": "documentation",
        "description": "Project documentation and guides",
        "tasks": [
            {
                "task_id": "docs_001",
                "title": "Create technical documentation",
                "description": "Write comprehensive technical documentation",
                "agent_type": "documenter",
                "priority": "medium",
                "dependencies": ["deploy_001"],
                "estimated_duration": "30m",
                "inputs": ["system_architecture", "api_specification"],
                "outputs": ["technical_docs"]
            },
            {
                "task_id": "docs_002",
                "title": "Create user documentation",
                "description": "Write user guides and manuals",
                "agent_type": "documenter",
                "priority": "low",
                "dependencies": ["docs_001"],
                "estimated_duration": "25m",
                "inputs": ["technical_docs"],
                "outputs": ["user_docs"]
            }
        ]
    }'
}

# Function to generate execution order
generate_execution_order() {
    local task_plan="$1"
    
    # Extract all tasks and build dependency graph
    local all_tasks
    all_tasks=$(echo "$task_plan" | jq '[.phases[].tasks[]] | sort_by(.task_id)')
    
    # Simple topological sort - in practice, this would be more sophisticated
    local execution_order='[]'
    
    # Add tasks in dependency order
    local phases=("planning" "architecture" "implementation" "testing" "deployment" "documentation")
    for phase in "${phases[@]}"; do
        local phase_tasks
        phase_tasks=$(echo "$task_plan" | jq -r ".phases.$phase.tasks[]?.task_id // empty")
        while IFS= read -r task_id; do
            if [[ -n "$task_id" ]]; then
                execution_order=$(echo "$execution_order" | jq ". + [\"$task_id\"]")
            fi
        done <<< "$phase_tasks"
    done
    
    echo "$task_plan" | jq ".execution_order = $execution_order"
}

# Function to assign agents to tasks
assign_agents_to_tasks() {
    local task_plan="$1"
    local agents_config="$2"
    
    # Read available agents and their capabilities
    local available_agents
    available_agents=$(cat "$agents_config" | jq '.agents')
    
    # Create agent assignment mapping
    local assignments='{}'
    
    # Get all agent types needed
    local agent_types
    agent_types=$(echo "$task_plan" | jq -r '[.phases[].tasks[].agent_type] | unique | .[]')
    
    while IFS= read -r agent_type; do
        if [[ -n "$agent_type" ]]; then
            # Find best matching agent
            local best_agent
            best_agent=$(find_best_agent_for_type "$agent_type" "$available_agents")
            assignments=$(echo "$assignments" | jq ". + {\"$agent_type\": \"$best_agent\"}")
        fi
    done <<< "$agent_types"
    
    echo "$task_plan" | jq ".agent_assignments = $assignments"
}

# Function to find best agent for type
find_best_agent_for_type() {
    local agent_type="$1"
    local available_agents="$2"
    
    # Agent type mapping
    case "$agent_type" in
        "analyst"|"planner") echo "architect" ;;
        "architect") echo "architect" ;;
        "developer") echo "developer" ;;
        "tester") echo "tester" ;;
        "devops") echo "developer" ;;  # Fallback to developer if no devops agent
        "documenter") echo "documenter" ;;
        *) echo "developer" ;;  # Default fallback
    esac
}

# Main execution
main() {
    if [[ -z "${REQUIREMENTS_FILE:-}" || ! -f "$REQUIREMENTS_FILE" ]]; then
        echo "[$AGENT_ID] ERROR: Requirements file not provided or not found"
        exit 1
    fi
    
    if [[ -z "${AGENTS_CONFIG:-}" || ! -f "$AGENTS_CONFIG" ]]; then
        echo "[$AGENT_ID] ERROR: Agents config file not provided or not found"
        exit 1
    fi
    
    # Step 1: Analyze requirements
    local analysis_file
    analysis_file=$(analyze_requirements "$REQUIREMENTS_FILE")
    
    # Step 2: Create dynamic task plan
    local task_plan_file
    task_plan_file=$(create_dynamic_task_plan "$analysis_file" "$AGENTS_CONFIG")
    
    # Step 3: Create execution summary
    local total_tasks
    total_tasks=$(jq '[.phases[].tasks[]] | length' "$task_plan_file" 2>/dev/null || echo "15")
    
    cat > "$ARTIFACTS_DIR/planning_summary.json" << EOF
{
    "planner_agent": "$AGENT_ID",
    "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "analysis_file": "$analysis_file",
    "task_plan_file": "$task_plan_file",
    "status": "completed",
    "total_tasks_planned": $total_tasks
}
EOF
    
    echo "[$AGENT_ID] Intelligent planning completed successfully"
    echo "[$AGENT_ID] Analysis: $analysis_file"
    echo "[$AGENT_ID] Task Plan: $task_plan_file"
}

# Execute main function
main