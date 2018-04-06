<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* AHELP XML to HTML convertor using XSL Transformations
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
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="date str func exsl extfuncs">

  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-ahelp_common" select="extfuncs:register-import-dependency('ahelp_common.xsl')"/>

  <xsl:include href="common.xsl"/>

  <!--*
      * allowed values for these parameters (if there are any)
      * - see check-param-allowed template for why want spaces
      *-->
  <xsl:variable name="allowed-types"   select="' live test trial '"/>
  <xsl:variable name="allowed-sites"   select="' ciao chips sherpa '"/>

  <!--* I THINK SOMETHING IS GOING WRONG .... *-->
  <xsl:param name="depth" select="''"/>

  <xsl:param name="favicon" select='""'/>

  <!--*
      * The current date (for the 'last modified' date); lastmod is not used for
      * the individual ahelp pages, but lastmodiso is.
      *-->
  <xsl:variable name="dt" select="date:date-time()"/>
  <xsl:variable name="lastmod"
    select="concat(date:day-in-month($dt),' ',date:month-name($dt),' ',date:year($dt))"/>

  <!--*
      * On Lenin using XSLT version 1.1.28 the following fails with:
      * xmlXPathCompOpEval: function month-in-year bound to undefined prefix date
      * xmlXPathCompOpEval: function day-in-month bound to undefined prefix date
      * so separating out the call to the date function and its use in xsl:number,
      * as this seems to work
  <xsl:variable name="month2"><xsl:number value="date:month-in-year($dt)" format="01"/></xsl:variable>
  <xsl:variable name="day2"><xsl:number value="date:day-in-month($dt)" format="01"/></xsl:variable>
      *
      *-->

  <xsl:variable name="hack-month2"><xsl:value-of select="date:month-in-year($dt)"/></xsl:variable>
  <xsl:variable name="hack-day2"><xsl:value-of select="date:day-in-month($dt)"/></xsl:variable>
  <xsl:variable name="month2"><xsl:number value="$hack-month2" format="01"/></xsl:variable>
  <xsl:variable name="day2"><xsl:number value="$hack-day2" format="01"/></xsl:variable>

  <xsl:variable name="lastmodiso"
		select="concat(date:year($dt), '-', $month2, '-', $day2)"/>

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
    <xsl:param name="slashcheck" select="0"/>

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
      <xsl:attribute name="id"><xsl:value-of select="translate($title,' ','_')"/></xsl:attribute>
      <xsl:value-of select="$title"/>
    </xsl:element>

  </xsl:template> <!--* name=add-title-anchor *-->

  <!--*
      * add a navbar and the spacer column
      *
      * Parameters:
      *   navbar - string, required
      *     included navbar_{$navbar}.incl
      *-->
  <xsl:template name="add-navbar">
    <xsl:param name="navbar" select="''"/>

    <xsl:call-template name="check-nonempty-param">
      <xsl:with-param name="name"     select="'navbar'"/>
      <xsl:with-param name="value"    select="$navbar"/>
      <xsl:with-param name="template" select="'add-navbar'"/>
    </xsl:call-template>

    <!--* add the navbar *-->
    <xsl:call-template name="add-ssi-include">
      <xsl:with-param name="file" select="concat('navbar_', $navbar, '.incl')"/>
    </xsl:call-template>
    
  </xsl:template> <!--* name=add-navbar *-->

  <!--* used by the test/trial headers *-->
  <xsl:template name="add-start-body-white">
    <xsl:call-template name="add-start-tag"/>body bgcolor=<xsl:call-template name="add-quote"/>#FFFFFF<xsl:call-template name="add-quote"/><xsl:call-template name="add-end-tag"/>
  </xsl:template>

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
  
<!--  <xsl:template name="add-font-m1">
    <xsl:call-template name="add-start-tag"/>font size=&quot;-1&quot;<xsl:call-template name="add-end-tag"/>
  </xsl:template>
  <xsl:template name="add-end-font">
    <xsl:call-template name="add-start-tag"/>/font<xsl:call-template name="add-end-tag"/>
  </xsl:template>
-->

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
