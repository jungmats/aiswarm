#!/bin/bash

# Parallel Agent Execution System - Runs agents in background processes

source "${SCRIPT_DIR}/lib/logger.sh"

# Global variables for parallel execution
TASK_QUEUE_FILE="${SESSION_WORKSPACE}/task_queue.json"
EXECUTION_STATE_FILE="${SESSION_WORKSPACE}/execution_state.json"
ACTIVE_JOBS_FILE="${SESSION_WORKSPACE}/active_jobs.json"
MAX_PARALLEL_AGENTS=3

# Initialize parallel execution system
execute_swarm_parallel() {
    local agents_config="$1"
    AGENTS_CONFIG="$agents_config"
    
    echo "DEBUG: execute_swarm_parallel started with config: $agents_config" >&2
    
    # Read max parallel agents from config
    MAX_PARALLEL_AGENTS=$(jq -r '.execution_settings.max_parallel_agents // 3' "$agents_config")
    echo "DEBUG: MAX_PARALLEL_AGENTS set to: $MAX_PARALLEL_AGENTS" >&2
    
    log_info "PARALLEL_EXECUTOR" "Initializing parallel agent swarm execution (max: $MAX_PARALLEL_AGENTS agents)"
    
    # Initialize execution state
    echo "DEBUG: Calling init_execution_state" >&2
    init_execution_state
    echo "DEBUG: init_execution_state completed" >&2
    
    # Load task plan and create execution queue
    echo "DEBUG: Calling create_task_queue" >&2
    create_task_queue
    echo "DEBUG: create_task_queue completed" >&2
    
    # Initialize active jobs tracking
    echo "DEBUG: Creating active jobs file: $ACTIVE_JOBS_FILE" >&2
    echo '{"active_jobs": {}, "completed_pids": []}' > "$ACTIVE_JOBS_FILE"
    echo "DEBUG: Active jobs file created" >&2
    
    # Execute tasks with parallel processing
    echo "DEBUG: Calling execute_task_queue_parallel" >&2
    execute_task_queue_parallel
    echo "DEBUG: execute_task_queue_parallel completed" >&2
    
    # Generate final summary
    echo "DEBUG: Calling generate_execution_summary" >&2
    generate_execution_summary
    echo "DEBUG: generate_execution_summary completed" >&2
}

# Initialize execution state
init_execution_state() {
    log_info "PARALLEL_EXECUTOR" "Initializing execution state"
    
    cat > "$EXECUTION_STATE_FILE" << EOF
{
  "execution_start": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "mode": "parallel",
  "max_parallel_agents": $MAX_PARALLEL_AGENTS,
  "agents_config": "$AGENTS_CONFIG",
  "task_plan": "${SESSION_WORKSPACE}/task_plan.json",
  "status": "running"
}
EOF
}

# Generate final execution summary
generate_execution_summary() {
    log_info "PARALLEL_EXECUTOR" "Generating execution summary"
    
    local total_tasks completed_tasks failed_tasks
    if ! total_tasks=$(jq '.queue | length' "$TASK_QUEUE_FILE" 2>/dev/null); then
        echo "ERROR: Failed to get total tasks from: $TASK_QUEUE_FILE" >&2
        total_tasks="0"
    fi
    if ! completed_tasks=$(jq '.completed | length' "$TASK_QUEUE_FILE" 2>/dev/null); then
        echo "ERROR: Failed to get completed tasks from: $TASK_QUEUE_FILE" >&2
        completed_tasks="0"
    fi
    if ! failed_tasks=$(jq '.failed | length' "$TASK_QUEUE_FILE" 2>/dev/null); then
        echo "ERROR: Failed to get failed tasks from: $TASK_QUEUE_FILE" >&2
        failed_tasks="0"
    fi
    
    # Update execution state
    jq --arg end_time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       --arg status "completed" \
       --argjson total $total_tasks \
       --argjson completed $completed_tasks \
       --argjson failed $failed_tasks \
       '. + {
         "execution_end": $end_time,
         "status": $status,
         "summary": {
           "total_tasks": $total,
           "completed_tasks": $completed,
           "failed_tasks": $failed,
           "success_rate": (($completed * 100) / ($total == 0 and 1 or $total))
         }
       }' "$EXECUTION_STATE_FILE" > "${EXECUTION_STATE_FILE}.tmp"
    mv "${EXECUTION_STATE_FILE}.tmp" "$EXECUTION_STATE_FILE"
}

