#!/usr/bin/env node
/**
 * Knowledge Graph Validation Script
 * Reads assembled-graph.json, layers.json, tour.json and validates them
 */

const fs = require('fs');
const path = require('path');

// Valid node types (16 total: 13 structural + 3 domain)
const VALID_NODE_TYPES = new Set([
  'file', 'function', 'class', 'module', 'concept', 'config', 'document',
  'service', 'table', 'endpoint', 'pipeline', 'schema', 'resource',
  'domain', 'flow', 'step'
]);

// Valid edge types (29 total: 26 structural + 3 domain)
const VALID_EDGE_TYPES = new Set([
  'imports', 'exports', 'contains', 'inherits', 'implements', 'calls',
  'subscribes', 'publishes', 'middleware', 'reads_from', 'writes_to',
  'transforms', 'validates', 'depends_on', 'tested_by', 'configures',
  'related', 'similar_to', 'deploys', 'serves', 'migrates', 'documents',
  'provisions', 'routes', 'defines_schema', 'triggers', 'contains_flow',
  'flow_step', 'cross_domain'
]);

// Valid node ID prefixes
const VALID_PREFIXES = [
  'file:', 'function:', 'class:', 'module:', 'concept:', 'config:',
  'document:', 'service:', 'table:', 'endpoint:', 'pipeline:', 'schema:',
  'resource:', 'domain:', 'flow:', 'step:'
];

// File-level node types (must appear in layers)
const FILE_LEVEL_TYPES = new Set([
  'file', 'config', 'document', 'service', 'pipeline', 'table',
  'schema', 'resource', 'endpoint'
]);

// Non-code node types with expected edge types
const NON_CODE_NODE_EXPECTATIONS = {
  'document': ['documents'],
  'service': ['deploys', 'depends_on'],
  'pipeline': ['triggers'],
  'table': ['migrates', 'defines_schema'],
  'schema': ['defines_schema'],
  'domain': ['contains_flow'],
  'flow': ['flow_step']
};

// Helper functions
function isValidPrefix(id) {
  return VALID_PREFIXES.some(prefix => id.startsWith(prefix));
}

function getPrefixFromType(type) {
  const prefixMap = {
    'file': 'file:',
    'function': 'function:',
    'class': 'class:',
    'module': 'module:',
    'concept': 'concept:',
    'config': 'config:',
    'document': 'document:',
    'service': 'service:',
    'table': 'table:',
    'endpoint': 'endpoint:',
    'pipeline': 'pipeline:',
    'schema': 'schema:',
    'resource': 'resource:',
    'domain': 'domain:',
    'flow': 'flow:',
    'step': 'step:'
  };
  return prefixMap[type];
}

function isFilenameOnly(summary, name) {
  // Check if summary is just the filename or equals the name
  if (!summary || summary.trim() === '') return true;
  if (summary === name) return true;
  // Check if summary is just a filename (no path separators, has extension)
  const filenameMatch = summary.match(/^[^\/\\]+\.[a-zA-Z0-9]+$/);
  if (filenameMatch && summary === path.basename(name)) return true;
  // Check if summary is just the file path
  if (summary === name) return true;
  return false;
}

