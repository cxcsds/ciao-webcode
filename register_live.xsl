<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the 'live' version of a register page (in HTML version)
    *
    * Recent changes:
    * 2008 May 30 DJB Removed generation of PDF version
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *
    * Variables:
    *  . regtype=data - used by links template in helper.xsl
    *
    * Note:
    *  creates:
    *    ${pagename}_src.html
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

  <!--* use this several times, so make it into a variable *-->
  <xsl:variable name="head" select="concat($install,$pagename)"/>

  <!--* include the stylesheets AFTER defining the variables *-->
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <!--*
      * top level: create
      *   ${pagename}_src.html
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

    <xsl:apply-templates select="register"/>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: ${pagename}_src.html
      *-->

  <xsl:template match="register">

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
	  <xsl:with-param name="name" select="$pagename"/>
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

		  <xsl:apply-templates select="text"/>
		</td>
	      </tr>
	    </table>
	  </xsl:when>
	  <xsl:otherwise>
	    <!--* the main text *-->
	    <div class="mainbar">
	      <xsl:apply-templates select="text"/>
	    </div>
	  </xsl:otherwise>
	</xsl:choose>

	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="name"  select="$pagename"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=register *-->

  <!--* note: we process the text so we can handle our `helper' tags *-->
  <xsl:template match="text">
   <xsl:apply-templates/>
  </xsl:template>

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
