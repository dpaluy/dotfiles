---
name: drawbridge
description: |
  Generate Excalidraw diagrams with a hand-drawn aesthetic using Drawbridge.
  Use when user asks for: flowcharts, dependency diagrams, project visualization,
  task maps, or "make a diagram of this". Pushes elements to a live Excalidraw
  canvas via HTTP API, or renders to PNG/SVG.
---

# Drawbridge Diagram Skill

Generate hand-drawn style diagrams as Excalidraw JSON. Uses the simplified element format with `convertToExcalidrawElements` handling all the heavy lifting (text measurement, container binding, arrow routing).

## Element Format (Simplified)

Only specify what matters. `convertToExcalidrawElements` fills in all required internal properties (groupIds, frameId, seeds, versions, etc.).

### Required Fields (all elements)
`type`, `id` (unique string), `x`, `y`

### Defaults (skip these)
strokeColor="#1e1e1e", backgroundColor="transparent", fillStyle="solid", strokeWidth=2, roughness=1, opacity=100

### Labeled Shapes (PREFERRED)

Add `label` to any shape for auto-centered text. No separate text elements needed:

```json
{ "type": "rectangle", "id": "r1", "x": 100, "y": 100, "width": 200, "height": 80,
  "roundness": { "type": 3 }, "backgroundColor": "#a5d8ff", "fillStyle": "solid",
  "label": { "text": "API Server", "fontSize": 20 } }
```

- Works on rectangle, ellipse, diamond
- Text auto-centers and container auto-resizes to fit
- Always include `"roundness": { "type": 3 }` for rounded corners

### Standalone Text (titles, annotations only)

```json
{ "type": "text", "id": "t1", "x": 150, "y": 50, "text": "System Architecture", "fontSize": 28 }
```

- `x` is the LEFT edge of the text
- To center text at position cx: `x = cx - (text.length * fontSize * 0.5) / 2`
- `textAlign` does NOT control horizontal position — it only affects multi-line wrapping

### Arrows

```json
{ "type": "arrow", "id": "a1", "x": 300, "y": 150, "width": 200, "height": 0,
  "points": [[0,0],[200,0]], "endArrowhead": "arrow" }
```

- `points`: [dx, dy] offsets from element x,y
- `endArrowhead`: null | "arrow" | "bar" | "dot" | "triangle"

### Arrow Labels

Annotate arrows with text:

```json
{ "type": "arrow", "id": "a1", "x": 300, "y": 150, "width": 200, "height": 0,
  "points": [[0,0],[200,0]], "endArrowhead": "arrow",
  "label": { "text": "API call", "fontSize": 16 } }
```

### Arrow Bindings

Bind arrows to shapes so they stay connected when shapes are moved. Use `start` and `end` with the target element's `id`:

```json
{
  "type": "arrow", "id": "a1", "x": 300, "y": 150, "width": 200, "height": 0,
  "points": [[0,0],[200,0]], "endArrowhead": "arrow",
  "start": { "id": "box1" },
  "end": { "id": "box2" }
}
```

**IMPORTANT:** Use `start`/`end` (skeleton format), NOT `startBinding`/`endBinding` (internal format). `convertToExcalidrawElements` resolves the bindings automatically, including setting up `boundElements` on the target shapes.

The binding point is calculated from the arrow's position relative to the shape. Position the arrow's x,y to start at the right edge of the source shape for a left-to-right connection.

### Background Zones

Group related elements with low-opacity rectangles:

```json
{ "type": "rectangle", "id": "zone1", "x": 80, "y": 80, "width": 540, "height": 400,
  "backgroundColor": "#d3f9d8", "fillStyle": "solid", "roundness": { "type": 3 },
  "strokeColor": "#22c55e", "strokeWidth": 1, "opacity": 35 }
```

Add a zone label as standalone text:
```json
{ "type": "text", "id": "zone1-label", "x": 100, "y": 86, "text": "Frontend Layer",
  "fontSize": 16, "strokeColor": "#15803d" }
```

## Color Palette

### Primary Colors (strokes, text)
| Name | Hex | Use |
|------|-----|-----|
| Blue | `#4a9eed` | Primary actions, links |
| Amber | `#f59e0b` | Warnings, highlights |
| Green | `#22c55e` | Success, positive |
| Red | `#ef4444` | Errors, negative |
| Purple | `#8b5cf6` | Accents, special |
| Cyan | `#06b6d4` | Info, secondary |

### Fills (pastel, for shape backgrounds)
| Color | Hex | Use |
|-------|-----|-----|
| Light Blue | `#a5d8ff` | Input, sources, primary |
| Light Green | `#b2f2bb` | Success, output, completed |
| Light Orange | `#ffd8a8` | Warning, pending, external |
| Light Purple | `#d0bfff` | Processing, middleware |
| Light Red | `#ffc9c9` | Error, critical, alerts |
| Light Yellow | `#fff3bf` | Notes, decisions, planning |
| Light Teal | `#c3fae8` | Storage, data, memory |

### Background Zones (use with opacity: 30-35)
| Color | Hex | Use |
|-------|-----|-----|
| Blue zone | `#dbe4ff` | UI / frontend layer |
| Purple zone | `#e5dbff` | Logic / agent layer |
| Green zone | `#d3f9d8` | Data / tool layer |

