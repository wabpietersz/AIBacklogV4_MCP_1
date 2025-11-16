# Hybrid Jira MCP Server Architecture

## Overview

This document outlines the hybrid architecture combining:
1. **FastMCP 2.0** - Modern Python MCP framework
2. **mcp-atlassian patterns** - Battle-tested Jira integration patterns
3. **Microsoft Agent Framework** - Enterprise agentic AI integration

## Architecture Components

### 1. Core MCP Server (FastMCP 2.0)

```
┌─────────────────────────────────────────────────────────────┐
│                    Jira MCP Server                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         Main FastMCP App (Custom Class)               │  │
│  │  - Lifespan context management                        │  │
│  │  - Tool filtering (read-only, enabled_tools)          │  │
│  │  - Multi-transport (stdio, SSE, streamable-http)      │  │
│  │  - Health check endpoint                              │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│  ┌────────────────────────┴────────────────────────┐        │
│  │                                                  │        │
│  ▼                                                  ▼        │
│ ┌──────────────────────┐            ┌──────────────────────┐│
│ │   Jira Tools Module  │            │  Azure AI Extensions ││
│ │  - Search issues     │            │  - Microsoft Graph   ││
│ │  - Create/Update     │            │  - Teams integration ││
│ │  - Transitions       │            │  - Azure AI Search   ││
│ │  - Comments          │            │  - Entra ID auth     ││
│ │  - Worklog           │            └──────────────────────┘│
│ │  - Agile (sprints)   │                                    │
│ └──────────────────────┘                                    │
└─────────────────────────────────────────────────────────────┘
```

### 2. Authentication Layer

Following mcp-atlassian's multi-auth pattern:

```python
Authentication Hierarchy:
1. Per-request token (highest priority)
   - Authorization: Bearer <oauth_token> (Cloud)
   - Authorization: Token <pat> (Server/DC)
   - X-Atlassian-Cloud-Id: <cloud_id> (optional)

2. Azure AD / Entra ID (new for Microsoft integration)
   - MSAL token acquisition
   - Azure Managed Identity support
   - Service Principal auth

3. Server-level config (fallback)
   - Environment variables
   - Azure Key Vault secrets
   - Docker secrets
```

### 3. Microsoft Agent Framework Integration

#### 3.1 Agent Consumption Pattern

```python
# Microsoft Agent Framework → MCP Server
from agent_framework import Agent
from mcp.client.streamable_http import streamablehttp_client
from mcp import ClientSession

# 1. Azure AD authenticated agent
agent = Agent(
    name="JiraAgent",
    model="gpt-4o",
    auth_provider=AzureADAuthProvider()
)

# 2. Connect to MCP server
async with streamablehttp_client(
    "https://jira-mcp-dev.azurecontainerapps.io/mcp",
    headers={
        "Authorization": f"Bearer {azure_token}",
        "X-Atlassian-Cloud-Id": cloud_id
    }
) as (read_stream, write_stream, _):
    async with ClientSession(read_stream, write_stream) as session:
        await session.initialize()

        # Agent can now use Jira tools
        result = await agent.run(
            "Create a bug ticket for the authentication issue",
            tools=session.get_tools()
        )
```

#### 3.2 Multi-Agent Orchestration

```python
# Azure AI Foundry multi-agent workflow
from agent_framework import Workflow, Agent

workflow = Workflow()

# Agent 1: Requirements analyst
analyst_agent = Agent(
    name="RequirementsAnalyst",
    mcp_servers=["jira-mcp"]
)

# Agent 2: Sprint planner
planner_agent = Agent(
    name="SprintPlanner",
    mcp_servers=["jira-mcp"]
)

# Define workflow
workflow.add_edge(analyst_agent, planner_agent)
workflow.register_mcp_server("jira-mcp", "https://jira-mcp-dev.azurecontainerapps.io/mcp")

# Execute
result = await workflow.run("Plan next sprint based on current backlog")
```

## Technical Stack

### Core Dependencies (from mcp-atlassian)

```toml
[project]
dependencies = [
    "fastmcp>=2.3.4,<3.0.0",          # Modern MCP framework
    "mcp>=1.8.0,<2.0.0",              # MCP protocol SDK
    "atlassian-python-api>=4.0.0",    # Jira API client (proven)
    "httpx>=0.28.0",                  # HTTP client
    "pydantic>=2.10.6",               # Data validation
    "python-dotenv>=1.0.1",           # Config management
    "cachetools>=5.0.0",              # Token caching
    "uvicorn>=0.27.1",                # ASGI server
    "starlette>=0.37.1",              # Web framework
]
```

### New Dependencies (Microsoft integration)

```toml
[project.optional-dependencies]
microsoft = [
    "azure-identity>=1.19.0",         # Azure AD / Entra ID
    "azure-keyvault-secrets>=4.9.0",  # Azure Key Vault
    "msal>=1.31.0",                   # Microsoft Authentication Library
    "msgraph-sdk>=1.13.0",            # Microsoft Graph (optional)
]
```

## Project Structure

