<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * $Id: list_root_node.xsl,v 1.2 2002/09/18 14:44:58 dburke Exp $ 
    *
    * there are better ways to find the name of the root node
    * of a document, but this has the advantage of being quick to write
    *
    * Recent changes:
    *   v1.2 - now outputs " test" after the root node name if /*/info/testonly exists
    *
    *-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  <xsl:template match="/">
    <xsl:value-of select="name(//*)"/>
    <xsl:if test="boolean(/*/info/testonly)">
      <xsl:text> TESTONLY</xsl:text>
    </xsl:if>
<xsl:text>
</xsl:text>
  </xsl:template>
</xsl:stylesheet>
