<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Recent changes:
    * 2008 May 30 DJB Removed generation of PDF links in header/footer
    *   except for threads
    * 2008 Apr 18 ECG: added dictionary_onepage as an allowed-pdf
    * 2008 Mar 13 ECG
    *  added cscdb as an allowed-pdf
    * [2008 Feb 14] ECG
    *  added csc as an allowed-site
    *  21 Feb 2008 ECG - updated copyright statement to extend to 2008
    * 2007 Oct 29 DJB
    *    added is-proglang-valid
    * 2007 Oct 22 DJB
    *    belatedly changed copyright date from "-2006" to "-2007"
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *    Need to check users of add-attribute, add-image
    *
    * "helper" templates
    *
    * Requires:
    *  sourcedir - "global" parameter used by add-disclaimer
    *    gives location of sourcedir (eg /data/da/Docs/chartweb/navbar)
    *
    *  updateby  - "global" parameter used by add-test-banner
    *    gives name of last person to publish the page
    *    (the output of whoami is sufficient)
    *
    * TO DO:
    *  - rationalise the use of the url parameter: we have it set by
    *    the processor (but this is only likely to be valid for
    *    non threads).
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:date="http://exslt.org/dates-and-times"
  xmlns:func="http://exslt.org/functions"
  xmlns:djb="http://hea-www.harvard.edu/~dburke/xsl/"
  extension-element-prefixes="date func djb">

  <!--*
      * used to determine whether the site is valid
      *
      * used to determine whether or not to add PDF links to header/footer
      * - see add-header/add-footer. Will be removed once we convert
      *   threads to the new figure environment.
      *
      * used to determine whether a download type is recognised
      * (to catch user error rather than any real need to restrict the types)
      * This should perhaps be determined by an external file (eg a list in the
      * config file that publish.pl can check rather than this code)
      *
      * the spaces around each root name are important for the simple checking we do
      * - should these be node sets rather than strings?
      *-->
  <xsl:variable name="allowed-pdf" select="' thread '"/>
  <xsl:variable name="allowed-sites" select="' ciao sherpa chips chart caldb pog icxc csc '"/>
  <xsl:variable name="allowed-download-types" select="' solaris fc4 fc8 osx_ppc osx_intel caldb atomdb '"/>

  <!--* note that '' is also allowed for proglang but this is checked for separately *-->
  <xsl:variable name="allowed-proglang" select="' py sl '"/>

  <!--*
      * handle unknown tags
      *  - perhaps we should exit with an error when we find an unknown tag?
      *  - currently the metalist template requires that we copy over unknown data
      *    any others?
      *
      * - this causes problems: have removed and handling meta tags
      *   [by copying over the attributes]
      *
      *-->
  <xsl:template match="@*|node()">
    <xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
  </xsl:template>

  <!--*
      * explicitly ignore comments
      * - this means that we need explicit markup for SSI's

  <xsl:template match="comment()">
   <xsl:comment><xsl:value-of select="."/></xsl:comment>
  </xsl:template>

      *-->
  <xsl:template match="comment()"/>

  <!--* 
      * add an attribute to the current node
      *
      * params are:
      *  name   - name of attribute
      *  value  - value of attribute
      *  idepth - depth to use (defaults to $depth if not given)
      *-->
  <xsl:template name="add-attribute">
    <xsl:param name="name"/>
    <xsl:param name="value"/>
    <xsl:param name="idepth" select="$depth"/>

    <xsl:attribute name="{$name}"><xsl:call-template name="add-path">
      <xsl:with-param name="idepth" select="$idepth"/>
    </xsl:call-template><xsl:value-of select="$value"/></xsl:attribute>

  </xsl:template> <!--* name=add-attribute *-->

  <!--* 
      * recursive system to add on the correct number of '../' to the path
      * parameter:
      *  idepth: "depth" of path (1 means at the top level)
      *          should be an integer >=1
      *-->
  <xsl:template name="add-path">
    <xsl:param name="idepth" select="1"/>
    <xsl:param name="path"   select="''"/>

    <xsl:choose>
      <xsl:when test="$idepth='' or $idepth&lt;1">
	<!--* safety check *-->
	<xsl:message terminate="yes">
 ERROR: add-path called with idepth &lt; 1 or undefined
	</xsl:message>
      </xsl:when>
      <xsl:when test="$idepth=1">
	<!--* stop recursion *-->
	<xsl:value-of select="$path"/>
      </xsl:when>
      <xsl:otherwise>
	<!--* recurse *-->
	<xsl:call-template name="add-path">
	  <xsl:with-param name="idepth" select="$idepth - 1"/>
	  <xsl:with-param name="path"   select="concat($path,'../')"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=add-path *-->

  <!--* UGLY way to add an image
      *
      * params are:
      *  src    - name of image (assumed to be at a depth of 1)
      *  alt    - value for alt tag (will be surrounded by [])
      *
      * Optional tags:
      *  height - height value
      *  width  - width value
      *  border - border value
      *  align  - align value
      *
      * perhaps depth should be renamed idepth
      *-->
  <xsl:template name="add-image">
    <xsl:param name="src"/>
    <xsl:param name="alt"/>

    <xsl:param name="height"/>
    <xsl:param name="width"/>
    <xsl:param name="border"/>
    <xsl:param name="align"/>

    <img>
      <!--* required attributes *-->
      <xsl:call-template name="add-attribute">
	<xsl:with-param name="name"  select="'src'"/>
	<xsl:with-param name="value" select="$src"/>
      </xsl:call-template>
      <xsl:attribute name="alt">[<xsl:value-of select="$alt"/>]</xsl:attribute>

      <!--* optional attributes (can we loop over params??) *-->
      <xsl:if test="$height!=''">
	<xsl:attribute name="height"><xsl:value-of select="$height"/></xsl:attribute>
      </xsl:if>
      <xsl:if test="$width!=''">
	<xsl:attribute name="width"><xsl:value-of select="$width"/></xsl:attribute>
      </xsl:if>
      <xsl:if test="$border!=''">
	<xsl:attribute name="border"><xsl:value-of select="$border"/></xsl:attribute>
      </xsl:if>
      <xsl:if test="$align!=''">
	<xsl:attribute name="align"><xsl:value-of select="$align"/></xsl:attribute>
      </xsl:if>
    </img>
  </xsl:template> <!--* add-image *-->

  <!--* add the 'new image' image *-->
  <xsl:template name="add-new-image">
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="'imgs/new.gif'"/>
      <xsl:with-param name="alt"    select="'New'"/>
    </xsl:call-template>
  </xsl:template> <!--* name=add-new-image *-->

  <!--* add the 'updated image' image *-->
  <xsl:template name="add-updated-image">
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="'imgs/updated.gif'"/>
      <xsl:with-param name="alt"    select="'Updated'"/>
    </xsl:call-template>
  </xsl:template> <!--* name=add-updated-image *-->

  <!--* 
      * add "do not edit this file" comment
      * - uses contents of variable $sourcedir to indicate the 
      *   directory containing the source file
      *-->
  <xsl:template name="add-disclaimer">
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:comment> THIS FILE IS CREATED AUTOMATICALLY - DO NOT EDIT MANUALLY </xsl:comment>
    <xsl:call-template name="newline"/>
    <xsl:comment> SEE: <xsl:value-of select="$sourcedir"/><xsl:value-of select="$pagename"/>.xml </xsl:comment>
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
  </xsl:template> <!--* name= add-disclaimer *-->

  <!--*
      * banner for hardcopy versions of the page
      *
      * Parameters: url
      * Variables:  lastmod
      *
      *-->
  <xsl:template name="add-hardcopy-banner-top">
    <xsl:param name="url" select="''"/>

    <xsl:if test="$url = ''">
      <xsl:message terminate="yes">
  Error: add-hardcopy-banner-top called with no url
      </xsl:message>
    </xsl:if>

    <table border="0" width="100%">
      <tr>
	<td align="left" valign="top">
	  <!--* using just [/sds]/incl/header_left.gif seemed to cause htmldoc pain so add full URL *-->
	  <img alt="[Chandra Science]" src="http://cxc.harvard.edu/incl/header_left.gif"/>
	</td>
	<td align="right" valign="center">
	  <font size="-1">
	    URL: <a href="{$url}"><xsl:value-of select="$url"/></a>
	    <br/>
	    Last modified: <xsl:value-of select="$lastmod"/>
	  </font>
	</td>
      </tr>
    </table>
    <xsl:call-template name="add-hr-strong"/>
    <br/>
    
  </xsl:template> <!--* name=add-hardcopy-banner-top *-->


  <!--*
      * banner for hardcopy versions of the page
      *
      * Parameters: url
      * Variables:  lastmod
      *
      *-->
  <xsl:template name="add-hardcopy-banner-bottom">
    <xsl:param name="url" select="''"/>

    <xsl:if test="$url = ''">
      <xsl:message terminate="yes">
  Error: add-hardcopy-banner-bottom called with no url
      </xsl:message>
    </xsl:if>

    <br/>
    <xsl:call-template name="add-hr-strong"/>
    <br/>
    <table border="0" width="100%">
      <tr>
	<td align="left" valign="top">
	  <font size="-1">
	    The Chandra X-Ray Center (CXC) is operated for NASA by the Smithsonian Astrophysical Observatory.
	    <br/>
	    60 Garden Street, Cambridge, MA 02138 USA.
	    <br/>
	    Smithsonian Institution, Copyright 
	    <xsl:text disable-output-escaping="yes">&amp;copy;</xsl:text>
	    1998-2008. All rights reserved. 
	  </font>
	</td>
	<td align="right" valign="center">
	  <font size="-1">
	    URL: <a href="{$url}"><xsl:value-of select="$url"/></a>
	    <br/>
	    Last modified: <xsl:value-of select="$lastmod"/>
	  </font>
	</td>
      </tr>
    </table>

  </xsl:template> <!--* name=add-hardcopy-banner-bottom *-->


  <!--* 
      * Create the "standard" HTML header
      * see add-htmlhead for extra customisation
      *
      * The title is set to
      *    info/title/short (if available)
      *    info/title/long  (otherwise)
      * If the $headtitlepostfix global parameter is set (ie not '') then
      * this is appended to the title, with a space in between
      *
      * IF run from a thread then we look in $threadInfo instead of info
      *
      * Note that for threads I have moved to using add-htmlhead-site
      * - in thread_common.xsl - which does not (currently) use the
      * headtitlepostfix parameter
      *-->
  <xsl:template name="add-htmlhead-standard">

    <!--*
        * rather a mess - wanted to set a variable to info/title or
        * $threadInfo/title and then use that but it didn't want to work
        * 
        *-->
    <xsl:variable name="titlestring"><xsl:choose>
	<xsl:when test="name(//*) = 'thread'"><xsl:choose>
	    <xsl:when test="boolean($threadInfo/title/short)"><xsl:value-of select='$threadInfo/title/short'/></xsl:when>
	    <xsl:otherwise><xsl:value-of select='$threadInfo/title/long'/></xsl:otherwise>
	  </xsl:choose></xsl:when>
	<xsl:otherwise><xsl:choose>
	    <xsl:when test="boolean(info/title/short)"><xsl:value-of select='info/title/short'/></xsl:when>
	    <xsl:otherwise><xsl:value-of select='info/title/long'/></xsl:otherwise>
	  </xsl:choose></xsl:otherwise>
      </xsl:choose></xsl:variable>

    <xsl:call-template name="add-htmlhead">
      <xsl:with-param name="title"><xsl:value-of select="$titlestring"/><xsl:if test="$headtitlepostfix!=''"><xsl:value-of select="concat(' - ',$headtitlepostfix)"/></xsl:if></xsl:with-param>
    </xsl:call-template>
  </xsl:template> <!--* name=add-htmlhead-standard *-->

  <!--* 
      * Given a title string, create the HTML head block
      * see also add-htmlhead-standard
      *
      * we include the contents of the info/metalist block.
      * this is a simple (too simple?) way of including extra meta info
      * into the html/head block.
      * and ditto for the htmlscripts/htmlscript
      * (added html prefix to separate from scripts used in threads)
      *
      * input variables:
      *   title - required
      *   css   - optional: text of css-1 rules
      *-->
  <xsl:template name="add-htmlhead">
    <xsl:param name='title'/>
    <xsl:param name='css'/>
    <head>
      <title><xsl:value-of select="$title"/></title>

      <!--* any meta information to add ? *-->
      <xsl:apply-templates select="info/metalist"/>

      <!--* any scripts ? *-->
      <xsl:apply-templates select="info/htmlscripts"/>

      <!--// all CSC pages get cscview.js //-->
      <xsl:if test="$site = 'csc'">
	<script type="text/javascript" language="JavaScript" src="/csc/cscview.js"/>
      </xsl:if>
      
      <!--* add main stylesheets *-->
      <link rel="stylesheet" title="Default stylesheet for CIAO-related pages" href="{$cssfile}"/>
      <link rel="stylesheet" title="Default stylesheet for CIAO-related pages" media="print" href="{$cssprintfile}"/>

      <!--*
          * This is an okay idea - although it requires some discipline when
          * creating the navbar and the navbarlink parameter added to 
          * stylesheets for other pages. The issue is what happens with a
          * page that has a navbar but is not on the navbar but can be
          * considered to be part of a section (so that section should be
          * highlighted) - eg bugs
          *
          *
         {!* add a rule to highlight the selected link in the navbar *}
      <xsl:if test="$navbarlink != ''">
