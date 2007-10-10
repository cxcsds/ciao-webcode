<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* lists the navbar's created by the transformation
    *
    * $Id: list_navbar.xsl,v 1.5 2004/05/11 15:54:18 dburke Exp $ 
    *-->

<!--* 
    * Recent changes:
    *   v1.5 - update to match v1.32 of navbar.xsl: we no longer assume
    *          navbars are created in the top-level directory
    *          also updated to match new use of "depth" code
    *   v1.4 - removed some of the included stylesheets as not needed
    *   v1.3 - removed xsl-revision/version as pointless
    *   v1.2 - added support for site=icxc
    *
    * User-defineable parameters:
    *  . type="test"|"live"
    *    whether to create the test or "real" version
    *
    *  . updateby=string
    *
    *  . lastmod=string to use to say when page was last modified
    *
    *  . site=one of: ciao chart icxc
    *    tells the stylesheet what site we are working with
    *
    *  . install=full path to directory where to install file
    *  . sourcedir=full path to directory containing navbar.xml
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--* these should be over-ridden from the command line *-->
  <xsl:param name="site"      select='""'/>
  <xsl:param name="install"   select='""'/>
  <xsl:param name="sourcedir" select='""'/>

  <!--* include the stylesheets AFTER defining the variables *-->
  <xsl:include href="helper.xsl"/>

  <!--* since we list the files we produce to the screen, the output method is text.
      *-->
  <xsl:output method="text" encoding="us-ascii"/>

  <!--* 
      * ROOT ELEMENT
      *
      * we list an output page for each section tag WITH an id attribute
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

    <xsl:for-each select="descendant::section[boolean(@id)]">

      <!--* top-level navbar *-->
<!--*
    * we no longer assume that the navbar will live in the
    * top-level. To get a top-level item use <dir>.</dir>
    *
      <xsl:apply-templates select="." mode="process">
	  <xsl:with-param name="depth" select="1"/>
      </xsl:apply-templates>
*-->

      <!--*
          * are there any dirs?
          * - we process the empty dir tag separately from the other tags
          *-->
      <xsl:for-each select="dirs/dir[.='']">
	<!--* there really should be only one of these at most *-->
	<xsl:apply-templates select="ancestor::section" mode="process">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>

      </xsl:for-each>

      <xsl:for-each select="dirs/dir[.!='']">
	<!--* messy way to find the number of / in the name of dir
            * (strip trailing / but then we add it back when calling the template)
	    *-->
	<xsl:variable name="dlen" select="string-length(.)"/>
	<xsl:variable name="dir" select="concat(substring(.,1,$dlen -1),translate(substring(.,$dlen),'/',''))"/>
	<xsl:variable name="ndepth" select="1 + $depth + string-length($dir) - string-length(translate($dir,'/',''))"/>

	<!--* call the template on each of the dirs *-->
	<xsl:apply-templates select="ancestor::section" mode="process">
	  <xsl:with-param name="dir"   select="concat($dir,'/')"/>
	  <xsl:with-param name="depth" select="$ndepth"/>
	</xsl:apply-templates>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template> <!--* match=navbar *-->

  <!--* process (well, just list) each section that has an output page
      *-->
  <xsl:template match="section" mode="process">
    <xsl:param name="dir"   select="''"/>
    <xsl:param name="depth" select="'1'"/>

    <!--* set up useful variables *-->
    <xsl:variable name="filename" select="concat($install,$dir,'navbar_',@id,'.incl')"/>

    <!--* print out the filename and ensure followed by a new line *-->
    <xsl:value-of select="$filename"/><xsl:text>
</xsl:text>

  </xsl:template> <!--* match=section mode=process *-->

</xsl:stylesheet>
