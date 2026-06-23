# Export Share Templates Frames Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add offline HTML export, file-based sharing/templates, richer frame styles, faster navigation, non-obstructive playback, and a complete horizontal filmstrip.

**Architecture:** Keep sharing and template conversion in pure services under `lib/share/`, with thin UI entry points. Keep database compatibility by storing new enum names as strings. Fix track reachability in layout/track code rather than adding special viewer hacks.

**Tech Stack:** Flutter 3.41.7, Dart 3.11.5, Riverpod, Drift/SQLite, share_plus, file_picker, Flutter tests.

---

## Tasks

1. Add dependencies and pure export/template services with tests.
2. Add editor/library share and template import/export UI wiring.
3. Expand frame enum/rendering/editor labels/tests.
4. Tune camera sensitivity and remove immersive item buttons.
5. Fix filmstrip content extent and verify six-image reachability.
6. Run full verification and build release APK.
