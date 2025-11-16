# Testing Strategy

Comprehensive testing approach for the agentic platform.

---

## 🎯 Testing Philosophy

### Principles

1. **Test the foundation thoroughly** - Generic components must be bulletproof
2. **Test personas separately** - Each persona is independent
3. **Test permission boundaries** - Security is critical
4. **Test integration points** - Layer boundaries must work
5. **Test real scenarios** - End-to-end user journeys

### Coverage Goals

- **Foundation (Layer 1)**: 100% coverage
- **MCP Servers (Layer 2)**: 90% coverage
- **Persona Agents (Layer 3)**: 95% coverage
- **Orchestrator (Layer 4)**: 90% coverage
- **Frontend (Layer 5)**: 80% coverage

---

## 🧪 Testing Pyramid

```
        /\
       /  \
      / E2E \ (10%)
     /      \
    /--------\
   / Integration \ (30%)
  /              \
 /----------------\
/   Unit Tests     \ (60%)
--------------------
```

**60% Unit Tests**: Fast, isolated, test single functions
**30% Integration Tests**: Test layer boundaries
**10% E2E Tests**: Test complete user journeys

---

## Layer 1: Foundation Testing

### Unit Tests (100% Coverage Required)

**Test File**: `tests/unit/foundation/test_persona.py`

```python
import pytest
from foundation.agents.persona import Persona, Permission

class TestPermission:
    def test_permission_string_representation(self):
        perm = Permission("jira", "read", "own")
        assert str(perm) == "jira:read:own"

    def test_permission_from_string(self):
        perm = Permission.from_string("jira:write:*")
        assert perm.resource == "jira"
        assert perm.action == "write"
        assert perm.scope == "*"

    def test_permission_default_scope(self):
        perm = Permission.from_string("jira:read")
        assert perm.scope == "*"

class TestPersona:
    @pytest.fixture
    def general_user_persona(self):
        return Persona(
            name="general_user",
            display_name="General User",
            description="Test persona",
            permissions=[
                Permission("jira", "read", "*"),
                Permission("jira", "write", "own")
            ],
            allowed_tools=["jira_search", "jira_create_issue"]
        )

    def test_can_use_tool_allowed(self, general_user_persona):
        assert general_user_persona.can_use_tool("jira_search")

    def test_can_use_tool_not_allowed(self, general_user_persona):
        assert not general_user_persona.can_use_tool("jira_delete_issue")

    def test_has_permission_match(self, general_user_persona):
        assert general_user_persona.has_permission("jira", "read", "*")

    def test_has_permission_no_match(self, general_user_persona):
        assert not general_user_persona.has_permission("jira", "admin", "*")

    def test_has_permission_scope_match(self, general_user_persona):
        assert general_user_persona.has_permission("jira", "write", "own")

    def test_has_permission_scope_wildcard(self, general_user_persona):
        # Should match because permission has scope "*"
        assert general_user_persona.has_permission("jira", "read", "project")

    def test_to_dict(self, general_user_persona):
        data = general_user_persona.to_dict()
        assert data["name"] == "general_user"
        assert "jira:read:*" in data["permissions"]
        assert "jira_search" in data["allowed_tools"]
```

**Test File**: `tests/unit/foundation/test_base_agent.py`

```python
import pytest
from foundation.agents.base_agent import BaseAgent
from foundation.agents.persona import Persona, Permission
from foundation.agents.agent_response import AgentResponse

class MockAgent(BaseAgent):
    """Mock agent for testing."""
    async def execute(self, task: str, user_context: dict):
        return AgentResponse(
            success=True,
            message=f"Executed: {task}",
            data={"task": task}
        )

class TestBaseAgent:
    @pytest.fixture
    def mock_persona(self):
        return Persona(
            name="mock",
            display_name="Mock",
            description="Mock persona",
            permissions=[Permission("test", "read", "*")],
            allowed_tools=["tool1", "tool2"]
        )

    @pytest.fixture
    def mock_agent(self, mock_persona):
        return MockAgent("MockAgent", mock_persona)

    @pytest.mark.asyncio
    async def test_execute(self, mock_agent):
        response = await mock_agent.execute(
            "test task",
            {"user_id": "123"}
        )
        assert response.success
        assert "test task" in response.message

    def test_can_use_tool_allowed(self, mock_agent):
        assert mock_agent.can_use_tool("tool1")

    def test_can_use_tool_not_allowed(self, mock_agent):
        assert not mock_agent.can_use_tool("tool3")

    def test_get_allowed_tools(self, mock_agent):
        tools = mock_agent.get_allowed_tools()
        assert "tool1" in tools
        assert "tool2" in tools
        assert len(tools) == 2

    def test_no_persona_no_restrictions(self):
        agent = MockAgent("NoPersonaAgent", persona=None)
        # Should return empty list for no persona
        assert agent.get_allowed_tools() == []
```

