# Agent-Centric Implementation Plan

**Goal**: Build a generic, reusable agentic platform with Jira use case as first implementation

**Timeline**: 7 weeks (4 weeks backend + 3 weeks frontend)

---

## Phase 1: Backend (4 weeks)

### Week 1: Foundation Layer (Generic & Reusable) - SIMPLIFIED ⭐

**Updated based on Microsoft Agent Framework analysis** - See `MICROSOFT_FRAMEWORK_INTEGRATION_SUMMARY.md`

The foundation provides reusable components for ANY agentic solution. We now use Microsoft's Agent Framework for MCP integration, focusing our effort on the unique Persona system.

**Time**: 3 days (down from 5 days!)

#### Day 1: Project Structure + Persona System

```bash
# Create structure
mkdir -p src/{foundation,agents,orchestration,mcp_servers}
mkdir -p src/foundation/{agents,mcp,auth,utils}
mkdir -p src/agents/{jira,base}
mkdir -p src/mcp_servers/jira
mkdir -p tests/{unit,integration,fixtures}

# Install Microsoft Agent Framework
pip install agent-framework-core agent-framework-azure-ai --pre
```

**Simplified project structure**:
```
src/
├── foundation/              # Generic, reusable foundation
│   ├── agents/
│   │   ├── persona.py              # Persona + Permission (OUR VALUE)
│   │   └── agent_response.py       # Standardized response
│   ├── mcp/
│   │   ├── __init__.py             # Re-export Microsoft's classes
│   │   ├── server_registry.py      # Config storage (80 lines)
│   │   └── persona_mapper.py       # Persona → tools mapping (OUR VALUE)
│   ├── auth/
│   │   ├── permission_checker.py   # Simplified permissions
│   │   └── azure_ad_auth.py        # Azure AD provider
│   └── utils/
│       ├── logging.py
│       └── telemetry.py
├── agents/                  # Use case specific agents
│   ├── jira/
│   │   ├── general_user_agent.py   # Uses Microsoft's ChatAgent
│   │   ├── admin_agent.py
│   │   └── persona_configs.py      # Persona definitions
│   └── base/
│       └── llm_agent.py            # LLM integration
├── orchestration/           # Agent coordination
│   ├── orchestrator.py
│   └── router.py
└── mcp_servers/            # MCP server implementations
    └── jira/
        ├── server.py
        ├── tools/
        └── config/
```

