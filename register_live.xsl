<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the 'live' version of a register page (in HTML version)
    *
    * $Id: register_live.xsl,v 1.14 2005/03/02 21:56:06 dburke Exp $ 
    *-->

<!--* 
    * Recent changes:
    *  v1.14 - <html> changed to <html lang="en"> following
    *            http://www.w3.org/TR/2005/WD-i18n-html-tech-lang-20050224/
    *  v1.13 - removed the regtype variable as no-longer used by the reglink tag
    *          Moved the reglink tag into this stylesheet as no longer needs to
    *          be in links.xsl.
    *  v1.12 - support for calling with hardcopy=0/1
    *          CIAO 3.1 updates (no longer need to create the _reg form)
    *  v1.11 - bug fix (type) for v1.10
    *  v1.10 - support for head/texttitlepostfix parameters
    *   v1.9 - added maintext anchor
    *   v1.8 - removing tables from header/footer
    *   v1.7 - added newsfile/newsfileurl parameters + use of globalparams.xsl
    *   v1.6 - reorganised header/footer for new look, added cssfile parameter
    *   v1.5 - ahelpindex support (CIAO 3.0)
    *   v1.4 - removed xsl-revision/version as pointless
    *   v1.3 - added support for siteversion parameter
    *   v1.2 - uses a special 'navbar'
    *   v1.1 - initial version (based on register.xsl and v1.8 of page.xsl)
    *
    * Variables:
    *  . regtype=data - used by links template in helper.xsl
    *
    * Note:
    *  creates:
    *    ${pagename}_src.html    hardcopy=0
    *    ${pagename}.hard.html   hardcopy=1
    *
    * As of CIAO 3.1 we no longer need to create a _reg version of the
    * file, so we have dropped the register.xsl file.
    *
    * It is not clear what changes we may need to make to this to
    * support the CIAO 3.1 download-page format: I am dropping the
    * hacked 'navbar' support as I removed it from the navbar code
    * and do not want to re-create it (so hopefully the register
    * pages will not have a navbar)
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text"/>

  <!--* we place this here to see if it works (was in header.xsl and wasn't working
      * - and it seems to
      *-->
  <!--* a template to output a new line (useful after a comment)  *-->
  <xsl:template name="newline">
<xsl:text> 
</xsl:text>
  </xsl:template>

  <!--* load in the set of "global" parameters *-->
  <xsl:include href="globalparams.xsl"/>

  <!--* will all templates see this, or do we have to pass the value to all elements a la the navbar? *-->
<!--
  <xsl:param name="depth" select="1"/>
-->
  
  <!--* use this several times, so make it into a variable *-->
  <xsl:variable name="head" select="concat($install,$pagename)"/>

  <!--* include the stylesheets AFTER defining the variables *-->
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <!--*
      * top level: create
      *   ${pagename}_src.html   hardcopy=0
      *   ${pagename}.hard.html  hardcopy=1
      *
      *-->
  <xsl:template match="/">

    <!--* check the params are okay *-->
    <xsl:call-template name="is-site-valid"/>
    <xsl:if test="substring($install,string-length($install))!='/'">
      <xsl:message terminate="yes">
  Error: install parameter must end in a / character.
    install=<xsl:value-of select="$install"/>
      </xsl:message>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<xsl:apply-templates name="register" mode="make-hardcopy">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </xsl:when>

      <xsl:otherwise>
	<xsl:apply-templates name="register" mode="make-live">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: ${pagename}_src.html
      *-->

  <xsl:template match="register" mode="make-live">
    <xsl:param name="depth" select="1"/>

    <xsl:variable name="filename"><xsl:value-of select="$head"/>_src.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">

      <!--* we start processing the XML file here *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-standard"/>

	<!--* add disclaimer about editing this HTML file *-->
	<xsl:call-template name="add-disclaimer"/>

	<!--* make the header - it's different depending on whether this is
	    * a test version or the actual production HTML 
            *-->
	<xsl:call-template name="add-header">
	  <xsl:with-param name="depth" select="$depth"/>
	  <xsl:with-param name="name" select="$pagename"/> <!--* PDF's are called pagename.<size>.pdf *-->
	</xsl:call-template>
	<xsl:call-template name="newline"/>

	<xsl:choose>
	  <xsl:when test="boolean(info/navbar)">
	    <!--* use a table to provide the page layout *-->
	    <table class="maintable" width="100%" border="0" cellspacing="2" cellpadding="2">
	      <tr>
		<xsl:call-template name="add-navbar">
		  <!--*
		      * As of CIAO 3.1 I do not want to have to hack the navbar
                      * so I am using the 'default' setting: will it still work?
                      *
		  <xsl:with-param name="name" select="concat(info/navbar,'_src')"/>
                      *
                      *-->
		  <xsl:with-param name="name" select="info/navbar"/>
		</xsl:call-template>
		<td class="mainbar" valign="top">
		  <!--* the main text *-->
		  <a name="maintext"/>
		  <xsl:apply-templates select="text">
		    <xsl:with-param name="depth" select="$depth"/>
		  </xsl:apply-templates>
		</td>
	      </tr>
	    </table>
	  </xsl:when>
	  <xsl:otherwise>
	    <!--* the main text *-->
	    <div class="mainbar">
	      <xsl:apply-templates select="text">
		<xsl:with-param name="depth" select="$depth"/>
	      </xsl:apply-templates>
	    </div>
	  </xsl:otherwise>
	</xsl:choose>

	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="depth" select="$depth"/>
	  <xsl:with-param name="name"  select="$pagename"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=page mode=make-viewable *-->

  <!--* 
      * create: <page>.hard.html
      *-->

  <xsl:template match="register" mode="make-hardcopy">
    <xsl:param name="depth" select="1"/>

    <xsl:variable name="filename"><xsl:value-of select="$head"/>.hard.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">

      <!--* we start processing the XML file here *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-standard"/>

	<!--* and now the main part of the text *-->
	<body>

	  <xsl:call-template name="add-hardcopy-banner-top">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	  <!--* do not need to bother with navbar's here as the hardcopy version *-->
	  <xsl:apply-templates select="text">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
      
	  <xsl:call-template name="add-hardcopy-banner-bottom">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	</body>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=register mode=make-hardcopy *-->

  <!--* note: we process the text so we can handle our `helper' tags *-->
  <xsl:template match="text">
   <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template> <!--* text *-->

  <!--* 
      * for links on the register page: as of CIAO 3.1 we just need
      * to link to the actual data product (previously we had to
      * either link to the data product OR link to the registration
      * page). This means we no longer need the regtype 'global' argument
      *
      * Can *only* be used in a register page (and as we no longer have
      * 2 stylesheets for registration pages we have moved it to
      * register_live.xsl from links.xsl)
      *
      * It is unclear whether we want to make the link HREF be
      *   javascript:getFtp('ftp://....tar.gz')
      * rather than just ftp://....tar.gz (add markup to indicate
      * whether we should do this conversion, ie a log attribute?)
      * 
      * parameters:
      *   depth - standard use
      *
      * attributes:
      *  either
      *    register - string optional
      *    href - string, optional
      *      URL to link to
      *  or
      *    dir  - string, optional
      *      dir name (after ftp://xc.harvard.edu/pub/ ending in /)
      *    file - string, optional
      *      name of file
      *
      * if register/href are used then text must be supplied (used for link)
      * if dir/file are used then file is used for the link text
      *
      *-->
 
  <xsl:template match="reglink">
    <xsl:param name="depth" select="1"/>

    <!--* what params have been supplied? *-->
    <xsl:choose>
      <xsl:when test="boolean(@dir) and boolean(@file)">

	<tt>
	  <a href="ftp://cxc.harvard.edu/pub/{@dir}{@file}"><xsl:value-of select="@file"/></a>
	</tt>
	
      </xsl:when>
      
      <xsl:when test="boolean(@register) and boolean(@href)">
	
	<a href="{@href}"><xsl:apply-templates/></a>
	
      </xsl:when>

      <xsl:otherwise>
	<xsl:message terminate="yes">
 Error:
   reglink has been called without either
     dir &amp; file or register &amp; href
   attributes
	  </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template> <!--* reglink *-->

</xsl:stylesheet>
