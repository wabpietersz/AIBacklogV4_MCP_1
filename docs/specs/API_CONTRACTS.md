# API Contracts & Data Models

Complete API specifications and data models for the agentic platform.

---

## 🎯 API Overview

### Backend API (Week 4)

**Base URL**: `https://api.jira-mcp.example.com`

**Authentication**: Azure AD Bearer token

**Endpoints**:
- `POST /execute` - Execute a task with a persona
- `GET /personas` - List available personas
- `GET /tools` - List tools for a persona
- `GET /health` - Health check
- `GET /metrics` - Usage metrics (admin only)

---

## 📊 Data Models

### Core Models

#### Permission

```python
@dataclass
class Permission:
    """A single permission."""
    resource: str      # e.g., "jira"
    action: str        # e.g., "read", "write", "admin"
    scope: str = "*"   # e.g., "own", "project", "*"

    def __str__(self) -> str:
        return f"{self.resource}:{self.action}:{self.scope}"

    @classmethod
    def from_string(cls, perm_str: str) -> "Permission":
        """Parse 'jira:read:own' format."""
        parts = perm_str.split(":")
        return cls(
            resource=parts[0],
            action=parts[1],
            scope=parts[2] if len(parts) > 2 else "*"
        )

# Examples:
# Permission("jira", "read", "*")     -> Can read all Jira issues
# Permission("jira", "write", "own")  -> Can write own issues only
# Permission("jira", "*", "*")        -> Admin - all operations
```

#### Persona

```python
@dataclass
class Persona:
    """Defines capabilities and permissions for an agent."""
    name: str                      # "general_user", "admin"
    display_name: str              # "General User", "Administrator"
    description: str               # Human-readable description
    permissions: List[Permission]  # What can this persona do
    allowed_tools: List[str]       # Which tools can be used
    metadata: Dict = None          # Color, icon, suggested prompts

    def can_use_tool(self, tool_name: str) -> bool:
        return tool_name in self.allowed_tools

    def has_permission(self, resource: str, action: str, scope: str = "*") -> bool:
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

# Example:
general_user = Persona(
    name="general_user",
    display_name="General User",
    description="Standard user with limited permissions",
    permissions=[
        Permission("jira", "read", "*"),
        Permission("jira", "write", "own"),
    ],
    allowed_tools=["jira_search", "jira_create_issue"],
    metadata={
        "color": "blue",
        "icon": "user",
        "suggested_prompts": ["Show my assigned issues"]
    }
)
```

#### Tool Execution

```python
@dataclass
class ToolExecution:
    """Record of a tool execution."""
    tool_name: str         # "jira_search"
    server: str            # "jira"
    parameters: Dict       # {"jql": "project = JB"}
    result: Any            # Tool result (JSON)
    duration_ms: float     # Execution time
    timestamp: datetime    # When executed

    def to_dict(self) -> dict:
        return {
            "tool": self.tool_name,
            "server": self.server,
            "parameters": self.parameters,
            "duration_ms": self.duration_ms,
            "timestamp": self.timestamp.isoformat()
        }
```

#### Agent Response

```python
@dataclass
class AgentResponse:
    """Standardized response from any agent."""
    success: bool                           # Did task succeed?
    message: str                            # Human-readable message
    data: Optional[Any] = None              # Result data
    error: Optional[str] = None             # Error message if failed
    tool_executions: List[ToolExecution] = None  # Tools that were called
    metadata: Dict = None                   # Additional context

    def to_dict(self) -> dict:
        return {
            "success": self.success,
            "message": self.message,
            "data": self.data,
            "error": self.error,
            "tool_executions": [
                t.to_dict() for t in (self.tool_executions or [])
            ],
            "metadata": self.metadata or {}
        }

# Example success:
AgentResponse(
    success=True,
    message="Found 5 assigned bugs",
    data=[...],
    tool_executions=[
        ToolExecution(
            tool_name="jira_search",
            server="jira",
            parameters={"jql": "assignee = currentUser() AND type = Bug"},
            result=[...],
            duration_ms=234.5,
            timestamp=datetime.now()
        )
    ]
)

# Example failure:
AgentResponse(
    success=False,
    message="Permission denied",
    error="General User cannot delete issues. Switch to Admin persona?",
    metadata={"required_permission": "jira:admin:*"}
)
```

