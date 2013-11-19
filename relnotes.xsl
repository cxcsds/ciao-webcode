<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Handle CIAO release notes. This creates a main page and
    * creates 'slugs' (or includable snippets) for other pages.
    *
    * We only want to generate the slugs for the current release, so
    * we check relnotes/@release against the siteversion parameter. In order
    * support updates (e.g. CIAO 4.5.2) then the check is that siteversion
    * matches the start of relnotes/@release (since siteversion is expected
    * to remain at 4.5, although this is not guaranteed).
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="exsl extfuncs">

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
      *   $pagename.html
      *   slugs for tools changed in this release (to be used
      *     to populate the ahelp files when they are published)
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

    <xsl:apply-templates select="relnotes" mode="page"/>
    <xsl:if test="$site = 'ciao' and starts-with(//relnotes/@release, $siteversion)">
      <xsl:apply-templates select="//relnotes/text/category[@name='Tools']" mode="ahelp-relnotes"/>
    </xsl:if>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: $pagename.html
      *-->

  <xsl:template match="relnotes" mode="page">

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$pagename"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="utf-8">

      <!--* we start processing the XML file here *-->
      <html lang="en">

	<xsl:call-template name="add-htmlhead-standard"/>
	<xsl:call-template name="add-disclaimer"/>
	<xsl:call-template name="add-header"/>

	<!--// main div begins page layout //-->
	<div id="main">

	  <!--* the main text *-->
	  <div id="content">
	    <div class="wrap">
       
              <xsl:variable name="release">
		<xsl:value-of select="@release"/>
	      </xsl:variable>
	      
	      <h1 class="pagetitle">
		CIAO <xsl:value-of select="$release"/> Release Notes
	      </h1>
	      
	      <xsl:if test="@package">
		<h2 class="pagetitle"><xsl:value-of select="@package"/> Release</h2>
	      </xsl:if>
	      
              <div class="qlinkbar"><a href="history.html">Version History</a></div>
	      
	      <hr/>
	      
	      <!--* add any summary text *-->
	      <xsl:if test="text/summary">
	        <xsl:apply-templates select="text/summary/*"/>
		
	        <hr/>
	      </xsl:if>
	      
	      <ul>
	        <xsl:for-each select="text/category">
	          <li>
	            <a>
	              <xsl:attribute name="href">
	                <xsl:value-of select="concat('#', translate(@name,' /',''))"/>
	              </xsl:attribute>
	              <xsl:value-of select="@name"/>
	            </a>
	          </li>
	        </xsl:for-each> <!-- select="category" -->
	      </ul>
	      
	      <hr/>
	      
	      <xsl:for-each select="text/category">
		<h2>
		  <a>
	            <xsl:attribute name="name">
	              <xsl:value-of select="translate(@name,' /','')"/>
	            </xsl:attribute>
		    <xsl:value-of select="@name"/>
		  </a>
		</h2>
		
		<xsl:apply-templates select="intro"/>
		
		<xsl:for-each select="section">
		  <h3><xsl:value-of select="@name"/></h3>
		  
		  <ul>
		    <xsl:for-each select="note">
		      <li>
		        <!--pre><xsl:value-of select="."/></pre-->
		        <xsl:apply-templates select="child::*|child::text()"/>
		      </li>
		    </xsl:for-each> <!-- select="note" -->
		  </ul>
		</xsl:for-each> <!-- select="section" -->
	
	        <hr/>
	      </xsl:for-each> <!-- select="category" -->

	    </div>
	  </div> <!--// close id=content //-->

	  <div id="navbar">
	    <div class="wrap">
	      <a name="navtext"/>
	      
	      <xsl:call-template name="add-navbar">
		<xsl:with-param name="name" select="info/navbar"/>
	      </xsl:call-template>
	    </div>
	  </div> <!--// close id=navbar //-->
	  
	</div> <!--// close id=main  //-->
	    
	<xsl:call-template name="add-footer"/>
	<xsl:call-template name="add-end-body"/>
      </html>
      
    </xsl:document>
  </xsl:template> <!--* match=relnotes, mode=page *-->

  <!--*
      * create the includes for the ahelp webpages; we assume
      * this is only called for $site='ciao'
      *
      *-->
  <xsl:template match="category" mode="ahelp-relnotes">

    <xsl:if test="$ahelpindexfile = ''">
      <xsl:message terminate="yes">

 ERROR: see Doug as you are processing a CIAO release notes section
    but have no ahelpindex information.

      </xsl:message>
    </xsl:if>

    <xsl:apply-templates mode="ahelp-relnotes"/>

  </xsl:template> <!--* match=category, mode=ahelp-relnotes *-->

  <!--*
      * We only want to process those section blocks which 
      *  . do not have @ahelpskip="1"
      *  . have a valid @ahelpkey attribute
      *    (ie there is an ahelp page matching @ahelpkey);
      *    if this attribute does not exist then use
      *    @name (which should exist).
      *-->
  <xsl:template match="section[@ahelpskip='1']" mode="ahelp-relnotes"/>

  <xsl:template match="section" mode="ahelp-relnotes">

    <xsl:variable name="pagename"><xsl:choose>
      <xsl:when test="boolean(@ahelpkey)"><xsl:value-of select="@ahelpkey"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="@name"/></xsl:otherwise>
    </xsl:choose></xsl:variable>
    <xsl:variable name="namematches" select="$ahelpindexfile//ahelp[key=$pagename]"/>
    <xsl:variable name="num" select="count($namematches)"/>

    <xsl:choose>
      <xsl:when test="$num=0">
        <xsl:message terminate="no">
 NOTE: release notes, no ahelp for [ahelp]name=<xsl:value-of select="$pagename"/> so skipping
        </xsl:message>
      </xsl:when>

      <xsl:when test="$num &gt; 1">
        <xsl:message terminate="yes">
 ERROR: tool release notes for [ahelp]name=<xsl:value-of select="$pagename"/>
   matches multiple (<xsl:value-of select="$num"/> ahelp files; see Doug
        </xsl:message>
      </xsl:when>

      <xsl:otherwise>
	<!-- write the slug to the storage area -->
	<xsl:variable name="outloc" select="$storageInfo//dir[@site=$site]"/>

	<xsl:variable name="filename"
	  select="concat($outloc, 'releasenotes/ciao_', $siteversion, '.', $pagename, '.slug.xml')"/>
      
        <!--* output filename to stdout (at present not used by publishing code) *-->
        <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>
	<xsl:variable name="should-not-be-a-function"
		      select="extfuncs:delete-file-if-exists($filename)"/>

        <xsl:document href="{$filename}" method="xml" encoding="utf-8">
	
	  <!--* add disclaimer about editing this HTML file *-->
	  <xsl:call-template name="add-disclaimer"/>
	  <slug>
	  <ul class="helplist">
	    <xsl:for-each select="note">
	      <li>
	        <!-- should this not just process everything as normal? -->
	        <xsl:apply-templates select="child::*|child::text()"/>
	      </li>
	    </xsl:for-each> <!-- select="note" -->
	  </ul> 
          </slug>
        </xsl:document>

      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* match=section, mode=ahelp-relnotes *-->

  <!--*
      * We can not guarantee that the contents do not contain <p>..</p>
      * tags, so we do not want to surround the whole thing in a p block
      * So we use a div instead.
      * We could be clever and look for the contents containing a p and
      * adding the containing p block if there are not any.
      *
      * This template is needed to remove the intro tag from the output
      *-->
  <xsl:template match="intro">
    <div>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template> <!-- match="@*|node()" -->

  <!--* note: we process the text so we can handle our `helper' tags *-->
  <xsl:template match="text">
   <xsl:apply-templates/>
  </xsl:template> <!--* text *-->

</xsl:stylesheet>