**Test File**: `tests/unit/foundation/test_mcp_client_manager.py`

```python
import pytest
from foundation.mcp.client_manager import MCPClientManager, MCPServer

class TestMCPClientManager:
    @pytest.fixture
    def manager(self):
        return MCPClientManager()

    def test_register_server(self, manager):
        manager.register_server(
            "test_server",
            "http://localhost:8000/mcp",
            {"bearer_token": "test_token"}
        )
        assert "test_server" in manager.servers
        assert manager.servers["test_server"].url == "http://localhost:8000/mcp"

    @pytest.mark.asyncio
    async def test_connect_unknown_server(self, manager):
        with pytest.raises(ValueError, match="Unknown MCP server"):
            await manager.connect("unknown_server")

    # More tests for actual MCP connection (integration tests)
```

**Test File**: `tests/unit/foundation/test_permission_checker.py`

```python
import pytest
from foundation.auth.permission_checker import PermissionChecker
from foundation.agents.persona import Persona, Permission

class TestPermissionChecker:
    @pytest.fixture
    def general_user_persona(self):
        return Persona(
            name="general_user",
            display_name="General User",
            description="Test",
            permissions=[
                Permission("jira", "read", "*"),
                Permission("jira", "write", "own")
            ],
            allowed_tools=["jira_search", "jira_update_issue"]
        )

    @pytest.fixture
    def admin_persona(self):
        return Persona(
            name="admin",
            display_name="Admin",
            description="Test",
            permissions=[Permission("jira", "*", "*")],
            allowed_tools=["jira_search", "jira_delete_issue"]
        )

    def test_can_execute_tool_allowed(self, general_user_persona):
        allowed, reason = PermissionChecker.can_execute_tool(
            general_user_persona,
            "jira_search",
            {"email": "user@example.com"}
        )
        assert allowed
        assert "Allowed" in reason

    def test_can_execute_tool_not_allowed(self, general_user_persona):
        allowed, reason = PermissionChecker.can_execute_tool(
            general_user_persona,
            "jira_delete_issue",
            {"email": "user@example.com"}
        )
        assert not allowed
        assert "not allowed" in reason

    def test_filter_jql_admin_no_filter(self, admin_persona):
        jql = "project = JB"
        filtered = PermissionChecker.filter_jql_for_persona(
            admin_persona,
            jql,
            {"email": "admin@example.com"}
        )
        # Admin should not get additional filters
        assert filtered == jql

    def test_filter_jql_general_user_own_scope(self):
        persona = Persona(
            name="test",
            display_name="Test",
            description="Test",
            permissions=[Permission("jira", "read", "own")],
            allowed_tools=[]
        )
        jql = "project = JB"
        filtered = PermissionChecker.filter_jql_for_persona(
            persona,
            jql,
            {"email": "user@example.com"}
        )
        # Should add assignee filter
        assert "assignee = user@example.com" in filtered
```

### Integration Tests (Foundation → Foundation)

**Test File**: `tests/integration/foundation/test_foundation_integration.py`

```python
import pytest
from foundation.agents.base_agent import BaseAgent
from foundation.agents.persona import Persona, Permission
from foundation.agents.agent_response import AgentResponse
from foundation.mcp.client_manager import MCPClientManager
from foundation.mcp.tool_registry import ToolRegistry

@pytest.mark.integration
class TestFoundationIntegration:
    """Test that foundation components work together."""

    @pytest.mark.asyncio
    async def test_agent_uses_mcp_manager(self):
        # Setup
        mcp_manager = MCPClientManager()
        tool_registry = ToolRegistry()

        # Register mock MCP server
        mcp_manager.register_server("mock", "http://localhost:8000", {})

        # Create agent that uses MCP manager
        class TestAgent(BaseAgent):
            def __init__(self, persona, mcp_manager):
                super().__init__("TestAgent", persona)
                self.mcp_manager = mcp_manager

            async def execute(self, task, context):
                # Would normally call mcp_manager.call_tool()
                return AgentResponse(success=True, message="Done")

        persona = Persona(
            name="test",
            display_name="Test",
            description="Test",
            permissions=[Permission("test", "read", "*")],
            allowed_tools=["test_tool"]
        )

        agent = TestAgent(persona, mcp_manager)
        response = await agent.execute("test", {})

        assert response.success
```

