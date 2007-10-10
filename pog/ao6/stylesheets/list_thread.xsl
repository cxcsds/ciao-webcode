<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * lists the pages/files needed/created by the thread page
    *
    * $Id: list_thread.xsl,v 1.3 2002/09/18 19:27:37 dburke Exp $ 
    *
    * Recent changes:
    *   v1.3 - added support for /thread/info/files/file
    *   v1.2 - added support for parameter files
    *   v1.1 - copy of v1.3 of list_ciao_thread.xsl
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

    <!--* we always create an index file ! *-->
    <xsl:text>html: index.html
</xsl:text>

    <!--* we always create a hardcopy version of the page ! *-->
    <xsl:text>html: index.hard.html
</xsl:text>

    <!--*
        * list the files that need pre-processing to convert into XML
        *
        * screen tags
        *   only want nodes that are within the text or images block,
        *   and have file attributes
        *
        * paramfile tags
        *   only want nodes that have file attributes
        *
        *-->
    <xsl:for-each select="//thread/text/descendant::screen[boolean(@file)]">
      <xsl:text>screen: </xsl:text><xsl:value-of select="@file"/><xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:for-each select="//thread/images/descendant::screen[boolean(@file)]">
      <xsl:text>screen: </xsl:text><xsl:value-of select="@file"/><xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:for-each select="//thread/parameters/paramfile[boolean(@file)]">
      <xsl:text>screen: </xsl:text><xsl:value-of select="@file"/><xsl:text>
</xsl:text>
    </xsl:for-each>

    <!--*
        * any figures related to the image pages?
        *
        * need to list the actual "source" files [image/ps]
        * and the pages that are created
        *-->
    <xsl:for-each select="//thread/images/image">

      <xsl:text>image: </xsl:text><xsl:value-of select="@src"/><xsl:text>
</xsl:text>
      <xsl:if test='boolean(@ps)'>
	<xsl:text>image: </xsl:text><xsl:value-of select="@ps"/><xsl:text>
</xsl:text>
      </xsl:if>
      
      <xsl:text>html: </xsl:text><xsl:value-of select='concat("img",position(),".html")'/><xsl:text>
</xsl:text>

    </xsl:for-each>

    <!--*
        * any figures related to the img tag?
        *
        * need to list the "source" file
        *-->
    <xsl:for-each select="//thread/text/descendant::img">
      <xsl:text>image: </xsl:text><xsl:value-of select="@src"/><xsl:text>
</xsl:text>
    </xsl:for-each>

    <!--*
        * any files listed in the /thread/info/files/ section?
        *-->
    <xsl:for-each select="//thread/info/files/file">
      <xsl:text>file: </xsl:text><xsl:value-of select="."/><xsl:text>
</xsl:text>
    </xsl:for-each>

  </xsl:template> <!--* match=/ *-->

</xsl:stylesheet>
