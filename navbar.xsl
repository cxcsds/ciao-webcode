<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * Convert navbar.xml into the SSI pages
    *
    * $Id: navbar.xsl,v 1.36 2004/09/08 20:52:02 dburke Exp $ 
    *-->

<!--* 
    * NEEDS to be re-written to not do multiple depths since this
    * leads to horrible templates everywhere (since the depth parameter needs 
    * to be passed through to every template)
    * 
    * Recent changes:
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

    <!--* process each section *-->
    <xsl:apply-templates select="descendant::section[boolean(@id)]" mode="with-id">
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>

  </xsl:template> <!--* match=navbar *-->

</xsl:stylesheet>