<style type="text/css">
/* highlight the link to this page only in the navbar */
.navbar a[href='<xsl:value-of select="$navbarlink"/>'] {
  background: #cccccc;
}
</style>
      </xsl:if>
         *
         *
         *-->

      <!--* do we have any CSS rules ? *-->
      <xsl:if test="$css!=''">
<style type="text/css">
<xsl:value-of select="$css"/>
</style>
      </xsl:if>
    </head>
  </xsl:template> <!--* add-htmlhead *-->

  <!--* metalist/meta are a hacky way of setting meta comments in
      * the head block of a HTML page.
      *-->
  <xsl:template match="metalist"><xsl:apply-templates select="meta"/></xsl:template>
  <xsl:template match="meta"><xsl:copy-of select="."/></xsl:template>

  <!--*
      * htmlscript(s) are a hacky way of setting the script tags in the header
      * block of a HTML page.
      * instead of being clever we assume there's always a language attribute
      * ansd there's either a src attribute or the tag has content
      * >>>AND<<< that content is in the form of a XML comment
      *-->
  <xsl:template match="htmlscripts"><xsl:apply-templates select="htmlscript"/></xsl:template>
  <xsl:template match="htmlscript">
    <!--* the following check will soon be enforced by the schema so can be removed *-->
    <xsl:if test="not(@type)">
      <xsl:message terminate="yes">
 Error: htmlscript tag is missing a type attribute
      </xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="boolean(@src)">
	<script language="{@language}" type="{@type}" src="{@src}"/>
      </xsl:when>
      <xsl:otherwise>
	<script language="{@language}" type="{@type}">
	  <xsl:if test="boolean(comment()) = false()">
	    <!--* safety check *-->
	    <xsl:message terminate="yes">
 Error: htmlscript has no src attribute and doesn't contain a XML comment!
	    </xsl:message>
	  </xsl:if>
	  <xsl:comment><xsl:value-of select="comment()"/></xsl:comment>
	</script>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* match=htmlscript *-->

  <!--*
      * Add the links to the PDF versions of the web page: factored out as
      * used in two places, the leading "internal-" in the template name
      * indicates that it's only meant to be used deep within other templates
      *
      * Can be removed once we clean up the threads.
      *-->
  <xsl:template name="internal-add-hardcopy-links">
