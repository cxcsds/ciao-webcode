<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the thread index pages - site agnostic
    *
    * Recent changes:
    * 2008 May 30 DJB Removed generation of PDF version
    *
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *    also changed a few name attributes of xsl:apply-template nodes
    *    to select attributes (why hasn't this caused a problem previously?)
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:output method="text"/>

  <!--* load in the set of "global" parameters *-->
  <xsl:param name="lastmod"   select='""'/>      <!--* over-ride the thread setting *-->
  <xsl:param name="depth"     select="2"/> <!--* not sure if we need *-->
  <xsl:include href="globalparams_thread.xsl"/>

  <!--* used to create the HTML header *-->
  <xsl:variable name="ciaothreadver" select="'Threads'"/>

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
      *   table.html (if datatable section is present)
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

    <xsl:apply-templates select="threadindex" mode="make-index"/>
    <xsl:apply-templates select="threadindex" mode="make-all"/>
    <xsl:apply-templates select="threadindex/section" mode="make-section"/>
    <xsl:if test="boolean(//threadindex/datatable)">
      <xsl:apply-templates select="threadindex" mode="make-table"/>
    </xsl:if>

  </xsl:template> <!--* match=/ *-->

  <!--* really need to sort out the whole newline business *-->
  <xsl:template name="newline">
<xsl:text>
</xsl:text>
  </xsl:template> <!--* name=newline *-->

</xsl:stylesheet>
