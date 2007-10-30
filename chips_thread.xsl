<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the HTML version of the ChIPS thread
    *
    * Recent changes:
    * 2007 Oct 30 DJB
    *    start work on supporting proglang (=sl or py)
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *   v1.3 - added syntax line under thread title
    *   v1.2 - changed "Sherpa" to "ChIPS"
    *   v1.1 - copy of v1.12 of the Sherpa thread stylesheet
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

	    <h2>ChIPS Threads (CIAO <xsl:value-of select="$siteversion"/>)</h2>
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

      <xsl:call-template name="add-top-links-chips-html">
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

      <xsl:call-template name="add-bottom-links-chips-html">
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