## Sizing Rules

### Font Sizes
- **Minimum 16** for body text, labels, descriptions
- **Minimum 20** for titles and headings
- **Minimum 14** for secondary annotations only (sparingly)
- **NEVER** use fontSize below 14

### Element Sizes
- **Minimum 120x60** for labeled rectangles/ellipses
- **20-30px gaps** between elements minimum
- Prefer fewer, larger elements over many tiny ones

## Drawing Order (CRITICAL)

Array order = z-order (first = back, last = front).

**Emit progressively:** background zone → shape → its arrows → next shape

- GOOD: `zone → box1 → arrow1 → box2 → arrow2 → box3`
- BAD: `box1 → box2 → box3 → arrow1 → arrow2`

This matters for streaming to the live viewer where elements appear one at a time.

## Complete Examples

### Two Connected Labeled Boxes

```json
[
  { "type": "rectangle", "id": "b1", "x": 100, "y": 100, "width": 200, "height": 100,
    "roundness": { "type": 3 }, "backgroundColor": "#a5d8ff", "fillStyle": "solid",
    "label": { "text": "Start", "fontSize": 20 } },
  { "type": "arrow", "id": "a1", "x": 300, "y": 150, "width": 150, "height": 0,
    "points": [[0,0],[150,0]], "endArrowhead": "arrow",
    "start": { "id": "b1" },
    "end": { "id": "b2" } },
  { "type": "rectangle", "id": "b2", "x": 450, "y": 100, "width": 200, "height": 100,
    "roundness": { "type": 3 }, "backgroundColor": "#b2f2bb", "fillStyle": "solid",
    "label": { "text": "End", "fontSize": 20 } }
]
```

### System Architecture with Zones

```json
[
  { "type": "text", "id": "title", "x": 200, "y": 10, "text": "System Architecture", "fontSize": 28 },
  { "type": "rectangle", "id": "zone-fe", "x": 80, "y": 60, "width": 300, "height": 200,
    "backgroundColor": "#dbe4ff", "fillStyle": "solid", "roundness": { "type": 3 },
    "strokeColor": "#4a9eed", "strokeWidth": 1, "opacity": 35 },
  { "type": "text", "id": "zone-fe-label", "x": 100, "y": 66, "text": "Frontend",
    "fontSize": 16, "strokeColor": "#1971c2" },
  { "type": "rectangle", "id": "app", "x": 120, "y": 100, "width": 200, "height": 80,
    "roundness": { "type": 3 }, "backgroundColor": "#a5d8ff", "fillStyle": "solid",
    "label": { "text": "React App", "fontSize": 20 } },
  { "type": "arrow", "id": "a1", "x": 320, "y": 140, "width": 150, "height": 0,
    "points": [[0,0],[150,0]], "endArrowhead": "arrow",
    "label": { "text": "REST API", "fontSize": 14 } },
  { "type": "rectangle", "id": "api", "x": 470, "y": 100, "width": 200, "height": 80,
    "roundness": { "type": 3 }, "backgroundColor": "#d0bfff", "fillStyle": "solid",
    "label": { "text": "API Server", "fontSize": 20 } }
]
```

## Output Options

### 1. Push to Excalidraw Live (real-time)

Push elements to the live viewer via HTTP API:

```bash
curl -s -X POST http://localhost:3062/api/session/SESSION_NAME/elements \
  -H "Content-Type: application/json" \
  -d '{"elements": [...]}'
```

Live viewer URL: `http://localhost:3060/#SESSION_NAME` (or your configured host)

API endpoints:
- `POST /api/session/:id/elements` — Replace all elements
- `POST /api/session/:id/append` — Add elements to existing
- `POST /api/session/:id/clear` — Clear canvas
- `POST /api/session/:id/undo` — Undo last operation
- `GET /api/session/:id` — Get current elements

### 2. Save as .excalidraw file

Wrap elements in the document structure:

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [ /* your elements array */ ],
  "appState": { "viewBackgroundColor": "#ffffff", "gridSize": null },
  "files": {}
}
```

### 3. Render to SVG or PNG

```bash
# From .excalidraw file (skeleton or resolved elements both work)
npx tsx scripts/render.ts input.excalidraw output.png
npx tsx scripts/render.ts input.excalidraw output.svg

# From a live session
curl -s http://localhost:3062/api/session/SESSION_NAME | \
  python3 -c "import json,sys; d=json.load(sys.stdin); json.dump({'type':'excalidraw','version':2,'source':'https://excalidraw.com','elements':d['elements'],'appState':{'viewBackgroundColor':'#ffffff','gridSize':None},'files':{}}, open('/tmp/diagram.excalidraw','w'))"
npx tsx scripts/render.ts /tmp/diagram.excalidraw /tmp/diagram.png
```

Uses headless Chromium + Excalidraw 0.18. Handles skeleton elements (with `label`, `start`/`end`) automatically via `convertToExcalidrawElements`. Takes ~5-8 seconds.

## Generation Workflow

1. **Plan layout** — Decide zones, flow direction, element grouping
2. **Generate elements** — Follow progressive drawing order
3. **Push to live viewer** — For real-time review with user
4. **Render to PNG/SVG** — For embedding in docs, reports, or sharing
