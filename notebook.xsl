<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Convert an XML web page into an HTML one
    * for notebooks
    *
    * info/notebook contains the notebook page
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="exsl extfuncs">

  <!--*
      * Options specific to notebooks
      *   the contents of the header
      *   the notebook itself
      *-->
  <xsl:param name="notebook_header" select='""'/>
  <xsl:param name="notebook_contents" select='""'/>
  
  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-page" select="extfuncs:register-import-dependency('notebook.xsl')"/>

  <xsl:output method="text"/>

  <!--* we place this here to see if it works (was in header.xsl and wasn't working
      * - and it seems to
      *-->
  <!--* a template to output a new line (useful after a comment)  *-->
  <xsl:template name="newline">
<xsl:text> 
</xsl:text>
  </xsl:template>

  <!--* load in the set of "global" parameters *-->
  <xsl:include href="globalparams.xsl"/>

  <!--* include the stylesheets AFTER defining the variables *-->
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <!--*
      * top level: create
      *   index.html
      *
      *-->
  <xsl:template match="/">

    <!--* check the params are okay *-->
    <xsl:call-template name="is-site-valid"/>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'install'"/>
      <xsl:with-param name="pvalue" select="$install"/>
    </xsl:call-template>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'canonicalbase'"/>
      <xsl:with-param name="pvalue" select="$canonicalbase"/>
    </xsl:call-template>

    <!--* we only want the top-level notebook *-->
    <xsl:apply-templates select="/notebook"/>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: <page>.html
      *-->

  <xsl:template match="/notebook">

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$pagename"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--*
        * create HTML5 document, see
        * http://w3c.github.io/html/syntax.html#doctype-legacy-string
        * http://www.microhowto.info/howto/generate_an_html5_doctype_using_xslt.html
        * https://stackoverflow.com/a/19379446
        *
        * Not sure that version="5.0" is actually working properly
        * (or maybe my libxslt is too old)
	*-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
                  doctype-system="about:legacy-compat"
		  version="5.0">

      <!--* we start processing the XML file here *-->
      <html lang="en-US">

	<!--*
	    * make the HTML head node
	    * - this is a manual version of add-htmlhead[-standard]
	    *-->
	<xsl:variable name="title"><xsl:choose>
	      <xsl:when test="boolean(//notebook/info/title/long)"><xsl:value-of select="info/title/long"/></xsl:when>
	      <xsl:when test="boolean(//notebook/info/title/short)"><xsl:value-of select="info/title/short"/></xsl:when>
	      <xsl:otherwise>
		<xsl:message terminate="yes">
 ERROR no info/title block
		</xsl:message>
	      </xsl:otherwise>
	    </xsl:choose></xsl:variable>

	<head>
	  <title><xsl:value-of select="$title"/></title>

	  <!--* any meta information to add ? *-->
	  <xsl:apply-templates select="info/metalist"/>

	  <!--* any scripts ? *-->
	  <xsl:apply-templates select="info/htmlscripts"/>

	  <xsl:variable name="nmath" select="count(//math) + count(//inlinemath)"/>
	  <xsl:if test="$use-mathjax = 1 and ($nmath != 0)">
	    <xsl:if test="$mathjaxpath = ''">
	      <xsl:message terminate="yes">
 ERROR: use-mathjax=1 but mathjaxpath is unset and the page contains math tags!
              </xsl:message>
	    </xsl:if>

	    <script src="{$mathjaxpath}"/>
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

	  <xsl:apply-templates select="info/css" mode="header"/>

	  <xsl:call-template name="add-sao-metadata">
	    <xsl:with-param name="title" select="normalize-space($title)"/>
	  </xsl:call-template>

	  <!-- add in navbar header contents -->
	  <xsl:value-of select="$notebook_header" disable-output-escaping="yes"/>

	</head>

	<!-- * create the page contents *-->
	<xsl:apply-templates select="text"/>

      </html>

    </xsl:document>
  </xsl:template> <!--* match=page *-->

  <xsl:template match="text[boolean(//notebook/info/navbar)]">

    <xsl:call-template name="add-body-withnavbar">
      <xsl:with-param name="contents">
	<xsl:apply-templates/>
      </xsl:with-param>
      <xsl:with-param name="navbar">
	<xsl:call-template name="add-navbar">
	  <xsl:with-param name="name" select="//notebook/info/navbar"/>
	</xsl:call-template>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!-- text with navbar -->

  <!-- no navbar -->
  <xsl:template match="text">

    <xsl:call-template name="add-body-nonavbar">
      <xsl:with-param name="contents">
	<xsl:apply-templates/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* text without navbar *-->

  <!--*
      * Add the notebook as
      *    title                  CURRENTLY NOT IMPLEMENTED
      *    [link to notebook]
      *    notebook_contents
      *-->
  <xsl:template match="notebook">
    <div class="notebook">
      <p class="notebook-link">
	View the
	<a><xsl:attribute name="href"><xsl:value-of select="//info/notebook"/></xsl:attribute>notebook</a>.
      </p>
    
      <xsl:value-of select="$notebook_contents" disable-output-escaping="yes"/>
    </div>
  </xsl:template>
      
  
</xsl:stylesheet>
