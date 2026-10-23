# Jupyter notebooks in Neovim

Open an existing notebook with `nvim analysis.ipynb`, or create one with
`:NewNotebook analysis`. The command also accepts an `.ipynb` extension and refuses
to overwrite an existing file. Choose a registered Python kernel when prompted.
Parent directories must already exist.

Neovim displays Markdown and fenced Python cells. The file on disk stays a Jupyter
notebook. For example, the starter notebook contains a title and this cell:

````markdown
# Notebook

```python
print(1 + 1)
```
````

Press `\ni`, choose your project's kernel, and wait for Molten's kernel-ready message.
Put your cursor on `print(1 + 1)` and press `\rc`. The output should be `2`.
Press `:w` to save both your edits and the outputs.
These shortcuts are normal-mode keys typed in sequence, not held together.
The local leader is a backslash in this configuration.

| Keys | Action |
| --- | --- |
| `\ni` | Choose a kernel and import saved notebook outputs |
| `\rc` | Run the cell under the cursor |
| `\ra` | Run all cells above, including the current cell |
| `\rb` | Run the current cell and all cells below |
| `\rA` | Run all cells of the current cell's language |
| `\rl` | Run the current line |
| `\r` in visual mode | Run the cells touched by the selection |
| `]c` / `[c` | Jump to the next / previous Python cell |
| `\os` / `\oh` | Enter / hide the output window |
| `\ox` | Open rich cell output in a browser |
| `\ri` | Interrupt a running computation |
| `\rr` | Restart the kernel |

Add a new code cell by inserting another fenced `python` block. Write Markdown
between the blocks for explanations. `gd`, `K`, and your existing completion menu
work inside Python cells through Pyright and Otter. Keybindings also work in Quarto
files. Ordinary Markdown files keep their existing behavior.

Opening a notebook does not start a kernel or run its code. `\ni` starts the selected
kernel and imports existing outputs without executing the notebook. Variables stay
in that kernel until you restart it or close the notebook. If a later cell uses a
variable from an earlier cell, run the earlier cell first. `\rA` is useful for
checking that the notebook runs in order.

## Plots and rich output

Install Matplotlib in your project's kernel environment to run this example:

```python
%matplotlib inline
import matplotlib.pyplot as plt
plt.plot([1, 2, 3], [1, 4, 9])
plt.show()
```

Image output uses image.nvim with ImageMagick's CLI. It is enabled automatically
when Neovim detects Ghostty or Kitty, and disabled in headless sessions. Tmux needs
these settings, which were added to `~/.tmux.conf` and applied to the running server:

```tmux
set -g allow-passthrough on
set -g visual-activity off
set -g focus-events on
```

If terminal detection is wrong, use `NVIM_NOTEBOOK_IMAGES=1 nvim analysis.ipynb`
to enable images or `NVIM_NOTEBOOK_IMAGES=0 nvim analysis.ipynb` to disable them.
An override cannot add graphics support to an incompatible terminal. HTML widgets
are not interactive inside Neovim; use `\ox` for browser output when supported.

## Using a project's Python environment

To install a package from a notebook cell, use `%pip install pandas`, rather than
`!pip install pandas`. `%pip` runs pip through the current kernel's Python;
`!pip` asks the shell to find an executable, which can select the system installer.
Each project's kernel needs its own pip installation. Restart the kernel after installing or upgrading packages
if imports still use old versions.

For example, check which environment a notebook is using with:

```python
import sys
print(sys.executable)
```

This should point to your project's Python executable, such as `.venv/bin/python`.

The editor's Python host is separate from notebook kernels. The host loads Molten
and converts files; the selected kernel runs your code. Keeping them separate means
a project's package changes do not remove the editor's notebook tools.

For example, register a project's environment as a kernel:

```sh
uv venv .venv
uv pip install --python .venv/bin/python ipykernel pip pandas numpy matplotlib
.venv/bin/python -m ipykernel install --user --name my-project --display-name 'Python (my-project)'
source .venv/bin/activate
nvim analysis.ipynb
```

Choose `Python (my-project)` with `\ni`. Starting Neovim with that environment
activated also tells Pyright which Python interpreter to inspect for completions.
Use `:MoltenDeinit` before choosing a different kernel in the same buffer.

## Installation and maintenance

The current machine has the plugins, editor's Python environment, and parsers installed.
Register a project's kernel separately using the instructions above.
Restart Neovim after changing this configuration.

To recreate the Python tools on another machine, run these commands from this config
directory. With custom XDG settings, use `:echo stdpath('data')` instead of the path below.

```sh
uv venv ~/.local/share/nvim/jupyter-venv --python python3
uv pip install --python ~/.local/share/nvim/jupyter-venv/bin/python -r requirements-notebooks.txt
~/.local/share/nvim/jupyter-venv/bin/python -c 'from pathlib import Path; from jupyter_core.paths import jupyter_runtime_dir; Path(jupyter_runtime_dir()).mkdir(parents=True, exist_ok=True, mode=0o700)'
```

You also need ImageMagick, a C compiler, and the tree-sitter CLI on your PATH.
This machine uses tree-sitter CLI 0.27.1 in `~/.local/bin/tree-sitter`.
Neovim's built-in Python provider uses the dedicated environment automatically;
Jupytext is added to Neovim's PATH without changing your shell's PATH.

Run `:Lazy restore` to install the locked plugin versions. Then run
`:UpdateRemotePlugins` and restart Neovim. Treesitter installs the `markdown`,
`markdown_inline`, `python`, and `yaml` parsers. Pyright is already installed through
Mason on this machine; on a new machine, run `:MasonInstall pyright`.
The Quarto CLI is not needed for this notebook workflow. `:QuartoPreview` is a
separate publishing feature that requires it.

Jupytext uses a sibling Markdown file while a notebook is open and normally removes
it when the buffer unloads. If a same-name `.md` file already exists, Jupytext uses
that file and leaves it in place. Avoid keeping unrelated `analysis.md` and
`analysis.ipynb` files together.

Molten's output import/export is experimental and matches cells by their code.
Repeated identical cells and running only part of a cell can make saved output
matching ambiguous. Prefer running whole cells. Existing outputs are preserved by
Jupytext for unchanged cells; new outputs are exported after conversion on `:w`.
Automatic output export expects one kernel per notebook. If you manually attach
several, saving gives a warning so you can export from the intended kernel explicitly.

For troubleshooting, use `:MoltenInfo`, `:checkhealth molten`, and `:checkhealth vim.provider`.
If Molten commands are missing, rerun `:UpdateRemotePlugins` and restart.

## Why these plugins

- Jupytext converts notebook JSON into editable Markdown and updates the original notebook on save.
- Molten sends code to Jupyter kernels and displays and saves the results.
- Quarto identifies code cells and offers run-cell and run-all commands.
- Otter gives the Python language server a Python-only view of those cells.
- Treesitter parses Markdown cell boundaries and provides syntax highlighting.
- image.nvim displays plot images through the terminal's graphics protocol.

The Python-cell alternative needs less Markdown integration, but displays prose as
comments. The browser workflow handles interactive widgets better, but requires a
browser window and synchronization. This setup uses the Markdown workflow you chose.

References: [Molten notebook setup](https://github.com/benlubas/molten-nvim/blob/main/docs/Notebook-Setup.md),
[Quarto configuration](https://github.com/quarto-dev/quarto-nvim),
[Jupytext](https://github.com/GCBallesteros/jupytext.nvim),
and [image.nvim terminal requirements](https://github.com/3rd/image.nvim#dependencies).
