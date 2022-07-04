# Master's Thesis
## Requirements
The `source.sh ` file contains script for using Pandoc to convert content into HTML or PDF.

- `pandoc`
- `texlive`
- `texlive-lang-european`
- `inotify-tools` for live preview

## Usage
First, we need to source the build commands.

```bash
source build.sh
```

Then, we can use them as follows. For PDF output

```bash
thesis_pdf
```

For HTML output

```bash
thesis_html
```

For automatically creating a PDF output if input files change.

```bash
thesis_preview thesis_pdf
```
