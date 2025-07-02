#!/bin/bash

# Logging System - Comprehensive tracking of agent activities

# Log levels
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3
LOG_LEVEL_DEBUG=4

# Current log level (can be overridden)
CURRENT_LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Color codes for console output
LOG_COLOR_INFO='\033[0;36m'    # Cyan
LOG_COLOR_WARN='\033[1;33m'    # Yellow
LOG_COLOR_ERROR='\033[0;31m'   # Red
LOG_COLOR_DEBUG='\033[0;35m'   # Magenta
LOG_COLOR_RESET='\033[0m'      # Reset

# Initialize logging system
init_logging() {
    local session_id="$1"
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    # Set global log files (should already be set by main script)
    MAIN_LOG="${MAIN_LOG:-${LOG_DIR}/${session_id}_main.log}"
    AGENT_LOG="${AGENT_LOG:-${LOG_DIR}/${session_id}_agents.log}"
    TASK_LOG="${TASK_LOG:-${LOG_DIR}/${session_id}_tasks.log}"
    
    # Initialize log files with headers
    cat > "$MAIN_LOG" << EOF
=== Agent Swarm System - Main Log ===
Session: $session_id
Started: $(date -Iseconds)
=====================================

EOF

    cat > "$AGENT_LOG" << EOF
=== Agent Swarm System - Agent Activity Log ===
Session: $session_id
Started: $(date -Iseconds)
Format: [TIMESTAMP] [AGENT_ID] [LEVEL] MESSAGE
============================================

EOF

    cat > "$TASK_LOG" << EOF
=== Agent Swarm System - Task Execution Log ===
Session: $session_id
Started: $(date -Iseconds)
Format: [TIMESTAMP] [TASK_ID] [STATUS] [AGENT] DETAILS
===================================================

EOF
}

# Generic logging function
_log() {
    local level="$1"
    local component="$2"
    local message="$3"
    local color="$4"
    local log_file="$5"
    
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    local log_entry="[$timestamp] [$component] [$level] $message"
    
    # Write to log file
    echo "$log_entry" >> "$log_file"
    
    # Also write to main log if not main log
    if [[ "$log_file" != "$MAIN_LOG" ]]; then
        echo "$log_entry" >> "$MAIN_LOG"
    fi
    
    # Console output with color
    if [[ -t 1 ]]; then  # Only colorize if outputting to terminal
        echo -e "${color}[$component]${LOG_COLOR_RESET} $message"
    else
        echo "[$component] $message"
    fi
}

# Info logging
log_info() {
    local component="$1"
    local message="$2"
    _log "INFO" "$component" "$message" "$LOG_COLOR_INFO" "$MAIN_LOG"
}

# Warning logging  
log_warn() {
    local component="$1"
    local message="$2"
    _log "WARN" "$component" "$message" "$LOG_COLOR_WARN" "$MAIN_LOG"
}

# Error logging
log_error() {
    local component="$1"
    local message="$2"
    _log "ERROR" "$component" "$message" "$LOG_COLOR_ERROR" "$MAIN_LOG"
}

# Debug logging
log_debug() {
    local component="$1"
    local message="$2"
    if [[ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_DEBUG ]]; then
        _log "DEBUG" "$component" "$message" "$LOG_COLOR_DEBUG" "$MAIN_LOG"
    fi
}

# Agent-specific logging
log_agent() {
    local agent_id="$1"
    local level="$2"
    local message="$3"
    
    local color="$LOG_COLOR_INFO"
    case "$level" in
        "WARN") color="$LOG_COLOR_WARN" ;;
        "ERROR") color="$LOG_COLOR_ERROR" ;;
        "DEBUG") color="$LOG_COLOR_DEBUG" ;;
    esac
    
    _log "$level" "$agent_id" "$message" "$color" "$AGENT_LOG"
}

# Task execution logging
log_task() {
    local task_id="$1"
    local status="$2" 
    local agent_id="$3"
    local details="$4"
    
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    local log_entry="[$timestamp] [$task_id] [$status] [$agent_id] $details"
    
    # Write to task log
    echo "$log_entry" >> "$TASK_LOG"
    
    # Also write to main log
    echo "$log_entry" >> "$MAIN_LOG"
    
    # Console output with appropriate color
    local color="$LOG_COLOR_INFO"
    case "$status" in
        "STARTED") color="$LOG_COLOR_INFO" ;;
        "COMPLETED") color="$LOG_COLOR_INFO" ;;
        "FAILED") color="$LOG_COLOR_ERROR" ;;
        "SKIPPED") color="$LOG_COLOR_WARN" ;;
    esac
    
    if [[ -t 1 ]]; then
        echo -e "${color}[TASK:$task_id]${LOG_COLOR_RESET} $status by $agent_id: $details"
    else
        echo "[TASK:$task_id] $status by $agent_id: $details"
    fi
}

# Agent task execution with input/output logging
log_agent_execution() {
    local agent_id="$1"
    local task_id="$2"
    local inputs="$3"
    local outputs="$4"
    local duration="$5"
    local status="$6"
    
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Create detailed execution log entry
    cat >> "$AGENT_LOG" << EOF
[$timestamp] [$agent_id] [EXECUTION] Task: $task_id
  Status: $status
  Duration: $duration
  Inputs: $inputs
  Outputs: $outputs
  ---
EOF
    
    # Summary to main log
    log_info "$agent_id" "Completed $task_id in $duration - Status: $status"
    
    # Task log entry
    log_task "$task_id" "$status" "$agent_id" "Duration: $duration, Outputs: $outputs"
}

# System summary logging
log_summary() {
    local total_tasks="$1"
    local completed_tasks="$2"
    local failed_tasks="$3"
    local total_duration="$4"
    
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    cat >> "$MAIN_LOG" << EOF

=== EXECUTION SUMMARY ===
Completed at: $timestamp
Total tasks: $total_tasks
Completed: $completed_tasks
Failed: $failed_tasks
Total duration: $total_duration
========================

EOF
    
    echo -e "${GREEN}📊 Execution Summary:${NC}"
    echo -e "   Total tasks: $total_tasks"
    echo -e "   Completed: $completed_tasks"
    echo -e "   Failed: $failed_tasks"
    echo -e "   Duration: $total_duration"
}