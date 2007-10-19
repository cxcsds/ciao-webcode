<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the FAQ HTML pages from one XML source file
    *
    * Recent changes:
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *  v1.18 - don't center-align errmsg tag; qlinkbar class added on index
    *  v1.17 - hyphen added to (head/text)titlepostfix instances
    *  v1.16 - <html> changed to <html lang="en"> following
    *            http://www.w3.org/TR/2005/WD-i18n-html-tech-lang-20050224/
    *  v1.15 - added support for the type/day/month/year attributes on faqentry tags
    *  v1.14 - improve layout of the index page (less lists, use headers and
    *          div's instead)
    *  v1.13 - use CSS for highlighting (better handling of errmsg tag)
    *  v1.12 - We are now called with hardopy=0 or 1 and this determines
    *          the type of the file created (CIAO 3.1)
    *  v1.11 - support for head/texttitlepostfix parameters
    *  v1.10 - added maintext anchor
    *   v1.9 - removing tables from header/footer
    *   v1.8 - added newsfile/newsfileurl parameters + use of globalparams.xsl
    *   v1.7 - re-organisation of layout for CIAO 3.0
    *          added cssfile parameter
    *   v1.6 - ahelpindex support for CIAO 3.0
    *   v1.5 - added support for siteversion parameter
    *   v1.4 - fixed pdf links (now to corrct version, not the index)
    *   v1.3 - introduced the external parameter updateby
    *   v1.2 - initial version
    *   v1.1 - copy of v1.8 of page.xsl
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

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<!--* hardcopy *-->
	<xsl:apply-templates select="faq" mode="make-hardcopy"/>
	<xsl:apply-templates select="//faqentry" mode="make-hardcopy"/>
      </xsl:when>

      <xsl:otherwise>
	<!--* softcopy *-->
	<xsl:apply-templates select="faq" mode="make-viewable"/>
	<xsl:apply-templates select="//faqentry" mode="make-viewable"/>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: index.html
      *-->

  <xsl:template match="faq" mode="make-viewable">

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

	<!--* use a table to provide the page layout *-->
	<table class="maintable" width="100%" border="0" cellspacing="2" cellpadding="2">
	  <tr>
	    <!--* add the navbar *-->
	    <xsl:call-template name="add-navbar">
	      <xsl:with-param name="name" select="info/navbar"/>
	    </xsl:call-template>

	    <!--* the main text *-->
	    <td class="mainbar" valign="top">

	      <a name="maintext"/>

	      <!--* add the intro text *-->
	      <xsl:apply-templates select="intro"/>
	  
	      <!--* create the list of FAQ's *--> 
	      <xsl:apply-templates select="faqlist" mode="toc"/>
	    
	    </td>
	  </tr>
	</table>
      
	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="name"  select="'index'"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=faq mode=make-viewable *-->

  <!--* 
      * create: index.hard.html
      *-->

  <xsl:template match="faq" mode="make-hardcopy">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>index.hard.html</xsl:variable>
    <xsl:variable name="url"><xsl:value-of select="$urlhead"/></xsl:variable>

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

	  <!--* add the intro text *-->
	  <xsl:apply-templates select="intro"/>
	      
	  <!--* create the list of FAQ's *--> 
	  <xsl:apply-templates select="faqlist" mode="toc"/>

	  <xsl:call-template name="add-hardcopy-banner-bottom">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	</body>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=faq mode=make-hardcopy *-->

  <!--* 
      * create: individual faq page (viewable)
      *-->

  <xsl:template match="faqentry" mode="make-viewable">

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

	  <a name="maintext"/>

	  <!--* page title *-->
	  <div>
	    <h2 align="center"><xsl:apply-templates select="title"/><xsl:call-template name="add-new-or-updated-info"/></h2>
	    <xsl:apply-templates select="errmsg"/>
	  </div>
	  <hr/>

	  <!--* add the explanation *-->
	  <xsl:apply-templates select="text"/>
	  
	  <br/><hr/>
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
	
	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=faqentry mode=make-viewable *-->

  <!--* 
      * create: individual faq page (hardcopy)
      *-->

  <xsl:template match="faqentry" mode="make-hardcopy">

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="@id"/>.hard.html</xsl:variable>
    <xsl:variable name="url"><xsl:value-of select="$urlhead"/><xsl:value-of select="@id"/>.html</xsl:variable>

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

	<!--* and now the main part of the text *-->
	<body>

	  <xsl:call-template name="add-hardcopy-banner-top">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	  <!--* page title (and link back to index) *-->
	  <div>
	    <h2 align="center"><xsl:apply-templates select="title"/><xsl:call-template name="add-new-or-updated-info"/></h2>

	    <xsl:apply-templates select="errmsg"/>
	  </div>
	  <br/>
	  <!--* note: no 'link to index' link for the hardcopy *-->
	  <hr/><br/>

	  <!--* add the explanation *-->
	  <xsl:apply-templates select="text"/>
	      
	  <xsl:call-template name="add-hardcopy-banner-bottom">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	</body>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=faqentry mode=make-hardcopy *-->

  <!--*
      * Create the list of faq questions
      *
      *
      *-->
  <xsl:template match="faqlist" mode="toc">

    <!--* create the list of topics *-->
    <div align="center" class="qlinkbar">
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
	<br/>
	<hr width="80%" align="center"/>
	<br/>
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
