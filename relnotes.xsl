<?xml version="1.0" encoding="UTF-8" ?>
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

  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-relnotes" select="extfuncs:register-import-dependency('relnotes.xsl')"/>

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

  <xsl:variable name="is-current-release" select="$site = 'ciao' and starts-with(//relnotes/@release, $siteversion)"/>

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
    <xsl:if test="$is-current-release">
      <xsl:apply-templates select="//relnotes/text/category[@name='Tools']" mode="ahelp-relnotes"/>
    </xsl:if>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: $pagename.html
      *-->

  <xsl:template match="relnotes" mode="page">

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$pagename"/>.html</xsl:variable>

    <xsl:variable name="release">
      <xsl:value-of select="@release"/>
    </xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
                  doctype-system="about:legacy-compat"
		  version="5.0">

      <!--* we start processing the XML file here *-->
      <html lang="en-US">

	<xsl:call-template name="add-htmlhead-standard"/>

	<xsl:call-template name="add-body-withnavbar">
	  <xsl:with-param name="contents">
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
		<!-- TODO: should this force the name attribute to be non-empty? -->
		<xsl:call-template name="add-section-title"/>
		<xsl:apply-templates select="intro"/>
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
	  </xsl:with-param>
	  
	  <xsl:with-param name="navbar">
	    <xsl:call-template name="add-navbar">
	      <xsl:with-param name="name" select="info/navbar"/>
	    </xsl:call-template>
	  </xsl:with-param>

	</xsl:call-template>

      </html>
      
    </xsl:document>
  </xsl:template> <!--* match=relnotes, mode=page *-->

  <!--*
      * Should the title include a link to the ahelp page?
      * This is *only* done for the current release, since
      * - prior to the 4.6 release - the necessary ahelpskip/ahelpkey
      * attributes were not used. The links could be added only
      * if the ahelp page exists in this case, but that is going
      * to be messy given how the code is written, so leave for now.
      *
      * This code needs refactoring since there are multiple
      * places with similar/the same code to access the ahelp
      * information.
      * -->
  <xsl:template name="add-section-title">
    <xsl:choose>
      <xsl:when test="@ahelpskip = '1' or not($is-current-release)">
	<h3><xsl:value-of select="@name"/></h3>
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="pagename"><xsl:choose>
	  <xsl:when test="boolean(@ahelpkey)"><xsl:value-of select="@ahelpkey"/></xsl:when>
	  <xsl:otherwise><xsl:value-of select="@name"/></xsl:otherwise>
	</xsl:choose></xsl:variable>
	
	<xsl:variable name="namematches" select="$ahelpindexfile//ahelp[key=$pagename]"/>
	<xsl:variable name="num" select="count($namematches)"/>
	
	<xsl:variable name="context"><xsl:choose>
	  <xsl:when test="boolean(@context)"><xsl:value-of select="@context"/></xsl:when>
	  <!-- special case when num=0 (ie ahelp is unknown) -->
	  <xsl:when test="$num=0 and $type!='live'">unknown</xsl:when>
	  <xsl:when test="$num=1"><xsl:value-of select="$namematches/context"/></xsl:when>
	  <xsl:otherwise>
	    <xsl:message terminate="yes">

 ERROR: have relnotes section for <xsl:value-of select="$pagename"/>
   that matches <xsl:value-of select="$num"/> contexts.
   You need to add a context attribute to distinguish between them.

	    </xsl:message>
	  </xsl:otherwise>
	</xsl:choose></xsl:variable>

	<xsl:variable name="matches" select="$namematches[context=$context]"/>
	<xsl:choose>
	  <xsl:when test="count($matches) = 0">
	    <xsl:choose>
	      <xsl:when test="$site = 'live'">
		<xsl:message terminate="yes">
 ERROR: release notes has a section for [ahelp]name=<xsl:value-of select="$pagename"/> but can
        find no matching ahelp file! Has it not been published yet?
		</xsl:message>
	      </xsl:when>
	      <xsl:otherwise>
		<h3><xsl:value-of select="concat('{*** will be ahelp link to ', @name, ' ***}')"/></h3>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:when>

	  <xsl:when test="count($matches) = 1">
	    <xsl:variable name="ahelpsite" select="$matches/site"/>
	    <xsl:variable name="hrefstart"><xsl:choose>
	      <xsl:when test="$site != $ahelpsite">
		<xsl:value-of select="concat('/',$ahelpsite,'/ahelp/')"/>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:call-template name="add-start-of-href">
		  <xsl:with-param name="extlink" select="0"/>
		  <xsl:with-param name="dirname" select="'ahelp/'"/>
	      </xsl:call-template></xsl:otherwise>
	    </xsl:choose></xsl:variable>


	    <h3><a class="helplink">
	      <xsl:if test="$matches/summary != ''">
		<xsl:attribute name="title">Ahelp (<xsl:value-of select="$context"/>): <xsl:value-of select="$matches/summary"/></xsl:attribute>
	      </xsl:if>
	      <xsl:attribute name="href"><xsl:value-of select="concat($hrefstart, $matches/page, '.html')"/></xsl:attribute>
	      <xsl:value-of select="@name"/>
	    </a></h3>
	  </xsl:when>

	  <xsl:otherwise>
	    <xsl:message terminate="yes">
 ERROR: tool release notes for [ahelp]name=<xsl:value-of select="$pagename"/> context=<xsl:value-of select="$context"/>
   matches multiple (<xsl:value-of select="$num"/>) ahelp files; see Doug
	    </xsl:message>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* name=add-section-title *-->

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
      *    @name (which should exist). The @context attribute is
      *    used for those pages with multiple contexts.
      *
      * Note: there is a lot of repeated code from links.xsl; needs
      *       refactoring.
      *-->
  <xsl:template match="section[@ahelpskip='1']" mode="ahelp-relnotes"/>

  <xsl:template match="section" mode="ahelp-relnotes">

    <xsl:variable name="pagename"><xsl:choose>
      <xsl:when test="boolean(@ahelpkey)"><xsl:value-of select="@ahelpkey"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="@name"/></xsl:otherwise>
    </xsl:choose></xsl:variable>
    <xsl:variable name="namematches" select="$ahelpindexfile//ahelp[key=$pagename]"/>
    <xsl:variable name="num" select="count($namematches)"/>

    <xsl:variable name="context"><xsl:choose>
      <xsl:when test="boolean(@context)"><xsl:value-of select="@context"/></xsl:when>

      <!-- special case when num=0 (ie ahelp is unknown) -->
      <xsl:when test="$num=0 and $type!='live'">unknown</xsl:when>
      
      <xsl:when test="$num=1"><xsl:value-of select="$namematches/context"/></xsl:when>
	
      <xsl:otherwise>
	<xsl:message terminate="yes">

 ERROR: have relnotes section for <xsl:value-of select="$pagename"/>
   that matches <xsl:value-of select="$num"/> contexts.
   You need to add a context attribute to distinguish between them.

	</xsl:message>
      </xsl:otherwise>
    </xsl:choose></xsl:variable>
    
    <xsl:variable name="matches" select="$namematches[context=$context]"/>
    <xsl:choose>
      <xsl:when test="count($matches) = 0">
	<xsl:choose>
	  <xsl:when test="$site = 'live'">
	    <xsl:message terminate="yes">
 ERROR: release notes has a section for [ahelp]name=<xsl:value-of select="$pagename"/> but can
        find no matching ahelp file! Has it not been published yet?
	    </xsl:message>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:message terminate="no">
 NOTE: release notes has a section for [ahelp]name=<xsl:value-of select="$pagename"/>
       that can not be found.
       This ahelp file must be published before this page will display on the live site!
	    </xsl:message>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>

      <xsl:when test="count($matches) = 1">
	<!--* 
	    * Use the $matches/page value to deal with pages like pget
	    * which have multiple contexts. The assumption is that $matches/page
	    * will be unique and match what ahelp code uses.
	    *-->
	<xsl:call-template name="write-relnotes-slug">
	  <xsl:with-param name="pagename" select="$matches/page"/>
	</xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:message terminate="yes">
 ERROR: tool release notes for [ahelp]name=<xsl:value-of select="$pagename"/> context=<xsl:value-of select="$context"/>
   matches multiple (<xsl:value-of select="$num"/>) ahelp files; see Doug
        </xsl:message>

      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* match=section, mode=ahelp-relnotes *-->

  <!--*
      * The slugs are written to
      *     .../releasenotes/ciao_$siteversion.$pagename.slug.xml
      *-->
  <xsl:template name="write-relnotes-slug">
    <xsl:param name="pagename" select="''"/>

    <xsl:if test="$pagename = ''">
      <xsl:message terminate="yes">
 ERROR: write-relnotes-slug called with empty pagename parameter!
      </xsl:message>
    </xsl:if>

    <!-- write the slug to the storage area -->
    <xsl:variable name="outloc" select="$storageInfo//dir[@site=$site]"/>

    <xsl:variable name="filename"
		  select="concat($outloc, 'releasenotes/ciao_', $siteversion, '.', $pagename, '.slug.xml')"/>
      
    <!--* output filename to stdout as used by publishing code *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>
    <xsl:variable name="should-not-be-a-function"
		  select="extfuncs:delete-file-if-exists($filename)"/>

    <xsl:document href="{$filename}" method="xml" encoding="UTF-8">
	
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

  </xsl:template> <!--* name=write-relnotes-slug *-->

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
