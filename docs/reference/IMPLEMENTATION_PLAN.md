# Implementation Plan: Hybrid Jira MCP Server

## Phase 1: Foundation (Week 1)

### 1.1 Project Setup
- [ ] Initialize Python project structure
  ```bash
  mkdir -p src/jira_mcp/{config,jira,tools,auth,models,utils}
  ```
- [ ] Create `pyproject.toml` based on mcp-atlassian
- [ ] Set up virtual environment and install FastMCP 2.0
- [ ] Configure development tools (ruff, mypy, pytest)

### 1.2 Core Configuration System
**Reference**: `/tmp/mcp-atlassian/src/mcp_atlassian/jira/config.py`

- [ ] `src/jira_mcp/config/jira_config.py`
  - Port `JiraConfig.from_env()` pattern from mcp-atlassian
  - Support PAT, OAuth, API token authentication
  - Multi-cloud ID support

- [ ] `src/jira_mcp/config/azure_config.py` (new)
  - Azure AD / Entra ID configuration
  - Managed Identity support
  - Key Vault integration

### 1.3 Basic FastMCP Server
**Reference**: `/tmp/mcp-atlassian/src/mcp_atlassian/servers/main.py`

- [ ] `src/jira_mcp/server.py`
  - Create custom `JiraMCP(FastMCP)` class
  - Implement lifespan context management
  - Add health check endpoint
  - Support stdio, SSE, streamable-http transports

**Code to implement**:
```python
from fastmcp import FastMCP
from contextlib import asynccontextmanager

@asynccontextmanager
async def jira_lifespan(app: FastMCP):
    # Load configs
    jira_config = JiraConfig.from_env()
    yield {"jira_config": jira_config}
    # Cleanup

jira_mcp = JiraMCP(name="Jira MCP", lifespan=jira_lifespan)
```

## Phase 2: Jira Integration (Week 1-2)

### 2.1 Jira API Client
**Reference**: `/tmp/mcp-atlassian/src/mcp_atlassian/jira/client.py`

- [ ] `src/jira_mcp/jira/client.py`
  - Port `JiraFetcher` class from mcp-atlassian
  - Wrap `atlassian-python-api` library
  - Add authentication handling (PAT, OAuth, API token)
  - Implement per-request auth override

- [ ] `src/jira_mcp/jira/search.py`
  - JQL query builder
  - Search pagination
  - Field selection logic

- [ ] `src/jira_mcp/jira/issues.py`
  - Get issue
  - Create issue
  - Update issue
  - Delete issue

### 2.2 Data Models
**Reference**: `/tmp/mcp-atlassian/src/mcp_atlassian/models/jira/`

- [ ] `src/jira_mcp/models/jira_models.py`
  - Port Pydantic models from mcp-atlassian:
    - `JiraIssue`
    - `JiraUser`
    - `JiraProject`
    - `JiraTransition`
    - `JiraComment`
  - Add `.to_simplified_dict()` methods for LLM consumption

### 2.3 Core Jira Tools
**Reference**: `/tmp/mcp-atlassian/src/mcp_atlassian/servers/jira.py`

- [ ] `src/jira_mcp/tools/jira_tools.py`

**Priority 1 Tools** (port from mcp-atlassian):
```python
@jira_mcp.tool(tags={"jira", "read"})
async def jira_search(ctx: Context, jql: str, max_results: int = 50) -> str:
    """Search Jira issues using JQL."""
    pass

@jira_mcp.tool(tags={"jira", "read"})
async def jira_get_issue(ctx: Context, issue_key: str, fields: str = "*all") -> str:
    """Get details of a specific Jira issue."""
    pass

@jira_mcp.tool(tags={"jira", "write"})
@check_write_access
async def jira_create_issue(ctx: Context, project: str, summary: str,
                            issue_type: str, description: str = None) -> str:
    """Create a new Jira issue."""
    pass

@jira_mcp.tool(tags={"jira", "write"})
@check_write_access
async def jira_update_issue(ctx: Context, issue_key: str, fields: dict) -> str:
    """Update an existing Jira issue."""
    pass

@jira_mcp.tool(tags={"jira", "write"})
@check_write_access
async def jira_add_comment(ctx: Context, issue_key: str, comment: str) -> str:
    """Add a comment to a Jira issue."""
    pass

@jira_mcp.tool(tags={"jira", "write"})
@check_write_access
async def jira_transition_issue(ctx: Context, issue_key: str,
                                transition_name: str) -> str:
    """Transition a Jira issue to a new status."""
    pass
```

## Phase 3: Authentication & Middleware (Week 2)

### 3.1 User Token Middleware
**Reference**: `/tmp/mcp-atlassian/src/mcp_atlassian/servers/main.py` (lines 209-326)

