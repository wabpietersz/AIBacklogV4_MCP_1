# Microsoft Agent Framework Analysis

**Date**: Pre-Day 1 (Final Review)
**Status**: ✅ Architecture Validated Against Microsoft's Approach

---

## Executive Summary

After analyzing Microsoft's Agent Framework repository, our planned architecture is **fundamentally sound** but can be **significantly simplified** by adopting Microsoft's proven MCP integration patterns while keeping our persona-based permission system.

**Key Finding**: Microsoft uses a **decentralized, tool-centric approach** rather than a centralized MCPClientManager. This is simpler and proven at scale.

**Recommendation**: Adopt **Hybrid Approach** - Use Microsoft's MCPTool pattern + Our Persona system

---

## Microsoft Agent Framework - Key Insights

### Package Structure

```
agent-framework-core (v1.0.0b251114)
├── Python 3.10+
├── Built-in MCP support (mcp[ws]>=1.13)
├── OpenTelemetry integration
└── Pydantic v2 for schemas
```

**Dependencies We Should Add**:
```python
# Our pyproject.toml should include:
"opentelemetry-api>=1.24",
"opentelemetry-sdk>=1.24",
"opentelemetry-exporter-otlp-proto-grpc>=1.36.0",
"opentelemetry-semantic-conventions-ai>=0.4.13",
"mcp[ws]>=1.13",  # We had this
```

---

## MCP Integration Patterns

### Microsoft's Approach: Three MCP Tool Classes

```python
# 1. MCPStdioTool - For local subprocess MCP servers
from agent_framework import MCPStdioTool

jira_mcp = MCPStdioTool(
    name="jira",
    command="npx",
    args=["-y", "@modelcontextprotocol/server-jira"],
    allowed_tools=["search_issues", "create_issue"]  # Built-in filtering
)

# 2. MCPStreamableHTTPTool - For HTTP/SSE MCP servers (what we planned)
from agent_framework import MCPStreamableHTTPTool

jira_mcp = MCPStreamableHTTPTool(
    name="jira",
    url="https://jira-mcp-server.azurecontainerapps.io/mcp",
    headers={"Authorization": f"Bearer {token}"},
    allowed_tools=["search_issues", "create_issue"]
)

# 3. MCPWebsocketTool - For WebSocket MCP servers
from agent_framework import MCPWebsocketTool

jira_mcp = MCPWebsocketTool(
    name="jira",
    url="wss://jira-mcp-server.example.com",
    allowed_tools=["search_issues", "create_issue"]
)
```

### Key Pattern: Auto-Expansion

```python
# When MCPTool is passed to agent, it auto-expands
agent = ChatAgent(
    chat_client=OpenAIChatClient(),
    tools=jira_mcp  # MCPTool instance
)

# Internally:
# 1. Connects to MCP server (if not connected)
# 2. Loads all tools from server
# 3. Converts each MCP tool → AIFunction
# 4. Filters by allowed_tools
# 5. Agent sees list of AIFunction instances
```

---

## Architecture Comparison

### Our Original Plan (Centralized)

```python
# Week 1 - Centralized approach
class MCPClientManager:
    """Manages connections to multiple MCP servers"""

    def __init__(self):
        self.servers: Dict[str, MCPServer] = {}
        self.sessions: Dict[str, ClientSession] = {}
        self.tools_cache: Dict[str, list] = {}

    async def connect(self, server_name: str) -> ClientSession:
        """Centralized connection management"""

    async def call_tool(self, server: str, tool: str, params: dict):
        """Centralized tool execution"""

class ToolRegistry:
    """Registry of all available tools"""

    def register_from_mcp(self, server: str, tools: list):
        """Register tools from MCP server"""

    def get_tools_for_persona(self, persona: Persona) -> List[Tool]:
        """Filter tools by persona"""
```

**Pros**:
- Centralized control
- Connection pooling
- Cross-server coordination

**Cons**:
- More complex
- More code to maintain
- Not following Microsoft's pattern

---

### Microsoft's Approach (Decentralized)

```python
# Microsoft's pattern - Each tool self-manages
class MCPTool:
    """Base class for MCP integrations"""

    def __init__(self, name: str, allowed_tools: list = None):
        self.name = name
        self.allowed_tools = allowed_tools
        self.session: ClientSession = None
        self._functions: List[AIFunction] = []

    async def connect(self):
        """Each tool manages own connection"""
        # Establishes session
        # Loads tools from server
        # Converts to AIFunctions

    @property
    def functions(self) -> List[AIFunction]:
        """Returns filtered list of tools"""
        if not self.allowed_tools:
            return self._functions
        return [f for f in self._functions
                if f.name in self.allowed_tools]

# Subclasses
class MCPStdioTool(MCPTool):
    def __init__(self, command: str, args: list, **kwargs):
        # stdio-specific implementation

class MCPStreamableHTTPTool(MCPTool):
    def __init__(self, url: str, headers: dict = None, **kwargs):
        # HTTP-specific implementation
```

