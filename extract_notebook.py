#!/usr/bin/env python

"""

Usage:

  ./extract_notebook.py nbfile outdir

Aim:

Extract the notebook components - that is the HTML of the
notebook and the PNG files - and write them to the output
directory. The screen output lists, one per line, the
names of the files that are created.

This requires that the folowing Python packages are installed:
  nbconvert >= 6.0

"""

import os
import sys

import nbformat

from traitlets.config import Config

from nbconvert import HTMLExporter


def convert(nbfile, outdir):

    if not nbfile.endswith('.ipynb'):
        raise ValueError(f'nbfile does not end in .ipynb - {nbfile}')

    if not os.path.isdir(outdir):
        raise IOError(f'Output directory does not exist: {outdir}')

    head = nbfile[:-6]

    with open(nbfile, 'r') as fh:
        nb = nbformat.reads(fh.read(), as_version=4)

    thisdir = os.path.dirname(os.path.realpath(__file__))

    # Convert the header
    #
    config = Config()
    config.HTMLExporter.template_file = os.path.join(thisdir, 'templates', 'fakehdr.html.j2')

    exporter = HTMLExporter(config=config)
    (body, resources) = exporter.from_notebook_node(nb)

    # Write out the body
    out = os.path.join(outdir, f'{head}-head')
    open(out, 'w').write(body)
    print(out)

    # Convert the main body
    #
    config = Config()
    config.HTMLExporter.preprocessors = ['nbconvert.preprocessors.ExtractOutputPreprocessor']
    config.ExtractOutputPreprocessor.output_filename_template = head + '_{unique_key}_{cell_index}_{index}{extension}'

    config.HTMLExporter.template_file = os.path.join(thisdir, 'templates', 'index.html.j2')

    exporter = HTMLExporter(config=config)
    (body, resources) = exporter.from_notebook_node(nb)

    # Write out the body
    out = os.path.join(outdir, head)
    open(out, 'w').write(body)
    print(out)

    # Write out the file contents
    for key, cnt in resources['outputs'].items():

        out = os.path.join(outdir, key)
        open(out, 'wb').write(cnt)
        print(out)


if __name__ == "__main__":

    if len(sys.argv) != 3:
        sys.stderr.write(f"Usage: {sys.argv[0]} nbfile outdir\n")
        sys.exit(1)

    convert(sys.argv[1], sys.argv[2])
