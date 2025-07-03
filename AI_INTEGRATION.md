# AI Integration Guide

## 🧠 Current vs AI-Powered Implementation

### Current Implementation (Template-Based)
The framework currently uses **static templates** and predefined code structures. While it demonstrates the agent coordination and task planning concepts, it generates the same output regardless of specification details.

**Limitations:**
- Fixed code templates for all applications
- No adaptation to specification requirements
- Limited to predefined technology stacks
- Static architecture decisions

### AI-Powered Implementation (Recommended)
To unlock the full potential of intelligent agent swarms, integrate with Claude or other AI systems for dynamic code generation.

## 🔑 Prerequisites for AI Integration

### 1. Claude API Access
```bash
# Required: Anthropic Claude API key
export CLAUDE_API_KEY="your-anthropic-api-key"
export CLAUDE_API_URL="https://api.anthropic.com/v1/messages"
export CLAUDE_MODEL="claude-3-sonnet-20240229"
```

### 2. Additional Dependencies
```bash
# Install curl for API calls (usually pre-installed)
# On Ubuntu/Debian:
sudo apt install curl jq

# On macOS:
brew install curl jq

# For advanced features:
pip install anthropic  # Python SDK (optional)
npm install @anthropic-ai/sdk  # Node.js SDK (optional)
```

### 3. Network Requirements
- Internet connectivity for API calls
- Outbound HTTPS access to api.anthropic.com
- Sufficient API rate limits for your usage

## 🔧 Converting to AI-Powered Agents

### Enhanced Agent Architecture
```bash
# agents/ai_architect.sh - AI-powered architect agent
#!/bin/bash

source "${SCRIPT_DIR}/lib/ai_client.sh"

ai_architect_agent() {
    local task_context="$1"
    local specification="$2"
    
    # Create AI prompt for architecture decisions
    local prompt="
    You are a senior software architect. Analyze this specification and create:
    1. System architecture decisions
    2. Technology stack recommendations  
    3. Database schema design
    4. API specifications
    
    Specification: $specification
    Task: $task_context
    
    Output format: JSON with architecture decisions and rationale.
    "
    
    # Call Claude API for intelligent analysis
    local ai_response
    ai_response=$(call_claude_api "$prompt")
    
    # Parse and implement AI recommendations
    implement_architecture_decisions "$ai_response"
}
```

### AI Client Library
```bash
# lib/ai_client.sh - Claude API integration
#!/bin/bash

call_claude_api() {
    local prompt="$1"
    local max_tokens="${2:-4000}"
    
    curl -s -X POST "$CLAUDE_API_URL" \
        -H "Authorization: Bearer $CLAUDE_API_KEY" \
        -H "Content-Type: application/json" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"$CLAUDE_MODEL\",
            \"max_tokens\": $max_tokens,
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$prompt\"
            }]
        }" | jq -r '.content[0].text'
}

# Enhanced prompt engineering for different agent types
create_architect_prompt() {
    local specification="$1"
    cat << EOF
You are an expert software architect. Analyze the following application specification and provide:

1. **Technology Stack Recommendations**
   - Backend framework and language
   - Frontend framework  
   - Database selection
   - Caching strategy
   - Deployment approach

2. **System Architecture**
   - High-level component design
   - Data flow patterns
   - Integration points
   - Scalability considerations

3. **Database Schema**
   - Entity definitions
   - Relationships
   - Indexing strategy
   - Performance optimizations

Specification:
$specification

Provide your response as structured JSON with clear rationale for each decision.
EOF
}

create_developer_prompt() {
    local task_description="$1"
    local architecture_context="$2"
    cat << EOF
You are a senior full-stack developer. Based on the architecture decisions and task description, generate production-ready code:

Task: $task_description
Architecture Context: $architecture_context

Generate:
1. Complete, runnable code files
2. Proper error handling
3. Security best practices
4. Performance optimizations
5. Clear documentation

Output the code with file paths and complete implementations.
EOF
}
```

## 🚀 Quick AI Integration Setup

### 1. Get Claude API Access
```bash
# Sign up at: https://console.anthropic.com/
# Create API key
# Set environment variable
export CLAUDE_API_KEY="sk-ant-api03-..."
```

### 2. Test AI Connection
```bash
# Test script
cat > test_ai.sh << 'EOF'
#!/bin/bash
curl -X POST "https://api.anthropic.com/v1/messages" \
  -H "Authorization: Bearer $CLAUDE_API_KEY" \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-3-sonnet-20240229",
    "max_tokens": 100,
    "messages": [{"role": "user", "content": "Hello, Claude!"}]
  }'
EOF

chmod +x test_ai.sh
./test_ai.sh
```

