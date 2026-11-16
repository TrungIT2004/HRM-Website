#!/usr/bin/env python3
"""
Prepare input for architecture analyzer from assembled-graph.json
"""
import json
import sys

# Read assembled graph
with open(r"C:\Users\ad\Desktop\HRM\.ua\intermediate\assembled-graph.json", "r", encoding="utf-8") as f:
    data = json.load(f)

nodes = data["nodes"]
edges = data["edges"]

# Build fileNodes (all nodes are file-level in this graph)
fileNodes = []
for node in nodes:
    fileNodes.append({
        "id": node["id"],
        "type": node["type"],
        "name": node["name"],
        "filePath": node["filePath"],
        "summary": node.get("summary", ""),
        "tags": node.get("tags", [])
    })

# Build allEdges (all edges)
allEdges = []
for edge in edges:
    allEdges.append({
        "source": edge["source"],
        "target": edge["target"],
        "type": edge["type"]
    })

# Build importEdges (edges with type "imports" or similar code imports)
# In this graph, the edge types are: "related", "documents", "imports", "configures", etc.
importEdges = [e for e in allEdges if e["type"] in ("imports", "calls", "uses")]

# Write input file
output = {
    "fileNodes": fileNodes,
    "importEdges": importEdges,
    "allEdges": allEdges
}

with open(r"C:\Users\ad\Desktop\HRM\.ua\tmp\ua-arch-input.json", "w", encoding="utf-8") as f:
    json.dump(output, f, indent=2)

print(f"Total fileNodes: {len(fileNodes)}")
print(f"Total allEdges: {len(allEdges)}")
print(f"Total importEdges: {len(importEdges)}")
print("Input file written to C:\\Users\\ad\\Desktop\\HRM\\.ua\\tmp\\ua-arch-input.json")