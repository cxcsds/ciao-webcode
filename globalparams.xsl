<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * List of "global" templates for the web-page stylesheets
    *
    * Note:
    *  Not all pages need all these parameters but it's easier to have
    *  them all in one place
    *
    * User-defineable parameters:
    *  . type="test"|"live"
    *    whether to create the test or "real" version
    *
    *  . ignoremissinglink="yes"|"no" ("no" is the default)
    *    by default the code will complain and error out if *some* links
    *    are missing (e.g. if there is an invalid dictionary link). However,
    *    this can lead to circular dependencies, so set this to yes to
    *    turn it into a warning rather than an error. Very likely
    *    incomplete - i.e. not added to all places it should be
    *
    *  . lastmod=string to use to say when page was last modified
    *  . lastmodiso=string to use to say when page was last modified
    *               in format YYYY-MM-DD
    *
    *  . site=one of: ciao chart chips sherpa pog icxc
    *    tells the stylesheet what site we are working with
    *
    *  . ahelpindex=full path to ahelp index file created by mk_ahelp_setup.pl
    *    something like /data/da/Docs/ciaoweb/published/ciao3/live/ahelp/ahelpindex.xml
    *    Used to work out the ahelp links
    *
    *  . cssfile=partial url to identify CSS sheet for the page
    *  . cssprintfile=partial url to identify CSS sheet for the page (media=print)
    *
    *  . newsfile=full path to the file containing the news for the "what's new" link
    *  . newsfileurl=URL to use for the "what's new" link
    *
    *  . watchouturl=URL to use for the "watch out" link
    *
    *  . navbarlink=url of link to highlight in navbar (should equate to this file)
    *    currently NOT used (code commented out in helper.xsl)
    *
    *  . searchssi=location of file for ssi inclusion to give the search bar
    *    defaults to /incl/search.html
    *
    *  . install=full path to directory where to install file
    *
    *  . canonicalbase=URL of parent directory (including trailing hash), so the
    *    full url is canonicalbase + pagename + '.html'. Overlaps with url/outurl
    *    and all this mess needs to be cleaned up. Since this is used for the
    *    canonical link header the URL should probably not be versioned, e.g.
    *    use http://cxc.harvard.edu/ciao/ rather than http://cxc.harvard.edu/ciao4.5/
    *
    *  . pagename=name of page (ie without .xml or .html)
    *
    *  . url=URL of page (on live server)
    *  . outurl=This appears to be the "base" url (ie the directory containing the page)
    *    SEE ALSO canonicalbase
    *
    *  . favicon=URL of the favicon for the site (optional)
    *
    *  . sourcedir=full path to directory containing navbar.xml
    *
    *  . depth=depth of the file
    *
    *  . updateby=name of person doing the update
    *
    *  . siteversion=version number of the site
    *    ony used by CIAO pages for now
    *
    *  . titlepostfix=text to add to title of page for HTML header
    *      HTML title = page title + " " + titlepostfix
    *    if titlepostfix != ''
    *
    *    THIS PARAMETER IS BEING PHASED OUT AND IS CURRENTLY ONLY SUPPORTED
    *    FOR THREADS
    *
    *  . storageloc - string, optional, default=''
    *    points to an XML file that contains the "storage" directories
    *    for the different sites for this version and type (live,...).
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:func="http://exslt.org/functions"
  xmlns:djb="http://hea-www.harvard.edu/~dburke/xsl/"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="func djb extfuncs">

  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-globalparams" select="extfuncs:register-import-dependency('globalparams.xsl')"/>

  <!--* 
      * Temporary:
      * Swap between using LaTeX to create PNG of equations
      * and MathJax for in-line display with this hard-coded
      * parameter. Could combine use-mathjax and mathjax-path
      * (ie use-mathjax=1 is the same as mathjaxpath != '').
      *-->
  <xsl:param name="use-mathjax" select='0'/>
  <xsl:param name="mathjaxpath" select='""'/>

  <!--* these should be over-ridden from the command line *-->

  <xsl:param name="cssfile"      select='""'/>
  <xsl:param name="cssprintfile" select='""'/>
  <xsl:param name="site"         select='""'/>
  <xsl:param name="install"      select='""'/>
  <xsl:param name="canonicalbase" select='""'/>
  <xsl:param name="pagename"     select='""'/>
  <xsl:param name="navbarlink"   select='""'/>
  <xsl:param name="url"          select='""'/>
  <xsl:param name="outurl"       select='""'/>
  <xsl:param name="favicon"      select='""'/>
  <xsl:param name="sourcedir"    select='""'/>
  <xsl:param name="updateby"     select='""'/>
  <xsl:param name="siteversion"  select='""'/>
  <xsl:param name="lastmod"      select='""'/>
  <xsl:param name="lastmodiso"   select='""'/>

  <xsl:param name="newsfile"    select='""'/>
  <xsl:param name="newsfileurl" select='""'/>
  <xsl:param name="watchouturl" select='""'/>
  <xsl:param name="searchssi"   select='"/incl/search.html"'/>

  <xsl:param name="headtitlepostfix" select='""'/>
  <xsl:param name="texttitlepostfix" select='""'/>

  <xsl:param name="ignoremissinglink" select='"no"'/>

  <!--* load in the ahelp index file *-->
  <xsl:param name="ahelpindex"  select='""'/>
  <xsl:variable name="ahelpindexfile" select="document($ahelpindex)"/>

  <xsl:param name="depth" select="1"/>
  
  <xsl:param name="storageloc" select="''"/>
  <xsl:variable name="storageInfo" select="djb:read-if-set($storageloc)"/>

  <!--*
      * Returns the document if set - as a node set - otherwise
      * the empty string.
      *-->
  <func:function name="djb:read-if-set">
    <xsl:param name="filename" select="''"/>
    <xsl:choose>
      <xsl:when test="$filename != ''"><func:result select="document($filename)"/></xsl:when>
      <xsl:otherwise><func:result/></xsl:otherwise>
    </xsl:choose>
  </func:function>

  <!--* easily add a new line to a concat(...) statement *-->
  <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

  <xsl:variable name="quot">"</xsl:variable>

</xsl:stylesheet>
