# Jira MCP Server — Technical Plan (DEV Environment)

## Overview
This document describes the end-to-end development plan to build a Jira MCP Server using FastMCP (Python) and deploy it to Azure Container Apps (ACA) in a development environment.

Designed for:
- Cursor IDE / Codex
- Azure dev environment
- Local development → Docker → ACR → ACA

## 1. Project Structure

```
jira-mcp-server/
 ├── server.py
 ├── requirements.txt
 ├── Dockerfile
 ├── .env
 ├── README.md
```

## 2. Local Development Setup

### 2.1 Create virtual environment
```
python -m venv .venv
source .venv/bin/activate
```

### 2.2 Install dependencies
requirements.txt:
```
fastmcp
httpx
python-dotenv
```

### 2.3 Local .env (DEV)
```
JIRA_BASE_URL=https://your-domain.atlassian.net
JIRA_EMAIL=sa.jira.mscopilot.uat@ifs.com
JIRA_API_TOKEN=your_token_here
JIRA_DEFAULT_PROJECT=JB
```

## 3. Jira MCP Server Implementation

(See full code in conversation – included earlier.)

## 4. Dockerization

Dockerfile contents included in conversation.

## 5. Push to Azure Container Registry (ACR)

Commands to create ACR and push the Docker image.

## 6. Deploy to Azure Container Apps (ACA)

Commands to create ACA environment, deploy the MCP server container, and configure secrets.

## 7. Verify Deployment

Use:
```
az containerapp show ...
```

## 8. Agent Integration

Python client snippet using StreamableHttpTransport.

## 9. DEV Notes

- External ingress allowed
- Secrets stored directly in ACA
- No VNET
- PAT auth only
- Minimal replicas

## 10. Next Steps

Possible extensions: labels, transitions, comments, attachments, Azure AI Search MCP integration.
