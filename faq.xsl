<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the FAQ HTML pages from one XML source file
    *
    * Recent changes:
    * 2008 May 30 DJB Removed generation of PDF version
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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

    <!--* check there's a navbar element *-->
    <xsl:if test="boolean(faq/info/navbar) = false()">
      <xsl:message terminate="yes">
  Error: the info block does not contain a navbar element.
      </xsl:message>
    </xsl:if>

    <!--*
        * If I take out the mode attributes here and in the
	* xsl:template nodes below then the output is not correct
	* since only some of the templates seem to get executed.
	* I do not understand why (could it be a libxml/libxslt
	* bug?)
	*-->
    <xsl:apply-templates select="faq" mode="why-this-mode"/>
    <xsl:apply-templates select="//faqentry"/>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: index.html
      *-->

  <xsl:template match="faq" mode="why-this-mode">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>index.html</xsl:variable>

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
	  <xsl:with-param name="name"  select="'index'"/>
	</xsl:call-template>
	<xsl:call-template name="newline"/>

	  <!--// main div begins page layout //-->
	    <div id="main">

		<!--* the main text *-->
		<div id="content">
		  <div class="wrap">


	      <!--* add the intro text *-->
	      <xsl:apply-templates select="intro"/>
	  
	      <!--* create the list of FAQ's *--> 
	      <xsl:apply-templates select="faqlist" mode="toc"/>
	    
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
	  <xsl:with-param name="name"  select="'index'"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is added by the add-htmlhead template] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=faq *-->

  <!--* 
      * create: individual faq page
      *-->

  <xsl:template match="faqentry">

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="@id"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">

      <!--* we start processing the XML file here *-->
      <html lang="en">

	<!--*
            * make the HTML head node
            *
            * note: need to supply the text for the page title
            *       since document title will be too long (in general)
            *
            *-->
	<xsl:call-template name="add-htmlhead">
	  <xsl:with-param name="title">FAQ Entry<xsl:if test="$texttitlepostfix!=''"><xsl:value-of select="concat(' - ',$texttitlepostfix)"/></xsl:if></xsl:with-param>
	</xsl:call-template>

	<!--* add disclaimer about editing this HTML file *-->
	<xsl:call-template name="add-disclaimer"/>

	<!--*
	    * make the header - it's different depending on whether this is
	    * a test version or the actual production HTML 
            *-->
	<xsl:call-template name="add-header">
	  <xsl:with-param name="name"  select="@id"/>
	</xsl:call-template>

	<div class="topbar">
	  <div class="qlinkbar">
	    Return to: <a href=".">FAQ index</a>
	  </div>
	</div>

	<div class="mainbar">

	  <!--* page title *-->
	  <div>
	    <h2 class="pagetitle"><xsl:apply-templates select="title"/><xsl:call-template name="add-new-or-updated-info"/></h2>
	    <xsl:apply-templates select="errmsg"/>
	  </div>
	  <hr/>

	  <!--* add the explanation *-->
	  <xsl:apply-templates select="text"/>
	  
	  <hr/>
	</div>

	<div class="bottombar">
	  <div class="qlinkbar">
	    Return to: <a href=".">FAQ index</a>
	  </div>
	</div>

	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="name"  select="@id"/>
	</xsl:call-template>
	
	<!--* add </body> tag [the <body> is added by the add-htmlhead template] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=faqentry *-->

  <!--*
      * Create the list of faq questions
      *
      *
      *-->
  <xsl:template match="faqlist" mode="toc">

    <!--* create the list of topics *-->
    <div class="navlinkbar qlinkbar">
    <xsl:for-each select="faqtopic">
       <xsl:if test="position() != 1"> | </xsl:if>
      <a href="#{@id}"><xsl:value-of select="name"/></a>
    </xsl:for-each>
    </div>
    <hr/>
    <br/>

    <!--* and now the list of entries *-->
    <xsl:for-each select="faqtopic">

      <!--* if not the first topic then add a hr *-->
      <xsl:if test="position() != 1">
	<hr class="midsep"/>
      </xsl:if>

      <!--* the header *-->
      <h2><a name="{@id}"><xsl:value-of select="name"/></a></h2>

      <!--* loop through the sections *-->
      <xsl:for-each select="faqsection">
	<h3><xsl:apply-templates select="name"/></h3>

	<!--* list through each entry *-->
	<ol type="1">
	  <xsl:for-each select="faqentry">
	    <li><a href="{@id}.html"><xsl:apply-templates select="title"/></a>
	    <xsl:call-template name="add-new-or-updated-info">
	      <xsl:with-param name="with-date" select="1"/>
	    </xsl:call-template>

	      <!--* do we need to add an error message? *-->
	      <xsl:apply-templates select="errmsg"/>
	    </li>
	  </xsl:for-each> <!--* faqentry *-->
	</ol>

      </xsl:for-each> <!--* faqsection *-->
      
    </xsl:for-each> <!--* faqtopic *-->

  </xsl:template> <!--* match=faqlist mode=toc *-->

  <!--* remove the 'whatever' tag and process the contents *-->
  <xsl:template match="intro|name|title|text">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * handle the errmsg tag
      *
      * - perhaps we should place the pre block within a
      *   div class="errmsg" block?
      *
      *-->
  <xsl:template match="errmsg">

    <xsl:call-template name="add-highlight-pre">
      <xsl:with-param name="contents"><xsl:apply-templates/></xsl:with-param>
    </xsl:call-template>

  </xsl:template>

  <!--*
      * adds a new or updated icon if the type attribute exists and
      * equals "new" or "updated" (we assume the curent context node
      * to be faqentry).
      * 
      * Also uses the day/month/year attributes
      * 
      * Note: 
      * 
      *-->
  <xsl:template name="add-new-or-updated-info">
    <xsl:param name="with-date" select="0"/>

    <xsl:choose>
      <xsl:when test="@type = 'new'">
	<xsl:call-template name="add-nbsp"/>
	<xsl:call-template name="add-new-image"/>
	<xsl:if test="boolean($with-date) and boolean(@day)"><xsl:call-template name="add-date"/></xsl:if>
      </xsl:when>
      <xsl:when test="@type = 'updated'">
	<xsl:call-template name="add-nbsp"/>
	<xsl:call-template name="add-updated-image"/>
	<xsl:if test="boolean($with-date) and boolean(@day)"><xsl:call-template name="add-date"/></xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template> <!--* name=add-new-or-updated-info *-->

</xsl:stylesheet>
