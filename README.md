# Master's Thesis
[![CC BY 4.0][cc-by-shield]][cc-by]

[cc-by]: http://creativecommons.org/licenses/by/4.0/
[cc-by-shield]: https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg

## Requirements
The `source.sh ` file contains script for using Pandoc to convert content into HTML or PDF.

- `pandoc`
- `texlive`
- `texlive-lang-european`
- `inotify-tools` for live preview

## Usage
First, we need to source the build commands.

```bash
source env.sh
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
