# Phase 1 Implementation Plan: Jira MCP Server

**Goal**: Build and deploy a production-ready Jira MCP server to Azure Container Apps

**Timeline**: 5 weeks

**Success Metric**: Deployed MCP server accessible at `https://jira-mcp-dev.azurecontainerapps.io/mcp`

---

## Week 1: Foundation & Core Tools

### Day 1-2: Project Setup

**Create project structure:**
```bash
mkdir -p src/jira_mcp/{config,jira,tools,auth,models,utils}
mkdir -p tests/{unit,integration,fixtures}
touch src/jira_mcp/__init__.py
```

**Files to create:**

1. `pyproject.toml` (based on mcp-atlassian)
```toml
[project]
name = "jira-mcp-server"
version = "0.1.0"
description = "Jira MCP Server with FastMCP 2.0"
requires-python = ">=3.10"
dependencies = [
    "fastmcp>=2.3.4,<3.0.0",
    "mcp>=1.8.0,<2.0.0",
    "atlassian-python-api>=4.0.0",
    "httpx>=0.28.0",
    "pydantic>=2.10.6",
    "python-dotenv>=1.0.1",
    "cachetools>=5.0.0",
    "uvicorn>=0.27.1",
    "starlette>=0.37.1",
    "click>=8.1.7",
]

[project.optional-dependencies]
microsoft = [
    "azure-identity>=1.19.0",
    "azure-keyvault-secrets>=4.9.0",
    "msal>=1.31.0",
]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "ruff>=0.3.0",
    "mypy>=1.8.0",
]

[project.scripts]
jira-mcp = "jira_mcp:main"
```

2. `.env.example`
```bash
# Jira Configuration
JIRA_URL=https://your-domain.atlassian.net
JIRA_USERNAME=sa.jira.mscopilot.uat@ifs.com
JIRA_API_TOKEN=your_api_token_here

# Server Configuration
TRANSPORT=streamable-http
PORT=8000
HOST=0.0.0.0

# Optional
READ_ONLY_MODE=false
MCP_VERBOSE=true
```

**Reference**: `/tmp/mcp-atlassian/pyproject.toml`, `/tmp/mcp-atlassian/.env.example`

### Day 2-3: Configuration System

**Create `src/jira_mcp/config/jira_config.py`**

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/jira/config.py`

Key elements to port:
- `JiraConfig` class with `from_env()` method
- Authentication detection (PAT vs API token vs OAuth)
- SSL verification settings
- URL validation

```python
from dataclasses import dataclass
from typing import Optional
import os

@dataclass
class JiraConfig:
    url: str
    username: Optional[str] = None
    api_token: Optional[str] = None
    personal_token: Optional[str] = None
    ssl_verify: bool = True

    @classmethod
    def from_env(cls) -> "JiraConfig":
        return cls(
            url=os.getenv("JIRA_URL", ""),
            username=os.getenv("JIRA_USERNAME"),
            api_token=os.getenv("JIRA_API_TOKEN"),
            personal_token=os.getenv("JIRA_PERSONAL_TOKEN"),
            ssl_verify=os.getenv("JIRA_SSL_VERIFY", "true").lower() == "true",
        )

    def is_auth_configured(self) -> bool:
        if self.personal_token:
            return True
        if self.username and self.api_token:
            return True
        return False
```

**Create `src/jira_mcp/utils/env.py`**

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/utils/env.py`

```python
def is_env_truthy(env_var: str, default: str = "false") -> bool:
    """Check if environment variable is truthy."""
    value = os.getenv(env_var, default).lower()
    return value in ("true", "1", "yes", "on")

def is_read_only_mode() -> bool:
    return is_env_truthy("READ_ONLY_MODE", "false")

def get_enabled_tools() -> Optional[set[str]]:
    enabled = os.getenv("ENABLED_TOOLS")
    if enabled:
        return set(t.strip() for t in enabled.split(","))
    return None
```

