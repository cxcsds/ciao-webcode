<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!-- $Id: links.xsl,v 1.55 2003/09/15 14:30:57 dburke Exp $ -->

<!--* attempt to provide a common stylesheet for links *-->

<!--*
    * Recent changes:
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

    *  . ahelpindex=full path to ahelp index file created by ahelp2html.pl
    *    something like /data/da/Docs/ciaoweb/published/ciao3/live/ahelp/seealso-index.xml
    *    Used to work out the ahelp links
    *

  <xsl:param name="ahelpindex"  select='""'/>
  <xsl:variable name="ahelpindexfile" select="document($ahelpindex)"/>

    * 
    * 
    * 
    * 
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
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
      * Link to the ahelp index page
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
      *-->
  <xsl:template match="ahelppage">
    <xsl:param name="depth" select="1"/>

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
   type attribute of ahelppage tag must be one of:
       main alphabet context
   and not <xsl:value-of select="@type"/>)

      </xsl:message>
    </xsl:if>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* link to ahelp index page *-->
    <a>
      <xsl:call-template name="add-whylink-style"/>
      <xsl:attribute name="title">Ahelp index</xsl:attribute>
      <xsl:attribute name="href">
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="depth"   select="$depth"/>
	  <xsl:with-param name="dirname" select="'ahelp/'"/>
	</xsl:call-template><xsl:choose>
	  <xsl:when test="@type = 'alphabet'">index_alphabet.html</xsl:when>
	  <xsl:when test="@type = 'context'">index_context.html</xsl:when>
	  </xsl:choose><xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if></xsl:attribute>

      <!--* text *-->
      <xsl:choose>
	<xsl:when test=".=''">Ahelp page</xsl:when>
	<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

  </xsl:template> <!--* ahelppage *-->

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
      * aren't multiple matches)
      *
      * - just after CIAO 3.0 release we added the summary for the ahelp
      *   page as a title attribute: this is displayed by modern browsers
      *   as a tool tip, but not by netscape 4
      *
      *-->

  <xsl:template match="ahelp">
    <xsl:param name="depth" select="1"/>

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
        *-->
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="namematches" select="$ahelpindexfile//ahelp[key=$name]"/>
    <xsl:if test="count($namematches)=0">
	<xsl:message terminate="yes">

 ERROR: have ahelp tag with unknown name of <xsl:value-of select="$name"/> 

      </xsl:message>
    </xsl:if>

    <xsl:variable name="context"><xsl:choose>
	<xsl:when test="boolean(@context)"><xsl:value-of select="@context"/></xsl:when>
	<xsl:when test="count($namematches)=1"><xsl:value-of select="$namematches/context"/></xsl:when>
	<xsl:otherwise>
	  <xsl:message terminate="yes">

 ERROR: have ahelp tag with name of <xsl:value-of select="$name"/>
   that matches more than one context. You need to add a context attribute

	  </xsl:message>
	</xsl:otherwise>
      </xsl:choose></xsl:variable>
    
    <!--* should only have 0 or 1 matches here *-->
    <xsl:variable name="matches" select="$namematches[context=$context]"/>
    <xsl:if test="count($matches)!=1">
      <xsl:message terminate="yes">

 ERROR: unable to find a ahelp match for
   name=<xsl:value-of select="$name"/> context=<xsl:value-of select="$context"/>

      </xsl:message>
    </xsl:if>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <a>
      <xsl:call-template name="add-whylink-style"/>
      <xsl:attribute name="href">

	<!--* where do we find the ahelp directory? *-->
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="depth"   select="$depth"/>
	  <xsl:with-param name="dirname" select="'ahelp/'"/>
	</xsl:call-template>
	<xsl:value-of select="$matches/page"/>.html<xsl:choose>
	  <xsl:when test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:when>
	  <xsl:when test="boolean(@param)">#plist.<xsl:value-of select="@param"/></xsl:when>
	</xsl:choose>
      </xsl:attribute> <!--* end of href *-->

      <!--*
          * Add the summary as a title attribute. There should be a summary
          * tag for all ahelp pages but just in case there isn't we use an if statement.
          *-->
      <xsl:if test="$matches/summary!=''">
	<xsl:attribute name="title">Ahelp: <xsl:value-of select="$matches/summary"/></xsl:attribute>
      </xsl:if>

      <!--* and now the text contents
          * if the contents are empty, the we have to use either @name or @param
	  * (which we may have to turn into uppercase).
	  *-->
      <xsl:choose>
	<!--* use the supplied text *-->
	<xsl:when test=".!=''"><xsl:value-of select="."/></xsl:when>

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

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>
    
  </xsl:template> <!--* ahelp *-->

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
    <xsl:param name="depth" select="1"/>

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
	<xsl:when test="$site != 'ciao' and $site != 'sherpa'">/ciao/faq/</xsl:when>
	<xsl:otherwise><xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="0"/>
	    <xsl:with-param name="depth"   select="$depth"/>
	    <xsl:with-param name="dirname" select="'faq/'"/>
	  </xsl:call-template></xsl:otherwise>
      </xsl:choose></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* are we linking to the whole file, or a specific part of it? *-->
    <a>
      <xsl:call-template name="add-whylink-style"/>
      <xsl:attribute name="title">CIAO Frequently Asked Questions</xsl:attribute>
      <xsl:attribute name="href"><xsl:value-of select="$hrefstart"/><xsl:if test="boolean(@id)"><xsl:value-of select="@id"/>.html</xsl:if></xsl:attribute>

      <!--* text *-->
      <xsl:choose>
	<xsl:when test=".=''">this FAQ</xsl:when>
	<xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
      </xsl:choose>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

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
    <xsl:param name="depth" select="1"/>

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed"/>

    <!--* check id attribute *-->
    <xsl:call-template name="check-id-for-no-html"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* do we link to the index or a separate page? *-->
    <a>
      <xsl:call-template name="add-whylink-style"/>
      <xsl:attribute name="title">CIAO Dictionary</xsl:attribute>
      <xsl:attribute name="href">

	<!--* where do we find the dictionary directory? *-->
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="depth"   select="$depth"/>
	  <xsl:with-param name="dirname" select="'dictionary/'"/>
	</xsl:call-template>

	<xsl:if test="boolean(@id)"><xsl:value-of select="@id"/>.html</xsl:if>
      </xsl:attribute>

      <!--* text *-->
      <xsl:value-of select="."/>
    </a>
    
    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>
    
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
    <xsl:param name="depth" select="1"/>

    <!--* are we linking to the index page or a specific one *-->
    <a>
      <xsl:call-template name="add-whylink-style"/>
      <xsl:attribute name="title">The Proposer's Observatory Guide</xsl:attribute>
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
    <xsl:param name="depth" select="1"/>

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
	<xsl:otherwise>
	  <!--* either chips or detect *-->
	  <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>
	  <xsl:call-template name="add-start-of-href">
	    <xsl:with-param name="extlink" select="$extlink"/>
	    <xsl:with-param name="depth"   select="$depth"/>
	    <xsl:with-param name="dirname">download/doc/<xsl:value-of select="@name"/>_html_manual/</xsl:with-param>
	  </xsl:call-template>
	</xsl:otherwise></xsl:choose></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <a>
      <xsl:attribute name="href"><xsl:value-of select="$href"/><xsl:call-template name="sort-out-anchor"/></xsl:attribute>
      <!--* text *-->
      <xsl:choose>
	<xsl:when test=".=''">
