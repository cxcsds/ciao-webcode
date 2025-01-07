#!/usr/bin/env python3

"""
Check if the *.html files under the given directory end in /
(and are not full URLs).


"""

# Argh - system has Python 3.6.....
#

from pathlib import Path
import subprocess as sbp
import sys


def get_stylesheet():
    """Return the stylesheet to use."""

    # This is a hack
    #
    thisfile = Path(__file__).absolute().resolve()
    thisdir = thisfile.parent
    xslt = thisdir / 'list_links.xsl'
    if not xslt.is_file():
        raise OSError("Unable to find '{xslt}'")

    return xslt


def check_file(xslt, infile):
    """Report potentially-suspicious links in the file."""

    comm = ["xsltproc",
            "-html",
            f"{xslt}",
            f"{infile}"
            ]

    proc = sbp.run(comm, check=True, stdout=sbp.PIPE, stderr=sbp.PIPE,
                   encoding="utf-8")
    stdout = proc.stdout.strip()
    if stdout == '':
        return set()

    return set(stdout.split("\n"))


def doit(inpath, always=False):
    """Find all the *.html files in indir and check them."""

    xslt = get_stylesheet()

    checked = 0
    seen = set()
    for m in inpath.glob("**/*.html"):
        checked += 1
        got = check_file(xslt, m)
        if always:
            ngot = got
        else:
            ngot = got.difference(seen)

        if len(ngot) == 0:
            continue

        seen = seen.union(ngot)
        print(f"# {m}")
        for g in sorted(ngot):
            print(f"  {g}")

    if checked == 0:
        raise OSError(f"No *.html in dir={inpath}")


def usage():
    sys.stderr.write(f"Usage: {sys.argv[0]} [--always] indir\n")
    sys.exit(1)


if __name__ == "__main__":

    nargs = len(sys.argv)
    if nargs < 2 or nargs > 3:
        usage()

    if nargs == 3:
        if sys.argv[1] != "--always":
            usage()

        always = True
        indir = sys.argv[2]
    else:
        always = False
        indir = sys.argv[1]

    inpath = Path(indir).absolute().resolve()
    if not inpath.is_dir():
        raise OSError(f"Not a directory: {inpath}")

    doit(inpath, always=always)