### Day 3-4: Jira API Client

**Create `src/jira_mcp/jira/client.py`**

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/jira/client.py`

Key elements:
- `JiraFetcher` class wrapping `atlassian-python-api`
- Authentication handling
- Error handling
- Per-request auth override

```python
from atlassian import Jira
from typing import Dict, List, Any, Optional
from ..config.jira_config import JiraConfig

class JiraFetcher:
    def __init__(self, config: JiraConfig):
        self.config = config
        self.jira = self._create_client()

    def _create_client(self) -> Jira:
        if self.config.personal_token:
            return Jira(
                url=self.config.url,
                token=self.config.personal_token,
                verify_ssl=self.config.ssl_verify
            )
        else:
            return Jira(
                url=self.config.url,
                username=self.config.username,
                password=self.config.api_token,
                verify_ssl=self.config.ssl_verify
            )

    @classmethod
    def from_config(cls, config: JiraConfig) -> "JiraFetcher":
        return cls(config)

    @classmethod
    def from_token(cls, token: str, auth_type: str = "pat") -> "JiraFetcher":
        config = JiraConfig(
            url=os.getenv("JIRA_URL"),
            personal_token=token if auth_type == "pat" else None,
            api_token=token if auth_type == "oauth" else None,
        )
        return cls(config)
```

**Create `src/jira_mcp/jira/search.py`**

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/jira/search.py`

```python
from typing import Dict, List, Any

class JiraSearch:
    def __init__(self, jira_client):
        self.jira = jira_client

    def search_issues(self, jql: str, max_results: int = 50,
                     fields: str = "*all") -> List[Dict[str, Any]]:
        """Search Jira issues using JQL."""
        return self.jira.jql(jql, limit=max_results, fields=fields)
```

### Day 4-5: Core MCP Server & Tools

**Create `src/jira_mcp/server.py`**

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/servers/main.py`

```python
from fastmcp import FastMCP
from contextlib import asynccontextmanager
from .config.jira_config import JiraConfig
import logging

logger = logging.getLogger(__name__)

@asynccontextmanager
async def jira_lifespan(app: FastMCP):
    """Lifespan context for managing Jira config."""
    logger.info("Initializing Jira MCP server...")

    jira_config = JiraConfig.from_env()

    if not jira_config.is_auth_configured():
        logger.error("Jira authentication not configured!")
        raise ValueError("Jira auth not configured")

    app_context = {
        "jira_config": jira_config,
        "read_only": is_read_only_mode(),
        "enabled_tools": get_enabled_tools(),
    }

    logger.info("Jira MCP server initialized")
    yield app_context

    logger.info("Shutting down Jira MCP server...")

class JiraMCP(FastMCP):
    """Custom FastMCP server with tool filtering."""

    async def _mcp_list_tools(self):
        # TODO: Implement tool filtering
        return await super()._mcp_list_tools()

# Create main server instance
jira_mcp = JiraMCP(name="Jira MCP Server", lifespan=jira_lifespan)

# Health check endpoint
@jira_mcp.custom_route("/healthz", methods=["GET"])
async def health_check(request):
    from starlette.responses import JSONResponse
    return JSONResponse({"status": "ok"})
```

**Create `src/jira_mcp/tools/jira_tools.py`**

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/servers/jira.py`