**Key Changes**:
- ❌ **Removed**: `base_agent.py`, `client_manager.py`, `tool_registry.py` (replaced by Microsoft's framework)
- ✅ **Added**: `persona_mapper.py` (our unique innovation)
- ✅ **Simplified**: Foundation now ~220 lines vs ~550 lines

#### Day 1-2: Persona System (Our Core Innovation)

**Create `src/foundation/agents/persona.py`**:

```python
from dataclasses import dataclass
from typing import List, Dict, Optional

@dataclass
class Permission:
    """A single permission."""
    resource: str      # e.g., "jira"
    action: str        # e.g., "read", "write", "admin"
    scope: str = "*"   # e.g., "own", "project", "*"

    def __str__(self):
        return f"{self.resource}:{self.action}:{self.scope}"

    @classmethod
    def from_string(cls, perm_str: str) -> "Permission":
        """Parse permission string like 'jira:read:own'."""
        parts = perm_str.split(":")
        return cls(
            resource=parts[0],
            action=parts[1],
            scope=parts[2] if len(parts) > 2 else "*"
        )

@dataclass
class Persona:
    """Defines capabilities and permissions for an agent."""
    name: str
    display_name: str
    description: str
    permissions: List[Permission]
    allowed_tools: List[str]
    metadata: Dict = None

    def can_use_tool(self, tool_name: str) -> bool:
        """Check if persona can use a tool."""
        return tool_name in self.allowed_tools

    def has_permission(self, resource: str, action: str, scope: str = "*") -> bool:
        """Check if persona has a specific permission."""
        for perm in self.permissions:
            if perm.resource == resource and perm.action == action:
                if perm.scope == "*" or perm.scope == scope:
                    return True
        return False

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "display_name": self.display_name,
            "description": self.description,
            "permissions": [str(p) for p in self.permissions],
            "allowed_tools": self.allowed_tools,
            "metadata": self.metadata or {}
        }
```

**Create `src/foundation/agents/agent_response.py`**:

```python
from dataclasses import dataclass
from typing import Optional, Any, List, Dict
from datetime import datetime

@dataclass
class ToolExecution:
    """Record of a tool execution."""
    tool_name: str
    server: str
    parameters: Dict
    result: Any
    duration_ms: float
    timestamp: datetime

@dataclass
class AgentResponse:
    """Standardized response from any agent."""
    success: bool
    message: str
    data: Optional[Any] = None
    error: Optional[str] = None
    tool_executions: List[ToolExecution] = None
    metadata: Dict = None

    def to_dict(self) -> dict:
        return {
            "success": self.success,
            "message": self.message,
            "data": self.data,
            "error": self.error,
            "tool_executions": [
                {
                    "tool": t.tool_name,
                    "server": t.server,
                    "duration_ms": t.duration_ms,
                    "timestamp": t.timestamp.isoformat()
                } for t in (self.tool_executions or [])
            ],
            "metadata": self.metadata or {}
        }
```

**Create `src/foundation/agents/base_agent.py`**:

```python
from abc import ABC, abstractmethod
from typing import Dict, List, Optional
from .persona import Persona
from .agent_response import AgentResponse

class BaseAgent(ABC):
    """Base class for all agents."""

    def __init__(
        self,
        name: str,
        persona: Optional[Persona] = None,
        llm_config: Optional[Dict] = None
    ):
        self.name = name
        self.persona = persona
        self.llm_config = llm_config or {}
        self.tools = []

    @abstractmethod
    async def execute(
        self,
        task: str,
        user_context: Dict
    ) -> AgentResponse:
        """
        Execute a task.

        Args:
            task: Natural language task description
            user_context: User context (user_id, email, roles, etc.)

        Returns:
            AgentResponse with results
        """
        pass

    def can_use_tool(self, tool_name: str) -> bool:
        """Check if this agent can use a tool."""
        if not self.persona:
            return True  # No persona = no restrictions
        return self.persona.can_use_tool(tool_name)

    def get_allowed_tools(self) -> List[str]:
        """Get list of tools this agent can use."""
        if not self.persona:
            return []
        return self.persona.allowed_tools

    async def validate_task(
        self,
        task: str,
        user_context: Dict
    ) -> tuple[bool, Optional[str]]:
        """
        Validate if agent can perform task.

        Returns:
            (is_valid, error_message)
        """
        # Override in subclasses for specific validation
        return True, None
```

#### Day 2: MCP Integration Layer (Simplified with Microsoft's Framework)

**Create `src/foundation/mcp/__init__.py`** (Re-export Microsoft's classes):

```python
"""
MCP integration layer using Microsoft Agent Framework.

This module provides a simplified interface to MCP servers by re-exporting
Microsoft's battle-tested MCPTool classes and adding our persona-based mapping.
"""

# Re-export Microsoft's MCP classes
from agent_framework import (
    MCPTool,                    # Base MCP tool class
    MCPStdioTool,              # For local subprocess servers
    MCPStreamableHTTPTool,     # For HTTP/SSE servers (primary)
    MCPWebsocketTool,          # For WebSocket servers
)

# Our custom components
from .server_registry import MCPServerRegistry, MCPServerConfig
from .persona_mapper import PersonaMCPMapper

__all__ = [
    # Microsoft's classes
    "MCPTool",
    "MCPStdioTool",
    "MCPStreamableHTTPTool",
    "MCPWebsocketTool",
    # Our classes
    "MCPServerRegistry",
    "MCPServerConfig",
    "PersonaMCPMapper",
]
```

**Create `src/foundation/mcp/server_registry.py`** (Config storage only):

```python
"""
Registry for MCP server configurations.

Stores connection details for MCP servers without managing sessions.
Microsoft's MCPTool classes handle their own connection lifecycle.
"""
from dataclasses import dataclass, field
from typing import Dict, Optional
import logging

logger = logging.getLogger(__name__)


@dataclass
class MCPServerConfig:
    """Configuration for an MCP server."""
    name: str
    transport: str  # "http", "stdio", "websocket"
    url: Optional[str] = None  # For http/websocket
    command: Optional[str] = None  # For stdio
    args: list = field(default_factory=list)  # For stdio
    headers: Dict[str, str] = field(default_factory=dict)  # Auth headers
    metadata: Dict = field(default_factory=dict)


class MCPServerRegistry:
    """
    Registry for MCP server configurations.

    Unlike the old MCPClientManager, this only stores configs.
    Microsoft's MCPTool instances manage their own connections.
    """

    def __init__(self):
        self._configs: Dict[str, MCPServerConfig] = {}

    def register_config(self, config: MCPServerConfig) -> None:
        """Register an MCP server configuration."""
        self._configs[config.name] = config
        logger.info(f"Registered MCP server config: {config.name}")

    def get_config(self, server_name: str) -> Optional[MCPServerConfig]:
        """Get configuration for a server."""
        return self._configs.get(server_name)

    def list_servers(self) -> list[str]:
        """List all registered server names."""
        return list(self._configs.keys())

    def remove_config(self, server_name: str) -> None:
        """Remove a server configuration."""
        if server_name in self._configs:
            del self._configs[server_name]
            logger.info(f"Removed MCP server config: {server_name}")
```

**Create `src/foundation/mcp/persona_mapper.py`** (Our unique value-add):

```python
"""
Maps Personas to filtered MCPTool instances.

This is our unique innovation on top of Microsoft's Agent Framework.
We create persona-specific tool instances with appropriate filtering.
"""
from typing import Optional
from agent_framework import MCPStreamableHTTPTool, MCPStdioTool, MCPWebsocketTool
from ..agents.persona import Persona
from .server_registry import MCPServerRegistry, MCPServerConfig
import logging

logger = logging.getLogger(__name__)


class PersonaMCPMapper:
    """
    Maps Persona permissions to filtered MCPTool instances.

    This bridges our Persona concept with Microsoft's MCPTool pattern:
    - Persona defines allowed_tools (our business logic)
    - MCPTool's allowed_tools filters what gets exposed
    - Result: Persona-aware tool instances
    """

    def __init__(self, registry: MCPServerRegistry):
        self.registry = registry

    def get_mcp_tool_for_persona(
        self,
        persona: Persona,
        server_name: str
    ) -> Optional[MCPStreamableHTTPTool | MCPStdioTool | MCPWebsocketTool]:
        """
        Create an MCPTool instance filtered for this persona.

        Args:
            persona: The persona defining allowed tools
            server_name: Name of the MCP server to connect to

        Returns:
            MCPTool instance configured with persona's allowed_tools
        """
        config = self.registry.get_config(server_name)
        if not config:
            logger.error(f"Server {server_name} not found in registry")
            return None

        # Filter allowed tools based on persona
        # Only include tools from this server that the persona can use
        persona_tools = [
            tool for tool in persona.allowed_tools
            if tool.startswith(f"{server_name}_")
        ]

        logger.info(
            f"Creating {config.transport} tool for persona '{persona.name}' "
            f"with {len(persona_tools)} allowed tools"
        )

        # Create appropriate MCPTool based on transport
        if config.transport == "http":
            return MCPStreamableHTTPTool(
                name=server_name,
                url=config.url,
                headers=config.headers,
                allowed_tools=persona_tools  # Microsoft's filtering!
            )
        elif config.transport == "stdio":
            return MCPStdioTool(
                name=server_name,
                command=config.command,
                args=config.args,
                allowed_tools=persona_tools
            )
        elif config.transport == "websocket":
            return MCPWebsocketTool(
                name=server_name,
                url=config.url,
                headers=config.headers,
                allowed_tools=persona_tools
            )
        else:
            raise ValueError(f"Unsupported transport: {config.transport}")

    def get_all_mcp_tools_for_persona(
        self,
        persona: Persona
    ) -> list[MCPStreamableHTTPTool | MCPStdioTool | MCPWebsocketTool]:
        """
        Get MCPTool instances for all servers this persona can access.

        Returns:
            List of MCPTool instances, one per server with allowed tools
        """
        tools = []
        for server_name in self.registry.list_servers():
            tool = self.get_mcp_tool_for_persona(persona, server_name)
            if tool:
                tools.append(tool)
        return tools
```

#### Day 3: Permission System (Simplified)

**Create `src/foundation/auth/permission_checker.py`** (Simplified - no tool registry needed):

```python
from typing import Dict
from ..agents.persona import Persona, Permission
import logging

logger = logging.getLogger(__name__)

class PermissionChecker:
    """Check if actions are allowed based on persona permissions."""

    @staticmethod
    def can_execute_tool(
        persona: Persona,
        tool_name: str,
        user_context: Dict
    ) -> tuple[bool, str]:
        """
        Check if persona can execute a tool.

        Returns:
            (allowed, reason)
        """
        # Check if tool is in allowed list
        if not persona.can_use_tool(tool_name):
            return False, f"Tool '{tool_name}' not allowed for {persona.display_name}"

        # Additional checks based on tool name
        # For example, update_issue might require checking if it's user's own issue
        if "update" in tool_name and not persona.has_permission("jira", "write", "*"):
            # Check if updating own issue
            if persona.has_permission("jira", "write", "own"):
                # Need to verify this is user's own issue
                # This would be done in the agent logic
                return True, "Can update own issues only"
            return False, "Cannot update issues"

        return True, "Allowed"

    @staticmethod
    def filter_jql_for_persona(
        persona: Persona,
        jql: str,
        user_context: Dict
    ) -> str:
        """
        Add JQL filters based on persona permissions.

        For example, general users might only see their own issues for updates.
        """
        if persona.has_permission("jira", "read", "*"):
            # Admin - no filter
            return jql

        if persona.has_permission("jira", "read", "project"):
            # Can read project, no additional filter
            return jql

        if persona.has_permission("jira", "read", "own"):
            # Can only read own issues
            user_email = user_context.get("email")
            if "assignee" not in jql.lower():
                return f"({jql}) AND assignee = {user_email}"

        return jql
```

### Week 1 Deliverables (Simplified ⭐)
- ✅ Generic foundation layer complete (~220 lines vs ~550 lines)
- ✅ Persona + Permission system (our core value)
- ✅ AgentResponse standardized response format
- ✅ MCPServerRegistry for config storage
- ✅ PersonaMCPMapper (our innovation on top of Microsoft)
- ✅ Permission system simplified
- ✅ Unit tests with 100% coverage

**What We Get from Microsoft** (no code needed):
- ✅ MCPTool, MCPStreamableHTTPTool, MCPStdioTool, MCPWebsocketTool
- ✅ Connection management and lifecycle
- ✅ Tool discovery and conversion to AIFunctions
- ✅ OpenTelemetry observability built-in

**Test Week 1**:
```python
# Test persona system
from foundation.agents.persona import Persona, Permission
from foundation.mcp import MCPServerRegistry, MCPServerConfig, PersonaMCPMapper

# Create persona
general_user = Persona(
    name="general_user",
    display_name="General User",
    description="Standard user with limited permissions",
    permissions=[
        Permission("jira", "read", "*"),
        Permission("jira", "write", "own"),
    ],
    allowed_tools=["jira_search", "jira_get_issue", "jira_create_issue"]
)

assert general_user.has_permission("jira", "read", "*")
assert not general_user.has_permission("jira", "admin", "*")
assert general_user.can_use_tool("jira_search")
assert not general_user.can_use_tool("jira_delete_issue")

# Test MCP integration
registry = MCPServerRegistry()
registry.register_config(MCPServerConfig(
    name="jira",
    transport="http",
    url="https://jira-mcp.example.com/mcp",
    headers={"Authorization": "Bearer token"}
))

mapper = PersonaMCPMapper(registry)
jira_tool = mapper.get_mcp_tool_for_persona(general_user, "jira")

assert jira_tool is not None
assert jira_tool.name == "jira"
# Microsoft's MCPTool will filter to only allowed_tools
```

**Time Saved**: 2 days! Week 1 now takes 3 days instead of 5.

---

### Week 2: Jira MCP Server

Follow PHASE1_IMPLEMENTATION.md Week 1-2 to build Jira MCP server.

**But with these changes**:
- Add more tools (12 total instead of 6)
- Ensure all tools have clear permission requirements in description
- Add tool tags for permission checking

**Tools to implement**:

#### Core (6 tools)
1. `jira_search` - tags: `["read", "jira"]`
2. `jira_get_issue` - tags: `["read", "jira"]`
3. `jira_create_issue` - tags: `["write", "jira"]`
4. `jira_update_issue` - tags: `["write", "jira"]`
5. `jira_add_comment` - tags: `["write", "jira"]`
6. `jira_transition_issue` - tags: `["write", "jira"]`

#### Advanced (6 tools)
7. `jira_delete_issue` - tags: `["admin", "jira"]`
8. `jira_get_sprints` - tags: `["read", "jira", "agile"]`
9. `jira_create_sprint` - tags: `["admin", "jira", "agile"]`
10. `jira_add_worklog` - tags: `["write", "jira"]`
11. `jira_assign_issue` - tags: `["admin", "jira"]`
12. `jira_bulk_update` - tags: `["admin", "jira"]`

### Week 2 Deliverables
- ✅ Jira MCP server with 12 tools
- ✅ Deployed to Azure Container Apps
- ✅ Registered with MCPClientManager
- ✅ Tools in ToolRegistry

---

### Week 3: Persona Agents

#### Day 11-12: Persona Configurations

**Create `src/agents/jira/persona_configs.py`**:

```python
from foundation.agents.persona import Persona, Permission

# General User Persona
GENERAL_USER_PERSONA = Persona(
    name="general_user",
    display_name="General User",
    description="Standard user with read access and ability to manage own issues",
    permissions=[
        Permission("jira", "read", "*"),         # Can read all
        Permission("jira", "write", "own"),      # Can write own issues
        Permission("jira", "create", "*"),       # Can create issues
        Permission("jira", "comment", "*"),      # Can comment on all
    ],
    allowed_tools=[
        "jira_search",
        "jira_get_issue",
        "jira_create_issue",
        "jira_update_issue",      # Will be filtered to own issues
        "jira_add_comment",
        "jira_transition_issue",  # Will be filtered to own issues
        "jira_get_sprints",       # Read-only
        "jira_add_worklog",       # Own issues only
    ],
    metadata={
        "color": "blue",
        "icon": "user",
        "suggested_prompts": [
            "Show me my assigned issues",
            "Create a new bug",
            "Add a comment to issue XXX",
            "What's in the current sprint?",
        ]
    }
)

# Admin Persona
ADMIN_PERSONA = Persona(
    name="admin",
    display_name="Administrator",
    description="Full access to all Jira operations",
    permissions=[
        Permission("jira", "*", "*"),  # All permissions
    ],
    allowed_tools=[
        # All tools
        "jira_search",
        "jira_get_issue",
        "jira_create_issue",
        "jira_update_issue",
        "jira_delete_issue",
        "jira_add_comment",
        "jira_transition_issue",
        "jira_get_sprints",
        "jira_create_sprint",
        "jira_add_worklog",
        "jira_assign_issue",
        "jira_bulk_update",
    ],
    metadata={
        "color": "red",
        "icon": "shield",
        "suggested_prompts": [
            "Assign all P0 bugs to the team",
            "Create a new sprint for next week",
            "Show project health metrics",
            "Bulk update priority for open bugs",
        ]
    }
)
```

#### Day 12-14: General User Agent (Using Microsoft's ChatAgent)

**Create `src/agents/jira/general_user_agent.py`** (Simplified with Microsoft's framework):

```python
"""
General User Agent using Microsoft's ChatAgent.

This demonstrates the hybrid approach:
- Microsoft's ChatAgent handles LLM and tool execution
- Our PersonaMCPMapper provides persona-filtered tools
- Result: Clean, simple, powerful agent
"""
import json
from typing import Dict
from agent_framework import ChatAgent
from agent_framework.clients import OpenAIChatClient
from foundation.mcp import PersonaMCPMapper, MCPServerRegistry
from foundation.auth.permission_checker import PermissionChecker
from foundation.agents.agent_response import AgentResponse
from .persona_configs import GENERAL_USER_PERSONA
import logging

logger = logging.getLogger(__name__)


class GeneralUserAgent:
    """
    Agent for general users with limited Jira permissions.

    Uses Microsoft's ChatAgent with persona-filtered tools.
    """

    def __init__(
        self,
        mcp_registry: MCPServerRegistry,
        llm_config: Dict = None
    ):
        self.persona = GENERAL_USER_PERSONA
        self.llm_config = llm_config or {}

        # Get persona-filtered MCP tools
        mapper = PersonaMCPMapper(mcp_registry)
        jira_tool = mapper.get_mcp_tool_for_persona(
            persona=self.persona,
            server_name="jira"
        )

        # Create Microsoft's ChatAgent with filtered tools
        self.agent = ChatAgent(
            chat_client=OpenAIChatClient(**self.llm_config),
            name="GeneralUserAgent",
            instructions="""
            You are a Jira assistant for general users.

            You can help with:
            - Searching for issues
            - Creating new issues
            - Adding comments
            - Viewing sprints

            You CANNOT:
            - Delete issues
            - Create sprints
            - Bulk update issues
            - Assign issues to others

            Always be helpful and explain what you're doing.
            """,
            tools=jira_tool  # Microsoft handles tool expansion!
        )

    async def execute(
        self,
        task: str,
        user_context: Dict
    ) -> AgentResponse:
        """
        Execute task with general user permissions.

        Microsoft's ChatAgent handles:
        - LLM interaction
        - Tool selection
        - Tool execution
        - Response formatting

        We just need to wrap it in our AgentResponse format.
        """
        logger.info(
            f"GeneralUserAgent executing: '{task}' "
            f"for user {user_context.get('email')}"
        )

        try:
            # Add user context to the message
            enhanced_task = f"""
            User: {user_context.get('email')}
            Request: {task}

            Remember: You can only update/transition issues assigned to this user.
            """

            # Microsoft's ChatAgent does all the heavy lifting!
            result = await self.agent.execute(enhanced_task)

            # Convert to our AgentResponse format
            return AgentResponse(
                success=True,
                message=result.message if hasattr(result, 'message') else str(result),
                data=result.data if hasattr(result, 'data') else None,
                metadata={
                    "persona": self.persona.name,
                    "user": user_context.get('email')
                }
            )

        except Exception as e:
            logger.error(f"Error in GeneralUserAgent: {e}", exc_info=True)
            return AgentResponse(
                success=False,
                message="An error occurred while processing your request.",
                error=str(e)
            )
```

#### Day 14-15: Admin Agent (Using Microsoft's ChatAgent)

**Create `src/agents/jira/admin_agent.py`** (Similar pattern to General User):

```python
"""
Admin Agent using Microsoft's ChatAgent.

Admins have full access to all Jira tools.
"""
from typing import Dict
from agent_framework import ChatAgent
from agent_framework.clients import OpenAIChatClient
from foundation.mcp import PersonaMCPMapper, MCPServerRegistry
from foundation.agents.agent_response import AgentResponse
from .persona_configs import ADMIN_PERSONA
import logging

logger = logging.getLogger(__name__)


class AdminAgent:
    """
    Agent for administrators with full Jira permissions.

    Uses Microsoft's ChatAgent with all tools available.
    """

    def __init__(
        self,
        mcp_registry: MCPServerRegistry,
        llm_config: Dict = None
    ):
        self.persona = ADMIN_PERSONA
        self.llm_config = llm_config or {}

        # Get all Jira tools for admin (no filtering needed)
        mapper = PersonaMCPMapper(mcp_registry)
        jira_tool = mapper.get_mcp_tool_for_persona(
            persona=self.persona,
            server_name="jira"
        )

        # Create Microsoft's ChatAgent with ALL tools
        self.agent = ChatAgent(
            chat_client=OpenAIChatClient(**self.llm_config),
            name="AdminAgent",
            instructions="""
            You are a Jira administrator assistant with full permissions.

            You can help with:
            - All user operations (search, create, update, etc.)
            - Administrative tasks (delete, bulk operations)
            - Sprint management (create, update sprints)
            - Team management (assign issues, workload balancing)

            You have access to all Jira tools. Use them wisely and always
            confirm destructive operations with the user.
            """,
            tools=jira_tool  # All 12 tools available
        )

    async def execute(
        self,
        task: str,
        user_context: Dict
    ) -> AgentResponse:
        """Execute task with admin permissions (no restrictions)."""
        logger.info(f"AdminAgent executing: '{task}' for {user_context.get('email')}")

        try:
            # Microsoft's ChatAgent handles everything
            result = await self.agent.execute(task)

            return AgentResponse(
                success=True,
                message=result.message if hasattr(result, 'message') else str(result),
                data=result.data if hasattr(result, 'data') else None,
                metadata={
                    "persona": self.persona.name,
                    "user": user_context.get('email')
                }
            )

        except Exception as e:
            logger.error(f"Error in AdminAgent: {e}", exc_info=True)
            return AgentResponse(
                success=False,
                message="An error occurred while processing your request.",
                error=str(e)
            )
```

### Week 3 Deliverables (Simplified ⭐)
- ✅ Persona configurations defined (GENERAL_USER_PERSONA, ADMIN_PERSONA)
- ✅ GeneralUserAgent using Microsoft's ChatAgent (~40 lines vs ~150 lines)
- ✅ AdminAgent using Microsoft's ChatAgent (~40 lines)
- ✅ Permission filtering via PersonaMCPMapper
- ✅ Unit tests for persona mapping
- ✅ Integration tests with Microsoft's framework

**Code Reduction**: ~300 lines → ~80 lines per agent (73% reduction!)

**What Microsoft Gives Us**:
- ✅ LLM integration (OpenAI, Azure, Anthropic, etc.)
- ✅ Tool selection and execution logic
- ✅ Streaming support
- ✅ Error handling
- ✅ Retry logic
- ✅ OpenTelemetry tracing

---

### Week 4: Orchestrator

**Create `src/orchestration/orchestrator.py`**:

```python
from typing import Dict
from foundation.agents.base_agent import BaseAgent, AgentResponse
import logging

logger = logging.getLogger(__name__)

class OrchestratorAgent(BaseAgent):
    """Routes requests to appropriate persona agents."""

    def __init__(self):
        super().__init__(name="Orchestrator", persona=None)
        self.persona_agents: Dict[str, BaseAgent] = {}

    def register_agent(self, persona_name: str, agent: BaseAgent):
        """Register a persona agent."""
        self.persona_agents[persona_name] = agent
        logger.info(f"Registered {persona_name} agent")

    async def execute(
        self,
        task: str,
        user_context: Dict
    ) -> AgentResponse:
        """Route to appropriate persona agent."""
        persona_name = user_context.get("persona", "general_user")

        agent = self.persona_agents.get(persona_name)
        if not agent:
            return AgentResponse(
                success=False,
                message=f"Unknown persona: {persona_name}",
                error="Invalid persona"
            )

        logger.info(f"Routing to {persona_name} agent")
        return await agent.execute(task, user_context)

    def list_personas(self) -> list:
        """List available personas."""
        return [
            {
                "name": agent.persona.name,
                "display_name": agent.persona.display_name,
                "description": agent.persona.description,
                "metadata": agent.persona.metadata
            }
            for agent in self.persona_agents.values()
            if agent.persona
        ]
```

**Create `src/main.py` (API entry point) - Simplified**:

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, Optional
from orchestration.orchestrator import OrchestratorAgent
from agents.jira.general_user_agent import GeneralUserAgent
from agents.jira.admin_agent import AdminAgent
from foundation.mcp import MCPServerRegistry, MCPServerConfig
import os

app = FastAPI(title="Agentic Platform API")

# Initialize MCP server registry
mcp_registry = MCPServerRegistry()

# Register Jira MCP server configuration
mcp_registry.register_config(MCPServerConfig(
    name="jira",
    transport="http",
    url=os.getenv("JIRA_MCP_URL", "https://jira-mcp-server.azurecontainerapps.io/mcp"),
    headers={
        "Authorization": f"Bearer {os.getenv('JIRA_API_TOKEN')}"
    }
))

# Initialize orchestrator
orchestrator = OrchestratorAgent()

# Create persona agents (they handle MCP tools internally)
llm_config = {
    "api_key": os.getenv("OPENAI_API_KEY"),
    "model": "gpt-4"
}

general_user_agent = GeneralUserAgent(mcp_registry, llm_config)
admin_agent = AdminAgent(mcp_registry, llm_config)

orchestrator.register_agent("general_user", general_user_agent)
orchestrator.register_agent("admin", admin_agent)

class TaskRequest(BaseModel):
    task: str
    persona: str = "general_user"
    user_email: str

@app.post("/execute")
async def execute_task(request: TaskRequest):
    """Execute a task via the appropriate persona agent."""
    user_context = {
        "persona": request.persona,
        "email": request.user_email
    }

    response = await orchestrator.execute(request.task, user_context)
    return response.to_dict()

@app.get("/personas")
async def list_personas():
    """List available personas."""
    return orchestrator.list_personas()

@app.get("/health")
async def health():
    return {"status": "ok"}
```

### Week 4 Deliverables
- ✅ Orchestrator routing to persona agents
- ✅ FastAPI backend API
- ✅ Persona listing endpoint
- ✅ Task execution endpoint
- ✅ Integration tests

**Test Week 4**:
```bash
# Start backend
uvicorn main:app --reload

# Test personas
curl http://localhost:8000/personas

# Test general user
curl -X POST http://localhost:8000/execute \
  -H "Content-Type: application/json" \
  -d '{"task":"Show my assigned bugs","persona":"general_user","user_email":"user@example.com"}'

# Test admin
curl -X POST http://localhost:8000/execute \
  -H "Content-Type: application/json" \
  -d '{"task":"Create a new sprint","persona":"admin","user_email":"admin@example.com"}'
```

---

## Phase 2: Frontend (3 weeks)

### Week 5: Next.js + Persona UI

- [ ] Next.js 15 setup
- [ ] Persona selector component
- [ ] Fetch personas from API
- [ ] Persona switcher with separate contexts
- [ ] Azure AD authentication

### Week 6: Chat Interface

- [ ] Chat UI with streaming
- [ ] Call backend `/execute` API
- [ ] Display tool executions
- [ ] Persona-specific suggestions
- [ ] Error handling (permission denied)

### Week 7: Polish & Deploy

- [ ] Direct Jira UI (optional)
- [ ] Mobile responsive
- [ ] Deploy to Azure
- [ ] End-to-end testing

---

## Success Criteria

### Phase 1 (Backend)
- ✅ Foundation layer complete and reusable
- ✅ Jira MCP server with 12 tools deployed
- ✅ General User agent working (search, create)
- ✅ Admin agent structure in place
- ✅ Orchestrator routing correctly
- ✅ API endpoints functional
- ✅ Persona permissions enforced

### Phase 2 (Frontend)
- ✅ Persona selector working
- ✅ Chat interface communicating with backend
- ✅ Tool executions visible
- ✅ Deployed to Azure

---

**Next Step**: Start Week 1 - Build foundation layer with BaseAgent, Persona, MCPClientManager, and ToolRegistry.
