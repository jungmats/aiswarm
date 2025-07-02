#!/bin/bash

# Parallel Agent Execution System - Runs agents in background processes

source "${SCRIPT_DIR}/lib/logger.sh"

# Global variables for parallel execution
AGENTS_CONFIG=""
TASK_QUEUE_FILE="${WORK_DIR}/task_queue.json"
EXECUTION_STATE_FILE="${WORK_DIR}/execution_state.json"
ACTIVE_JOBS_FILE="${WORK_DIR}/active_jobs.json"
MAX_PARALLEL_AGENTS=3

# Initialize parallel execution system
execute_swarm_parallel() {
    local agents_config="$1"
    AGENTS_CONFIG="$agents_config"
    
    # Read max parallel agents from config
    MAX_PARALLEL_AGENTS=$(jq -r '.execution_settings.max_parallel_agents // 3' "$agents_config")
    
    log_info "PARALLEL_EXECUTOR" "Initializing parallel agent swarm execution (max: $MAX_PARALLEL_AGENTS agents)"
    
    # Initialize execution state
    init_execution_state
    
    # Load task plan and create execution queue
    create_task_queue
    
    # Initialize active jobs tracking
    echo '{"active_jobs": {}, "completed_pids": []}' > "$ACTIVE_JOBS_FILE"
    
    # Execute tasks with parallel processing
    execute_task_queue_parallel
    
    # Generate final summary
    generate_execution_summary
}

# Execute tasks with parallel processing
execute_task_queue_parallel() {
    log_info "PARALLEL_EXECUTOR" "Starting parallel task queue execution"
    
    local total_tasks
    total_tasks=$(jq '.queue | length' "$TASK_QUEUE_FILE")
    local completed_count=0
    
    while [[ $completed_count -lt $total_tasks ]]; do
        # Clean up completed jobs
        cleanup_completed_jobs
        
        # Get currently running job count
        local active_count
        active_count=$(jq '.active_jobs | length' "$ACTIVE_JOBS_FILE")
        
        # Start new jobs if we have capacity and available tasks
        while [[ $active_count -lt $MAX_PARALLEL_AGENTS ]]; do
            local next_task
            next_task=$(get_next_executable_task_parallel)
            
            if [[ "$next_task" == "null" ]]; then
                break  # No more executable tasks available
            fi
            
            # Start task in background
            start_background_task "$next_task"
            ((active_count++))
        done
        
        # Wait a bit before checking again
        sleep 1
        
        # Update completed count
        completed_count=$(jq '.completed | length' "$TASK_QUEUE_FILE")
        
        # Check for deadlock (no active jobs, no progress)
        active_count=$(jq '.active_jobs | length' "$ACTIVE_JOBS_FILE")
        if [[ $active_count -eq 0 && $completed_count -lt $total_tasks ]]; then
            local queue_size
            queue_size=$(jq '.queue | length' "$TASK_QUEUE_FILE")
            if [[ $queue_size -gt 0 ]]; then
                log_error "PARALLEL_EXECUTOR" "Deadlock detected: $queue_size tasks remaining but none executable"
                break
            fi
        fi
    done
    
    # Wait for all remaining jobs to complete
    wait_for_all_jobs
    
    log_info "PARALLEL_EXECUTOR" "Parallel task queue execution completed"
}

