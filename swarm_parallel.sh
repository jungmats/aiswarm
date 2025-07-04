#!/bin/bash

# Agent Swarm System - Main Orchestration Script with Parallel Execution
# Usage: ./swarm_parallel.sh <agents_config> <specification_file> [--parallel]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
WORK_DIR="${SCRIPT_DIR}/workspace"
AGENTS_DIR="${SCRIPT_DIR}/agents"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Execution mode
PARALLEL_MODE=false

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --parallel)
                PARALLEL_MODE=true
                shift
                ;;
            --sequential)
                PARALLEL_MODE=false
                shift
                ;;
            *)
                if [[ -z "${AGENTS_CONFIG:-}" ]]; then
                    AGENTS_CONFIG="$1"
                elif [[ -z "${SPEC_FILE:-}" ]]; then
                    SPEC_FILE="$1"
                else
                    echo "Unknown argument: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Initialize system
init_system() {
    echo -e "${BLUE}🚀 Initializing Agent Swarm System${NC}"
    if [[ "$PARALLEL_MODE" == "true" ]]; then
        echo -e "${YELLOW}⚡ Parallel execution mode enabled${NC}"
    else
        echo -e "${YELLOW}📋 Sequential execution mode${NC}"
    fi
    
    # Create session ID first
    SESSION_ID="swarm_$(date +%Y%m%d_%H%M%S)"
    
    # Create directories including session-specific workspace and logs
    mkdir -p "$WORK_DIR" "$AGENTS_DIR"
    SESSION_WORKSPACE="${WORK_DIR}/${SESSION_ID}"
    SESSION_LOG_DIR="${SESSION_WORKSPACE}/logs"
    mkdir -p "$SESSION_WORKSPACE" "$SESSION_LOG_DIR"
    
    # Create session logs within the workspace
    MAIN_LOG="${SESSION_LOG_DIR}/main.log"
    AGENT_LOG="${SESSION_LOG_DIR}/agents.log"
    TASK_LOG="${SESSION_LOG_DIR}/tasks.log"
    
    # Export for use in sourced scripts
    export SESSION_ID SESSION_WORKSPACE SESSION_LOG_DIR MAIN_LOG AGENT_LOG TASK_LOG
    
    echo "Session ID: $SESSION_ID" | tee "$MAIN_LOG"
    echo "Session Workspace: $SESSION_WORKSPACE" | tee -a "$MAIN_LOG"
    echo "Session Logs: $SESSION_LOG_DIR" | tee -a "$MAIN_LOG"
    echo "Started at: $(date)" | tee -a "$MAIN_LOG"
    echo "Execution Mode: $([ "$PARALLEL_MODE" = true ] && echo "Parallel" || echo "Sequential")" | tee -a "$MAIN_LOG"
    echo "Arguments: $*" | tee -a "$MAIN_LOG"
    echo "----------------------------------------" | tee -a "$MAIN_LOG"
}

# Validate inputs
validate_inputs() {
    local agents_config="$1"
    local spec_file="$2"
    
    if [[ ! -f "$agents_config" ]]; then
        echo -e "${RED}❌ Agents config file not found: $agents_config${NC}" >&2
        exit 1
    fi
    
    if [[ ! -f "$spec_file" ]]; then
        echo -e "${RED}❌ Specification file not found: $spec_file${NC}" >&2
        exit 1
    fi
    
    # Validate JSON structure
    if ! jq empty "$agents_config" 2>/dev/null; then
        echo -e "${RED}❌ Invalid JSON in agents config: $agents_config${NC}" >&2
        exit 1
    fi
    
    echo -e "${GREEN}✅ Input files validated${NC}" | tee -a "$MAIN_LOG"
}

# Show execution mode info
show_execution_info() {
    local agents_config="$1"
    
    if [[ "$PARALLEL_MODE" == "true" ]]; then
        local max_parallel
        max_parallel=$(jq -r '.execution_settings.max_parallel_agents // 3' "$agents_config")
        echo -e "${BLUE}⚡ Parallel Execution Configuration:${NC}"
        echo -e "   Max Concurrent Agents: $max_parallel"
        echo -e "   Task Dependency Resolution: Automatic"
        echo -e "   Process Isolation: Background jobs"
        echo -e "   Monitoring: Real-time status updates"
    else
        echo -e "${BLUE}📋 Sequential Execution Configuration:${NC}"
        echo -e "   Execution: One task at a time"
        echo -e "   Dependency Resolution: Linear"
        echo -e "   Process Model: Single main process"
    fi
    echo ""
}

# Monitor execution in parallel mode
start_execution_monitor() {
    if [[ "$PARALLEL_MODE" == "true" ]]; then
        (
            # Load parallel executor functions
            source "${SCRIPT_DIR}/lib/parallel_executor.sh"
            monitor_parallel_execution
        ) &
        MONITOR_PID=$!
        echo -e "${BLUE}📊 Started execution monitor (PID: $MONITOR_PID)${NC}"
    fi
}

# Stop execution monitor
stop_execution_monitor() {
    if [[ -n "${MONITOR_PID:-}" ]]; then
        kill $MONITOR_PID 2>/dev/null || true
        wait $MONITOR_PID 2>/dev/null || true
    fi
}

