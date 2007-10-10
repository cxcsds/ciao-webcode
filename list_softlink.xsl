<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * List the files for a soft link
    *
    * $Id: list_softlink.xsl,v 1.2 2002/09/04 18:24:25 dburke Exp $ 
    *-->

<!--* 
    * Recent changes:
    *   v1.2 - initial version
    *   v1.1 - copy of redirect.xsl
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:apply-templates name="softlink"/>
  </xsl:template> <!--* match=/ *-->

  <!--*
      * list the files
      *-->
  <xsl:template match="softlink">

    <!--* output original name *-->
    <xsl:text>original: </xsl:text>
    <xsl:value-of select="original"/><xsl:text>
</xsl:text>

    <!--* output link name *-->
    <xsl:text>link: </xsl:text>
    <xsl:value-of select="link"/><xsl:text>
</xsl:text>

  </xsl:template> <!--* match=softlink *-->

</xsl:stylesheet>