function validateNode(node, index, issues, warnings, nodeIdSet, nodeIdToIndex) {
  // Check required fields
  if (!node.id || typeof node.id !== 'string' || node.id.trim() === '') {
    issues.push(`Node at index ${index}: missing or empty 'id' field`);
    return;
  }

  // Check duplicate IDs
  if (nodeIdSet.has(node.id)) {
    issues.push(`Duplicate node ID '${node.id}' at indices ${nodeIdToIndex.get(node.id).join(', ')} and ${index}`);
    return;
  }
  nodeIdSet.add(node.id);
  if (!nodeIdToIndex.has(node.id)) nodeIdToIndex.set(node.id, []);
  nodeIdToIndex.get(node.id).push(index);

  // Validate ID prefix convention
  if (!isValidPrefix(node.id)) {
    issues.push(`Node at index ${index} (id: '${node.id}'): invalid ID prefix, must start with one of: ${VALID_PREFIXES.join(', ')}`);
  }

  // Validate type
  if (!node.type || typeof node.type !== 'string') {
    issues.push(`Node '${node.id}': missing or invalid 'type' field`);
  } else if (!VALID_NODE_TYPES.has(node.type)) {
    issues.push(`Node '${node.id}': invalid type '${node.type}', must be one of: ${Array.from(VALID_NODE_TYPES).join(', ')}`);
  } else {
    // Check type/prefix consistency
    const expectedPrefix = getPrefixFromType(node.type);
    if (expectedPrefix && !node.id.startsWith(expectedPrefix)) {
      warnings.push(`Node '${node.id}': type '${node.type}' does not match ID prefix (expected '${expectedPrefix}')`);
    }
  }

  // Validate name
  if (!node.name || typeof node.name !== 'string' || node.name.trim() === '') {
    issues.push(`Node '${node.id}': missing or empty 'name' field`);
  }

  // Validate summary
  if (!node.summary || typeof node.summary !== 'string' || node.summary.trim() === '') {
    issues.push(`Node '${node.id}': missing or empty 'summary' field`);
  } else if (isFilenameOnly(node.summary, node.name)) {
    warnings.push(`Node '${node.id}': summary appears to be just a filename or duplicates the name`);
  }

  // Validate tags
  if (!node.tags || !Array.isArray(node.tags) || node.tags.length === 0) {
    issues.push(`Node '${node.id}': missing or empty 'tags' array (must have at least 1 element)`);
  } else {
    for (const tag of node.tags) {
      if (typeof tag !== 'string' || tag !== tag.toLowerCase() || tag.includes(' ')) {
        warnings.push(`Node '${node.id}': tag '${tag}' should be lowercase and hyphenated`);
      }
    }
  }

  // Validate complexity
  if (!node.complexity || !['simple', 'moderate', 'complex'].includes(node.complexity)) {
    issues.push(`Node '${node.id}': invalid complexity '${node.complexity}', must be one of: simple, moderate, complex`);
  }
}

function validateEdge(edge, index, issues, warnings, nodeIdSet) {
  // Check required fields
  if (!edge.source || typeof edge.source !== 'string' || edge.source.trim() === '') {
    issues.push(`Edge at index ${index}: missing or empty 'source' field`);
    return;
  }
  if (!edge.target || typeof edge.target !== 'string' || edge.target.trim() === '') {
    issues.push(`Edge at index ${index}: missing or empty 'target' field`);
    return;
  }
  if (!edge.type || typeof edge.type !== 'string') {
    issues.push(`Edge at index ${index}: missing or invalid 'type' field`);
    return;
  }
  if (!edge.direction || typeof edge.direction !== 'string') {
    issues.push(`Edge at index ${index}: missing or invalid 'direction' field`);
    return;
  }
  if (typeof edge.weight !== 'number' || isNaN(edge.weight)) {
    issues.push(`Edge at index ${index}: missing or invalid 'weight' field`);
    return;
  }

  // Validate edge type
  if (!VALID_EDGE_TYPES.has(edge.type)) {
    issues.push(`Edge at index ${index} ('${edge.source}' -> '${edge.target}'): invalid type '${edge.type}', must be one of: ${Array.from(VALID_EDGE_TYPES).join(', ')}`);
  }

  // Validate direction
  if (!['forward', 'backward', 'bidirectional'].includes(edge.direction)) {
    issues.push(`Edge at index ${index} ('${edge.source}' -> '${edge.target}'): invalid direction '${edge.direction}', must be one of: forward, backward, bidirectional`);
  }

  // Validate weight
  if (edge.weight < 0.0 || edge.weight > 1.0) {
    issues.push(`Edge at index ${index} ('${edge.source}' -> '${edge.target}'): weight ${edge.weight} must be between 0.0 and 1.0`);
  }

  // Referential integrity
  if (!nodeIdSet.has(edge.source)) {
    issues.push(`Edge at index ${index}: source node '${edge.source}' does not exist`);
  }
  if (!nodeIdSet.has(edge.target)) {
    issues.push(`Edge at index ${index}: target node '${edge.target}' does not exist`);
  }

  // Self-referencing edge (warning)
  if (edge.source === edge.target) {
    warnings.push(`Edge at index ${index}: self-referencing edge (source === target === '${edge.source}')`);
  }
}

