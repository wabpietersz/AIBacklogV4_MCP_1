#!/bin/bash
# Development helper script
# Useful commands for daily development

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if virtual environment is activated
if [ -z "$VIRTUAL_ENV" ]; then
    echo -e "${YELLOW}⚠ Virtual environment not activated${NC}"
    echo "Run: source .venv/bin/activate"
    exit 1
fi

# Function to show help
show_help() {
    cat << EOF
${BLUE}Generic Agentic Platform - Development Commands${NC}

Usage: ./dev.sh <command>

Commands:
  ${GREEN}test${NC}           Run all tests
  ${GREEN}test-cov${NC}       Run tests with coverage report
  ${GREEN}test-unit${NC}      Run only unit tests
  ${GREEN}test-int${NC}       Run only integration tests
  ${GREEN}lint${NC}           Run ruff linter
  ${GREEN}format${NC}         Format code with ruff
  ${GREEN}type${NC}           Run mypy type checker
  ${GREEN}check${NC}          Run all checks (lint + type + test)
  ${GREEN}clean${NC}          Clean build artifacts and cache
  ${GREEN}run-api${NC}        Run FastAPI backend (dev mode)
  ${GREEN}run-mcp${NC}        Run Jira MCP server (dev mode)
  ${GREEN}docker-build${NC}   Build Docker image
  ${GREEN}docker-run${NC}     Run Docker container locally
  ${GREEN}deps${NC}           Update dependencies
  ${GREEN}help${NC}           Show this help message

Examples:
  ./dev.sh test          # Run all tests
  ./dev.sh check         # Run full quality check
  ./dev.sh run-api       # Start backend API

EOF
}

# Parse command
case "$1" in
    test)
        echo -e "${BLUE}Running tests...${NC}"
        pytest
        ;;

    test-cov)
        echo -e "${BLUE}Running tests with coverage...${NC}"
        pytest --cov=src --cov-report=html --cov-report=term
        echo -e "${GREEN}✓ Coverage report: htmlcov/index.html${NC}"
        ;;

    test-unit)
        echo -e "${BLUE}Running unit tests...${NC}"
        pytest tests/unit -v
        ;;

    test-int)
        echo -e "${BLUE}Running integration tests...${NC}"
        pytest tests/integration -v
        ;;

    lint)
        echo -e "${BLUE}Running ruff linter...${NC}"
        ruff check .
        echo -e "${GREEN}✓ Linting passed${NC}"
        ;;

    format)
        echo -e "${BLUE}Formatting code...${NC}"
        ruff format .
        echo -e "${GREEN}✓ Code formatted${NC}"
        ;;

    type)
        echo -e "${BLUE}Running mypy type checker...${NC}"
        mypy src/
        echo -e "${GREEN}✓ Type checking passed${NC}"
        ;;

    check)
        echo -e "${BLUE}Running full quality check...${NC}"
        echo ""
        echo -e "${BLUE}1/4 Linting...${NC}"
        ruff check .
        echo ""
        echo -e "${BLUE}2/4 Formatting...${NC}"
        ruff format . --check
        echo ""
        echo -e "${BLUE}3/4 Type checking...${NC}"
        mypy src/
        echo ""
        echo -e "${BLUE}4/4 Testing...${NC}"
        pytest --tb=short
        echo ""
        echo -e "${GREEN}✓ All checks passed!${NC}"
        ;;

    clean)
        echo -e "${BLUE}Cleaning build artifacts...${NC}"
        find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
        find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
        find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
        find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
        find . -type f -name "*.pyc" -delete
        rm -rf build/ dist/ htmlcov/ .coverage
        echo -e "${GREEN}✓ Cleaned${NC}"
        ;;

    run-api)
        echo -e "${BLUE}Starting FastAPI backend...${NC}"
        if [ ! -f "src/main.py" ]; then
            echo -e "${RED}Error: src/main.py not found${NC}"
            echo "Complete Week 4 to create the API backend"
            exit 1
        fi
        uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
        ;;

    run-mcp)
        echo -e "${BLUE}Starting Jira MCP server...${NC}"
        if [ ! -f "src/mcp_servers/jira/server.py" ]; then
            echo -e "${RED}Error: Jira MCP server not found${NC}"
            echo "Complete Week 2 to create the MCP server"
            exit 1
        fi
        python -m src.mcp_servers.jira.server --transport stdio -v
        ;;

    docker-build)
        echo -e "${BLUE}Building Docker image...${NC}"
        if [ ! -f "Dockerfile" ]; then
            echo -e "${RED}Error: Dockerfile not found${NC}"
            echo "Create Dockerfile first (see Week 2, Day 9)"
            exit 1
        fi
        docker build -t jira-mcp-platform:latest .
        echo -e "${GREEN}✓ Docker image built: jira-mcp-platform:latest${NC}"
        ;;

    docker-run)
        echo -e "${BLUE}Running Docker container...${NC}"
        docker run --rm --env-file .env -p 8000:8000 jira-mcp-platform:latest
        ;;

    deps)
        echo -e "${BLUE}Updating dependencies...${NC}"
        pip install --upgrade pip
        pip install -e ".[dev]" --upgrade
        echo -e "${GREEN}✓ Dependencies updated${NC}"
        ;;

    help|--help|-h|"")
        show_help
        ;;

    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
