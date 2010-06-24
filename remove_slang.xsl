<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<xsl:stylesheet version="1.0" encoding="us-ascii" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" version="1.0" encoding="us-ascii"/>

<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" disable-output-escaping="yes"/>
  </xsl:copy>
</xsl:template>

<!-- drop proglang -->
<xsl:template match="proglang"/>

<!-- drop all S-Lang nodes -->
<xsl:template match="*[@restrict='sl']"/>

<!-- try and drop any restrict attributes -->
<xsl:template match="@restrict"/>

</xsl:stylesheet>
