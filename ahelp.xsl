<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* AHELP XML to HTML convertor using XSL Transformations
    * 
    * The stylesheet produces a text output - to STDOUT - listing the files it
    * has created (it uses xsl:document to create the HTML files). This is
    * because it used to create two different versions of the file: one for
    * the web site and a temporary one for use in generating PDF files. The
    * latter is no longer produced but we leave the text output for now.
    *   
    * User (ie by the stylesheet processor) defineable parameters:
    *  . type - string, required
    *    one of "live", "test", or "trial"
    *      determines where the HTML files are created
    *      trial is a "developer only" value
    *
    *  . urlbase - string, required
    *    base URL of page [ie full URL without the trailing foo.html]
    *    Must end in a '/'.
    *    NOTE: THIS MAY NO LONGER BE NEEDED NOW WE DO NOT GENERATE PDF
    *      VERSIONS (UNLESS WE WANT TO ADD IT TO THE HTML AND HIDE IT
    *      FROM USERS USING CSS?)
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
    * Notes:
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
  xmlns:djb="http://hea-www.harvard.edu/~dburke/xsl/"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="date str func exsl djb extfuncs">

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

  <!--* Later on we check that this parameter is set *-->
  <xsl:param name="storageloc" select="''"/>
  <xsl:variable name="storageInfo" select="djb:read-if-set($storageloc)"/>

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
  <xsl:param name="have-bugs"     select="count(//ENTRY/BUGS)!=0"/> <!-- FIX THIS as depends on the site -->

  <!-- only need to worry about this for site=ciao? -->
  <xsl:param name="bugs-path"><xsl:value-of 
	select="concat($storageInfo//dir[@site=$site],'bugs/',
                       $outname, '.slug.xml')"/></xsl:param>
  <xsl:param name="bugs-contents" select="extfuncs:read-file-if-exists($bugs-path)"/>
  <xsl:param name="have-bugs-external" select="count($bugs-contents/slug) != 0"/>

  <xsl:param name="relnotes-path"><xsl:value-of 
	select="concat($storageInfo//dir[@site=$site],'releasenotes/ciao_',
                       $version, '.', $outname, '.slug.xml')"/></xsl:param>
  <xsl:param name="relnotes-contents" select="extfuncs:read-file-if-exists($relnotes-path)"/>
  <xsl:param name="have-relnotes" select="count($relnotes-contents/slug) != 0"/>

  <!-- used for the canonical link and the URL bar (hard copy) -->
  <xsl:variable name="url" select="concat($urlbase,'ahelp/', $outname,'.html')"/>

  <!--*
      * Start processing here: "/"
      *   
      * start with the root node since we may want to loop over
      * cxchelptopics multiple times (NOTE: this is no longer
      * true but leave as is for now).
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

    <xsl:call-template name="check-param">
      <xsl:with-param name="pname"   select="'storageloc'"/>
      <xsl:with-param name="pvalue"  select="$storageloc"/>
    </xsl:call-template>

    <!--* end of checks *-->

    <xsl:apply-templates name="cxchelptopics"/>

    <!--* and that's it *-->

  </xsl:template> <!--* match=/ *-->
  
  <!--*
      * Returns the document if set - as a node set - otherwise
      * the empty string.
      *-->
  <func:function name="djb:read-if-set">
    <xsl:param name="filename" select="''"/>
    <xsl:choose>
      <xsl:when test="$filename != ''"><func:result select="document($filename)"/></xsl:when>
      <xsl:otherwise><func:result/></xsl:otherwise>
    </xsl:choose>
  </func:function>

</xsl:stylesheet> <!--* FIN *-->