<xsl:message terminate="yes">
 ERROR:
   manual tag (name=<xsl:value-of select="@name"/> page=<xsl:value-of select="@page"/>)
   used without any link text 
</xsl:message>
	</xsl:when>
	<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>
    
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
    <xsl:param name="depth" select="1"/>

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
	<xsl:when test="@site='ciao' or @site = ''">
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

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* link to manuals page *-->
    <a href="{$href}"><xsl:choose>
	<xsl:when test=".=''">Manuals page</xsl:when>
	<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose></a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

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
    <xsl:param name="depth" select="1"/>

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed"/>

    <!--* check name attribute *-->
    <xsl:call-template name="check-page-for-no-html"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* link to data products guide *-->
    <a>
      <xsl:attribute name="href">
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="depth"   select="$depth"/>
	  <xsl:with-param name="dirname" select="'data_products_guide/'"/>
	</xsl:call-template>
	<xsl:call-template name="sort-out-anchor"/>
      </xsl:attribute>

      <!--* text *-->
      <xsl:choose>
	<xsl:when test=".=''">Data Products Guide</xsl:when>
	<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

  </xsl:template> <!--* dpguide *-->

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
    <xsl:param name="depth" select="1"/>

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed"/>

    <!--* check name attribute *-->
    <xsl:call-template name="check-page-for-no-html"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* link to caveat *-->
    <a>
      <xsl:attribute name="href">
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="depth"   select="$depth"/>
	  <xsl:with-param name="dirname" select="'caveats/'"/>
	</xsl:call-template>
	<xsl:call-template name="sort-out-anchor"/>
      </xsl:attribute>

      <!--* text *-->
      <xsl:choose>
	<xsl:when test=".=''">
