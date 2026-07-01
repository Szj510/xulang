# Delete Images and Cinematic Layouts Design

## Goal

Add editor-side deletion for a photo placement, then add three new cinematic gallery layouts: Scroll Journey, Wind Book, and Firework Cascade.

## Placement deletion

The editor image panel will expose a destructive “delete image” action for the selected placement. The action removes only the current chapter placement, not the underlying media asset. This preserves reuse across chapters and avoids deleting copied or referenced originals unexpectedly. After deletion the editor selects the next placement in the same chapter, then the previous placement if there is no next item, otherwise it returns to canvas mode.

## Layout concepts

### Scroll Journey

Scroll Journey is a long handscroll composition. In portrait it moves top-to-bottom through an ordered zig-zag path; photos alternate left, right, and center with subtle rotation and shadow. In landscape it becomes a horizontal scroll with vertical zig-zag variation. The layout remains deterministic and order-preserving.

### Wind Book

Wind Book presents photos as discoveries inside wind-turned pages. v1 uses Flutter transforms and custom painting rather than a true page mesh. Photos sit on page surfaces, with nearby pages slightly tilted or offset to suggest a breeze flipping through paper. The selected photo receives the strongest focus while preceding and following pages create depth.

### Firework Cascade

Firework Cascade arranges photos from a central burst into falling trajectories. The canvas paints spark particles and tails behind the ordered photos. Photo positions remain deterministic by index, while scale and rotation suggest photos released by a firework bloom. A lightweight built-in firework sound hook will be added for this layout; if runtime audio triggering needs additional polishing later, the data/model path will already be present.

## Data and rendering

`GalleryLayout` gains three values: `scrollJourney`, `windBook`, and `fireworkCascade`. `LayoutResolver` maps each layout into `ResolvedSceneNode` positions and transforms. `SceneCanvas` adds painter details where needed, with reduced-motion compatibility by keeping the geometry static and limiting extra particles.

## Testing

Tests cover:

- editor placement deletion behavior;
- layout resolver output for all three layouts;
- visible localized layout labels;
- golden coverage will be extended only if the new layouts are included in the existing golden matrix.