- [ ] `src/jira_mcp/auth/middleware.py`
  - Port `UserTokenMiddleware` from mcp-atlassian
  - Extract Bearer tokens (OAuth)
  - Extract Token headers (PAT)
  - Extract `X-Atlassian-Cloud-Id` header
  - Set `request.state` for per-request auth

### 3.2 Azure AD Integration (New)

- [ ] `src/jira_mcp/auth/azure_auth.py`
  - Implement `AzureADAuthProvider`
  - MSAL token acquisition
  - Managed Identity support
  - Service Principal auth

```python
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential

class AzureAuthMiddleware:
    async def get_token(self) -> str:
        if os.getenv("AZURE_USE_MANAGED_IDENTITY"):
            credential = ManagedIdentityCredential()
        else:
            credential = DefaultAzureCredential()

        token = credential.get_token("https://api.atlassian.com/.default")
        return token.token
```

### 3.3 Dependency Injection
**Reference**: `/tmp/mcp-atlassian/src/mcp_atlassian/servers/dependencies.py`

- [ ] `src/jira_mcp/dependencies.py`
  - Port `get_jira_fetcher(ctx)` pattern
  - Check for per-request auth
  - Fall back to server config

## Phase 4: Advanced Features (Week 3)

### 4.1 Agile Tools
**Reference**: `/tmp/mcp-atlassian/src/mcp_atlassian/jira/boards.py`, `sprints.py`

- [ ] Sprint management tools:
  - `jira_get_agile_boards`
  - `jira_get_sprints_from_board`
  - `jira_get_sprint_issues`
  - `jira_create_sprint`
  - `jira_update_sprint`

### 4.2 Advanced Issue Operations

- [ ] Worklog tools (time tracking)
- [ ] Issue linking
- [ ] Attachment handling
- [ ] Batch operations

### 4.3 Tool Filtering
**Reference**: `/tmp/mcp-atlassian/src/mcp_atlassian/servers/main.py` (lines 109-186)

- [ ] Implement `_mcp_list_tools()` override
- [ ] Filter by `enabled_tools` config
- [ ] Filter by `read_only` mode
- [ ] Filter by service availability

## Phase 5: Microsoft Agent Framework Integration (Week 3-4)

### 5.1 Agent Examples

- [ ] `examples/microsoft_agent_python.py`
```python
from agent_framework import Agent
from mcp.client.streamable_http import streamablehttp_client

agent = Agent(name="JiraAgent", model="gpt-4o")

async with streamablehttp_client("http://localhost:8000/mcp") as client:
    result = await agent.run(
        "Find all P0 bugs and create a summary",
        mcp_servers=[client]
    )
```

- [ ] `examples/microsoft_agent_dotnet.cs` (.NET example)

### 5.2 Azure AI Foundry Integration

- [ ] Create tutorial for registering MCP server in Azure AI Foundry
- [ ] Multi-agent orchestration example
- [ ] Agent-to-Agent (A2A) protocol example

### 5.3 Azure-Specific Tools (Optional)

- [ ] `jira_sync_to_azure_ai_search` - Sync Jira data to Azure AI Search
- [ ] `jira_create_from_teams_message` - Create Jira from Teams
- [ ] `jira_notify_teams` - Post updates to Teams channel

## Phase 6: Testing (Week 4)

### 6.1 Unit Tests

- [ ] `tests/unit/test_jira_config.py`
- [ ] `tests/unit/test_jira_client.py`
- [ ] `tests/unit/test_auth_middleware.py`
- [ ] `tests/unit/test_jira_tools.py`

### 6.2 Integration Tests

- [ ] `tests/integration/test_jira_api.py` (real Jira instance)
- [ ] `tests/integration/test_mcp_server.py` (MCP protocol)
- [ ] `tests/integration/test_microsoft_agent.py` (Agent Framework)

### 6.3 Test Fixtures
**Reference**: `/tmp/mcp-atlassian/tests/fixtures/`

- [ ] Mock Jira responses
- [ ] Mock MCP client
- [ ] Test environment setup

## Phase 7: Containerization & Deployment (Week 4-5)

### 7.1 Docker

- [ ] `Dockerfile`
  - Multi-stage build
  - Production dependencies only
  - Non-root user
  - Health check

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY pyproject.toml .
RUN pip install --no-cache-dir build && \
    python -m build

