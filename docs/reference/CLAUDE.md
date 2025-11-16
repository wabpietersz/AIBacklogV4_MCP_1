# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hybrid Jira MCP Server combining:
- **FastMCP 2.0** - Modern Python MCP framework
- **mcp-atlassian patterns** - Battle-tested Jira integration (https://github.com/sooperset/mcp-atlassian)
- **Microsoft Agent Framework** - Enterprise agentic AI integration

The server exposes Jira operations as MCP tools consumable by Microsoft Agent Framework, Claude Desktop, Cursor IDE, and other MCP-compatible clients.

**Target Environment**: Azure Container Apps (ACA)
**Development Flow**: Local → Docker → Azure Container Registry → Azure Container Apps

## Architecture

### Hybrid Approach

This implementation uses a **hybrid architecture**:
1. Core server structure and patterns from **mcp-atlassian** (proven, production-ready)
2. Modern FastMCP 2.0 framework features
3. Azure-native integrations for Microsoft Agent Framework

### Core Components

1. **Custom FastMCP Server** (`src/jira_mcp/server.py`):
   - Custom `JiraMCP(FastMCP)` class with tool filtering
   - Lifespan context management for config/resources
   - Multi-transport support (stdio, SSE, streamable-http)
   - Health check endpoint for Azure Container Apps

2. **Jira API Client** (`src/jira_mcp/jira/client.py`):
   - Wraps `atlassian-python-api` library (battle-tested)
   - Multi-auth support (PAT, OAuth, API token, Azure AD)
   - Per-request auth override via middleware

3. **Authentication Layer** (`src/jira_mcp/auth/`):
   - User token middleware (Bearer/Token headers)
   - Azure AD / Entra ID integration
   - Managed Identity support
   - Multi-cloud ID header (`X-Atlassian-Cloud-Id`)

4. **Microsoft Agent Integration**:
   - MCP server registration in Azure AI Foundry
   - Agent-to-Agent (A2A) protocol support
   - Multi-agent orchestration examples

### Authentication Hierarchy

```
1. Per-request token (highest priority)
   - Authorization: Bearer <oauth_token>  # Cloud
   - Authorization: Token <pat>           # Server/DC
   - X-Atlassian-Cloud-Id: <cloud_id>     # Multi-cloud

2. Azure AD / Entra ID (new)
   - MSAL token acquisition
   - Managed Identity
   - Service Principal

3. Server-level config (fallback)
   - Environment variables
   - Azure Key Vault secrets
```

**Default credentials**:
- Service account: `sa.jira.mscopilot.uat@ifs.com`
- Base URL: `https://your-domain.atlassian.net`

## Development Commands

### Local Development

```bash
# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies (basic)
pip install -e .

# Install with Microsoft integration
pip install -e ".[microsoft]"

# Install development dependencies
pip install -e ".[dev]"

# Run server locally (stdio for testing with MCP Inspector)
python -m jira_mcp --transport stdio -vv

# Run as HTTP server (for Microsoft Agent Framework)
python -m jira_mcp --transport streamable-http --port 8000 -vv

# Test with MCP Inspector
npx @modelcontextprotocol/inspector python -m jira_mcp
```

### Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src/jira_mcp --cov-report=html

# Run specific test file
pytest tests/unit/test_jira_client.py -v

# Run integration tests (requires real Jira instance)
pytest tests/integration/ -v --env-file=.env.test
```

### Docker Commands

```bash
# Build Docker image
docker build -t jira-mcp-server:latest .

# Run locally in Docker
docker run --env-file .env -p 8000:8000 jira-mcp-server:latest

# Test health endpoint
curl http://localhost:8000/healthz

# Run with MCP Inspector
docker run -it --env-file .env -p 8000:8000 jira-mcp-server:latest
```

### Azure Deployment

```bash
# Login to Azure
az login

# Push to ACR
az acr login --name <your-acr-name>
docker tag jira-mcp-server:latest <your-acr-name>.azurecr.io/jira-mcp-server:dev
docker push <your-acr-name>.azurecr.io/jira-mcp-server:dev

# Deploy to ACA
az containerapp create \
  --name jira-mcp-dev \
  --resource-group <resource-group> \
  --environment <aca-environment> \
  --image <your-acr-name>.azurecr.io/jira-mcp-server:dev \
  --secrets jira-token=<token> \
  --env-vars JIRA_BASE_URL=<url> JIRA_EMAIL=<email> JIRA_API_TOKEN=secretref:jira-token

# Check deployment status
az containerapp show --name jira-mcp-dev --resource-group <resource-group>
```

## Environment Configuration

### Core Variables

```bash
# Jira Configuration
JIRA_URL=https://your-domain.atlassian.net
JIRA_USERNAME=sa.jira.mscopilot.uat@ifs.com  # For Cloud with API token
JIRA_API_TOKEN=<your_api_token>              # Cloud

# OR for Server/Data Center
JIRA_PERSONAL_TOKEN=<your_pat>               # Server/DC

# Server Configuration
TRANSPORT=streamable-http  # stdio | sse | streamable-http
PORT=8000
HOST=0.0.0.0
STREAMABLE_HTTP_PATH=/mcp

# Tool Filtering
ENABLED_TOOLS=jira_search,jira_get_issue,jira_create_issue,jira_update_issue,jira_add_comment,jira_transition_issue
READ_ONLY_MODE=false

# Logging
MCP_VERBOSE=true        # INFO level
MCP_VERY_VERBOSE=false  # DEBUG level
MCP_LOGGING_STDOUT=true
```

### Azure-Specific Variables (New)

```bash
# Azure AD / Entra ID
AZURE_CLIENT_ID=<your_client_id>
AZURE_TENANT_ID=<your_tenant_id>
AZURE_CLIENT_SECRET=<your_secret>  # Or use Managed Identity
AZURE_USE_MANAGED_IDENTITY=true

# Azure Key Vault (optional)
AZURE_KEY_VAULT_URL=https://<vault-name>.vault.azure.net/
```

### Multi-Cloud Support

```bash
# For multi-cloud deployments, clients can override via headers:
# X-Atlassian-Cloud-Id: <cloud_id>
```

## MCP Tools (from mcp-atlassian)

### Core Tools (Priority 0)

1. **`jira_search`** - Search issues using JQL
   - Tags: `{jira, read}`
   - Params: `jql`, `max_results`, `fields`

2. **`jira_get_issue`** - Get issue details
   - Tags: `{jira, read}`
   - Params: `issue_key`, `fields`, `expand`

3. **`jira_create_issue`** - Create new issue
   - Tags: `{jira, write}`
   - Params: `project`, `summary`, `issue_type`, `description`, `fields`

4. **`jira_update_issue`** - Update existing issue
   - Tags: `{jira, write}`
   - Params: `issue_key`, `fields`

5. **`jira_add_comment`** - Add comment to issue
   - Tags: `{jira, write}`
   - Params: `issue_key`, `comment`

6. **`jira_transition_issue`** - Change issue status
   - Tags: `{jira, write}`
   - Params: `issue_key`, `transition_name`

### Advanced Tools (Priority 1)

7. **`jira_get_agile_boards`** - List agile boards
8. **`jira_get_sprints_from_board`** - Get sprints for a board
9. **`jira_get_sprint_issues`** - Get issues in a sprint
10. **`jira_add_worklog`** - Add time tracking entry
11. **`jira_create_issue_link`** - Link two issues
12. **`jira_get_transitions`** - Get available transitions

### Azure Integration Tools (Priority 2 - Future)

13. **`jira_sync_to_azure_ai_search`** - Sync to Azure AI Search
14. **`jira_create_from_teams`** - Create issue from Teams message

## Microsoft Agent Framework Integration

### Python Agent Example

```python
from agent_framework import Agent
from mcp.client.streamable_http import streamablehttp_client

# Create agent
agent = Agent(name="JiraAgent", model="gpt-4o")

# Connect to MCP server
async with streamablehttp_client(
    "https://jira-mcp-dev.azurecontainerapps.io/mcp",
    headers={"Authorization": f"Bearer {token}"}
) as (read, write, _):
    async with ClientSession(read, write) as session:
        await session.initialize()
        result = await agent.run(
            "Find all P0 bugs and create a summary",
            tools=session.get_tools()
        )
```

### .NET Agent Example

```csharp
using Microsoft.Agents.AI;
using Microsoft.Agents.MCP;

var agent = new Agent("JiraAgent")
    .WithMCPServer("https://jira-mcp-dev.azurecontainerapps.io/mcp")
    .WithAzureAD();

var result = await agent.RunAsync(
    "Create a sprint report for the last 2 weeks"
);
```

## Key Implementation Patterns

### 1. Custom FastMCP Server Class

```python
from fastmcp import FastMCP
from mcp.types import Tool as MCPTool

class JiraMCP(FastMCP):
    async def _mcp_list_tools(self) -> list[MCPTool]:
        # Filter tools based on:
        # - enabled_tools config
        # - read_only mode
        # - authentication status
        pass
```

### 2. Dependency Injection for Tools

```python
from fastmcp import Context

async def get_jira_fetcher(ctx: Context):
    """Get Jira client with per-request auth override."""
    request = getattr(ctx, "request", None)
    if request and hasattr(request.state, "user_atlassian_token"):
        return JiraFetcher.from_token(request.state.user_atlassian_token)
    return JiraFetcher.from_config(ctx.lifespan_context["jira_config"])

@jira_mcp.tool(tags={"jira", "read"})
async def jira_search(ctx: Context, jql: str) -> str:
    jira = await get_jira_fetcher(ctx)
    return jira.search_issues(jql)
```

### 3. Write Access Decorator

```python
from functools import wraps

def check_write_access(func):
    @wraps(func)
    async def wrapper(ctx: Context, *args, **kwargs):
        if is_read_only_mode():
            raise PermissionError("Server is in read-only mode")
        return await func(ctx, *args, **kwargs)
    return wrapper
```

## Project Structure

```
src/jira_mcp/
├── __init__.py
├── server.py              # Main FastMCP server
├── config/
│   ├── jira_config.py     # From mcp-atlassian pattern
│   └── azure_config.py    # New
├── jira/
│   ├── client.py          # Jira API wrapper
│   ├── issues.py
│   ├── search.py
│   └── agile.py
├── tools/
│   ├── jira_tools.py      # MCP tool definitions
│   └── azure_tools.py
├── auth/
│   ├── middleware.py      # Token extraction
│   ├── jira_auth.py
│   └── azure_auth.py
├── models/
│   └── jira_models.py     # Pydantic models
└── utils/
    ├── logging.py
    └── decorators.py
```

## Deployment Strategy (DEV Environment)

- **External ingress**: Enabled for Microsoft Agent Framework access
- **Secrets**: Azure Key Vault integration via Managed Identity
- **Networking**: No VNET (public endpoint with auth)
- **Scaling**: Min 1, Max 5 replicas (autoscale on CPU/memory)
- **Authentication**: Multi-auth (PAT, OAuth, Azure AD)
- **Monitoring**: Application Insights integration

## Development Approach

This project is built in **two distinct phases**:

### Phase 1: Jira MCP Server (5 weeks) - CURRENT PHASE
- Build and deploy production-ready MCP server
- All 6 core Jira tools working
- Multi-auth support (PAT, OAuth, Azure AD)
- Deployed to Azure Container Apps
- Public endpoint: `https://jira-mcp-server.azurecontainerapps.io/mcp`

**Status**: In Development
**See**: `PHASE1_IMPLEMENTATION.md` for detailed week-by-week plan

### Phase 2: Frontend Interface (4 weeks) - FUTURE
- Next.js web application
- Chat interface with LLM integration
- Direct Jira operations UI
- Admin dashboard
- Deployed to Azure Static Web Apps

**Status**: Not Started (waiting for Phase 1 completion)
**See**: `PHASED_APPROACH.md` for frontend architecture

## Current Focus: Phase 1

When implementing Phase 1, focus on:
1. **Week 1**: Core tools (search, get, create, update, comment, transition)
2. **Week 2**: Authentication middleware and tool filtering
3. **Week 3**: Comprehensive testing
4. **Week 4**: Docker and CI/CD
5. **Week 5**: Azure deployment and monitoring

## Reference Implementation

This project uses patterns from:
- **mcp-atlassian** (https://github.com/sooperset/mcp-atlassian) - Jira integration patterns cloned to `/tmp/mcp-atlassian`
- **FastMCP 2.0** (https://gofastmcp.com/) - Modern MCP framework
- **Microsoft Agent Framework** (https://learn.microsoft.com/en-us/agent-framework/)

## Key Documents

- `PHASED_APPROACH.md` - Overview of both phases
- `PHASE1_IMPLEMENTATION.md` - Detailed Phase 1 implementation guide (START HERE)
- `ARCHITECTURE.md` - Complete system architecture
- `IMPLEMENTATION_PLAN.md` - Original full implementation plan
- `CLAUDE.md` - This file (development guide)
