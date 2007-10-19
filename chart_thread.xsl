<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the HTML version of the ChaRT thread
    *
    * Recent changes:
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *  v1.15 - <html> changed to <html lang="en"> following
    *            http://www.w3.org/TR/2005/WD-i18n-html-tech-lang-20050224/
    *  v1.14 - Big change for CIAO 3.1: moved chart_thread_hard.xsl
    *          into this stylesheet - see v1.23/1.24 of ciao_thread.xsl
    *  v1.13 - added an anchor for the 'skip nav. bar' link
    *  v1.12 - imglinkicon[width/height] parameters now define icon for
    *          imglink tag (so user can change them via config file)
    *  v1.11 - fixes to HTML plus more table-related changes (add-header/footer)
    *          imglink now uses a single a tag with name and href attributes
    *  v1.10 - added newsfile/newsfileurl parameters + use of globalparams_thread.xsl
    *   v1.9 - use of tables for the main text has changed.
    *   v1.8 - call add-header/footer so that the PDF links are created correctly
    *   v1.7 - change format for CIAO 3.0; added cssfile parameter
    *          allow year attribute > 2000
    *   v1.6 - ahelpindex (CIAO 3.0)
    *   v1.5 - commented out threadVersion variable
    *   v1.4 - re-introduced the external parameter updateby
    *   v1.3 - cleaned up (moved image-generation to thread_common.xsl)
    *   v1.2 - initial version for ChaRT
    *   v1.1 - copy of v1.5 of the CIAO thread stylesheet
    *
    * To do:
    *
    * Parameters:
    *   imglinkicon, string, required
    *     location of the image, relative to the top-level for this site,
    *     for the image to use at the end of "image" links
    *     e.g. imgs/imageicon.gif
    *
    *   imglinkiconwidth, integer, required
    *     width of imglinkicon in pixels
    *
    *   imglinkiconheight, integer, required
    *     height of imglinkicon in pixels
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--* we create the HTML files using xsl:document statements *-->
  <xsl:output method="text"/>

  <!--* load in the set of "global" parameters *-->
  <xsl:include href="globalparams_thread.xsl"/>

  <!--* include the stylesheets *-->
  <xsl:include href="thread_common.xsl"/>
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <!--*
      * NOTE:
      *   currently the default values for these parameters are set
      *   by the calling process, which in this case is publish.pl
      *-->
  <xsl:param name="imglinkicon" select='""'/>
  <xsl:param name="imglinkiconwidth" select='0'/>
  <xsl:param name="imglinkiconheight" select='0'/>

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
    <xsl:if test="substring($install,string-length($install))!='/'">
      <xsl:message terminate="yes">
  Error: install parameter must end in a / character.
    install=<xsl:value-of select="$install"/>
      </xsl:message>
    </xsl:if>

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
	    </xsl:choose> - ChaRT</xsl:with-param>
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

	    <h2><strong>ChaRT Threads</strong></h2>

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
	  <div align="center"><strong>ChaRT Threads</strong></div>

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
	  </xsl:choose> - ChaRT</xsl:with-param>
      </xsl:call-template>
      
      <!--* add disclaimer about editing the HTML file *-->
      <xsl:call-template name="add-disclaimer"/>
      
      <!--* make the header *-->
      <xsl:call-template name="add-header">
	<xsl:with-param name="name"  select="//thread/info/name"/>
      </xsl:call-template>

      <!--* set up the standard links before the page starts *-->
      <xsl:call-template name="add-top-links-chart-html">
	<xsl:with-param name="name" select="$threadName"/>
      </xsl:call-template>

      <div class="mainbar">

	<!--* let the 'skip nav bar' have somewhere to skip to *-->
	<a name="maintext"/>

	<!--* set up the title block of the page *-->
	<div align="center"><h1><xsl:value-of select="$threadInfo/title/long"/></h1></div>
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
      <xsl:call-template name="add-bottom-links-chart-html">
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
