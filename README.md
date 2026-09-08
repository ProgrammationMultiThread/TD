# ProgrammationMultiThread/TD

This repository contains modular and reusable teaching materials used to build exercise sheets, practical assignments, and their corrections for the Concurrent Multithreaded Programming course at Nantes Université.

See the [course organization](https://github.com/ProgrammationMultiThread/) for the course description and additional resources.

## Repository structure

```text
├── LICENSE.txt               # CC BY-SA 4.0 legal text
├── Makefile                  # Build, configuration, and maintenance commands
├── README.md                 # This file
├── build/                    # Temporary LaTeX compilation files
├── docs/                     # Generated PDFs
├── latex-libs/               # Automatically downloaded LaTeX dependency
└── src/
    ├── courses/              # Course drivers
    ├── archives/             # Optional archived course drivers
    ├── exercises/            # Reusable exercises organized by topic
    └── img/                  # Redistributable images used in the documents
```

Every `.tex` file directly inside a subdirectory of courses is treated as a document driver. Files in `src/exercises/` can be included directly by name.

## Requirements

Compilation requires:

- GNU Make;
- a LaTeX distribution providing `pdflatex` and the packages used by the documents;
- an internet connection for the first build.

## Compilation

Build every document and its correction for the current course:

```bash
make
```

For a `td.tex` driver in the selected course, this produces:

```text
docs/<course>/td.pdf
docs/<course>/correction/td.pdf
```

The main build targets are:

```bash
make main             # Build all documents for the current course
make correction       # Build all corrections for the current course
make td               # Build both variants of td.tex
make td-main          # Build only the document, with one LaTeX pass
make td-correction    # Build only the correction, with one LaTeX pass
make all-courses      # Build all current courses, excluding archives
```

The aggregate targets use two LaTeX passes. The document-specific `-main` and `-correction` targets use one pass for faster incremental work.

To remove generated files:

```bash
make clean            # Remove temporary compilation files
make cleanall         # Also remove generated PDFs
```

## Course selection and reuse

List the available courses and document drivers:

```bash
make list
```

Select a course persistently for local work:

```bash
make configure COURSE=course-name
```

For a one-off build without changing the persistent selection:

```bash
make COURSE=course-name td
```

To create another course variant, copy an existing course directory and edit its drivers:

```bash
cp -r src/courses/existing-course src/courses/new-course
make configure COURSE=new-course
```

Course directories under `src/archives/` can be selected in exactly the same way. The `src/archives/` directory is optional, is never created automatically, and is excluded from `make all-courses`.

## Dependencies

The documents rely on styles from the [latex-libs](https://github.com/MatthieuPerrin/latex-libs) project. On the first build, the Makefile automatically clones this dependency into `latex-libs/`. Subsequent builds can run offline.

Update both this repository and the local dependency with:

```bash
make update
```

## License

Except where otherwise stated, the original LaTeX sources and teaching materials in this repository are distributed under the [Creative Commons Attribution–ShareAlike 4.0 International license](LICENSE.txt).

Third-party materials, images, code excerpts, attribution requirements, and exceptions are documented in the [organization-wide licensing notice](https://github.com/ProgrammationMultiThread/.github/blob/main/LICENSE.md).

## Contributions

Contributions are welcome. In particular, you may propose corrections, improve existing exercises or visuals, add new material, or translate existing content.

Please follow these guidelines:

- keep reusable exercises in `src/exercises/`, preferably one exercise per file;
- do not commit generated PDFs or files from `build/` and `latex-libs/`;
- ensure that contributed material is original or compatible with the repository license;
- provide the source, author, and licensing information for any third-party material;
- verify the relevant build targets before submitting a pull request.

For substantial changes, please open an issue before starting the work.
