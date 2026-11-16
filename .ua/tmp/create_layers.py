#!/usr/bin/env python3
"""
Create final layers.json from structural analysis results.
"""
import json

# Load structural analysis results
with open(r"C:\Users\ad\Desktop\HRM\.ua\tmp\ua-arch-results.json", "r", encoding="utf-8") as f:
    results = json.load(f)

directory_groups = results["directoryGroups"]
node_by_id = {}  # We'll need to load the original nodes for details

# Load original input to get node details
with open(r"C:\Users\ad\Desktop\HRM\.ua\tmp\ua-arch-input.json", "r", encoding="utf-8") as f:
    input_data = json.load(f)

for node in input_data["fileNodes"]:
    node_by_id[node["id"]] = node

# ============================================================
# LAYER ASSIGNMENTS
# ============================================================

# First, assign each node to exactly one layer using a deterministic approach
# We'll build a mapping of node_id -> layer_id
node_to_layer = {}

# 1. FRONTEND - HRM Website (Next.js React application) - ENTIRE directory group
for node_id in directory_groups.get("HRM Website", []):
    node_to_layer[node_id] = "layer:frontend"

# 2. BACKEND API - Java Spring Boot REST API - ENTIRE directory group
for node_id in directory_groups.get("backend", []):
    node_to_layer[node_id] = "layer:backend-api"

# 3. AI SERVICE - Python LLM-based services - ENTIRE directory group
for node_id in directory_groups.get("ai-service", []):
    node_to_layer[node_id] = "layer:ai-service"

# 4. INFRASTRUCTURE - Docker, docker-compose
for node_id in directory_groups.get("root", []):
    node = node_by_id.get(node_id, {})
    if "docker-compose" in node.get("filePath", "") or "Dockerfile" in node.get("name", ""):
        node_to_layer[node_id] = "layer:infrastructure"
# Also check for Dockerfiles in other groups
for group_name, nodes in directory_groups.items():
    for node_id in nodes:
        if node_id in node_to_layer:
            continue
        node = node_by_id.get(node_id, {})
        if "Dockerfile" in node.get("name", ""):
            node_to_layer[node_id] = "layer:infrastructure"

# 5. CONFIGURATION - Root config files (only those not already assigned)
config_patterns = ["package.json", "tsconfig.json", ".env.example", "opencode.json", "postman.json", "next.config.ts", "postcss.config.mjs", "tailwind.config.ts", "requirements.txt"]
for node_id in directory_groups.get("root", []):
    if node_id in node_to_layer:
        continue
    node = node_by_id.get(node_id, {})
    name = node.get("name", "")
    if any(x in name for x in config_patterns):
        node_to_layer[node_id] = "layer:configuration"
# HRM Website configs (but they're already in frontend group, so skip - they stay in frontend)
# ai-service configs (already in ai-service group)

# 6. DOCUMENTATION - Root docs, diagrams, .agents skills
for node_id in directory_groups.get("root", []):
    if node_id in node_to_layer:
        continue
    node = node_by_id.get(node_id, {})
    name = node.get("name", "")
    if name.endswith(".md") or name in ["AGENTS.md", "CLAUDE.md", "README.md"] or "SPEC_" in name:
        node_to_layer[node_id] = "layer:documentation"
# Diagrams
for node_id in directory_groups.get("diagrams", []):
    if node_id not in node_to_layer:
        node_to_layer[node_id] = "layer:documentation"
# .agents skills
for node_id in directory_groups.get(".agents", []):
    if node_id not in node_to_layer:
        node_to_layer[node_id] = "layer:documentation"

# 7. DEVELOPMENT TOOLS - .scratch, .ua, Check Attendance
for group in [".scratch", ".ua", "Check Attendance"]:
    for node_id in directory_groups.get(group, []):
        if node_id not in node_to_layer:
            node_to_layer[node_id] = "layer:development-tools"

