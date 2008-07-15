<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * List of "global" templates for the web-page stylesheets
    *
    * Recent changes:
    *   2007 Oct 31 DJB Added storageloc parameters, not sure about storage
    *   2007 Oct 26 DJB Added proglang and storage parameters
    *
    *   v1.7 - added hardcopy parameter
    *   v1.6 - added cssprintfile parameter
    *   v1.5 - added headtitlepostfix and texttitlepostfix parameters
    *   v1.4 - comment change to indicate expeced value of ahelpindex
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
    *    whether to create the test or "real" version
    *
    *  . lastmod=string to use to say when page was last modified
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
    *  . pagename=name of page (ie without .xml or .html or any proglang additions)
    *
    *  . url=URL of page (on live server)
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
    *  . hardcopy - integer, optional, default=0
    *    if 0 then create the "softcopy" version, if 1 then the "hardcopy"
    *    version. Setting to 1 with site=icxc is not valid but we do not
    *    check for this
    *
    *    THIS PARAMETER IS BEING PHASED OUT AND IS CURRENTLY ONLY SUPPORTED
    *    FOR THREADS
    *
    *  . storage - string, optional, default=''
    *    gives the location of the "storage" files - ie the copies of the
    *    published XML documents for the site/version. This is currently
    *    needed so we can access the thread pages for the threadlink tags
    *    (proglang info). It should be sent to the top-level storage
    *    location for the site/version, not the location for this particular
    *    page - EXCEPT THAT I DO NOT KNOW HOW WE ARE GOING TO HANDLE LINKS
    *    BETWEEN SITES USING THIS SCHEME ...
    *
    *    For now we assume the threadlinking is done within the same site
    *
    *    IT IS VERY LIKELY THAT STORAGE WILL BE REMOVED RSN
    *
    *  . proglang - string, optional, default=''
    *    if set - to either "sl" or "py" - then 'specialize' the document
    *    for the given language.
    *
    *  . storageloc - string, optional, default=''
    *    points to an XML file that contains the "storage" directories
    *    for the different sites for this version and type (live,...).
    *    Currently used by threads to access stored thread information.
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:func="http://exslt.org/functions"
  xmlns:djb="http://hea-www.harvard.edu/~dburke/xsl/"
  extension-element-prefixes="func djb">

  <!--* these should be over-ridden from the command line *-->

  <xsl:param name="cssfile"      select='""'/>
  <xsl:param name="cssprintfile" select='""'/>
  <xsl:param name="site"         select='""'/>
  <xsl:param name="install"      select='""'/>
  <xsl:param name="pagename"     select='""'/>
  <xsl:param name="navbarlink"   select='""'/>
  <xsl:param name="url"          select='""'/>
  <xsl:param name="sourcedir"    select='""'/>
  <xsl:param name="updateby"     select='""'/>
  <xsl:param name="siteversion"  select='""'/>
  <xsl:param name="lastmod"      select='""'/>

  <xsl:param name="newsfile"    select='""'/>
  <xsl:param name="newsfileurl" select='""'/>
  <xsl:param name="watchouturl" select='""'/>
  <xsl:param name="searchssi"   select='"/incl/search.html"'/>

  <xsl:param name="headtitlepostfix" select='""'/>
  <xsl:param name="texttitlepostfix" select='""'/>

  <!--* ONLY USED BY THREADS; WILL BE REMOVED SOON *-->
  <xsl:param name="hardcopy"     select="0"/>

  <!--* load in the ahelp index file *-->
  <xsl:param name="ahelpindex"  select='""'/>
  <xsl:variable name="ahelpindexfile" select="document($ahelpindex)"/>

  <xsl:param name="depth" select="1"/>
  
  <!--*
      * If set (not empty) to sl or py then the output document should
      * be for the given language (S-lang or Python)
      *-->
  <xsl:param name="proglang" select="''"/>

  <!--* not sure about this; see header *-->
  <xsl:param name="storage" select="''"/>

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

</xsl:stylesheet>