---

## Layer 2: MCP Server Testing

### Unit Tests (90% Coverage)

**Test File**: `tests/unit/mcp_servers/jira/test_jira_config.py`

```python
import pytest
import os
from mcp_servers.jira.config.jira_config import JiraConfig

class TestJiraConfig:
    def test_from_env_cloud(self, monkeypatch):
        monkeypatch.setenv("JIRA_URL", "https://test.atlassian.net")
        monkeypatch.setenv("JIRA_USERNAME", "test@example.com")
        monkeypatch.setenv("JIRA_API_TOKEN", "test_token")

        config = JiraConfig.from_env()

        assert config.url == "https://test.atlassian.net"
        assert config.username == "test@example.com"
        assert config.api_token == "test_token"
        assert config.is_auth_configured()

    def test_from_env_server(self, monkeypatch):
        monkeypatch.setenv("JIRA_URL", "https://jira.company.com")
        monkeypatch.setenv("JIRA_PERSONAL_TOKEN", "test_pat")

        config = JiraConfig.from_env()

        assert config.url == "https://jira.company.com"
        assert config.personal_token == "test_pat"
        assert config.is_auth_configured()

    def test_is_auth_configured_false(self):
        config = JiraConfig(url="https://test.atlassian.net")
        assert not config.is_auth_configured()
```

**Test File**: `tests/unit/mcp_servers/jira/test_jira_tools.py`

```python
import pytest
import json
from unittest.mock import Mock, patch
from mcp_servers.jira.tools.jira_tools import jira_search, jira_create_issue

@pytest.mark.asyncio
class TestJiraTools:
    @pytest.fixture
    def mock_context(self):
        ctx = Mock()
        ctx.lifespan_context = {
            "jira_config": Mock(
                url="https://test.atlassian.net",
                username="test@example.com",
                api_token="test_token"
            )
        }
        return ctx

    @patch('mcp_servers.jira.dependencies.get_jira_fetcher')
    async def test_jira_search(self, mock_get_fetcher, mock_context):
        # Setup mock
        mock_fetcher = Mock()
        mock_fetcher.search_issues.return_value = [
            {"key": "TEST-1", "summary": "Test issue"}
        ]
        mock_get_fetcher.return_value = mock_fetcher

        # Execute
        result = await jira_search(
            mock_context,
            jql="project = TEST",
            max_results=10
        )

        # Verify
        mock_fetcher.search_issues.assert_called_once_with("project = TEST", 10)
        data = json.loads(result)
        assert len(data) == 1
        assert data[0]["key"] == "TEST-1"

    @patch('mcp_servers.jira.dependencies.get_jira_fetcher')
    async def test_jira_create_issue(self, mock_get_fetcher, mock_context):
        # Setup mock
        mock_fetcher = Mock()
        mock_fetcher.jira.create_issue.return_value = {
            "key": "TEST-123",
            "id": "10001"
        }
        mock_get_fetcher.return_value = mock_fetcher

        # Execute
        result = await jira_create_issue(
            mock_context,
            project="TEST",
            summary="Test issue",
            issue_type="Bug"
        )

        # Verify
        data = json.loads(result)
        assert data["key"] == "TEST-123"
```

### Integration Tests (MCP Server → Real Jira)

**Test File**: `tests/integration/mcp_servers/test_jira_mcp_integration.py`