```
jira-mcp-server/
├── src/
│   └── jira_mcp/
│       ├── __init__.py
│       ├── server.py                 # Main FastMCP server setup
│       ├── config/
│       │   ├── __init__.py
│       │   ├── jira_config.py        # Jira configuration (from mcp-atlassian pattern)
│       │   └── azure_config.py       # Azure-specific config
│       ├── jira/
│       │   ├── __init__.py
│       │   ├── client.py             # Jira API client wrapper (from mcp-atlassian)
│       │   ├── issues.py             # Issue operations
│       │   ├── search.py             # JQL search
│       │   ├── transitions.py        # Workflow transitions
│       │   ├── comments.py           # Comment management
│       │   ├── worklog.py            # Time tracking
│       │   └── agile.py              # Sprints, boards, epics
│       ├── tools/
│       │   ├── __init__.py
│       │   ├── jira_tools.py         # Jira MCP tools (from mcp-atlassian pattern)
│       │   └── azure_tools.py        # Azure integration tools (new)
│       ├── auth/
│       │   ├── __init__.py
│       │   ├── middleware.py         # Token extraction (from mcp-atlassian)
│       │   ├── jira_auth.py          # Jira authentication
│       │   └── azure_auth.py         # Azure AD/Entra ID (new)
│       ├── models/
│       │   ├── __init__.py
│       │   ├── jira_models.py        # Pydantic models (from mcp-atlassian)
│       │   └── base.py
│       └── utils/
│           ├── __init__.py
│           ├── logging.py            # Logging setup (from mcp-atlassian)
│           ├── env.py                # Environment helpers
│           └── decorators.py         # @check_write_access, etc.
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── Dockerfile
├── requirements.txt
├── pyproject.toml
├── .env.example
├── ARCHITECTURE.md                   # This file
├── CLAUDE.md                         # Development guide
└── README.md
```

## Key Design Patterns (from mcp-atlassian)

### 1. Custom FastMCP Server Class

```python
from fastmcp import FastMCP
from mcp.types import Tool as MCPTool

class JiraMCP(FastMCP):
    """Custom FastMCP server with tool filtering."""

    async def _mcp_list_tools(self) -> list[MCPTool]:
        # Filter based on:
        # - enabled_tools from config
        # - read_only mode
        # - authentication status
        # - service availability

        all_tools = await self.get_tools()
        filtered = []

        for name, tool in all_tools.items():
            if should_include_tool(name, self.enabled_tools):
                if not (self.read_only and "write" in tool.tags):
                    filtered.append(tool.to_mcp_tool(name=name))

        return filtered
```

### 2. Lifespan Context Management

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def jira_lifespan(app: FastMCP):
    # Startup
    jira_config = JiraConfig.from_env()
    azure_config = AzureConfig.from_env()

    app_context = {
        "jira_config": jira_config,
        "azure_config": azure_config,
        "read_only": is_read_only_mode(),
        "enabled_tools": get_enabled_tools()
    }

    yield app_context

    # Shutdown cleanup
    await jira_config.close()
```

### 3. Dependency Injection for Tools

```python
from fastmcp import Context

async def get_jira_fetcher(ctx: Context):
    """Get Jira client with per-request auth override."""
    request = getattr(ctx, "request", None)

    # Check for per-request token (from middleware)
    if request and hasattr(request.state, "user_atlassian_token"):
        # Use per-request credentials
        return JiraFetcher.from_token(
            request.state.user_atlassian_token,
            request.state.user_atlassian_auth_type
        )

    # Fall back to server config
    config = ctx.lifespan_context.get("jira_config")
    return JiraFetcher.from_config(config)

@jira_mcp.tool(tags={"jira", "read"})
async def jira_search(ctx: Context, jql: str) -> str:
    jira = await get_jira_fetcher(ctx)
    results = jira.search_issues(jql)
    return json.dumps(results)
```

### 4. User Token Middleware (Multi-tenant)

```python
from starlette.middleware.base import BaseHTTPMiddleware

class UserTokenMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        auth_header = request.headers.get("Authorization")
        cloud_id = request.headers.get("X-Atlassian-Cloud-Id")

        if auth_header:
            if auth_header.startswith("Bearer "):
                # OAuth token
                request.state.user_atlassian_token = auth_header[7:]
                request.state.user_atlassian_auth_type = "oauth"
            elif auth_header.startswith("Token "):
                # PAT
                request.state.user_atlassian_token = auth_header[6:]
                request.state.user_atlassian_auth_type = "pat"

        if cloud_id:
            request.state.user_atlassian_cloud_id = cloud_id

        return await call_next(request)
```

## Azure Container Apps Deployment

### Configuration

```yaml
# Azure Container Apps Environment Variables
JIRA_BASE_URL: https://your-domain.atlassian.net
JIRA_EMAIL: sa.jira.mscopilot.uat@ifs.com

# Authentication (choose one or support all)
# Option 1: PAT (simplest)
JIRA_API_TOKEN: ${KEYVAULT_JIRA_TOKEN}

# Option 2: OAuth (from mcp-atlassian pattern)
ATLASSIAN_OAUTH_CLIENT_ID: ${KEYVAULT_OAUTH_CLIENT_ID}
ATLASSIAN_OAUTH_CLIENT_SECRET: ${KEYVAULT_OAUTH_SECRET}
ATLASSIAN_OAUTH_CLOUD_ID: ${CLOUD_ID}

