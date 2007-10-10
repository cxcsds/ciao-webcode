<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the HTML version of the ChaRT thread
    *
    * $Id: pog_thread.xsl,v 1.13 2003/09/12 17:02:05 dburke Exp $ 
    *-->

<!--* 
    * Recent changes:
    *  v1.13 - threadVersion veriable replaced by siteversion
    *  v1.12 - fixes to HTML plus more table-related changes (add-header/footer)
    *          imglink now uses a single a tag with name and href attributes
    *  v1.11 - added newsfile/newsfileurl parameters + use of globalparams_thread.xsl
    *  v1.10 - use of tables for the main text has changed.
    *   v1.9 - call add-header/footer so that the PDF links are created correctly
    *   v1.8 - change format for CIAO 3.0; added cssfile parameter
    *          year can be > 2000 now
    *   v1.7 - ahelpindex for CIAO 3.0
    *   v1.6 - removed xsl-revision/version as pointless
    *   v1.5 - added siteversion variable which does NOTHING for now
    *   v1.4 - add-bottom-links-pog-html
    *   v1.3 - cleaned up (moved image generation code to thread_common.xsl)
    *   v1.2 - converted to POG
    *   v1.1 - copy of v1.2 of the ChaRT thread stylesheet
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--* we create the HTML files using xsl:document statements *-->
  <xsl:output method="text"/>

  <!--* load in the set of "global" parameters *-->
  <xsl:include href="globalparams_thread.xsl"/>

  <!--* include the stylesheets *-->
  <xsl:include href="thread_common.xsl"/>
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <!--* really need to sort out the newline template issue *-->
  <xsl:template name="newline">
<xsl:text> 
</xsl:text>
  </xsl:template>

  <!--* 
      * top level - create:
      *   index.html
      *   img<n>.html
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

    <!--* create the HTML (viewable) version *-->
    <xsl:apply-templates select="thread" mode="html-viewable">
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>

  <!--*
      * create the image files
      *-->
    <xsl:apply-templates select="thread/images/image" mode="list">
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>

  </xsl:template> <!-- match="/" *-->

  <!--*
      * create: $install/index.html
      *-->
  <xsl:template match="thread" mode="html-viewable">
    <xsl:param name="depth" select="1"/>
    
    <xsl:variable name="filename"><xsl:value-of select="$install"/>index.html</xsl:variable>
    
    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <!--* get the start of the document over with *-->
      <xsl:call-template name="add-start-html"/>

      <!--* make the HTML head node *-->
      <xsl:call-template name="add-htmlhead">
	<xsl:with-param name="title"><xsl:choose>
	    <xsl:when test="boolean($threadInfo/title/short)"><xsl:value-of select="$threadInfo/title/short"/></xsl:when>
	    <xsl:otherwise><xsl:value-of select="$threadInfo/title/long"/></xsl:otherwise>
	  </xsl:choose> - POG <xsl:value-of select="$siteversion"/></xsl:with-param>
      </xsl:call-template>
      
      <!--* add disclaimer about editing the HTML file *-->
      <xsl:call-template name="add-disclaimer"/>
      
      <!--* make the header *-->
      <xsl:call-template name="add-header">
	<xsl:with-param name="depth" select="$depth"/>
	<xsl:with-param name="name"  select="//thread/info/name"/>
      </xsl:call-template>

      <!--* set up the standard links before the page starts *-->
      <xsl:call-template name="add-top-links-pog-html">
	<xsl:with-param name="depth" select="$depth"/>
	<xsl:with-param name="name" select="$threadName"/>
      </xsl:call-template>

      <div class="mainbar">

	<!--* set up the title block of the page *-->
	<div align="center"><h1><xsl:value-of select="$threadInfo/title/long"/></h1></div>
	<xsl:call-template name="add-hr-strong"/>

	<!--* Introductory text *-->
	<xsl:call-template name="add-introduction">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:call-template>

	<!--* table of contents *-->
	<xsl:call-template name="add-toc">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:call-template>

	<!--* Main thread *-->
	<xsl:apply-templates select="text/sectionlist">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
	
	<!--* Summary text *-->
	<xsl:call-template name="add-summary">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:call-template>
	
	<!--* Parameter files *-->
	<xsl:call-template name="add-parameters">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:call-template>

	<!-- History -->
	<xsl:apply-templates select="info/history">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>

	<xsl:call-template name="add-hr-strong"/>

      </div> <!--* class=mainbar *-->

      <!--* set up the trailing links to threads/harcdopy *-->
      <xsl:call-template name="add-bottom-links-pog-html">
	<xsl:with-param name="depth" select="$depth"/>
	<xsl:with-param name="name" select="$threadName"/>
      </xsl:call-template>

      <!--* add the footer text *-->
      <xsl:call-template name="add-footer">
	<xsl:with-param name="depth" select="$depth"/>
	<xsl:with-param name="name"  select="//thread/info/name"/>
      </xsl:call-template>

      <!--* add </body> tag [the <body> is included in a SSI] *-->
      <xsl:call-template name="add-end-body"/>
      <xsl:call-template name="add-end-html"/>

    </xsl:document>

  </xsl:template> <!--* match=thread mode=html-viewable *-->

  <!--*** handle images ***-->

  <!--*
      * handle imglink tags 
      * 
      *  attributes:
      *    src - string, required
      *          name of image in gif/jpeg format
      *    id  - string, required
      *          used to tie in with imglink, and 
      *          allow "back to thread" link
      *
      * This template uses the find-pos template to
      * find the number of the image node (in the list
      * of image nodes) that has an id attribute that
      * matches the input id attribute.
      * Not elegant, but it works.
      *
      * We have multiple versions of this template, one in
      * XXXX_thread.xsl for when creating the viewable HTML
      * file, and one in XXXX_thread_hard.xsl for when
      * creating the hardcopy HTML file. This is because
      * we use different links in the two cases: to a 
      * separate file (viewable) and to an anchor within
      * the file (hardcopy)
      *
      * Should use a stylesheet global variable (hardcopy?)
      * to determine what to do (then don't need multiple copies)
      *
      *-->

  <xsl:template match="imglink">
    <xsl:param name="depth" select="1"/>

    <!--*
        * get the name of the file that this link links to
        * - must be a better way of doing this
        *-->
    <xsl:variable name="pos">
      <xsl:call-template name="find-pos">
	<xsl:with-param name="matchID" select="@id"/>
	<xsl:with-param name="pos"     select="count(//thread/images/image)"/>
	<xsl:with-param name="nodes"   select="//thread/images/image"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="filename">img<xsl:value-of select="$pos"/></xsl:variable> 

    <!--* need an anchor so that the img<n>.html page can link back to the text *-->
    <a name="{@id}" href="{$filename}.html">
      <xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
      <xsl:call-template name="add-nbsp"/>
      <xsl:call-template name="add-image">
	<xsl:with-param name="src"    select="'imgs/imageicon.gif'"/>
	<xsl:with-param name="depth"  select="$depth"/>
	<xsl:with-param name="alt">Link to Image <xsl:value-of select="$pos"/></xsl:with-param>
	<xsl:with-param name="width"  select="30"/>
	<xsl:with-param name="height" select="30"/>
	<xsl:with-param name="border" select="0"/>
      </xsl:call-template>
    </a>

  </xsl:template> <!--* imglink *-->

</xsl:stylesheet>