---

## 🔌 API Endpoints

### POST /execute

Execute a task with a specific persona.

**Request**:
```json
{
  "task": "Show me all P0 bugs assigned to me",
  "persona": "general_user",
  "user_email": "user@example.com",
  "context": {
    "project": "JB"
  }
}
```

**Request Schema**:
```python
class ExecuteRequest(BaseModel):
    task: str                          # Natural language task
    persona: str                       # "general_user" or "admin"
    user_email: str                    # User's email (for JQL filtering)
    context: Optional[Dict] = None     # Additional context

# Validation:
# - task: 1-500 characters
# - persona: Must be in available personas
# - user_email: Valid email format
```

**Response (Success)**:
```json
{
  "success": true,
  "message": "Found 3 P0 bugs assigned to you",
  "data": {
    "issues": [
      {
        "key": "JB-123",
        "summary": "Login fails on Safari",
        "priority": "P0",
        "status": "Open",
        "assignee": "user@example.com"
      },
      {
        "key": "JB-124",
        "summary": "API timeout",
        "priority": "P0",
        "status": "In Progress",
        "assignee": "user@example.com"
      },
      {
        "key": "JB-125",
        "summary": "Database connection lost",
        "priority": "P0",
        "status": "Open",
        "assignee": "user@example.com"
      }
    ]
  },
  "tool_executions": [
    {
      "tool": "jira_search",
      "server": "jira",
      "parameters": {
        "jql": "assignee = user@example.com AND priority = P0 AND type = Bug",
        "max_results": 50
      },
      "duration_ms": 234.5,
      "timestamp": "2025-01-16T10:30:00Z"
    }
  ],
  "metadata": {
    "persona_used": "general_user",
    "agent": "GeneralUserAgent",
    "execution_time_ms": 250.3
  }
}
```

**Response (Permission Denied)**:
```json
{
  "success": false,
  "message": "Permission denied",
  "error": "General User cannot delete issues. Switch to Admin persona to delete issues.",
  "data": null,
  "tool_executions": [],
  "metadata": {
    "required_permission": "jira:admin:*",
    "current_persona": "general_user",
    "suggested_action": "switch_persona",
    "suggested_persona": "admin"
  }
}
```

**Response (Error)**:
```json
{
  "success": false,
  "message": "Failed to execute task",
  "error": "Jira MCP server is unavailable",
  "data": null,
  "tool_executions": [],
  "metadata": {
    "error_code": "MCP_SERVER_UNAVAILABLE",
    "retry_after": 60
  }
}
```