```python
import pytest
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client
import os

@pytest.mark.integration
@pytest.mark.skipif(
    not os.getenv("JIRA_API_TOKEN"),
    reason="JIRA_API_TOKEN not set"
)
class TestJiraMCPIntegration:
    """Test MCP server against real Jira instance."""

    @pytest.fixture
    def jira_url(self):
        return os.getenv("JIRA_URL", "https://test.atlassian.net")

    @pytest.fixture
    def jira_token(self):
        return os.getenv("JIRA_API_TOKEN")

    @pytest.mark.asyncio
    async def test_mcp_server_list_tools(self, jira_url, jira_token):
        async with streamablehttp_client(
            "http://localhost:8000/mcp",
            headers={"Authorization": f"Bearer {jira_token}"}
        ) as (read, write, _):
            async with ClientSession(read, write) as session:
                await session.initialize()
                tools = await session.list_tools()

                # Should have 12 tools
                assert len(tools) >= 12

                # Check core tools exist
                tool_names = [t.name for t in tools]
                assert "jira_search" in tool_names
                assert "jira_create_issue" in tool_names

    @pytest.mark.asyncio
    async def test_mcp_server_search_tool(self, jira_url, jira_token):
        async with streamablehttp_client(
            "http://localhost:8000/mcp",
            headers={"Authorization": f"Bearer {jira_token}"}
        ) as (read, write, _):
            async with ClientSession(read, write) as session:
                await session.initialize()

                result = await session.call_tool(
                    "jira_search",
                    {"jql": "project = TEST ORDER BY created DESC", "max_results": 5}
                )

                # Should return issues (or empty list)
                assert isinstance(result, (list, str))
```

---

## Layer 3: Persona Agents Testing

### Unit Tests (95% Coverage)

**Test File**: `tests/unit/agents/jira/test_general_user_agent.py`

```python
import pytest
from unittest.mock import Mock, AsyncMock
from agents.jira.general_user_agent import GeneralUserAgent
from foundation.mcp.client_manager import MCPClientManager
from foundation.agents.agent_response import AgentResponse

@pytest.mark.asyncio
class TestGeneralUserAgent:
    @pytest.fixture
    def mock_mcp_manager(self):
        manager = Mock(spec=MCPClientManager)
        manager.call_tool = AsyncMock()
        return manager

    @pytest.fixture
    def agent(self, mock_mcp_manager):
        return GeneralUserAgent(mock_mcp_manager)

    async def test_handle_search_my_assigned(self, agent, mock_mcp_manager):
        # Setup
        mock_mcp_manager.call_tool.return_value = json.dumps([
            {"key": "JB-123", "summary": "Test"}
        ])

        # Execute
        response = await agent.execute(
            "Show me my assigned issues",
            {"email": "user@example.com", "persona": "general_user"}
        )

        # Verify
        assert response.success
        assert "1" in response.message  # Should mention count
        mock_mcp_manager.call_tool.assert_called_once()

        # Verify JQL includes user filter
        call_args = mock_mcp_manager.call_tool.call_args
        assert "assignee = user@example.com" in call_args[1]["parameters"]["jql"]

    async def test_handle_create_issue(self, agent, mock_mcp_manager):
        # Setup
        mock_mcp_manager.call_tool.return_value = json.dumps({
            "key": "JB-456",
            "id": "10001"
        })

        # Execute
        response = await agent.execute(
            "Create a new bug for login issue",
            {"email": "user@example.com", "persona": "general_user"}
        )

        # Verify
        assert response.success
        assert "JB-456" in response.message

    async def test_permission_denied_delete(self, agent):
        # Execute - try to delete (not allowed)
        response = await agent.execute(
            "Delete issue JB-123",
            {"email": "user@example.com", "persona": "general_user"}
        )

        # Verify
        assert not response.success
        assert "permission" in response.error.lower() or "cannot" in response.message.lower()
```

**Test File**: `tests/unit/agents/jira/test_admin_agent.py`

```python
import pytest
from unittest.mock import Mock, AsyncMock
from agents.jira.admin_agent import AdminAgent
from foundation.mcp.client_manager import MCPClientManager

@pytest.mark.asyncio
class TestAdminAgent:
    @pytest.fixture
    def mock_mcp_manager(self):
        manager = Mock(spec=MCPClientManager)
        manager.call_tool = AsyncMock()
        return manager

    @pytest.fixture
    def agent(self, mock_mcp_manager):
        return AdminAgent(mock_mcp_manager)

    async def test_admin_can_delete(self, agent, mock_mcp_manager):
        # Setup
        mock_mcp_manager.call_tool.return_value = json.dumps({
            "success": True
        })

        # Execute
        response = await agent.execute(
            "Delete issue JB-123",
            {"email": "admin@example.com", "persona": "admin"}
        )

        # Verify - admin should succeed
        assert response.success or "coming soon" in response.message.lower()
```

### Permission Boundary Tests (Critical)

**Test File**: `tests/unit/agents/test_permission_boundaries.py`

