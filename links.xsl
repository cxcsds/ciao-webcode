<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * attempt to provide a common stylesheet for links
    *
    * Recent changes:
    *
    * 2008 Aug 26 ECG
    *    download link version is taken from version tag in page,
    *    not hardcoded
    * 2008 Apr 24 ECG
    *    distinguish between why links in CIAO and CSC sites
    *
    * 2008 Feb 20 ECG
    *    put back beta site refs that are at least needed for sherpabeta
    *
    * 2008 Jan 30 ECG
    *    xsl:choose added to ahelp section so that sherpa links point
    *	 to /sherpabeta/; removed some old beta site refs that aren't
    *	 needed any longer.
    *
    * 2007 Dec 04 ECG
    *    changed version in download link to ciao4.0
    * 2007 Nov 01 ECG
    *    changed version in download link to ciao4b3
    * 2007 Oct 31 DJB
    *    ahelp tag handling is now improved for pages with context=sl.*/py.*
    * 2007 Oct 29 DJB
    *    add support for proglang attribute for threadlink
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    * 2007 Oct 16 DJB
    *   Updated to account for ahelp files now existing under ciao,
    *   sherpa, and chips web sites
    *  v1.81 - Links for chips site: faq, ahelp, ahelppage
    *  v1.80 - changed version in download link to ciao4b2
    *  v1.79 - changed version in download link to ciao4b1
    *  v1.78 - typo in POF title attribute ("Proposer's" to "Proposers'")
    *  v1.76 - check that page attribute of bug tag doesn't contain
    *	       ".html" (using check-page-for-no-html)
    *  v1.75 - revised "bug" link code to work in both CIAO and Sherpa
    *	       sites (and presumably anywhere else in CIAODOC)
    *  v1.70 - removed a reference to "bugs_redesign" leftover from
    *	       testing
    *  v1.69 - created a "bug" link; primarily for use in building the
    *	       bug list index
    *  v1.68 - manualpage: corrected a probable error highlighted in the
    *          libxml2.6.13 upgrade (@foo != '' if foo is not defined)
    *          This MAY cause problems elsewhere [fix also works with old
    *          libxml2 version]
    *  v1.67 - another 'we need a DTD/schema' change: flag item attibutes in
    *          dictionary tags
    *  [note: not sure when the version numbers got out of step]
    *  v1.65 - for icxc site: buglink tag to link to bug
    *  v1.64 - minor change to list attributes of an empty tag (makes finding
    *          the offending tag easier)
    *  v1.63 - fix to warning message for cxclink vs threadpage/link usage
    *  v1.62 - add-text-styles no-longer checks for empty content, we
    *          have to do it here. Also updated many link tags to process
    *          their contents rather than just copy the text: they need the
    *          depth parameter set (or we clean up the depth-handling logic!)
    *  v1.61 - major change with the way styles are added to links:
    *          much better
    *  v1.60 - Actually, we no longer need reglink here, moved to
    *          register_live.xsl
    *  v1.60 - reglink does not need to create 2 versions
    *  v1.59 - v1.58 fix: CALDB and ATOMDB sites do not register
    *  v1.58 - download tag now set up for CIAO 3.1 arrangement
    *          - link either to /ciao/download/[index.html#id]
    *            or /cgi-gen/ciao/download_ciao_{@type}.cgi
    *  v1.57 - added in 1.55.1.1 branch - title attribute for ahelp
    *          [synopsis] links now include the context of the page
    *          plus parameter title string now contains parameter name
    *          plus changed attribute order to make testing easier
    *  v1.56 - ahelp/parameter links now include parameter synopsis
    *          (and die if it doesn't exist)
    *  v1.55 - added title attribute to faq/dictionary/pog/analysis
    *          guide/helpdesk links (just says faq/dictionary/etc)
    *  v1.54 - ahelp links now have a title atribute == ahelp summary
    *  v1.53 - added id attriute to scriptpage
    *  v1.52 - ahelppage: added type attribute ("main", "alphabet", or "context")
    *          to choose which index page to link to; also it now has an id attribute
    *  v1.51 - reglink links: moved tt style outside of a so that a:hover
    *          works in konqueror (should ensure for other links too, although
    *          those that use start-styles are okay)
    *  v1.50 - more manual tag updates for sherpa manual
    *  v1.49 - refined check added in 1.48
    *  v1.48 - added download_ciao_reg text to cxclink test (use download tag instead)
    *  v1.47 - manual/manualpage: updated to allow sherpa site
    *  v1.46 - script template now a wrapper around create-script-link (so
    *          that the scriptlist tag in myhtml.xsl can work easily)
    *  v1.45 - corrected scriptpage link to use correct scheme (which has
    *          been used for some time; oops)
    *  v1.44 - fix to helpdesk tag plus swapped order of attributes for tests
    *  v1.43 - faq link now has optional site attribute
    *          removed use of http://cxc.harvard.edu/ from test site
    *  v1.42 - add class="helplink" to many links
    *          - picked up by v1.41 helper.xsl stylesheet
    *  v1.41 - complains if ahelppage attribute has a name attribute
    *  v1.40 - < to &lt; in an xsl:message block for ahelp tag
    *  v1.39 - updating ahelp support for CIAO 3.0: added context attribute
    *          and using ahelpindexfile variable. If no name attribute must
    *          use ahelppage tag instead
    *          If ahelp tag is used initial/master stylesheet must define ahelpindexfile
    *          variable
    *  v1.38 - pog links now take you to /proposer/POG/ [+ revert v1.37 changes]
    *  v1.37 - pog links now take you to the live site if on test site
    *  v1.36 - ChaRT test site is now on asc-bak: some code simplifoed
    *  v1.35 - and more ...
    *  v1.34 - more fixes for threadlink...
    *  v1.33 - band-aid for threadlink id="foo" problem. Could do with more thought/rework
    *  v1.32 - removed a warning from extlink if site=icxc
    *  v1.31 - added icxclink for site=icxc only; fixed faq bug for site!=ciao
    *  v1.30 - to be consistent: threadlink takes you to cxc not asc-bak
    *  v1.29 - more threadlink changes: if from chart go to asc-bak, 
    *          if to chart then use iCXC (for @site, test!= live)
    *  v1.28 - fixed threadlink for @site!=$site and test!=live (needed an extra /sds)
    *  v1.27 - more warnings/errors if mis-use (partially making up for no DTD)
    *  v1.26 - aguide now complains if name attribute is present
    *  v1.25 - ahelp now complains if name attribute ends in .html
    *  v1.24 - documents_ahelp.html is now ahelp/
    *  v1.23 - threadlink tag: allow 'no name' use from include files
    *  v1.22 - changed dictionary to use new location
    *  v1.21 - added why & aguide tags
    *  v1.20 - changed faq to use new location
    *  v1.19 - added support for reglink
    *  v1.18 - dpguide links to top level dir now
    *  v1.17 - removed extlink image (ie external-link-image template) + fix to threadlink/site
    *  v1.16 - moved imglink template to ciao_thread.xsl
    *  v1.15 - bug fix for v1.14
    *  v1.14 - arrow_right_blue is now looked for in imgs/ not gifs/
    *  v1.13 - amalgamated thread code
    *  v1.12 - thread links now go to the new scheme
    *  v1.11 - added caveat tag [link to ciao pages only]
    *  v1.10 - added dpguide tag [link to ciao pages only]
    *   v1.9 - only get the "external link image" for pages not on cxc.harvard.edu
    *          this means that some of the "depth-pass-thru" code is no-longer required
    *
    * Ahelp support:
    *   If a page uses the ahelp tag then the master/initial/control stylesheet
    *   needs to include something like
    *
    *  . ahelpindex=full path to ahelp index file created by mk_ahelp_setup.pl
    *    something like /data/da/Docs/ciaoweb/published/ciao3/live/ahelp/ahelpindex.xml
    *    Used to work out the ahelp links
    *

  <xsl:param name="ahelpindex"  select='""'/>
  <xsl:variable name="ahelpindexfile" select="document($ahelpindex)"/>

    * 
    * Thread support:
    *   We have added support for the proglang attribute to threadlink tags, and
    *   the /thread/info/proglang tags to thread pages. This complicates thread
    *   linking, since we have to check the storage location for the given thread
    *   to see if the thread has language-specific versions.
    * 
    * Thoughts:
    * - a number of links go to the 'index' page (eg ahelp)
    *   when no attribute is given whereas some tags have a separate
    *   tag for this (manual and manualpage).
    *   We could have a uniform look by making ahelp, faq, dictionary, pog, ??
    *   have separate tags (ahelppage, ...) to go to the index page
    *   - is this a good consistency gain?
    *   - have implemented this for ahelp tag
    *
    * - a number of tags are essentially the same (eg dpguide, caveat, aguide, why)
    *   so they should all be thin wrappers around a single template
    *
    * To do:
    *   We link to /ciao/... or /$site/... when we may want to go to the
    *   beta version of that page instead. How do we handle this?
    *   Perhaps we need to consider ciaobeta a new site, etc.
    *-->

<!--* 
    * handle links
    *
    * Requires:
    *   "global" variable site - what set of pages are we working with (eg ciao, chart)
    *
    * To do:
    *   complete conversion to using the site variable
    *   work out how to handle tags like <faq/> when site=chart
    *     - do we have the same document name in different sites or hard-code the
    *       names in the transform (or pass in as a variable)?
    *       [for faq have added a site attribute but it's not a good solution
    *        since this code needs changing when a new faq page is added to
    *        a site]
    *   add id attribute to the link constructs (see cxclink for an example)
    *  
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:func="http://exslt.org/functions"
  xmlns:djb="http://hea-www.harvard.edu/~dburke/xsl/"
  extension-element-prefixes="exsl func djb">

  <!--* we don't like "a" tags! *-->
  <xsl:template match="a|A">
    <xsl:message terminate="yes">
      Please convert all &lt;<xsl:value-of select="name()"/>&gt; tags to one of:
      threadlink, cxclink, imglink, extlink, id, helpdesk, manual, pog, caveat, ...
      The tag contains:
      <xsl:value-of select="."/>
    </xsl:message>
  </xsl:template> <!-- a|A -->

  <!--*
      * Link to the ahelp index page. If the site attribute is given
      * then link to that site's index page, otherwise use the local
      * index if in chips or sherpa sites, otherwise fall back to the
      * CIAO site ahelp index.
      *
      * The only attributes it uses are the "style" attributes
      * - we complain if there's a name attribute to catch people
      *   using it wrongly
      *
      * Attribute:
      *   @type - optional, string: "main", "alphabet", or "context"
      *     defaults to "main". do we link to index.html,
      *     index_alphabet.html, or index_context.html
      *
      *   @id - optional, string
      *     the anchor on the page to link to
      *
      *   @site - optional, string
      *     the site for the index page (should be "ciao", "sherpa", or
      *     "chips")
      *
      *-->
  <xsl:template match="ahelppage">

    <!--* safety check *-->
    <xsl:if test="boolean(@name)">
      <xsl:message terminate="yes">

 ERROR: you have an ahelppage tag with a name attribute
   (set to <xsl:value-of select="@name"/>) - I think you
   should be using the ahelp tag to link to an ahelp
   page.

      </xsl:message>
    </xsl:if>

    <!--* ohh for a DTD *-->
    <xsl:if test="boolean(@type) and @type!='main' and @type!='alphabet' and @type!='context'">
      <xsl:message terminate="yes">

 ERROR:
   In the <xsl:value-of select="$site"/> site, the type attribute of ahelppage tag must be one of:
       main alphabet context
   You have a type of "<xsl:value-of select="@type"/>"

      </xsl:message>
    </xsl:if>

    <!--*
        * complicated mess to work out where to link to
        * copied from FAQ section of XSL
        * - if have a site attribute, then use that
        * - otherwise if site=ciao use that
        * - otherwise if site=chips use that
        * - otherwise if site=sherpa use that
        * - otherwise assume the CIAO site
        *
        *-->
    <xsl:variable name="hrefstart"><xsl:choose>
	<xsl:when test="boolean(@site)"><xsl:value-of select="concat('/',@site,'/ahelp/')"/></xsl:when>
	<xsl:when test="$site != 'ciao' and $site != 'chips' and $site != 'sherpa' and $site != 'ciaobeta' and $site != 'chipsbeta' and $site != 'sherpabeta'">/ciao/ahelp/</xsl:when>
	<xsl:otherwise><xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="0"/>
	    <xsl:with-param name="dirname" select="'ahelp/'"/>
	  </xsl:call-template></xsl:otherwise>
      </xsl:choose></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>

	  <xsl:attribute name="class">
	    <xsl:text>helplink</xsl:text></xsl:attribute>

	  <xsl:attribute name="title">
	    <xsl:text>Ahelp index (</xsl:text>
	    <xsl:call-template name="process-site-name-for-text"/>
	    <xsl:text>)</xsl:text></xsl:attribute>

	  <xsl:attribute name="href">
	  <xsl:value-of select="$hrefstart"/>

	  <xsl:choose>
	      <xsl:when test="@type = 'alphabet'">index_alphabet.html</xsl:when>
	      <xsl:when test="@type = 'context'">index_context.html</xsl:when>
	    </xsl:choose><xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if></xsl:attribute>

	  <!--* text *-->
	  <xsl:choose>
	    <xsl:when test=".=''">Ahelp page</xsl:when>
	    <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
	  </xsl:choose>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* ahelppage *-->

  <!--*
      * The context node either contains a site attribute or we use the
      * $site global symbol.
      *-->
  <xsl:template name="process-site-name-for-text">
    <xsl:variable name="out"><xsl:choose>
      <xsl:when test="boolean(@site)"><xsl:value-of select="@site"/></xsl:when>
      <xsl:when test="$site != 'ciao' and $site != 'chips' and $site != 'sherpa'">CIAO</xsl:when>
      <xsl:otherwise><xsl:value-of select="$site"/></xsl:otherwise>
    </xsl:choose></xsl:variable>
    <xsl:variable name="outlc" select="translate($out,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/>
    <xsl:choose>
      <xsl:when test="$outlc = 'ciao' or $outlc = 'ciaobeta'">CIAO</xsl:when>
      <xsl:when test="$outlc = 'sherpa' or $outlc = 'sherpabeta'">Sherpa</xsl:when>
      <xsl:when test="$outlc = 'chips' or $outlc = 'chipsbeta'">ChIPS</xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
 Expected site=ciao, sherpa, or chips but sent '<xsl:value-of select="$outlc"/>'
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--*
      * handle ahelp tags:
      * 
      * Attributes:
      *   name - string, required
      *     the ahelp 'key'
      *   context - string, optional
      *     the ahelp context
      *
      *   'ahelp slang print' has a key of print and context of slang
      *
      *   id - string, optional
      *     part of the ahelp file to link to - not for parameters.
      *     Also see param attribute.
      *   param - string, optional
      *     link to the description of this parameter - do not combine with id
      *     Also see id attribute.
      *
      *   em/tt/strong - boolean, optional
      *     if true, link text is set to these styles
      *   uc - boolean, optional
      *     if true set the link text to upper case
      *
      * As of CIAO 3.0 you can no longer use this tag without a name
      * attribute. To link to the ahelp index pages use the ahelppage tag
      * [we die with an error message if name key does not exist]
      *
      * We use the ahelp index file created by the ahelp publishing code to
      * map between key/context values and the HTML file name. We also use
      * this file to ensure that the key is a valid one (and that there
      * aren't multiple matches), as well as to determine what site the
      * ahelp page belongs to.
      *
      * - just after CIAO 3.0 release we added the summary for the ahelp
      *   page as a title attribute: this is displayed by modern browsers
      *   as a tool tip, but not by netscape 4
      *   Now added parameter SYNOPSIS for parameter links
      *
      * I explicitly check for site attributes and die to make sure we 
      * clean up the input documents (all part of the move to per-site
      * ahelp files in the CIAO 4 series of releases).
      *
      * In CIAO 4 we have added the $proglang variable which, if set,
      * is used to determine which of the context=sl.*/py.*  files
      * to link to. If $proglang is not set and you have context=sl.*/py.*
      * matches, we automatically link to both. 
      *-->


  <xsl:template match="ahelp">

    <!--* temporary check for the site attribute, as should not be used *-->
    <xsl:if test="boolean(@site)=true()">
      <xsl:message terminate="yes">
 ERROR: ahelp link contains site='<xsl:value-of select="@site"/>' attribute
   which should not be needed. Consult with Doug (after deleting the attribute
   and seeing if things work correctly).
      </xsl:message>
    </xsl:if>

    <!--* safety check for old pages *-->
    <xsl:if test="boolean(@name)=false()">
      <xsl:message terminate="yes">

 ERROR: as of CIAO 3.0 you can no longer use &lt;ahelp/> to link to
   the ahelp index page. You must use &lt;ahelppage/> instead.

      </xsl:message>
    </xsl:if>

    <xsl:if test="$ahelpindexfile = ''">
      <xsl:message terminate="yes">

 ERROR: see Doug as you have a ahelp tag but no ahelpindex information

      </xsl:message>
    </xsl:if>

    <!--*
        * find the matching entry:
        *   search on either
        *     name
        *   or
        *     name and context
        *   attributes, which makes the following a bit of a mess and
        *   not partcularly efficient
        * 
        * Could just output 'ahelp foo' if we don't know foo - ie with no
        * link. This would allow pages to be published before the ahelp
        * file makes it into the database (still print a warning and
        * only do this for no matches: multiple matches would still die)
        * 
        * note: looks like we can't say @name on the RHS of tests in XPATH
	* and get it to refer to the value of the name attribute of the
	* current context node (ie that node that is current before the
	* XPATH statement is evaluated), hence the introduction of the
	* $name variable
        *-->
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="namematches" select="$ahelpindexfile//ahelp[key=$name]"/>
    <xsl:variable name="num" select="count($namematches)"/>

    <xsl:if test="$num=0">
	<xsl:message terminate="yes">

 ERROR: have ahelp tag with unknown name of <xsl:value-of select="$name"/> 

      </xsl:message>
    </xsl:if>

    <!--*
        * Hack to link to both sl.* and py.* versions of a file if they
	* exist and $proglang is not set.
	*-->
    <xsl:variable name="have-sl-py-context"
		  select="$num = 2 and
			  (substring($namematches[1]/context,1,3) = 'sl.' or substring($namematches[1]/context,1,3) = 'py.')
			  and
			  (substring($namematches[2]/context,1,3) = 'sl.' or substring($namematches[2]/context,1,3) = 'py.')"/>

    <xsl:choose>
      <xsl:when test="$have-sl-py-context and $proglang = '' and boolean(@context)=false()">
	<xsl:call-template name="add-ahelp-multiple-context">
	  <xsl:with-param name="name" select="$name"/>
	  <xsl:with-param name="namematches" select="$namematches"/>
	  <xsl:with-param name="num" select="$num"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="add-ahelp-single-context">
	  <xsl:with-param name="name" select="$name"/>
	  <xsl:with-param name="namematches" select="$namematches"/>
	  <xsl:with-param name="num" select="$num"/>
	  <xsl:with-param name="have-sl-py-context" select="$have-sl-py-context"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* ahelp *-->

  <!--*
      * An ahelp link to a single file (ie not to both sl.* and py.*
      * versions of the same ahelp file).
      *
      * For development versions we do not require that the ahelp file is present
      * (a screen message will be displayed if it is not), but for the live
      * version the ahelp file must have already been published.
      *-->
  <xsl:template name="add-ahelp-single-context">
    <xsl:param name="name"/>
    <xsl:param name="namematches"/>
    <xsl:param name="num"/>
    <xsl:param name="have-sl-py-context"/>

    <xsl:variable name="context"><xsl:choose>
	<xsl:when test="boolean(@context)"><xsl:value-of select="@context"/></xsl:when>
	<xsl:when test="$num=1"><xsl:value-of select="$namematches/context"/></xsl:when>

	<!--*
	    * Handle sl/py.* versions when $proglang is set. It is a bit cumbersome.
	    *-->
	<xsl:when test="$proglang != '' and $have-sl-py-context">
	  <xsl:value-of select="$namematches[substring(context,1,2)=$proglang]/context"/>
	</xsl:when>

	<xsl:otherwise>
	  <xsl:message terminate="yes">

 ERROR: have ahelp tag with name of <xsl:value-of select="$name"/>
   that matches <xsl:value-of select="$num"/> contexts.
   You need to add a context attribute to distinguish between them.

	  </xsl:message>
	</xsl:otherwise>
      </xsl:choose></xsl:variable>
    
    <!--*
	* should only have 0 or 1 matches here; the code has become somewhat
	* unwieldly as we now support publishing to the test/devel sites
	* when the ahelp file is not present. This code should be
	* refactored
	*-->
    <xsl:variable name="matches" select="$namematches[context=$context]"/>
    <xsl:choose>
      <xsl:when test="count($matches)!=1">
	<xsl:choose>
	  <xsl:when test="$type='live'">
	    <xsl:message terminate="yes">
 ERROR: unable to find an ahelp match for
   name=<xsl:value-of select="$name"/> context=<xsl:value-of select="$context"/>

	    </xsl:message>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:message terminate="no">
 WARNING: unable to find a ahelp match for
   name=<xsl:value-of select="$name"/> context=<xsl:value-of select="$context"/>
   This ahelp file must be published before this page will display on the live site!

	    </xsl:message>
	    <xsl:apply-templates/>
	    <xsl:value-of select="concat('{*** ahelp link to key=',$name,' context=',$context,' ***}')"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>

      <xsl:otherwise>

	<!--* what site is the ahelp page on? *-->
	<xsl:variable name="ahelpsite" select="$matches/site"/>
	
	<!--*
	    * if this is a parameter link then check we know about this parameter
	    *-->
	<xsl:variable name="paramname" select="@param"/>
	<xsl:variable name="parammatch" select="$matches/parameters/parameter[name=$paramname]"/>
	
	<xsl:if test="boolean(@param)">
	  <xsl:if test="count($parammatch)!=1">
	    <xsl:message terminate="yes">
	      
 ERROR: ahelp unable to find parameter=<xsl:value-of select="@param"/> for
   name=<xsl:value-of select="$name"/> context=<xsl:value-of select="$context"/>

	    </xsl:message>
	  </xsl:if>
	</xsl:if>

	<!--*
	    * The ahelp page is either in this site or another one
	    *-->
	<xsl:variable name="hrefstart"><xsl:choose>
	  <xsl:when test="$site != $ahelpsite">
	    <xsl:value-of select="concat('/',$ahelpsite,'/ahelp/')"/>
	  </xsl:when>
	  
	  <xsl:otherwise><xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="0"/>
	    <xsl:with-param name="dirname" select="'ahelp/'"/>
	  </xsl:call-template></xsl:otherwise>
	</xsl:choose></xsl:variable>
	
	<!--* process the contents, surrounded by styles *-->
	<xsl:call-template name="add-text-styles">
	  <xsl:with-param name="contents">
	    <a>
	      <xsl:attribute name="class">helplink</xsl:attribute>
	      
	      <!--*
		  * Add the summary as a title attribute. There should be
		  * a summary tag for all ahelp pages, but use an if
		  * statement in case one is missing.
		  * 
		  * If we are linking to a parameter, use that synopsis
		  * instead 
		  *
		  * NOTE: add the context if including summary 
		  *-->
	      
	      <xsl:choose>
		<xsl:when test="count($parammatch)=1">
		  <xsl:attribute name="title">Ahelp (<xsl:value-of select="@name"/><xsl:text> </xsl:text><xsl:value-of select="$paramname"/><xsl:text> parameter)</xsl:text>
		<xsl:if test="$parammatch/synopsis != ''">
		  <xsl:text>: </xsl:text><xsl:value-of select="$parammatch/synopsis"/>
		</xsl:if>
		  </xsl:attribute>
		</xsl:when>

		<xsl:when test="$matches/summary!=''">
		  <xsl:attribute name="title">Ahelp (<xsl:value-of select="$context"/>): <xsl:value-of select="$matches/summary"/></xsl:attribute>
		</xsl:when>
	      </xsl:choose>
	      
	      <xsl:attribute name="href">
		<xsl:value-of select="$hrefstart"/>
		<xsl:value-of select="$matches/page"/>
		<xsl:text>.html</xsl:text>
		<xsl:choose>
		  <xsl:when test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:when>
		  <xsl:when test="boolean(@param)">#plist.<xsl:value-of select="@param"/></xsl:when>
		</xsl:choose>
	      </xsl:attribute> <!--* end of href *-->
	      
	      <!--* and now the text contents
		  * if the contents are empty, the we have to use either @name or @param
		  * (which we may have to turn into uppercase).
		  *-->
	      <xsl:choose>
		<!--* use the supplied text *-->
		<xsl:when test=".!=''"><xsl:apply-templates/></xsl:when>
		
		<!--* we have to use either the @param or @name attribute *-->
		<xsl:when test="boolean(@param)">
		  <xsl:call-template name="handle-uc">
		    <xsl:with-param name="uc"   select="boolean(@uc) and @uc=1"/>
		    <xsl:with-param name="text" select="@param"/>
		  </xsl:call-template>
		</xsl:when>
		
		<xsl:otherwise>
		  <xsl:call-template name="handle-uc">
		    <xsl:with-param name="uc"   select="boolean(@uc) and @uc=1"/>
		    <xsl:with-param name="text" select="@name"/>
		  </xsl:call-template>
		</xsl:otherwise>
	      </xsl:choose>
	      
	    </a>
	  </xsl:with-param>
	</xsl:call-template> <!--* add-text-styles *-->
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* name=add-ahelp-single-context *-->

  <!--*
      * An ahelp link to a file with both sl.* and py.* contexts,
      * so we link to both of them.
      *-->
  <xsl:template name="add-ahelp-multiple-context">
    <xsl:param name="name"/>
    <xsl:param name="namematches"/>
    <xsl:param name="num"/>

    <!--* do not allow param matches here *-->
    <xsl:if test="boolean(@param)">
      <xsl:message terminate="yes">
 ERROR: ahelp tag should not have param attribute (set to '<xsl:value-of select="@param"/>') for
        name=<xsl:value-of select="$name"/>
      </xsl:message>
    </xsl:if>

    <xsl:variable name="slmatch" select="$namematches[substring(context,1,2)='sl']"/>
    <xsl:variable name="pymatch" select="$namematches[substring(context,1,2)='py']"/>

    <!--* what site is the ahelp page on (assume the same for both links)? *-->
    <xsl:variable name="ahelpsite" select="$slmatch/site"/>

    <!--*
        * The ahelp page is either in this site or another one
        *-->
    <xsl:variable name="hrefstart"><xsl:choose>
      <xsl:when test="$site != $ahelpsite"><xsl:value-of select="concat('/',$ahelpsite,'/ahelp/')"/></xsl:when>
      <xsl:otherwise><xsl:call-template name="add-start-of-href">
	<xsl:with-param name="extlink" select="0"/>
	<xsl:with-param name="dirname" select="'ahelp/'"/>
      </xsl:call-template></xsl:otherwise>
    </xsl:choose></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
        <xsl:attribute name="class">helplink</xsl:attribute>

	<xsl:choose>
	  <xsl:when test=".!=''"><xsl:apply-templates/></xsl:when>

	  <xsl:otherwise>
	    <xsl:call-template name="handle-uc">
	      <xsl:with-param name="uc"   select="boolean(@uc) and @uc=1"/>
	      <xsl:with-param name="text" select="@name"/>
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>

	<xsl:text> (</xsl:text>
	<a>
	  <xsl:attribute name="class">helplink</xsl:attribute>
	  <xsl:if test="$slmatch/summary!=''">
	    <xsl:attribute name="title">Ahelp (<xsl:value-of select="$slmatch/context"/>): <xsl:value-of select="$slmatch/summary"/></xsl:attribute>
	  </xsl:if>

	  <xsl:attribute name="href">
	    <xsl:value-of select="$hrefstart"/>
	    <xsl:value-of select="$slmatch/page"/>
	    <xsl:text>.html</xsl:text>
	    <xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if>
	  </xsl:attribute>

	  <xsl:text>S-Lang</xsl:text>
	</a>
	<xsl:text> or </xsl:text>
	<a>
	  <xsl:attribute name="class">helplink</xsl:attribute>
	  <xsl:if test="$pymatch/summary!=''">
	    <xsl:attribute name="title">Ahelp (<xsl:value-of select="$pymatch/context"/>): <xsl:value-of select="$pymatch/summary"/></xsl:attribute>
	  </xsl:if>

	  <xsl:attribute name="href">
	    <xsl:value-of select="$hrefstart"/>
	    <xsl:value-of select="$pymatch/page"/>
	    <xsl:text>.html</xsl:text>
	    <xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if>
	  </xsl:attribute>

	  <xsl:text>Python</xsl:text>
	</a>
	<xsl:text> help)</xsl:text>


      </xsl:with-param>
    </xsl:call-template> <!--* add-text-styles *-->
    
  </xsl:template> <!--* name=add-ahelp-multiple-context *-->

  <!--*
      * handle FAQ tags:
      * produces different links depending on whether type=test or live
      *
      * similar to the ahelp tag, except that we are linking to the FAQ.
      * If no value is given, use the text link "this FAQ".
      * If the id attribute is supplied, link to that page (adding a trailing .html)
      * otherwise link to the FAQ index.
      *
      * If no site attribute (new to CIAO 3.0) is available
      *   a faq link in the ciao   pages links to the CIAO faq
      *   a faq link in the sherpa pages links to the Sherpa faq
      *   a faq link elsewhere assumes the CIAO faq
      *-->

  <xsl:template match="faq">

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed">
      <xsl:with-param name="tag" select="'id'"/>
    </xsl:call-template>

    <!--* check id attribute *-->
    <xsl:call-template name="check-id-for-no-html"/>

    <!--* TEMPORARY: throw a wobbly if an old id is supplied *-->
    <xsl:if test="boolean(@id)">
      <xsl:if test="starts-with(@id,'general-') or
	starts-with(@id,'parameter-') or
	starts-with(@id,'ce-') or
	starts-with(@id,'firstlook-') or
	starts-with(@id,'prism-') or
	starts-with(@id,'filtwin-') or
	starts-with(@id,'ds9-') or
	starts-with(@id,'sherpa-') or
	starts-with(@id,'acis_process_events-') or
	starts-with(@id,'asphist-') or
	starts-with(@id,'dmcopy-') or
	starts-with(@id,'dmextract-') or
	starts-with(@id,'dmgroup-') or
	starts-with(@id,'dmhedit-') or
	starts-with(@id,'dmstat-') or
	starts-with(@id,'dmtcalc-') or
	starts-with(@id,'lightcurve-') or
	starts-with(@id,'mkrmf-') or
	starts-with(@id,'tg_create_mask') or
	starts-with(@id,'fullgarf-') or
	starts-with(@id,'spectrum.sl-')">
	<xsl:message terminate="yes">
  Error: it appears that you are using the old style FAQ id
  (<xsl:value-of select="@id"/>). Please convert to the new one
  - see /data/da/Docs/ciaoweb/faq_ids
  If you are using the new one then bug Doug about why I'm complaining.
	</xsl:message>
      </xsl:if>
    </xsl:if>

    <!--*
        * complicated mess to work out where to link to
        * - if have a site attribute then use that
        * - otherwise if site=ciao use that
        * - otherwise if site=sherpa use that
        * - otherwise assume the CIAO site
        * 
        *-->
    <xsl:variable name="hrefstart"><xsl:choose>
	<xsl:when test="boolean(@site)"><xsl:value-of select="concat('/',@site,'/faq/')"/></xsl:when>
	<xsl:when test="$site != 'ciao' and $site != 'sherpa' and $site != 'chips'">/ciao/faq/</xsl:when>
	<xsl:otherwise><xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="0"/>
	    <xsl:with-param name="dirname" select="'faq/'"/>
	  </xsl:call-template></xsl:otherwise>
      </xsl:choose></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<!--* are we linking to the whole file, or a specific part of it? *-->
	<a>
	  <xsl:attribute name="title">CIAO Frequently Asked Questions</xsl:attribute>
	  <xsl:attribute name="href"><xsl:value-of select="$hrefstart"/><xsl:if test="boolean(@id)"><xsl:value-of select="@id"/>.html</xsl:if></xsl:attribute>

	  <!--* text *-->
	  <xsl:choose>
	    <xsl:when test=".=''">this FAQ</xsl:when>
	    <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
	  </xsl:choose>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* faq *-->

  <!--*
      * handle dictionary tags:
      * produces different links depending on whether type=test or live
      *
      * similar to the faq tag, except that we are linking to the dictionary.
      *
      * NOTE: there is no default text for the link - you must supply it
      *
      * The id attribute gives the id entry in the dictionary you want to link to
      * If you want to link to just the dictionary then don't supply an id attribute
      *
      * CURRENTLY links to the CIAO dictionary only
      *
      * Could make it clever so that it recognises when the root node is dictionary
      * so that we don't add the ../dictionary/ to the url - but can not be bothered
      *
      *-->
  
  <xsl:template match="dictionary">

    <xsl:call-template name="check-contents-are-not-empty"/>
    
    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed">
      <xsl:with-param name="tag" select="'id'"/>
    </xsl:call-template>
    <xsl:if test="boolean(@item)">
      <xsl:message terminate="yes">
 Error:
   a dictionary tag contains item=<xsl:value-of select="@item"/> when
   it should (almost certainly) be id=...
      </xsl:message>
    </xsl:if>

    <!--* check id attribute *-->
    <xsl:call-template name="check-id-for-no-html"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>


    <!--// if there is an attribute, use it 
	   otherwise, link to the "in-site" dictionary //-->
    <xsl:variable name="hrefstart"><xsl:choose>    
      <xsl:when test="@site = 'ciao'">/ciao/dictionary/</xsl:when>
      <xsl:when test="@site = 'csc'">/csc/dictionary/</xsl:when>

      <xsl:when test="$site = 'csc'">
        <xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="0"/>
	  <xsl:with-param name="dirname" select="'dictionary/'"/>
	</xsl:call-template>
      </xsl:when>

      <!-- ciao, chips, sherpa, etc. //-->
      <xsl:otherwise>
        <xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="dirname" select="'dictionary/'"/>
	</xsl:call-template>
      </xsl:otherwise>
      </xsl:choose></xsl:variable>


    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <xsl:choose>
	    <xsl:when test="($site != 'csc') or (@site = 'ciao')">
 	      <xsl:attribute name="title">CIAO Dictionary</xsl:attribute>
  
	      <xsl:attribute name="href">
	        <xsl:value-of select="$hrefstart"/>
		<xsl:if test="boolean(@id)">
		  <xsl:value-of select="@id"/>.html</xsl:if>
	      </xsl:attribute> 
	    </xsl:when>

	    <xsl:when test="($site = 'csc') or (@site = 'csc')">
 	      <xsl:attribute name="title">CSC Dictionary</xsl:attribute>
  
	      <xsl:attribute name="href">
	        <xsl:value-of select="$hrefstart"/>
		<xsl:if test="boolean(@id)">entries.html#<xsl:value-of select="@id"/></xsl:if>
	      </xsl:attribute>
	    </xsl:when>
	  </xsl:choose>

	  <!--* text *-->
	  <xsl:apply-templates/>
	</a>

      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template> <!--* dictionary *-->

  <!--*
      * handle POG tags:
      *
      *
      * - by default links to /proposer/POG/
      * - if a name attribute is supplied then we link to
      *   /proposer/POG/html/<name>
      *
      * Attributes:
      *   name - string, optional
      *     name of file: defaults to index.html if not supplied
      *   id - string, optional
      *     part of the POG file to link to
      *     shouldn't really be used without a name attribute
      *   ao - string, optional
      *     *** EXPERIMENTAL ***  >>> ACTUALLY NOT IMPLEMENTED <<<
      *     if need to link to a particular version of POG then use this
      *
      * similar to the ahelp tag, except that we are linking to the POG.
      * If no value is given, use the text link "the POG". 
      *
      * NOTE: currently no styles are allowed
      *
      *-->

  <xsl:template match="pog">

    <!--* are we linking to the index page or a specific one *-->
    <a>
      <xsl:attribute name="title">The Proposers' Observatory Guide</xsl:attribute>
      <xsl:attribute name="href">
	<xsl:text>/proposer/POG/</xsl:text>
        <!--* note the added "html/" here *-->
	<xsl:if test="boolean(@name)">html/<xsl:value-of select="@name"/></xsl:if>
        <!--* could worry about including index.html before # if there's no @name *-->
	<xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if>
      </xsl:attribute>

      <!--* text *-->
      <xsl:choose>
	<xsl:when test=".=''">the POG</xsl:when>
	<xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
      </xsl:choose>
    </a>
    
  </xsl:template> <!--* pog *-->

  <!--*
      * handle manual tags:
      * produces different links depending on whether type=test or live
      *
      * similar to the faq tag, except that we are linking to the manual.
      *
      * NOTE: there is no default text for the link - you must supply it
      *
      * the name of the manual (chips, detect, sherpa) is given in the
      * name attribute.
      * the page attribute gives the name of the page (sans trailing .html)
      * to link to (if not the main page) *** EXPERIMENTAL ***
      *
      * the id attribute is available to link to a section of a page
      * *** EXPERIMENTAL ***
      *
      * For CIAO 3.0:
      *     chips, detect -> CIAO site
      *     sherpa        -> Sherpa site
      *
      *-->

  <xsl:template match="manual">

    <xsl:call-template name="check-contents-are-not-empty"/>
    
    <!--* check name attribute *-->
    <xsl:call-template name="check-page-for-no-html"/>

    <!--*
        * where do we link:
        *    for chips and detect manual want the CIAO site
        *    for sherpa           manual want the Sherpa site
        *-->
    <xsl:variable name="href"><xsl:choose>
	<xsl:when test="@name='sherpa'">
	  <!--* sherpa *-->
	  <xsl:choose>
	    <xsl:when test="$site = 'sherpa'">
	      <xsl:call-template name="add-path">
		<xsl:with-param name="idepth" select="$depth"/>
	      </xsl:call-template>
	    </xsl:when>
	    <xsl:otherwise>/sherpa/</xsl:otherwise>
	  </xsl:choose>documents/manuals/html/</xsl:when>

	<xsl:when test="@name='chips'">
	  <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>
	  <xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="$extlink"/>
	    <xsl:with-param name="dirname">download/doc/chips_manual/</xsl:with-param>
	  </xsl:call-template>
	</xsl:when> <!--// end chips //-->

	<xsl:when test="@name='detect'">
	  <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>
	  <xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="$extlink"/>
	    <xsl:with-param name="dirname">download/doc/detect_manual/</xsl:with-param>
	  </xsl:call-template>
	</xsl:when> <!--// end detect //-->
      </xsl:choose></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <xsl:attribute name="href"><xsl:value-of select="$href"/><xsl:call-template name="sort-out-anchor"/></xsl:attribute>
	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template> <!--* manual *-->

  <!--*
      * Link to the manuals page
      *
      * Parameters:
      *   site, string, optional (defaults to CIAO)
      *     - what 
      *   standard style attributes
      *
      * For CIAO 3.0 added the site attribute to allow us to link
      * to different manual pages (if necessary). Defaults to 
      * CIAO if not specified
      *
      *-->
  <xsl:template match="manualpage">

    <!--* where are we linking to? *-->
    <xsl:variable name="href"><xsl:choose>
	<xsl:when test="@site='sherpa'">
	  <!--* sherpa *-->
	  <xsl:choose>
	    <xsl:when test="$site = 'sherpa'">
	      <xsl:call-template name="add-path">
		<xsl:with-param name="idepth" select="$depth"/>
	      </xsl:call-template>
	    </xsl:when>
	    <xsl:otherwise>/sherpa/</xsl:otherwise>
	  </xsl:choose>documents/</xsl:when>
	<xsl:when test="@site='ciao' or not(@site)">
	  <!--* CIAO *-->
	  <xsl:choose>
	    <xsl:when test="$site = 'ciao'">
	      <xsl:call-template name="add-path">
		<xsl:with-param name="idepth" select="$depth"/>
	      </xsl:call-template>
	    </xsl:when>
	    <xsl:otherwise>/ciao/</xsl:otherwise>
	  </xsl:choose>manuals.html</xsl:when>
	<xsl:otherwise>
	  <xsl:message terminate="yes">

Error: manualpage tag found with site=<xsl:value-of select="@site"/>
       when the permitted values are ciao or sherpa

	  </xsl:message>
	</xsl:otherwise></xsl:choose></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<!--* link to manuals page *-->
	<a href="{$href}"><xsl:choose>
	    <xsl:when test=".=''">Manuals page</xsl:when>
	    <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
	  </xsl:choose></a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* manualpage *-->

  <!--* 
      * Link to the data products guide
      *
      * Attributes:
      *  page - strong, optional
      *   the name of the page to link to [without the .html]
      *  id - the anchor to link to
      *
      *  + the 'style' attributes although UC is ignored
      *
      * if no name is supplied we link to the index page
      *
      * if the tag is empty, use the text "Data Products guide"
      *-->
  <xsl:template match="dpguide">

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed"/>

    <!--* check name attribute *-->
    <xsl:call-template name="check-page-for-no-html"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<!--* link to data products guide *-->
	<a>
	  <xsl:attribute name="href">
	    <xsl:call-template name="add-start-of-href">
	      <xsl:with-param name="extlink" select="$extlink"/>
	      <xsl:with-param name="dirname" select="'data_products_guide/'"/>
	    </xsl:call-template>
	    <xsl:call-template name="sort-out-anchor"/>
	  </xsl:attribute>

	  <!--* text *-->
	  <xsl:choose>
	    <xsl:when test=".=''">Data Products Guide</xsl:when>
	    <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
	  </xsl:choose>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* dpguide *-->

  <!--*
      * Link to the bugs page
      *
      * parameters:
      *   depth 
      *
      * attributes:
      * id   - string, optional
      *   anchor on page to link to (eg as created by id tag)
      *
      *   em/tt/strong - boolean, optional
      *     if true, link text is set to these styles
      *   uc - boolean, optional
      *     if true set the link text to upper case [***does not work***]
      *
      *-->
  <xsl:template match="bug">

    <!--* check page attribute *-->
    <xsl:call-template name="check-page-for-no-html"/>

    <!--*
        * complicated mess copied from FAQ section
        *-->
    <xsl:variable name="hrefstart"><xsl:choose>
	<xsl:when test="boolean(@site)"><xsl:value-of select="concat('/',@site,'/bugs/')"/></xsl:when>
	<xsl:when test="$site != 'ciao' and $site != 'sherpa'">/ciao/bugs/</xsl:when>
	<xsl:otherwise><xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="0"/>
	    <xsl:with-param name="dirname" select="'bugs/'"/>
	  </xsl:call-template></xsl:otherwise>
      </xsl:choose></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<!--* link to bug page *-->
	<a>
	  <xsl:attribute name="href">
	    <xsl:value-of select="$hrefstart"/>
	    <xsl:call-template name="sort-out-anchor"/>
	  </xsl:attribute>

	  <!--* text *-->
	  <xsl:choose>
	    <xsl:when test=".=''"><xsl:value-of select="@page"/></xsl:when>
	    <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
          </xsl:choose>

	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* bug *-->



  <!--* 
      * Link to a caveat
      *
      * Attributes:
      *  page - strong, optional
      *   the name of the page to link to [without the .html]
      *  id - the anchor to link to
      *
      *  + the 'style' attributes although UC is ignored
      *
      * if no name is supplied we link to the data caveats index page
      *
      * There is no default text
      *-->
  <xsl:template match="caveat">

    <xsl:call-template name="check-contents-are-not-empty"/>

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed"/>

    <!--* check name attribute *-->
    <xsl:call-template name="check-page-for-no-html"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<!--* link to caveat *-->
	<a>
	  <xsl:attribute name="href">
	    <xsl:call-template name="add-start-of-href">
	      <xsl:with-param name="extlink" select="$extlink"/>
	      <xsl:with-param name="dirname" select="'caveats/'"/>
	    </xsl:call-template>
	    <xsl:call-template name="sort-out-anchor"/>
	  </xsl:attribute>
	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* caveat *-->


  <!--* 
      * Link to an analysis guide
      *
      * Attributes:
      *  page - strong, optional
      *   the name of the page to link to [without the .html]
      *  id - the anchor to link to
      *
      *  + the 'style' attributes although UC is ignored
      *
      * if no page attribute is supplied we link to the analysis guides index page
      *
      * if a name attribute is supplied then we complain (need a DTD!)
      *
      * There is no default text
      *-->
  <xsl:template match="aguide">

    <xsl:call-template name="check-contents-are-not-empty"/>

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed"/>

    <!--* check name attribute *-->
    <xsl:call-template name="check-page-for-no-html"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<!--* link to analysis guides *-->
	<a>
	  <xsl:attribute name="title">CIAO Analysis Guides</xsl:attribute>
	  <xsl:attribute name="href">
	    <xsl:call-template name="add-start-of-href">
	      <xsl:with-param name="extlink" select="$extlink"/>
	      <xsl:with-param name="dirname" select="'guides/'"/>
	    </xsl:call-template>
	    <xsl:call-template name="sort-out-anchor"/>
	  </xsl:attribute>
	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* aguide *-->

  <!--* 
      * Link to a why document
      *
      * Attributes:
      *  page - strong, optional
      *   the name of the page to link to [without the .html]
      *  id - the anchor to link to
      *
      *  + the 'style' attributes although UC is ignored
      *
      * if no name is supplied we link to the why index page
      *
      * There is no default text
      *-->
  <xsl:template match="why">

    <xsl:call-template name="check-contents-are-not-empty"/>

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed"/>

    <!--* check name attribute *-->
    <xsl:call-template name="check-page-for-no-html"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--// if there is an attribute, use it 
	   otherwise, link to the "in-site" why topic //-->
    <xsl:variable name="hrefstart"><xsl:choose>    
      <xsl:when test="@site = 'ciao'">/ciao/why/</xsl:when>
      <xsl:when test="@site = 'csc'">/csc/why/</xsl:when>

      <xsl:when test="$site = 'csc'">
        <xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="0"/>
	  <xsl:with-param name="dirname" select="'why/'"/>
	</xsl:call-template>
      </xsl:when>

      <!-- ciao, chips, sherpa, etc. //-->
      <xsl:otherwise>
        <xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="dirname" select="'why/'"/>
	</xsl:call-template>
      </xsl:otherwise>
      </xsl:choose></xsl:variable>


    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <xsl:choose>
	    <xsl:when test="($site != 'csc') or (@site = 'ciao')">
 	      <xsl:attribute name="title">CIAO Why Topic</xsl:attribute>
	    </xsl:when>

	    <xsl:when test="($site = 'csc') or (@site = 'csc')">
 	      <xsl:attribute name="title">CSC How and Why Topic</xsl:attribute>
	    </xsl:when>
	  </xsl:choose>

	  <xsl:attribute name="href">
	    <xsl:value-of select="$hrefstart"/>
	    <xsl:call-template name="sort-out-anchor"/>
	  </xsl:attribute>
	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* why *-->

  <!--*
      * handle download tags:
      *  - in CIAO 3.1 we updated the system so that
      *    a) the index page is /ciao/download/index.html rather than
      *       /ciao/download_ciao_reg.html
      *    b) split the actual download areas into separate pages
      *       (one per OS): ie
      *          /ciao/download/<type>_reg.html
      *          /ciao/download/<type>_src.html
      *    c) and then we have CALDB and ATOMDB that do not have a
      *       registration page
      *
      * So we have:
      *   tag                                         url
      *   <download>foo bar</download>                /ciao/download/
      *   <download id="bar">foo bar</download>       /ciao/download/index.html#bar
      *   <download type="solaris">foo bar</download> /cgi-gen/ciao/download_ciao_solaris.cgi
      *   for now no id attribute allowed with id attribute
      *
      *   <download type="caldb">foo bar</download>   /ciao/download/caldb.html
      *
      * NOTES:
      *  - there is no default text for the link - you must supply it
      *  - the decision on whether we link to a CGI script or actual HTML
      *    page (ie whether there is a registration page) should not be
      *    hard-coded but should be set by the XSLT processor (ie user)
      *
      *-->

  <xsl:template match="download">

    <xsl:call-template name="check-contents-are-not-empty"/>

    <!--* the spaces are important *-->
    <xsl:variable name="no-register-type" select="' caldb atomdb '"/>

    <!--*
        * checks: for now can not have both type and id fields
        *-->
    <xsl:if test="boolean(@type)">
      <xsl:call-template name="is-download-type-valid">
	<xsl:with-param name="type" select="@type"/>
      </xsl:call-template>
      <xsl:if test="boolean(@id)">
	<xsl:message terminate="yes">
 ERROR: download link found with type and id attributes
 when only one is allowed
 type=<xsl:value-of select="@type"/>  id=<xsl:value-of select="@id"/> 
	</xsl:message>
      </xsl:if>
    </xsl:if> <!--* boolean(@type) *-->

    <!--*
        * What are we linking to:
        *  - no type attribute then it is /ciao/download/index.html
        *  - if a type attribute then it is either of
        *        /cgi-gen/ciao/download_ciao_@type.cgi
        *        /ciao/download/@type.html
        *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <xsl:attribute name="href">
	    <xsl:choose>
	      <xsl:when test="boolean(@type)">
		<xsl:choose>
		  <xsl:when test="contains($no-register-type,concat(' ',@type,' '))=true()">
		    <xsl:call-template name="add-start-of-href">
		      <xsl:with-param name="extlink" select="$extlink"/>
		      <xsl:with-param name="dirname" select="''"/>
		    </xsl:call-template>
		    <xsl:value-of select="concat('download/',@type,'.html')"/>
		  </xsl:when>
		  <xsl:otherwise>
		    <xsl:variable name="linkversion"><xsl:value-of select="$siteversion"/></xsl:variable>
		    <xsl:value-of select="concat('/cgi-gen/ciao/download_ciao',$linkversion,'_',@type,'.cgi')"/>
		  </xsl:otherwise>
		</xsl:choose>
	      </xsl:when>
	      <xsl:otherwise>
		<!--* index page *-->
		<xsl:call-template name="add-start-of-href">
		  <xsl:with-param name="extlink" select="$extlink"/>
		  <xsl:with-param name="dirname" select="''"/>
		</xsl:call-template>
		<xsl:text>download/</xsl:text>
		<xsl:if test='boolean(@id)'>index.html#<xsl:value-of select="@id"/></xsl:if>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:attribute>
	  <!--* text *-->
	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template> <!--* download *-->

  <!--*
      * handle script tags:
      * produces different links depending on whether type=test or live
      * 
      * Attributes:
      *   name - string, required
      *     name of script
      *
      *   em/tt/strong - boolean, optional
      *     if true, link text is set to these styles
      *
      * If no value - ie tag is empty - then we use the name as the link text
      *
      * CURRENTLY links to CIAO scipts only
      *
      * This is just a wrapper around the create-script-link template
      * so that we can call the same code from the scriptlist template
      * in myhtml.xsl. Apart from the style options which are only
      * (currently) available to the script tag user and not the
      * create-script-link template
      *
      *-->

  <xsl:template match="script">

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<xsl:call-template name="create-script-link">
	  <xsl:with-param name="name"  select="@name"/>
	  <xsl:with-param name="text"  select="."/>
	</xsl:call-template>
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template> <!--* match=script *-->

  <xsl:template name="create-script-link">
    <xsl:param name="name"  select="''"/>
    <xsl:param name="text"  select="''"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* link to script *-->
    <a>
      <xsl:attribute name="href">
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="dirname" select="'download/scripts/'"/>
	</xsl:call-template>
	<xsl:value-of select="$name"/>
      </xsl:attribute>

      <!--* text *-->
      <xsl:choose>
	<xsl:when test="$text=''"><xsl:value-of select="$name"/></xsl:when>
	<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
      </xsl:choose>
    </a>
    
  </xsl:template> <!--* name=create-script-link *-->

  <!--*
      * Link to the scripts page
      *
      * parameters:
      *   depth 
      *
      * attributes:
      * id   - string, optional
      *   anchor on page to link to (eg as created by id tag)
      *
      *   em/tt/strong - boolean, optional
      *     if true, link text is set to these styles
      *   uc - boolean, optional
      *     if true set the link text to upper case [***does not work***]
      *
      * CURRENTLY links to the CIAO scipt page only
      *-->
  <xsl:template match="scriptpage">

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<!--* link to script page *-->
	<a>
	  <xsl:attribute name="href">
	    <xsl:call-template name="add-start-of-href">
	      <xsl:with-param name="extlink" select="$extlink"/>
	      <xsl:with-param name="dirname" select="'download/scripts/'"/>
	    </xsl:call-template>
	    <xsl:if test="boolean(@id)">index.html#<xsl:value-of select="@id"/></xsl:if>
	  </xsl:attribute>

	  <!--* text *-->
	  <xsl:choose>
	    <xsl:when test=".=''">Scripts page</xsl:when>
	    <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
	  </xsl:choose>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* scriptpage *-->

  <!--*
      * +++ this template may no longer be worth the effort now we have a 'unified' test site +++
      *
      * We use mylink as a "quick and easy" way to handle
      * <a> tags in this document - it handles depth
      *
      * It was originally designed when the test site was incomplete
      * so that we wanted to link to the live site to allow checks of
      * the link. This approach is no longer valid so some of the
      * complexity (and need for the template) has gone.
      * 
      * Tried to be clever, decided it's too hard, so
      * parameters:
      *   filename = string
      *      name of file (including any anchor such as #foo) to link to
      *   dir = string
      *      url = concat(dir,filename) so dir should end in a /
      *      (or be the empty string)
      *   test = string
      *      contents of link
      *-->

  <xsl:template name="mylink">

    <!--* list the params expected by this template *-->
    <xsl:param name="filename"/>
    <xsl:param name="dir"/>
    <xsl:param name="text"/>

    <!--*
        * used to say for href: concat($dir,'/',$filename)
        * but decided to make the dir parameter end in / where necessary
        *-->
    <a href="{concat($dir,$filename)}"><xsl:value-of select="$text"/></a>
  </xsl:template> <!--* mylink *-->

  <!--* 
      * we allow the contents of <extlink> to contain HTML 
      *
      * Attributes:
      *  href = URL of page
      *  id   = anchor
      *
      *  it also accepts the "style" attributes
      *
      * Up to (and including) v1.16 external links were followed
      * by an "external link" image. This has been removed since
      * it wasn't that useful (needed explanation) and could
      * cause some slightly ugly looking links.
      *
      * will warn about use when cxclink should be used instead
      * (I couldn't be bothered to also check for more specific tags, since
      *  cxclink will do that).
      *
      * Need to have to worry (slightly) about if this is an iCXC page
      *
      *-->
  <xsl:template match="extlink">

    <xsl:call-template name="check-contents-are-not-empty"/>

    <!--* warn if there's a better option *-->
    <xsl:if test="$site != 'icxc' and starts-with(@href,'http://cxc.harvard.edu')">
      <xsl:message>
  Warning: extlink href=<xsl:value-of select="@href"/>
  should be cxclink href=<xsl:value-of select="substring(@href,23)"/>
      </xsl:message>
    </xsl:if>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <xsl:attribute name="href"><xsl:value-of select="@href"/><xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if></xsl:attribute>

	  <!--// allow javascripty goodness //-->
          <xsl:if test="boolean(@onclick)">
	    <xsl:attribute name="onclick"><xsl:value-of select="@onclick"/></xsl:attribute>
	  </xsl:if>
          <xsl:if test="boolean(@target)">
	    <xsl:attribute name="target"><xsl:value-of select="@target"/></xsl:attribute>
	  </xsl:if>

	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* extlink *-->

  <!--* 
      * for links within cxc.harvard.edu
      *
      * parameters:
      *   depth 
      *
      * attributes:
      * href - string, optional
      *   URL to link to
      * id   - string, optional
      *   anchor on page to link to (eg as created by id tag)
      *
      *   em/tt/strong - boolean, optional
      *     if true, link text is set to these styles
      *   uc - boolean, optional
      *     if true set the link text to upper case [***does not work***]
      *
      * either/both href and id must exist
      *
      * We no longer link to cxc.harvard.edu from test site
      * - ie we assume asc-bak is populated enough for our purposes
      *
      * This template is complicated because we want to also support
      * cxclink's in navbar's. These then need (if not "external") to
      * account for the depth of the current page. We do this by
      * checking to see if the top-level element is `navbar': if so
      * we have to add a "path element" to the filename, otherwise the
      * depth parameter is only used to link to the external image icon.
      *
      * NEED TO HANDLE site!=ciao [do we?]
      *
      * will warn about use when some other, more specific, tags would be better
      *
      * This tag can NOT be used if $site=icxc
      *
      * Do we need to support use in pages that have /<head>/info/proglang
      * elements? e.g. <cxclink href="foo">...</cxclink> could link to both
      * versions automaticallyt (or only one if within a given language page).
      *-->

  <xsl:template name="warn-in-cxclink">
    <xsl:param name="link"/>
    <xsl:message>
 Warning:
  cxclink has href=<xsl:value-of select="@href"/>
  you should (almost certainly) be using the <xsl:value-of select="$link"/> tag instead
    </xsl:message>
  </xsl:template>

  <xsl:template match="cxclink">

    <xsl:call-template name="check-contents-are-not-empty"/>

    <!--* safety check *-->
    <xsl:if test="$site = 'icxc'">
      <xsl:message terminate="yes">
  Error:
    The document contains a cxclink tag but we're in the internal
    site, so should be using icxclink or extlink
    contents of tag:
<xsl:value-of select="."/>
      </xsl:message>
    </xsl:if>

    <!--* warn if there's a better option *-->
    <xsl:if test="boolean(@href)">
      <xsl:if test="contains(@href,'documents_thread') or contains(@href,'threads/')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'threadpage or threadlink'"/></xsl:call-template>
      </xsl:if>
      <xsl:if test="contains(@href,'documents_dictionary') or contains(@href,'dictionary/')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'dictionary'"/></xsl:call-template>
      </xsl:if>
      <xsl:if test="contains(@href,'documents_ahelp') or contains(@href,'ahelp/')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'ahelp'"/></xsl:call-template>
      </xsl:if>
      <xsl:if test="contains(@href,'documents_faq') or contains(@href,'faq/')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'faq'"/></xsl:call-template>
      </xsl:if>
      <xsl:if test="contains(@href,'documents_manual')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'manualpage'"/></xsl:call-template>
      </xsl:if>
      <xsl:if test="contains(@href,'html_manual')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'manual'"/></xsl:call-template>
      </xsl:if>
      
      <xsl:if test="contains(@href,'download/doc/data_products_guide')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'dpguide'"/></xsl:call-template>
      </xsl:if>
      <!--* if start with /ciao then assume linking to a specific version so allow it *-->
      <xsl:if test="contains(@href,'download_ciao_reg') and not(starts-with(@href,'/ciao'))">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'download'"/></xsl:call-template>
      </xsl:if>
      
      <xsl:if test="contains(@href,'caveats/')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'caveat'"/></xsl:call-template>
      </xsl:if>
      <xsl:if test="contains(@href,'why/')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'why'"/></xsl:call-template>
      </xsl:if>
      <xsl:if test="contains(@href,'aguide/')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'aguide'"/></xsl:call-template>
      </xsl:if>
      
      <xsl:if test="contains(@href,'POG')">
	<xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'pog'"/></xsl:call-template>
      </xsl:if>
    </xsl:if>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <!--* note the ugly way I find the name of the root node (ie 'name(//*)') *-->
	  <xsl:attribute name="href">
	    <xsl:if test="boolean(@href)"><xsl:if test="starts-with(@href,'/')=false() and name(//*)='navbar'"><xsl:call-template name="add-path">
	      <xsl:with-param name="idepth" select="$depth"/>
	    </xsl:call-template></xsl:if><xsl:value-of select="@href"/></xsl:if>
	    <xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if>
	  </xsl:attribute>
	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template> <!--* cxclink *-->                                            


<!--*
    * Link to the release notes page
    *
    * You cannot link directly to index.html as it is a redirect.
    *
    * parameters:
    *   depth 
    *
    * attributes:
    * ver - string, optional
    *   version of CIAO page to link to (e.g. 4.3 for ciao_4.3_release.html )
    *
    * href - string, optional
    *   specific page to link, e.g. history.html
    *
    * id   - string, optional
    *   anchor on page to link to (eg as created by id tag)
    *
    *   em/tt/strong - boolean, optional
    *     if true, link text is set to these styles
    *   uc - boolean, optional
    *     if true set the link text to upper case [***does not work***]
    *
    *-->
<xsl:template match="relnote">

  <!--* check page attribute *-->
  <xsl:call-template name="check-page-for-no-html"/>

  <!--*
      * complicated mess copied from FAQ section
      *-->
  <xsl:variable name="hrefstart"><xsl:choose>
	<xsl:when test="boolean(@site)"><xsl:value-of select="concat('/',@site,'/releasenotes/')"/></xsl:when>
	<xsl:when test="$site != 'ciao'">/ciao/releasenotes/</xsl:when>
	<xsl:otherwise><xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="0"/>
	    <xsl:with-param name="dirname" select="'releasenotes/'"/>
	  </xsl:call-template></xsl:otherwise>
    </xsl:choose></xsl:variable>

  <!--* process the contents, surrounded by styles *-->
  <xsl:call-template name="add-text-styles">
    <xsl:with-param name="contents">
	<!--* link to releasenotes page *-->
	<a>
	  <xsl:attribute name="href">
	    <xsl:value-of select="$hrefstart"/>
	    <xsl:choose>
	      <xsl:when test="boolean(@ver)">
		<xsl:value-of select="concat('ciao_',@ver,'_release.html')"/><xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if>
	      </xsl:when>

	      <!-- bit of a cludge to link to history.html -->
	      <xsl:when test="boolean(@href)">
		<xsl:value-of select="@href"/><xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if>
	      </xsl:when>

	      <xsl:otherwise>
		<xsl:text>index.html</xsl:text>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:attribute>

	  <!--* link text *-->
	  <xsl:apply-templates/>

	</a>
    </xsl:with-param>
  </xsl:call-template>

</xsl:template> <!--* relnote *-->


  <!--* 
      * for links within icxc.harvard.edu/sds/
      *
      * parameters:
      *   depth 
      *
      * attributes:
      * href - string, optional
      *   URL to link to
      * id   - string, optional
      *   anchor on page to link to (eg as created by id tag)
      *
      *   em/tt/strong - boolean, optional
      *     if true, link text is set to these styles
      *
      * either/both href and id must exist
      *
      * This template is complicated because we want to also support
      * cxclink's in navbar's. These then need (if not "external") to
      * account for the depth of the current page. We do this by
      * checking to see if the top-level element is `navbar': if so
      * we have to add a "path element" to the filename, otherwise the
      * depth parameter is only used to link to the external image icon.
      *
      * This tag can ONLY be used if $site=icxc
      *
      *-->

  <xsl:template match="icxclink">

    <xsl:call-template name="check-contents-are-not-empty"/>
    
    <!--* safety check *-->
    <xsl:if test="$site != 'icxc'">
      <xsl:message terminate="yes">
  Error:
    The document contains an icxclink tag but we're not
    a page for the internal site (site=<xsl:value-of select="$site"/>)
    contents of tag:
<xsl:value-of select="."/>
      </xsl:message>
    </xsl:if>
    
    <!--* are we an "external" link for this site *-->
    <xsl:variable name="extlink" select="starts-with(@href,'/')"/>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <!--* note the ugly way I find the name of the root node (ie 'name(//*)') *-->
	  <xsl:attribute name="href">
	    <xsl:choose>
	      <xsl:when test="boolean($extlink)=false() and name(//*)='navbar'"><xsl:call-template name="add-path">
		  <xsl:with-param name="idepth" select="$depth"/>
		</xsl:call-template></xsl:when>
	    </xsl:choose>
	    <xsl:value-of select="@href"/><xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if>
	  </xsl:attribute>
	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template> <!--* icxclink *-->

  <!--*
      * add a link to the help desk
      * produces different links depending on whether type=test or live
      * - - - DO WE NEED TO BOTHER ABOUT THE TEST SITE HERE? - - -
      *
      *   em/tt/strong - boolean, optional
      *     if true, link text is set to these styles
      *   uc - boolean, optional
      *     if true set the link text to upper case [***not used***]
      *
      * similar to the ahelp tag, except that we are linking to the help desk.
      * If no value is given, use the text link "Helpdesk". 
      *
      * as with cxclink, depth tag is used only for the extlink image
      *-->
  
  <xsl:template match="helpdesk">

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<!--* could just set href directly but want class to appear first (for testing) *-->
	<a>
	  <xsl:attribute name="title">CXC Helpdesk</xsl:attribute>
	  <xsl:attribute name="href">/helpdesk/</xsl:attribute>
	  <xsl:choose>
	    <xsl:when test=".=''">Helpdesk</xsl:when>
	    <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
	  </xsl:choose>
	</a>
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template> <!--* helpdesk *-->
  
  <!--* 
      * for links to the thread index page(s)
      *
      * attributes:
      * name - string, optional
      *   if not supplied links to the top-level page,
      *   otherwise link to this particular section of the threads
      * id   - string, optional
      *   to link to a particular part of the page
      *   [probably not needed, but left in for consistency]
      * site - string, optional
      *   "site" of thread if it's not the same as $site
      *
      *   em/tt/strong - boolean, optional
      *     if true, link text is set to these styles
      *   uc - boolean, optional
      *     if true set the link text to upper case [***does not work***]
      *
      * NOTES:
      *  see threadlink for "complicated" site handling
      *
      *  there is NO default text
      *
      *-->

  <xsl:template match="threadpage">

    <xsl:call-template name="check-contents-are-not-empty"/>
    
    <!--* since we don't have a DTD *-->
    <xsl:call-template name="page-not-allowed"/>

    <!--* set up the url fragment:
        *   a) handle the site/depth
        *   b) handle the file location and is there an anchor too?
        *-->
    <xsl:variable name="urlfrag"><xsl:call-template name="handle-thread-site-link">
	<xsl:with-param name="linktype"  select="'threadpage'"/>
      </xsl:call-template></xsl:variable>

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <!--* add the href attibute *-->
	  <xsl:call-template name="add-attribute">
	    <!--* we've added the depth to the url above (if it's needed), so we set depth to 1 here *-->
	    <xsl:with-param name="idepth" select="1"/>
	    <xsl:with-param name="name"  select="'href'"/>
	    <xsl:with-param name="value"><xsl:value-of
		select="$urlfrag"/><xsl:choose>
		<!--* which index page? *-->
		<xsl:when test="boolean(@name)"><xsl:value-of select="@name"/></xsl:when>
		<xsl:otherwise>index</xsl:otherwise>
	      </xsl:choose>.html<xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if></xsl:with-param>
	  </xsl:call-template>

	  <!--* process the contents of the tag *-->
	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* match=threadpage *-->

  <!--* for links to threads
      *
      * attributes:
      * name - string, optional
      *   matches thread/info/name value of thread
      * id   - string, optional
      *   to link to a particular part of the thread
      * site - string, optional
      *   "site" of thread if it's not the same as $site
      *
      *   em/tt/strong - boolean, optional
      *     if true, link text is set to these styles
      *   uc - boolean, optional
      *     if true set the link text to upper case [***does not work***]
      *
      * notes: 
      *  if no name attribute is supplied we either:
      *   - if the root node is thread, link to the current page
      *   - else throw a wobbly and tell the user to use threadpage (or there's an error). 
      *
      *  we now support the proglang attribute - which says link to
      *  a specific language - and the //thread/info/proglang values -
      *  which indicate what language(s) the thread covers.
      *
      *  id only is only allowed if the rootnode is thread
      *    OR dummy (ie an include file)
      *
      * As we now have to read in the thread we *could* support empty
      * thread link tags, which would mean using the short/long title
      * elements for the thread as the link text.
      *
      *-->

  <xsl:template match="threadlink">

    <!--* safety checks *-->
    <xsl:call-template name="check-contents-are-not-empty"/>
    <xsl:call-template name="page-not-allowed"/>

    <!--* are we within a thread (or an included file)? *-->
    <xsl:variable name="in-thread" select="name(//*)='thread' or name(//*)='dummy'"/>

    <xsl:if test="$in-thread=false() and boolean(@name)=false()">
      <xsl:message terminate="yes">
  threadlink tag must contain a name attribute when not used in a thread.
  If you want to link to the thread index page use the threadpage tag.
  Threadlink contents:
  <xsl:value-of select="."/>
      </xsl:message>
    </xsl:if>

    <!--*
        * How do we handle threadlink tags from included files?
	* XXX TODO XXX send in thread name?
	*-->
    <xsl:if test="boolean(@name)=false() and name(//*)!='thread' and $threadName = ''">
      <xsl:message terminate="yes">
 Internal error: threadlink has no @name, not in a thread, and $threadName=''
      </xsl:message>
    </xsl:if>

    <xsl:variable name="threadInfo" select="djb:read-in-thread-info()"/>
    <xsl:variable name="tInfo" select="exsl:node-set($threadInfo)"/>
    <xsl:variable name="tname" select="$tInfo/name"/>
    <xsl:variable name="nlang" select="count($tInfo/proglang)"/>

    <!--*
	* How do we process the link?
	* We first handle the obvious error cases
	*-->
    <xsl:choose>

      <xsl:when test="boolean(@proglang) and $nlang=0">
	<xsl:message terminate="yes">
 ERROR: threadlink tag has proglang attribute (value=<xsl:value-of select="@proglang"/>)
    but the thread (name=<xsl:value-of select="$tname"/>) has no //thread/info/proglang nodes!
	</xsl:message>
      </xsl:when>

      <xsl:when test="$nlang = 1 and boolean(@proglang) and @proglang != $tInfo/proglang">
	<xsl:message terminate="yes">
 ERROR: threadlink tag has proglang attribute=<xsl:value-of select="@proglang"/>
   but the thread (name=<xsl:value-of select="$name"/>) only has
   //thread/info/proglang=<xsl:value-of select="$tInfo/proglang"/>
	</xsl:message>
      </xsl:when>

      <xsl:when test="$nlang &gt; 0 and (boolean(@proglang) or $proglang != '')">
	<xsl:call-template name="threadlink-single-proglang">
	  <xsl:with-param name="in-thread" select="$in-thread"/>
	</xsl:call-template>
      </xsl:when>

      <xsl:when test="$nlang &gt; 1">
	<xsl:call-template name="threadlink-multiple-proglang">
	  <xsl:with-param name="in-thread" select="$in-thread"/>
	</xsl:call-template>
      </xsl:when>

      <xsl:otherwise>

	<xsl:if test="boolean(@proglang)">
	  <xsl:message>
 WARNING: threadlink has @proglang=<xsl:value-of select="@proglang"/> but the thread,
          name=<xsl:value-of select="$tname"/>, does not appear to be language-specific
	  </xsl:message>
	</xsl:if>

	<xsl:call-template name="threadlink-simple">
	  <xsl:with-param name="in-thread" select="$in-thread"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* match=threadlink *-->

  <!--* XXX TODO XXX refactor the threadlink-* templates *-->

  <!--* Handle a threadlink when we do not have to bother about proglang values *-->
  <xsl:template name="threadlink-simple">
    <xsl:param name="in-thread" select="false()"/>

    <!--* set up the url fragment:
	*   a) handle the site/depth
	*   b) handle the file location and is there an anchor too?
	*-->
    <xsl:variable name="urlfrag"><xsl:call-template name="handle-thread-site-link">
      <xsl:with-param name="linktype"  select="'threadlink'"/>
      <xsl:with-param name="in-thread" select="$in-thread"/>
    </xsl:call-template></xsl:variable>

    <xsl:variable name="index">index.html</xsl:variable>
    
    <!--*
	* Process the contents, surrounded by styles.
	* I think the code below can be cleaned up; see threadlink-multiple-proglang
	*-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <!--* add the href attibute *-->
	  <xsl:attribute name="href"><xsl:value-of
		select="$urlfrag"/><xsl:choose>
		<!--* and now the actual directory/file *-->
	
		<!--* name specified (id may or may not be) *-->
		<xsl:when test="boolean(@name)"><xsl:value-of select="@name"/>/<xsl:if
		    test="boolean(@id)"><xsl:value-of select="concat($index,'#',@id)"/></xsl:if></xsl:when>

		<!--* 
                    * if id only then we include the page name in the URL to make
                    * offline browsing/site-packaging code to work
                    *-->
		<xsl:when test="boolean(@id)"><xsl:value-of select="concat($index,'#',@id)"/></xsl:when>

		<!--* link to itself (a bit pointless) *-->
		<xsl:otherwise><xsl:value-of select="$index"/></xsl:otherwise>
	  </xsl:choose></xsl:attribute>

	  <!--* process the contents of the tag *-->
	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* name=threadlink-simple *-->

  <!--*
      * Thread has multiple languages, use
      * @proglang or $proglang to determine which to use
      * (check for @proglang first, then fall back to $proglang)
      *-->
  <xsl:template name="threadlink-single-proglang">
    <xsl:param name="in-thread" select="false()"/>

    <xsl:variable name="urlfrag"><xsl:call-template name="handle-thread-site-link">
      <xsl:with-param name="linktype"  select="'threadlink'"/>
      <xsl:with-param name="in-thread" select="$in-thread"/>
    </xsl:call-template></xsl:variable>

    <xsl:variable name="index">index<xsl:choose>
    <xsl:when test="boolean(@proglang)"><xsl:value-of select="concat('.',@proglang)"/></xsl:when>
    <xsl:when test="$proglang != ''"><xsl:value-of select="concat('.',$proglang)"/></xsl:when>
    <xsl:otherwise>
      <xsl:message terminate="yes">
 Internal error: neither @proglang or $proglang is available for threadlink disambiguation
      </xsl:message>
    </xsl:otherwise>
    </xsl:choose>.html</xsl:variable>

    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <xsl:attribute name="href"><xsl:value-of
		select="$urlfrag"/><xsl:choose>
	
		<xsl:when test="boolean(@name)"><xsl:value-of select="concat(@name,'/',$index)"/><xsl:if
		    test="boolean(@id)"><xsl:value-of select="concat('#',@id)"/></xsl:if></xsl:when>

		<xsl:when test="boolean(@id)"><xsl:value-of select="concat($index,'#',@id)"/></xsl:when>

		<xsl:otherwise><xsl:value-of select="$index"/></xsl:otherwise>
	  </xsl:choose></xsl:attribute>

	  <xsl:apply-templates/>
	</a>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* name=threadlink-single-proglang *-->

  <!--*
      * We have multiple programming languages to deal with,
      * and - at present - we assume these are always
      * "sl" and "py". The output contains two links, one
      * to each version.
      *-->
  <xsl:template name="threadlink-multiple-proglang">
    <xsl:param name="in-thread" select="false()"/>

    <xsl:variable name="urlfrag"><xsl:call-template name="handle-thread-site-link">
      <xsl:with-param name="linktype"  select="'threadlink'"/>
      <xsl:with-param name="in-thread" select="$in-thread"/>
    </xsl:call-template></xsl:variable>

    <!--* is this correct? *-->
    <xsl:variable name="urlpagehead"><xsl:choose>
      <xsl:when test="boolean(@name)"><xsl:value-of select="concat(@name,'/')"/></xsl:when>
    </xsl:choose>index.</xsl:variable>

    <xsl:variable name="urltail">.html<xsl:if
    test="boolean(@id)"><xsl:value-of select="concat('#',@id)"/></xsl:if></xsl:variable>
    
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<xsl:apply-templates/>
	<xsl:text> (</xsl:text>
	<a>
	  <xsl:attribute name="href"><xsl:value-of
	  select='concat($urlfrag,$urlpagehead,"sl",$urltail)'/></xsl:attribute>
	  <xsl:text>S-Lang</xsl:text>
	</a>
	<xsl:text> or </xsl:text>
	<a>
	  <xsl:attribute name="href"><xsl:value-of
	  select='concat($urlfrag,$urlpagehead,"py",$urltail)'/></xsl:attribute>
	  <xsl:text>Python</xsl:text>
	</a>
	<xsl:text>)</xsl:text>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* name=threadlink-multiple-proglang *-->

  <!--*
      * this mess is to allow threadlink/threadpage to
      * link to the correct site/server.
      *
      * Parameters:
      *   linktype - string, required
      *     one of threadlink or threadpage
      *
      *   in-thread - boolean, only if linktype = threadlink
      *     are we linking from within a thread?
      *
      *   depth - usual
      *
      *-->
  <xsl:template name="handle-thread-site-link">
    <xsl:param name="linktype"  select="''"/>
    <xsl:param name="in-thread" select="false()"/>

    <xsl:variable name="urlfrag"><xsl:choose>
      <!--* do we start with the site or the depth? *-->
      <!--* UGH: this is horrible since it depends on what site/type we're doing *-->

      <!--*
	  * Need to think about whether links should be to asc-bak
	  * or to cxc in the test case
	  *-->
      <xsl:when test="boolean(@site) and @site != $site">/<xsl:value-of select="@site"/>/threads/</xsl:when>

      <!--*
	  * if within a thread
	  *   and linking to itself, do nothing
	  *   linking to another thread then add "../"
	  *   linking to the thread index then add "../"
	  *-->
      <xsl:when test="$in-thread"><xsl:if
				      test="boolean(@name)">../</xsl:if></xsl:when>

      <!--* was a complicated expression, hopefully we can just fall through to this now
	  <xsl:when test="$linktype = 'threadpage' or ($linktype = 'threadlink' and (not($in-thread) or boolean(@name)))"><xsl:call-template name="add-path">
	  *-->
      <xsl:otherwise><xsl:call-template name="add-path">
	<xsl:with-param name="idepth" select="$depth"/>
      </xsl:call-template>threads/</xsl:otherwise>
    </xsl:choose></xsl:variable>

    <xsl:value-of select="$urlfrag"/>

  </xsl:template> <!--* name=handle-thread-site-link *-->

  <!--*
      * add a link to the bug page
      * ONLY FOR site=iCXC
      *
      * Attributes:
      *    num, integer, required
      *      the bug number to link to
      *
      * If the contents are empty then we use the bug number
      *-->
  
  <xsl:template match="buglink">

    <!--* check we are in the iCXC site *-->
    <xsl:if test="$site != 'icxc'">
      <xsl:message terminate="yes">
  ERROR: the <xsl:value-of select="name()"/> tag can only be used in an iCXC document.

      </xsl:message>
    </xsl:if>

    <!--* check that the num attribute exists *-->
    <xsl:if test="boolean(@num) = false()">
      <xsl:message terminate="yes">
  ERROR: the <xsl:value-of select="name()"/> tag must contain a @num attribute
    contents="<xsl:value-of select="."/>"

      </xsl:message>
    </xsl:if>

    <!-- add the link -->
    <a href="https://icxc.harvard.edu/pipe/ascds_help/k2/cgi-bin/edit_bug_frame.cgi?bugno={@num}"><xsl:choose>
	<xsl:when test=".=''"><xsl:value-of select="@num"/></xsl:when>
	<xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
    </xsl:choose></a>
    
  </xsl:template> <!--* buglink *-->
  
  <!--*
      * add a <a name="id"></a> item to the document 
      * <id name="foo"/> or <id name="foo">...</id>
      *
      *-->
  <xsl:template match="id">

    <xsl:if test="boolean(@name)!='1'">
      <xsl:message terminate="yes">
  id tag MUST have a name attribute.
      </xsl:message>
    </xsl:if>
    <a name="{@name}"><xsl:apply-templates/></a>
  </xsl:template> <!--* id *-->

  <!--* 
      * handle-uc
      *
      * params:
      *   text - text to convert
      *   uc   - 0 or 1 (default = 0) convert text to upper case if uc=1 otherwise leave as is
      *
      *-->
  <xsl:template name="handle-uc">
    <xsl:param name="uc"   select="0"/>
    <xsl:param name="text" select="''"/>

    <xsl:choose>
      <xsl:when test="$uc=1"><xsl:value-of select="translate($text,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=handle-uc *-->

  <!--* 
      * returns a 0 if $site != ciao, a 1 otherwise
      *
      * example use:
      *   <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>
      *
      *-->
  <xsl:template name="not-in-ciao">
    <xsl:choose>
      <xsl:when test="$site='ciao'"><xsl:value-of select="0"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="1"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* not-in-ciao *-->

  <!--*
      * a helper tag: dies if the name attribute has been supplied
      * - only needed because we don't have a DTD
      *
      * Parameters:
      *   tag - string, optional (defaults to page)
      *     name of correct tag
      *
      *-->
  <xsl:template name="name-not-allowed">
    <xsl:param name="tag" select="'page'"/>

    <xsl:if test="boolean(@name)">
      <xsl:message terminate="yes">
 Error:
   a <xsl:value-of select="name()"/> tag has a name attribute (name=<xsl:value-of select="@name"/>)
   when it should (almost certainly) be <xsl:value-of select="$tag"/>=<xsl:value-of select="@name"/>
      </xsl:message>
    </xsl:if>
  </xsl:template>

  <!--*
      * a helper tag: dies if the page attribute has been supplied
      * - only needed because we don't have a DTD
      *
      *-->
  <xsl:template name="page-not-allowed">
    <xsl:if test="boolean(@page)">
      <xsl:message terminate="yes">
 Error:
   a <xsl:value-of select="name()"/> tag has a name attribute (page=<xsl:value-of select="@page"/>)
   when it should (almost certainly) be name=<xsl:value-of select="@page"/>
      </xsl:message>
    </xsl:if>
  </xsl:template>

  <!--*
      * a helper tag: dies if the name attribute contains .html
      *-->
  <xsl:template name="check-name-for-no-html">
    <!--* not sure if the boolean statements 'short circuit' as in C, so do them separately *-->
    <xsl:if test="boolean(@name)">
      <xsl:if test="contains(@name,'.html')">
	<xsl:message terminate="yes">
 Error:
   name attribute of <xsl:value-of select="name()"/> tag contains .html
   (name=<xsl:value-of select="@name"/>)
   If this is not wrong see Doug, because it should be...
	</xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!--*
      * a helper tag: dies if the id attribute contains .html
      *-->
  <xsl:template name="check-id-for-no-html">
    <!--* not sure if the boolean statements 'short circuit' as in C, so do them separately *-->
    <xsl:if test="boolean(@id)">
      <xsl:if test="contains(@id,'.html')">
	<xsl:message terminate="yes">
 Error:
   id attribute of <xsl:value-of select="name()"/> tag contains .html
   (id=<xsl:value-of select="@id"/>)
   If this is not wrong see Doug, because it should be...
	</xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!--*
      * a helper tag: dies if the page attribute contains .html
      *-->
  <xsl:template name="check-page-for-no-html">
    <!--* not sure if the boolean statements 'short circuit' as in C, so do them separately *-->
    <xsl:if test="boolean(@page)">
      <xsl:if test="contains(@page,'.html')">
	<xsl:message terminate="yes">
 Error:
   page attribute of <xsl:value-of select="name()"/> tag contains .html
   (page=<xsl:value-of select="@page"/>)
   If this is not wrong see Doug, because it should be...
	</xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!--*
      * used to create the start of the href attribute of a link
      * (a simpler version of the old mylink template)
      *
      * Parameters:
      *   extlink
      *   depth
      *   dirname
      *
      *-->
  <xsl:template name="add-start-of-href">
    <xsl:param name="extlink"/>
    <xsl:param name="dirname"/>

    <xsl:choose>
      <xsl:when test="$extlink=1">/ciao/</xsl:when>
      <xsl:otherwise><xsl:call-template name="add-path">
	  <xsl:with-param name="idepth" select="$depth"/>
	</xsl:call-template></xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="$dirname"/>

  </xsl:template> <!--* name=add-start-of-href *-->

  <!--*
      * because I don't want to have an anchor looking like /#foo
      * - since it messes up the tar file of the site/deosn't work
      *   with off-line browsing - it's a bit messy
      *
      * Assumes the context node contains (or can contain)
      #  @page and @id attributes
      *
      *-->
  <xsl:template name="sort-out-anchor">

    <xsl:choose>
      <xsl:when test="boolean(@page)"><xsl:value-of select="@page"/>.html<xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if></xsl:when>
      <xsl:when test="boolean(@id)">index.html#<xsl:value-of select="@id"/></xsl:when>
    </xsl:choose>

  </xsl:template> <!--* name=sort-out-anchor *-->

  <!--*
      * This should perhaps be in helper.xsl
      * It is used to check that links contain text (or a tag)
      *
      *-->
  <xsl:template name="check-contents-are-not-empty">
    <xsl:if test="count(child::*)=0 and normalize-space(.) = ''">
      <xsl:message terminate="yes">
 ERROR: the <xsl:value-of select="name()"/> node can not be empty<xsl:text>
