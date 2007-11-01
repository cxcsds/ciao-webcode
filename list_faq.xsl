<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* lists the FAQ pages created by the transformation
    *
    * Recent changes:
    *   v1.4 - we no longer include the installation directory, so
    *          we do not need parameters or any checks
    *   v1.3 - removed xsl-revision/version as pointless
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--*
      * since we list the files we produce to the screen, the output method is text.
      *-->
  <xsl:output method="text" encoding="us-ascii"/>

  <!--* 
      * ROOT ELEMENT
      *
      * top level: create the set of pages
      *
      *   index.html
      *   {faqentry/@id}.html
      *      
      * does NOT list the hardcopy versions
      *
      *-->
  <xsl:template match="/">
    <!--* the index page *-->
<xsl:text>index.html
</xsl:text>

    <!--* the individual faq pages *-->
    <xsl:for-each select="//faqentry">
      <xsl:value-of select="@id"/>.html<xsl:text>
</xsl:text>
    </xsl:for-each>

  </xsl:template> <!--* match=/ *-->

</xsl:stylesheet>
