# Master's Thesis
*Monitoring parallel file system usage in a high-performance computer cluster*

## Documents
Download links for documents from the `build` branch.

- [**PDF**](https://github.com/jaantollander/masters-thesis/blob/build/sci_2022_tollander-de-balsch_jaan.pdf)
- [**EPUB**](https://github.com/jaantollander/masters-thesis/blob/build/sci_2022_tollander-de-balsch_jaan.epub)


## Usage
The `env.sh ` file contains script for using Pandoc to convert content into HTML or PDF.
It depends on the `pandoc`, `texlive`, `texlive-lang-european`, `inotify-tools` and `rsvg-convert` Linux packages.

We can build the various documents format using the `thesis` script with the following arguments.

```bash
./thesis pdf
./thesis epub
./thesis html
```

We can use the preview for automatically running a build command if files in `metadata` or `content` files change.

```bash
./thesis preview pdf
```
