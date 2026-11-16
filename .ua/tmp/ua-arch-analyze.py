#!/usr/bin/env python3
"""
Architecture Analyzer - Structural Analysis Script
Analyzes file structure, imports, and dependencies to identify architectural layers.
"""
import json
import sys
import os
import re
from collections import defaultdict, Counter
from pathlib import Path

# Pattern matching for directory names to architectural patterns
DIR_PATTERNS = {
    "api": ["routes", "api", "controllers", "endpoints", "handlers", "serializers", "routers", "blueprints", "controller", "request", "response", "dto"],
    "service": ["services", "core", "lib", "domain", "logic", "internal", "signals", "mailers", "jobs", "channels", "composables", "src/main/java"],
    "data": ["models", "db", "data", "persistence", "repository", "entities", "migrations", "entity", "sql", "database", "schema"],
    "ui": ["components", "views", "pages", "ui", "layouts", "screens"],
    "middleware": ["middleware", "plugins", "interceptors", "guards"],
    "utility": ["utils", "helpers", "common", "shared", "tools", "pkg", "templatetags"],
    "config": ["config", "constants", "env", "settings", "management", "commands", "wsgi.py", "asgi.py"],
    "test": ["__tests__", "test", "tests", "spec", "specs", "src/test/java"],
    "types": ["types", "interfaces", "schemas", "contracts", "dtos", "dto"],
    "hooks": ["hooks"],
    "state": ["store", "state", "reducers", "actions", "slices"],
    "assets": ["assets", "static", "public"],
    "entry": ["cmd", "bin", "manage.py", "main.go", "Application.java", "Program.cs", "config.ru", "lib.rs", "main.rs"],
    "documentation": ["docs", "documentation", "wiki"],
    "infrastructure": ["deploy", "deployment", "infra", "infrastructure", "k8s", "kubernetes", "helm", "charts", "terraform", "tf", "docker"],
    "ci-cd": [".github", ".gitlab", ".circleci"],
}

# File-level patterns
FILE_PATTERNS = {
    "test": [r".*\.test\..*", r".*\.spec\..*", r"test_.*\.py", r".*_test\.go", r".*Test\.java", r".*_spec\.rb", r".*Test\.php", r".*Tests\.cs"],
    "types": [r".*\.d\.ts$"],
    "entry": [r"^index\.(ts|js)$", r"^__init__\.py$", r"^manage\.py$", r"^wsgi\.py$", r"^asgi\.py$", r"^main\.go$", r"^main\.rs$", r"^lib\.rs$", r"^Application\.java$", r"^Program\.cs$", r"^config\.ru$"],
    "config": [r"^Cargo\.toml$", r"^go\.mod$", r"^Gemfile$", r"^pom\.xml$", r"^build\.gradle$", r"^composer\.json$", r"^package\.json$", r"^tsconfig\.json$"],
    "infrastructure": [r"^Dockerfile", r"^docker-compose", r".*\.tf$", r".*\.tfvars$"],
    "ci-cd": [r"^\.github/workflows/.*", r"^\.gitlab-ci\.yml$", r"^Jenkinsfile$"],
    "data": [r".*\.sql$"],
    "types": [r".*\.graphql$", r".*\.gql$", r".*\.proto$"],
    "documentation": [r".*\.md$", r".*\.rst$"],
    "infrastructure": [r"^Makefile$"],
}

def match_dir_pattern(dir_name):
    """Match directory name to architectural pattern."""
    dir_lower = dir_name.lower()
    for pattern, dirs in DIR_PATTERNS.items():
        for d in dirs:
            if d.lower() == dir_lower or dir_lower.startswith(d.lower() + "/"):
                return pattern
    return None

def match_file_pattern(file_path):
    """Match file path to architectural pattern."""
    file_name = os.path.basename(file_path)
    for pattern, regexes in FILE_PATTERNS.items():
        for regex in regexes:
            if re.match(regex, file_name, re.IGNORECASE):
                return pattern
    return None

def get_top_level_dir(file_path, common_prefix=""):
    """Extract top-level directory after common prefix."""
    if common_prefix and file_path.startswith(common_prefix):
        rel = file_path[len(common_prefix):]
    else:
        rel = file_path
    parts = rel.split("/")
    if len(parts) > 1:
        return parts[0]
    return "root"

def find_common_prefix(paths):
    """Find common path prefix among all paths."""
    if not paths:
        return ""
    # Split all paths
    split_paths = [p.split("/") for p in paths]
    # Find common prefix
    common = []
    for i in range(min(len(p) for p in split_paths)):
        first = split_paths[0][i]
        if all(p[i] == first for p in split_paths):
            common.append(first)
        else:
            break
    return "/".join(common) + "/" if common else ""

