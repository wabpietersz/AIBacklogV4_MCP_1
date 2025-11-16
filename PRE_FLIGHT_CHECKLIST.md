# Pre-Flight Checklist

Complete this checklist BEFORE starting Day 1 tomorrow.

---

## ✅ Environment Setup

### Local Development Machine

**Python Environment**:
- [ ] Python 3.10 or higher installed
  ```bash
  python --version  # Should be 3.10+
  ```
- [ ] `uv` package installer installed (recommended)
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```
  OR
  ```bash
  pip install uv
  ```
- [ ] Git installed and configured
  ```bash
  git --version
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```

**Docker**:
- [ ] Docker Desktop installed and running
  ```bash
  docker --version
  docker ps  # Should not error
  ```

**Code Editor**:
- [ ] Cursor IDE installed and configured
- [ ] Python extension installed in Cursor
- [ ] Pylance extension installed

**Terminal Tools**:
- [ ] curl or wget available
- [ ] jq installed (for JSON parsing)
  ```bash
  # macOS
  brew install jq
  # Linux
  sudo apt install jq
  ```

---

## ✅ Azure Setup

### Azure Subscription

- [ ] Active Azure subscription
- [ ] Subscription ID noted down
- [ ] Resource group created
  ```bash
  az group create --name jira-mcp-rg --location eastus2
  ```

### Azure CLI

- [ ] Azure CLI installed
  ```bash
  az --version  # Should be 2.50+
  ```
- [ ] Logged into Azure
  ```bash
  az login
  az account show  # Verify correct subscription
  ```
- [ ] Set default subscription
  ```bash
  az account set --subscription "<your-subscription-id>"
  ```

### Azure Resources (Create These Now)

**Container Registry**:
```bash
az acr create \
  --resource-group jira-mcp-rg \
  --name jiramcpacr \
  --sku Basic \
  --location eastus2

# Enable admin user
az acr update --name jiramcpacr --admin-enabled true

# Get credentials (save these!)
az acr credential show --name jiramcpacr
```
- [ ] ACR created
- [ ] Admin credentials saved

**Key Vault**:
```bash
az keyvault create \
  --name jira-mcp-kv \
  --resource-group jira-mcp-rg \
  --location eastus2
```
- [ ] Key Vault created

**Container Apps Environment**:
```bash
az containerapp env create \
  --name jira-mcp-env \
  --resource-group jira-mcp-rg \
  --location eastus2
```
- [ ] Container Apps environment created

**Application Insights**:
```bash
az monitor app-insights component create \
  --app jira-mcp-insights \
  --location eastus2 \
  --resource-group jira-mcp-rg

# Get instrumentation key
az monitor app-insights component show \
  --app jira-mcp-insights \
  --resource-group jira-mcp-rg \
  --query instrumentationKey -o tsv
```
- [ ] Application Insights created
- [ ] Instrumentation key saved

---

## ✅ Jira Setup

### Jira Instance

- [ ] Jira instance accessible (Cloud or Server/Data Center)
- [ ] Jira base URL noted: `https://your-domain.atlassian.net`
- [ ] Test project created (e.g., "JB" - Jira Bot)

### Jira Authentication

**For Jira Cloud**:
- [ ] API token generated at https://id.atlassian.com/manage-profile/security/api-tokens
- [ ] API token saved securely
- [ ] Service account email: `sa.jira.mscopilot.uat@ifs.com` (or your service account)

**For Jira Server/Data Center**:
- [ ] Personal Access Token (PAT) generated
- [ ] PAT saved securely

### Test Jira Access

```bash
# For Cloud (replace with your values)
curl -u "sa.jira.mscopilot.uat@ifs.com:YOUR_API_TOKEN" \
  https://your-domain.atlassian.net/rest/api/2/myself

# Should return your user info
```
- [ ] Jira API access confirmed

### Store Jira Credentials in Azure Key Vault

```bash
# Store Jira credentials
az keyvault secret set \
  --vault-name jira-mcp-kv \
  --name jira-api-token \
  --value "YOUR_API_TOKEN"

az keyvault secret set \
  --vault-name jira-mcp-kv \
  --name jira-url \
  --value "https://your-domain.atlassian.net"

az keyvault secret set \
  --vault-name jira-mcp-kv \
  --name jira-email \
  --value "sa.jira.mscopilot.uat@ifs.com"
```
- [ ] Jira credentials in Key Vault

---

## ✅ GitHub Setup

### Repository

- [ ] GitHub repository created
  ```bash
  # If not already created
  gh repo create jira-mcp-platform --private
  ```
- [ ] Local repository initialized
  ```bash
  cd Chat-MCP-Jira-V1
  git init
  git remote add origin https://github.com/YOUR_USERNAME/jira-mcp-platform.git
  ```

### GitHub Secrets (for CI/CD)

Add these secrets to your GitHub repository:

```bash
# Go to: Settings → Secrets and variables → Actions → New repository secret
```

- [ ] `AZURE_CREDENTIALS` - Service principal JSON
  ```bash
  # Create service principal
  az ad sp create-for-rbac \
    --name "github-actions-jira-mcp" \
    --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/jira-mcp-rg \
    --sdk-auth
  # Copy entire JSON output to GitHub secret
  ```
- [ ] `ACR_NAME` - `jiramcpacr`
- [ ] `RESOURCE_GROUP` - `jira-mcp-rg`
- [ ] `AZURE_SUBSCRIPTION_ID` - Your subscription ID

---

## ✅ Development Tools

### Python Tools

```bash
# Install development tools globally
pip install ruff mypy black pytest
```
- [ ] Ruff installed (linting)
- [ ] Mypy installed (type checking)
- [ ] Black installed (formatting - optional, ruff can format too)
- [ ] Pytest installed

