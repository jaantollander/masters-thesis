# Master's Thesis
- Title: *Monitoring parallel file system usage in a high-performance computer cluster*
- [Download **PDF** document](https://github.com/jaantollander/masters-thesis/blob/build/sci_2023_tollander-de-balsch_jaan.pdf)


## Usage
The `thesis` shell script convert the Markdown content to PDF via LaTeX.
It depends on the `pandoc`, `texlive`, `texlive-latex-extra`, `texlive-lang-european` and `rsvg-convert`.
We can build the various documents format using the `thesis` script with the following arguments.

```bash
./thesis pdf
```

We can use the preview for automatically running a build command if files in `metadata` or `content` files change.
It depends on `inotify-tools`.

```bash
./thesis preview pdf
```
