<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * Convert navbar.xml into the SSI pages
    *
    * To do:
    *
    * Parameters:
    *   startdepth, integer, required
    *     the starting depth of the navbar (normally 1)
    *
    *   logoimage, string, optional
    *     if the navbar is to have a logo image at the top, this gives the
    *     location of the image, relative to the top-level for this site
    *     e.g. imgs/ciao_logo_navbar.gif
    *
    *   logotext, string, optional
    *     if logoimage is set then this gives the the ALT text for the
    *     logo image, eg "CIAO Logo". If logoimage is unset then this is the
    *     text that is used
    *
    *   logourl, string, optional
    *     If a logo is used (either text or an image) then make it a link to
    *     this location (e.g. '/ciao4.8/').
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="extfuncs">

  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-navbar" select="extfuncs:register-import-dependency('navbar.xsl')"/>

  <!--* load in the set of "global" parameters *-->
  <xsl:include href="globalparams.xsl"/>

  <xsl:param name="startdepth" select='""'/>
  <xsl:param name="logoimage" select='""'/>
  <xsl:param name="logotext"  select='""'/>
  <xsl:param name="logourl"  select='""'/>

  <!--*
      * include the stylesheets AFTER defining the variables
      *-->
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <xsl:include href="navbar_main.xsl"/>

  <!--* there shouldn't be any output to stdout.
      * The include files are created using a
      * xsl:document statement in the section (mode=process) template
      * below as HTML files
      *-->
  <xsl:output method="text" encoding="UTF-8"/>

  <!--* 
      * ROOT ELEMENT
      *
      * we create an output page for each section tag WITH an id attribute
      * and each dirs/dir element of these tags
      *      
      *-->
  <xsl:template match="navbar">

    <!--* check the params are okay *-->
    <xsl:call-template name="is-site-valid"/>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'install'"/>
      <xsl:with-param name="pvalue" select="$install"/>
    </xsl:call-template>
    <xsl:if test="$startdepth = ''">
      <xsl:message terminate="yes">
 ERROR: navbar.xsl called without a startdepth parameter!
      </xsl:message>
    </xsl:if>

    <!--*
        * We are only intersted in sections which contain an id attribute.
        * If $stardepth == $depth then we process the dirs/dir='' entries
	* otherwise it's the non-empty dir elements. We need to be in the
	* dirs/dir node for write-navbar to work (could be changed as only
	* affects the access of the section/@id attribute when setting the
	* matchid parameter within write-navbar).
	*-->
    <xsl:choose>
      <xsl:when test="$startdepth = $depth">
	<xsl:for-each select="descendant::section[boolean(@id)]/dirs/dir[.='']">
	  <xsl:call-template name="write-navbar">
	    <xsl:with-param name="filename" select="concat($install,'navbar_',../../@id,'.incl')"/>
	  </xsl:call-template>
	</xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
	<xsl:for-each select="descendant::section[boolean(@id)]/dirs/dir[.!='']">

	  <!--*
	      * Calculate the new depth from $startdepth and the number of / in the dir name
	      *-->
	  <xsl:variable name="dlen" select="string-length(.)"/>
	  <xsl:variable name="dir"><xsl:choose>
	    <xsl:when test="substring(.,$dlen)='/'"><xsl:value-of select="."/></xsl:when>
	    <xsl:otherwise><xsl:value-of select="concat(.,'/')"/></xsl:otherwise>
	  </xsl:choose></xsl:variable>
	  <xsl:variable name="ndepth" select="$startdepth + string-length($dir) - string-length(translate($dir,'/',''))"/>

	  <xsl:if test="$depth = $ndepth">
	    <xsl:call-template name="write-navbar">
	      <xsl:with-param name="filename" select="concat($install,$dir,'navbar_',../../@id,'.incl')"/>
	    </xsl:call-template>
	  </xsl:if>
	</xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>


  </xsl:template> <!--* match=navbar *-->

</xsl:stylesheet>
