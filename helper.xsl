<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
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

  <xsl:include href="common.xsl"/>

  <!--*
      * used to determine whether the site is valid
      *
      * used to determine whether a download type is recognised
      * (to catch user error rather than any real need to restrict the types)
      * This should perhaps be determined by an external file (eg a list in the
      * config file that publish.pl can check rather than this code)
      *
      * the spaces around each root name are important for the simple checking we do
      * - should these be node sets rather than strings?
      *-->
  <xsl:variable name="allowed-sites" select="' ciao sherpa chips chart caldb pog icxc csc obsvis iris '"/>
  <xsl:variable name="allowed-download-types" select="' solaris solaris10 fc4 fc8 osx_ppc osx_intel caldb atomdb '"/>

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
      *
      * input variables:
      *   title - required
      *   css   - optional: text of css-1 rules
      *   page  - optional: if given then the canonical link is created as
      *              canonicalbase + page
      *           else
      *              canonicalbase + pagename (stylesheet variable) + '.html'
      *           If canonicalbase is empty then no canonical link is given
      *           (For developing also use url as a fallback)
      *-->
  <xsl:template name="add-htmlhead-standard">
    <xsl:param name='page'/>

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
      <xsl:with-param name="page" select="$page"/>
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
      * Support for the "standard" set of metadata pages for SAO
      * pages is included.
      *
      * MathJax support is added if the page contains any math tags
      * (if $use-mathjax is set to 1); in this case it is an error
      * to have mathjaxpath unset.
      *
      * CSS can be added either via the css attribute or from the
      * info/css block in the input file.
      *
      * input variables:
      *   title - required
      *   css   - optional: text of css-1 rules
      *   page  - optional: if given then the canonical link is created as
      *              canonicalbase + page
      *           else
      *              canonicalbase + pagename (stylesheet variable) + '.html'
      *           If canonicalbase is empty then no canonical link is given
      *           (For developing also use url as a fallback)
      *-->
  <xsl:template name="add-htmlhead">
    <xsl:param name='title'/>
    <xsl:param name='css'/>
    <xsl:param name='page'/>
    <head>

      <title><xsl:value-of select="$title"/></title>

      <!--* any meta information to add ? *-->
      <xsl:apply-templates select="info/metalist"/>

      <!--* any scripts ? *-->
      <xsl:apply-templates select="info/htmlscripts"/>

      <xsl:if test="$use-mathjax = 1 and count(//math) != 0">
	<xsl:if test="$mathjaxpath = ''">
	  <xsl:message terminate="yes">
 ERROR: use-mathjax=1 but mathjaxpath is unset and the page contains math tags!
          </xsl:message>
	</xsl:if>

	<!--*
	    * We do not use the CDN version because of HEAD/SAO policy
	    *
	    * Given that we do not support Ascii Math (AMS) or MathML (MML)
	    * input, and do not need the texjax input processor, is it
	    * worth using a "custom" config?
	    *-->
	<script type="text/javascript" src="{$mathjaxpath}"/>
      </xsl:if>

      <!--* add main stylesheets *-->
      <xsl:choose>
	<xsl:when test="$site='iris'">
	  <link rel="stylesheet" title="Stylesheet for Iris pages" href="{$cssfile}"/>
	  <link rel="stylesheet" title="Stylesheet for Iris pages" media="print" href="{$cssprintfile}"/>
	</xsl:when>
	 
	<xsl:when test="$site='csc'">
	  <link rel="stylesheet" title="Stylesheet for CSC pages" href="{$cssfile}"/>
	  <link rel="stylesheet" title="Stylesheet for CSC pages" media="print" href="{$cssprintfile}"/>
	</xsl:when>
	 
	<xsl:otherwise>
	  <link rel="stylesheet" title="Default stylesheet for CIAO-related pages" href="{$cssfile}"/>
	  <link rel="stylesheet" title="Default stylesheet for CIAO-related pages" media="print" href="{$cssprintfile}"/>
	</xsl:otherwise>
      </xsl:choose>

      <!--// add an RSS link for the news page //-->
      <xsl:if test="$site='ciao' and ($pagename='news' or ($pagename='index' and $depth=1))">
	<link rel="alternate" type="application/rss+xml" title="CIAO News RSS Feed" href="{$outurl}feed.xml" />
      </xsl:if>

      <!-- canonical link for search results
           (include in non-live sites for better testing)
	   The use of url as a fallback is for development only
	   Trailing /index.html is stripped off if present,
           replaced by /
	-->
      <xsl:variable name="canonicalurl"><xsl:choose>
	<xsl:when test="$canonicalbase = ''">
	  <xsl:message terminate="no">
 DEVELOPMENT WARNING: no canonicalbase parameter so falling back to url=<xsl:value-of select="$url"/>
  (if you see this warning tell Doug!)
          </xsl:message>
	  <xsl:choose>
	    <xsl:when test="$url != ''"><xsl:value-of select="$url"/></xsl:when>
	    <xsl:otherwise>
	      <xsl:message terminate="no">
 WARNING: page has no canonical link (missing canonicalbase/url params)
	      </xsl:message>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:when>
	<xsl:when test="$page != ''"><xsl:value-of select="concat($canonicalbase, $page)"/></xsl:when>
	<xsl:when test="$pagename != ''"><xsl:value-of select="concat($canonicalbase, $pagename, '.html')"/></xsl:when>
	<xsl:otherwise>
	  <xsl:message terminate="no">
 WARNING: page has no canonical link (missing page/pagename)
	  </xsl:message>
	</xsl:otherwise>
      </xsl:choose></xsl:variable>
      <xsl:if test="$canonicalurl != ''">
	<xsl:variable name="cpos" select="string-length($canonicalurl) - 10"/>
	<xsl:if test="$cpos &lt; 1">
	  <xsl:message terminate="yes">
 ERROR: canonicalurl=<xsl:value-of select="$canonicalurl"/> is too short!
	  </xsl:message>
	</xsl:if>
	<xsl:choose>
	  <xsl:when test="substring($canonicalurl, $cpos) = '/index.html'">
	    <link rel="canonical" href="{substring($canonicalurl, 1, $cpos)}"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <link rel="canonical" href="{$canonicalurl}"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:if>

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

      <xsl:apply-templates select="info/css" mode="header"/>

      <xsl:call-template name="add-sao-metadata">
	<xsl:with-param name="title" select="normalize-space($title)"/>
      </xsl:call-template>
      
    </head>
    
    <xsl:call-template name="start-tag"/>body<xsl:call-template name="end-tag"/>  <!--// open html body //-->
  </xsl:template> <!--* add-htmlhead *-->

  <!--*
      * test out trying to allow CSS in header blocks, hence the mode=header
      *
      * there are two forms: bare css tag, where the contents are processed,
      * or an empty css block with a src tag. The latter case should be
      * updated to support optional media and title attributes
    -->
  <xsl:template match="css[@src]" mode="header">
    <xsl:if test="normalize-space(.)!=''">
      <xsl:message terminate="yes">
 ERROR: css tag with src attribute is not empty:
   tag=<xsl:value-of select="@src"/>
   contents=<xsl:value-of select="."/>
      </xsl:message>
    </xsl:if>
	
    <link rel="stylesheet" href="{@src}"/>
  </xsl:template>

  <xsl:template match="css" mode="header">
    <style type="text/css">
      <xsl:apply-templates/>
    </style>
  </xsl:template>

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

      <xsl:call-template name="add-ssi-include">
        <xsl:with-param name="file" select="concat('navbar_',$name,'.incl')"/>
      </xsl:call-template>
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

    
      <br clear="all"/>
      <p>
	  Last published by: <xsl:value-of select="$updateby"/>
	    at: <xsl:value-of select="$time"/><xsl:text> </xsl:text>
	    <xsl:value-of select="$date"/>
	</p>
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
      *-->
  <xsl:template match="whatsnew">
    <xsl:call-template name="add-whatsnew-link"/>
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
    <div class="noprint" style="text-align: center">
      <span class="pheader">

      <!--// split so that title text is accurate for Sherpa //-->
      <xsl:if test="$site = 'ciao' or $site = 'chips'">
	<a title="What's new for CIAO &amp; users of CIAO" href="{$newsfileurl}">WHAT'S NEW</a>
	<xsl:if test="$watchouturl != ''">
	  <xsl:text> | </xsl:text>
	  <a title="Items to be aware of when using CIAO" href="{$watchouturl}">WATCH OUT</a>
	</xsl:if>
      </xsl:if>


      <xsl:if test="$site = 'sherpa'">
	<a title="What's new for Sherpa &amp; users of Sherpa" href="{$newsfileurl}">WHAT'S NEW</a>
	<xsl:if test="$watchouturl != ''">
	  <xsl:text> | </xsl:text>
	  <a title="Items to be aware of when using Sherpa" href="{$watchouturl}">WATCH OUT</a>
	</xsl:if>
      </xsl:if>

      </span>
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

</xsl:stylesheet>
