#!/bin/bash

# Agent Swarm System - Main Orchestration Script
# Usage: ./swarm.sh <agents_config> <specification_file>

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

# Initialize system
init_system() {
    echo -e "${BLUE}🚀 Initializing Agent Swarm System${NC}"
    
    # Create directories
    mkdir -p "$LOG_DIR" "$WORK_DIR" "$AGENTS_DIR"
    
    # Create session log
    SESSION_ID="swarm_$(date +%Y%m%d_%H%M%S)"
    MAIN_LOG="${LOG_DIR}/${SESSION_ID}_main.log"
    AGENT_LOG="${LOG_DIR}/${SESSION_ID}_agents.log"
    TASK_LOG="${LOG_DIR}/${SESSION_ID}_tasks.log"
    
    # Export for use in sourced scripts
    export SESSION_ID MAIN_LOG AGENT_LOG TASK_LOG
    
    echo "Session ID: $SESSION_ID" | tee "$MAIN_LOG"
    echo "Started at: $(date)" | tee -a "$MAIN_LOG"
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
    
    echo -e "${GREEN}✅ Input files validated${NC}" | tee -a "$MAIN_LOG"
}

# Main execution flow
main() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: $0 <agents_config> <specification_file>"
        echo ""
        echo "Arguments:"
        echo "  agents_config      - JSON file defining available agents and their roles"
        echo "  specification_file - Text file describing the target application"
        echo ""
        echo "Example:"
        echo "  $0 agents.json app_spec.txt"
        exit 1
    fi
    
    local agents_config="$1"
    local spec_file="$2"
    
    init_system "$@"
    validate_inputs "$agents_config" "$spec_file"
    
    echo -e "${BLUE}📋 Analyzing specification and planning tasks...${NC}" | tee -a "$MAIN_LOG"
    source "${SCRIPT_DIR}/lib/task_planner.sh"
    plan_tasks "$spec_file" "$agents_config"
    
    echo -e "${BLUE}🤖 Executing agent swarm...${NC}" | tee -a "$MAIN_LOG"
    source "${SCRIPT_DIR}/lib/agent_executor.sh"
    execute_swarm "$agents_config"
    
    echo -e "${GREEN}🎉 Agent swarm execution completed!${NC}" | tee -a "$MAIN_LOG"
    echo -e "${YELLOW}📊 Check logs in: $LOG_DIR${NC}"
    echo -e "${YELLOW}💾 Output in: $WORK_DIR${NC}"
}

# Run main function
main "$@"