```python
from fastmcp import Context
from typing import Annotated
from pydantic import Field
import json
from ..jira.client import JiraFetcher

@jira_mcp.tool(tags={"jira", "read"})
async def jira_search(
    ctx: Context,
    jql: Annotated[str, Field(description="JQL query string")],
    max_results: Annotated[int, Field(description="Max results", default=50)] = 50,
) -> str:
    """Search Jira issues using JQL."""
    jira = await get_jira_fetcher(ctx)
    results = jira.search_issues(jql, max_results)
    return json.dumps(results, indent=2)

@jira_mcp.tool(tags={"jira", "read"})
async def jira_get_issue(
    ctx: Context,
    issue_key: Annotated[str, Field(description="Issue key (e.g., PROJ-123)")],
) -> str:
    """Get Jira issue details."""
    jira = await get_jira_fetcher(ctx)
    issue = jira.jira.issue(issue_key)
    return json.dumps(issue, indent=2)

@jira_mcp.tool(tags={"jira", "write"})
async def jira_create_issue(
    ctx: Context,
    project: Annotated[str, Field(description="Project key")],
    summary: Annotated[str, Field(description="Issue summary")],
    issue_type: Annotated[str, Field(description="Issue type (Bug, Story, etc.)")],
    description: Annotated[str, Field(description="Issue description")] = "",
) -> str:
    """Create a new Jira issue."""
    jira = await get_jira_fetcher(ctx)
    issue = jira.jira.create_issue(
        fields={
            "project": {"key": project},
            "summary": summary,
            "description": description,
            "issuetype": {"name": issue_type},
        }
    )
    return json.dumps(issue, indent=2)

# Add remaining 3 core tools: update, comment, transition
```

**Create `src/jira_mcp/__init__.py`** (Entry point)

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/__init__.py`

```python
import click
import asyncio
from dotenv import load_dotenv
from .server import jira_mcp

@click.command()
@click.option("--transport", default="stdio", type=click.Choice(["stdio", "sse", "streamable-http"]))
@click.option("--port", default=8000)
@click.option("--host", default="0.0.0.0")
@click.option("-v", "--verbose", count=True)
def main(transport: str, port: int, host: str, verbose: int):
    """Jira MCP Server"""
    load_dotenv()

    run_kwargs = {"transport": transport}
    if transport in ["sse", "streamable-http"]:
        run_kwargs.update({"host": host, "port": port})

    asyncio.run(jira_mcp.run_async(**run_kwargs))

if __name__ == "__main__":
    main()
```

### Week 1 Deliverables
- ✅ Project structure created
- ✅ Configuration system working
- ✅ Jira API client functional
- ✅ Basic FastMCP server running
- ✅ 3-4 core tools working (search, get, create)

**Test Week 1:**
```bash
# Install and run
pip install -e .
python -m jira_mcp --transport stdio -v

# Test with MCP Inspector
npx @modelcontextprotocol/inspector python -m jira_mcp
```

---

## Week 2: Authentication & Remaining Tools

### Day 6-7: User Token Middleware

**Create `src/jira_mcp/auth/middleware.py`**

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/servers/main.py` (lines 209-326)

Key features:
- Extract `Authorization: Bearer <token>` header
- Extract `Authorization: Token <pat>` header
- Extract `X-Atlassian-Cloud-Id` header
- Set `request.state` for per-request auth

```python
from starlette.middleware.base import BaseHTTPMiddleware
import logging

logger = logging.getLogger(__name__)

class UserTokenMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        auth_header = request.headers.get("Authorization")

        if auth_header:
            if auth_header.startswith("Bearer "):
                token = auth_header[7:].strip()
                request.state.user_atlassian_token = token
                request.state.user_atlassian_auth_type = "oauth"
            elif auth_header.startswith("Token "):
                token = auth_header[6:].strip()
                request.state.user_atlassian_token = token
                request.state.user_atlassian_auth_type = "pat"

        cloud_id = request.headers.get("X-Atlassian-Cloud-Id")
        if cloud_id:
            request.state.user_atlassian_cloud_id = cloud_id

        return await call_next(request)
```

**Update `src/jira_mcp/server.py`** to add middleware:

```python
from starlette.middleware import Middleware
from .auth.middleware import UserTokenMiddleware

class JiraMCP(FastMCP):
    def http_app(self, path=None, middleware=None, transport="streamable-http"):
        user_token_mw = Middleware(UserTokenMiddleware)
        final_middleware = [user_token_mw]
        if middleware:
            final_middleware.extend(middleware)
        return super().http_app(path=path, middleware=final_middleware, transport=transport)
```

