<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html"/>
  <xsl:template match="/">
    <xsl:apply-templates select="//PARA"/>
  </xsl:template>

  <xsl:template match="EQUATION">
    <xsl:variable name="pre"  select="preceding-sibling::node()[1][self::text()]"/>
    <xsl:variable name="post" select="following-sibling::node()[1][self::text()]"/>

    <xsl:variable name="is-pre-text"  select="normalize-space($pre) != ''"/>
    <xsl:variable name="is-post-text" select="normalize-space($post) != ''"/>

    <xsl:variable name="is-pre-eqn"  select="name(preceding-sibling::*[1]) = 'EQUATION'"/>
    <xsl:variable name="is-post-eqn" select="name(following-sibling::*[1]) = 'EQUATION'"/>

    <xsl:if test="$is-pre-text or not($is-pre-eqn)">
      <xsl:message>ENTERING EQUATION SET</xsl:message>
    </xsl:if>

    <xsl:message>{{<xsl:value-of select="normalize-space(.)"/>}}</xsl:message>

    <xsl:if test="$is-post-text or not($is-post-eqn)">
      <xsl:message>LEAVING EQUATION SET</xsl:message>
    </xsl:if>

  </xsl:template>

<!--
  <xsl:template match="*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
-->

</xsl:stylesheet>