# Main execution flow
main() {
    # Initialize variables
    AGENTS_CONFIG=""
    SPEC_FILE=""
    
    echo "DEBUG: main() called with args: $*" >&2
    
    # Parse arguments
    parse_arguments "$@"
    
    echo "DEBUG: After parsing - AGENTS_CONFIG='$AGENTS_CONFIG'" >&2
    echo "DEBUG: After parsing - SPEC_FILE='$SPEC_FILE'" >&2
    echo "DEBUG: After parsing - PARALLEL_MODE='$PARALLEL_MODE'" >&2
    
    # Show usage if insufficient arguments
    if [[ -z "${AGENTS_CONFIG:-}" || -z "${SPEC_FILE:-}" ]]; then
        echo "Usage: $0 <agents_config> <specification_file> [--parallel|--sequential]"
        echo ""
        echo "Arguments:"
        echo "  agents_config      - JSON file defining available agents and their roles"
        echo "  specification_file - Text file describing the target application"
        echo ""
        echo "Options:"
        echo "  --parallel         - Execute agents in parallel (default: sequential)"
        echo "  --sequential       - Execute agents sequentially"
        echo ""
        echo "Examples:"
        echo "  $0 agents.json app_spec.txt"
        echo "  $0 agents.json app_spec.txt --parallel"
        echo "  $0 agents.json app_spec.txt --sequential"
        exit 1
    fi
    
    init_system "$@"
    validate_inputs "$AGENTS_CONFIG" "$SPEC_FILE"
    show_execution_info "$AGENTS_CONFIG"
    
    echo -e "${BLUE}📋 Analyzing specification and planning tasks...${NC}" | tee -a "$MAIN_LOG"
    source "${SCRIPT_DIR}/lib/task_planner.sh"
    plan_tasks "$SPEC_FILE" "$AGENTS_CONFIG"
    
    echo -e "${BLUE}🤖 Executing agent swarm...${NC}" | tee -a "$MAIN_LOG"
    
    if [[ "$PARALLEL_MODE" == "true" ]]; then
        # Use parallel execution
        echo "DEBUG: About to call execute_swarm_parallel with AGENTS_CONFIG='$AGENTS_CONFIG'" >&2
        source "${SCRIPT_DIR}/lib/parallel_executor.sh"
        start_execution_monitor
        execute_swarm_parallel "$AGENTS_CONFIG"
        stop_execution_monitor
        show_parallel_stats
    else
        # Use sequential execution
        source "${SCRIPT_DIR}/lib/agent_executor.sh"
        execute_swarm "$AGENTS_CONFIG"
    fi
    
    echo -e "${GREEN}🎉 Agent swarm execution completed!${NC}" | tee -a "$MAIN_LOG"
    echo -e "${YELLOW}📊 Session workspace: $SESSION_WORKSPACE${NC}"
    echo -e "${YELLOW}📋 Session logs: $SESSION_LOG_DIR${NC}"
    echo -e "${YELLOW}💾 Generated artifacts: $SESSION_WORKSPACE/artifacts${NC}"
    
    # Show final summary
    show_final_summary
}

# Show final execution summary
show_final_summary() {
    echo ""
    echo -e "${BLUE}=== Final Execution Summary ===${NC}"
    
    local total_tasks completed_tasks failed_tasks
    total_tasks=$(jq '.phases | to_entries | map(.value.tasks | length) | add' "${SESSION_WORKSPACE}/task_plan.json" 2>/dev/null || echo "0")
    completed_tasks=$(jq '.completed | length' "${SESSION_WORKSPACE}/task_queue.json" 2>/dev/null || echo "0")
    failed_tasks=$(jq '.failed | length' "${SESSION_WORKSPACE}/task_queue.json" 2>/dev/null || echo "0")
    
    echo "Execution Mode: $([ "$PARALLEL_MODE" = true ] && echo "Parallel" || echo "Sequential")"
    echo "Total Tasks: $total_tasks"
    echo "Completed: $completed_tasks"
    echo "Failed: $failed_tasks"
    echo "Success Rate: $(( completed_tasks * 100 / (total_tasks == 0 ? 1 : total_tasks) ))%"
    
    if [[ "$PARALLEL_MODE" == "true" ]]; then
        local max_parallel
        max_parallel=$(jq -r '.execution_settings.max_parallel_agents // 3' "$AGENTS_CONFIG")
        echo "Max Parallel Agents: $max_parallel"
        echo "Theoretical Speedup: Up to ${max_parallel}x faster"
    fi
    
    echo "Generated Files: $(find "${SESSION_WORKSPACE}/artifacts" -type f 2>/dev/null | wc -l || echo "0")"
    echo "Session ID: $SESSION_ID"
}

# Signal handling for cleanup
cleanup() {
    echo -e "\n${YELLOW}🛑 Received interrupt signal${NC}"
    stop_execution_monitor
    
    if [[ "$PARALLEL_MODE" == "true" ]]; then
        echo -e "${YELLOW}⏹️  Stopping background processes...${NC}"
        # Kill any remaining background jobs
        jobs -p | xargs -r kill 2>/dev/null || true
    fi
    
    echo -e "${YELLOW}📋 Partial results available in: $SESSION_WORKSPACE${NC}"
    exit 130
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Run main function
main "$@"