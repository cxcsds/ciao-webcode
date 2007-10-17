<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the thread index pages - site agnostic
    *
    * $Id: threadindex.xsl,v 1.7 2004/05/14 18:22:46 dburke Exp egalle $ 
    *-->

<!--* 
    * ***NOTE*** - hardcopy code could be made more modular (lots of repeated stuff)
    *
    * Recent changes:
    *   v1.7 - We are no called with hardcopy=0 or 1 and this determines
    *          the type of the file created (CIAO 3.1)
    *   v1.6 - updated to handle head/texttitlepostfix
    *   v1.5 - added newsfile/newsfileurl parameters + use of globalparams_thread.xsl
    *   v1.4 - added cssfile parameter
    *   v1.3 - ensured that type is listed as a parameter here (used in threadindex_common.xsl)
    *   v1.2 - changed comments from v1.2 - no functional change
    *   v1.1 - copy of v1.18 of ciao_threadinex.xsl
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:output method="text"/>

  <!--* load in the set of "global" parameters *-->
  <xsl:param name="lastmod"   select='""'/>      <!--* over-ride the thread setting *-->
  <xsl:param name="depth"     select="2"/>
  <xsl:include href="globalparams_thread.xsl"/>

  <!--* used to create the HTML header *-->
  <xsl:variable name="ciaothreadver" select="concat('Threads for CIAO ',$siteversion)"/>

  <!--* include the stylesheets *-->
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>
  <xsl:include href="threadindex_common.xsl"/>

  <!--* 
      * top level: create the set of thread pages
      *
      *   index.html
      *   all.html
      *   <section>.html
      *   table.html (if datatabel section is present)
      *   
      *-->

  <xsl:template match="/">

    <!--* check the params are okay *-->
    <xsl:call-template name="is-site-valid"/>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'install'"/>
      <xsl:with-param name="pvalue" select="$install"/>
    </xsl:call-template>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'sourcedir'"/>
      <xsl:with-param name="pvalue" select="$sourcedir"/>
    </xsl:call-template>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'threadDir'"/>
      <xsl:with-param name="pvalue" select="$threadDir"/>
    </xsl:call-template>
    <!--* end checks *-->

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<!--* hardcopy *-->
	<xsl:apply-templates name="threadindex" mode="make-index-hard">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
	<xsl:apply-templates name="threadindex" mode="make-all-hard">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="threadindex/section" mode="make-section-hard">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
	<xsl:if test="boolean(//threadindex/datatable)">
	  <xsl:apply-templates name="threadindex" mode="make-table-hard">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</xsl:if>
      </xsl:when>

      <xsl:otherwise>
	<!--* softcopy *-->
	<xsl:apply-templates name="threadindex" mode="make-index">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
	<xsl:apply-templates name="threadindex" mode="make-all">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="threadindex/section" mode="make-section">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
	<xsl:if test="boolean(//threadindex/datatable)">
	  <xsl:apply-templates name="threadindex" mode="make-table">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</xsl:if>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* match=/ *-->

  <!--* really need to sort out the whole newline business *-->
  <xsl:template name="newline">
<xsl:text>
</xsl:text>
  </xsl:template> <!--* name=newline *-->

</xsl:stylesheet>