<!--
    <xsl:message terminate="yes">
 ERROR: internal-add-hardcopy-links has been called
    </xsl:message>
-->
    <xsl:param name="name"  select="''"/>

    <xsl:if test="$name = ''">
      <xsl:message terminate="yes">
  Internal error: internal-add-hardcopy-links called with no name parameter
      </xsl:message>
    </xsl:if>

    Hardcopy (PDF):
    <a title="PDF (A4 format) version of the page" href="{$name}.a4.pdf">A4</a> |
    <a title="PDF (US Letter format) version of the page" href="{$name}.letter.pdf">Letter</a>

  </xsl:template> <!--* name=internal-add-hardcopy-links *-->

  <!--*
      * add the header
      *
      * Parameters:
      *   name - string, required
      *
      * Also depends on the package-wide params/variables:
      *    $site, $type, $updateby, $url [kind of]
      *
      * In CIAO 3.0 changed to remove the use of tables. Use CSS instead.
      *
      * For now we only add a "URL:" bar if the global $url
      * variable is not ''. We need to sort this out so that we
      * can have one for all pages.
      *
      *-->
  <xsl:template name="add-header">
    <xsl:param name="name"  select="''"/>

    <!--* TODO: invert the logic of this check once we remove the PDF support in threads *-->
    <xsl:if test="$name = ''">
      <xsl:message terminate="yes">
  Internal Error: add-header called with no name attribute
      </xsl:message>
    </xsl:if>

    <xsl:variable name="root" select="name(//*)"/>

    <!--* site=icxc publishing really should have type=live? *-->
    <xsl:if test='($type="test" and $site!="icxc") or $type="trial"'>
      <!--* add the body tag (start) and test header info *-->
      <xsl:call-template name="add-start-body-white"/>
      <xsl:call-template name="add-test-banner"/>
    </xsl:if>

    <xsl:choose>
      <xsl:when test='$type="trial"'>
        <xsl:call-template name="add-header-trial"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="add-ssi-include">
          <xsl:with-param name="file" select="'/incl/header.html'"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

    <!--* we break up into lots of different sections to try and make lynx happier *-->

    <!--*
        * this is only going to be picked up by user agents that do not process
        * stylesheets - as long as the stylesheet has a rule
        *    .hidmem { display: none; }
        * so it's a good way of getting to lynx users
        *-->
    <div class="hideme">
      <a href="#maintext" accesskey="s"
	title="Skip past the navigation links to the main part of the page">Skip the navigation links</a>
    </div>

    <!--* we do not have a search bar on the pages for site=icxc *-->
    <xsl:if test="$site != 'icxc'">
      <div class="topbar">
	<xsl:call-template name="add-search-ssi"/>
      </div>
    </xsl:if>

    <div class="topbar">
      <div class="lastmodbar">Last modified: <xsl:value-of select="$lastmod"/></div>
      <xsl:if test="$url != ''">
	<!--* this is a safety check for now *-->
	<br class="hideme"/>
	<div class="urlbar">URL: <xsl:value-of select="$url"/></div>
      </xsl:if>
    </div>

    <!--* add links to PDF files - WHICH WE ARE REMOVING *-->
    <xsl:if test="$site != 'icxc' and contains($allowed-pdf,concat(' ',$root,' '))">
      <div class="topbar">
	<div class="pdfbar">
	  <xsl:call-template name="internal-add-hardcopy-links">
	    <xsl:with-param name="name" select="$name"/>
	  </xsl:call-template>
	</div>
      </div>
    </xsl:if>

  </xsl:template> <!--* name=add-header *-->

  <!--*
      * add the necessary SSI to get the search bar
      * - as of CIAO 3.0 we now use the searchssi parameter
      *   trather than hard-code the location
      *-->
  <xsl:template name="add-search-ssi">

    <xsl:call-template name="add-ssi-include">
      <xsl:with-param name="file" select="$searchssi"/>
    </xsl:call-template>

  </xsl:template> <!--* add-search-ssi *-->

  <!--*
      * trial header:
      *  create here rather than use include files
      *
      *  added 'fake' search button to make it look 'more' real
      *  use EXSLT date function to get the 'last published' time
      *
      * only used for trial version: the test version can use the
      * incl/header|search.html file on that site
      *
      *-->
  <xsl:template name="add-header-trial">

    <table border="0" cellpadding="0" cellspacing="0" width="100%">
      <tr>
        <td align="left" valign="top">
	  <map name="header_left">
	    <area alt="Chandra Science" coords="0,4,192,72" href="http://cxc.harvard.edu/" shape="RECT"/>
	  </map>
	  <img src="/sds/imgs/header_left.gif" border="0" alt="Chandra Science" usemap="#header_left"/>
	</td>

	<td align="right" valign="top">
	  <map name="header_right">
	    <area alt="About Chandra" coords="0,14,107,31" href="http://cxc.harvard.edu/udocs/overview.html" shape="RECT"/>
	    <area alt="Archive" coords="118,13,185,32" href="http://cxc.harvard.edu/cda/" shape="RECT"/>
	    <area alt="Proposer" coords="197,12,268,31" href="http://cxc.harvard.edu/prop.html" shape="RECT"/>
	    <area alt="Instruments &amp; Calibration" coords="283,14,453,32" href="http://cxc.harvard.edu/cal/" shape="RECT"/>
	    <area alt="Newsletters" coords="112,33,198,51" href="http://cxc.harvard.edu/newsletters.html" shape="RECT"/>
	    <area alt="Data Analysis" coords="1,35,97,50" href="http://cxc.harvard.edu/ciao/" shape="RECT"/>
	    <area alt="HelpDesk" coords="218,34,295,51" href="http://cxc.harvard.edu/helpdesk/" shape="RECT"/>
	    <area alt="Calibration Database" coords="309,34,450,52" href="http://cxc.harvard.edu/caldb/" shape="RECT"/>
	    <area alt="NASA Archives &amp; Centers" coords="295,53,452,75" href="http://cxc.harvard.edu/nasa_links.html" shape="RECT"/>
	  </map>
	  <img src="/sds/imgs/header_right.gif" border="0" alt="Chandra Science" usemap="#header_right"/>
	</td>
      </tr>
    </table>
    <br clear="all"/>
    <xsl:call-template name="newline"/>
    <br/>
  </xsl:template> <!--* add-header-trial *-->

  <!--*
      * add the footer
      *
      * Parameters:
      *   name - string, required
      *     passed through to add-standard-banner
      *
      * Also depends on the package-wide params/variables:
      *    $site, $type
      *
      *-->
  <xsl:template name="add-footer">
    <xsl:param name="name"  select="''"/>

    <!--* TODO: invert the logic of this check once we remove the PDF support in threads *-->
    <xsl:if test="$name = ''">
      <xsl:message terminate="yes">
  Internal Error: add-footer called with no name attribute
      </xsl:message>
    </xsl:if>

    <!--* add the "standard" banner *-->
    <xsl:variable name="root" select="name(//*)"/>

    <!--* add links to PDF files - WHICH WE ARE NOW REMOVING *-->
    <div class="bottombar">
      <xsl:if test="$site != 'icxc' and contains($allowed-pdf,concat(' ',$root,' '))">
	<div>
	  <xsl:call-template name="internal-add-hardcopy-links">
	    <xsl:with-param name="name" select="$name"/>
	  </xsl:call-template>
	</div>
      </xsl:if>
      <div>Last modified: <xsl:value-of select="$lastmod"/></div>
    </div>

    <xsl:choose>

      <xsl:when test='$type="live" or $type="test"'>
	<xsl:call-template name="add-ssi-include">
	  <xsl:with-param name="file" select="'/incl/footer.html'"/>
	</xsl:call-template>
      </xsl:when>

      <xsl:when test='$type="trial"'>
	<xsl:call-template name="add-footer-trial"/>
      </xsl:when>
	
    </xsl:choose>
  </xsl:template> <!--* name=add-footer *-->

  <!--* manually include the live footer: wil need updating if live footer changes *-->
  <xsl:template name="add-footer-trial">

    <br clear="all"/>
    <div align="center">
      <font face="Arial,Helvetica,sans-serif">
	<a href="http://cxc.harvard.edu/">Chandra Science</a>
	<xsl:call-template name="add-nbsp"/>|<xsl:call-template name="add-nbsp"/>
	<a href="http://chandra.harvard.edu/">Chandra Home</a>
	<xsl:call-template name="add-nbsp"/>|<xsl:call-template name="add-nbsp"/>
	<a href="http://cxc.harvard.edu/udocs/www.html">Astronomy links</a>
	<xsl:call-template name="add-nbsp"/>|<xsl:call-template name="add-nbsp"/>
	<a href="http://icxc.harvard.edu/">iCXC (CXC only)</a>
	<xsl:call-template name="add-nbsp"/>|<xsl:call-template name="add-nbsp"/>
	<a href="http://cxc.harvard.edu/AT-CXCquery.html">Search</a>
      </font></div>
    <br clear="all"/><br/>
    <table align="left" cellpadding="3" cellspacing="3">
      <tr>
	<td align="left" valign="middle"><img src="/sds/imgs/cxc-logo_sm45.jpg" border="0" alt="CXC Logo"/></td>
	<td align="left" valign="top">
	  <font face="Arial,Helvetica,sans-serif" size="-1">
	    <em>The Chandra X-Ray
	      Center (CXC) is operated for NASA by the Smithsonian Astrophysical Observatory.</em>
	    <br/>
	    60 Garden Street, Cambridge, MA 02138 USA.
	    <xsl:call-template name="add-nbsp"/><xsl:call-template name="add-nbsp"/><xsl:call-template name="add-nbsp"/>
	    Email: <a href="mailto:cxcweb@head-cfa.harvard.edu">cxcweb@head-cfa.harvard.edu</a>
	    <br/>
	    Smithsonian Institution, Copyright 
	    <xsl:text disable-output-escaping="yes">&amp;copy; </xsl:text>
	    1998-2008. All rights reserved.
	  </font>
	</td>
      </tr>
    </table>
    
  </xsl:template> <!--* name=add-footer-trial *-->

  <!--*
      * add the navbar: depends on the parameter $type
      * input variables:
      *  type (required) - one of "live" or "test"
      *  name (required) - include navbar_<name>.html
      *
      * NOTE: 
      *   as of CIAO 3.0 have removed the spacer column
      *-->
  <xsl:template name="add-navbar">
    <xsl:param name='name'/>

    <td class="navbar" valign="top">
      <xsl:call-template name="add-ssi-include">
	<xsl:with-param name="file" select="concat('navbar_',$name,'.incl')"/>
      </xsl:call-template>
    </td>
    <xsl:call-template name="newline"/>

  </xsl:template> <!--* name= add-navbar *-->

  <!--***
      *** check parameters are okay
      ***-->
  <xsl:template name="is-site-valid">
    <xsl:if test="contains($allowed-sites,concat(' ',$site,' '))=false()">
      <xsl:message terminate="yes">
  Error:
    site parameter [<xsl:value-of select="$site"/>] is unknown
    allowed values: <xsl:value-of select="$allowed-sites"/>
      </xsl:message>
    </xsl:if>
  </xsl:template> <!--* name=is-site-valid *-->

  <xsl:template name="is-proglang-valid">
    <xsl:choose>
      <xsl:when test="$proglang=''"/>
      <xsl:when test="contains($allowed-sites,concat(' ',$site,' '))=true()"/>
      <xsl:otherwise>
	<xsl:message terminate="yes">
  Error:
    proglang parameter [<xsl:value-of select="$proglang"/>] is unknown
    allowed values: '' or <xsl:value-of select="$allowed-proglang"/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=is-proglang-valid *-->

  <!--***
      *** check parameters are okay
      ***-->
  <xsl:template name="is-download-type-valid">
    <xsl:param name="type" select="'XX'"/>

    <xsl:if test="contains($allowed-download-types,concat(' ',$type,' '))=false()">
      <xsl:message terminate="yes">
  Error:
    download type parameter [<xsl:value-of select="$type"/>] is unknown
    allowed values: <xsl:value-of select="$allowed-download-types"/>
      </xsl:message>
    </xsl:if>
  </xsl:template> <!--* name=is-download-type-valid *-->

  <!--*
      * dummy is used as the root element of included files
      *-->
  <xsl:template match="dummy">
    <xsl:apply-templates/>
  </xsl:template>

  <!--* make this bar stand out *-->
  <xsl:template name="add-hr-strong">
    <!--* <hr size="3"/> *-->
    <hr size="5" noshade="0"/>
  </xsl:template>

  <!--*
      * add a line containing URL (on left) and
      * last modified date (on right)
      *
      * Parameters:
      *   urlfrag, string, required
      *     URL for page = http://cxc.harvard.edu/$site/$urlfrag
      *   lastmod, string, required
      *     last modified date
      *
      * Now that we have the $url 'global' parameter, do we
      * need urlfrag? I guess we do but need to look over the
      * templates to understand what is going on
      *
      * AHA: it appears that the url 'global' parameter in threads 
      *  is empty (presumably because there's a one-2-many mapping
      *  in the thread code, ie it makes multiple pages)
      *-->
  <xsl:template name="add-id-hardcopy">
    <xsl:param name="urlfrag" select="''"/>
    <xsl:param name="lastmod" select="''"/>

    <xsl:variable name="urlval" select="concat('http://cxc.harvard.edu/',$site,'/',$urlfrag)"/>

    <table border="0" width="100%">
      <tr>
        <td align="left">
          URL: <a href="{$urlval}"><xsl:value-of select="$urlval"/></a>
        </td>
        <td align="right">
          Last modified: <xsl:value-of select="$lastmod"/>
        </td>
      </tr>
    </table>

  </xsl:template> <!--* name=add-id-hardcopy *-->

  <!--*
      * add a ssi include statement to the output, surrounded by new lines
      * (because we are having issues with the register CGI stuff
      *  and I'm hoping that the carriage returns will improve
      *  things)
      *
      * Parameters:
      *  file - string, required
      *    the file to include
      *
      *-->
  <xsl:template name="add-ssi-include">
    <xsl:param name='file'/>
    <xsl:if test="$file = ''">
      <xsl:message terminate="yes">

