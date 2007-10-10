<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the hardcopy HTML version of the CIAO thread
    *
    * $Id: pog_thread_hard.xsl,v 1.7 2003/09/12 17:02:05 dburke Exp $ 
    *-->

<!--* 
    * Recent changes:
    *   v1.7 - threadVersion veriable replaced by siteversion
    *   v1.6 - added newsfile/newsfileurl parameters + use of globalparams_thread.xsl
    *   v1.5 - ahelpindex (CIAO 3.0)
    *   v1.4 - removed xsl-revision/version as pointless
    *   v1.3 - added siteversion variable which does NOTHING for now
    *   v1.2 - converted to POG
    *   v1.1 - copy of v1.2 of ChaRT hardcopy thread
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
      *   $install/index.hard.html
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

    <!--* create the HTML (hardcopy) version *-->
    <xsl:apply-templates select="thread" mode="html-hardcopy">
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>

  </xsl:template> <!-- match="/" *-->

  <!--*
      * create: $install/index.hard.html
      *-->
  <xsl:template match="thread" mode="html-hardcopy">
    <xsl:param name="depth" select="1"/>

    <xsl:variable name="filename"><xsl:value-of select="$install"/>index.hard.html</xsl:variable>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <!--* get the start of the document over with *-->
      <html>

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead">
	  <xsl:with-param name="title"><xsl:choose>
	      <xsl:when test="boolean($threadInfo/title/short)"><xsl:value-of select="$threadInfo/title/short"/></xsl:when>
	      <xsl:otherwise><xsl:value-of select="$threadInfo/title/long"/></xsl:otherwise>
	    </xsl:choose> - POG <xsl:value-of select="$siteversion"/></xsl:with-param>
	</xsl:call-template>

	<!--* and now the main part of the text *-->
	<body>

	  <!--* set up the title page *-->
	  <div align="center">

	    <h1><xsl:value-of select="$threadInfo/title/long"/></h1>

	    <!--*
	        * just add the logo directly
	        * don't use any templates, since this is a bit of a fudge
                *-->
	    <img src="../cxc-logo.gif" alt="[CXC Logo]"/>

	    <h2><strong>POG Threads</strong></h2>

	  </div>
	  <xsl:call-template name="add-new-page"/>

	  <!--* table of contents page *-->
	  <xsl:call-template name="add-toc">
	    <xsl:with-param name="depth" select="$depth"/>
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>

	  <xsl:call-template name="add-new-page"/>

	  <!--* start the thread *-->

	  <!--* make the header *-->
	  <xsl:call-template name="add-id-hardcopy">
	    <xsl:with-param name="urlfrag" select="concat('threads/',$threadName,'/')"/>
	    <xsl:with-param name="lastmod" select="$lastmodified"/>
	  </xsl:call-template>
	  <xsl:call-template name="add-hr-strong"/>
	  <br/>

	  <!--* set up the title block of the page *-->
	  <h1 align="center"><xsl:value-of select="$threadInfo/title/long"/></h1>
	  <div align="center"><strong>Proposal Threads for <xsl:value-of select="$siteversion"/></strong></div>

	  <!--* Introductory text *-->
	  <xsl:call-template name="add-introduction">
	    <xsl:with-param name="depth" select="$depth"/>
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>

	  <!--* Main thread *-->
	  <xsl:apply-templates select="text/sectionlist">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	
	  <!--* Summary text *-->
	  <xsl:call-template name="add-summary">
	    <xsl:with-param name="depth" select="$depth"/>
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>
	
	  <!--* Parameter files *-->
	  <xsl:call-template name="add-parameters">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:call-template>

	  <!-- History -->
	  <xsl:apply-templates select="info/history">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>

	  <!--* add the footer text *-->
	  <br/>
	  <xsl:call-template name="add-hr-strong"/>
	  <xsl:call-template name="add-id-hardcopy">
	    <xsl:with-param name="urlfrag" select="concat('threads/',$threadName,'/')"/>
	    <xsl:with-param name="lastmod" select="$lastmodified"/>
	  </xsl:call-template>

	  <!--* add the images *-->
	  <xsl:for-each select="images/image">

	    <!--* based on template match="image" mode="list" *-->
	    <xsl:variable name="pos" select="position()"/>
	    <xsl:variable name="imgname" select='concat("Image ",$pos)'/>

	    <!--* add a new page *-->
	    <xsl:call-template name="add-new-page"/>
	    <h3><a name="img-{@id}"><xsl:value-of select="$imgname"/>: <xsl:value-of select="title"/></a></h3>

	    <!--* "pre-image" text *-->
	    <xsl:if test="boolean(before)">
	      <xsl:apply-templates select="before">
		<xsl:with-param name="depth" select="$depth"/>
	      </xsl:apply-templates>
	    </xsl:if>

	    <!--* image:
                *   would like to use the PS version if available
                *   BUT htmldoc doesn't support this
                *-->
	    <img alt="[{$imgname}]" src="{@src}"/>
		
	    <!--* "post-image" text *-->
	    <xsl:if test="boolean(after)">
	      <xsl:apply-templates select="after">
		<xsl:with-param name="depth" select="$depth"/>
	      </xsl:apply-templates>
	    </xsl:if>

	  </xsl:for-each>
	  
	</body>
      </html>

    </xsl:document>

  </xsl:template> <!--* match=thread mode=html-hardcopy *-->

  <!--*
      * add a "new page" comment to be read by HTMLDOC
      *-->
  <xsl:template name="add-new-page">
    <xsl:comment> NEW PAGE </xsl:comment><xsl:text>
</xsl:text>
  </xsl:template> <!--* name=add-new-page *-->

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
      * We have two versions of this template, one in
      * ciao_thread.xsl for when creating the viewable HTML
      * file, and one in ciao_thread_hard.xsl for when
      * creating the hardcopy HTML file. This is because
      * we use different links in the two cases: to a 
      * separate file (viewable) and to an anchor within
      * the file (hardcopy)
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

    <!--* need an anchor so that the img<n>.html page can link back to the text *-->
    <a name="{@id}">
      <a href="#img-{@id}">
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
    </a> <!--* anchor *-->

  </xsl:template> <!--* imglink *-->

</xsl:stylesheet>