### Node.js (for MCP Inspector)

```bash
# Install Node.js if not already
# macOS
brew install node

# Verify
node --version  # Should be 18+
npm --version

# Install MCP Inspector globally
npm install -g @modelcontextprotocol/inspector
```
- [ ] Node.js installed
- [ ] MCP Inspector installed

---

## ✅ Project Files Ready

### Core Files Created

In `Chat-MCP-Jira-V1/`:
- [ ] `README.md` - Project overview
- [ ] `AGENT_ARCHITECTURE.md` - Architecture
- [ ] `AGENT_IMPLEMENTATION_PLAN.md` - Implementation guide
- [ ] `MASTER_PLAN.md` - This master plan
- [ ] `PRE_FLIGHT_CHECKLIST.md` - This checklist

### Create Initial Project Structure

```bash
cd Chat-MCP-Jira-V1

# Create directories
mkdir -p src/{foundation,agents,orchestration,mcp_servers}
mkdir -p src/foundation/{agents,mcp,auth,utils}
mkdir -p src/agents/{jira,base}
mkdir -p src/mcp_servers/jira/{config,jira,tools}
mkdir -p src/orchestration
mkdir -p tests/{unit,integration,fixtures}
mkdir -p tests/unit/{foundation,agents,mcp_servers}
mkdir -p docs
mkdir -p scripts

# Create placeholder files
touch src/__init__.py
touch src/foundation/__init__.py
touch src/foundation/agents/__init__.py
touch src/foundation/mcp/__init__.py
touch src/foundation/auth/__init__.py
touch src/foundation/utils/__init__.py
touch src/agents/__init__.py
touch src/orchestration/__init__.py
touch src/mcp_servers/__init__.py
touch tests/__init__.py

# Create .gitignore
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

# Create .env.example
cat > .env.example << 'EOF'
# Jira Configuration
JIRA_URL=https://your-domain.atlassian.net
JIRA_USERNAME=sa.jira.mscopilot.uat@ifs.com
JIRA_API_TOKEN=your_api_token_here

# MCP Server Configuration
TRANSPORT=streamable-http
PORT=8000
HOST=0.0.0.0

# Tool Filtering
ENABLED_TOOLS=  # Empty = all tools enabled
READ_ONLY_MODE=false

# Logging
MCP_VERBOSE=true
MCP_VERY_VERBOSE=false
MCP_LOGGING_STDOUT=true

# Azure (Optional)
AZURE_CLIENT_ID=
AZURE_TENANT_ID=
AZURE_CLIENT_SECRET=
AZURE_USE_MANAGED_IDENTITY=false
APPLICATIONINSIGHTS_CONNECTION_STRING=
EOF
```
- [ ] Directory structure created
- [ ] .gitignore created
- [ ] .env.example created

---

## ✅ Reference Code

### mcp-atlassian Reference

```bash
# Verify mcp-atlassian is cloned
ls -la /tmp/mcp-atlassian

# If not, clone it
git clone https://github.com/sooperset/mcp-atlassian.git /tmp/mcp-atlassian
```
- [ ] mcp-atlassian cloned to `/tmp/mcp-atlassian`

---

## ✅ Documentation Review

### Read These Documents (30 min total)

- [ ] **README.md** (5 min) - Vision overview
- [ ] **AGENT_ARCHITECTURE.md** (10 min) - Understand 5 layers
- [ ] **MASTER_PLAN.md** (10 min) - This file
- [ ] **AGENT_IMPLEMENTATION_PLAN.md** (5 min) - Skim Week 1

---

## ✅ Mental Preparation

### Understand the Vision

Can you explain these to yourself?

- [ ] Why is the foundation generic and reusable?
- [ ] What's the difference between General User and Admin personas?
- [ ] How does the orchestrator route to the right agent?
- [ ] Why is Week 1 building foundation instead of Jira tools?
- [ ] How will this architecture support HR use case in the future?

If you can't answer these, re-read AGENT_ARCHITECTURE.md.

---

## ✅ Final Checks

### Day 1 Tomorrow - Are You Ready?

- [ ] I understand the 5-layer architecture
- [ ] I have my environment set up
- [ ] I have Jira credentials ready
- [ ] I have Azure resources created
- [ ] I have read AGENT_IMPLEMENTATION_PLAN.md Week 1
- [ ] I'm excited to build a reusable platform!

### Time Allocation

**Week 1 requires**:
- ~6-8 hours per day
- ~30-40 hours total
- Can be spread over 7 calendar days if needed

**Have you blocked time**:
- [ ] Day 1: 6-8 hours
- [ ] Day 2: 6-8 hours
- [ ] Day 3: 6-8 hours
- [ ] Day 4: 6-8 hours
- [ ] Day 5: 6-8 hours

---

## 🚀 Ready to Start!

If all checkboxes above are checked, you're ready to start Week 1, Day 1 tomorrow!

**First task tomorrow**:
Open AGENT_IMPLEMENTATION_PLAN.md → Week 1 → Day 1 → Start coding BaseAgent, Persona, Permission classes.

**Good luck! You're building something amazing! 🎉**

---

## 📞 Quick Reference

### Key URLs to Bookmark

- **Jira**: https://your-domain.atlassian.net
- **Azure Portal**: https://portal.azure.com
- **GitHub Repo**: https://github.com/YOUR_USERNAME/jira-mcp-platform
- **mcp-atlassian**: https://github.com/sooperset/mcp-atlassian

### Key Commands

```bash
# Start local development
cd Chat-MCP-Jira-V1
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# Run tests
pytest

# Lint
ruff check .

# Type check
mypy src/

# Format
ruff format .

# Run MCP Inspector
npx @modelcontextprotocol/inspector python -m your_module
```

Save this file - you'll reference it throughout the project!
