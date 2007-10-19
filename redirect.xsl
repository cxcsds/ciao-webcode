<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create a "redirect" page to automatically redirect the
    * brower to the new page
    *
    * Recent changes:
    *   v1.5 - <html> changed to <html lang="en"> following
    *            http://www.w3.org/TR/2005/WD-i18n-html-tech-lang-20050224/
    *   v1.4 - added a title tag to make pages match the DTD
    *   v1.3 - explicitly checks for filename being set; cleaned up
    *          screen output (no more DTD declaration)
    *   v1.2 - page is written to the correct file, rather than to STDOUT
    *   v1.1 - initial version
    *
    * Currently a very simple stylesheet that requires only one
    * parameter.
    *
    * Parameters:
    *  . filename=full name of output file (including .html)
    *  
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text"/>

  <xsl:param name="filename"/>

  <xsl:template match="/">

    <!--*
        * safety check: are all the required parameters defined/sensible
        *-->
    <xsl:if test="$filename=''">
      <xsl:message terminate="yes">
 Error:
   the stylesheet has been called without setting the required parameter
     filename

      </xsl:message>
    </xsl:if>

    <xsl:apply-templates name="redirect"/>
  </xsl:template> <!--* match=/ *-->

  <!--*
      * create: <page>.html
      *
      * the tag has one node - to - which contains the url
      * the page is to be redirected to
      *
      * Currently we always set the delay to 0.
      * A value > 0 would be easy to allow, but we'd then have to
      * worry about what text to include on the page
      *
      * The title tag is needed to ensure the page is valid
      * ie the DTD requires it. It is not clear what use it
      * is beyond ensuring validity.
      *-->
  <xsl:template match="redirect">

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:text>
</xsl:text>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">

      <!--* create document *-->
      <html lang="en">
	<head>
	  <title>The page you are looking for has moved</title>
	  <meta http-equiv="Refresh" >
	    <xsl:attribute name="content">0; URL=<xsl:value-of select="to"/></xsl:attribute>
	  </meta>
	</head>
	<body/>
      </html>
    </xsl:document>
  </xsl:template> <!--* match=redirect *-->

</xsl:stylesheet>