Programming error: add-ssi-include called with an empty file parameter

      </xsl:message>
    </xsl:if>

    <xsl:call-template name="newline"/>
    <xsl:comment>#include virtual="<xsl:value-of select="$file"/>"</xsl:comment>
    <xsl:call-template name="newline"/>

  </xsl:template> <!--* name=add-ssi *-->

  <!--* used by the test/trial headers *-->
  <xsl:template name="add-start-body-white">
    <xsl:call-template name="start-tag"/>body bgcolor=<xsl:call-template name="add-quote"/>#FFFFFF<xsl:call-template name="add-quote"/><xsl:call-template name="end-tag"/>
  </xsl:template>

  <!--*
      * add the "banner" for test pages (at the very top)
      * Lists the current time (found using EXSLT routines)
      * and the person who did the last update.
      *
      * The header for the test site has (as of Dec 03) changed
      * to make it abundantly clear that it is a test site.
      * so we have changed the header to just give the last-updated
      * date and editor. Might be better in a different position
      * on the page but that would require changing too much
      *
      * Requires:
      *   "global" parameter $updateby (set by stylesheet processor)
      *
      *-->
  <xsl:template name="add-test-banner">

    <xsl:comment> This header is for pages on the test site only </xsl:comment>

    <!--* set up the time/date using EXSLT *OR* hardcode if testing stylesheets *-->
    <xsl:variable name="dt"   select="date:date-time()"/>
    <xsl:variable name="date"><xsl:choose>
	<xsl:when test="$updateby = 'a_tester'">tomorrow</xsl:when>
	<xsl:otherwise><xsl:value-of select="substring(date:date($dt),1,10)"/></xsl:otherwise>
      </xsl:choose></xsl:variable>
    <xsl:variable name="time"><xsl:choose>
	<xsl:when test="$updateby = 'a_tester'">The day before</xsl:when>
	<xsl:otherwise><xsl:value-of select="substring(date:time($dt),1,8)"/></xsl:otherwise>
      </xsl:choose></xsl:variable>

    <table width="100%" border="0">
      <tr>
	<td align="left">
	  <font color="red" size="-1">
	    Last published by: <xsl:value-of select="$updateby"/>
	  </font>
	</td>
	<td align="right">
	  <font color="red" size="-1">
	    at: <xsl:value-of select="$time"/><xsl:text> </xsl:text>
	    <xsl:value-of select="$date"/>
	  </font>
	</td>
      </tr>
    </table>
    <br clear="all"/>
    <xsl:call-template name="newline"/>
    
  </xsl:template> <!--* name=add-test-banner *-->

  <!--*
      * check that the parameter value ends in a / character
      *
      * Parameters:
      *   pname, string, required
      *     name of parameter
      *   pvalue, string, required
      *     value of parameter
      *
      *-->
  <xsl:template name="check-param-ends-in-a-slash">
    <xsl:param name="pname"  select="''"/>
    <xsl:param name="pvalue" select="''"/>

    <xsl:if test="substring($pvalue,string-length($pvalue))!='/'">
      <xsl:message terminate="yes">
  Error: <xsl:value-of select="$pname"/> parameter must end in a / character.
    <xsl:value-of select="$pname"/>=<xsl:value-of select="$pvalue"/>
      </xsl:message>
    </xsl:if>

  </xsl:template> <!--* name=check-param-ends-in-a-slash *-->

  <!--*
      * adds the "What's New" link to the title
      * - only for ciao & sherpa sites at the moment
      *
      * - the location of the file on disk is given by the
      *   stylesheet parameter
      *     newsfile
      *   and the actual link by the
      *     newsfileurl
      *   parameter
      *
      * - we also link to the "watch out" page which is controlled
      *   by the
      *     watchouturl
      *   (not bothering with the actual file since we know we can't show the
      *    last-modified date)
      *   Only include the link if the parameter is set
      *
      * Params:
      *
      * Should we allow control over title level (ie h2 or something else)
      *
      * DAMN DAMN DAMN
      *   #flastmod file="foo" - foo can NOT be an absolute path or
      *        contain ../ which means we can not use it to access
      *        the news page. Which is a pain
      *
      * WE ONLY CREATE ANY OUTPUT IF HARDCOPY != 1
      *-->
  <xsl:template match="whatsnew">
    <xsl:if test="$hardcopy != 1">
      <xsl:call-template name="add-whatsnew-link"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="add-whatsnew-link">

    <xsl:if test="$site != 'ciao' and $site != 'sherpa' and $site != 'chips'">
      <xsl:message terminate="yes">

  ERROR: at the moment the whatsnew tag/link is only available
    to site=ciao, chips, or sherpa, not site=<xsl:value-of select="$site"/>

      </xsl:message>
    </xsl:if>

    <!--* programming check *-->
    <xsl:if test="$newsfile='' or $newsfileurl=''">
      <xsl:message terminate="yes">
  Internal error: newsfile or newsfileurl parameters not set

      </xsl:message>
    </xsl:if>
    <xsl:if test="$newsfile='dummy' or $newsfileurl='dummy'">
      <xsl:message terminate="yes">
  Internal error: newsfile or newsfileurl parameters set to "dummy"

      </xsl:message>
    </xsl:if>

    <!--*
        * We do not use h2 here for the what's new link in order not
        * to use too much vertical whitespace
        *-->
    <div class="noprint" align="center">
      <font size="+1">
	<a title="What's new for CIAO &amp; users of CIAO" href="{$newsfileurl}">WHAT'S NEW</a>
	<xsl:if test="$watchouturl != ''">
	  <xsl:text> | </xsl:text>
	  <a title="Items to be aware of when using CIAO" href="{$watchouturl}">WATCH OUT</a>
	</xsl:if>
      </font>
      <br/>
    </div>

  </xsl:template> <!--* name=add-whatsnew-link *-->


  <!--*
      * adds the skymap table include to the CSC website
      * - only for csc site
      *
      * - the location of the file on disk is fixed
      *-->

  <xsl:template match="l3progress">
    <xsl:call-template name="add-progress-link"/>
  </xsl:template>

  <xsl:template name="add-progress-link">

    <xsl:if test="$site != 'csc'">
      <xsl:message terminate="yes">

      ERROR: at the moment the l3progress tag/link is only available
      to site=csc, not site=<xsl:value-of select="$site"/>

      </xsl:message>
    </xsl:if>

    <div class="l3progress">
        <xsl:call-template name="add-ssi-include">
          <xsl:with-param name="file" select="'/csc/skymap/l3progress.html'"/>
        </xsl:call-template>
      <br/>
    </div>

  </xsl:template> <!--* name=add-progress-link *-->



  <!--*
      * Convert the $proglang variable into printable text.
      * It is not expected to be called when $proglang is empty.
      *-->
  <func:function name="djb:get-proglang-string">
    <func:result><xsl:choose>
      <xsl:when test="$proglang = 'sl'">S-Lang</xsl:when>
      <xsl:when test="$proglang = 'py'">Python</xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
 Internal error - djb:get-proglang-string() does not recognise proglang='<xsl:value-of select="$proglang"/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose></func:result>
  </func:function>

</xsl:stylesheet>
