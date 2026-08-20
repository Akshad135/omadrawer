# OmaDrawer

A modern plugin for the Omarchy top bar designed to group, organize, and manage top bar plugins into clean, collapsible drawers.

## Features

- **Top Bar Widget**: Compact drawer icon on the top bar with real-time status and tooltip.
- **Group Manager UI**: Popup panel inspired by the Omarchy design system.
- **Group Listing**: View all configured groups with icons, descriptions, and assigned plugin tags.
- **Add & Edit Groups**: Create custom drawer groups, select icon presets, and assign installed bar plugins.
- **Delete Groups**: Remove groups with safe confirmation prompts.
- **Persistence**: Automatically preserves group configurations in `~/.local/state/omarchy/plugins/akshad.omadrawer/groups.json`.

## Installation

Symlink this directory to Omarchy's user plugins folder:

```bash
ln -s ~/Projects/omadrawer ~/.config/omarchy/plugins/akshad.omadrawer
omarchy-shell shell rescanPlugins
```

Add `akshad.omadrawer` to your bar layout in `~/.config/omarchy/shell.json`.