function validateLayers(layers, issues, warnings, nodeIdSet, isDomainGraph) {
  if (!layers || layers.length === 0) {
    if (isDomainGraph) {
      warnings.push('No layers defined (domain graph - relaxed check)');
    } else {
      issues.push('No layers defined (at least 1 layer required for structural graphs)');
    }
    return;
  }

  const nodeToLayerCount = new Map();

  for (let i = 0; i < layers.length; i++) {
    const layer = layers[i];
    if (!layer.nodeIds || !Array.isArray(layer.nodeIds)) {
      issues.push(`Layer at index ${i}: missing or invalid 'nodeIds' array`);
      continue;
    }
    if (layer.nodeIds.length === 0) {
      warnings.push(`Layer '${layer.id || i}': empty nodeIds array`);
    }
    for (const nodeId of layer.nodeIds) {
      if (!nodeIdSet.has(nodeId)) {
        issues.push(`Layer '${layer.id || i}': references non-existent node '${nodeId}'`);
      }
      // Count layer membership
      nodeToLayerCount.set(nodeId, (nodeToLayerCount.get(nodeId) || 0) + 1);
    }
  }

  // Check file-level nodes appear in exactly one layer (structural graphs only)
  if (!isDomainGraph) {
    for (const [nodeId, count] of nodeToLayerCount) {
      // We need to check the node type - but we don't have node objects here
      // This check is best done with the full graph data
    }
  }
}

function validateTour(tour, issues, warnings, nodeIdSet) {
  if (!tour || tour.length === 0) {
    warnings.push('No tour steps defined');
    return;
  }

  const orders = new Set();
  let hasValidSteps = false;

  for (let i = 0; i < tour.length; i++) {
    const step = tour[i];
    if (!step.nodeIds || !Array.isArray(step.nodeIds) || step.nodeIds.length === 0) {
      warnings.push(`Tour step at index ${i}: missing or empty 'nodeIds' array`);
      continue;
    }
    hasValidSteps = true;

    if (typeof step.order !== 'number' || !Number.isInteger(step.order) || step.order < 1) {
      warnings.push(`Tour step at index ${i}: invalid 'order' value '${step.order}', must be positive integer`);
    } else if (orders.has(step.order)) {
      warnings.push(`Tour step at index ${i}: duplicate order value ${step.order}`);
    }
    orders.add(step.order);

    for (const nodeId of step.nodeIds) {
      if (!nodeIdSet.has(nodeId)) {
        issues.push(`Tour step at index ${i} (order ${step.order}): references non-existent node '${nodeId}'`);
      }
    }
  }

  if (hasValidSteps) {
    const orderValues = Array.from(orders).sort((a, b) => a - b);
    // Check sequential from 1
    for (let i = 0; i < orderValues.length; i++) {
      if (orderValues[i] !== i + 1) {
        warnings.push(`Tour orders not sequential starting from 1: got ${orderValues.join(', ')}`);
        break;
      }
    }
    // Check step count
    if (orderValues.length < 5 || orderValues.length > 15) {
      warnings.push(`Tour has ${orderValues.length} steps, recommended range is 5-15`);
    }
  }
}

function validateOrphans(nodes, edges, warnings, nodeIdSet) {
  const connectedNodes = new Set();
  for (const edge of edges) {
    connectedNodes.add(edge.source);
    connectedNodes.add(edge.target);
  }

  const orphanNodes = [];
  for (const node of nodes) {
    if (!connectedNodes.has(node.id)) {
      orphanNodes.push(node.id);
    }
  }

  if (orphanNodes.length > 0) {
    warnings.push(`${orphanNodes.length} orphan node(s) with no edges: ${orphanNodes.slice(0, 10).join(', ')}${orphanNodes.length > 10 ? '...' : ''}`);
  }
}

function validateNonCodeNodes(nodes, edges, warnings) {
  // Build adjacency map for quick lookup
  const outgoingEdges = new Map();
  for (const edge of edges) {
    if (!outgoingEdges.has(edge.source)) outgoingEdges.set(edge.source, []);
    outgoingEdges.get(edge.source).push(edge.type);
  }

  for (const node of nodes) {
    const expectedTypes = NON_CODE_NODE_EXPECTATIONS[node.type];
    if (!expectedTypes) continue;

    const nodeOutgoing = outgoingEdges.get(node.id) || [];
    const hasExpected = expectedTypes.some(t => nodeOutgoing.includes(t));

    if (!hasExpected) {
      warnings.push(`${node.type} node '${node.id}' has no expected edge types: ${expectedTypes.join(' or ')}`);
    }
  }
}