# Create task execution queue
create_task_queue() {
    log_info "PARALLEL_EXECUTOR" "Creating task execution queue"
    echo "DEBUG: create_task_queue - SESSION_WORKSPACE=$SESSION_WORKSPACE" >&2
    echo "DEBUG: create_task_queue - TASK_QUEUE_FILE=$TASK_QUEUE_FILE" >&2
    
    # Check if task plan exists
    if [[ ! -f "${SESSION_WORKSPACE}/task_plan.json" ]]; then
        log_error "PARALLEL_EXECUTOR" "Task plan file not found: ${SESSION_WORKSPACE}/task_plan.json"
        exit 1
    fi
    echo "DEBUG: Task plan file exists" >&2
    
    # Read task plan and create executable queue
    local execution_order
    execution_order=$(jq -r '.execution_order[]' "${SESSION_WORKSPACE}/task_plan.json" 2>/dev/null)
    
    if [[ -z "$execution_order" ]]; then
        log_error "PARALLEL_EXECUTOR" "No execution order found in task plan"
        exit 1
    fi
    
    log_info "PARALLEL_EXECUTOR" "Found execution order with $(echo "$execution_order" | wc -l) tasks"
    
    # Initialize empty queue
    echo '{"queue": [], "completed": [], "failed": []}' > "$TASK_QUEUE_FILE"
    
    # Add tasks to queue in execution order
    while IFS= read -r task_id; do
        [[ -n "$task_id" ]] || continue
        
        log_info "PARALLEL_EXECUTOR" "Processing task: $task_id"
        
        local task_data
        task_data=$(jq --arg tid "$task_id" '
            .phases | to_entries[] | .value.tasks[] | select(.task_id == $tid)
        ' "${SESSION_WORKSPACE}/task_plan.json" 2>/dev/null)
        
        if [[ -z "$task_data" || "$task_data" == "null" ]]; then
            log_warn "PARALLEL_EXECUTOR" "No task data found for task: $task_id"
            continue
        fi
        
        # Add task to queue
        jq --argjson task "$task_data" '.queue += [$task]' "$TASK_QUEUE_FILE" > "${TASK_QUEUE_FILE}.tmp" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${TASK_QUEUE_FILE}.tmp" "$TASK_QUEUE_FILE"
        else
            log_error "PARALLEL_EXECUTOR" "Failed to add task $task_id to queue"
            rm -f "${TASK_QUEUE_FILE}.tmp"
        fi
        
    done <<< "$execution_order"
    
    local queue_size
    queue_size=$(jq '.queue | length' "$TASK_QUEUE_FILE")
    log_info "PARALLEL_EXECUTOR" "Task queue created with $queue_size tasks"
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
        if ! active_count=$(jq '.active_jobs | length' "$ACTIVE_JOBS_FILE" 2>/dev/null); then
            echo "ERROR: Failed to get active job count from: $ACTIVE_JOBS_FILE" >&2
            active_count="0"
        fi
        
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
        if ! completed_count=$(jq '.completed | length' "$TASK_QUEUE_FILE" 2>/dev/null); then
            echo "ERROR: Failed to get completed count from: $TASK_QUEUE_FILE" >&2
            completed_count="0"
        fi
        
        # Check for deadlock (no active jobs, no progress)
        if ! active_count=$(jq '.active_jobs | length' "$ACTIVE_JOBS_FILE" 2>/dev/null); then
            echo "ERROR: Failed to get active count for deadlock check from: $ACTIVE_JOBS_FILE" >&2
            active_count="0"
        fi
        if [[ $active_count -eq 0 && $completed_count -lt $total_tasks ]]; then
            local queue_size
            if ! queue_size=$(jq '.queue | length' "$TASK_QUEUE_FILE" 2>/dev/null); then
                echo "ERROR: Failed to get queue size for deadlock check from: $TASK_QUEUE_FILE" >&2
                queue_size="0"
            fi
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
    # Debug: Show file paths being accessed
    echo "DEBUG: Checking files - TASK_QUEUE_FILE=$TASK_QUEUE_FILE, ACTIVE_JOBS_FILE=$ACTIVE_JOBS_FILE" >&2
    
    # Check if required files exist
    if [[ ! -f "$TASK_QUEUE_FILE" ]]; then
        echo "ERROR: TASK_QUEUE_FILE does not exist: $TASK_QUEUE_FILE" >&2
        echo "null"
        return
    fi
    
    if [[ ! -f "$ACTIVE_JOBS_FILE" ]]; then
        echo "ERROR: ACTIVE_JOBS_FILE does not exist: $ACTIVE_JOBS_FILE" >&2
        echo "null"
        return
    fi
    
    # Safely get completed and active task lists with detailed error logging
    local completed_json active_json
    if ! completed_json=$(jq '.completed // []' "$TASK_QUEUE_FILE" 2>/dev/null); then
        echo "ERROR: Failed to read completed tasks from: $TASK_QUEUE_FILE" >&2
        completed_json='[]'
    fi
    
    if ! active_json=$(jq '.active_jobs // {} | keys' "$ACTIVE_JOBS_FILE" 2>/dev/null); then
        echo "ERROR: Failed to read active jobs from: $ACTIVE_JOBS_FILE" >&2
        active_json='[]'
    fi
    
    # Find first task where dependencies are met and not currently active
    local next_task
    if ! next_task=$(jq -r --argjson completed "$completed_json" \
                    --argjson active "$active_json" '
        .queue[]? | select(
            (.dependencies // [] | length == 0) or 
            (.dependencies // [] | all(. as $dep | $completed | index($dep)))
        ) | select(.task_id as $tid | $active | index($tid) | not) | .task_id
    ' "$TASK_QUEUE_FILE" 2>/dev/null | head -1); then
        echo "ERROR: Failed to query next task from: $TASK_QUEUE_FILE" >&2
        echo "ERROR: Completed JSON: $completed_json" >&2
        echo "ERROR: Active JSON: $active_json" >&2
        next_task=""
    fi
    
    if [[ "$next_task" == "null" || -z "$next_task" ]]; then
        echo "null"
    else
        echo "$next_task"
    fi
}

# Start a task in background process
start_background_task() {
    local task_id="$1"
    
    # Get task details with error logging
    local task_data
    if ! task_data=$(jq --arg tid "$task_id" '.queue[] | select(.task_id == $tid)' "$TASK_QUEUE_FILE" 2>/dev/null); then
        echo "ERROR: Failed to get task data for $task_id from: $TASK_QUEUE_FILE" >&2
        return 1
    fi
    
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
        local job_result_file="${SESSION_WORKSPACE}/job_${task_id}_$$.result"
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
    for result_file in "${SESSION_WORKSPACE}"/job_*.result; do
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
    
    # Create a simple artifact record
    echo "Task $task_id completed with status: $execution_result" > "${SESSION_WORKSPACE}/artifacts/${task_id}_result.txt"
}

# Monitor parallel execution status
monitor_parallel_execution() {
    echo "[MONITOR] Waiting for execution files to be created..." >&2
    
    # Wait for required files to exist before monitoring
    local timeout=60
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if [[ -f "$TASK_QUEUE_FILE" && -f "$ACTIVE_JOBS_FILE" && -f "$TASK_PLAN_FILE" ]]; then
            echo "[MONITOR] Execution files found, starting monitoring..." >&2
            break
        fi
        sleep 1
        ((elapsed++))
    done
    
    if [[ $elapsed -ge $timeout ]]; then
        echo "[MONITOR] Timeout waiting for execution files, starting monitoring anyway..." >&2
    fi
    
    while true; do
        local active_count completed_count failed_count total_count
        if ! active_count=$(jq '.active_jobs | length' "$ACTIVE_JOBS_FILE" 2>/dev/null); then
            active_count="0"
        fi
        if ! completed_count=$(jq '.completed | length' "$TASK_QUEUE_FILE" 2>/dev/null); then
            completed_count="0"
        fi
        if ! failed_count=$(jq '.failed | length' "$TASK_QUEUE_FILE" 2>/dev/null); then
            failed_count="0"
        fi
        if ! total_count=$(jq '.phases | to_entries | map(.value.tasks | length) | add' "$TASK_PLAN_FILE" 2>/dev/null); then
            total_count="0"
        fi
        
        echo -e "${BLUE}[MONITOR]${NC} Active: $active_count | Completed: $completed_count | Failed: $failed_count | Total: $total_count"
        
        # Exit if all tasks are done
        if [[ $((completed_count + failed_count)) -eq $total_count && $total_count -gt 0 ]]; then
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
  "session_artifacts": "${SESSION_WORKSPACE}/artifacts",
  "parallel_execution": true,
  "max_parallel": $MAX_PARALLEL_AGENTS
}
EOF
    
    # Execute unified agent executor
    echo "DEBUG: Executing unified agent executor for $agent_type" >&2
    
    if [[ -f "${AGENTS_DIR}/agent_executor.sh" ]]; then
        bash "${AGENTS_DIR}/agent_executor.sh" "$agent_workspace/task_context.json" > "$agent_workspace/output.log" 2>&1
        local exit_code=$?
        echo "DEBUG: Agent executor finished with exit code: $exit_code" >&2
        return $exit_code
    else
        echo "ERROR: Unified agent executor not found: ${AGENTS_DIR}/agent_executor.sh" > "$agent_workspace/error.log"
        echo "DEBUG: Agent executor file not found" >&2
        return 1
    fi
}

# Display parallel execution statistics
show_parallel_stats() {
    echo -e "${YELLOW}=== Parallel Execution Statistics ===${NC}"
    echo "Max Parallel Agents: $MAX_PARALLEL_AGENTS"
    echo "Session Artifacts: $(find "${SESSION_WORKSPACE}/artifacts" -type f | wc -l) files generated"
    echo "Agent Workspaces: $(find "${SESSION_WORKSPACE}/agents" -type d -name "*_*" | wc -l) created"
    echo "Background Processes: Peak of $MAX_PARALLEL_AGENTS concurrent agents"
}