</xsl:text>
   <xsl:for-each select="attribute::*">
     <xsl:value-of select="concat('  ',name(),'= ',.)"/><xsl:text>
</xsl:text>
   </xsl:for-each>
   <xsl:text>
</xsl:text>
      </xsl:message>
    </xsl:if>
  </xsl:template>

  <!--*
      * djb:get-thread-filename($name,$site)
      *
      * Returns the full path to the given thread; it
      * does not check that the name/site parameters
      * are valid.
      *
      *   $name is the thread name (ie as used in threadlink @name)
      *   $site is the site name (e.g. threadlink @site attribute)
      *     and can be left out, when it defaults to the site of the page
      *-->
  <func:function name="djb:get-thread-filename">
    <xsl:param name="name" select="''"/>
    <xsl:param name="site" select="$site"/>

    <xsl:if test="$name = ''">
      <xsl:message terminate="yes">
 Internal error: djb:get-thread-filename called with an empty name argument.
      </xsl:message>
    </xsl:if>

    <!--* this only needs to be tested once but do it every time, for now *-->
    <xsl:if test="$storageloc = ''">
      <xsl:message terminate="yes">
 Internal error: storageloc parameter is empty, needs to point to the storage XML file!
      </xsl:message>
    </xsl:if>

    <xsl:variable name="head" select="$storageInfo//dir[@site=$site]"/>
    <xsl:choose>
      <xsl:when test="count($head) = 0">
	<xsl:message terminate="yes">
 ERROR: no storage directory for site=<xsl:value-of select="$site"/> in
   storageloc=<xsl:value-of select="$storageloc"/>
	</xsl:message>
      </xsl:when>
      <xsl:when test="count($head) != 1">
	<xsl:message terminate="yes">
 ERROR: multiple storage directories for site=<xsl:value-of select="$site"/> in
   storageloc=<xsl:value-of select="$storageloc"/>
	</xsl:message>
      </xsl:when>
      <xsl:when test="substring($head,string-length($head))!='/'">
	<xsl:message terminate="yes">
 ERROR: storage directory for site=<xsl:value-of select="$site"/> in
   storageloc=<xsl:value-of select="$storageloc"/>
   does not end in a '/' - value=<xsl:value-of select="$head"/>
	</xsl:message>
      </xsl:when>
    </xsl:choose>

    <func:result select="concat($head,'threads/',$name,'/thread.xml')"/>

  </func:function> <!--* name djb:get-thread-filename *-->

  <!--*
      * Returns the //thread/info node for either the current document
      * (ie when dealing with the current thread) or that of a separate
      * document - determined by the @name attribute. To handle (ie hack)
      * threadlink calls that occur in included files we also check to
      * see whether the threadname "global" parameter has been set, and
      * use that when no @name and name(//*)!='thread'
      *
      * I am trying this in the hope that it will always return a node set,
      * since I am having troubles with handling the external files
      * otherwise.
      *
      * To do: deal with multiple sites
      *
      * At present assumed to be called with a threadlink tag as the
      * context node. Perhaps the input values should be sent in as
      * arguments to the function?
      *-->
  <func:function name="djb:read-in-thread-info">
    <xsl:choose>
      <xsl:when test="boolean(@site) and boolean(@name)">
	<xsl:variable name="adoc" select="document(djb:get-thread-filename(@name,@site))"/>
	<xsl:if test="count($adoc) = 0">
	  <xsl:message>
 WARNING: need to publish <xsl:value-of select="concat('thread=',@name,' site=',@site)"/>
          and then re-publish this page.
	  </xsl:message>
	</xsl:if>
	<func:result select="$adoc//thread/info"/>
      </xsl:when>

      <xsl:when test="boolean(@name)">
	<xsl:variable name="bdoc" select="document(djb:get-thread-filename(@name))"/>
	<xsl:if test="count($bdoc) = 0">
	  <xsl:message>
 WARNING: need to publish <xsl:value-of select="concat('thread=',@name)"/>
          and then re-publish this page.
	  </xsl:message>
	</xsl:if>
	<func:result select="$bdoc//thread/info"/>
      </xsl:when>

      <xsl:when test="name(//*) = 'thread'">
	<func:result select="//thread/info"/>
<!--	<func:result select="$threadInfo"/>   should be able to say this but haven't tested it -->
      </xsl:when>

      <!--*
          * This is a hack to deal with threadlink tags in an included
	  * file that refer to the parent thread
	  *-->

      <xsl:when test="$threadName != ''">
	<xsl:variable name="cdoc" select="document(djb:get-thread-filename($threadName))"/>
	<xsl:if test="count($cdoc) = 0">
	  <xsl:message>
 WARNING: need to publish <xsl:value-of select="concat('thread=',$threadName)"/>
          and then re-publish this page.
	  </xsl:message>
	</xsl:if>
	<func:result select="$cdoc//thread/info"/>
      </xsl:when>

      <xsl:otherwise>
	<xsl:message terminate="yes">
  ERROR: internal error - djb:read-in-thread-info
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </func:function> <!--* name=djb:read-in-thread-info *-->

</xsl:stylesheet>
