<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Convert an XML web page into an HTML one
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
    <xsl:apply-templates select="relnotes" mode="page"/>

    <xsl:if test="$site = 'ciao'">      
      <xsl:apply-templates select="//relnotes/text/category[@name='Tools']" mode="ahelp"/>
    </xsl:if>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: <relnotes>.html
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
	    
	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="name"  select="$pagename"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is added by the add-htmlhead template] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=relnotes, mode=page *-->


  <!-- create the includes for the ahelp webpages -->
  <xsl:template match="//relnotes/text/category[@name='Tools']" mode="ahelp">

    <xsl:for-each select="section">
		
      <xsl:variable name="filename"><xsl:value-of select="$install"/>ciao_<xsl:value-of select="$siteversion"/>.<xsl:value-of select="@name"/>.incl.html</xsl:variable>

      <!--* output filename to stdout *-->
      <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

      <xsl:document href="{$filename}" method="xml" encoding="utf-8">

	<!--* add disclaimer about editing this HTML file *-->
	<xsl:call-template name="add-disclaimer"/>

	<ul class="helplist">
	  <xsl:for-each select="note">
	    <li>
	      <xsl:apply-templates select="child::*|child::text()"/>
	    </li>
	  </xsl:for-each> <!-- select="note" -->
	</ul> 

      </xsl:document>
    </xsl:for-each>
  </xsl:template> <!--* match=relnotes, mode=ahelp *-->


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