**HTTP Status Codes**:
- `200` - Success (check `success` field in response)
- `400` - Bad request (invalid persona, malformed request)
- `401` - Unauthorized (invalid or missing auth token)
- `403` - Forbidden (user doesn't have access to persona)
- `429` - Too many requests (rate limited)
- `500` - Internal server error
- `503` - Service unavailable (MCP server down)

### GET /personas

List available personas for the authenticated user.

**Request**:
```
GET /personas
Authorization: Bearer <token>
```

**Response**:
```json
{
  "personas": [
    {
      "name": "general_user",
      "display_name": "General User",
      "description": "Standard user with limited permissions. Can search issues, create basic items, and manage own issues.",
      "permissions": [
        "jira:read:*",
        "jira:write:own",
        "jira:create:*",
        "jira:comment:*"
      ],
      "allowed_tools": [
        "jira_search",
        "jira_get_issue",
        "jira_create_issue",
        "jira_update_issue",
        "jira_add_comment",
        "jira_transition_issue",
        "jira_get_sprints",
        "jira_add_worklog"
      ],
      "metadata": {
        "color": "blue",
        "icon": "user",
        "suggested_prompts": [
          "Show me my assigned issues",
          "Create a new bug for the login issue",
          "What's in the current sprint?"
        ]
      }
    },
    {
      "name": "admin",
      "display_name": "Administrator",
      "description": "Full access to all Jira operations. Can manage sprints, delete issues, bulk operations, and project settings.",
      "permissions": [
        "jira:*:*"
      ],
      "allowed_tools": [
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
        "jira_bulk_update"
      ],
      "metadata": {
        "color": "red",
        "icon": "shield",
        "suggested_prompts": [
          "Assign all P0 bugs to the team",
          "Create a new sprint for next week",
          "Bulk update priority for open bugs"
        ]
      }
    }
  ]
}
```

### GET /tools

List tools available to a specific persona.

**Request**:
```
GET /tools?persona=general_user
Authorization: Bearer <token>
```

**Response**:
```json
{
  "persona": "general_user",
  "tools": [
    {
      "name": "jira_search",
      "description": "Search Jira issues using JQL",
      "server": "jira",
      "parameters": {
        "jql": {
          "type": "string",
          "description": "JQL query string",
          "required": true
        },
        "max_results": {
          "type": "integer",
          "description": "Maximum results to return",
          "default": 50
        }
      },
      "tags": ["read", "jira"]
    },
    {
      "name": "jira_create_issue",
      "description": "Create a new Jira issue",
      "server": "jira",
      "parameters": {
        "project": {
          "type": "string",
          "description": "Project key",
          "required": true
        },
        "summary": {
          "type": "string",
          "description": "Issue summary",
          "required": true
        },
        "issue_type": {
          "type": "string",
          "description": "Issue type (Bug, Task, Story)",
          "required": true
        },
        "description": {
          "type": "string",
          "description": "Issue description",
          "required": false
        }
      },
      "tags": ["write", "jira"]
    }
  ]
}
```

### GET /health

Health check endpoint.

**Request**:
```
GET /health
```

**Response**:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "components": {
    "api": {
      "status": "up",
      "latency_ms": 2.3
    },
    "mcp_servers": {
      "jira": {
        "status": "up",
        "url": "https://jira-mcp-server.azurecontainerapps.io/mcp",
        "latency_ms": 45.6
      }
    },
    "database": {
      "status": "up",
      "latency_ms": 12.1
    }
  },
  "timestamp": "2025-01-16T10:30:00Z"
}
```

---

## 🔒 Authentication

### Azure AD Bearer Token

All requests (except `/health`) require authentication:

```
Authorization: Bearer <azure_ad_token>
```

**Token Claims**:
```json
{
  "oid": "user-object-id",
  "email": "user@example.com",
  "name": "User Name",
  "roles": ["GeneralUser"] or ["Admin"],
  "tid": "tenant-id"
}
```

**Persona Mapping**:
- User with role `GeneralUser` → Can use `general_user` persona
- User with role `Admin` → Can use both `general_user` and `admin` personas

---

## 🌐 MCP Server API (Layer 2)

### Jira MCP Server

**Base URL**: `https://jira-mcp-server.azurecontainerapps.io/mcp`

**Protocol**: MCP (Model Context Protocol)

**Transport**: Streamable HTTP

**Authentication**: Per-request via headers
```
Authorization: Bearer <jira_oauth_token>
or
Authorization: Token <jira_pat>
```

### MCP Protocol Messages

**Initialize**:
```json
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "protocolVersion": "1.0",
    "capabilities": {}
  },
  "id": 1
}
```

**List Tools**:
```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "params": {},
  "id": 2
}
```