# Get next executable task that's not already running
get_next_executable_task_parallel() {
    local completed_tasks active_tasks
    completed_tasks=$(jq -r '.completed[]' "$TASK_QUEUE_FILE" 2>/dev/null || echo "")
    active_tasks=$(jq -r '.active_jobs | keys[]' "$ACTIVE_JOBS_FILE" 2>/dev/null || echo "")
    
    # Find first task where dependencies are met and not currently active
    local next_task
    next_task=$(jq -r --argjson completed "$(jq '.completed' "$TASK_QUEUE_FILE")" \
                    --argjson active "$(jq '.active_jobs | keys' "$ACTIVE_JOBS_FILE")" '
        .queue[] | select(
            (.dependencies | length == 0) or 
            (.dependencies | all(. as $dep | $completed | index($dep)))
        ) | select(.task_id as $tid | $active | index($tid) | not) | .task_id
    ' "$TASK_QUEUE_FILE" | head -1)
    
    if [[ "$next_task" == "null" || -z "$next_task" ]]; then
        echo "null"
    else
        echo "$next_task"
    fi
}

# Start a task in background process
start_background_task() {
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
    
    # Create agent instance ID
    local agent_id="${agent_type}_$(date +%s%3N)_$$"
    
    log_agent "$agent_id" "INFO" "Starting parallel task: $task_id - $title"
    
    # Start background job
    (
        local start_time
        start_time=$(date +%s)
        
        # Execute the agent for this task
        if execute_agent "$agent_id" "$agent_type" "$task_id" "$description" "$inputs" "$outputs"; then
            execution_result="SUCCESS"
        else
            execution_result="FAILED"
        fi
        
        local end_time duration
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        # Write completion status to a file for the main process to pick up
        local job_result_file="${WORK_DIR}/job_${task_id}_$$.result"
        cat > "$job_result_file" << EOF
{
  "task_id": "$task_id",
  "agent_id": "$agent_id",
  "status": "$execution_result",
  "duration": $duration,
  "inputs": "$inputs",
  "outputs": "$outputs",
  "pid": $$
}
EOF
        
        if [[ "$execution_result" == "SUCCESS" ]]; then
            log_task "$task_id" "COMPLETED" "$agent_id" "Duration: ${duration}s"
            log_agent_execution "$agent_id" "$task_id" "$inputs" "$outputs" "${duration}s" "SUCCESS"
        else
            log_task "$task_id" "FAILED" "$agent_id" "Duration: ${duration}s"
            log_agent_execution "$agent_id" "$task_id" "$inputs" "$outputs" "${duration}s" "FAILED"
        fi
        
    ) &
    
    local job_pid=$!
    
    # Track the background job
    jq --arg task_id "$task_id" --arg pid "$job_pid" --arg agent_id "$agent_id" '
        .active_jobs[$task_id] = {
            "pid": ($pid | tonumber),
            "agent_id": $agent_id,
            "started_at": now
        }
    ' "$ACTIVE_JOBS_FILE" > "${ACTIVE_JOBS_FILE}.tmp"
    mv "${ACTIVE_JOBS_FILE}.tmp" "$ACTIVE_JOBS_FILE"
    
    echo -e "${BLUE}[PARALLEL]${NC} Started $task_id in background (PID: $job_pid)"
}

# Clean up completed background jobs
cleanup_completed_jobs() {
    # Check for completed job result files
    for result_file in "${WORK_DIR}"/job_*.result; do
        [[ -f "$result_file" ]] || continue
        
        local job_result
        job_result=$(cat "$result_file")
        local task_id status
        task_id=$(echo "$job_result" | jq -r '.task_id')
        status=$(echo "$job_result" | jq -r '.status')
        
        # Remove from active jobs
        jq --arg task_id "$task_id" 'del(.active_jobs[$task_id])' "$ACTIVE_JOBS_FILE" > "${ACTIVE_JOBS_FILE}.tmp"
        mv "${ACTIVE_JOBS_FILE}.tmp" "$ACTIVE_JOBS_FILE"
        
        # Update task queue
        if [[ "$status" == "SUCCESS" ]]; then
            mark_task_completed "$task_id"
            store_task_artifacts "$task_id" "$(echo "$job_result" | jq -r '.outputs')" "$status"
        else
            mark_task_failed "$task_id"
        fi
        
        # Clean up result file
        rm -f "$result_file"
        
        echo -e "${GREEN}[PARALLEL]${NC} Completed $task_id with status: $status"
    done
}

# Wait for all active jobs to complete
wait_for_all_jobs() {
    log_info "PARALLEL_EXECUTOR" "Waiting for all background jobs to complete..."
    
    while [[ $(jq '.active_jobs | length' "$ACTIVE_JOBS_FILE") -gt 0 ]]; do
        cleanup_completed_jobs
        sleep 1
    done
    
    log_info "PARALLEL_EXECUTOR" "All background jobs completed"
}

# Monitor parallel execution status
monitor_parallel_execution() {
    while true; do
        local active_count completed_count failed_count total_count
        active_count=$(jq '.active_jobs | length' "$ACTIVE_JOBS_FILE" 2>/dev/null || echo "0")
        completed_count=$(jq '.completed | length' "$TASK_QUEUE_FILE" 2>/dev/null || echo "0")
        failed_count=$(jq '.failed | length' "$TASK_QUEUE_FILE" 2>/dev/null || echo "0")
        total_count=$(jq '.phases | to_entries | map(.value.tasks | length) | add' "$TASK_PLAN_FILE" 2>/dev/null || echo "0")
        
        echo -e "${BLUE}[MONITOR]${NC} Active: $active_count | Completed: $completed_count | Failed: $failed_count | Total: $total_count"
        
        # Exit if all tasks are done
        if [[ $((completed_count + failed_count)) -eq $total_count ]]; then
            break
        fi
        
        sleep 5
    done
}

# Enhanced execute_agent function for parallel execution
execute_agent() {
    local agent_id="$1"
    local agent_type="$2"
    local task_id="$3"
    local description="$4"
    local inputs="$5"
    local outputs="$6"
    
    # Create agent workspace with PID for uniqueness
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
  "session_artifacts": "${WORK_DIR}/artifacts",
  "parallel_execution": true,
  "max_parallel": $MAX_PARALLEL_AGENTS
}
EOF
    
    # Execute agent based on type with proper error handling
    case "$agent_type" in
        "architect")
            bash "${AGENTS_DIR}/architect.sh" "$agent_workspace/task_context.json" > "$agent_workspace/output.log" 2>&1
            ;;
        "developer")
            bash "${AGENTS_DIR}/developer.sh" "$agent_workspace/task_context.json" > "$agent_workspace/output.log" 2>&1
            ;;
        "tester")
            bash "${AGENTS_DIR}/tester.sh" "$agent_workspace/task_context.json" > "$agent_workspace/output.log" 2>&1
            ;;
        "documenter")
            bash "${AGENTS_DIR}/documenter.sh" "$agent_workspace/task_context.json" > "$agent_workspace/output.log" 2>&1
            ;;
        *)
            echo "Unknown agent type: $agent_type" > "$agent_workspace/error.log"
            return 1
            ;;
    esac
}

# Display parallel execution statistics
show_parallel_stats() {
    echo -e "${YELLOW}=== Parallel Execution Statistics ===${NC}"
    echo "Max Parallel Agents: $MAX_PARALLEL_AGENTS"
    echo "Session Artifacts: $(find "${WORK_DIR}/artifacts" -type f | wc -l) files generated"
    echo "Agent Workspaces: $(find "${WORK_DIR}/agents" -type d -name "*_*" | wc -l) created"
    echo "Background Processes: Peak of $MAX_PARALLEL_AGENTS concurrent agents"
}