def main():
    if len(sys.argv) != 3:
        print("Usage: python ua-arch-analyze.py <input.json> <output.json>", file=sys.stderr)
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    # Load input
    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    file_nodes = data["fileNodes"]
    import_edges = data["importEdges"]
    all_edges = data["allEdges"]

    # Build node lookup
    node_by_id = {n["id"]: n for n in file_nodes}

    # A. Directory Grouping
    all_paths = [n["filePath"] for n in file_nodes]
    common_prefix = find_common_prefix(all_paths)

    directory_groups = defaultdict(list)
    for node in file_nodes:
        group = get_top_level_dir(node["filePath"], common_prefix)
        directory_groups[group].append(node["id"])

    # If flat structure (only one group), group by file type
    if len(directory_groups) <= 1:
        directory_groups = defaultdict(list)
        for node in file_nodes:
            pattern = match_file_pattern(node["filePath"])
            group = pattern if pattern else "other"
            directory_groups[group].append(node["id"])

    # B. Node Type Grouping
    node_type_groups = defaultdict(list)
    for node in file_nodes:
        node_type_groups[node["type"]].append(node["id"])

    # C. Import Adjacency Matrix
    fan_out = defaultdict(int)
    fan_in = defaultdict(int)
    adj_list = defaultdict(set)
    reverse_adj = defaultdict(set)

    for edge in import_edges:
        src = edge["source"]
        tgt = edge["target"]
        if src in node_by_id and tgt in node_by_id:
            fan_out[src] += 1
            fan_in[tgt] += 1
            adj_list[src].add(tgt)
            reverse_adj[tgt].add(src)

    # Group-level imports
    node_to_group = {}
    for group, nodes in directory_groups.items():
        for node_id in nodes:
            node_to_group[node_id] = group

    group_imports = defaultdict(lambda: defaultdict(int))
    group_imported_by = defaultdict(lambda: defaultdict(int))

    for edge in import_edges:
        src = edge["source"]
        tgt = edge["target"]
        if src in node_to_group and tgt in node_to_group:
            src_group = node_to_group[src]
            tgt_group = node_to_group[tgt]
            if src_group != tgt_group:
                group_imports[src_group][tgt_group] += 1
                group_imported_by[tgt_group][src_group] += 1

    # D. Cross-Category Dependency Analysis
    cross_category = defaultdict(lambda: defaultdict(lambda: defaultdict(int)))
    for edge in all_edges:
        src = edge["source"]
        tgt = edge["target"]
        if src in node_by_id and tgt in node_by_id:
            src_type = node_by_id[src]["type"]
            tgt_type = node_by_id[tgt]["type"]
            cross_category[src_type][tgt_type][edge["type"]] += 1

    cross_category_edges = []
    for src_type, targets in cross_category.items():
        for tgt_type, edge_types in targets.items():
            for edge_type, count in edge_types.items():
                cross_category_edges.append({
                    "fromType": src_type,
                    "toType": tgt_type,
                    "edgeType": edge_type,
                    "count": count
                })

    # E. Inter-Group Import Frequency
    inter_group_imports = []
    for src_group, targets in group_imports.items():
        for tgt_group, count in targets.items():
            inter_group_imports.append({
                "from": src_group,
                "to": tgt_group,
                "count": count
            })

    # F. Intra-Group Import Density
    intra_group_density = {}
    for group, nodes in directory_groups.items():
        internal_edges = 0
        total_edges = 0
        node_set = set(nodes)
        for src in nodes:
            for tgt in adj_list.get(src, []):
                total_edges += 1
                if tgt in node_set:
                    internal_edges += 1
            for src2 in reverse_adj.get(src, []):
                if src2 not in node_set:
                    total_edges += 1
        density = internal_edges / total_edges if total_edges > 0 else 0
        intra_group_density[group] = {
            "internalEdges": internal_edges,
            "totalEdges": total_edges,
            "density": round(density, 3)
        }

    # G. Directory Pattern Matching
    pattern_matches = {}
    for group in directory_groups:
        pattern = match_dir_pattern(group)
        if pattern:
            pattern_matches[group] = pattern
        else:
            # Try file-level pattern matching for the group
            sample_files = [node_by_id[n]["filePath"] for n in directory_groups[group][:5]]
            for f in sample_files:
                fp = match_file_pattern(f)
                if fp:
                    pattern_matches[group] = fp
                    break

    # H. Deployment Topology Detection
    infra_files = []
    has_dockerfile = False
    has_compose = False
    has_k8s = False
    has_terraform = False
    has_ci = False

    for node in file_nodes:
        path = node["filePath"]
        name = node["name"]
        if "Dockerfile" in name:
            has_dockerfile = True
            infra_files.append(path)
        if "docker-compose" in name:
            has_compose = True
            infra_files.append(path)
        if path.startswith("k8s/") or path.startswith("kubernetes/") or path.startswith("helm/") or ".yaml" in path or ".yml" in path:
            if any(k in path for k in ["k8s", "kubernetes", "helm", "chart"]):
                has_k8s = True
                infra_files.append(path)
        if path.endswith(".tf") or path.endswith(".tfvars"):
            has_terraform = True
            infra_files.append(path)
        if ".github/workflows/" in path or ".gitlab-ci.yml" in path or "Jenkinsfile" in name:
            has_ci = True
            infra_files.append(path)

    deployment_topology = {
        "hasDockerfile": has_dockerfile,
        "hasCompose": has_compose,
        "hasK8s": has_k8s,
        "hasTerraform": has_terraform,
        "hasCI": has_ci,
        "infraFiles": infra_files
    }

    # I. Data Pipeline Detection
    schema_files = []
    migration_files = []
    data_model_files = []
    api_handler_files = []

    for node in file_nodes:
        path = node["filePath"]
        name = node["name"]
        if name.endswith(".sql") and "migration" not in path.lower():
            schema_files.append(path)
        if "migration" in path.lower() and name.endswith(".sql"):
            migration_files.append(path)
        if any(p in path for p in ["models/", "entities/", "db/", "data/"]) and (name.endswith(".py") or name.endswith(".ts") or name.endswith(".java")):
            data_model_files.append(path)
        if any(p in path for p in ["routes/", "api/", "controllers/", "handlers/", "endpoints/"]):
            api_handler_files.append(path)

    data_pipeline = {
        "schemaFiles": schema_files,
        "migrationFiles": migration_files,
        "dataModelFiles": data_model_files,
        "apiHandlerFiles": api_handler_files
    }

    # J. Documentation Coverage
    groups_with_docs = 0
    undocumented_groups = []

    for group, nodes in directory_groups.items():
        has_doc = False
        for node_id in nodes:
            node = node_by_id[node_id]
            if node["type"] == "document" or node["filePath"].endswith(".md") or node["filePath"].endswith(".rst"):
                has_doc = True
                break
        if has_doc:
            groups_with_docs += 1
        else:
            undocumented_groups.append(group)

    total_groups = len(directory_groups)
    doc_coverage = {
        "groupsWithDocs": groups_with_docs,
        "totalGroups": total_groups,
        "coverageRatio": round(groups_with_docs / total_groups, 2) if total_groups > 0 else 0,
        "undocumentedGroups": undocumented_groups
    }

    # K. Dependency Direction
    dependency_direction = []
    for src_group, targets in group_imports.items():
        for tgt_group, count in targets.items():
            reverse_count = group_imported_by[tgt_group].get(src_group, 0)
            if count > reverse_count:
                dependency_direction.append({
                    "dependent": src_group,
                    "dependsOn": tgt_group
                })

    # File stats
    file_stats = {
        "totalFileNodes": len(file_nodes),
        "filesPerGroup": {g: len(nodes) for g, nodes in directory_groups.items()},
        "nodeTypeCounts": {t: len(nodes) for t, nodes in node_type_groups.items()}
    }

    # Fan in/out
    file_fan_in = {k: v for k, v in sorted(fan_in.items(), key=lambda x: -x[1])[:20]}
    file_fan_out = {k: v for k, v in sorted(fan_out.items(), key=lambda x: -x[1])[:20]}

    # Output results
    results = {
        "scriptCompleted": True,
        "directoryGroups": dict(directory_groups),
        "nodeTypeGroups": dict(node_type_groups),
        "crossCategoryEdges": cross_category_edges,
        "interGroupImports": inter_group_imports,
        "intraGroupDensity": intra_group_density,
        "patternMatches": pattern_matches,
        "deploymentTopology": deployment_topology,
        "dataPipeline": data_pipeline,
        "docCoverage": doc_coverage,
        "dependencyDirection": dependency_direction,
        "fileStats": file_stats,
        "fileFanIn": file_fan_in,
        "fileFanOut": file_fan_out
    }

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print("Analysis complete!")
    print(f"Directory groups: {len(directory_groups)}")
    print(f"Node types: {len(node_type_groups)}")
    print(f"Cross-category edges: {len(cross_category_edges)}")
    print(f"Inter-group imports: {len(inter_group_imports)}")
    print(f"Results written to {output_path}")

if __name__ == "__main__":
    main()