**Call Tool**:
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "jira_search",
    "arguments": {
      "jql": "project = JB AND status = Open",
      "max_results": 20
    }
  },
  "id": 3
}
```

---

## 📝 Error Codes

### Application Error Codes

| Code | Message | Description |
|------|---------|-------------|
| `INVALID_PERSONA` | Invalid persona | Persona doesn't exist |
| `PERMISSION_DENIED` | Permission denied | User lacks required permission |
| `TOOL_NOT_ALLOWED` | Tool not allowed | Tool not in persona's allowed list |
| `MCP_SERVER_UNAVAILABLE` | MCP server unavailable | Cannot connect to MCP server |
| `TOOL_EXECUTION_FAILED` | Tool execution failed | Tool returned error |
| `INVALID_TOKEN` | Invalid authentication token | Token expired or invalid |
| `RATE_LIMIT_EXCEEDED` | Rate limit exceeded | Too many requests |
| `TASK_TOO_LONG` | Task too long | Task exceeds 500 characters |
| `INVALID_EMAIL` | Invalid email | User email not valid |

---

## 📐 Rate Limiting

### Limits

| Persona | Requests per minute | Burst |
|---------|---------------------|-------|
| General User | 60 | 10 |
| Admin | 120 | 20 |

### Rate Limit Headers

```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1642345678
```

### Rate Limit Response

```json
{
  "success": false,
  "message": "Rate limit exceeded",
  "error": "Too many requests. Try again in 30 seconds.",
  "metadata": {
    "error_code": "RATE_LIMIT_EXCEEDED",
    "retry_after": 30,
    "limit": 60,
    "remaining": 0,
    "reset": 1642345678
  }
}
```

---

## 🧪 Example Flows

### Flow 1: General User Searches Issues

```
1. User clicks "General User" persona in UI

2. Frontend → Backend API
   POST /execute
   {
     "task": "Show my assigned bugs",
     "persona": "general_user",
     "user_email": "user@example.com"
   }

3. Backend → GeneralUserAgent
   - Analyzes task: "search assigned bugs"
   - Constructs JQL: "assignee = user@example.com AND type = Bug"
   - Calls jira_search tool

4. Backend → Jira MCP Server
   POST /mcp (MCP protocol)
   {
     "method": "tools/call",
     "params": {
       "name": "jira_search",
       "arguments": {"jql": "assignee = user@example.com AND type = Bug"}
     }
   }

5. Jira MCP Server → Jira API
   GET /rest/api/2/search?jql=...

6. Response flows back:
   Jira API → MCP Server → Backend → Frontend

7. Frontend displays:
   - "Found 3 bugs assigned to you"
   - List of bugs
   - Tool execution details
```

### Flow 2: General User Tries to Delete (Denied)

```
1. User (General User persona): "Delete issue JB-123"

2. Frontend → Backend API
   POST /execute
   {
     "task": "Delete issue JB-123",
     "persona": "general_user",
     "user_email": "user@example.com"
   }

3. Backend → GeneralUserAgent
   - Analyzes task: "delete issue"
   - Checks permissions: general_user.can_use_tool("jira_delete_issue")
   - Returns: False

4. Backend → Frontend
   {
     "success": false,
     "message": "Permission denied",
     "error": "General User cannot delete issues. Switch to Admin persona?",
     "metadata": {
       "suggested_action": "switch_persona",
       "suggested_persona": "admin"
     }
   }

5. Frontend shows:
   - Error message
   - Button: "Switch to Admin" (if user has admin role)
```

### Flow 3: Admin Deletes Issue

```
1. User switches to "Admin" persona

2. User: "Delete issue JB-123"

3. Frontend → Backend API
   POST /execute
   {
     "task": "Delete issue JB-123",
     "persona": "admin",
     "user_email": "admin@example.com"
   }

4. Backend → AdminAgent
   - Analyzes task: "delete issue JB-123"
   - Checks permissions: admin.can_use_tool("jira_delete_issue")
   - Returns: True
   - Calls jira_delete_issue tool

5. Jira MCP Server → Jira API
   DELETE /rest/api/2/issue/JB-123

6. Success response flows back

7. Frontend shows:
   - "Issue JB-123 deleted successfully"
   - Tool execution: jira_delete_issue (took 156ms)
```

---

This API contract ensures consistent behavior across the entire platform.
