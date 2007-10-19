<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Convert an XML web page into an HTML one
    *
    * Recent changes:
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *  v1.22 - <html> changed to <html lang="en"> following
    *            http://www.w3.org/TR/2005/WD-i18n-html-tech-lang-20050224/
    *  v1.21 - We are no called with hardopy=0 or 1 and this determines
    *          the type of the file created (CIAO 3.1)
    *  v1.20 - HTML title created from page title + titlepostfix parameter
    *          (ie no-longer hard-coded to " - CIAO $version"
    *  v1.19 - added maintext anchor
    *  v1.18 - removing tables from header/footer
    *  v1.17 - added newsfile/newsfileurl parameters + use of globalparams.xsl
    *  v1.16 - added navbarlink parameter (although it isn't used at the moment)
    *  v1.15 - now have a single table for page structure (at least CIAO part)
    *          added cssfile parameter
    *  v1.14 - added ahelpindex command-line parameter
    *  v1.13 - removed xsl-revision/version as pointless
    *  v1.12 - added support for siteversion parameter
    *  v1.11 - added support for site=icxc
    *  v1.10 - re-introduced the external parameter updateby
    *   v1.9 - removed comments for updatetime/by parameters
    *   v1.8 - minor clean up on 1.7
    *   v1.7 - use add-standard-banner (for header/footer)
    *   v1.6 - now also creates 'hardcopy' version (name.hard.html)
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="exsl">

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

    <!--* what do we create *-->
    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<xsl:if test="$site = 'icxc'">
	  <xsl:message terminate="yes">
PROGRAMMING ERROR: site=icxc and hardcopy=1
	  </xsl:message>
	</xsl:if>
	<xsl:apply-templates name="page" mode="make-hardcopy"/>
      </xsl:when>
      
      <xsl:otherwise>
	<xsl:apply-templates name="page" mode="make-viewable"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: <page>.html
      *-->

  <xsl:template match="page" mode="make-viewable">

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$pagename"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">

      <!--* we start processing the XML file here *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-standard"/>

	<!--* add disclaimer about editing this HTML file *-->
	<xsl:call-template name="add-disclaimer"/>

	<!--* make the header - it's different depending on whether this is
	    * a test version or the actual production HTML 
            *-->
	<xsl:call-template name="add-header">
	  <xsl:with-param name="name" select="$pagename"/>
	</xsl:call-template>

	<xsl:choose>
	  <xsl:when test="boolean(info/navbar)">
	    <!--* use a table to provide the page layout *-->
	    <table class="maintable" width="100%" border="0" cellspacing="2" cellpadding="2">
	      <tr>
		<xsl:call-template name="add-navbar">
		  <xsl:with-param name="name" select="info/navbar"/>
		</xsl:call-template>
		<td class="mainbar" valign="top">
		  <!--* the main text *-->
		  <a name="maintext"/>
		  <xsl:apply-templates select="text"/>
		</td>
	      </tr>
	    </table>
	  </xsl:when>
	  <xsl:otherwise>
	    <!--* the main text *-->
	    <div class="mainbar">
	      <a name="maintext"/>
	      <xsl:apply-templates select="text"/>
	    </div>
	  </xsl:otherwise>
	</xsl:choose>
	    
	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="name"  select="$pagename"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=page mode=make-viewable *-->

  <!--* 
      * create: <page>.hard.html
      *-->

  <xsl:template match="page" mode="make-hardcopy">

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$pagename"/>.hard.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">

      <!--* we start processing the XML file here *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-standard"/>

	<!--* and now the main part of the text *-->
	<body>

	  <xsl:call-template name="add-hardcopy-banner-top">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	  <!--* do not need to bother with navbar's here as the hardcopy version *-->
	  <xsl:apply-templates select="text"/>
      
	  <xsl:call-template name="add-hardcopy-banner-bottom">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	</body>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=page mode=make-hardcopy *-->

  <!--* note: we process the text so we can handle our `helper' tags *-->
  <xsl:template match="text">
   <xsl:apply-templates/>
  </xsl:template> <!--* text *-->

</xsl:stylesheet>