**Create `src/jira_mcp/dependencies.py`**

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/servers/dependencies.py`

```python
from fastmcp import Context
from .jira.client import JiraFetcher

async def get_jira_fetcher(ctx: Context) -> JiraFetcher:
    """Get Jira client with per-request auth override."""
    request = getattr(ctx, "request", None)

    # Check for per-request token
    if request and hasattr(request.state, "user_atlassian_token"):
        return JiraFetcher.from_token(
            request.state.user_atlassian_token,
            request.state.user_atlassian_auth_type
        )

    # Fall back to server config
    config = ctx.lifespan_context.get("jira_config")
    return JiraFetcher.from_config(config)
```

### Day 7-8: Remaining Core Tools

Add to `src/jira_mcp/tools/jira_tools.py`:

```python
@jira_mcp.tool(tags={"jira", "write"})
async def jira_update_issue(
    ctx: Context,
    issue_key: str,
    fields: dict,
) -> str:
    """Update Jira issue."""
    jira = await get_jira_fetcher(ctx)
    jira.jira.update_issue_field(issue_key, fields)
    return json.dumps({"success": True, "issue_key": issue_key})

@jira_mcp.tool(tags={"jira", "write"})
async def jira_add_comment(
    ctx: Context,
    issue_key: str,
    comment: str,
) -> str:
    """Add comment to Jira issue."""
    jira = await get_jira_fetcher(ctx)
    jira.jira.issue_add_comment(issue_key, comment)
    return json.dumps({"success": True})

@jira_mcp.tool(tags={"jira", "write"})
async def jira_transition_issue(
    ctx: Context,
    issue_key: str,
    transition_name: str,
) -> str:
    """Transition Jira issue status."""
    jira = await get_jira_fetcher(ctx)

    # Get available transitions
    transitions = jira.jira.get_issue_transitions(issue_key)
    transition_id = None

    for t in transitions:
        if t['name'].lower() == transition_name.lower():
            transition_id = t['id']
            break

    if not transition_id:
        return json.dumps({"error": f"Transition '{transition_name}' not found"})

    jira.jira.set_issue_status(issue_key, transition_id)
    return json.dumps({"success": True})
```

### Day 8-10: Tool Filtering & Write Protection

**Create `src/jira_mcp/utils/decorators.py`**

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/utils/decorators.py`

```python
from functools import wraps
from fastmcp import Context
from .env import is_read_only_mode

def check_write_access(func):
    """Decorator to check if write operations are allowed."""
    @wraps(func)
    async def wrapper(ctx: Context, *args, **kwargs):
        if is_read_only_mode():
            raise PermissionError("Server is in read-only mode")
        return await func(ctx, *args, **kwargs)
    return wrapper
```

Apply to write tools:
```python
from ..utils.decorators import check_write_access

@jira_mcp.tool(tags={"jira", "write"})
@check_write_access
async def jira_create_issue(...):
    ...
```

**Implement tool filtering in `JiraMCP._mcp_list_tools()`**

Port from: `/tmp/mcp-atlassian/src/mcp_atlassian/servers/main.py` (lines 109-186)

### Week 2 Deliverables
- ✅ All 6 core tools working
- ✅ Per-request authentication
- ✅ Tool filtering (read-only mode, enabled_tools)
- ✅ Write protection decorator

---

## Week 3: Testing

### Unit Tests

**Create `tests/unit/test_jira_config.py`**
```python
import pytest
from jira_mcp.config.jira_config import JiraConfig

def test_config_from_env(monkeypatch):
    monkeypatch.setenv("JIRA_URL", "https://test.atlassian.net")
    monkeypatch.setenv("JIRA_USERNAME", "test@test.com")
    monkeypatch.setenv("JIRA_API_TOKEN", "token123")

    config = JiraConfig.from_env()
    assert config.url == "https://test.atlassian.net"
    assert config.is_auth_configured()
```

