<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the HTML version of the ChaRT thread
    *
    * Recent changes:
    * 2007 Oct 30 DJB
    *    start work on supporting proglang (=sl or py)
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

  <!--* for general comments see ciao_thread.xsl *-->
  <xsl:output method="text"/>

  <xsl:include href="globalparams_thread.xsl"/>

  <xsl:include href="thread_common.xsl"/>
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <xsl:param name="imglinkicon" select='""'/>
  <xsl:param name="imglinkiconwidth" select='0'/>
  <xsl:param name="imglinkiconheight" select='0'/>

  <xsl:template name="newline">
<xsl:text> 
</xsl:text>
  </xsl:template>

  <xsl:template match="/">

    <!--* check the params are okay *-->
    <xsl:call-template name="is-site-valid"/>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'install'"/>
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

  <xsl:template match="thread" mode="html-hardcopy">

    <xsl:variable name="langid"><xsl:choose>
      <xsl:when test="$proglang=''"/>
      <xsl:otherwise><xsl:value-of select="concat('.',$proglang)"/></xsl:otherwise>
    </xsl:choose></xsl:variable>

    <xsl:variable name="filename"
		  select="concat($install,'index',$langid,'.hard.html')"/>

    <xsl:variable name="urlfrag">
      <xsl:value-of select="concat('threads/',$threadName,'/')"/>
      <xsl:if test="$proglang != ''">
	<xsl:value-of select="concat('index',$langid,'.html')"/>
      </xsl:if>
    </xsl:variable>

    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <html lang="en">

	<xsl:call-template name="add-htmlhead-site-thread"/>

	<body>

	  <div align="center">

	    <h1><xsl:value-of select="$threadInfo/title/long"/></h1>

	    <!--*
	        * just add the logo directly
	        * don't use any templates, since this is a bit of a fudge
                *-->
	    <img src="../../imgs/cxc-logo.gif" alt="[CXC Logo]"/>

	    <h2><strong>ChaRT Threads</strong></h2>
	    <xsl:call-template name="add-proglang-sub-header"/>

	  </div>
	  <xsl:call-template name="add-new-page"/>

	  <xsl:call-template name="add-toc">
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>

	  <xsl:call-template name="add-new-page"/>

	  <xsl:call-template name="add-id-hardcopy">
	    <xsl:with-param name="urlfrag" select="$urlfrag"/>
	    <xsl:with-param name="lastmod" select="$lastmodified"/>
	  </xsl:call-template>
	  <xsl:call-template name="add-hr-strong"/>
	  <br/>

	  <xsl:call-template name="add-threadtitle-main-hard"/>

	  <xsl:call-template name="add-introduction">
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>

	  <xsl:apply-templates select="text/sectionlist"/>
	
	  <xsl:call-template name="add-summary">
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>
	
	  <xsl:call-template name="add-parameters"/>

	  <xsl:apply-templates select="info/history"/>

	  <br/>
	  <xsl:call-template name="add-hr-strong"/>
	  <xsl:call-template name="add-id-hardcopy">
	    <xsl:with-param name="urlfrag" select="$urlfrag"/>
	    <xsl:with-param name="lastmod" select="$lastmodified"/>
	  </xsl:call-template>

	  <xsl:for-each select="images/image">

	    <xsl:variable name="pos" select="position()"/>
	    <xsl:variable name="imgname" select='concat("Image ",$pos)'/>

	    <xsl:call-template name="add-new-page"/>
	    <h3><a name="img-{@id}"><xsl:value-of select="$imgname"/>: <xsl:value-of select="title"/></a></h3>

	    <xsl:if test="boolean(before)">
	      <xsl:apply-templates select="before"/>
	    </xsl:if>

	    <img alt="[{$imgname}]" src="{@src}"/>
		
	    <xsl:if test="boolean(after)">
	      <xsl:apply-templates select="after"/>
	    </xsl:if>

	  </xsl:for-each>
	  
	</body>
      </html>

    </xsl:document>

  </xsl:template> <!--* match=thread mode=html-hardcopy *-->

  <xsl:template match="thread" mode="html-viewable">
    
    <xsl:variable name="langid"><xsl:choose>
      <xsl:when test="$proglang=''"/>
      <xsl:otherwise><xsl:value-of select="concat('.',$proglang)"/></xsl:otherwise>
    </xsl:choose></xsl:variable>

    <xsl:variable name="filename"
		  select="concat($install,'index',$langid,'.html')"/>

    <xsl:variable name="hardcopyName" select="concat(//thread/info/name,$langid)"/>

    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <xsl:call-template name="add-start-html"/>

      <xsl:call-template name="add-htmlhead-site-thread"/>
      
      <xsl:call-template name="add-disclaimer"/>
      
      <xsl:call-template name="add-header">
	<xsl:with-param name="name"  select="$hardcopyName"/>
      </xsl:call-template>

      <xsl:call-template name="add-top-links-chart-html">
	<xsl:with-param name="name" select="$threadName"/>
      </xsl:call-template>

      <div class="mainbar">

	<a name="maintext"/>

	<xsl:call-template name="add-thread-title"/>

	<xsl:call-template name="add-introduction"/>

	<xsl:call-template name="add-toc"/>

	<xsl:apply-templates select="text/sectionlist"/>
	
	<xsl:call-template name="add-summary"/>
	
	<xsl:call-template name="add-parameters"/>

	<xsl:apply-templates select="info/history"/>

	<xsl:call-template name="add-hr-strong"/>

      </div> <!--* class=mainbar *-->

      <xsl:call-template name="add-bottom-links-chart-html">
	<xsl:with-param name="name" select="$threadName"/>
      </xsl:call-template>

      <xsl:call-template name="add-footer">
	<xsl:with-param name="name"  select="$hardcopyName"/>
      </xsl:call-template>

      <xsl:call-template name="add-end-body"/>
      <xsl:call-template name="add-end-html"/>

    </xsl:document>

  </xsl:template> <!--* match=thread mode=html-viewable *-->

</xsl:stylesheet>