<xsl:message terminate="yes">
 ERROR:
   caveat tag (name=<xsl:value-of select="@name"/> id=<xsl:value-of select="@id"/>)
   used without any link text 
</xsl:message>
	</xsl:when>
	<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

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
    <xsl:param name="depth" select="1"/>

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed"/>

    <!--* check name attribute *-->
    <xsl:call-template name="check-page-for-no-html"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* link to analysis guides *-->
    <a>
      <xsl:call-template name="add-whylink-style"/>
      <xsl:attribute name="title">CIAO Analysis Guides</xsl:attribute>
      <xsl:attribute name="href">
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="depth"   select="$depth"/>
	  <xsl:with-param name="dirname" select="'guides/'"/>
	</xsl:call-template>
	<xsl:call-template name="sort-out-anchor"/>
      </xsl:attribute>

      <!--* text *-->
      <xsl:choose>
	<xsl:when test=".=''">
<xsl:message terminate="yes">
 ERROR:
   aguide tag (name=<xsl:value-of select="@name"/> id=<xsl:value-of select="@id"/>)
   used without any link text 
</xsl:message>
	</xsl:when>
	<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

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
    <xsl:param name="depth" select="1"/>

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="name-not-allowed"/>

    <!--* check name attribute *-->
    <xsl:call-template name="check-page-for-no-html"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* link to why documents *-->
    <a>
      <xsl:call-template name="add-whylink-style"/>
      <xsl:attribute name="title">CIAO "Why" Topics</xsl:attribute>
      <xsl:attribute name="href">
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="depth"   select="$depth"/>
	  <xsl:with-param name="dirname" select="'why/'"/>
	</xsl:call-template>
	<xsl:call-template name="sort-out-anchor"/>
      </xsl:attribute>

      <!--* text *-->
      <xsl:choose>
	<xsl:when test=".=''">
<xsl:message terminate="yes">
 ERROR:
   why tag (name=<xsl:value-of select="@name"/> id=<xsl:value-of select="@id"/>)
   used without any link text 