FROM python:3.12-slim
RUN useradd -m -u 1000 appuser
WORKDIR /app
COPY --from=builder /app/dist/*.whl .
RUN pip install --no-cache-dir *.whl
USER appuser
EXPOSE 8000
HEALTHCHECK CMD curl -f http://localhost:8000/healthz || exit 1
CMD ["python", "-m", "jira_mcp", "--transport", "streamable-http", "--port", "8000"]
```

- [ ] `.dockerignore`
- [ ] `docker-compose.yml` (for local testing)

### 7.2 Azure Container Registry

- [ ] Create ACR instance
- [ ] Set up CI/CD pipeline (GitHub Actions)
- [ ] Push multi-arch images (amd64, arm64)

### 7.3 Azure Container Apps Deployment

- [ ] Create ACA environment
- [ ] Configure secrets (Key Vault integration)
- [ ] Set up ingress (external)
- [ ] Configure autoscaling
- [ ] Add monitoring (Application Insights)

**Deployment script**:
```bash
#!/bin/bash
# deploy-to-aca.sh

az containerapp create \
  --name jira-mcp-server \
  --resource-group $RESOURCE_GROUP \
  --environment $ACA_ENV \
  --image $ACR_NAME.azurecr.io/jira-mcp-server:latest \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 0.5 --memory 1.0Gi \
  --registry-server $ACR_NAME.azurecr.io \
  --registry-identity system \
  --secrets \
    jira-token=keyvaultref:${KEYVAULT_URI}/secrets/jira-token,identityref:${IDENTITY} \
  --env-vars \
    JIRA_BASE_URL=${JIRA_URL} \
    JIRA_EMAIL=${JIRA_EMAIL} \
    JIRA_API_TOKEN=secretref:jira-token \
    TRANSPORT=streamable-http
```

## Phase 8: Documentation & Examples (Week 5)

### 8.1 Documentation

- [ ] Update `README.md` with quick start
- [ ] Add authentication setup guide
- [ ] Create Microsoft Agent Framework integration guide
- [ ] Add troubleshooting section

### 8.2 Examples

- [ ] Python agent examples
- [ ] .NET agent examples
- [ ] Multi-agent workflow examples
- [ ] Azure AI Foundry tutorial

### 8.3 API Documentation

- [ ] Generate tool schema documentation
- [ ] Create MCP protocol examples
- [ ] Add JQL query examples

## Phase 9: Production Readiness (Week 6)

### 9.1 Observability

- [ ] Structured logging (JSON)
- [ ] Application Insights integration
- [ ] Custom metrics (tool usage, latency)
- [ ] Distributed tracing

### 9.2 Security

- [ ] Secret scanning (pre-commit hooks)
- [ ] Dependency vulnerability scanning
- [ ] HTTPS enforcement
- [ ] Rate limiting
- [ ] Input validation & sanitization

### 9.3 Performance

- [ ] Token caching (TTLCache)
- [ ] Connection pooling
- [ ] Response compression
- [ ] Query optimization

## Implementation Priority Matrix

| Feature | Priority | Effort | Value | Week |
|---------|----------|--------|-------|------|
| Core MCP Server | P0 | Medium | High | 1 |
| Basic Jira Tools (search, get, create) | P0 | High | High | 1-2 |
| User Token Middleware | P0 | Medium | High | 2 |
| Docker + ACA Deployment | P0 | Medium | High | 4 |
| Advanced Jira Tools (sprints, worklog) | P1 | High | Medium | 3 |
| Microsoft Agent Examples | P1 | Medium | High | 3-4 |
| Azure AD Integration | P1 | Medium | Medium | 3 |
| Testing Suite | P1 | High | High | 4 |
| Azure-Specific Tools | P2 | High | Low | Future |
| Multi-agent Orchestration | P2 | Medium | Medium | Future |

## Success Metrics

- [ ] All P0 Jira tools working (6 core tools)
- [ ] Authentication working (PAT, OAuth, Azure AD)
- [ ] Deployed to Azure Container Apps
- [ ] Microsoft Agent Framework integration example
- [ ] 80%+ test coverage
- [ ] Documentation complete
- [ ] Sub-500ms p95 latency for tool calls
- [ ] Zero critical security vulnerabilities

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Jira API rate limits | Implement caching, request throttling |
| Authentication complexity | Start with PAT, add OAuth later |
| Microsoft Agent Framework changes | Abstract MCP layer, version pin |
| Azure costs | Start with minimal replicas, autoscale |
| mcp-atlassian divergence | Pin to specific commit, fork if needed |

## Go-Live Checklist

- [ ] All P0 features implemented
- [ ] Integration tests passing
- [ ] Docker image published to ACR
- [ ] Deployed to DEV environment
- [ ] Health checks passing
- [ ] Monitoring configured
- [ ] Documentation published
- [ ] Microsoft Agent examples tested
- [ ] Security scan passed
- [ ] Load testing completed (100 req/min)
