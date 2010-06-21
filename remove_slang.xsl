<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="/">
    <xsl:call-template name="copyit"/>
  </xsl:template>

  <xsl:template name="copyit">
    <!-- node() is needed to capture comments -->
    <xsl:copy-of select="@* | node()"/>
  </xsl:template>

</xsl:stylesheet>