**Create `tests/unit/test_jira_client.py`**
**Create `tests/unit/test_tools.py`**

### Integration Tests

**Create `tests/integration/test_mcp_server.py`**
```python
import pytest
from mcp import ClientSession
from mcp.client.stdio import stdio_client

@pytest.mark.asyncio
async def test_mcp_server_tools():
    async with stdio_client(["python", "-m", "jira_mcp"]) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()

            tools = await session.list_tools()
            assert len(tools) >= 6

            # Test search
            result = await session.call_tool("jira_search", {"jql": "project = TEST"})
            assert result is not None
```

### Week 3 Deliverables
- ✅ 80%+ test coverage
- ✅ All tests passing
- ✅ Integration tests with real Jira

---

## Week 4: Docker & CI/CD

### Dockerfile

```dockerfile
FROM python:3.12-slim AS builder

WORKDIR /app
COPY pyproject.toml .
COPY src/ src/

RUN pip install --no-cache-dir build && \
    python -m build

FROM python:3.12-slim

RUN useradd -m -u 1000 appuser
WORKDIR /app

COPY --from=builder /app/dist/*.whl .
RUN pip install --no-cache-dir *.whl && rm *.whl

USER appuser
EXPOSE 8000

HEALTHCHECK CMD curl -f http://localhost:8000/healthz || exit 1

CMD ["python", "-m", "jira_mcp", "--transport", "streamable-http", "--port", "8000"]
```

### GitHub Actions CI/CD

**Create `.github/workflows/deploy.yml`**

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Log in to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Build and push to ACR
        run: |
          az acr login --name ${{ secrets.ACR_NAME }}
          docker build -t ${{ secrets.ACR_NAME }}.azurecr.io/jira-mcp-server:${{ github.sha }} .
          docker push ${{ secrets.ACR_NAME }}.azurecr.io/jira-mcp-server:${{ github.sha }}

      - name: Deploy to Container Apps
        run: |
          az containerapp update \
            --name jira-mcp-server \
            --resource-group ${{ secrets.RESOURCE_GROUP }} \
            --image ${{ secrets.ACR_NAME }}.azurecr.io/jira-mcp-server:${{ github.sha }}
```

### Week 4 Deliverables
- ✅ Docker image builds successfully
- ✅ CI/CD pipeline working
- ✅ Automated tests in CI

---

## Week 5: Azure Deployment & Monitoring

### Azure Resources Setup

```bash
# Create resource group
az group create --name jira-mcp-rg --location eastus2

# Create Container Apps environment
az containerapp env create \
  --name jira-mcp-env \
  --resource-group jira-mcp-rg \
  --location eastus2

# Create Azure Container Registry
az acr create \
  --resource-group jira-mcp-rg \
  --name jiramcpacr \
  --sku Basic

# Create Key Vault
az keyvault create \
  --name jira-mcp-kv \
  --resource-group jira-mcp-rg \
  --location eastus2

# Add secrets
az keyvault secret set \
  --vault-name jira-mcp-kv \
  --name jira-api-token \
  --value "your-token"
```

### Deploy to Container Apps

```bash
# Build and push
docker build -t jiramcpacr.azurecr.io/jira-mcp-server:latest .
az acr login --name jiramcpacr
docker push jiramcpacr.azurecr.io/jira-mcp-server:latest

# Create managed identity
az identity create \
  --resource-group jira-mcp-rg \
  --name jira-mcp-identity

