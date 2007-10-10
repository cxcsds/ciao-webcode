<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * lists the math tag contents (or at least the info used to
    * create the mathematical equations)
    *
    * $Id: list_math.xsl,v 1.2 2002/09/04 23:51:40 dburke Exp $ 
    *-->

<!--* 
    * Recent changes:
    *   v1.2 - initial version
    *   v1.1 - copy of v1.2 of list_thread.xsl
    *
    * User-defineable parameters:
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="us-ascii"/>

  <!--* 
      * ROOT ELEMENT
      *
      *-->
  <xsl:template match="/">

    <!--*
        * loop through all the math tags:
        * - for the moment we use latex to create methematical
        *   equations
        *
        * All we output here is the value of the name node
        * (this is used to create the tex/gif file)
        *-->
    <xsl:for-each select="//math">
<xsl:value-of select="name"/><xsl:text>
</xsl:text>
    </xsl:for-each>

  </xsl:template> <!--* match=/ *-->

</xsl:stylesheet>