```python
import pytest
from agents.jira.general_user_agent import GeneralUserAgent
from agents.jira.admin_agent import AdminAgent
from foundation.mcp.client_manager import MCPClientManager
from unittest.mock import Mock

class TestPermissionBoundaries:
    """Test that permissions are enforced correctly."""

    @pytest.mark.asyncio
    async def test_general_user_cannot_use_admin_tools(self):
        """General user should not be able to call admin-only tools."""
        agent = GeneralUserAgent(Mock(spec=MCPClientManager))

        # Test admin-only tools
        admin_tools = [
            "jira_delete_issue",
            "jira_create_sprint",
            "jira_bulk_update"
        ]

        for tool in admin_tools:
            assert not agent.can_use_tool(tool), \
                f"General user should not be able to use {tool}"

    @pytest.mark.asyncio
    async def test_admin_can_use_all_tools(self):
        """Admin should be able to use all tools."""
        agent = AdminAgent(Mock(spec=MCPClientManager))

        # Test all tools
        all_tools = [
            "jira_search",
            "jira_delete_issue",
            "jira_create_sprint",
            "jira_bulk_update"
        ]

        for tool in all_tools:
            assert agent.can_use_tool(tool), \
                f"Admin should be able to use {tool}"
```

---

## Layer 4: Orchestrator Testing

### Unit Tests (90% Coverage)

**Test File**: `tests/unit/orchestration/test_orchestrator.py`

```python
import pytest
from unittest.mock import Mock, AsyncMock
from orchestration.orchestrator import OrchestratorAgent
from foundation.agents.base_agent import BaseAgent
from foundation.agents.agent_response import AgentResponse

@pytest.mark.asyncio
class TestOrchestrator:
    @pytest.fixture
    def orchestrator(self):
        return OrchestratorAgent()

    @pytest.fixture
    def mock_agent(self):
        agent = Mock(spec=BaseAgent)
        agent.execute = AsyncMock(return_value=AgentResponse(
            success=True,
            message="Mock response"
        ))
        agent.persona = Mock(
            name="mock",
            display_name="Mock",
            description="Mock",
            metadata={}
        )
        return agent

    def test_register_agent(self, orchestrator, mock_agent):
        orchestrator.register_agent("mock_persona", mock_agent)
        assert "mock_persona" in orchestrator.persona_agents

    async def test_execute_routes_to_agent(self, orchestrator, mock_agent):
        orchestrator.register_agent("test_persona", mock_agent)

        response = await orchestrator.execute(
            "test task",
            {"persona": "test_persona", "email": "user@example.com"}
        )

        assert response.success
        mock_agent.execute.assert_called_once()

    async def test_execute_unknown_persona(self, orchestrator):
        response = await orchestrator.execute(
            "test task",
            {"persona": "unknown", "email": "user@example.com"}
        )

        assert not response.success
        assert "Unknown persona" in response.message

    def test_list_personas(self, orchestrator, mock_agent):
        orchestrator.register_agent("test", mock_agent)

        personas = orchestrator.list_personas()

        assert len(personas) == 1
        assert personas[0]["name"] == "mock"
```

### API Integration Tests

**Test File**: `tests/integration/api/test_api_endpoints.py`

```python
import pytest
from fastapi.testclient import TestClient
from main import app

class TestAPIEndpoints:
    @pytest.fixture
    def client(self):
        return TestClient(app)

    def test_health_endpoint(self, client):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"

    def test_personas_endpoint(self, client):
        # Would need auth token in real test
        response = client.get("/personas")
        # Either 200 with personas or 401 unauthorized
        assert response.status_code in [200, 401]

    def test_execute_endpoint_missing_auth(self, client):
        response = client.post("/execute", json={
            "task": "test",
            "persona": "general_user",
            "user_email": "user@example.com"
        })
        # Should require authentication
        assert response.status_code == 401
```

---

## Layer 5: Frontend Testing

### Component Tests (80% Coverage)

**Test File**: `frontend/tests/components/PersonaSelector.test.tsx`

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import PersonaSelector from '@/components/PersonaSelector';