**Pros**:
- Simpler
- Self-contained
- Proven at Microsoft scale
- Less coupling

**Cons**:
- Potential duplicate connections
- Less centralized control

---

## Recommended Hybrid Approach

**Best of both worlds**: Microsoft's MCPTool pattern + Our Persona system

### Updated Architecture

```python
# foundation/mcp/mcp_tool.py
# Re-export Microsoft's classes with minimal wrapper
from agent_framework import (
    MCPStdioTool,
    MCPStreamableHTTPTool,
    MCPWebsocketTool
)

__all__ = ["MCPStdioTool", "MCPStreamableHTTPTool", "MCPWebsocketTool"]
```

```python
# foundation/mcp/server_registry.py
from dataclasses import dataclass
from typing import Dict, Optional

@dataclass
class MCPServerConfig:
    """Configuration for an MCP server"""
    name: str
    transport: str  # "stdio", "http", "websocket"

    # For stdio
    command: Optional[str] = None
    args: Optional[list] = None

    # For HTTP/WebSocket
    url: Optional[str] = None
    headers: Optional[Dict[str, str]] = None

class MCPServerRegistry:
    """Registry for MCP server configurations (NOT sessions)"""

    def __init__(self):
        self._configs: Dict[str, MCPServerConfig] = {}

    def register_config(self, config: MCPServerConfig):
        """Register server configuration"""
        self._configs[config.name] = config

    def get_config(self, name: str) -> MCPServerConfig:
        """Get server configuration"""
        return self._configs[name]

    def create_tool(self, server_name: str,
                    allowed_tools: list = None) -> MCPTool:
        """Factory method to create MCPTool instance"""
        config = self._configs[server_name]

        if config.transport == "stdio":
            return MCPStdioTool(
                name=config.name,
                command=config.command,
                args=config.args,
                allowed_tools=allowed_tools
            )
        elif config.transport == "http":
            return MCPStreamableHTTPTool(
                name=config.name,
                url=config.url,
                headers=config.headers,
                allowed_tools=allowed_tools
            )
        elif config.transport == "websocket":
            return MCPWebsocketTool(
                name=config.name,
                url=config.url,
                allowed_tools=allowed_tools
            )
```

```python
# foundation/agents/persona_mcp_mapper.py
from typing import List
from .persona import Persona
from ..mcp.server_registry import MCPServerRegistry

class PersonaMCPMapper:
    """Maps Persona permissions to MCP tool configurations"""

    def __init__(self, registry: MCPServerRegistry):
        self.registry = registry

    def get_mcp_tool_for_persona(
        self,
        persona: Persona,
        server_name: str
    ) -> MCPTool:
        """
        Create MCP tool filtered for persona's allowed tools.

        Example:
            persona = Persona(
                name="general_user",
                allowed_tools=["jira_search", "jira_create_issue"]
            )

            tool = mapper.get_mcp_tool_for_persona(persona, "jira")
            # Returns MCPTool with only search and create allowed
        """
        # Get tools this persona can use from this server
        allowed_tools = [
            tool for tool in persona.allowed_tools
            if tool.startswith(f"{server_name}_")
        ]

        # Create filtered tool instance
        return self.registry.create_tool(
            server_name=server_name,
            allowed_tools=allowed_tools
        )
```

### Usage Example

```python
# Week 1: Setup registry
registry = MCPServerRegistry()
registry.register_config(MCPServerConfig(
    name="jira",
    transport="http",
    url="https://jira-mcp-server.azurecontainerapps.io/mcp",
    headers={"Authorization": f"Bearer {token}"}
))

# Week 3: Create persona agents
from agents.jira.persona_configs import GENERAL_USER_PERSONA

mapper = PersonaMCPMapper(registry)

# Get Jira MCP tool filtered for general user
jira_tool = mapper.get_mcp_tool_for_persona(
    GENERAL_USER_PERSONA,
    "jira"
)

# Create agent with filtered tool
general_user_agent = ChatAgent(
    chat_client=OpenAIChatClient(),
    name="GeneralUserAgent",
    tools=jira_tool  # Auto-expands to allowed AIFunctions only
)
```

---

## Updated Component Design

### Week 1: Foundation Layer

