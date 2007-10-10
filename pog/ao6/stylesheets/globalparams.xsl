<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!-- List of "global" templates for the web-page stylesheets -->
<!-- $Id: globalparams.xsl,v 1.3 2003/08/05 21:07:05 dburke Exp $ -->

<!--*
    * Recent changes:
    *   v1.3 - added watchouturl parameter
    *   v1.2 - added searchssi parameter
    *   v1.1 - Initial version
    *
    * Note:
    *  Not all pages need all these parameters but it's easier to have
    *  them all in one place
    *
    * User-defineable parameters:
    *  . type="test"|"live"
    *    wether to create the test or "real" version
    *
    *  . lastmod=string to use to say when page was last modified
    *
    *  . site=one of: ciao chart icxc
    *    tells the stylesheet what site we are working with
    *
    *  . ahelpindex=full path to ahelp index file created by ahelp2html.pl
    *    something like /data/da/Docs/ciaoweb/published/ciao3/live/ahelp/seealso-index.xml
    *    Used to work out the ahelp links
    *
    *  . cssfile=partial url to identify CSS sheet for the page
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
    *  . pagename=name of page (ie wothout .xml or .html)
    *
    *  . url=URL of page (on live server)
    *
    *  . sourcedir=full path to directory containing navbar.xml
    *
    *  . depth=depth of the file: needed for images and some links
    *
    *  . updateby=name of person doing the update
    *
    *  . siteversion=version number of the site
    *    ony used by CIAO pages for now
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--* these should be over-ridden from the command line *-->
  <xsl:param name="cssfile"     select='""'/>
  <xsl:param name="site"        select='""'/>
  <xsl:param name="install"     select='""'/>
  <xsl:param name="pagename"    select='""'/>
  <xsl:param name="navbarlink"  select='""'/>
  <xsl:param name="url"         select='""'/>
  <xsl:param name="sourcedir"   select='""'/>
  <xsl:param name="updateby"    select='""'/>
  <xsl:param name="siteversion" select='""'/>
  <xsl:param name="lastmod"     select='""'/>

  <xsl:param name="newsfile"    select='""'/>
  <xsl:param name="newsfileurl" select='""'/>
  <xsl:param name="watchouturl" select='""'/>
  <xsl:param name="searchssi"   select='"/incl/search.html"'/>

  <!--* load in the ahelp index file *-->
  <xsl:param name="ahelpindex"  select='""'/>
  <xsl:variable name="ahelpindexfile" select="document($ahelpindex)"/>

  <!--* really need to sort out the navbar (does this work for the navbar?) *-->
  <xsl:param name="depth" select="1"/>
  
</xsl:stylesheet>
