<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the HTML version of the CIAO thread
    *
    * Recent changes:
    * 2007 Oct 29 DJB
    *    start work on supporting proglang (=sl or py)
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *  v1.27 - add version under thread title
    *  v1.26 - <html> changed to <html lang="en"> following
    *            http://www.w3.org/TR/2005/WD-i18n-html-tech-lang-20050224/
    *  v1.25 - moved add-new-page to thread_common.xsl
    *  v1.24 - moved imglink to thread_common.xsl
    *  v1.23 - Big change for CIAO 3.1: moved ciao_thread_hard.xsl
    *          into this stylesheet and made the templates aware of
    *          the 'global' hardcopy variable
    *  v1.22 - added an anchor for the 'skip nav. bar' link
    *  v1.21 - imglinkicon[width/height] parameters now define icon for
    *          imglink tag (so user can change them via config file)
    *  v1.20 - updated to handle head/texttitlepostfix
    *  v1.19 - fixes to HTML plus more table-related changes (add-header/footer)
    *          imglink now uses a single a tag with name and href attributes
    *  v1.18 - added newsfile/newsfileurl parameters + use of globalparams_thread.xsl
    *  v1.17 - use of tables for the main text has changed.
    *  v1.16 - call add-header/footer so that the PDF links are created correctly
    *  v1.15 - change format for CIAO 3.0; added cssfile parameter
    *  v1.14 - @year can now handle values > 2000 sensibly; changes to layout
    *  v1.13 - ahelpindex (CIAO 3.0)
    *  v1.12 - added support for siteversion parameter
    *  v1.11 - threadDir is now set by the processor, not by the stylesheet
    *  v1.10 - re-introduced the external parameter updateby
    *   v1.9 - added pagename parameter, imglink can now be called from include files
    *   v1.8 - cleaned up (image generation code moved to thread_common.xsl)
    *   v1.7 - fixes to recent change in helper.xsl (add-last-modified)
    *   v1.6 - use thread_common.xsl rather than ciao_thread_common.xsl
    *   v1.5 - moved templates into ciao_thread_common.xsl and ciao_thread_hard.xsl
    *   v1.4 - added imglink template (from links.xsl), have a hacky way to link to id
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
      * top level
      * if proglang == '' then create
      *   index.html                - hardcopy != 1
      *   img<n>.html               - hardcopy != 1
      *   $install/index.hard.html  - hardcopy = 1
      * else create
      *   index.<proglang>.html                - hardcopy != 1
      *   img<n>.<proglang>.html               - hardcopy != 1
      *   $install/index.hard.<proglang>.html  - hardcopy = 1
      *   in this case no index.html case is created (heardcopy != 1)
      *
      *-->

  <xsl:template match="/">

    <!--* check the params are okay *-->
    <xsl:call-template name="is-site-valid"/>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname" select="'install'"/>
      <xsl:with-param name="pvalue" select="$install"/>
    </xsl:call-template>
    <xsl:call-template name="is-proglang-valid"/>

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
      * create:
      *    $install/index.hard.html
      * or
      *    $install/index.hard.<proglang>.html
      *-->
  <xsl:template match="thread" mode="html-hardcopy">

    <xsl:variable name="langid"><xsl:choose>
      <xsl:when test="$proglang=''"/>
      <xsl:otherwise><xsl:value-of select="concat('.',$proglang)"/></xsl:otherwise>
    </xsl:choose></xsl:variable>

    <xsl:variable name="filename"
		  select="concat($install,'index',$langid,'hard.html')"/>

    <xsl:variable name="urlfrag">
      <xsl:value-of select="concat('threads/',$threadName,'/')"/>
      <xsl:if test="$proglang != ''">
	<xsl:value-of select="concat('index',$langid,'.html')"/>
      </xsl:if>
    </xsl:variable>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <!--* get the start of the document over with *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-site-thread"/>

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

	    <h2><strong>CIAO <xsl:value-of select="$siteversion"/> Science Threads</strong></h2>
	    <xsl:call-template name="add-proglang-sub-header"/>

	  </div>
	  <xsl:call-template name="add-new-page"/>

	  <!--* table of contents page *-->
	  <xsl:call-template name="add-toc">
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>

	  <xsl:call-template name="add-new-page"/>

	  <!--* start the thread *-->

	  <!--* Make the header. *-->
	  <xsl:call-template name="add-id-hardcopy">
	    <xsl:with-param name="urlfrag" select="$urlfrag"/>
	    <xsl:with-param name="lastmod" select="$lastmodified"/>
	  </xsl:call-template>
	  <xsl:call-template name="add-hr-strong"/>
	  <br/>

	  <!--* set up the title block of the page *-->
	  <xsl:call-template name="add-threadtitle-main-hard"/>

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
w
	  <!-- History -->
	  <xsl:apply-templates select="info/history"/>

	  <!--* add the footer text *-->
	  <br/>
	  <xsl:call-template name="add-hr-strong"/>
	  <xsl:call-template name="add-id-hardcopy">
	    <xsl:with-param name="urlfrag" select="$urlfrag"/>
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
      * create:
      *    $install/index.html
      * or
      *    $install/index.<proglang>.html
      *-->
  <xsl:template match="thread" mode="html-viewable">
    
    <xsl:variable name="langid"><xsl:choose>
      <xsl:when test="$proglang=''"/>
      <xsl:otherwise><xsl:value-of select="concat('.',$proglang)"/></xsl:otherwise>
    </xsl:choose></xsl:variable>

    <xsl:variable name="filename"
		  select="concat($install,'index',$langid,'.html')"/>

    <xsl:variable name="hardcopyName" select="concat(//thread/info/name,$langid)"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <!--* get the start of the document over with *-->
      <xsl:call-template name="add-start-html"/>

      <!--* make the HTML head node *-->
      <xsl:call-template name="add-htmlhead-site-thread"/>
      
      <!--* add disclaimer about editing the HTML file *-->
      <xsl:call-template name="add-disclaimer"/>
      
      <!--* make the header *-->
      <xsl:call-template name="add-header">
	<xsl:with-param name="name"  select="$hardcopyName"/>
      </xsl:call-template>

      <!--* set up the standard links before the page starts *-->
      <xsl:call-template name="add-top-links-ciao-html">
	<xsl:with-param name="name" select="$threadName"/>
      </xsl:call-template>

      <div class="mainbar">

	<!--* let the 'skip nav bar' have somewhere to skip to *-->
	<a name="maintext"/>

	<!--* set up the title block of the page *-->
	<xsl:call-template name="add-thread-title"/>

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

	<!--* set up the trailing links to threads/harcdopy *-->
	<xsl:call-template name="add-hr-strong"/>

      </div> <!--* calss=mainbar *-->

      <!--* set up the trailing links to threads/harcdopy *-->
      <xsl:call-template name="add-bottom-links-html">
	<xsl:with-param name="name" select="$threadName"/>
      </xsl:call-template>

      <!--* add the footer text *-->
      <xsl:call-template name="add-footer">
	<xsl:with-param name="name"  select="$hardcopyName"/>
      </xsl:call-template>

      <!--* add </body> tag [the <body> is included in a SSI] *-->
      <xsl:call-template name="add-end-body"/>
      <xsl:call-template name="add-end-html"/>

    </xsl:document>

  </xsl:template> <!--* match=thread mode=html-viewable *-->

</xsl:stylesheet>
