#!/bin/bash
# Setup script for Generic Agentic Platform
# Run this on Day 1 to set up your development environment

set -e  # Exit on error

echo "🚀 Setting up Generic Agentic Platform..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check Python version
echo -e "${BLUE}Checking Python version...${NC}"
python_version=$(python3 --version 2>&1 | awk '{print $2}')
required_version="3.10"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo -e "${RED}Error: Python 3.10+ required. Found: $python_version${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python $python_version${NC}"

# Create virtual environment
echo ""
echo -e "${BLUE}Creating virtual environment...${NC}"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment already exists${NC}"
fi

# Activate virtual environment
source .venv/bin/activate

# Upgrade pip
echo ""
echo -e "${BLUE}Upgrading pip...${NC}"
pip install --upgrade pip > /dev/null
echo -e "${GREEN}✓ pip upgraded${NC}"

# Install dependencies
echo ""
echo -e "${BLUE}Installing dependencies...${NC}"
pip install -e ".[dev]"
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Create directory structure
echo ""
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p src/{foundation,agents,orchestration,mcp_servers}
mkdir -p src/foundation/{agents,mcp,auth,utils}
mkdir -p src/agents/{jira,base}
mkdir -p src/mcp_servers/jira/{config,jira,tools}
mkdir -p src/orchestration
mkdir -p tests/{unit,integration,fixtures}
mkdir -p tests/unit/{foundation,agents,mcp_servers}
mkdir -p docs
mkdir -p scripts
mkdir -p examples

# Create __init__.py files
touch src/__init__.py
touch src/foundation/__init__.py
touch src/foundation/agents/__init__.py
touch src/foundation/mcp/__init__.py
touch src/foundation/auth/__init__.py
touch src/foundation/utils/__init__.py
touch src/agents/__init__.py
touch src/agents/jira/__init__.py
touch src/agents/base/__init__.py
touch src/orchestration/__init__.py
touch src/mcp_servers/__init__.py
touch src/mcp_servers/jira/__init__.py
touch tests/__init__.py

echo -e "${GREEN}✓ Directory structure created${NC}"

# Create .env file if it doesn't exist
echo ""
echo -e "${BLUE}Setting up environment variables...${NC}"
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "${GREEN}✓ .env file created (please update with your credentials)${NC}"
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
.venv/
venv/
ENV/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
.mypy_cache/
.ruff_cache/

# Environment
.env
.env.local
.env.*.local

# Logs
*.log

# OS
.DS_Store
Thumbs.db

# Azure
.azure/

# Documentation builds
docs/_build/
EOF
    echo -e "${GREEN}✓ .gitignore created${NC}"
fi

# Install pre-commit hooks (optional)
echo ""
echo -e "${BLUE}Setting up git hooks...${NC}"
if [ -d ".git" ]; then
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook: Run linting and tests

echo "Running pre-commit checks..."

# Run ruff
echo "Running ruff..."
ruff check .
if [ $? -ne 0 ]; then
    echo "❌ Ruff check failed. Please fix the errors."
    exit 1
fi

# Run mypy
echo "Running mypy..."
mypy src/
if [ $? -ne 0 ]; then
    echo "❌ Mypy check failed. Please fix the type errors."
    exit 1
fi

# Run tests
echo "Running tests..."
pytest --tb=short
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Please fix the failing tests."
    exit 1
fi

echo "✅ All pre-commit checks passed!"
EOF
    chmod +x .git/hooks/pre-commit
    echo -e "${GREEN}✓ Git pre-commit hook installed${NC}"
else
    echo -e "${BLUE}ℹ Git repository not initialized. Run 'git init' to enable hooks.${NC}"
fi

# Print summary
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}✓ Setup complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Activate virtual environment: source .venv/bin/activate"
echo "  2. Update .env with your credentials"
echo "  3. Review documentation: cat START_HERE.md"
echo "  4. Start coding: See AGENT_IMPLEMENTATION_PLAN.md Week 1"
echo ""
echo "Useful commands:"
echo "  - Run tests: pytest"
echo "  - Lint code: ruff check ."
echo "  - Format code: ruff format ."
echo "  - Type check: mypy src/"
echo "  - Coverage: pytest --cov=src"
echo ""
echo -e "${BLUE}Happy coding! 🚀${NC}"