# Option 3: Azure AD (new)
AZURE_CLIENT_ID: ${KEYVAULT_AZURE_CLIENT_ID}
AZURE_TENANT_ID: ${TENANT_ID}
AZURE_USE_MANAGED_IDENTITY: true

# Server config
TRANSPORT: streamable-http
PORT: 8000
HOST: 0.0.0.0
ENABLED_TOOLS: jira_search,jira_get_issue,jira_create_issue,jira_update_issue,jira_add_comment,jira_transition_issue
READ_ONLY_MODE: false
```

### Container Apps Configuration

```bash
az containerapp create \
  --name jira-mcp-server \
  --resource-group ${RESOURCE_GROUP} \
  --environment ${ACA_ENVIRONMENT} \
  --image ${ACR_NAME}.azurecr.io/jira-mcp-server:latest \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 0.5 --memory 1.0Gi \
  --secrets \
    jira-token=keyvaultref:${KEYVAULT_URI}/secrets/jira-token,identityref:${USER_IDENTITY} \
  --env-vars \
    JIRA_BASE_URL=${JIRA_URL} \
    JIRA_EMAIL=${JIRA_EMAIL} \
    JIRA_API_TOKEN=secretref:jira-token \
    TRANSPORT=streamable-http \
    PORT=8000
```

## Microsoft Agent Framework Integration Points

### 1. MCP Server Registration in Azure AI Foundry

```python
# Register MCP server in Azure AI Foundry
from azure.ai.agents import AgentFactory

factory = AgentFactory()
factory.register_mcp_server(
    name="jira-mcp",
    url="https://jira-mcp-dev.azurecontainerapps.io/mcp",
    auth_provider=AzureADAuthProvider()
)
```

### 2. Agent Consumption

```python
# .NET Agent Framework
using Microsoft.Agents.AI;
using Microsoft.Agents.MCP;

var agent = new Agent("JiraAgent")
    .WithMCPServer("https://jira-mcp-dev.azurecontainerapps.io/mcp")
    .WithAzureAD();

var result = await agent.RunAsync(
    "Find all P0 bugs assigned to me and create a summary"
);
```

### 3. Python Agent Framework

```python
# Python Agent Framework
from agent_framework import Agent
from agent_framework.mcp import MCPClient

agent = Agent(
    name="JiraAgent",
    model="gpt-4o"
)

# Add MCP server
mcp_client = MCPClient("https://jira-mcp-dev.azurecontainerapps.io/mcp")
agent.add_mcp_server(mcp_client)

# Run agent
result = await agent.run(
    "Create a sprint report for the last 2 weeks"
)
```

## Development Workflow

### Local Development

```bash
# 1. Setup
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev,microsoft]"

# 2. Run locally (stdio for testing)
python -m jira_mcp --transport stdio -vv

# 3. Run as HTTP server
python -m jira_mcp --transport streamable-http --port 8000 -vv

# 4. Test with MCP Inspector
npx @modelcontextprotocol/inspector python -m jira_mcp
```

### Docker Build & Test

```bash
# Build
docker build -t jira-mcp-server:latest .

# Run locally
docker run --env-file .env -p 8000:8000 jira-mcp-server:latest

# Test health endpoint
curl http://localhost:8000/healthz
```

### Azure Deployment

```bash
# Push to ACR
az acr login --name ${ACR_NAME}
docker tag jira-mcp-server:latest ${ACR_NAME}.azurecr.io/jira-mcp-server:dev
docker push ${ACR_NAME}.azurecr.io/jira-mcp-server:dev

# Deploy to ACA
az containerapp update \
  --name jira-mcp-server \
  --resource-group ${RESOURCE_GROUP} \
  --image ${ACR_NAME}.azurecr.io/jira-mcp-server:dev
```

## Benefits of Hybrid Approach

### From mcp-atlassian

✅ Battle-tested Jira API patterns
✅ Comprehensive error handling
✅ Multi-auth support (OAuth, PAT, API token)
✅ Multi-cloud support
✅ Tool filtering and access control
✅ Proven JQL query handling
✅ Agile board/sprint support

### From FastMCP 2.0

✅ Modern, production-ready framework
✅ Modular and composable architecture
✅ Built-in enterprise auth (extensible)
✅ Multiple transport protocols
✅ Native async/await
✅ Type safety with Pydantic

### New Microsoft Integration

✅ Native Azure AD / Entra ID support
✅ Microsoft Agent Framework compatibility
✅ Azure AI Foundry integration
✅ Multi-agent orchestration
✅ Azure Key Vault for secrets
✅ Managed Identity support

## Next Steps

1. ✅ Complete architectural design
2. ⏳ Implement core server structure
3. ⏳ Port Jira tools from mcp-atlassian
4. ⏳ Add Azure auth layer
5. ⏳ Implement Microsoft Agent Framework examples
6. ⏳ Create comprehensive tests
7. ⏳ Docker containerization
8. ⏳ Azure deployment automation
