# View

Wraps much of SketchUp's internal complexity, such as field of view
sometimes being measured vertically and sometimes horizontally, and handling
of explicit vs implicit aspect ratios.

## Installation

1. Place file inside your extension's directory, preferably in a sub-directory called vendor to distinguish it from your own code base.
2. Wrap file content in your extension's namespace.
3. Require the file from files depending on it.
