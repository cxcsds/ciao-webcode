<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!-- AHELP XML to HTML convertor using XSL Transformations -->

<!--* 
    * Recent changes:
    *  2007 Oct 16 DJB
    *    Removed support for type=dist
    *  v1.18 - fixed default setting of global hardcopy param
    *  v1.17 - strip space from PARA as well as SYNTAX blocks to clean a
    *          few things up.
    *  v1.16 - big change for CIAO 3.1: the stylesheet now either creates
    *          the soft or hard-copy version of the page, NOT both
    *          There is also support for the new more-CSS-friendly
    *          versions of ahelp_main/common.xsl.
    *  v1.15 - updated for the new scheme for creating ahelp pages
    *          [where the index-creationg is separated from the pages]
    *          url parameter now urlbase
    *  v1.14 - added searchssi parameter (format=web only)
    *  v1.13 - added cssfile parameter (format=web only)
    *  v1.12 - added bugs to quick links (just defines have-bugs variable here)
    *  v1.11 - pagename input param changed to outname, install to outdir
    *          added depth parameter (string containing '../'s and NOT a number)
    *          Updated maxlen to better match CIAO 3.0 ahelp (80 column display)
    *          Moved out a lot of code to ahelp_main.xsl (helps testing)
    *  v1.10 - corrected bugs/error links in the standard "bugs" section
    *   v1.9 - added support for format=dist
    *   v1.8 - added input parameter: updateby
    *   v1.7 - added hardcopy support for format=web; now uses ahelp_common.xsl
    *   v1.6 - fixed parameter table (header and data rows weren't in sync);
    *          greater hacks to the URL/text of a HREF block
    *   v1.5 - fixed See Also code; remove example numbers from text; format changes
    *          to the viewable HTML output; change asc to cxc in HREF blocks
    *   v1.4 - output back to ahelp/foo.html
    *   v1.3 - reworked the LINE handling (now a pull approach from SYNTAX) +
    *          output now to ahelp/foo/index.html not ahelp/foo.html [format=web]
    *   v1.2 - reworked: still needs work before usable
    *   v1.1 - original version (from /data/da/Docs/ahelp2html/)
    * 
    * We have two versions/flavours of HTML output:
    *   a) HTML for CIAO web page (http://cxc.harvard.edu/ciao/ahelp/foo.html)
    *   b) HTML used to create PDF for CIAO web site using htmldoc
    *      (page not seen by users; in fact it's deleted after PDF are created
    *       but that's external to this stylesheet)
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
    *  . hardcopy - integer, optional, default=0
    *    if 0 then create the "softcopy" version, if 1 then the "hardcopy"
    *    version.
    *
    *  . urlbase - string, required
    *    base URL of page [ie full URL without the trailing foo.html]
    *    (used when creating the hardcopy versions). Must end in a '/'
    *
    *  . updateby - string, required
    *    name of person publishing the page (output of whoami is sufficient)
    *
    *  . cssfile - string, only equired format=web
    *    url of CSS file for pages
    *
    *  . searchssi - string, default=/incl/search.html, required
    *      url of SSI file for the search bar
    *
    *  . outdir - string, required
    *    full path to directory where to install file
    *    must end in a /
    *    must NOT include the name of the ahelp file
    *    (ie for dmcopy it doesn't have the trailing 'dmcopy/')
    *
    *  . outname - string, required
    *    output name of page WITHOUT leading path or trailing .html
    *    the path is taken to be outdir
    *
    *  . depth - string, required
    *    what to stick in front of index.html to get back to the index.
    *
    *  . version, string, required
    *    used to create title element in html block.
    *    If "CIAO 2.2.1", then version = "2.2.1"
    *    NOTE: don't 'trust' the contents of the version block
    *
    *  . seealsofile, string, optional
    *    the name of the XML file (including the full path) that contains
    *    the "See Also" block. If not supplied we don't create a see also block
    *
    *  . bgcolor, string, optional (default=cccccc)
    *    a hex string giving the colour to use for the
    *    background of the syntax/equation/example text
    *    do not supply the leading #
    *
    *  . bocolor, string, optional (default=000000)
    *    as for bgcolor; colour of the border around the
    *    background/highlight colour
    *
    *
    * Notes:
    *  . As of CIAO 3.1 we have separated out the creation of the soft and
    *    hardcopy versions - ie you need to run the stylesheet twice and set
    *    the hardcopy flag to 1 to get the 'hardcopy' version. This is
    *    less efficient but it simplifies the stylesheets (and should make it
    *    simpler when we get to the point we can finally stop producing the
    *    hardcopy/PDF versions)
    *
    *  . we make use of EXSLT functions for date/time
    *    (see http://www.exslt.org/). 
    *    Actually, could have used an input parameter to do this
    * 
    *  . for search/replace, use a function obtained from
    *    http://www.exslt.org/str/functions/replace/
    *    (not an actual EXSLT function since not implemented in libxslt)
    * 
    *  . the DTD allows HREF nodes within LINE ones. This makes
    *    'normalizing' the LINE nodes to a "max" length of maxlen
    *    rather complicated. So for now, as we don't actually have
    *    any such nodesets, I don't handle the case (throws a warning
    *    so you know about it)
    * 
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:str="http://exslt.org/strings"
  xmlns:date="http://exslt.org/dates-and-times"
  xmlns:func="http://exslt.org/functions"
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="date str func exsl">

  <!--* load in templates (_main includes _common) *-->
  <xsl:include href="ahelp_main.xsl"/>

  <xsl:output method="text"/>

  <!--*
      * this is needed to get the output looking good
      * - the stripping of PARA is to allow us to find cases
      *   when a PARA block contains a single SYNTAX or EQUATION block
      *-->
  <xsl:strip-space elements="SYNTAX PARA"/>

  <!--* parameters to be set by stylesheet processor *-->
  <xsl:param name="hardcopy" select="0"/>

  <xsl:param name="cssfile"/>
  <xsl:param name="cssprintfile"/>
  <xsl:param name="type"/>
  <xsl:param name="urlbase"/>
  <xsl:param name="outdir"/>
  <xsl:param name="outname"/>
  <xsl:param name="version"/>
  <xsl:param name="seealsofile"/>
  <xsl:param name="updateby"/>
  <xsl:param name="depth" value="''"/>

  <xsl:param name="searchssi"   select='"/incl/search.html"'/>

  <!--*
      * since we need this at least once, maybe twice, cache the result
      * EXCEPT that I was using xsl:value-of select="document()"
      * which converted things to a string rather than keeping it as a
      * node set. Can't be bothered to fix:
      *-->
  <xsl:param name="seealso" select="document($seealsofile)/seealso"/>

  <!--*
      * max number of characters in an output "line"
      * - 'ahelp mkinstmap' suggests 72 but 'ahelp mkexpmap' suggests 71
      *-->
  <xsl:variable name="maxlen" select="72"/>

  <!--*
      * background colours:
      * perhaps we should just a single value for the background
      * colour, since that will probably be less confusing to the
      * reader.
      * see http://www.brobstsystems.com/colors.htm for a list
      * of so-called "safe" colours, although how much one can trust
      * this list I don't know
      * however, using their recommendation of only 00, 44, 66, 99, CC, and FF
      * values:
      *   #FFFFFF white
      *   #CCCCCC light grey    
      *   #999999 darker grey
      *   #000000 black
      *
      * but #999999 is too dark, so changed to #CCCCCC, and #CCCCCC to #E0E0E0
      * and now changed back to a single colour, #CCCCCC
      *
      * -->
  <xsl:param name="bgcolor">cccccc</xsl:param>
  <xsl:param name="bocolor">000000</xsl:param>

  <!--*
      * set up a few variables used to determine whether we need certain columns
      * in the parameter table
      * these have to be "global" variables since used in 2 templates
      * (well, could pass them through as parameters but that's too much work!)
      *-->
  <xsl:variable name="nparam"     select="count(//ENTRY/PARAMLIST/PARAM)"/>
  <xsl:variable name="have-ftype" select="count(//PARAM[@filetype])!=0"/>
  <xsl:variable name="have-def"   select="count(//PARAM[@def])!=0"/>
  <xsl:variable name="have-min"   select="count(//PARAM[@min])!=0"/>
  <xsl:variable name="have-max"   select="count(//PARAM[@max])!=0"/>
  <xsl:variable name="have-units" select="count(//PARAM[@units])!=0"/>
  <xsl:variable name="have-reqd"  select="count(//PARAM[@reqd])!=0"/>
  <xsl:variable name="have-stcks" select="count(//PARAM[@stacks])!=0"/>
  <xsl:variable name="have-aname" select="count(//PARAM[@autoname])!=0"/>

  <!--* stuff for handling the examples *-->
  <xsl:variable name="nexample" select="count(//ENTRY/QEXAMPLELIST/QEXAMPLE)"/>

  <!--*
      * currently these are only used to create the "quick links" bar
      * but they could be useful to other templates so stuck here
      *
      * why do I have xsl:variable above but xsl:param below?
      *-->
  <!--*** <xsl:param name="have-synopsis" select="count(//ENTRY/SYNOPSIS)!=0"/> ***-->
  <xsl:param name="have-desc"     select="count(//ENTRY/DESC)!=0"/>
  <xsl:param name="have-example"  select="$nexample!=0"/>
  <xsl:param name="have-param"    select="$nparam!=0"/>
  <xsl:param name="have-seealso"  select="$seealso != ''"/>
  <xsl:param name="have-bugs"     select="count(//ENTRY/BUGS)!=0"/>

  <xsl:variable name="url"        select="concat($urlbase,$outname,'.html')"/>

  <!--*
      * Start processing here: "/"
      *   
      * start with the root node since we may want to loop over
      * cxchelptopics multiple times
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
      <xsl:with-param name="pname"   select="'outname'"/>
      <xsl:with-param name="pvalue"  select="$outname"/>
    </xsl:call-template>
    <xsl:if test="contains($outname,'.html')">
      <xsl:message terminate="yes">
 Error:
   outname parameter contains .html
   outname=<xsl:value-of select="$outname"/>

      </xsl:message>
    </xsl:if>

    <!--* 
        * it's a bit late to check urlbase here since we
        * have already used it in setting up the variable url
        *-->
    <xsl:call-template name="check-param">
      <xsl:with-param name="pname"   select="'urlbase'"/>
      <xsl:with-param name="pvalue"  select="$urlbase"/>
      <xsl:with-param name="pvalue"  select="1"/>
    </xsl:call-template>
      
    <xsl:call-template name="check-param">
      <xsl:with-param name="pname"   select="'version'"/>
      <xsl:with-param name="pvalue"  select="$version"/>
    </xsl:call-template>

    <!--* end of checks *-->

    <!--*
        * what pages do we create?
        *-->

    <xsl:choose>
      <!--* pages for the web site (softcopy) *-->
      <xsl:when test="$hardcopy = '0'">
	<xsl:apply-templates name="cxchelptopics" mode="make-viewable"/>
      </xsl:when>

      <!--* the version from which we create the PDF *-->
      <xsl:when test="$hardcopy = '1'">
	<xsl:apply-templates name="cxchelptopics" mode="make-hardcopy"/>
      </xsl:when>

      <xsl:otherwise>
	<xsl:message terminate="yes">
 Error:
   Unrecognised value for hardcopy parameter: '<xsl:value-of select="$hardcopy"/>'
   Should be 0 or 1

	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>

    <!--* and that's it *-->

  </xsl:template> <!--* match=/ *-->
  
</xsl:stylesheet> <!--* FIN *-->
