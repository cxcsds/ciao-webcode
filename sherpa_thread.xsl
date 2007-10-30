<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the HTML version of the Sherpa thread
    *
    * Recent changes:
    * 2007 Oct 30 DJB
    *    start work on supporting proglang (=sl or py)
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *  v1.12 - <html> changed to <html lang="en"> following
    *            http://www.w3.org/TR/2005/WD-i18n-html-tech-lang-20050224/
    *  v1.11 - Big change for CIAO 3.1: moved sherpa_thread_hard.xsl
    *          into this stylesheet - see v1.23/1.24 of ciao_thread.xsl
    *  v1.10 - added an anchor for the 'skip nav. bar' link
    *   v1.9 - imglinkicon[width/height] parameters now define icon for
    *          imglink tag (so user can change them via config file)
    *   v1.8 - fixes to HTML plus more table-related changes (add-header/footer)
    *          imglink now uses a single a tag with name and href attributes
    *   v1.7 - added newsfile/newsfileurl parameters + use of globalparams_thread.xsl
    *   v1.6 - use of tables for the main text has changed.
    *   v1.5 - oops: need to do to add-footer too
    *   v1.4 - call add-header correctly so that PDF links are created correctly
    *   v1.3 - change format for CIAO 3.0; added cssfile parameter
    *   v1.2 - update title to better-match the new style
    *   v1.1 - copy of v1.6 of the ChaRT thread stylesheet
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

  <xsl:param name="imglinkicon" select='""'/>
  <xsl:param name="imglinkiconwidth" select='0'/>
  <xsl:param name="imglinkiconheight" select='0'/>

  <xsl:include href="thread_common.xsl"/>
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <xsl:template name="newline">
<xsl:text> 
</xsl:text>
  </xsl:template>

  <xsl:template match="/">

    <xsl:call-template name="is-site-valid"/>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'install'"/>
      <xsl:with-param name="pvalue" select="$install"/>
    </xsl:call-template>
    <xsl:call-template name="is-proglang-valid"/>

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<xsl:apply-templates select="thread" mode="html-hardcopy-standard"/>
      </xsl:when>

      <xsl:otherwise>
	<xsl:apply-templates select="thread" mode="html-viewable"/>
	<xsl:apply-templates select="thread/images/image" mode="list"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!-- match="/" *-->


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

      <xsl:call-template name="add-top-links-sherpa-html">
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

      <xsl:call-template name="add-bottom-links-sherpa-html">
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
