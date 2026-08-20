# OmaDrawer for Omarchy

A native [Omarchy](https://omarchy.org/) status bar and drawer manager plugin that organizes and bundles your status bar widgets into clean, collapsible, slide-out drawers.

![OmaDrawer Preview](preview.png)

## Features

- **Collapsible Drawer Groups:** Bundle multiple top bar plugins into compact, expandable drawer groups to keep your status bar minimal and organized.
- **Independent Bar Positioning:** Place individual drawer groups on the **Left**, **Center**, or **Right** section of your top bar independently.
- **Per-Group Slide Direction:** Configure each drawer group to expand either **Left** (`󰁍`) or **Right** (`󰁔`) to perfectly match your screen edge and layout preferences.
- **Top Bar Display Mode:** Choose between **Icon**, **Name**, or **Both** (e.g. `󰵪 Media`) for drawer headers on the bar via common preferences.
- **Live Origin Tracking & Safe Restores:** Automatically restores un-grouped plugins back to their exact original bar regions (`left`, `center`, `right`) when groups are modified or deleted.
- **Smart Icon & Manifest Resolution:** Automatically discovers 3rd-party plugin SVG assets and provides 1:1 matching Nerd Font glyphs for all 1st-party Omarchy widgets.
- **Reorder Controls:** Arrange the layout order of widgets inside each drawer with simple up (`▲`) and down (`▼`) controls.
- **Icon Avatar Library:** 60+ preset icons spanning gaming, media, hardware, network, and productivity tools with custom avatar selection.
- **Dynamic Theming:** Seamlessly inherits your active Omarchy theme colors (`colors.toml`) and typography.
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

- **Left-Click Drawer Header on Bar:** Slide out or collapse bundled widgets.
- **Right-Click OmaDrawer Icon:** Open the OmaDrawer Manager popup.
- **Toggle Manager via Shortcut / CLI:** Run `omarchy-shell akshad.omadrawer toggle`.
- **Manager Navigation:**
  - **`+ Add Group`**: Create a new drawer group.
  - **`󰒓 Preferences`**: Switch between Icon, Name, or Both on the top bar.
  - **`󰏫 Edit / 󰆴 Delete`**: Modify or remove existing groups.
  - **`Escape`**: Close popup manager.

---

## Configuration

Settings can be managed directly in the OmaDrawer Manager view:
- **Bar Position:** Assign each group to Left, Center, or Right.
- **Slide Expansion:** Choose Left or Right slide expansion per group.
- **Header Display:** Set Icon, Name, or Both across bar drawers.
- **Plugin Selection:** Add active top bar widgets with automatic exclusion of nested expandable drawers.

All preferences and group definitions persist safely in `~/.local/state/omarchy/plugins/akshad.omadrawer/drawers.json`.

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
- **Privilege Boundary:** Runs entirely as an unprivileged user process without elevated permissions, root daemons, or sudoers modifications.
- **State Storage:** Settings and group configurations persist safely in `~/.local/state/omarchy/plugins/akshad.omadrawer/drawers.json`.

---

## Testing

Run the automated test suite:

```bash
npm test
```

---

## License

[MIT](LICENSE) © [Akshad Agrawal](https://github.com/Akshad135)
