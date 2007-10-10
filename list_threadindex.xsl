<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* lists the 'thread index' pages created by the transformation
    *
    * $Id: list_threadindex.xsl,v 1.3 2004/05/14 15:17:51 dburke Exp $ 
    *-->

<!--* 
    * Recent changes:
    *   v1.3 - removed a lot of extraneous/un-needed info and removed checks
    *          to avoid pulling in helper.xsl and hence set up params
    *   v1.2 - added comment to say that this is meant to be site agnostic
    *          (ie we do not have separate list_site_threadindex.xsl stylesheets)
    *   v1.1 - copy of v1.7 of list_ciao_threadindex.xsl
    *
    * As of v1.3 we no longer prepend the installion directory onto the
    * file names as this can be done externally
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="us-ascii"/>

  <!--* 
      * ROOT ELEMENT
      *
      * top level: create the set of thread pages
      *
      *   index.html
      *   all.html
      *   <section>.html
      *   table.html
      *      
      * As of v1.3 we no longer prepend the installion directory onto the
      * file names as this can be done externally
      *      
      * Played some tricks to ensure we have one file per line with no
      * white-space. It's not really necessary (can post-process the output)
      * but it is a bit nicer.
      *-->
  <xsl:template match="threadindex">

<xsl:text>index.html
all.html
</xsl:text>

    <xsl:for-each select="section">
      <xsl:value-of select="id/name"/><xsl:text>.html
</xsl:text>
    </xsl:for-each>

    <xsl:if test="boolean(//threadindex/datatable)">
<xsl:text>table.html
</xsl:text>
    </xsl:if>

</xsl:template> <!--* match=threadindex *-->

</xsl:stylesheet>
