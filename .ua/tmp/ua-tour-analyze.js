const fs = require('fs');
const path = require('path');

// Read input
const inputPath = process.argv[2];
const outputPath = process.argv[3];
const layersPath = process.argv[4]; // Optional layers file

if (!inputPath || !outputPath) {
  console.error('Usage: node ua-tour-analyze.js <input.json> <output.json> [layers.json]');
  process.exit(1);
}

const data = JSON.parse(fs.readFileSync(inputPath, 'utf-8'));
const { nodes, edges } = data;

// Read layers from separate file if provided
let layers = [];
if (layersPath) {
  try {
    const layersData = JSON.parse(fs.readFileSync(layersPath, 'utf-8'));
    layers = layersData;
  } catch (e) {
    console.error('Warning: Could not read layers file:', e.message);
  }
}

// Build adjacency lists
const fanIn = new Map();
const fanOut = new Map();
const nodeMap = new Map();

nodes.forEach(node => {
  nodeMap.set(node.id, node);
  fanIn.set(node.id, 0);
  fanOut.set(node.id, 0);
});

edges.forEach(edge => {
  if (fanIn.has(edge.target)) {
    fanIn.set(edge.target, fanIn.get(edge.target) + 1);
  }
  if (fanOut.has(edge.source)) {
    fanOut.set(edge.source, fanOut.get(edge.source) + 1);
  }
});

// A. Fan-In Ranking (Importance) - Top 20
const fanInRanking = Array.from(fanIn.entries())
  .map(([id, fanIn]) => {
    const node = nodeMap.get(id);
    return { id, fanIn, name: node?.name || id };
  })
  .sort((a, b) => b.fanIn - a.fanIn)
  .slice(0, 20);

// B. Fan-Out Ranking (Scope) - Top 20
const fanOutRanking = Array.from(fanOut.entries())
  .map(([id, fanOut]) => {
    const node = nodeMap.get(id);
    return { id, fanOut, name: node?.name || id };
  })
  .sort((a, b) => b.fanOut - a.fanOut)
  .slice(0, 20);

// C. Entry Point Candidates
const entryPointCandidates = [];
const entryFilePatterns = [
  'index.ts', 'index.js', 'main.ts', 'main.js', 'app.ts', 'app.js',
  'server.ts', 'server.js', 'mod.rs', 'main.go', 'main.py', 'main.rs',
  'manage.py', 'app.py', 'wsgi.py', 'asgi.py', 'run.py', '__main__.py',
  'Application.java', 'Main.java', 'Program.cs', 'config.ru', 'index.php',
  'App.swift', 'Application.kt', 'main.cpp', 'main.c'
];

nodes.forEach(node => {
  let score = 0;
  const name = node.name || '';
  const filePath = node.filePath || '';

  // Documentation files
  if (node.type === 'document') {
    if (name === 'README.md' && !filePath.includes('/') && !filePath.includes('\\')) {
      score += 5; // Root README
    } else if (name.endsWith('.md') && !filePath.includes('/') && !filePath.includes('\\')) {
      score += 2; // Other root markdown
    }
  }

  // Code files
  if (node.type === 'file') {
    // Filename match
    if (entryFilePatterns.some(p => name === p || name.endsWith('/' + p) || name.endsWith('\\' + p))) {
      score += 3;
    }
    // Project root or one level deep
    const depth = (filePath.match(/[\/\\]/g) || []).length;
    if (depth <= 1) {
      score += 1;
    }
    // High fan-out (top 10%)
    const fanOutVal = fanOut.get(node.id) || 0;
    const fanOutValues = Array.from(fanOut.values()).sort((a, b) => b - a);
    const top10PercentThreshold = fanOutValues[Math.floor(fanOutValues.length * 0.1)] || 0;
    if (fanOutVal >= top10PercentThreshold && top10PercentThreshold > 0) {
      score += 1;
    }
    // Low fan-in (bottom 25%)
    const fanInVal = fanIn.get(node.id) || 0;
    const fanInValues = Array.from(fanIn.values()).sort((a, b) => a - b);
    const bottom25PercentThreshold = fanInValues[Math.floor(fanInValues.length * 0.25)] || 0;
    if (fanInVal <= bottom25PercentThreshold) {
      score += 1;
    }
  }

  if (score > 0) {
    entryPointCandidates.push({
      id: node.id,
      score,
      name: node.name,
      summary: node.summary || ''
    });
  }
});

entryPointCandidates.sort((a, b) => b.score - a.score);
const topEntryPoints = entryPointCandidates.slice(0, 5);

