<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the HTML version of the ChIPS thread
    *
    * Recent changes:
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *   v1.3 - added syntax line under thread title
    *   v1.2 - changed "Sherpa" to "ChIPS"
    *   v1.1 - copy of v1.12 of the Sherpa thread stylesheet
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--* we create the HTML files using xsl:document statements *-->
  <xsl:output method="text"/>

  <!--* load in the set of "global" parameters *-->
  <xsl:include href="globalparams_thread.xsl"/>

  <!--*
      * NOTE:
      *   currently the default values for these parameters are set
      *   by the calling process, which in this case is publish.pl
      *-->
  <xsl:param name="imglinkicon" select='""'/>
  <xsl:param name="imglinkiconwidth" select='0'/>
  <xsl:param name="imglinkiconheight" select='0'/>

  <!--* include the stylesheets *-->
  <xsl:include href="thread_common.xsl"/>
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <!--* really need to sort out the newline template issue *-->
  <xsl:template name="newline">
<xsl:text> 
</xsl:text>
  </xsl:template>

  <!--* 
      * top level - create:
      *   index.html                - hardcopy != 1
      *   img<n>.html               - hardcopy != 1
      *   $install/index.hard.html  - hardcopy = 1
      *
      *-->

  <xsl:template match="/">

    <!--* check the params are okay *-->
    <xsl:call-template name="is-site-valid"/>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'install'"/>
      <xsl:with-param name="pvalue" select="$install"/>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<xsl:apply-templates select="thread" mode="html-hardcopy"/>
      </xsl:when>

      <xsl:otherwise>
	<xsl:apply-templates select="thread" mode="html-viewable"/>
	<xsl:apply-templates select="thread/images/image" mode="list"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!-- match="/" *-->

  <!--*
      * create: $install/index.hard.html
      *-->
  <xsl:template match="thread" mode="html-hardcopy">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>index.hard.html</xsl:variable>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <!--* get the start of the document over with *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead">
	  <xsl:with-param name="title"><xsl:choose>
	      <xsl:when test="boolean($threadInfo/title/short)"><xsl:value-of select="$threadInfo/title/short"/></xsl:when>
	      <xsl:otherwise><xsl:value-of select="$threadInfo/title/long"/></xsl:otherwise>
	    </xsl:choose> - ChIPS</xsl:with-param>
	</xsl:call-template>

	<!--* and now the main part of the text *-->
	<body>

	  <!--* set up the title page *-->
	  <div align="center">

	    <h1><xsl:value-of select="$threadInfo/title/long"/></h1>

	    <!--*
	        * just add the logo directly
	        * don't use any templates, since this is a bit of a fudge
                *-->
	    <img src="../../imgs/cxc-logo.gif" alt="[CXC Logo]"/>

	    <h2>ChIPS Threads (CIAO <xsl:value-of select="$siteversion"/>)</h2>

	  </div>
	  <xsl:call-template name="add-new-page"/>

	  <!--* table of contents page *-->
	  <xsl:call-template name="add-toc">
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>

	  <xsl:call-template name="add-new-page"/>

	  <!--* start the thread *-->

	  <!--* make the header *-->
	  <xsl:call-template name="add-id-hardcopy">
	    <xsl:with-param name="urlfrag" select="concat('threads/',$threadName,'/')"/>
	    <xsl:with-param name="lastmod" select="$lastmodified"/>
	  </xsl:call-template>
	  <xsl:call-template name="add-hr-strong"/>
	  <br/>

	  <!--* set up the title block of the page *-->
	  <h1 align="center"><xsl:value-of select="$threadInfo/title/long"/></h1>
	  <div align="center"><strong>ChIPS Threads</strong></div>

	  <!--* Introductory text *-->
	  <xsl:call-template name="add-introduction">
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>

	  <!--* Main thread *-->
	  <xsl:apply-templates select="text/sectionlist"/>
	
	  <!--* Summary text *-->
	  <xsl:call-template name="add-summary">
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>
	
	  <!--* Parameter files *-->
	  <xsl:call-template name="add-parameters"/>

	  <!-- History -->
	  <xsl:apply-templates select="info/history"/>

	  <!--* add the footer text *-->
	  <br/>
	  <xsl:call-template name="add-hr-strong"/>
	  <xsl:call-template name="add-id-hardcopy">
	    <xsl:with-param name="urlfrag" select="concat('threads/',$threadName,'/')"/>
	    <xsl:with-param name="lastmod" select="$lastmodified"/>
	  </xsl:call-template>

	  <!--* add the images *-->
	  <xsl:for-each select="images/image">

	    <!--* based on template match="image" mode="list" *-->
	    <xsl:variable name="pos" select="position()"/>
	    <xsl:variable name="imgname" select='concat("Image ",$pos)'/>

	    <!--* add a new page *-->
	    <xsl:call-template name="add-new-page"/>
	    <h3><a name="img-{@id}"><xsl:value-of select="$imgname"/>: <xsl:value-of select="title"/></a></h3>

	    <!--* "pre-image" text *-->
	    <xsl:if test="boolean(before)">
	      <xsl:apply-templates select="before"/>
	    </xsl:if>

	    <!--* image:
                *   would like to use the PS version if available
                *   BUT htmldoc doesn't support this
                *-->
	    <img alt="[{$imgname}]" src="{@src}"/>
		
	    <!--* "post-image" text *-->
	    <xsl:if test="boolean(after)">
	      <xsl:apply-templates select="after"/>
	    </xsl:if>

	  </xsl:for-each>
	  
	</body>
      </html>

    </xsl:document>

  </xsl:template> <!--* match=thread mode=html-hardcopy *-->

  <!--*
      * create: $install/index.html
      *-->
  <xsl:template match="thread" mode="html-viewable">
    
    <xsl:variable name="filename"><xsl:value-of select="$install"/>index.html</xsl:variable>
    
    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <!--* get the start of the document over with *-->
      <xsl:call-template name="add-start-html"/>

      <!--* make the HTML head node *-->
      <xsl:call-template name="add-htmlhead">
	<xsl:with-param name="title"><xsl:choose>
	    <xsl:when test="boolean($threadInfo/title/short)"><xsl:value-of select="$threadInfo/title/short"/></xsl:when>
	    <xsl:otherwise><xsl:value-of select="$threadInfo/title/long"/></xsl:otherwise>
	  </xsl:choose> - ChIPS</xsl:with-param>
      </xsl:call-template>
      
      <!--* add disclaimer about editing the HTML file *-->
      <xsl:call-template name="add-disclaimer"/>
      
      <!--* make the header *-->
      <xsl:call-template name="add-header">
	<xsl:with-param name="name"  select="//thread/info/name"/>
      </xsl:call-template>

      <!--* set up the standard links before the page starts *-->
      <xsl:call-template name="add-top-links-chips-html">
	<xsl:with-param name="name" select="$threadName"/>
      </xsl:call-template>

      <div class="mainbar">

	<!--* let the 'skip nav bar' have somewhere to skip to *-->
	<a name="maintext"/>

	<!--* set up the title block of the page *-->
	<div align="center">
	  <h1><xsl:value-of select="$threadInfo/title/long"/></h1>

	  <xsl:if test="$threadInfo/syntax = 'py'">
	    <h3>[Python Syntax]</h3>
	  </xsl:if>
	  <xsl:if test="$threadInfo/syntax = 'sl'">
	    <h3>[S-Lang Syntax]</h3>
	  </xsl:if>
	</div>

	<xsl:call-template name="add-hr-strong"/>

	<!--* Introductory text *-->
	<xsl:call-template name="add-introduction"/>

	<!--* table of contents *-->
	<xsl:call-template name="add-toc"/>

	<!--* Main thread *-->
	<xsl:apply-templates select="text/sectionlist"/>
	
	<!--* Summary text *-->
	<xsl:call-template name="add-summary"/>
	
	<!--* Parameter files *-->
	<xsl:call-template name="add-parameters"/>

	<!-- History -->
	<xsl:apply-templates select="info/history"/>

	<xsl:call-template name="add-hr-strong"/>

      </div> <!--* class=mainbar *-->

      <!--* set up the trailing links to threads/harcdopy *-->
      <xsl:call-template name="add-bottom-links-chips-html">
	<xsl:with-param name="name" select="$threadName"/>
      </xsl:call-template>

      <!--* add the footer text *-->
      <xsl:call-template name="add-footer">
	<xsl:with-param name="name"  select="//thread/info/name"/>
      </xsl:call-template>

      <!--* add </body> tag [the <body> is included in a SSI] *-->
      <xsl:call-template name="add-end-body"/>
      <xsl:call-template name="add-end-html"/>

    </xsl:document>

  </xsl:template> <!--* match=thread mode=html-viewable *-->

</xsl:stylesheet>