# Deploy
az containerapp create \
  --name jira-mcp-server \
  --resource-group jira-mcp-rg \
  --environment jira-mcp-env \
  --image jiramcpacr.azurecr.io/jira-mcp-server:latest \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 0.5 --memory 1.0Gi \
  --registry-server jiramcpacr.azurecr.io \
  --registry-identity system \
  --secrets \
    jira-token=keyvaultref:https://jira-mcp-kv.vault.azure.net/secrets/jira-api-token,identityref:system \
  --env-vars \
    JIRA_URL=https://your-domain.atlassian.net \
    JIRA_USERNAME=sa.jira.mscopilot.uat@ifs.com \
    JIRA_API_TOKEN=secretref:jira-token \
    TRANSPORT=streamable-http \
    PORT=8000
```

### Application Insights

```bash
# Create Application Insights
az monitor app-insights component create \
  --app jira-mcp-insights \
  --location eastus2 \
  --resource-group jira-mcp-rg

# Get instrumentation key
INSIGHTS_KEY=$(az monitor app-insights component show \
  --app jira-mcp-insights \
  --resource-group jira-mcp-rg \
  --query instrumentationKey -o tsv)

# Update container app
az containerapp update \
  --name jira-mcp-server \
  --resource-group jira-mcp-rg \
  --set-env-vars APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$INSIGHTS_KEY"
```

### Week 5 Deliverables
- ✅ Deployed to Azure Container Apps
- ✅ Public endpoint: `https://jira-mcp-server.azurecontainerapps.io/mcp`
- ✅ Health check responding
- ✅ Monitoring with Application Insights
- ✅ Auto-scaling configured
- ✅ Documentation complete

---

## Phase 1 Acceptance Criteria

Before moving to Phase 2, verify:

1. **Functionality**
   - [ ] All 6 core tools working correctly
   - [ ] JQL search returns accurate results
   - [ ] Can create issues in test Jira project
   - [ ] Can update issues
   - [ ] Can add comments
   - [ ] Can transition issues

2. **Authentication**
   - [ ] PAT authentication working
   - [ ] API token authentication working
   - [ ] Per-request token override working
   - [ ] Multi-cloud ID header working

3. **Deployment**
   - [ ] Deployed to Azure Container Apps
   - [ ] Public endpoint accessible
   - [ ] HTTPS working
   - [ ] Health check responding
   - [ ] No errors in logs

4. **Performance**
   - [ ] Sub-500ms p95 latency
   - [ ] Can handle 100 concurrent requests
   - [ ] Auto-scaling working

5. **Testing**
   - [ ] 80%+ test coverage
   - [ ] All tests passing
   - [ ] Tested with MCP Inspector
   - [ ] Tested with Claude Desktop
   - [ ] Tested with Microsoft Agent (optional)

6. **Documentation**
   - [ ] README.md complete
   - [ ] API documentation
   - [ ] Deployment guide
   - [ ] Troubleshooting guide

---

## Testing Phase 1 Before Phase 2

### Test with MCP Inspector
```bash
npx @modelcontextprotocol/inspector \
  --url https://jira-mcp-server.azurecontainerapps.io/mcp \
  --header "Authorization: Bearer YOUR_TOKEN"
```

### Test with Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "jira-mcp": {
      "url": "https://jira-mcp-server.azurecontainerapps.io/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_TOKEN"
      }
    }
  }
}
```

Then ask Claude:
- "Search for all bugs in project JB"
- "Create a new task in project JB with summary 'Test task'"
- "Add a comment to JB-123 saying 'Test comment'"

### Test with cURL

```bash
# Health check
curl https://jira-mcp-server.azurecontainerapps.io/healthz

# Initialize MCP session
curl -X POST https://jira-mcp-server.azurecontainerapps.io/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}'

# List tools
curl -X POST https://jira-mcp-server.azurecontainerapps.io/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}'

# Call jira_search
curl -X POST https://jira-mcp-server.azurecontainerapps.io/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"jira_search","arguments":{"jql":"project=JB"}},"id":3}'
```

---

## Ready for Phase 2

Once all acceptance criteria are met, you're ready to start Phase 2 (Frontend).

Phase 1 provides a solid, tested, production-ready backend that Phase 2 can build on with confidence.
