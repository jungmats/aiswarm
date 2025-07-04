#!/bin/bash

# Agent Execution System - Manages agent swarm execution

source "${SCRIPT_DIR}/lib/logger.sh"

# Global variables for execution state
AGENTS_CONFIG=""
TASK_QUEUE_FILE="${SESSION_WORKSPACE}/task_queue.json"
EXECUTION_STATE_FILE="${SESSION_WORKSPACE}/execution_state.json"

# Initialize agent execution system
execute_swarm() {
    local agents_config="$1"
    AGENTS_CONFIG="$agents_config"
    
    log_info "EXECUTOR" "Initializing agent swarm execution"
    
    # Initialize execution state
    init_execution_state
    
    # Load task plan and create execution queue
    create_task_queue
    
    # Execute tasks in dependency order
    execute_task_queue
    
    # Generate final summary
    generate_execution_summary
}

# Initialize execution state tracking
init_execution_state() {
    log_info "EXECUTOR" "Initializing execution state"
    
    cat > "$EXECUTION_STATE_FILE" << EOF
{
  "session_id": "$SESSION_ID",
  "started_at": "$(date -Iseconds)",
  "status": "running",
  "completed_tasks": [],
  "failed_tasks": [],
  "active_agents": {},
  "artifacts": {}
}
EOF
}

