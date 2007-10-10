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

    <xsl:message>{{<xsl:value-of select="normalize-space(.)"/>}}</xsl:message>

    <xsl:call-template name="match-following-verbatim">
      <xsl:with-param name="nodelist" select="following-sibling::*"/>
    </xsl:call-template>	

<!--* I do not think this is actually important?
    <xsl:if test="$is-post-text or not($is-post-eqn)">
      <xsl:message>LEAVING EQUATION SET</xsl:message>
    </xsl:if>
*-->
      <xsl:message>LEAVING EQUATION SET</xsl:message>
    </xsl:if>

  </xsl:template>

  <!--*
      * can I create a subset of a node list? eg remove element 1?
      *-->
  <xsl:template name="match-following-verbatim">
    <xsl:param name="nodelist" select="''"/>

    <xsl:call-template name="match-following-verbatim-iter">
      <xsl:with-param name="nodelist" select="$nodelist"/>
      <xsl:with-param name="len" select="count($nodelist)"/>
      <xsl:with-param name="pos" select="1"/>
    </xsl:call-template>      
  </xsl:template>

  <xsl:template name="match-following-verbatim-iter">
    <xsl:param name="nodelist" select="''"/>
    <xsl:param name="len" select="0"/>
    <xsl:param name="pos" select="1"/>

    <!--* do we process and continue or stop? *-->
    <xsl:choose>
      <!--* the '$len=0' check should be unnescessary but left in for documentation *-->
      <xsl:when test="$len = 0 or $pos > $len"/>
      <xsl:when test="name($nodelist[$pos]) != 'EQUATION'"/>

      <xsl:otherwise>
    <xsl:message>{{<xsl:value-of select="normalize-space($nodelist[$pos])"/>}}</xsl:message>
	<xsl:call-template name="match-following-verbatim-iter">
	  <xsl:with-param name="nodelist" select="$nodelist"/>
	  <xsl:with-param name="len" select="$len"/>
	  <xsl:with-param name="pos" select="$pos + 1"/>
	</xsl:call-template>      
      </xsl:otherwise>
    </xsl:choose>

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