**Simplified Structure**:
```
src/foundation/
├── agents/
│   ├── base_agent.py          # Minimal wrapper around ChatAgent
│   ├── persona.py             # Keep as-is
│   └── agent_response.py      # Keep as-is
├── mcp/
│   ├── __init__.py           # Re-export Microsoft's MCPTool classes
│   ├── server_registry.py    # Configuration registry (not session manager)
│   └── persona_mapper.py     # Map Persona → allowed_tools
└── auth/
    ├── permission_checker.py  # Simplified - mainly for JQL filtering
    └── azure_ad_auth.py      # Keep as-is
```

**What Changed**:
- ❌ Removed: `MCPClientManager` (complex session management)
- ❌ Removed: `ToolRegistry` (Microsoft's MCPTool handles this)
- ✅ Added: `MCPServerRegistry` (simple config registry)
- ✅ Added: `PersonaMCPMapper` (persona → allowed_tools mapping)
- ✅ Simplified: Use Microsoft's MCPTool classes directly

---

## Permission System Mapping

### Our Persona Concept → Microsoft's Patterns

```python
# Our Persona
@dataclass
class Persona:
    name: str
    permissions: List[Permission]
    allowed_tools: List[str]  # Maps to MCPTool.allowed_tools ✅

# Maps to Microsoft's approval_mode
approval_mode_mapping = {
    "general_user": {
        "always_require_approval": [
            "jira_delete_issue",
            "jira_assign_issue"
        ],
        "never_require_approval": [
            "jira_search",
            "jira_get_issue",
            "jira_create_issue"
        ]
    },
    "admin": {
        "never_require_approval": ["*"]  # All tools allowed
    }
}

# Combined approach
jira_tool = MCPStreamableHTTPTool(
    name="jira",
    url="...",
    allowed_tools=persona.allowed_tools,  # From Persona
    approval_mode=approval_mode_mapping[persona.name]  # Permission control
)
```

---

## Code Examples

### Example 1: General User Agent (Simplified)

```python
# agents/jira/general_user_agent.py
from agent_framework import ChatAgent
from agent_framework.openai import OpenAIChatClient
from foundation.mcp.server_registry import MCPServerRegistry
from foundation.mcp.persona_mapper import PersonaMCPMapper
from .persona_configs import GENERAL_USER_PERSONA

class GeneralUserAgent:
    """Agent for general users with limited Jira permissions"""

    def __init__(
        self,
        registry: MCPServerRegistry,
        chat_client: OpenAIChatClient
    ):
        self.registry = registry
        self.chat_client = chat_client
        self.mapper = PersonaMCPMapper(registry)

    async def create_agent(self) -> ChatAgent:
        """Create ChatAgent with persona-filtered MCP tools"""

        # Get Jira tool filtered for general user
        jira_tool = self.mapper.get_mcp_tool_for_persona(
            GENERAL_USER_PERSONA,
            "jira"
        )

        # Create agent with filtered tool
        agent = ChatAgent(
            chat_client=self.chat_client,
            name="GeneralUserAgent",
            instructions="""
            You are a helpful Jira assistant for general users.
            You can help with:
            - Searching issues
            - Creating new issues
            - Adding comments
            - Updating assigned issues

            You cannot:
            - Delete issues
            - Assign issues to others
            - Manage sprints
            """,
            tools=jira_tool  # MCPTool auto-expands
        )

        return agent
```

### Example 2: Orchestrator (Simplified)

```python
# orchestration/orchestrator.py
from typing import Dict
from agent_framework import ChatAgent
from foundation.agents.persona import Persona

class OrchestratorAgent:
    """Routes requests to appropriate persona agents"""

    def __init__(self):
        self.persona_agents: Dict[str, ChatAgent] = {}

    def register_agent(self, persona_name: str, agent: ChatAgent):
        """Register a persona agent"""
        self.persona_agents[persona_name] = agent

    async def execute(self, task: str, user_context: Dict) -> str:
        """Route to appropriate persona agent"""
        persona_name = user_context.get("persona", "general_user")

        agent = self.persona_agents.get(persona_name)
        if not agent:
            raise ValueError(f"Unknown persona: {persona_name}")

        # Direct execution - ChatAgent handles everything
        result = await agent.run(task)
        return result
```

---

## Updated Dependencies

### Add to pyproject.toml

```toml
dependencies = [
    # Core frameworks
    "fastapi>=0.104.0",
    "uvicorn[standard]>=0.24.0",
    "pydantic>=2.5.0",

    # Microsoft Agent Framework 🆕
    "agent-framework-core>=1.0.0b251114",  # Core package
    "agent-framework-azure-ai",             # Azure AI integration

    # OR if using meta-package
    # "agent-framework>=1.0.0b251114",  # Includes all sub-packages

    # OpenTelemetry (included in agent-framework-core)
    # "opentelemetry-api>=1.24",
    # "opentelemetry-sdk>=1.24",

    # MCP (included in agent-framework-core)
    # "mcp[ws]>=1.13",

    # Azure SDK
    "azure-identity>=1.15.0",
    "azure-keyvault-secrets>=4.7.0",

    # Jira (for MCP server only)
    "atlassian-python-api>=3.41.0",

    # Utilities
    "python-dotenv>=1.0.0",
    "structlog>=23.2.0",
]
```

---

## Migration Path

### Week 1 Implementation Changes

**Old Plan** → **New Approach**

| Component | Old | New |
|-----------|-----|-----|
| MCP Integration | Custom `MCPClientManager` | Use Microsoft's `MCPTool` classes |
| Tool Registry | Custom `ToolRegistry` class | Built into `MCPTool` |
| Connection Management | Centralized pooling | Each tool self-manages |
| Tool Filtering | Registry-level | `allowed_tools` parameter |
| Persona Mapping | Custom integration | `PersonaMCPMapper` utility |

**What to Keep**:
- ✅ `Persona` and `Permission` classes - Core to our design
- ✅ `BaseAgent` abstract class - Adds structure
- ✅ `AgentResponse` - Standardized responses
- ✅ `PermissionChecker` - For JQL filtering and validation

**What to Simplify**:
- 🔄 `MCPClientManager` → `MCPServerRegistry` (config only)
- 🔄 `ToolRegistry` → Use MCPTool.functions property
- 🔄 Connection management → Use context managers

---

## Benefits of Hybrid Approach

### 1. Less Code to Write

**Old**: ~500 lines for MCPClientManager + ToolRegistry
**New**: ~150 lines for MCPServerRegistry + PersonaMCPMapper

**Savings**: 70% less code in Week 1!

### 2. Battle-Tested Pattern

- Microsoft's MCPTool is used in production
- Handles edge cases we haven't thought of
- Community support and updates

### 3. Keep Our Innovation

- Persona system is still our unique approach
- Permission granularity preserved
- JQL auto-filtering maintained

### 4. Easier Maintenance

- Less custom code to debug
- Updates from Microsoft for free
- Standard patterns for team understanding

---

## Testing Strategy Update

### Week 1 Tests (Simplified)

```python
# Old plan - Test custom MCPClientManager
def test_mcp_client_manager_connection():
    manager = MCPClientManager()
    await manager.connect("jira")
    assert manager.sessions["jira"] is not None

# New approach - Test persona mapping
def test_persona_mcp_mapper():
    registry = MCPServerRegistry()
    registry.register_config(jira_config)

    mapper = PersonaMCPMapper(registry)
    tool = mapper.get_mcp_tool_for_persona(
        GENERAL_USER_PERSONA,
        "jira"
    )

    assert tool.allowed_tools == [
        "jira_search",
        "jira_create_issue",
        "jira_add_comment"
    ]
```

---

## Risks and Mitigations

### Risk 1: Dependency on Microsoft's Package

**Risk**: Microsoft could deprecate or change API
**Mitigation**:
- Use stable v1.0+ release
- Pin version in pyproject.toml
- Our PersonaMCPMapper isolates most of our code from changes

### Risk 2: Missing Features

**Risk**: Microsoft's MCPTool might not have all features we need
**Mitigation**:
- Can extend their classes if needed
- Most features already there (approval_mode, allowed_tools, etc.)

### Risk 3: Learning Curve

**Risk**: Team needs to learn Microsoft's patterns
**Mitigation**:
- Excellent documentation at https://learn.microsoft.com/agent-framework
- Lots of samples in their repo
- Simpler than our custom implementation

---

## Final Recommendation

### ✅ Adopt Hybrid Approach

**Use Microsoft Agent Framework as foundation:**
```python
from agent_framework import ChatAgent, MCPStreamableHTTPTool
from agent_framework.openai import OpenAIChatClient
```

**Add our persona layer on top:**
```python
from foundation.agents.persona import Persona, Permission
from foundation.mcp.persona_mapper import PersonaMCPMapper
```

**Result**:
- 70% less code in Week 1
- Battle-tested MCP integration
- Keep our unique persona-based approach
- Production-ready from day 1

---

## Next Steps

1. ✅ Update AGENT_IMPLEMENTATION_PLAN.md Week 1 with simplified approach
2. ✅ Update pyproject.toml with agent-framework dependency
3. ✅ Update .cursorrules with Microsoft's patterns
4. ✅ Simplify Week 1 deliverables in MASTER_PLAN.md

---

**This analysis validates our architecture and simplifies Week 1 by 70%!** 🎉