# Create task execution queue based on dependencies
create_task_queue() {
    log_info "EXECUTOR" "Creating task execution queue"
    
    # Read task plan and create executable queue
    local execution_order
    execution_order=$(jq -r '.execution_order[]' "$TASK_PLAN_FILE")
    
    # Initialize empty queue
    echo '{"queue": [], "completed": [], "failed": []}' > "$TASK_QUEUE_FILE"
    
    # Add tasks to queue in execution order
    while IFS= read -r task_id; do
        local task_data
        task_data=$(jq --arg tid "$task_id" '
            .phases | to_entries[] | .value.tasks[] | select(.task_id == $tid)
        ' "$TASK_PLAN_FILE")
        
        # Add task to queue
        jq --argjson task "$task_data" '.queue += [$task]' "$TASK_QUEUE_FILE" > "${TASK_QUEUE_FILE}.tmp"
        mv "${TASK_QUEUE_FILE}.tmp" "$TASK_QUEUE_FILE"
        
    done <<< "$execution_order"
    
    local queue_size
    queue_size=$(jq '.queue | length' "$TASK_QUEUE_FILE")
    log_info "EXECUTOR" "Task queue created with $queue_size tasks"
}

# Execute all tasks in the queue
execute_task_queue() {
    log_info "EXECUTOR" "Starting task queue execution"
    
    local total_tasks
    total_tasks=$(jq '.queue | length' "$TASK_QUEUE_FILE")
    local current_task=1
    
    # Process each task in the queue
    while [[ $(jq '.queue | length' "$TASK_QUEUE_FILE") -gt 0 ]]; do
        # Get next executable task (dependencies satisfied)
        local next_task
        next_task=$(get_next_executable_task)
        
        if [[ "$next_task" == "null" ]]; then
            log_error "EXECUTOR" "No executable tasks found - possible dependency deadlock"
            break
        fi
        
        echo -e "${BLUE}[$current_task/$total_tasks]${NC} Executing task..."
        
        # Execute the task
        execute_single_task "$next_task"
        
        ((current_task++))
    done
    
    log_info "EXECUTOR" "Task queue execution completed"
}

# Get next task that can be executed (dependencies satisfied)
get_next_executable_task() {
    local completed_tasks
    completed_tasks=$(jq -r '.completed[]' "$TASK_QUEUE_FILE" 2>/dev/null || echo "")
    
    # Find first task where all dependencies are completed
    local next_task
    next_task=$(jq -r --argjson completed "$(jq '.completed' "$TASK_QUEUE_FILE")" '
        .queue[] | select(
            (.dependencies | length == 0) or 
            (.dependencies | all(. as $dep | $completed | index($dep)))
        ) | .task_id
    ' "$TASK_QUEUE_FILE" | head -1)
    
    if [[ "$next_task" == "null" || -z "$next_task" ]]; then
        echo "null"
    else
        echo "$next_task"
    fi
}

# Execute a single task
execute_single_task() {
    local task_id="$1"
    
    # Get task details
    local task_data
    task_data=$(jq --arg tid "$task_id" '.queue[] | select(.task_id == $tid)' "$TASK_QUEUE_FILE")
    
    local agent_type title description inputs outputs
    agent_type=$(echo "$task_data" | jq -r '.agent_type')
    title=$(echo "$task_data" | jq -r '.title')
    description=$(echo "$task_data" | jq -r '.description')
    inputs=$(echo "$task_data" | jq -r '.inputs | join(", ")')
    outputs=$(echo "$task_data" | jq -r '.outputs | join(", ")')
    
    log_task "$task_id" "STARTED" "$agent_type" "$title"
    local start_time
    start_time=$(date +%s)
    
    # Create agent instance and execute task
    local agent_id="${agent_type}_$(date +%s%3N)"
    
    log_agent "$agent_id" "INFO" "Starting task: $task_id - $title"
    
    # Execute the agent for this task
    local execution_result
    if execute_agent "$agent_id" "$agent_type" "$task_id" "$description" "$inputs" "$outputs"; then
        execution_result="SUCCESS"
    else
        execution_result="FAILED"
    fi
    
    local end_time duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    if [[ "$execution_result" == "SUCCESS" ]]; then
        # Task completed successfully
        log_task "$task_id" "COMPLETED" "$agent_id" "Duration: ${duration}s"
        log_agent_execution "$agent_id" "$task_id" "$inputs" "$outputs" "${duration}s" "SUCCESS"
        
        # Move task from queue to completed
        mark_task_completed "$task_id"
        
        # Store artifacts
        store_task_artifacts "$task_id" "$outputs" "$execution_result"
        
    else
        # Task failed
        log_task "$task_id" "FAILED" "$agent_id" "Duration: ${duration}s"
        log_agent_execution "$agent_id" "$task_id" "$inputs" "$outputs" "${duration}s" "FAILED"
        
        # Move task to failed list
        mark_task_failed "$task_id"
    fi
}

# Execute specific agent type using unified agent executor
execute_agent() {
    local agent_id="$1"
    local agent_type="$2"
    local task_id="$3"
    local description="$4"
    local inputs="$5"
    local outputs="$6"
    
    # Create agent workspace
    local agent_workspace="${SESSION_WORKSPACE}/agents/${agent_id}"
    mkdir -p "$agent_workspace"
    
    # Create task context file for agent
    cat > "${agent_workspace}/task_context.json" << EOF
{
  "agent_id": "$agent_id",
  "agent_type": "$agent_type",
  "task_id": "$task_id",
  "description": "$description",
  "inputs": "$inputs",
  "outputs": "$outputs",
  "workspace": "$agent_workspace",
  "session_artifacts": "${SESSION_WORKSPACE}/artifacts"
}
EOF
    
    # Execute unified agent executor
    log_agent "$agent_id" "INFO" "Executing unified agent executor for $agent_type task"
    
    if [[ -f "${AGENTS_DIR}/agent_executor.sh" ]]; then
        bash "${AGENTS_DIR}/agent_executor.sh" "$agent_workspace/task_context.json" > "$agent_workspace/output.log" 2>&1
        return $?
    else
        log_error "$agent_id" "Unified agent executor not found: ${AGENTS_DIR}/agent_executor.sh"
        # Fallback to legacy execution if needed
        execute_legacy_agent "$agent_id" "$agent_type" "$agent_workspace"
        return $?
    fi
}

# Legacy fallback agent execution (when unified executor is not available)
execute_legacy_agent() {
    local agent_id="$1"
    local agent_type="$2"
    local workspace="$3"
    
    log_agent "$agent_id" "WARN" "Using legacy fallback for $agent_type agent"
    
    # Create basic output based on agent type
    mkdir -p "${SESSION_WORKSPACE}/artifacts"
    
    local task_context
    task_context=$(cat "$workspace/task_context.json")
    local task_id description
    task_id=$(echo "$task_context" | jq -r '.task_id')
    description=$(echo "$task_context" | jq -r '.description')
    
    case "$agent_type" in
        "architect")
            create_basic_architecture_output "$agent_id" "$task_id" "$description"
            ;;
        "developer") 
            create_basic_development_output "$agent_id" "$task_id" "$description"
            ;;
        "tester")
            create_basic_testing_output "$agent_id" "$task_id" "$description"
            ;;
        "documenter")
            create_basic_documentation_output "$agent_id" "$task_id" "$description"
            ;;
        *)
            create_basic_generic_output "$agent_id" "$task_id" "$description" "$agent_type"
            ;;
    esac
    
    log_agent "$agent_id" "INFO" "Legacy fallback output created for $task_id"
}

# Basic output creators for legacy fallback
create_basic_architecture_output() {
    local agent_id="$1"
    local task_id="$2"
    local description="$3"
    
    cat > "${SESSION_WORKSPACE}/artifacts/${task_id}_architecture.md" << EOF
# Architecture Output - $task_id

**Agent:** $agent_id  
**Task:** $description
**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## System Architecture
Basic system architecture decisions and patterns.

## Technology Stack
- Backend: Node.js/Express
- Frontend: React
- Database: PostgreSQL
- Cache: Redis

## API Design
RESTful API with standard endpoints.
EOF
}

