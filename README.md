# Sublime Style Column Selection

Enable Sublime style 'Column Selection', allowing you to drag across lines to select a block of text with carets on each line.

Also similar to Textmate's 'Multiple Carets', or BBEdit's 'Block Select'

![](https://raw.github.com/bigfive/atom-sublime-select/master/screenshot.png)

## Usage
Hold the modifier key then click and drag with the configured mouse button across multiple lines. Dragging vertically places carets on each line at that column; dragging horizontally as well selects the text on each line.

Default key combinations are:

|Platform |Modifier Key |Mouse Button |
|---------|-------------|-------------|
|Windows  |Alt          |Left         |
|OS X     |Option       |Left         |
|Linux    |Shift        |Left         |

## Settings
The modifier key and mouse button can both be configured from the package's settings page. Available options:

### Mouse Button
- Left (default)
- Middle
- Right

### Key Trigger (default selected based on platform)
- Shift (default on linux)
- Alt/Option (default on win/mac)
- Ctrl
- None

You can require both a certain key & modifier, or trigger on either one.

### Logic Operator
- And (default)
- Or

Optionally change cursor to crosshair when selecting.

### Change Cursor to Crosshair
- true (default)
- false