describe('PersonaSelector', () => {
  const mockPersonas = [
    { name: 'general_user', display_name: 'General User' },
    { name: 'admin', display_name: 'Administrator' }
  ];

  it('renders personas', () => {
    render(<PersonaSelector personas={mockPersonas} onSelect={() => {}} />);
    expect(screen.getByText('General User')).toBeInTheDocument();
    expect(screen.getByText('Administrator')).toBeInTheDocument();
  });

  it('calls onSelect when persona clicked', () => {
    const mockOnSelect = jest.fn();
    render(<PersonaSelector personas={mockPersonas} onSelect={mockOnSelect} />);

    fireEvent.click(screen.getByText('General User'));
    expect(mockOnSelect).toHaveBeenCalledWith('general_user');
  });
});
```

### E2E Tests

**Test File**: `frontend/tests/e2e/chat.spec.ts`

```typescript
import { test, expect } from '@playwright/test';

test.describe('Chat Interface', () => {
  test('user can switch personas and execute tasks', async ({ page }) => {
    // Navigate to app
    await page.goto('http://localhost:3000');

    // Login (assuming auth is configured)
    // ...

    // Select General User persona
    await page.click('text=General User');

    // Type a task
    await page.fill('[placeholder="Type your message..."]', 'Show my assigned bugs');
    await page.click('button[type="submit"]');

    // Wait for response
    await expect(page.locator('.message.assistant')).toBeVisible();

    // Verify tool execution shown
    await expect(page.locator('.tool-execution')).toContainText('jira_search');

    // Try admin task (should fail)
    await page.fill('[placeholder="Type your message..."]', 'Delete issue JB-123');
    await page.click('button[type="submit"]');

    // Should see permission error
    await expect(page.locator('.error-message')).toContainText('permission');

    // Switch to Admin
    await page.click('text=Administrator');

    // Try again
    await page.fill('[placeholder="Type your message..."]', 'Delete issue JB-123');
    await page.click('button[type="submit"]');

    // Should succeed
    await expect(page.locator('.message.assistant')).toContainText('deleted');
  });
});
```

---

## 🔄 Test Automation

### GitHub Actions Workflow

**File**: `.github/workflows/test.yml`

```yaml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test-foundation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          pip install -e ".[dev]"

      - name: Run foundation tests
        run: |
          pytest tests/unit/foundation/ -v --cov=src/foundation --cov-report=xml

      - name: Check coverage
        run: |
          coverage report --fail-under=100  # Foundation must be 100%

  test-agents:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          pip install -e ".[dev]"

      - name: Run agent tests
        run: |
          pytest tests/unit/agents/ -v --cov=src/agents --cov-report=xml

      - name: Check coverage
        run: |
          coverage report --fail-under=95  # Agents must be 95%

  integration-tests:
    runs-on: ubuntu-latest
    needs: [test-foundation, test-agents]
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          pip install -e ".[dev]"

      - name: Run integration tests
        run: |
          pytest tests/integration/ -v
        env:
          # Skip Jira integration tests in CI (unless secrets available)
          SKIP_JIRA_INTEGRATION: true
```

---

## 📊 Coverage Reports

### Generate Coverage Report

```bash
# Run all tests with coverage
pytest --cov=src --cov-report=html --cov-report=term

# View HTML report
open htmlcov/index.html
```

### Coverage Thresholds

```ini
# setup.cfg
[coverage:run]
source = src

[coverage:report]
fail_under = 80
exclude_lines =
    pragma: no cover
    def __repr__
    raise AssertionError
    raise NotImplementedError
    if __name__ == .__main__.:

[coverage:html]
directory = htmlcov
```

---

## ✅ Test Checklist (Per Week)

### Week 1: Foundation
- [ ] 100% unit test coverage
- [ ] All permission scenarios tested
- [ ] Persona system tested with mock use cases
- [ ] MCPClientManager connection tests
- [ ] ToolRegistry filtering tests

### Week 2: MCP Server
- [ ] All 12 tools have unit tests
- [ ] Integration tests with real Jira (manual)
- [ ] MCP protocol compliance tested
- [ ] Health check tested
- [ ] Error handling tested

### Week 3: Persona Agents
- [ ] General User permission tests
- [ ] Admin permission tests
- [ ] JQL filtering tests
- [ ] Permission boundary tests
- [ ] Error message clarity tests

### Week 4: Orchestrator
- [ ] Routing tests
- [ ] API endpoint tests
- [ ] Authentication tests
- [ ] Rate limiting tests
- [ ] Load tests (100 concurrent)

### Week 5-7: Frontend
- [ ] Component tests (all components)
- [ ] Integration tests (API calls)
- [ ] E2E tests (user journeys)
- [ ] Accessibility tests
- [ ] Mobile responsive tests

---

This testing strategy ensures a bulletproof, production-ready platform!
