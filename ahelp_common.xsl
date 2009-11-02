<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!-- AHELP XML to HTML convertor using XSL Transformations -->

<!--* 
    * Recent changes:
    *  30 May 2008 DJB Removed links to PDF version in header/footer
    *  21 Feb 2008 ECG - updated copyright statement to extend to 2008
    *  Oct 15 2007 DJB
    *    added $allowed-sites, removed dist from $allowed-types; copyright statement
    *    now 2007
    * 
    * Common templates used by ahelp.xsl and ahelp_index.xsl. These stylesheets
    * will define a number of parameters used below (don't describe them here
    * since they'd quickly become out of date)
    * 
    * Notes:
    *  . we make use of EXSLT functions for date/time
    *    (see http://www.exslt.org/). 
    *    Actually, could have used an input parameter to do this
    * 
    *  . for search/replace, use a function obtained from
    *    http://www.exslt.org/str/functions/replace/
    *    (not an actual EXSLT function since not implemented in libxslt)
    * 
    *  . do we need to sent the url parameter to templates now it is
    *    a 'global' variable?
    * 
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:date="http://exslt.org/dates-and-times"
  xmlns:str="http://exslt.org/strings"
  xmlns:func="http://exslt.org/functions"
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="date str func exsl">

  <!--*
      * allowed values for these parameters (if there are any)
      * - see check-param-allowed template for why want spaces
      *-->
  <xsl:variable name="allowed-types"   select="' live test trial '"/>
  <xsl:variable name="allowed-sites"   select="' ciao chips sherpa '"/>

  <!--* I THINK SOMETHING IS GOING WRONG .... *-->
  <xsl:param name="depth" value="''"/>

  <!--*
      * Quit with an error message if:
      *   the parameter is undefined
      *   the parameter doesn't match it's allowed values (optional)
      *
      * Parameters:
      * . pname - string, required
      *     the name of the parameter that has not been defined
      * . pvalue - required
      *     the value of the parameter that has not been defined
      * . allowed - string, optional
      *     a string containing all the allowed values separated
      *     on both sides, by a space:
      *     e.g.  " foo bar "
      * . slashcheck - integer, optional default=0
      *     if true then checks that the value ends in a "/"
      *
      * We could add ' ' to the start/end of $allowed, but can't be bothered
      *
      *-->
  <xsl:template name="check-param">
    <xsl:param name="pname"/>
    <xsl:param name="pvalue"/>
    <xsl:param name="allowed"/>
    <xsl:param name="slashcheck" value="0"/>

    <!--* check 'existence' *-->
    <xsl:if test="$pvalue=''">
      <xsl:message terminate="yes">
 Error:
   the stylesheet has been called without setting the required parameter
     <xsl:value-of select="$pname"/>

      </xsl:message>
    </xsl:if>

    <!--* check it's value (optional) *-->
    <xsl:if test="$allowed != ''">
      <xsl:if test="contains($allowed,concat(' ',$pvalue,' ')) = false()">
	<xsl:message terminate="yes">
 Error:
   the parameter <xsl:value-of select="$pname"/> was set to <xsl:value-of select="$pvalue"/>
   when it can only be one of:
   <xsl:value-of select="$allowed"/>

	</xsl:message>
      </xsl:if>
    </xsl:if>

    <!--* does the parameter end in a / ? *-->
    <xsl:if test="boolean($slashcheck)">
      <xsl:if test="substring($pvalue,string-length($pvalue))!='/'">
	<xsl:message terminate="yes">
  Error: <xsl:value-of select="$pname"/> parameter must end in a / character.
    <xsl:value-of select="$pname"/>=<xsl:value-of select="$pvalue"/>
	</xsl:message>
      </xsl:if>
    </xsl:if>

  </xsl:template> <!--* name=check-param *-->

  <!--* start/end paragraphs *-->
  <xsl:template name="start-para"><xsl:text disable-output-escaping="yes">&lt;p&gt;</xsl:text></xsl:template>
  <xsl:template name="end-para"><xsl:text disable-output-escaping="yes">&lt;/p&gt;</xsl:text></xsl:template>

  <!--*
      * We 'highlight' the text.
      *
      * Prior to CIAO 3.1 (v1.19 of this file) this template used to
      * be split into two (add-start/end-highlight) AND it used to
      * include checks for being called within a PARA block. We have
      * consolidated things (which makes the code a lot nicer to read/write)
      * and moved the logic for checking within PARA's out to the
      * calling templates (since they know - from the DTD - whether they
      * are in a PARA)
      * 
      * The contents to highlight are supplied in the parameter contents
      * and can be a node set (but already processed). This way we can
      * handle a number of calling cases.
      * 
      *-->
  <xsl:template name="add-highlight">
    <xsl:param name="contents" select="''"/>

    <xsl:if test="$contents = ''">
      <xsl:message terminate="yes">
 ERROR: add-highlight called with no/empty contents parameter for key=<xsl:value-of select="//ENTRY/@key"/> context=<xsl:value-of select="//ENTRY/@context"/>
      </xsl:message>
    </xsl:if>

    <!--* yay CSS (although highlight is a poor class name) *-->
    <pre class="highlight"><xsl:copy-of select="$contents"/></pre>

  </xsl:template> <!--* name=add-highlight *-->

  <!--*
      * add a 'title' with an associated HTML anchor. The 
      * size of the title depends on where we are:
      *    h5 - within a PARAMLIST (as param title is h4)
      *    h3 - otherwise
      *
      * Parameters:
      *   title - string, required
      *-->
  <xsl:template name="add-title-anchor">
    <xsl:param name="title"/>

    <xsl:if test="$title=''">
      <xsl:message terminate="yes">
  *** ERROR: called add-title-anchor with an empty/missing title
      </xsl:message>
    </xsl:if>

    <xsl:variable name="type"><xsl:choose>
	<xsl:when test="ancestor::PARAM">h5</xsl:when>
	<xsl:otherwise>h3</xsl:otherwise>
      </xsl:choose></xsl:variable>

    <xsl:element name="{$type}">
      <xsl:attribute name="class">ahelpparatitle</xsl:attribute>
	<a name="{translate($title,' ','_')}"><xsl:value-of select="$title"/></a>
    </xsl:element>

  </xsl:template> <!--* name=add-title-anchor *-->

  <!--*
      * check the input parameters are input
      *
      * Parameters:
      *   name - string, required
      *     name of parameter
      *
      *   value - string, required
      *     input value of parameter
      *
      *   template - string, required
      *     name of template
      *
      *-->
  <xsl:template name="check-input-param">
    <!--* we don't check these parameters! *-->
    <xsl:param name="name"/>
    <xsl:param name="value"/>
    <xsl:param name="template"/>

    <xsl:if test="$value = ''">
      <xsl:message terminate="yes">
 Error: <xsl:value-of select="$template"/> called without a <xsl:value-of select="$name"/> parameter
      </xsl:message>
    </xsl:if>

  </xsl:template> <!--* name=check-input-param *-->

  <!--*
      * add a navbar and the spacer column
      *
      * Parameters:
      *   navbar - string, required
      *     included navbar_{$navbar}.incl
      *-->
  <xsl:template name="add-navbar">
    <xsl:param name="navbar" select="''"/>

    <xsl:call-template name="check-input-param">
      <xsl:with-param name="name"     select="'navbar'"/>
      <xsl:with-param name="value"    select="$navbar"/>
      <xsl:with-param name="template" select="'add-navbar'"/>
    </xsl:call-template>

    <td class="navbar" valign="top">
      <!--* add the navbar *-->

      <xsl:choose>
	<xsl:when test="starts-with(//ENTRY/@context,'sl.') and $site!='ciao'">
	  <xsl:comment>#include virtual="navbar_ahelp_slang.incl"</xsl:comment>
	</xsl:when>
	<xsl:when test="starts-with(//ENTRY/@context,'py.') and $site!='ciao'">
	  <xsl:comment>#include virtual="navbar_ahelp_python.incl"</xsl:comment>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:comment>#include virtual="navbar_<xsl:value-of select="$navbar"/>.incl"</xsl:comment>
	</xsl:otherwise>
      </xsl:choose>

      <xsl:call-template name="newline"/>
    </td>
    
  </xsl:template> <!--* name=add-navbar *-->

  <!--*
      * output the standard banner (head) for format=web
      *
      * Parameters:
      *   lastmod - string, required
      *     last modified date
      *
      *-->
  <xsl:template name="add-standard-banner-header">
    <xsl:param name="lastmod"  select="''"/>
    <xsl:param name="pagename"  select="''"/>

    <!--* TODO: remove me when happy stylesheets have been cleaned up *-->
    <xsl:if test="$pagename != ''">
      <xsl:message terminate="yes">
 ERROR: add-standard-banner-header called with pagename=<xsl:value-of select="$pagename"/>
      </xsl:message>
    </xsl:if>

    <xsl:call-template name="check-input-param">
      <xsl:with-param name="name"     select="'lastmod'"/>
      <xsl:with-param name="value"    select="$lastmod"/>
      <xsl:with-param name="template" select="'add-standard-banner-header'"/>
    </xsl:call-template>

    <!--* we break up into lots of different sections to try and make lynx happier *-->

    <!--*
        * this is only going to be picked up by user agents that do not process
        * stylesheets - as long as the stylesheet has a rule
        *    .hideme { display: none; }
        * so it's a good way of getting to lynx users
        *-->
    <div class="hideme">
      <a href="#navtext" accesskey="s"
	title="Skip to the navigation links">Skip to the navigation links</a>
    </div>

    <div class="topbar">
      <xsl:call-template name="add-cxc-search-ssi"/>
    </div>

    <div class="topbar">
      <div class="lastmodbar">Last modified: <xsl:value-of select="$lastmod"/></div>
      <xsl:if test="$url != ''">
	<!--* this is a safety check for now *-->
	<br class="hideme"/>
	<div class="urlbar">URL: <xsl:value-of select="$url"/></div>
      </xsl:if>
    </div>

  </xsl:template> <!--* name=add-standard-banner-header *-->

  <!--*
      * output the standard banner (foot) for format=web
      *
      * Parameters:
      *   lastmod - string, required
      *     last modified date
      *
      *-->
  <xsl:template name="add-standard-banner-footer">
    <xsl:param name="lastmod"  select="''"/>
    <xsl:param name="pagename"  select="''"/>

    <!--* TODO: remove me when happy stylesheets have been cleaned up *-->
    <xsl:if test="$pagename != ''">
      <xsl:message terminate="yes">
 ERROR: add-standard-banner-footer called with pagename=<xsl:value-of select="$pagename"/>
      </xsl:message>
    </xsl:if>

    <xsl:call-template name="check-input-param">
      <xsl:with-param name="name"     select="'lastmod'"/>
      <xsl:with-param name="value"    select="$lastmod"/>
      <xsl:with-param name="template" select="'add-standard-banner-footer'"/>
    </xsl:call-template>

    <div class="bottombar">
      <div>Last modified: <xsl:value-of select="$lastmod"/></div>
    </div>

  </xsl:template> <!--* name=add-standard-banner-footer *-->

  <xsl:template name="add-cxc-search-ssi">
    <xsl:comment>#include virtual="<xsl:value-of select="$searchssi"/>"</xsl:comment>
    <xsl:call-template name="newline"/>
  </xsl:template> <!--* name=add-cxc-search-ssi *-->

  <!--*
      * add the CXC header
      * - depends on the type (live, test, trial) of the transform
      *-->

  <xsl:template name="add-cxc-header">

    <xsl:if test='$type!="live"'>
      <!--* add the body tag (start) and test header info *-->
      <xsl:call-template name="add-start-body-white"/>
      <xsl:call-template name="add-cxc-test-banner"/>
    </xsl:if>

    <xsl:choose>
      <xsl:when test='$type="trial"'>
        <xsl:call-template name="add-cxc-header-trial"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="add-cxc-header-live"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template> <!--* add-cxc-header *-->

  <!--*
      * add the standard header files
      *-->
  <xsl:template name="add-cxc-header-live">
    <xsl:comment>#include virtual="/incl/header.html"</xsl:comment>
    <xsl:call-template name="newline"/>

  </xsl:template>

  <!--*
      * add the header for the trial site
      *
      * HTML is based upon the contents of the include files header.html
      * and search.html from the live site Aug 2002
      * (modified to point to different files/URLs when required)
      *-->
  <xsl:template name="add-cxc-header-trial">

    <table border="0" cellpadding="0" cellspacing="0" width="100%">
      <tr>
	<td align="left" valign="top">
	  <map name="header_left">
	    <area alt="Chandra Science" coords="0,4,192,72" href="http://cxc.harvard.edu/" shape="RECT"/>
	  </map>
	  <img src="/sds/imgs/header_left.gif" border="0" alt="Chandra Science" usemap="#header_left"/>
	</td>
	
	<td align="right" valign="top">
	  <!--* note: all but CIAO links are to the live site *-->
	  <map name="header_right">
	    <area alt="About Chandra" coords="0,14,107,31" href="http://cxc.harvard.edu/udocs/overview.html" shape="RECT"/>
	    <area alt="Archive" coords="118,13,185,32" href="http://cxc.harvard.edu/cda/" shape="RECT"/>
	    <area alt="Proposer" coords="197,12,268,31" href="http://cxc.harvard.edu/prop.html" shape="RECT"/>
	    <area alt="Instruments &amp; Calibration" coords="283,14,453,32" href="http://cxc.harvard.edu/cal/" shape="RECT"/>
	    <area alt="Newsletters" coords="112,33,198,51" href="http://cxc.harvard.edu/newsletters.html" shape="RECT"/>
	    <area alt="Data Analysis" coords="1,35,97,50" href="/sds/ciao/" shape="RECT"/>
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
    
    <!--* add search button *-->
    <form action="http://cxc.harvard.edu/cgi-gen/AT-CXCsearch.cgi" method="POST">
      <table cellpadding="0" cellspacing="0" width="100%" border="0">
	<tr>
	  <td align="right">
	    <font face="Arial,Helvetica,sans-serif">
	      <input type="Text" name="search" size="17"/>
	      <xsl:call-template name="add-nbsp"/>
	      <xsl:call-template name="add-nbsp"/>
	      <input type="image" name="SearchButton" align="middle"
		src="/sds/imgs/search.gif"/>
	      <input type="hidden" name="sp" value="sp"/>
	    </font>
	  </td>
        </tr>
      </table>
    </form>
    <br/>
  </xsl:template> <!--* name=add-cxc-header-trial *-->

  <!--* used by the test/trial headers *-->
  <xsl:template name="add-start-body-white">
    <xsl:call-template name="add-start-tag"/>body bgcolor=<xsl:call-template name="add-quote"/>#FFFFFF<xsl:call-template name="add-quote"/><xsl:call-template name="add-end-tag"/>
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
  <xsl:template name="add-cxc-test-banner">

    <xsl:comment> This header is for pages on the test site only </xsl:comment>
    <xsl:call-template name="newline"/>

    <!--* set up the time/date using EXSLT *-->
    <xsl:variable name="dt"   select="date:date-time()"/>
    <xsl:variable name="date" select="substring(date:date($dt),1,10)"/>
    <xsl:variable name="time" select="substring(date:time($dt),1,8)"/>

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

  </xsl:template> <!--* name=add-cxc-test-banner *-->

  <!--*
      * output the page "footer"
      *-->
  <xsl:template name="add-cxc-footer">

    <br/>
    <xsl:comment>#include virtual="/incl/footer.html"</xsl:comment>
    <xsl:call-template name="newline"/>

  </xsl:template> <!--* add-cxc-footer *-->

  <!--* taken from helper.xsl *-->

  <xsl:template name="add-start-tag">
    <xsl:text disable-output-escaping="yes">&lt;</xsl:text>
  </xsl:template>
  <xsl:template name="add-end-tag">
    <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
  </xsl:template>
  
  <xsl:template name="add-br">
    <xsl:text disable-output-escaping="yes">&lt;br&gt;</xsl:text>
  </xsl:template>
  <xsl:template name="add-hr">
    <xsl:text disable-output-escaping="yes">&lt;hr&gt;</xsl:text>
  </xsl:template>

  <xsl:template name="add-start-tr">
    <xsl:text disable-output-escaping="yes">&lt;tr&gt;</xsl:text>
  </xsl:template>
  <xsl:template name="add-end-tr">
    <xsl:text disable-output-escaping="yes">&lt;/tr&gt;</xsl:text>
  </xsl:template>

  <xsl:template name="add-start-td">
    <xsl:text disable-output-escaping="yes">&lt;td&gt;</xsl:text>
  </xsl:template>
  <xsl:template name="add-end-td">
    <xsl:text disable-output-escaping="yes">&lt;/td&gt;</xsl:text>
  </xsl:template>

  <xsl:template name="add-start-dl">
    <xsl:text disable-output-escaping="yes">&lt;dl&gt;</xsl:text>
  </xsl:template>
  <xsl:template name="add-end-dl">
    <xsl:text disable-output-escaping="yes">&lt;/dl&gt;</xsl:text>
  </xsl:template>

  <xsl:template name="add-start-pre">
    <xsl:text disable-output-escaping="yes">&lt;pre&gt;</xsl:text>
  </xsl:template>
  <xsl:template name="add-end-pre">
    <xsl:text disable-output-escaping="yes">&lt;/pre&gt;</xsl:text>
  </xsl:template>

  <xsl:template name="add-quote">
    <xsl:text disable-output-escaping="yes">&quot;</xsl:text>
  </xsl:template>
  <xsl:template name="add-nbsp">
    <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
  </xsl:template>
  
  <xsl:template name="add-end-body">
    <xsl:call-template name="add-start-tag"/>/body<xsl:call-template name="add-end-tag"/>
  </xsl:template>

  <xsl:template name="add-font-m1">
    <xsl:call-template name="add-start-tag"/>font size=&quot;-1&quot;<xsl:call-template name="add-end-tag"/>
  </xsl:template>
  <xsl:template name="add-end-font">
    <xsl:call-template name="add-start-tag"/>/font<xsl:call-template name="add-end-tag"/>
  </xsl:template>

  <!--* make this bar stand out *-->
  <xsl:template name="add-hr-strong">
    <hr size="3"/> <!--* could also use noshade="0" *-->
  </xsl:template>

  <!--***** START: TEMP SEARCH/REPLACE FUNCTION *****-->

  <!--*
      * the following was obtained from
      *   http://www.exslt.org/str/functions/replace/
      * since libXSLT does not natively support str:replace
      *
      * Parameters:
      *   string  - string, required
      *     the text to act on
      *   search  - string, required
      *     the text to be replaced
      *   replace - string, required
      *     the replacement text
      *
      *
      *-->
  <func:function name="str:replace">
    <xsl:param name="string" select="''" />
    <xsl:param name="search" select="/.." />
    <xsl:param name="replace" select="/.." />
    <xsl:choose>
      <xsl:when test="not($string)">
        <func:result select="/.." />
      </xsl:when>
      <xsl:when test="function-available('exsl:node-set')">
	<!-- this converts the search and replace arguments to node sets
	if they are one of the other XPath types -->
	<xsl:variable name="search-nodes-rtf">
	  <xsl:copy-of select="$search" />
	</xsl:variable>
	<xsl:variable name="replace-nodes-rtf">
	  <xsl:copy-of select="$replace" />
	</xsl:variable>
	<xsl:variable name="replacements-rtf">
	  <xsl:for-each select="exsl:node-set($search-nodes-rtf)/node()">
	    <xsl:variable name="pos" select="position()" />
	    <replace search="{.}">
	      <xsl:copy-of select="exsl:node-set($replace-nodes-rtf)/node()[$pos]" />
	    </replace>
	  </xsl:for-each>
	</xsl:variable>
	<xsl:variable name="sorted-replacements-rtf">
	  <xsl:for-each select="exsl:node-set($replacements-rtf)/replace">
	    <xsl:sort select="string-length(@search)" data-type="number" order="descending" />
	    <xsl:copy-of select="." />
	  </xsl:for-each>
	</xsl:variable>
	<xsl:variable name="result">
	  <xsl:choose>
	    <xsl:when test="not($search)">
	      <xsl:value-of select="$string" />
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:call-template name="str:_replace">
		<xsl:with-param name="string" select="$string" />
		<xsl:with-param name="replacements" select="exsl:node-set($sorted-replacements-rtf)/replace" />
	      </xsl:call-template>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:variable>
	<func:result select="exsl:node-set($result)/node()" />
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
  ERROR: function implementation of str:replace() relies on exsl:node-set().
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>

  <xsl:template name="str:_replace">
    <xsl:param name="string" select="''" />
    <xsl:param name="replacements" select="/.." />
    <xsl:choose>
      <xsl:when test="not($string)" />
      <xsl:when test="not($replacements)">
	<xsl:value-of select="$string" />
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="replacement" select="$replacements[1]" />
	<xsl:variable name="search" select="$replacement/@search" />
	<xsl:choose>
	  <xsl:when test="not(string($search))">
	    <xsl:value-of select="substring($string, 1, 1)" />
	    <xsl:copy-of select="$replacement/node()" />
	    <xsl:call-template name="str:_replace">
	      <xsl:with-param name="string" select="substring($string, 2)" />
	      <xsl:with-param name="replacements" select="$replacements" />
	    </xsl:call-template>
	  </xsl:when>
	  <xsl:when test="contains($string, $search)">
	    <xsl:call-template name="str:_replace">
	      <xsl:with-param name="string" select="substring-before($string, $search)" />
	      <xsl:with-param name="replacements" select="$replacements[position() > 1]" />
	    </xsl:call-template>      
	    <xsl:copy-of select="$replacement/node()" />
	    <xsl:call-template name="str:_replace">
	      <xsl:with-param name="string" select="substring-after($string, $search)" />
	      <xsl:with-param name="replacements" select="$replacements" />
	    </xsl:call-template>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:call-template name="str:_replace">
	      <xsl:with-param name="string" select="$string" />
	      <xsl:with-param name="replacements" select="$replacements[position() > 1]" />
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--***** END: TEMP SEARCH/REPLACE FUNCTION *****-->
  
</xsl:stylesheet> <!--* FIN *-->
