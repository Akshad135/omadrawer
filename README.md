# OmaDrawer for Omarchy

A native [Omarchy](https://omarchy.org/) status bar and drawer manager plugin that organizes and bundles your status bar widgets into clean, collapsible, slide-out drawers.

![OmaDrawer Preview](preview.png)

## Features

- **Collapsible Drawer Groups:** Bundle multiple status bar widgets into compact, expandable slide-out drawers.
- **Independent Bar Positioning:** Place individual drawer groups on the **Left**, **Center**, or **Right** bar section.
- **Per-Group Slide Direction:** Configure each drawer to expand left or right to match your screen layout.
- **Top Bar Display Mode:** Choose between **Icon**, **Name**, or **Both** (e.g. `Games`) for drawer headers on the bar.
- **Live Origin Tracking & Safe Restores:** Automatically restores un-grouped widgets back to their original bar positions when groups are modified or deleted.
- **Reorder Controls:** Arrange the order of widgets inside each drawer with simple up and down controls.
- **Icon Library:** 60+ preset icons spanning gaming, media, hardware, network, and productivity tools.
- **Dynamic Theming:** Automatically inherits colors from your active Omarchy theme (`colors.toml`).
- **IPC & CLI Integration:** Toggle the drawer manager anytime via `omarchy-shell akshad.omadrawer toggle`.

---

## Installation

Install and enable the plugin:

```bash
omarchy plugin add https://github.com/Akshad135/omadrawer.git --enable
omarchy restart shell
```

---

## Usage & Controls

- **Left-Click Drawer Header:** Slide out or collapse bundled widgets.
- **Right-Click OmaDrawer Icon:** Open the OmaDrawer Manager popup.
- **CLI / Keybinding:** Toggle manager via `omarchy-shell akshad.omadrawer toggle`.
- **Keyboard Shortcuts in Manager:**
  - `Escape`: Close popup manager.

---

## Configuration

Settings can be managed directly in the OmaDrawer Manager view:
- **Bar Position:** Assign each group to Left, Center, or Right.
- **Slide Direction:** Choose Left or Right slide expansion per group.
- **Header Display:** Set Icon, Name, or Both across bar drawers.
- **Plugin Selection:** Add active bar widgets with automatic exclusion of nested expandable drawers.

All preferences and group definitions persist safely in `~/.local/state/omarchy/plugins/akshad.omadrawer/groups.json`.

---

## Uninstallation

To disable or remove the plugin:

```bash
omarchy plugin disable akshad.omadrawer
omarchy plugin remove akshad.omadrawer
```

---

## Dependencies & Requirements

- `omarchy` / `quickshell` (status bar framework)

---

## Architecture & Security

- **Offline & Zero Network:** 100% local status bar management; zero outbound network requests or telemetry.
- **Zero Credentials:** No passwords, tokens, or private user data required or stored.
- **Safe Execution:** All background child processes use structured argument arrays without shell string interpolation.
- **Privilege Boundary:** Runs entirely as an unprivileged user process without elevated permissions or background daemons.
- **State Storage:** Settings and group configurations persist safely in `~/.local/state/omarchy/plugins/akshad.omadrawer/groups.json`.

---

## Testing

Run the automated test suite:

```bash
npm test
```

---

## License

[MIT](LICENSE) © [Akshad Agrawal](https://github.com/Akshad135)
