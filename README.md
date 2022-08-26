# Master's Thesis
[![CC BY 4.0][cc-by-shield]][cc-by]

[cc-by]: http://creativecommons.org/licenses/by/4.0/
[cc-by-shield]: https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg


## Documents
Download links for documents.

- [**PDF**](https://github.com/jaantollander/masters-thesis/blob/build/index.pdf)
- [**EPUB**](https://github.com/jaantollander/masters-thesis/blob/build/index.epub)
- [**HTML** (standalone)](https://github.com/jaantollander/masters-thesis/blob/build/index.html)


## Usage
The `env.sh ` file contains script for using Pandoc to convert content into HTML or PDF. It depends on the `pandoc`, `texlive`, `texlive-lang-european` and `inotify-tools` Linux packages. We can use it by sourcing the `env.sh` script.

```bash
source env.sh
```

Then, we can build the various documents format using the following commands.

```bash
thesis_pdf
thesis_epub
thesis_html
```

We can use the preview for automatically running a build command if files in `metadata` or `content` files change.

```bash
thesis_preview thesis_html
```