function computeStats(nodes, edges) {
  const nodeTypes = {};
  const edgeTypes = {};

  for (const node of nodes) {
    nodeTypes[node.type] = (nodeTypes[node.type] || 0) + 1;
  }
  for (const edge of edges) {
    edgeTypes[edge.type] = (edgeTypes[edge.type] || 0) + 1;
  }

  return { nodeTypes, edgeTypes };
}

// Main validation function
async function main() {
  const graphPath = process.argv[2];
  const outputPath = process.argv[3];

  if (!graphPath || !outputPath) {
    console.error('Usage: node ua-graph-validate.js <graph-file> <output-file>');
    process.exit(1);
  }

  let graph, layers, tour;

  try {
    graph = JSON.parse(fs.readFileSync(graphPath, 'utf-8'));
  } catch (e) {
    console.error(`Failed to read/parse graph file: ${e.message}`);
    process.exit(1);
  }

  try {
    const layersPath = path.join(path.dirname(graphPath), 'layers.json');
    layers = JSON.parse(fs.readFileSync(layersPath, 'utf-8'));
  } catch (e) {
    console.error(`Failed to read/parse layers.json: ${e.message}`);
    process.exit(1);
  }

  try {
    const tourPath = path.join(path.dirname(graphPath), 'tour.json');
    tour = JSON.parse(fs.readFileSync(tourPath, 'utf-8'));
  } catch (e) {
    console.error(`Failed to read/parse tour.json: ${e.message}`);
    process.exit(1);
  }

  const issues = [];
  const warnings = [];
  const nodeIdSet = new Set();
  const nodeIdToIndex = new Map();

  const nodes = graph.nodes || [];
  const edges = graph.edges || [];

  // Check 1 & 5: Schema validation and uniqueness
  for (let i = 0; i < nodes.length; i++) {
    validateNode(nodes[i], i, issues, warnings, nodeIdSet, nodeIdToIndex);
  }

  // Check 2: Referential integrity for edges
  for (let i = 0; i < edges.length; i++) {
    validateEdge(edges[i], i, issues, warnings, nodeIdSet);
  }

  // Check 3: Completeness
  if (nodes.length === 0) {
    issues.push('Graph has zero nodes');
  }
  if (edges.length === 0) {
    issues.push('Graph has zero edges');
  }

  // Detect domain graph
  const isDomainGraph = nodes.some(n => ['domain', 'flow', 'step'].includes(n.type));

  // Check 4: Layer coverage
  validateLayers(layers, issues, warnings, nodeIdSet, isDomainGraph);

  // Additional layer coverage check: file-level nodes in exactly one layer
  if (!isDomainGraph && layers.length > 0) {
    const nodeToLayerCount = new Map();
    for (const layer of layers) {
      if (layer.nodeIds && Array.isArray(layer.nodeIds)) {
        for (const nodeId of layer.nodeIds) {
          nodeToLayerCount.set(nodeId, (nodeToLayerCount.get(nodeId) || 0) + 1);
        }
      }
    }

    const fileLevelNodes = nodes.filter(n => FILE_LEVEL_TYPES.has(n.type));
    for (const node of fileLevelNodes) {
      const count = nodeToLayerCount.get(node.id) || 0;
      if (count === 0) {
        issues.push(`File-level node '${node.id}' (type: ${node.type}) does not appear in any layer`);
      } else if (count > 1) {
        issues.push(`File-level node '${node.id}' (type: ${node.type}) appears in ${count} layers (must be exactly 1)`);
      }
    }
  }

  // Check 6: Tour validation
  validateTour(tour, issues, warnings, nodeIdSet);

  // Check 7: Quality checks
  validateOrphans(nodes, edges, warnings, nodeIdSet);

  // Check 8: Non-code node quality checks
  validateNonCodeNodes(nodes, edges, warnings);

  // Check 9: Node type / ID prefix consistency (already done in validateNode)

  // Compute stats
  const { nodeTypes, edgeTypes } = computeStats(nodes, edges);

  const result = {
    scriptCompleted: true,
    issues,
    warnings,
    stats: {
      totalNodes: nodes.length,
      totalEdges: edges.length,
      totalLayers: layers.length,
      tourSteps: tour.length,
      nodeTypes,
      edgeTypes
    }
  };

  fs.writeFileSync(outputPath, JSON.stringify(result, null, 2));
  console.log(`Validation complete. Issues: ${issues.length}, Warnings: ${warnings.length}`);
  process.exit(0);
}

main().catch(err => {
  console.error(`Script error: ${err.message}`);
  process.exit(1);
});