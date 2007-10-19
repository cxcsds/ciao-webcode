<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * Convert navbar.xml into the SSI pages
    *
    * Recent changes:
    *  Oct 19 2007 DJB
    *    Re-written so that we only process a single depth at a time
    *    Need to send in the startdepth parameter to indicate the
    *    depth of the top-level of the navbar.
    *  v1.36 - split out most code into navbar_main.xsl
    *  v1.35 - place contents within htdig_noindex /htdig_noindex comments
    *          to hide contents from search engine
    *  v1.34 - further minor changes to look of a news item (updates to v1.34)
    *  v1.33 - we no longer automatically add p's to the contents of news/item
    *          tags since we want to allow multiple paragraphs
    *  v1.32 - we no longer assume a navbar should be created at the top-level
    *          to do this you need to say <dir>.</dir>
    *  v1.31 - allow a navbar to be written when depth != 1
    *  v1.30 - removed br element at start when no logoimage/text
    *  v1.29 - if site=caldb include a news bar
    *          date handling now uses add-date from myhtml.xsl (so handles
    *          'year 2000' issues)
    *  v1.28 - sections no longer require a link attribute
    *          (it doesn't look wonderful but let's try it)
    *  v1.27 - logos are now determined by logoimage/logotext parameters
    *  v1.26 - fixed links in section-headings beginning with "/"
    *  v1.25 - added newsfile/newsfileurl parameters + use of globalparams.xsl
    *  v1.24 - navbar class is now inherited from td not from div
    *  v1.23 - CIAO logo is centred
    *          "old news" link is now in the header of the "news" bar
    *          everything surrounded by a "div class='navbar'"
    *          Sherpa site has news items rather than links
    *  v1.22 - Changed the look of the navbars for CIAO 3
    *          Always publish lists; marker for current section; use of CSS
    *          [needs updated helper.xsl, v1.41 at least]
    *  v1.21 - added Sherpa logo (trial)
    *  v1.20 - add highlight attribute to section tags - at the moment this 
    *          stops the change in font size by -1 if @highlight=1
    *  v1.19 - Sherpa logo: none for now
    *  v1.18 - added ahelpindex support (for CIAO 3.0)
    *  v1.17 - removed xsl-revision/version as pointless
    *  v1.16 - added "Old News Items" item to the end of the News table
    *  v1.15 - removed CIAO logo from ChaRT navigation bars
    *  v1.14 - 'fix' ns 4.x issue with the date in each news item
    *  v1.13 - added support for site=icxc
    *  v1.12 - chart navbar's now have a blue background, so they need the transparent logo
    *  v1.11 - taken out logos since show with a border around them in netscape!
    *  v1.10 - CIAO logo at top pf navbar takes you to CIAO home page
    *          IF site=ciao, ChaRT page if site=chart
    *   v1.9 - decided that the _src version of download page should be created
    *          by a perl script (easier to handle than messing around
    *          making sure images are created with leading /ciao/ if necessary)
    *   v1.8 - clean up of HTML
    *   v1.7 - last news item doesn't end in a hr
    *   v1.6 - news bar appears on all CIAO navbar's (not just the main one)
    *          text for "run ChaRT" link section now obtained from navbar.xml
    *          for ChaRT (rather than hard-coded into this stylesheet)
    *          GIFs are now looked for in imgs/ and not gifs/ 
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
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--* load in the set of "global" parameters *-->
  <xsl:include href="globalparams.xsl"/>

  <xsl:param name="startdepth" select='""'/>
  <xsl:param name="logoimage" select='""'/>
  <xsl:param name="logotext"  select='""'/>

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
  <xsl:output method="text" encoding="us-ascii"/>

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
