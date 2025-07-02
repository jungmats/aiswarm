#!/bin/bash

# Agent Execution System - Manages agent swarm execution

source "${SCRIPT_DIR}/lib/logger.sh"

# Global variables for execution state
AGENTS_CONFIG=""
TASK_QUEUE_FILE="${WORK_DIR}/task_queue.json"
EXECUTION_STATE_FILE="${WORK_DIR}/execution_state.json"

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

# Execute specific agent type
execute_agent() {
    local agent_id="$1"
    local agent_type="$2"
    local task_id="$3"
    local description="$4"
    local inputs="$5"
    local outputs="$6"
    
    # Create agent workspace
    local agent_workspace="${WORK_DIR}/agents/${agent_id}"
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
  "session_artifacts": "${WORK_DIR}/artifacts"
}
EOF
    
    # Execute agent based on type
    case "$agent_type" in
        "architect")
            execute_architect_agent "$agent_id" "$agent_workspace"
            ;;
        "developer")
            execute_developer_agent "$agent_id" "$agent_workspace"
            ;;
        "tester")
            execute_tester_agent "$agent_id" "$agent_workspace"
            ;;
        "documenter")
            execute_documenter_agent "$agent_id" "$agent_workspace"
            ;;
        *)
            log_error "$agent_id" "Unknown agent type: $agent_type"
            return 1
            ;;
    esac
}

# Execute architect agent
execute_architect_agent() {
    local agent_id="$1"
    local workspace="$2"
    
    log_agent "$agent_id" "INFO" "Executing architect agent"
    
    # Run architect agent script
    if [[ -f "${AGENTS_DIR}/architect.sh" ]]; then
        bash "${AGENTS_DIR}/architect.sh" "$workspace/task_context.json" > "$workspace/output.log" 2>&1
    else
        # Fallback: create basic architectural output
        create_architecture_output "$agent_id" "$workspace"
    fi
}

# Execute developer agent  
execute_developer_agent() {
    local agent_id="$1"
    local workspace="$2"
    
    log_agent "$agent_id" "INFO" "Executing developer agent"
    
    if [[ -f "${AGENTS_DIR}/developer.sh" ]]; then
        bash "${AGENTS_DIR}/developer.sh" "$workspace/task_context.json" > "$workspace/output.log" 2>&1
    else
        create_development_output "$agent_id" "$workspace"
    fi
}

# Execute tester agent
execute_tester_agent() {
    local agent_id="$1"
    local workspace="$2"
    
    log_agent "$agent_id" "INFO" "Executing tester agent"
    
    if [[ -f "${AGENTS_DIR}/tester.sh" ]]; then
        bash "${AGENTS_DIR}/tester.sh" "$workspace/task_context.json" > "$workspace/output.log" 2>&1
    else
        create_testing_output "$agent_id" "$workspace"
    fi
}

# Execute documenter agent
execute_documenter_agent() {
    local agent_id="$1"
    local workspace="$2"
    
    log_agent "$agent_id" "INFO" "Executing documenter agent"
    
    if [[ -f "${AGENTS_DIR}/documenter.sh" ]]; then
        bash "${AGENTS_DIR}/documenter.sh" "$workspace/task_context.json" > "$workspace/output.log" 2>&1
    else
        create_documentation_output "$agent_id" "$workspace"
    fi
}

# Fallback output creators (when agent scripts don't exist)
create_architecture_output() {
    local agent_id="$1"
    local workspace="$2"
    
    mkdir -p "${WORK_DIR}/artifacts"
    
    local task_context
    task_context=$(cat "$workspace/task_context.json")
    local task_id description
    task_id=$(echo "$task_context" | jq -r '.task_id')
    description=$(echo "$task_context" | jq -r '.description')
    
    cat > "${WORK_DIR}/artifacts/${task_id}_output.md" << EOF
# Architecture Output - $task_id

**Agent:** $agent_id
**Task:** $description
**Generated:** $(date -Iseconds)

## Architecture Decisions

[Generated architecture content would go here]

## Technical Stack

[Technology decisions would be documented here]

## System Design

[High-level system design would be described here]
EOF
    
    log_agent "$agent_id" "INFO" "Created architecture output: ${task_id}_output.md"
}

create_development_output() {
    local agent_id="$1"
    local workspace="$2"
    
    mkdir -p "${WORK_DIR}/artifacts/code"
    
    local task_context
    task_context=$(cat "$workspace/task_context.json")
    local task_id description
    task_id=$(echo "$task_context" | jq -r '.task_id')
    description=$(echo "$task_context" | jq -r '.description')
    
    cat > "${WORK_DIR}/artifacts/code/${task_id}_implementation.md" << EOF
# Implementation - $task_id

**Agent:** $agent_id
**Task:** $description
**Generated:** $(date -Iseconds)

## Code Implementation

[Generated code would go here]

## Dependencies

[Required dependencies would be listed here]

## Notes

[Implementation notes and considerations]
EOF
    
    log_agent "$agent_id" "INFO" "Created development output: code/${task_id}_implementation.md"
}

create_testing_output() {
    local agent_id="$1"
    local workspace="$2"
    
    mkdir -p "${WORK_DIR}/artifacts/tests"
    
    local task_context
    task_context=$(cat "$workspace/task_context.json")
    local task_id description
    task_id=$(echo "$task_context" | jq -r '.task_id')
    description=$(echo "$task_context" | jq -r '.description')
    
    cat > "${WORK_DIR}/artifacts/tests/${task_id}_tests.md" << EOF
# Test Implementation - $task_id

**Agent:** $agent_id
**Task:** $description
**Generated:** $(date -Iseconds)

## Test Cases

[Generated test cases would go here]

## Test Data

[Test data and fixtures]

## Coverage

[Coverage requirements and notes]
EOF
    
    log_agent "$agent_id" "INFO" "Created testing output: tests/${task_id}_tests.md"
}

create_documentation_output() {
    local agent_id="$1"
    local workspace="$2"
    
    mkdir -p "${WORK_DIR}/artifacts/docs"
    
    local task_context
    task_context=$(cat "$workspace/task_context.json")
    local task_id description
    task_id=$(echo "$task_context" | jq -r '.task_id')
    description=$(echo "$task_context" | jq -r '.description')
    
    cat > "${WORK_DIR}/artifacts/docs/${task_id}_documentation.md" << EOF
# Documentation - $task_id

**Agent:** $agent_id
**Task:** $description
**Generated:** $(date -Iseconds)

## Overview

[Documentation content would go here]

## Usage

[Usage instructions and examples]

## References

[Links and additional resources]
EOF
    
    log_agent "$agent_id" "INFO" "Created documentation output: docs/${task_id}_documentation.md"
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