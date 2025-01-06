
# Publication code for CIAO, Sherpa, CALDB, CSC subsites

This code is used to convert XML files - in a home-grown schema - to
HTML files on the CXC website. It can be thought of as a static
website generator, but very specialized for Chandra.

## Checking the output

One concern is that the pages can be used "easily" if they are
[downloaded from the CXC website and used locally](https://cxc.harvard.edu/ciao/download/web.html). The main issue is that it is "natural" to
create a link to a directory, but for the local use case we should
append "index.html".

One way to check is to fine the HTML files and use the unused/list_links.xsl
stylesheet - e.g.

```
% xsltproc -html unused/list_links.xsl /path/to/*.html > /tmp/x.lis
... ignore this output
% sort /tmp/x.lis | uniq -c
      2 /help/
      1 threads/auxlut/
      1 threads/axbary/
      1 threads/ciao_install_conda/
      2 threads/ciao_install_tool/
      1 threads/ciao_startup/
      2 threads/createL2/
      2 threads/diffuse_emission/
      1 threads/merge_all/
      1 threads/prep_chart/
      1 threads/reproject_aspect/
```

This shows that the threadlink code needs work. The `/help/` link is
"okay" since it isn't going to work for a local download anyway.