// D. BFS from top code entry point (skip documentation)
const codeEntryPoints = topEntryPoints.filter(c => nodeMap.get(c.id)?.type === 'file');
const startNode = codeEntryPoints[0]?.id || nodes.find(n => n.type === 'file')?.id;

let bfsTraversal = {
  startNode: startNode || '',
  order: [],
  depthMap: {},
  byDepth: {}
};

if (startNode) {
  const visited = new Set();
  const queue = [{ node: startNode, depth: 0 }];
  const depthMap = {};
  const byDepth = {};

  while (queue.length > 0) {
    const { node: current, depth } = queue.shift();
    if (visited.has(current)) continue;
    visited.add(current);

    bfsTraversal.order.push(current);
    depthMap[current] = depth;
    if (!byDepth[depth]) byDepth[depth] = [];
    byDepth[depth].push(current);

    // Follow imports and calls edges forward
    edges.forEach(edge => {
      if (edge.source === current && (edge.type === 'imports' || edge.type === 'calls')) {
        if (!visited.has(edge.target)) {
          queue.push({ node: edge.target, depth: depth + 1 });
        }
      }
    });
  }

  bfsTraversal.depthMap = depthMap;
  bfsTraversal.byDepth = byDepth;
}

// E. Non-Code File Inventory
const nonCodeFiles = {
  documentation: [],
  infrastructure: [],
  data: [],
  config: []
};

nodes.forEach(node => {
  const entry = { id: node.id, name: node.name, type: node.type, summary: node.summary || '' };
  if (node.type === 'document') {
    nonCodeFiles.documentation.push(entry);
  } else if (['service', 'pipeline', 'resource'].includes(node.type)) {
    nonCodeFiles.infrastructure.push(entry);
  } else if (['table', 'schema', 'endpoint'].includes(node.type)) {
    nonCodeFiles.data.push(entry);
  } else if (node.type === 'config') {
    nonCodeFiles.config.push(entry);
  }
});

// F. Tightly Coupled Clusters
// Find bidirectional relationships
const bidirectionalPairs = new Map();
edges.forEach(edge => {
  if (edge.direction === 'bidirectional' || edge.type === 'imports') {
    const reverse = edges.find(e => e.source === edge.target && e.target === edge.source &&
      (e.direction === 'bidirectional' || e.type === 'imports'));
    if (reverse) {
      const key = [edge.source, edge.target].sort().join('|');
      if (!bidirectionalPairs.has(key)) {
        bidirectionalPairs.set(key, [edge.source, edge.target]);
      }
    }
  }
});

// Build clusters from bidirectional pairs
const clusters = [];
const processed = new Set();

bidirectionalPairs.forEach((pair, key) => {
  if (processed.has(key)) return;
  const cluster = new Set(pair);
  let expanded = true;
  while (expanded) {
    expanded = false;
    bidirectionalPairs.forEach((otherPair, otherKey) => {
      if (processed.has(otherKey)) return;
      const overlap = otherPair.filter(p => cluster.has(p)).length;
      if (overlap >= 2) {
        otherPair.forEach(p => cluster.add(p));
        processed.add(otherKey);
        expanded = true;
      }
    });
  }
  if (cluster.size >= 2 && cluster.size <= 5) {
    // Count internal edges
    let edgeCount = 0;
    const clusterArray = Array.from(cluster);
    clusterArray.forEach(a => {
      clusterArray.forEach(b => {
        if (a !== b) {
          const hasEdge = edges.some(e => e.source === a && e.target === b);
          if (hasEdge) edgeCount++;
        }
      });
    });
    clusters.push({ nodes: clusterArray, edgeCount });
  }
  processed.add(key);
});

clusters.sort((a, b) => b.edgeCount - a.edgeCount);
const topClusters = clusters.slice(0, 10);

// G. Layer List
const layerList = (layers || []).map(l => ({ id: l.id, name: l.name, description: l.description }));

// H. Node Summary Index
const nodeSummaryIndex = {};
nodes.forEach(node => {
  nodeSummaryIndex[node.id] = {
    name: node.name,
    type: node.type,
    summary: node.summary || ''
  };
});

// Output results
const results = {
  scriptCompleted: true,
  entryPointCandidates: topEntryPoints,
  fanInRanking,
  fanOutRanking,
  bfsTraversal,
  nonCodeFiles,
  clusters: topClusters,
  layers: {
    count: (layers || []).length,
    list: layerList
  },
  nodeSummaryIndex,
  totalNodes: nodes.length,
  totalEdges: edges.length
};

fs.writeFileSync(outputPath, JSON.stringify(results, null, 2));
console.log('Analysis complete. Results written to', outputPath);