# Catch any remaining unassigned nodes from root (like test_result.txt)
for node_id in directory_groups.get("root", []):
    if node_id not in node_to_layer:
        node = node_by_id.get(node_id, {})
        name = node.get("name", "")
        # Default remaining root files to documentation
        node_to_layer[node_id] = "layer:documentation"

# Now build layers from the mapping
layers = [
    {
        "id": "layer:frontend",
        "name": "Frontend",
        "description": "Next.js 14 React application with App Router, TypeScript, Tailwind CSS, and shadcn/ui components for HRM user interface",
        "nodeIds": [nid for nid, lid in node_to_layer.items() if lid == "layer:frontend"]
    },
    {
        "id": "layer:backend-api",
        "name": "Backend API",
        "description": "Java Spring Boot 3 REST API with JWT authentication, domain-driven modules (employees, attendance, leave, overtime, payroll, assets, IT tickets, performance, resignation, documents, admin, AI chat), and PostgreSQL persistence",
        "nodeIds": [nid for nid, lid in node_to_layer.items() if lid == "layer:backend-api"]
    },
    {
        "id": "layer:ai-service",
        "name": "AI Service",
        "description": "Python-based AI services for Text2SQL generation, RAG document retrieval, LLM routing, and quota-managed Gemini API integration with 6-key round-robin rotation",
        "nodeIds": [nid for nid, lid in node_to_layer.items() if lid == "layer:ai-service"]
    },
    {
        "id": "layer:infrastructure",
        "name": "Infrastructure",
        "description": "Container orchestration with docker-compose.yml for multi-service deployment (frontend, backend, ai-service, database)",
        "nodeIds": [nid for nid, lid in node_to_layer.items() if lid == "layer:infrastructure"]
    },
    {
        "id": "layer:configuration",
        "name": "Configuration",
        "description": "Project configuration files including package.json, tsconfig.json, environment templates, and build settings for all services",
        "nodeIds": [nid for nid, lid in node_to_layer.items() if lid == "layer:configuration"]
    },
    {
        "id": "layer:documentation",
        "name": "Documentation",
        "description": "Project documentation including README, architecture specifications (SPEC_*), architecture diagrams, and AI assistant skill definitions (.agents/skills)",
        "nodeIds": [nid for nid, lid in node_to_layer.items() if lid == "layer:documentation"]
    },
    {
        "id": "layer:development-tools",
        "name": "Development Tools",
        "description": "Development artifacts including scratch workspace for issue tracking, Understand-Anything analysis outputs, and legacy Check Attendance demo project",
        "nodeIds": [nid for nid, lid in node_to_layer.items() if lid == "layer:development-tools"]
    },
]

# Remove any empty layers
layers = [l for l in layers if l["nodeIds"]]

# ============================================================
# VERIFICATION
# ============================================================
all_assigned = []
for layer in layers:
    all_assigned.extend(layer["nodeIds"])

total_input = len(input_data["fileNodes"])
total_assigned = len(all_assigned)
unique_assigned = len(set(all_assigned))

print(f"Total input nodes: {total_input}")
print(f"Total assigned: {total_assigned}")
print(f"Unique assigned: {unique_assigned}")
print(f"Layers: {len(layers)}")

# Check for duplicates
from collections import Counter
dupes = [k for k, v in Counter(all_assigned).items() if v > 1]
if dupes:
    print(f"DUPLICATES: {dupes}")

# Check for missing
missing = set(node_by_id.keys()) - set(all_assigned)
if missing:
    print(f"MISSING ({len(missing)}): {list(missing)[:20]}")

# Print layer summary
for layer in layers:
    print(f"  {layer['id']}: {len(layer['nodeIds'])} nodes")

# Write output
output_path = r"C:\Users\ad\Desktop\HRM\.ua\intermediate\layers.json"
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(layers, f, indent=2)

print(f"\nWritten to {output_path}")