</xsl:message>
	</xsl:when>
	<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

  </xsl:template> <!--* why *-->

  <!--*
      * handle download tags:
      * produces different links depending on whether type=test or live
      *
      * similar to the faq tag, except that we are linking to the download page.
      *
      * NOTE: there is no default text for the link - you must supply it
      *
      * The id of the
      * download (ie the bit to the right of the documents_foo.html#)
      * is given in the id attribute. This is optional.
      *
      * CURRENTLY links to the CIAO download page only
      *-->

  <xsl:template match="download">
    <xsl:param name="depth" select="1"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* are we linking to the whole file, or a specific part of it? *-->
    <a>
      <xsl:attribute name="href">
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="depth"   select="$depth"/>
	  <xsl:with-param name="dirname" select="''"/>
	</xsl:call-template>
	<xsl:text>download_ciao_reg.html</xsl:text>
	<xsl:if test='boolean(@id)'>#<xsl:value-of select="@id"/></xsl:if>
      </xsl:attribute>

      <!--* text *-->
      <xsl:choose>
	<xsl:when test=".=''">
<xsl:message terminate="yes">
 ERROR:
   download tag (id=<xsl:value-of select="@id"/>)
   used without any link text 
</xsl:message>
	</xsl:when>
	<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>
    
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
    <xsl:param name="depth" select="1"/>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <xsl:call-template name="create-script-link">
      <xsl:with-param name="name"  select="@name"/>
      <xsl:with-param name="text"  select="."/>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:call-template>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>
    
  </xsl:template> <!--* match=script *-->

  <xsl:template name="create-script-link">
    <xsl:param name="name"  select="''"/>
    <xsl:param name="text"  select="''"/>
    <xsl:param name="depth" select="1"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* link to script *-->
    <a>
      <xsl:attribute name="href">
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="depth"   select="$depth"/>
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
    <xsl:param name="depth" select="1"/>

    <!--* are we in the ciao pages or not (ie is this an `external' link or not) *-->
    <xsl:variable name="extlink"><xsl:call-template name="not-in-ciao"/></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* link to script page *-->
    <a>
      <xsl:attribute name="href">
	<xsl:call-template name="add-start-of-href">
	  <xsl:with-param name="extlink" select="$extlink"/>
	  <xsl:with-param name="depth"   select="$depth"/>
	  <xsl:with-param name="dirname" select="'download/scripts/'"/>
	</xsl:call-template>
	<xsl:if test="boolean(@id)">index.html#<xsl:value-of select="@id"/></xsl:if>
      </xsl:attribute>

      <!--* text *-->
      <xsl:choose>
	<xsl:when test=".=''">Scripts page</xsl:when>
	<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

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
    <xsl:param name="depth" select="1"/>

    <!--* warn if there's a better option *-->
    <xsl:if test="$site != 'icxc' and starts-with(@href,'http://cxc.harvard.edu')">
      <xsl:message>
  Warning: extlink href=<xsl:value-of select="@href"/>
  should be cxclink href=<xsl:value-of select="substring(@href,23)"/>
      </xsl:message>
    </xsl:if>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <a><xsl:attribute name="href"><xsl:value-of select="@href"/><xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if></xsl:attribute><xsl:apply-templates/></a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

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
    <xsl:param name="depth" select="1"/>

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
    <xsl:if test="contains(@href,'documents_thread') or contains(@href,'threads/')">
      <xsl:call-template name="warn-in-cxclink"><xsl:with-param name="link" select="'threadpage'"/></xsl:call-template>
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

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <a>
      <!--* will whitespace mess things up?
          * also note the ugly way I find the name of the root node (ie 'name(//*)')
          *-->
      <xsl:attribute name="href">
	<xsl:if test="starts-with(@href,'/')=false() and name(//*)='navbar'"><xsl:call-template name="add-path">
	    <xsl:with-param name="idepth" select="$depth"/>
	  </xsl:call-template></xsl:if>
        <xsl:value-of select="@href"/><xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if>
      </xsl:attribute>
      <xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>
    
  </xsl:template> <!--* cxclink *-->                                            

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
    <xsl:param name="depth" select="1"/>

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

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <a>
      <!--* will whitespace mess things up?
          * also not the ugly way I find the name of the root node (ie 'name(//*)')
          *-->
      <xsl:attribute name="href">
        <xsl:choose>
	  <xsl:when test="boolean($extlink)=false() and name(//*)='navbar'"><xsl:call-template name="add-path">
	    <xsl:with-param name="idepth" select="$depth"/>
	    </xsl:call-template></xsl:when>
        </xsl:choose>
        <xsl:value-of select="@href"/><xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if>
      </xsl:attribute>
      <xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>
    
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
    <xsl:param name="depth" select="1"/>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <!--* could just set href directly but want class to appear first (for testing) *-->
    <a>
      <xsl:call-template name="add-whylink-style"/>
      <xsl:attribute name="title">CXC Helpdesk</xsl:attribute>
      <xsl:attribute name="href">/helpdesk/</xsl:attribute>
      <xsl:choose>
	<xsl:when test=".=''">Helpdesk</xsl:when>
	<xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
      </xsl:choose>
    </a>
    
    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>
    
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
    <xsl:param name="depth" select="1"/>

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="page-not-allowed"/>

    <!--* set up the url fragment:
        *   a) handle the site/depth
        *   b) handle the file location and is there an anchor too?
        *-->
    <xsl:variable name="urlfrag"><xsl:call-template name="handle-thread-site-link">
	<xsl:with-param name="depth"     select="$depth"/>
	<xsl:with-param name="linktype"  select="'threadpage'"/>
      </xsl:call-template></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <a>
      <!--* add the href attibute *-->
      <xsl:call-template name="add-attribute">
	<!--* we've added the depth to the url above (if it's needed), so we set depth to 1 here *-->
	<xsl:with-param name="depth" select="1"/>
	<xsl:with-param name="name"  select="'href'"/>
	<xsl:with-param name="value"><xsl:value-of
	    select="$urlfrag"/><xsl:choose>
	    <!--* which index page? *-->
	    <xsl:when test="boolean(@name)"><xsl:value-of select="@name"/></xsl:when>
	    <xsl:otherwise>index</xsl:otherwise>
	  </xsl:choose>.html<xsl:if test="boolean(@id)">#<xsl:value-of select="@id"/></xsl:if></xsl:with-param>
      </xsl:call-template>

      <!--* process the contents of the tag *-->
      <xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

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
      *  id only is only allowed if the rootnode is thread
      *    OR dummy (ie an include file)
      *
      *-->

  <xsl:template match="threadlink">
    <xsl:param name="depth" select="1"/>

    <!--* since we don't have a DTD *-->
    <xsl:call-template name="page-not-allowed"/>

    <!--* are we within a thread (or an included file)? *-->
    <xsl:variable name="in-thread" select="name(//*)='thread' or name(//*)='dummy'"/>

    <!--* set up the url fragment:
        *   a) handle the site/depth
        *   b) handle the file location and is there an anchor too?
        *-->
    <xsl:variable name="urlfrag"><xsl:call-template name="handle-thread-site-link">
	<xsl:with-param name="depth"     select="$depth"/>
	<xsl:with-param name="linktype"  select="'threadlink'"/>
	<xsl:with-param name="in-thread" select="$in-thread"/>
      </xsl:call-template></xsl:variable>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <a>
      <!--* add the href attibute *-->
      <xsl:call-template name="add-attribute">
	<!--* we've added the depth to the url above (if it's needed), so we set depth to 1 here *-->
	<xsl:with-param name="depth" select="1"/>
	<xsl:with-param name="name"  select="'href'"/>
	<xsl:with-param name="value"><xsl:value-of
	    select="$urlfrag"/><xsl:choose>
	    <!--* and now the actual directory/file *-->
	
	    <!--* name specified (id may or may not be) *-->
	    <xsl:when test="boolean(@name)"><xsl:value-of select="@name"/>/<xsl:if
		test="boolean(@id)">index.html#<xsl:value-of select="@id"/></xsl:if></xsl:when>

	    <!--* 
                * the following options (id only or no attribute) are
                * only allowed within a thread
                *-->
	    <xsl:when test="$in-thread=false()">
	      <xsl:message terminate="yes">
  threadlink tag must contain a name attribute when not used in a thread.
  If you want to link to the thread index page use the
  threadpage tag.
  Thread contents:
  <xsl:value-of select="."/>
	      </xsl:message>
	    </xsl:when>
	
	    <!--* 
                * if id only then we include the index.html in the URL to make
                * offline browsing/site-packaging code to work
                *-->
	    <xsl:when test="boolean(@id)">index.html#<xsl:value-of select="@id"/></xsl:when>

	    <!--* link to itself (a bit pointless) *-->
	    <xsl:otherwise>index.html</xsl:otherwise>
	  </xsl:choose></xsl:with-param>
      </xsl:call-template>

      <!--* process the contents of the tag *-->
      <xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </a>

    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

  </xsl:template> <!--* threadlink *-->

  <!--*
      * this mess is to allow threadlink/threadpage to
      * link to the correct site/server
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
    <xsl:param name="depth"     select="1"/>

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

    <!--* return the value *-->
    <xsl:value-of select="$urlfrag"/>
  </xsl:template> <!--* name=handle-thread-site-link *-->

  <!--*
      * add a <a name="id"></a> item to the document 
      * <id name="foo"/> or <id name="foo">...</id>
      *
      *-->
  <xsl:template match="id">
    <xsl:param name="depth" select="1"/>

    <xsl:if test="boolean(@name)!='1'">
      <xsl:message terminate="yes">
  id tag MUST have a name attribute.
      </xsl:message>
    </xsl:if>
    <a name="{@name}"><xsl:apply-templates><xsl:with-param name="depth" select="$depth"/></xsl:apply-templates></a>
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
      * returns a 1 if $site != ciao, a 1 otherwise
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
      * for links on the register page: we have 2 versions of the
      * link, one that goes to the register page, the other that
      * goes to the actual URL/data file/whatever.
      *
      * Can *only* be used in a register page
      *
      * parameters:
      *   regtype -
      *     "global" parameter determines whether the "send to register"
      *     or "sent to data" link is to be created
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

    <!--* check that we are in a "register" page *-->
    <xsl:variable name="root" select="name(//*)"/>
    <xsl:if test="$root != 'register'">
      <xsl:message terminate="yes">
 Error:
   reglink has been used in a non-register document.
      </xsl:message>
    </xsl:if>

    <!--* check that $regtype is known (just to check programming errors) *-->
    <xsl:if test="$regtype != 'register' and $regtype != 'data'">
      <xsl:message terminate="yes">
 Error:
   regtype variable (<xsl:value-of select="$regtype"/>) is invalid
      </xsl:message>
    </xsl:if>

    <!--* what params have been supplied? *-->
    <xsl:choose>
      <xsl:when test="boolean(@dir) and boolean(@file)">

	<tt><a><xsl:choose>
	      <xsl:when test="$regtype = 'register'">
		<xsl:attribute name="href"><xsl:call-template name="add-path">
		    <xsl:with-param name="idepth" select="$depth"/>
		  </xsl:call-template>register.html</xsl:attribute>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:attribute name="href">ftp://cxc.harvard.edu/pub/<xsl:value-of select="@dir"/><xsl:value-of select="@file"/></xsl:attribute>
	      </xsl:otherwise>
	    </xsl:choose><xsl:value-of select="@file"/></a></tt>
	
      </xsl:when>

      <xsl:when test="boolean(@register) and boolean(@href)">

	<a><xsl:choose>
	    <xsl:when test="$regtype = 'register'">
	      <xsl:attribute name="href"><xsl:value-of select="@register"/></xsl:attribute>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
	    </xsl:otherwise>
	  </xsl:choose><xsl:apply-templates/></a>

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
    <xsl:param name="depth"/>
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
      * Indicate this is an "informational" link.
      * It is up to the stylesheet + browser to render this
      * - I hope it does not mess up htmldoc
      *-->
  <xsl:template name="add-whylink-style">
    <xsl:attribute name="class">helplink</xsl:attribute>
  </xsl:template>
    
</xsl:stylesheet>