### 3. Enhanced Agent Configuration
```json
{
  "agents": {
    "ai_architect": {
      "name": "AI-Powered Architect",
      "ai_enabled": true,
      "model": "claude-3-sonnet-20240229",
      "max_tokens": 4000,
      "capabilities": ["dynamic_architecture", "tech_stack_selection", "schema_generation"]
    },
    "ai_developer": {
      "name": "AI-Powered Developer", 
      "ai_enabled": true,
      "model": "claude-3-sonnet-20240229",
      "max_tokens": 8000,
      "capabilities": ["code_generation", "framework_adaptation", "security_implementation"]
    }
  },
  "ai_settings": {
    "api_timeout": 30,
    "retry_attempts": 3,
    "rate_limit_delay": 1000,
    "enable_streaming": false
  }
}
```

## 🎯 AI-Enhanced Agent Examples

### Intelligent Architecture Agent
```bash
# The AI architect analyzes specifications and makes intelligent decisions:
# - Chooses React vs Vue vs Angular based on team size and complexity
# - Selects PostgreSQL vs MongoDB based on data relationships  
# - Decides microservices vs monolith based on scale requirements
# - Generates custom database schemas optimized for use cases
```

### Adaptive Developer Agent  
```bash
# The AI developer generates code tailored to specifications:
# - Creates domain-specific models (e.g., "Recipe" for cooking app)
# - Implements business logic matching the use cases
# - Adapts to different frameworks based on architecture decisions
# - Generates appropriate validation rules and security measures
```

### Intelligent Tester Agent
```bash
# The AI tester creates comprehensive test suites:
# - Generates test cases based on specification use cases
# - Creates realistic test data for the domain
# - Implements edge case testing based on requirements
# - Adapts testing strategy to chosen tech stack
```

## 💡 Benefits of AI Integration

### Dynamic Adaptation
- **Custom code** for each specification
- **Intelligent tech stack** selection
- **Domain-specific implementations**
- **Adaptive architecture patterns**

### Higher Quality Output
- **Best practices** automatically applied
- **Security considerations** built-in
- **Performance optimizations** included
- **Comprehensive error handling**

### Broader Capability
- **Multiple programming languages**
- **Various frameworks and patterns**
- **Complex business logic**
- **Industry-specific solutions**

## 🔒 Security Considerations

### API Key Management
```bash
# Store securely
echo "CLAUDE_API_KEY=sk-ant-..." >> ~/.env
source ~/.env

# Never commit API keys to version control
echo "*.env" >> .gitignore
```

### Rate Limiting
```bash
# Implement rate limiting to avoid API limits
rate_limit_api_calls() {
    local last_call_file="/tmp/last_claude_call"
    local min_interval=1  # seconds between calls
    
    if [[ -f "$last_call_file" ]]; then
        local last_call=$(cat "$last_call_file")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_call))
        
        if [[ $time_diff -lt $min_interval ]]; then
            sleep $((min_interval - time_diff))
        fi
    fi
    
    date +%s > "$last_call_file"
}
```

### Input Sanitization
```bash
# Sanitize specification inputs before sending to AI
sanitize_input() {
    local input="$1"
    # Remove potential injection attempts
    echo "$input" | sed 's/[<>]//g' | head -c 10000
}
```

## 📊 Cost Considerations

### API Usage Estimation
```
Typical Agent Swarm Session (15 tasks):
- Architect: 3 tasks × 2,000 tokens = 6,000 tokens
- Developer: 5 tasks × 4,000 tokens = 20,000 tokens  
- Tester: 4 tasks × 3,000 tokens = 12,000 tokens
- Documenter: 3 tasks × 2,000 tokens = 6,000 tokens

Total: ~44,000 tokens per application
Cost: ~$0.50-$1.00 per generated application (Claude Sonnet pricing)
```

### Cost Optimization
```bash
# Use caching for repeated patterns
cache_ai_response() {
    local prompt_hash=$(echo "$1" | sha256sum | cut -d' ' -f1)
    local cache_file="/tmp/ai_cache_$prompt_hash"
    
    if [[ -f "$cache_file" ]] && [[ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt 3600 ]]; then
        cat "$cache_file"
    else
        local response=$(call_claude_api "$1")
        echo "$response" > "$cache_file"
        echo "$response"
    fi
}
```

## 🚀 Migration Path

### Phase 1: Hybrid Approach
- Keep existing template agents as fallback
- Add AI agents for specific tasks
- Compare outputs and quality

### Phase 2: Full AI Integration  
- Replace all template agents with AI-powered versions
- Implement sophisticated prompt engineering
- Add domain-specific knowledge

### Phase 3: Advanced Features
- Multi-model integration (Claude + Codex)
- Iterative code improvement
- Automated testing and validation

---

**Note:** The current framework provides the foundation for agent coordination and task management. Adding AI integration transforms it from a sophisticated template system into a truly intelligent software generation platform.