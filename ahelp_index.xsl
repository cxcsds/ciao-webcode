<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* AHELP XML to HTML convertor using XSL Transformations 
    *
    * 
    * Create the "index" pages for the ahelp pages - at least the
    * alphabetical and contextual listings.
    * 
    * The stylesheet produces a text output - to STDOUT - listing the files it
    * has created (it uses xsl:document to create the HTML files).
    *   
    * User (ie by the stylesheet processor) defineable parameters:
    *  . type - string, required
    *    one of "live", "test", or "trial"
    *      determines where the HTML files are created
    *      trial is a "developer only" value
    *
    *  . site - string, required
    *    what site are we to generate the index for, should be
    *    one of ciao, chips, or sherpa
    *
    *  . url - TEMPORARY HACK - see v1.21 of ahelp_common
    *
    *  . urlbase - string
    *    base URL of pages (MAY NOT BE NEEDED AS NO LONGER
    *       GENERATE PDF VERSION)
    *
    *  . updateby - string
    *    name of person publishing the page (output of whoami is sufficient)
    *
    *  . cssfile - string
    *    url of CSS file for pages
    *
    *  . navbarname="name" of navbar to use for indexes
    *    if navbar is called navbar_XXX.incl then set navbarname to XXX
    *    default=ahelp
    *
    *  . searchssi - string, default=/incl/search.html, required
    *    url of SSI file for the search bar
    *
    *  . logoimage, string, optional
    *
    *    if the navbar is to have a logo image at the top, this gives the
    *    location of the image, relative to *THE LOCATION OF THE NAV BAR*
    *    e.g. ../imgs/ciao_logo_navbar.gif
    *    This is different than in navbar.xsl where we produce multiple
    *    navigation "bars" in one go and they are not guaranteed to be
    *    all at the same 'depth'
    *
    *  . logotext, string, optional
    *
    *    if logoimage is set then this gives the the ALT text for the
    *    logo image, eg "CIAO Logo". If logoimage is unset then this is the
    *    text that is used
    *
    *  . logourl, string, optional
    *
    *    If a logo is used (either text or an image) then make it a link to
    *    this location (e.g. '/ciao4.8/').
    *
    *  . indir - string, required
    *    full path to directory where to find the XML files
    *    must end in a /
    *
    *  . outdir - string, required
    *    full path to directory where to install file
    *    must end in a /
    *
    *  . version, string, required
    *    used to create title element in html block.
    *    If "CIAO 2.2.1", then version = "2.2.1"
    *    NOTE: don't 'trust' the contents of the version block
    * 
    * Notes:
    *  . we make use of EXSLT functions for date/time
    *    (see http://www.exslt.org/). 
    *    Actually, could have used an input parameter to do this
    * 
    *  . can some of these templates be amalgamated/abstracted?
    * 
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:str="http://exslt.org/strings"
  xmlns:date="http://exslt.org/dates-and-times"
  xmlns:func="http://exslt.org/functions"
  xmlns:exsl="http://exslt.org/common"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="date str func exsl extfuncs">

  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-ahelp_index" select="extfuncs:register-import-dependency('ahelp_index.xsl')"/>

  <!--* load in templates *-->
  <xsl:include href="ahelp_common.xsl"/>

  <xsl:output method="text"/>

  <xsl:param name="site" select="''"/>

  <xsl:param name="cssfile"/>
  <xsl:param name="navbarname" select='"ahelp"'/>
  <xsl:param name="searchssi"  select='"/incl/search.html"'/>

  <xsl:param name="logoimage" select='""'/>
  <xsl:param name="logotext"  select='""'/>
  <xsl:param name="logourl"   select='""'/>

  <xsl:param name="headtitlepostfix"  select='""'/>
  <xsl:param name="texttitlepostfix"  select='""'/>

  <xsl:param name="type"/>
  <xsl:param name="urlbase"/>
  <xsl:param name="ahelpindexfile"/>
  <xsl:param name="outdir"/>
  <xsl:param name="version"/>
  <xsl:param name="updateby"/>

  <xsl:variable name="indir"/>

  <!--* temporary hack for v1.21/2 of ahelp_common.xsl *-->
  <xsl:param name="url" select='""'/>


  <!--* not used: just to stop ahelp_common.xsl from complaining (or I've made a mistake ...) *-->
  <xsl:param name="depth" value="''"/>

  <!--*
      * Start processing here: "/"
      *   
      * start with the root node since want a 'pull' style approach
      *
      *-->
  <xsl:template match="/">

    <!--*
        * safety check: are all the required parameters defined/sensible
        *-->
    <xsl:call-template name="check-param">
      <xsl:with-param name="pname"   select="'type'"/>
      <xsl:with-param name="pvalue"  select="$type"/>
      <xsl:with-param name="allowed" select="$allowed-types"/>
    </xsl:call-template>

    <xsl:call-template name="check-param">
      <xsl:with-param name="pname"   select="'site'"/>
      <xsl:with-param name="pvalue"  select="$site"/>
      <xsl:with-param name="allowed" select="$allowed-sites"/>
    </xsl:call-template>

    <xsl:call-template name="check-param">
      <xsl:with-param name="pname"   select="'urlbase'"/>
      <xsl:with-param name="pvalue"  select="$urlbase"/>
    </xsl:call-template>
    <xsl:if test="substring($urlbase,string-length($urlbase))!='/'">
      <xsl:message terminate="yes">
 Error:
   urlbase parameter must end in a / character.
   urlbase=<xsl:value-of select="$urlbase"/>

      </xsl:message>
    </xsl:if>

    <xsl:call-template name="check-param">
      <xsl:with-param name="pname"   select="'outdir'"/>
      <xsl:with-param name="pvalue"  select="$outdir"/>
    </xsl:call-template>
    <xsl:if test="substring($outdir,string-length($outdir))!='/'">
      <xsl:message terminate="yes">
 Error:
   outdir parameter must end in a / character.
   outdir=<xsl:value-of select="$outdir"/>

      </xsl:message>
    </xsl:if>

    <xsl:call-template name="check-param">
      <xsl:with-param name="pname"   select="'version'"/>
      <xsl:with-param name="pvalue"  select="$version"/>
    </xsl:call-template>

    <!--*
        * check the logo parameters
        *-->
    <xsl:if test="$logoimage != '' and $logotext = ''">
      <xsl:message terminate="yes">
  Error: logotext is unset but logoimage is set to '<xsl:value-of select="$logoimage"/>'
      </xsl:message>
    </xsl:if>

    <!--*
        * Check that we have some data:
	*    ahelpindex/ahelplist/ahelp/site=$site
	*    ahelpindex/alphabet[@site=$site]
	*    ahelpindex/context[@site=$site]
	* We only need to check one, so try the alphabetical list
	*-->
    <xsl:if test="count(//ahelpindex/alphabet[@site=$site])=0">
      <xsl:message terminate="yes">
  Error: no ahelp files found for site='<xsl:value-of select="$site"/>'
      </xsl:message>
    </xsl:if>

    <!--* end of checks *-->

    <!--*
        * what pages do we create?
        *-->
    <xsl:call-template name="make-navbar"/>
    <xsl:call-template name="make-alphabet"/>
    <xsl:call-template name="make-context"/>

    <!--* and that's it *-->

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: navbar_ahelp_index.incl
      *
      * Since the output is "simple" we create a text file and
      * manually create all the tags (which is why there are so
      * many xsl:text calls around!!!)
      * As of CIAO 3.0 we use CSS to improve control of the look
      * of the navbar, and now include the CIAO logo
      *
      * We also add a title attribute to each ahelp link listing
      * the summary for that ahelp page
      *
      * After the CIAO 3.1 release added comments at the start/end
      * of the navbar to hide the contents from the ht://Dig search
      * engine used by the CXC (since this navbar contains all the
      * ahelp names then it messes up the search)
      *
      * This is different to the main navbar page, since it retains
      * the pre-CIAO 4.8 approach of using a dl to organise the
      * contents (CIAO 4.8 main navbars now use a list)
      *-->
  <xsl:template name="make-navbar">

    <!--* output filename to stdout *-->
    <xsl:variable name="filename" select="concat($outdir,'navbar_ahelp_index.incl')"/>
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="text">

      <xsl:text disable-output-escaping="yes">&lt;!--htdig_noindex--&gt;
&lt;div&gt;
</xsl:text>

      <!--* add the logo/link if required *-->
      <xsl:if test="$logotext != ''">
	<xsl:text disable-output-escaping="yes">&lt;p class="navimage"&gt;</xsl:text>

        <!--* link ? -->
	<xsl:if test="$logourl != ''">
	  <xsl:text disable-output-escaping="yes">&lt;a href="</xsl:text>
	  <xsl:value-of select="$logourl"/>
	  <xsl:text disaple-output-escaping="yes">"&gt;</xsl:text>
	</xsl:if>

	<!--* logo or text? *-->
	<xsl:choose>
	  <xsl:when test="$logoimage != ''">
	    <xsl:text disable-output-escaping="yes">&lt;img alt="[</xsl:text><xsl:value-of select="$logotext"/><xsl:text>]" src="</xsl:text><xsl:value-of select="$logoimage"/>"<xsl:text disable-output-escaping="yes">&gt;</xsl:text>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="$logotext"/>
	  </xsl:otherwise>
	</xsl:choose>

	<xsl:if test="$logourl != ''">
	  <xsl:text disaple-output-escaping="yes">&lt;/a&gt;</xsl:text>
	</xsl:if>

	<xsl:text disable-output-escaping="yes">&lt;/p&gt;</xsl:text>
      </xsl:if> <!--* $logotext != '' *-->

      <!--* navbar class is now inherited from parent td, not from this div *-->
      <!--* create the header links (within a dl list)*-->
      <xsl:text disable-output-escaping="yes">&lt;dl&gt;</xsl:text>
      <xsl:call-template name="add-navbar-qlinks"/>
      <xsl:call-template name="add-navbar-alphabet"/>
      <xsl:text disable-output-escaping="yes">&lt;/dl&gt;</xsl:text>
      <xsl:text disable-output-escaping="yes">&amp;nbsp;&lt;br&gt;</xsl:text>

      <!--* loop through each 'letter' (within another dl list) *-->
      <xsl:text disable-output-escaping="yes">&lt;dl&gt;</xsl:text>
      <xsl:for-each select="ahelpindex/alphabet[@site=$site]/term">

<xsl:text disable-output-escaping="yes">&lt;dt&gt;&lt;a class=&quot;heading&quot; name=&quot;navbar-</xsl:text>
	<xsl:value-of select="name"/>
<xsl:text disable-output-escaping="yes">&quot;&gt;</xsl:text>
	<xsl:value-of select="name"/>
<xsl:text disable-output-escaping="yes">&lt;/a&gt;&lt;/dt&gt;</xsl:text>

	<xsl:text disable-output-escaping="yes">&lt;dd&gt;</xsl:text>

	<!--*
	    * loop through each help file
            * - try and be clever if have multiple items with the
            *   same key but different contexts
	    *   have @samekey=1  => single match so can just use key
	    *                 2  => two matches, so either have to say
	    *                         "key (context)"
	    *                       OR we want to combine because context=sl.*/py.*
	    *       NOTE: the latter option is not supported yet
            *                 _  => error
            *-->
	<xsl:for-each select="itemlist/item">
	  <xsl:variable name="thisid"   select="@id"/>
	  <xsl:variable name="ahelpobj" select="/ahelpindex/ahelplist/ahelp[@id = $thisid]"/>
	  <xsl:if test="boolean($ahelpobj) = false()">
	    <xsl:message terminate="yes">
  Error: Unable to find ahelp info in ahelp index for
    key=<xsl:value-of select="$thiskey"/> context=<xsl:value-of select="$thiscon"/>
	    </xsl:message>
	  </xsl:if>

	  <xsl:choose>
	    <xsl:when test="$ahelpobj/@samekey = 1">
	      <xsl:call-template name="add-navbar-entry-key">
		<xsl:with-param name="ahelpobj" select="$ahelpobj"/>
	      </xsl:call-template>
	    </xsl:when>

	    <xsl:when test="$ahelpobj/@samekey = 2">
	      <xsl:variable name="contail" select="substring($ahelpobj/context,4)"/>
	      <xsl:choose>
		<xsl:when test="starts-with($ahelpobj/context,'sl.')">
		  <xsl:if test="count($ahelpobj/preceding-sibling::ahelp[key=$ahelpobj/key and context=concat('py.',$contail)]) = 0">
		    <xsl:call-template name="add-navbar-entry-key-slpy-context">
		      <xsl:with-param name="slobj" select="$ahelpobj"/>
		      <xsl:with-param name="context"  select="$contail"/>
		    </xsl:call-template>
		  </xsl:if>
		</xsl:when>
		<xsl:when test="starts-with($ahelpobj/context,'py.')">
		  <xsl:if test="count($ahelpobj/preceding-sibling::ahelp[key=$ahelpobj/key and context=concat('sl.',$contail)]) = 0">
		    <xsl:call-template name="add-navbar-entry-key-pysl-context">
		      <xsl:with-param name="pyobj" select="$ahelpobj"/>
		      <xsl:with-param name="context"  select="$contail"/>
		    </xsl:call-template>
		  </xsl:if>
		</xsl:when>
		<xsl:otherwise>
		  <xsl:call-template name="add-navbar-entry-key-context">
		    <xsl:with-param name="ahelpobj" select="$ahelpobj"/>
		  </xsl:call-template>
		</xsl:otherwise>
	      </xsl:choose>
	    </xsl:when>

	    <xsl:otherwise>
	      <xsl:message terminate="yes">
 ERROR: ahelp key=<xsl:value-of select="$ahelpobj/key"/> context=<xsl:value-of select="$ahelpobj/context"/> @samekey=<xsl:value-of select="$ahelpobj/@samekey"/>
	      </xsl:message>
	    </xsl:otherwise>
	  </xsl:choose>

	</xsl:for-each> <!--* itemlist/item *-->

	<xsl:text disable-output-escaping="yes">&amp;nbsp;&lt;br&gt;&lt;/dd&gt;</xsl:text>

      </xsl:for-each> <!--* alphabet[@site=$site]/term *-->

      <xsl:text disable-output-escaping="yes">&lt;/dl&gt;</xsl:text>

      <!--* create the header links (in a dl list) *-->
      <xsl:text disable-output-escaping="yes">&lt;dl&gt;</xsl:text>
      <xsl:call-template name="add-navbar-alphabet"/>
      <xsl:call-template name="add-navbar-qlinks"/>
      <xsl:text disable-output-escaping="yes">&lt;/dl&gt;</xsl:text>
      <xsl:text disable-output-escaping="yes">&lt;/div&gt;
</xsl:text> <!--* class=navbar *-->
	
      <xsl:text disable-output-escaping="yes">&lt;!--/htdig_noindex--&gt;
</xsl:text>

    </xsl:document>

  </xsl:template> <!--* name=make-navbar *-->

  <!--*
      * Add a link to the navbar to an ahelp entry; only the key is needed
      * here
      *-->
  <xsl:template name="add-navbar-entry-key">
    <xsl:param name="ahelpobj" select="''"/>

    <xsl:call-template name="add-link-to-text">
      <xsl:with-param name="title" select="concat('Ahelp (',$ahelpobj/context,'): ',$ahelpobj/summary)"/>
      <xsl:with-param name="url" select="concat($ahelpobj/page,'.html')"/>
      <xsl:with-param name="txt"><xsl:value-of select="$ahelpobj/key"/></xsl:with-param>
    </xsl:call-template> 
    <xsl:call-template name="add-br"/>

  </xsl:template> <!--* name=add-navbar-entry-key *-->

  <!--*
      * Add a link to the navbar to an ahelp entry; both the key
      * and context are needed here
      *-->
  <xsl:template name="add-navbar-entry-key-context">
    <xsl:param name="ahelpobj" select="''"/>

    <xsl:call-template name="add-link-to-text">
      <xsl:with-param name="title" select="concat('Ahelp (',$ahelpobj/context,'): ',$ahelpobj/summary)"/>
      <xsl:with-param name="url" select="concat($ahelpobj/page,'.html')"/>
      <xsl:with-param name="txt"><xsl:value-of select="concat($ahelpobj/key,' (',$ahelpobj/context,')')"/></xsl:with-param>
    </xsl:call-template> 
    <xsl:call-template name="add-br"/>

  </xsl:template> <!--* name=add-navbar-entry-key-context *-->

  <!--*
      * Add the actual text + link for a ahelp page with
      * a multi-language context.
      * Place Python first.
      *-->
  <xsl:template name="add-navbar-entry-lang">
    <xsl:param name="pyobj" select="''"/>
    <xsl:param name="slobj" select="''"/>

    <xsl:variable name="key" select="$slobj/key"/>

    <xsl:value-of select="concat($key,' - ')"/>
    <xsl:call-template name="add-link-to-text">
      <xsl:with-param name="title" select="concat('Ahelp (',$pyobj/context,'): ',$pyobj/summary)"/>
      <xsl:with-param name="url" select="concat($pyobj/page,'.html')"/>
      <xsl:with-param name="txt">py</xsl:with-param>
    </xsl:call-template> 
    <xsl:text> </xsl:text>
    <xsl:call-template name="add-link-to-text">
      <xsl:with-param name="title" select="concat('Ahelp (',$slobj/context,'): ',$slobj/summary)"/>
      <xsl:with-param name="url" select="concat($slobj/page,'.html')"/>
      <xsl:with-param name="txt">sl</xsl:with-param>
    </xsl:call-template> 
    <xsl:call-template name="add-br"/>
  </xsl:template> <!--* name=add-navbar-entry-lang *-->

  <!--*
      * Add a link to the navbar to an ahelp entry which has
      * multi-language support. Place Python first.
      * The ahelpobj sent in represents the sl.* version
      *-->
  <xsl:template name="add-navbar-entry-key-slpy-context">
    <xsl:param name="slobj" select="''"/>
    <xsl:param name="context"  select="''"/>

    <xsl:variable name="key" select="$slobj/key"/>
    <xsl:variable name="pyobj" select="$slobj/following-sibling::ahelp[key=$key and context=concat('py.',$context)]"/>

    <xsl:call-template name="add-navbar-entry-lang">
      <xsl:with-param name="pyobj" select="$pyobj"/>
      <xsl:with-param name="slobj" select="$slobj"/>
    </xsl:call-template>

  </xsl:template> <!--* name=add-navbar-entry-key-slpy-context *-->

  <!--*
      * Add a link to the navbar to an ahelp entry which has
      * multi-language support. Place Python first.
      * The ahelpobj sent in represents the py.* version
      *-->
  <xsl:template name="add-navbar-entry-key-pysl-context">
    <xsl:param name="pyobj" select="''"/>
    <xsl:param name="context"  select="''"/>

    <xsl:variable name="key" select="$pyobj/key"/>
    <xsl:variable name="slobj" select="$pyobj/following-sibling::ahelp[key=$key and context=concat('sl.',$context)]"/>

    <xsl:call-template name="add-navbar-entry-lang">
      <xsl:with-param name="pyobj" select="$pyobj"/>
      <xsl:with-param name="slobj" select="$slobj"/>
    </xsl:call-template>

  </xsl:template> <!--* name=add-navbar-entry-key-pysl-context *-->

  <!--*
      * create the "quick links" section of the navbar
      * - add a link to the main site "home page"
      * - this no-longer looks like the main navbar (as of CIAO 4.8)
      *   since that uses a ul rather than li
      *-->
  <xsl:template name="add-navbar-qlinks">

    <xsl:variable name="pretty-site"><xsl:choose>
      <xsl:when test="$site = 'ciao'">CIAO</xsl:when>
      <xsl:when test="$site = 'chips'">ChIPS</xsl:when>
      <xsl:when test="$site = 'sherpa'">Sherpa</xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
  ERROR: expected site to be ciao, chips, or sherpa, not '<xsl:value-of select="$site"/>'
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose></xsl:variable>

    <!--* link to the home page for the site IF there is no logo link *-->
    <xsl:if test="$logourl = ''">
      <xsl:text disable-output-escaping="yes">&lt;dt&gt;</xsl:text>
      <xsl:call-template name="add-link-to-text">
	<xsl:with-param name="url" select="'../index.html'"/> <!--* I do not think we have a valid depth parameter? *-->
	<xsl:with-param name="txt" select="concat('Home page (',$pretty-site,')')"/>
	<xsl:with-param name="class" select="'heading'"/>
	<xsl:with-param name="title" select="concat('The ',$pretty-site,' Home page')"/>
      </xsl:call-template>
      <xsl:text disable-output-escaping="yes">&lt;/dt&gt;</xsl:text>
    </xsl:if>

    <!--* links to the index pages *-->
    <xsl:text disable-output-escaping="yes">&lt;dt&gt;</xsl:text>
    <xsl:call-template name="add-link-to-text">
      <xsl:with-param name="url" select="'index.html'"/>
      <xsl:with-param name="txt" select="'Help pages (AHELP)'"/>
      <xsl:with-param name="class" select="'heading'"/>
      <xsl:with-param name="title" select="'Main Ahelp page'"/>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">&lt;/dt&gt;</xsl:text>

    <xsl:text disable-output-escaping="yes">&lt;dt&gt;</xsl:text>
    <xsl:call-template name="add-link-to-text">
      <xsl:with-param name="url" select="'index_alphabet.html'"/>
      <xsl:with-param name="txt" select="'List by alphabet'"/>
      <xsl:with-param name="class" select="'heading'"/>
      <xsl:with-param name="title" select="'Ahelp pages listed in alphabetical order'"/>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">&lt;/dt&gt;</xsl:text>

    <xsl:text disable-output-escaping="yes">&lt;dt&gt;</xsl:text>
    <xsl:call-template name="add-link-to-text">
      <xsl:with-param name="url" select="'index_context.html'"/>
      <xsl:with-param name="txt" select="'List by context'"/>
      <xsl:with-param name="class" select="'heading'"/>
      <xsl:with-param name="title" select="'Ahelp pages listed by context'"/>
    </xsl:call-template> 
    <xsl:text disable-output-escaping="yes">&lt;/dt&gt;</xsl:text>

  </xsl:template> <!--* name=add-navbar-qlinks *-->

  <!--*
      * create the "alphabetical links" section of the navbar
      *-->
  <xsl:template name="add-navbar-alphabet">

    <xsl:text disable-output-escaping="yes">&lt;dt&gt;&lt;span class=&quot;heading&quot;&gt;Jump to:&lt;/span&gt;&lt;/dt&gt;</xsl:text>

    <!--* links to the alphabetical sections below *-->
    <xsl:text disable-output-escaping="yes">&lt;dd&gt;</xsl:text>
    <xsl:for-each select="ahelpindex/alphabet[@site=$site]/term">
      <xsl:call-template name="add-link-to-text">
	<xsl:with-param name="url" select="concat('#navbar-',name)"/>
	<xsl:with-param name="txt" select="name"/>
	<xsl:with-param name="title" select="concat('Jump to the letter ',name)"/>
      </xsl:call-template><xsl:text> </xsl:text>
    </xsl:for-each>
    <xsl:text disable-output-escaping="yes">&lt;/dd&gt;</xsl:text>

  </xsl:template> <!--* name=add-navbar-alphabet *-->

  <!--* 
      * create: index_alphabet.html
      *-->
  <xsl:template name="make-alphabet">

    <xsl:variable name="pagename">index_alphabet</xsl:variable>
    <xsl:variable name="filename"><xsl:value-of select="$outdir"/><xsl:value-of select="$pagename"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
                  doctype-system="about:legacy-compat"
		  version="5.0" encoding="utf-8">
      
      <html lang="en">

	<xsl:call-template name="add-htmlhead">
	  <xsl:with-param name="title">Ahelp (alphabetical) - <xsl:value-of select="$headtitlepostfix"/></xsl:with-param>
	  <xsl:with-param name="pagename" select="$pagename"/>
	</xsl:call-template>

	<!--* add header and banner *-->
	<xsl:call-template name="add-header">
	  <xsl:with-param name="with-navbar" select="1"/>
	</xsl:call-template>

	  <!--// main div begins page layout //-->
	    <div id="main">

		<!--* the main text *-->
		<div id="content">
		  <div class="wrap">

	      <!--* process the contents *-->
	      <xsl:apply-templates select="ahelpindex/alphabet[@site=$site]"/>

		  </div>
		</div> <!--// close id=content //-->

		<div id="navbar">
		  <div class="wrap">
		    <a name="navtext"/>

		  <xsl:call-template name="add-navbar">
                    <xsl:with-param name="navbar" select="$navbarname"/>
		  </xsl:call-template>
		  </div>
		</div> <!--// close id=navbar //-->
		
	    </div> <!--// close id=main  //-->
	
	<!--* add the banner *-->
	<xsl:call-template name="add-footer"/>
	
	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>
      
    </xsl:document>
  </xsl:template> <!--* name=make-alphabet *-->

  <!--* add a set of 'jump to' links for the alphabetical list *-->
  <xsl:template name="add-alphabet-jump">
    <div class="qlinkbar">Jump to:
      <a title="Main Ahelp page" href="index.html">Main AHELP page</a> |
      <a title="List by context" href="index_context.html">Contextual List</a>
    </div>
  </xsl:template>

  <!--* add a set of 'jump to' links for the contextual list *-->
  <xsl:template name="add-context-jump">
    <div class="qlinkbar">Jump to:
      <a title="Main Ahelp page" href="index.html">Main AHELP page</a> |
      <a title="List by alphabet" href="index_alphabet.html">Alphabetical List</a>
    </div>
  </xsl:template>

  <!--*
      * Create the alphabetical index
      *
      * Output also depends on the value of $type.
      * It *may* be that we can get away with assuming this is always going to
      * have the correct site-specific alphabet list, but add separate rules to
      * ensure this (and it appears that we need that rule)
      *
      * I did have
      *   xsl:template match="alphabet[@site=$site]"
      * but 
      *   xsltproc was compiled against libxml 20628, libxslt 10121 and libexslt 813
      * complained (libxslt 10115 and earlier did not). Is this valid XSLT or not?
      * Decided to try and work around this rather than work out what should be
      * be going on.
      *
      * With further review/reqrite it may be that we should only ever be processing
      * alphabet nodes for which @site = $site anyway, which will avoid this sissue
      *-->
  <xsl:template match="alphabet">
    <xsl:if test="@site = $site">
      <xsl:call-template name="handle-alphabet"/>
    </xsl:if>
  </xsl:template> <!--* match=alphabet *-->

  <xsl:template name="handle-alphabet">

    <!--* title *-->
    <h2 class="pagetitle">Alphabetical List of Ahelp Files</h2>

    <!--* add text/links *-->
    <xsl:call-template name="add-alphabet-jump"/>
    <hr/>

    <!--* create the list of letters/links *-->
    <div class="navlinkbar">
      <p>
      <xsl:for-each select="term">
	<xsl:variable name="letter"
	  select="translate(name,
	  'abcdefghijklmnopqrstuvwxyz',
	  'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
	<a title="Jump to the letter {$letter}" href="#{$letter}"><xsl:value-of select="$letter"/></a>
	<xsl:text> </xsl:text>
      </xsl:for-each>
      </p>
    </div>

    <!--* begin the table *-->
    <table class="ahelptable">

      <!--* the header *-->
      <thead>
      <tr>
	<th><xsl:call-template name="add-nbsp"/><xsl:call-template name="add-nbsp"/><xsl:call-template name="add-nbsp"/></th>
	<th>Topic</th>
	<th>Context</th>
	<th>Summary</th>
      </tr>
      </thead>

      <tbody>
      <!--* loop through each 'letter' *-->
      <xsl:for-each select="term">
	
	<xsl:variable name="letter"
	  select="translate(name,
	  'abcdefghijklmnopqrstuvwxyz',
	  'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>

	<!--*
	    * loop through each help file
	    * - unlike navbar, don't need to bother about same
	    *   key but different contexts, since we give the context
	    *-->
	<xsl:for-each select="itemlist/item">
	  <xsl:variable name="thisid"   select="@id"/>
	  <xsl:variable name="ahelpobj" select="/ahelpindex/ahelplist/ahelp[@id = $thisid]"/>
	  <xsl:variable name="thiskey"  select="$ahelpobj/key"/>
	  <xsl:variable name="thiscon"  select="$ahelpobj/context"/>

	  <tr>

	    <!--* do we need to add the 'label' *-->
	    <xsl:if test="position() = 1">
	      <th valign="top" rowspan="{last()}">
		<a name="{$letter}"><xsl:value-of select="$letter"/></a>
	      </th>
	    </xsl:if>
	    
	    <!--* and the actual data *-->
	    <td valign="top">
	      <xsl:call-template name="add-table-bg-color"/>
	      <a href="{$ahelpobj/page}.html"><xsl:value-of select="$thiskey"/></a>
	    </td>
	    <td valign="top">
	      <xsl:call-template name="add-table-bg-color"/>
	      <a href="index_context.html#{$thiscon}"><xsl:value-of select="$thiscon"/></a>
	    </td>
	    <td>
	      <xsl:call-template name="add-table-bg-color"/>
	      <xsl:value-of select="$ahelpobj/summary"/>
	    </td>
	  </tr>

	</xsl:for-each> <!--* indexlist/index *-->
		  
	<!--* do we add a HR? *-->
	<xsl:if test="position() != last()">
	  <tr><td colspan="7"><hr/></td></tr>
	</xsl:if>
	
      </xsl:for-each> <!--* term *-->

      </tbody>
    </table>
    
    <!--* jump back links *-->
    <xsl:call-template name="add-alphabet-jump"/>
    
  </xsl:template> <!--* name=handle-alphabet *-->

  <!--* 
      * create: index_context.html (Web)
      *-->
  <xsl:template name="make-context">

    <xsl:variable name="pagename">index_context</xsl:variable>
    <xsl:variable name="filename"><xsl:value-of select="$outdir"/><xsl:value-of select="$pagename"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
                  doctype-system="about:legacy-compat"
		  version="5.0" encoding="utf-8">
      
      <html lang="en">

	<xsl:call-template name="add-htmlhead">
	  <xsl:with-param name="title">Ahelp (contextual) - <xsl:value-of select="$headtitlepostfix"/></xsl:with-param>
	  <xsl:with-param name="pagename" select="$pagename"/>
	</xsl:call-template>

	<!--* add header and banner *-->
	<xsl:call-template name="add-header">
	  <xsl:with-param name="with-navbar" select="1"/>
	</xsl:call-template>

	  <!--// main div begins page layout //-->
	    <div id="main">

		<!--* the main text *-->
		<div id="content">
		  <div class="wrap">

	      <!--* process the contents *-->
	      <xsl:apply-templates select="ahelpindex/context[@site=$site]"/>

		  </div>
		</div> <!--// close id=content //-->

		<div id="navbar">
		  <div class="wrap">
		    <a name="navtext"/>

		  <xsl:call-template name="add-navbar">
                    <xsl:with-param name="navbar" select="$navbarname"/>
		  </xsl:call-template>
		  </div>
		</div> <!--// close id=navbar //-->
		
	    </div> <!--// close id=main  //-->

	<!--* add the banner *-->
	<xsl:call-template name="add-footer"/>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>
      
    </xsl:document>
  </xsl:template> <!--* name=make-context *-->

  <!--*
      * Create the contextual index
      *
      * Output also depends on the value of $type
      * It *may* be that we can get away with assuming this is always going to
      * have the correct site-specific context list, but add separate rules to
      * ensure this
      *
      * I did have
      *   xsl:template match="context[@site=$site]"
      * but 
      *   xsltproc was compiled against libxml 20628, libxslt 10121 and libexslt 813
      * complained (libxslt 10115 and earlier did not). Is this valid XSLT or not?
      * Decided to try and work around this rather than work out what should be
      * be going on.
      *
      * With further review/reqrite it may be that we should only ever be processing
      * context nodes for which @site = $site anyway, which will avoid this sissue
      *-->
  <xsl:template match="context">
    <xsl:if test="@site = $site">
      <xsl:call-template name="handle-context"/>
    </xsl:if>
  </xsl:template> <!--* match=context *-->

  <xsl:template name="handle-context">

    <!--* title *-->
    <h2 class="pagetitle">Contextual List of Ahelp Files</h2>

    <!--* add text/links *-->
    <xsl:call-template name="add-context-jump"/>
    <hr/>

    <!--* create the list of concepts/links *-->
    <div class="navlinkbar">
      <p>
      <xsl:for-each select="term">
	<a title="Jump to context '{name}'" href="#{name}"><xsl:value-of select="name"/></a>

	<xsl:if test="position() != last()">
	  <xsl:text> | </xsl:text>
	</xsl:if>
      </xsl:for-each>
      </p>
    </div>

    <!--* begin the table *-->
    <table class="ahelptable">

      <!--* the header *-->
      <thead>
      <tr>
	<th>Context</th>
	<th>Topic</th>
	<th>Summary</th>
      </tr>
      </thead>

      <tbody>
      <!--* loop through each 'context' *-->
      <xsl:for-each select="term">

	<xsl:variable name="context" select="name"/>

	<!--*
	    * loop through each help file
	    * - unlike navbar, don't need to bother about same
	    *   key but different contexts since list context explicitly
	    *-->
	<xsl:for-each select="itemlist/item">
	  <xsl:variable name="thisid"   select="@id"/>
	  <xsl:variable name="ahelpobj" select="/ahelpindex/ahelplist/ahelp[@id = $thisid]"/>
	  <xsl:variable name="thiskey"  select="$ahelpobj/key"/>

	  <tr>
	    <!--* do we need to add the 'label' *-->
	    <xsl:if test="position() = 1">
	      <th valign="top" rowspan="{last()}"><a name="{$context}"><xsl:value-of select="$context"/></a></th>
	    </xsl:if>
	    
	    <!--* and the actual data *-->
	    <td valign="top">
	      <xsl:call-template name="add-table-bg-color"/>
	      <a href="{$ahelpobj/page}.html"><xsl:value-of select="$thiskey"/></a>
	    </td>

	    <td>
	      <xsl:call-template name="add-table-bg-color"/>
	      <xsl:value-of select="$ahelpobj/summary"/>
	    </td>
	  </tr>
	  
	</xsl:for-each> <!--* indexlist/index *-->
	
	<!--* do we add a HR? *-->
	<xsl:if test="position() != last()">
	  <tr><td colspan="5"><hr/></td></tr>
	</xsl:if>

      </xsl:for-each> <!--* ahelpindex/context/term *-->
      </tbody>
    </table>
    
    <!--* jump back links *-->
    <xsl:call-template name="add-context-jump"/>
    
  </xsl:template> <!--* name=handle-context *-->

  <!--* taken from helper.xsl *-->

  <xsl:template name="newline">
<xsl:text>
</xsl:text>
  </xsl:template>

  <!--*
      * for writing out a link to a text file: only needed to create
      * the navbar output file (where output format=text but want it to
      * include html)
      *
      * Parameters:
      *    url, string, required
      *    txt, string, required
      *    class, string, optional
      *    title, string, optional
      *-->
  <xsl:template name="add-link-to-text">
    <xsl:param name="url"/>
    <xsl:param name="txt"/>
    <xsl:param name="class"/>
    <xsl:param name="title"/>
    
    <xsl:text disable-output-escaping="yes">
&lt;a href=&quot;</xsl:text><xsl:value-of select="$url"/><xsl:text disable-output-escaping="yes">&quot;</xsl:text>

<xsl:if test="$class != ''">
<xsl:value-of select="concat(' class=&quot;',$class,'&quot;')"/>
</xsl:if>

<!--*
    * we know some summaries contain " and < characters so protect them
    *-->
<xsl:if test="$title != ''">
<xsl:variable name="ntitle"><xsl:call-template name="protect-a-title">
<xsl:with-param name="initial" select="$title"/></xsl:call-template></xsl:variable>
<xsl:value-of select="concat(' title=&quot;',$ntitle,'&quot;')"/>
</xsl:if>

<xsl:text>&gt;</xsl:text><xsl:value-of select="$txt"/><xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>

  </xsl:template> <!--* name=add-link-to-text *-->


  <!-- add the altrow class as necessary -->
  <xsl:template name="add-table-bg-color">
    <xsl:if test="@number mod 2 = 0">
      <xsl:attribute name="class">altrow</xsl:attribute>
    </xsl:if>
  </xsl:template>

  <!--* 
      * Given a title string, create the HTML head block
      *
      * input variables:
      *   title - string, required
      *   pagename - string, required
      *   withcss - 0 or 1, defaults to 1
      *-->
  <xsl:template name="add-htmlhead">
    <xsl:param name='title'/>
    <xsl:param name='pagename'/>
    <xsl:param name='withcss' select="1"/>

    <head>
      <title><xsl:value-of select="$title"/></title>

      <!--* add main stylesheet - if wanted *-->
      <xsl:if test="$withcss = 1">
	<link rel="stylesheet" title="Default stylesheet for CIAO-related pages" href="{$cssfile}"/>
	<link rel="stylesheet" title="Default stylesheet for CIAO-related pages" media="print" href="{$cssprintfile}"/>
      </xsl:if>

      <!-- canonical link -->
      <link rel="canonical" href="{concat($urlbase, 'ahelp/', $pagename, '.html')}"/>

      <xsl:call-template name="add-sao-metadata">
	<xsl:with-param name="title" select="normalize-space($title)"/>
      </xsl:call-template>

    </head>
  </xsl:template> <!--* add-htmlhead *-->

  <!--*
      * protect-a-title
      *
      * paramters:
      *   initial - string, required
      *
      * tries to convert ", <, and > to &quot;, &lt;, and &gt; in the string
      * (which is "returned"). Ideally would like to say soemthing like:
      *
      * <xsl:value-of select="concat(' title=&quot;',
      *   translate( translate( translate($title,'&lt;','&amp;lt;'), '&gt;','&amp;gt;'), '&quot;','&amp;quot;' ),
      *   '&quot;')"/>
      *
      * rather than this recursive loop but translate only does single-string replacement - ie
      * the above code just replaces ",<,> by &
      *
      *-->
  <xsl:template name="protect-a-title">
    <xsl:param name="initial"/>
    <xsl:call-template name="protect-a-title-loop">
      <xsl:with-param name="string" select="$initial"/>
      <xsl:with-param name="length" select="string-length($initial)"/>
      <xsl:with-param name="pos"    select="1"/>
    </xsl:call-template>
  </xsl:template> <!--* name=protect-a-title *-->

  <xsl:template name="protect-a-title-loop">
    <xsl:param name="string"/>
    <xsl:param name="length"/>
    <xsl:param name="pos"/>

    <xsl:if test="$pos &lt;= $length">

      <xsl:variable name="thischar" select="substring($string,$pos,1)"/>
      <xsl:choose>
	<xsl:when test='$thischar = &apos;&quot;&apos;'><xsl:text disable-output-escaping="yes">&amp;quot;</xsl:text></xsl:when>
	<xsl:when test='$thischar = "&lt;"'><xsl:text>&amp;lt;</xsl:text></xsl:when>
	<xsl:when test='$thischar = "&gt;"'><xsl:text>&amp;gt;</xsl:text></xsl:when>
	<xsl:otherwise><xsl:value-of select="$thischar"/></xsl:otherwise>
      </xsl:choose>

      <xsl:call-template name="protect-a-title-loop">
	<xsl:with-param name="string" select="$string"/>
	<xsl:with-param name="length" select="$length"/>
	<xsl:with-param name="pos"    select="1+$pos"/>
      </xsl:call-template>
    </xsl:if>

  </xsl:template> <!--* name=protect-a-title-loop *-->


</xsl:stylesheet> <!--* FIN *-->