create_basic_development_output() {
    local agent_id="$1"
    local task_id="$2" 
    local description="$3"
    
    cat > "${SESSION_WORKSPACE}/artifacts/${task_id}_implementation.md" << EOF
# Implementation Output - $task_id

**Agent:** $agent_id
**Task:** $description  
**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Code Implementation
Basic code structure and implementation approach.

## Project Structure
Standard project layout with src/, tests/, and config/ directories.

## Dependencies
Package dependencies and build configuration.
EOF
}

create_basic_testing_output() {
    local agent_id="$1"
    local task_id="$2"
    local description="$3"
    
    cat > "${SESSION_WORKSPACE}/artifacts/${task_id}_tests.md" << EOF
# Testing Output - $task_id

**Agent:** $agent_id
**Task:** $description
**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Test Strategy
Unit tests, integration tests, and end-to-end testing approach.

## Test Framework
Jest for unit testing, Cypress for E2E testing.

## Coverage Goals
Target 80% code coverage across all modules.
EOF
}

create_basic_documentation_output() {
    local agent_id="$1"
    local task_id="$2"
    local description="$3"
    
    cat > "${SESSION_WORKSPACE}/artifacts/${task_id}_documentation.md" << EOF
# Documentation Output - $task_id

**Agent:** $agent_id
**Task:** $description
**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Technical Documentation
API documentation, deployment guides, and technical specifications.

## User Documentation
User guides and how-to documentation.

## Deployment Guide
Instructions for deployment and configuration.
EOF
}

create_basic_generic_output() {
    local agent_id="$1"
    local task_id="$2"
    local description="$3"
    local agent_type="$4"
    
    cat > "${SESSION_WORKSPACE}/artifacts/${task_id}_${agent_type}.md" << EOF
# $agent_type Output - $task_id

**Agent:** $agent_id
**Task:** $description
**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Output
Basic $agent_type task output and results.
EOF
}

# Mark task as completed
mark_task_completed() {
    local task_id="$1"
    
    # Move from queue to completed
    jq --arg tid "$task_id" '
        .completed += [$tid] | 
        .queue = (.queue | map(select(.task_id != $tid)))
    ' "$TASK_QUEUE_FILE" > "${TASK_QUEUE_FILE}.tmp"
    mv "${TASK_QUEUE_FILE}.tmp" "$TASK_QUEUE_FILE"
}

# Mark task as failed
mark_task_failed() {
    local task_id="$1"
    
    # Move from queue to failed
    jq --arg tid "$task_id" '
        .failed += [$tid] | 
        .queue = (.queue | map(select(.task_id != $tid)))
    ' "$TASK_QUEUE_FILE" > "${TASK_QUEUE_FILE}.tmp"
    mv "${TASK_QUEUE_FILE}.tmp" "$TASK_QUEUE_FILE"
}

# Store task artifacts
store_task_artifacts() {
    local task_id="$1"
    local outputs="$2"
    local execution_result="$3"
    
    # Update execution state with artifacts
    jq --arg tid "$task_id" --arg outputs "$outputs" --arg result "$execution_result" '
        .artifacts[$tid] = {
            "outputs": $outputs,
            "result": $result,
            "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        }
    ' "$EXECUTION_STATE_FILE" > "${EXECUTION_STATE_FILE}.tmp"
    mv "${EXECUTION_STATE_FILE}.tmp" "$EXECUTION_STATE_FILE"
}

# Generate final execution summary
generate_execution_summary() {
    log_info "EXECUTOR" "Generating execution summary"
    
    local total_tasks completed_tasks failed_tasks
    total_tasks=$(jq '.phases | to_entries | map(.value.tasks | length) | add' "$TASK_PLAN_FILE")
    completed_tasks=$(jq '.completed | length' "$TASK_QUEUE_FILE")
    failed_tasks=$(jq '.failed | length' "$TASK_QUEUE_FILE")
    
    # Update final execution state
    jq --arg status "completed" --arg end_time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
        .status = $status | 
        .completed_at = $end_time
    ' "$EXECUTION_STATE_FILE" > "${EXECUTION_STATE_FILE}.tmp"
    mv "${EXECUTION_STATE_FILE}.tmp" "$EXECUTION_STATE_FILE"
    
    # Calculate total duration
    local start_time end_time duration
    start_time=$(jq -r '.metadata.created_at' "$TASK_PLAN_FILE" | date -d - +%s)
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    log_summary "$total_tasks" "$completed_tasks" "$failed_tasks" "${duration}s"
}