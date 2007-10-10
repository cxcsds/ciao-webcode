<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Useful templates for creating the CIAO threads
    *
    * $Id: thread_common.xsl,v 1.25 2003/09/15 20:14:07 dburke Exp $ 
    *-->

<!--* 
    * Recent changes:
    *  v1.24 - PDF links now have a title attribute
    *  v1.23 - previous change included not adding p../p around some text blocks
    *          if they already contained p tags; this is a fix to that check
    *  v1.22 - more changes to the layout of the blocks in the synopsis section
    *  v1.21 - call add-header/footer so that the PDF links are created correctly for images
    *          all TOC links should now be of the form index.html#<anchor>
    *  v1.20 - #start-thread -> index.html#start-thread
    *  v1.19 - CIAO 3.0 layout changes
    *  v1.18 - Sherpa threads now have links to thread sections a la CIAO threads
    *          (instead of 'Insert link here' text)
    *  v1.17 - paramfile/plist: now combine name and id to form anchor
    *  v1.16 - more changes to look of overview section
    *  v1.15 - more changes to look of overview section [updated info to right of title]
    *  v1.14 - added chart top/bottom links, overview section now has width=100%,
    *          overview section now only requires the "why" field, last mod date now first
    *  v1.13 - fixed up anchor problem
    *  v1.12 - overview now in red tag, background iis light grey (experimental)
    *          and hr after overview is now bold
    *  v1.11 - handling of overview vs introduction
    *  v1.10 - removed xsl-revision/version tags since defined in most stylesheets
    *          which libxslt no-longer likes.
    *   v1.9 - remove before/after tags (but not contents) from output
    *   v1.8 - removed comented code (variables that are set up in stylesheet)
    *   v1.7 - subsection's handled through a pull-style approach; apply to more templates?
    *   v1.6 - fudge to remove extra HR when no param block: needs reworking
    *   v1.5 - minor cleanups from using on threads
    *   v1.4 - added add-bottom-links-pog-html
    *   v1.3 - fixed add-hardcopy-links calls, added image[mode=list]
    *   v1.2 - moved add-hr-strong, add-id-hardcopy to helper.xsl
    *
    * User-defineable parameters:
    *  - defined in including stylesheets
    *
    * Notes:
    *  - do we really need to bother with depth as a parameter
    *    since we know it'll be fixed for a single run.
    *    There are templates for which we need to send it in as
    *    a parameter (ie templates in links.xsl) but that shuold
    *    be okay since we just don't remove them
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--* we create the HTML files using xsl:document statements *-->
  <xsl:output method="text"/>

  <!--*
      * set up the "top level" links for the HTML page
      * [links to processing/names threads, thread index,
      *  and hardcopy versions]
      *
      * Parameters:
      *   depth, number, required
      *     - standard meaning
      *
      * Updated for CIAO 3.0 to remove some 'excess' baggage
      *
      *-->
  <xsl:template name="add-top-links-ciao-html">
    <xsl:param name="depth" select="1"/>

    <!--* safety check *-->
    <xsl:if test="$site != 'ciao'">
      <xsl:message terminate="yes">
  Error: template add-top-links-ciao-html called but not for a CIAO thread
      </xsl:message>
    </xsl:if>

    <div class="topbar">
      <div class="qlinkbar">
	<!--* create links to threads *-->
	<xsl:call-template name="add-thread-qlinks">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:call-template>
      </div>
    </div>

  </xsl:template> <!--* name=add-top-links-ciao-html *-->

  <!--*
      * set up the "top level" links for the HTML page (ChaRT)
      * [links to processing/names threads, thread index,
      *  and hardcopy versions]
      *
      * Parameters:
      *   depth, number, required
      *     - standard meaning
      *
      *-->
  <xsl:template name="add-top-links-chart-html">
    <xsl:param name="depth" select="1"/>

    <!--* safety check *-->
    <xsl:if test="$site != 'chart'">
      <xsl:message terminate="yes">
  Error: template add-top-links-chart-html called but not for a ChaRT thread
      </xsl:message>
    </xsl:if>

    <div class="topbar">
      <div class="qlinkbar">
	<!--* create links to threads *-->
	Return to 
	<xsl:call-template name="mylink">
	  <xsl:with-param name="depth" select="$depth"/>
	  <xsl:with-param name="dir">../</xsl:with-param>
	  <xsl:with-param name="filename"></xsl:with-param>
	  <xsl:with-param name="text">Threads Page</xsl:with-param>
	</xsl:call-template>
      </div>
    </div>

  </xsl:template> <!--* name=add-top-links-chart-html *-->

  <!--*
      * set up the "top level" links for the HTML page (Sherpa)
      * [links to processing/names threads, thread index,
      *  and hardcopy versions]
      *
      * Parameters:
      *   depth, number, required
      *     - standard meaning
      *
      *-->
  <xsl:template name="add-top-links-sherpa-html">
    <xsl:param name="depth" select="1"/>

    <!--* safety check *-->
    <xsl:if test="$site != 'sherpa'">
      <xsl:message terminate="yes">
  Error: template add-top-links-sherpa-html called but not for a Sherpa thread
      </xsl:message>
    </xsl:if>

    <div class="topbar">
      <div class="qlinkbar">
      <!--* create links to threads *-->
	<xsl:call-template name="add-thread-qlinks">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:call-template>
      </div>
    </div>

  </xsl:template> <!--* name=add-top-links-sherpa-html *-->

  <!--*
      * set up the "top level" links for the HTML page (POG)
      * [links to processing/names threads, thread index,
      *  and hardcopy versions]
      *
      * Parameters:
      *   depth, number, required
      *     - standard meaning
      *
      *-->
  <xsl:template name="add-top-links-pog-html">
    <xsl:param name="depth" select="1"/>

    <!--* safety check *-->
    <xsl:if test="$site != 'pog'">
      <xsl:message terminate="yes">
  Error: template add-top-links-pog-html called but not for a POG thread
      </xsl:message>
    </xsl:if>

    <div class="topbar">
      <div class="qlinkbar">
	<!--* create links to threads *-->
	Return to 
	<xsl:call-template name="mylink">
	  <xsl:with-param name="depth" select="$depth"/>
	  <xsl:with-param name="dir">../</xsl:with-param>
	  <xsl:with-param name="filename"></xsl:with-param>
	  <xsl:with-param name="text">Threads Page</xsl:with-param>
	</xsl:call-template>
      </div>
    </div>

  </xsl:template> <!--* name=add-top-links-pog-html *-->

  <!--*
      * set up the "trailing" links for the HTML page
      * [links to thread indexes and hardcopy versions]
      *
      * Parameters:
      *   depth, number, required
      *     - standard meaning
      *
      * *****CIAO SPECIFIC*****
      *
      *-->
  <xsl:template name="add-bottom-links-html">
    <xsl:param name="depth" select="1"/>

    <!--* safety check *-->
    <xsl:if test="$site != 'ciao'">
      <xsl:message terminate="yes">
  Error: template add-bottom-links-html called but not for a CIAO thread
      </xsl:message>
    </xsl:if>

    <!--* create the trailing links to threads *-->
    <div class="bottombar">
      <!--* create links to threads *-->
      <xsl:call-template name="add-thread-qlinks">
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:call-template>
    </div>

  </xsl:template> <!--* name=add-bottom-links-html *-->

  <!--*
      * set up the "trailing" links for the HTML page (ChaRT)
      * [links to thread indexes and hardcopy versions]
      *
      * Parameters:
      *   depth, number, required
      *     - standard meaning
      *
      *-->
  <xsl:template name="add-bottom-links-chart-html">
    <xsl:param name="depth" select="1"/>

    <!--* safety check *-->
    <xsl:if test="$site != 'chart'">
      <xsl:message terminate="yes">
  Error: template add-bottom-links-chart-html called but not for a ChaRT thread
      </xsl:message>
    </xsl:if>

    <!--* create the trailing links to threads *-->
    <div class="bottombar">
      <!--* create links to threads *-->
      Return to 
      <xsl:call-template name="mylink">
	<xsl:with-param name="depth" select="$depth"/>
	<xsl:with-param name="dir">../</xsl:with-param>
	<xsl:with-param name="filename"></xsl:with-param>
	<xsl:with-param name="text">Threads Page</xsl:with-param>
      </xsl:call-template>
    </div>

  </xsl:template> <!--* name=add-bottom-links-chart-html *-->

  <!--*
      * set up the "trailing" links for the HTML page (Sherpa)
      * [links to thread indexes and hardcopy versions]
      *
      * Parameters:
      *   depth, number, required
      *     - standard meaning
      *
      *-->
  <xsl:template name="add-bottom-links-sherpa-html">
    <xsl:param name="depth" select="1"/>

    <!--* safety check *-->
    <xsl:if test="$site != 'sherpa'">
      <xsl:message terminate="yes">
  Error: template add-bottom-links-sherpa-html called but not for a Sherpa thread
      </xsl:message>
    </xsl:if>

    <!--* create the trailing links to threads *-->
    <div class="bottombar">
      <!--* create links to threads *-->
      <xsl:call-template name="add-thread-qlinks">
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:call-template>
    </div>

  </xsl:template> <!--* name=add-bottom-links-sherpa-html *-->

  <!--*
      * set up the "trailing" links for the HTML page (POG)
      * [links to thread indexes and hardcopy versions]
      *
      * Parameters:
      *   depth, number, required
      *     - standard meaning
      *
      * At the moment this is the same as the ChaRT version
      *
      *-->
  <xsl:template name="add-bottom-links-pog-html">
    <xsl:param name="depth" select="1"/>

    <!--* safety check *-->
    <xsl:if test="$site != 'pog'">
      <xsl:message terminate="yes">
  Error: template add-bottom-links-pog-html called but not for a POG thread
      </xsl:message>
    </xsl:if>

    <!--* create the trailing links to threads *-->
    <div class="bottombar">
      <!--* create links to threads *-->
      Return to 
      <xsl:call-template name="mylink">
	<xsl:with-param name="depth" select="$depth"/>
	<xsl:with-param name="dir">../</xsl:with-param>
	<xsl:with-param name="filename"></xsl:with-param>
	<xsl:with-param name="text">Threads Page</xsl:with-param>
      </xsl:call-template>
    </div>
    
  </xsl:template> <!--* name=add-bottom-links-pog-html *-->

  <!--*
      * Add the introductory text:
      *  as of CIAO 3.0 this can either be the introduction block
      *  OR the overview block, the latter being more formalised
      *  in its content
      *
      * Parameters:
      *   depth - standard meaning
      *
      *   hardcopy, 0|1, optional
      *     - is this for the hardcopy version of the HTML page?
      *       (default is 0)
      *
      *-->
  <xsl:template name="add-introduction">
    <xsl:param name="depth" select="1"/>
    <xsl:param name="hardcopy" select="0"/>

    <xsl:choose>
      <xsl:when test="boolean(text/introduction) and boolean(text/overview)">
	<xsl:message terminate="yes">

 ERROR:
   The text block contains an introduction AND an overview section.
   Only one is allowed.

	</xsl:message>
      </xsl:when>

      <xsl:when test="boolean(text/introduction)">
	<br/>
	<h2><a name="introduction">Introduction</a></h2>
	<xsl:apply-templates select="text/introduction">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
	<br/><hr/><br/>
      </xsl:when> <!--* text/introduction *-->

      <!--*
          * try and make the overview stand out
          * We use a table to get the background colour and
          * width (since we can't use CSS for it due to the
          * use of htmldoc)
          *-->
      <xsl:when test="boolean(text/overview)">
	<br/>
	<table width="100%" border="0" bgcolor="#eeeeee">
	  <tr>
	    <td>
	      <h2><a name="overview"><font color="red">Overview</font></a></h2>
	      <xsl:apply-templates select="text/overview">
		<xsl:with-param name="depth" select="$depth"/>
	      </xsl:apply-templates>
	    </td>
	  </tr>
	</table>
	<br/><xsl:call-template name="add-hr-strong"/><br/>
      </xsl:when> <!--* text/overview *-->

    </xsl:choose>
  </xsl:template> <!--* name=add-introduction *-->

  <!--* process the contents of the introduction tag *-->
  <xsl:template match="introduction">
    <xsl:param name="depth" select="1"/>
    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template> <!--* match=introduction *-->

  <!--*
      * process the contents of the overview tag:
      * use a pull-style approach since don't have a DTD to
      * enforce the correct order
      *
      * Really should be using stylesheets
      *
      *-->
  <xsl:template match="overview">
    <xsl:param name="depth" select="1"/>

    <!--* safety checks (oh we need a DTD) *-->
    <xsl:if test="boolean(synopsis)=false()">
      <xsl:message terminate="yes">

 ERROR: overview block is missing a synopsis block

      </xsl:message>
    </xsl:if>

    <xsl:apply-templates
      select="/thread/info/history/entry[position()=count(/thread/info/history/entry)]" mode="most-recent">
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>

    <!--*
        * br/ at end of div block this is needed for konqueror but apparently
        * not other browsers; must be a better way of doing it - CSS?
        *
        * adding a p tag around the sections is horrible...
        *-->
    <p><strong>Synopsis:</strong></p>
    <xsl:choose>
      <xsl:when test="count(descendant::p)=0">
	<p>
	  <xsl:apply-templates select="synopsis">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</p>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="synopsis">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="boolean(why)">
      <xsl:apply-templates select="why" mode="overview">
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </xsl:if>

    <xsl:if test="boolean(when)">
      <xsl:apply-templates select="when">
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </xsl:if>

    <xsl:if test="boolean(calinfo)">
      <xsl:apply-templates select="calinfo">
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </xsl:if>

    <!--* umm, not sure about this *-->
    <xsl:if test="boolean(seealso)">
      <p><strong>Related Links:</strong></p>
      <ul>
	<xsl:for-each select="seealso/item">
	  <li>
	    <xsl:apply-templates>
	      <xsl:with-param name="depth" select="$depth"/>
	    </xsl:apply-templates>
	  </li>
	</xsl:for-each>
      </ul>
    </xsl:if> <!--* if: seealso *-->

    <p><strong>
	Proceed to the <a href="index.html#start-thread">HTML</a> or
	hardcopy (PDF:
	<a title="PDF (A4 format) version of the page" href="{/thread/info/name}.a4.pdf">A4</a>
	<xsl:text> | </xsl:text>
	<a title="PDF (US Letter format) version of the page" href="{/thread/info/name}.letter.pdf">letter</a>)
	version of the thread.
      </strong></p>

  </xsl:template> <!--* match=overview *-->

  <!--* process the contents of the calinfo tag *-->
  <xsl:template match="calinfo">
    <xsl:param name="depth" select="1"/>

    <p><strong><a name="calnotes">Calibration Updates:</a></strong></p>
    
    <xsl:if test="boolean(caltext)">
      <xsl:choose>
	<xsl:when test="count(descendant::p)=0">
	  <p>
	    <xsl:apply-templates select="caltext">
	      <xsl:with-param name="depth" select="$depth"/>
	    </xsl:apply-templates>
	  </p>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates select="caltext">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <xsl:if test="boolean(calupdates)">
      <ul>
	<xsl:apply-templates select="calupdates/calupdate">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </ul>
    </xsl:if>
    
  </xsl:template> <!--* match=calinfo *-->
  
  <!--* process the contents of the calupdate tag *-->
  <xsl:template match="calupdate">
    <xsl:param name="depth" select="1"/>

    <li>
      <strong>
	<a><xsl:attribute name="href">/caldb/Release_notes/CALDB_v<xsl:value-of select="@version"/>.txt</xsl:attribute>CALDB v<xsl:value-of select="@version"/></a>
	<xsl:text> </xsl:text>
	<!--* add-date template is in myhtml.xsl, is it loaded? *-->
	<xsl:call-template name="add-date"/>:</strong>
      <xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </li>
  </xsl:template> <!--* match=calupdate *-->

  <!--*
      * add the summary text
      *
      * Parameters:
      *   depth - standard meaning
      *
      *   hardcopy, 0|1, optional
      *     - is this for the hardcopy version of the HTML page?
      *       (default is 0)
      *
      *-->
  <xsl:template name="add-summary">
    <xsl:param name="depth" select="1"/>
    <xsl:param name="hardcopy" select="0"/>

    <xsl:if test="boolean(text/summary)">
      <hr/><br/>
      <h2><a name="summary">Summary</a></h2>

      <xsl:apply-templates select="text/summary">
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>

      <br/>

    </xsl:if>

  </xsl:template> <!--* name-add-summary *-->

  <!--* process the contents of the summary tag *-->
  <xsl:template match="summary">
    <xsl:param name="depth" select="1"/>
    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template> <!--* match=summary *-->

  <xsl:template match="synopsis|when">
    <xsl:param name="depth" select="1"/>
    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template>

  <!--*
      * Process the overview/why node
      * - we need the mode="overview" part to 
      *   disambiguate with the why tag used to
      *   link to a 'why' document
      *-->
  <xsl:template match="why" mode="overview">
    <xsl:param name="depth" select="1"/>
    <p><strong>Purpose:</strong></p>
    <xsl:choose>
      <xsl:when test="count(descendant::p)=0">
	<p>
	  <xsl:apply-templates>
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</p>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates>
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* match=why mode=overview *-->

  <!--*
      * Process the overview/when node
      *-->
  <xsl:template match="when">
    <xsl:param name="depth" select="1"/>
    <p><strong>Read this thread if:</strong></p>
    <xsl:choose>
      <xsl:when test="count(descendant::p)=0">
	<p>
	  <xsl:apply-templates>
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</p>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates>
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* match=when *-->


  <!--*
      * do we create a table of contents? 
      * We do *IF* there is more than one section block
      * (perhaps should also check for any parameter files or images
      *  but that logic can be added if needed)
      *
      * Parameters:
      *   depth, number, optional
      *     - standard meaning
      *
      *   hardcopy, 0|1, optional
      *     - is this for the hardcopy version of the HTML page?
      *       (default is 0)
      *
      * Prior to CIAO 3.0 we included links to the introduction
      * but we don't anymore (the introduction now can also be overview)
      * We leave in the summary link
      *
      *-->

  <xsl:template name="add-toc">
    <xsl:param name="depth" select="1"/>
    <xsl:param name="hardcopy" select="0"/>

    <xsl:if test="count(text/sectionlist/section) > 1">
      <!--* Table of contents, list of parameter files, history *-->

      <!--* sort out the header: depends on hardcopy *-->
      <xsl:choose>
	<xsl:when test="$hardcopy = 0"><h2><a name="toc">Contents</a></h2></xsl:when>
	<xsl:when test="$hardcopy = 1"><h1><a name="toc">Table of Contents</a></h1></xsl:when>
      </xsl:choose>

      <ul>
	<!--* Sections & Subsections *-->
	<xsl:apply-templates select="text/sectionlist/section" mode="toc">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
	      
	<!--* do we have a summary? *-->
	<xsl:if test="boolean(text/summary)">
	  <li><a href="index.html#summary"><strong>Summary</strong></a></li>
	</xsl:if>
	      
	<!--* Parameter files (if any) *-->
	<xsl:if test="boolean(parameters)">
	  <xsl:apply-templates select="parameters" mode="toc">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</xsl:if>
	      
	<!--* History *-->
	<li><strong><a href="index.html#history">History</a></strong></li>
	
	<!--* Images (if any) *-->
	<xsl:if test="boolean(images)">
	  <xsl:apply-templates select="images" mode="toc">
	    <xsl:with-param name="depth" select="$depth"/>
	    <xsl:with-param name="hardcopy" select="$hardcopy"/>
	  </xsl:apply-templates>
	</xsl:if>
	
      </ul>

      <!--* do not want a hr if in hardcopy mode *-->
      <xsl:if test="$hardcopy = 0"><hr/></xsl:if>

    </xsl:if>
    
  </xsl:template> <!--* name-add-toc *-->

  <!--*
      * add the parameter info
      *-->
  <xsl:template name="add-parameters">
    <xsl:param name="depth" select="1"/>

    <xsl:choose>
      <xsl:when test="boolean(parameters)">
	<xsl:apply-templates select="parameters">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
	<!--* to separate out the text from the history *-->
	<xsl:call-template name="add-hr-strong"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* name-add-parameters *-->

  <!--*
      * this is called from the "Table of contents" part of the thread template 
      * We wrap each element in a link - checking to see if we have
      * to parse a subsectionlist
      *
      * Prior to CIAO 3.0 the threadlink attribute used to link directly to the
      * thread. We now include a section in the main text just to make things
      * clearer.
      *
      * many "id" nodes are created automatically - you can
      * add extra ones into a document using the id tag
      *-->
  <xsl:template match="section" mode="toc">
    <xsl:param name="depth" select="$depth"/>

    <li>
      <!--* could use CSS here - do we really need this TOC in hardcopy version? *-->
      <strong>
	<xsl:choose>
	  <xsl:when test="boolean(@threadlink)">
	    <a href="{concat('index.html#',@threadlink)}"><xsl:value-of select="title"/></a>
	  </xsl:when>
	  <xsl:otherwise>
	    <a href="{concat('index.html#',@id)}"><xsl:value-of select="title"/></a>
	  </xsl:otherwise>
	</xsl:choose>
      </strong>
      
      <!--* do we have to bother with any subsection's for this section? *-->
      <xsl:if test="boolean(subsectionlist)">
	<xsl:apply-templates select="subsectionlist" mode="toc">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </xsl:if> 
    </li>

  </xsl:template> <!--* match=section mode=toc *-->

  <!--*
      * Create the text from the sectionlist contents
      * Sections are given a H2 title - ie not included
      * in a list
      *
      * see the amazing hack to find out when we're in the last
      * section, and so do not draw a HR...
      * It works like this: we define a parameter whose name matches
      * the id of the last section. This is passed to the
      * section template, which only prints out a HR if the id's
      * don't match.
      *-->

  <xsl:template match="sectionlist">
    <xsl:param name="depth" select="$depth"/>

    <br/>

    <!--* anchor linked to from the overview section *-->
    <xsl:if test="boolean(/thread/text/overview)"><a name="start-thread"/></xsl:if>

    <xsl:apply-templates>
      <xsl:with-param name="last-section-id" select="section[position()=count(../section)]/@id"/>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
    <br/>

  </xsl:template> <!--* match=sectionlist *-->

  <!--*
      * if threadlink attribute exists then we create a little
      * section
      *
      * we only draw a horizontal bar after the last section
      * if there's a summary. This is getting hacky/complicated
      * and needs a redesign
      *-->
  <xsl:template match="section">
    <xsl:param name="depth" select="$depth"/>
    <xsl:param name="last-section-id" select='""'/>
    
    <xsl:choose>
      <xsl:when test="boolean(@threadlink)">
	<xsl:variable name="linkThread" select="document(concat($threadDir,'/',@threadlink,'/thread.xml'))"/>
	<xsl:variable name="linkTitle"><xsl:choose>
	    <xsl:when test="boolean($linkThread//thread/info/title/long)">
	      <xsl:value-of select="$linkThread//thread/info/title/long"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:value-of select="$linkThread//thread/info/title/short"/>
	    </xsl:otherwise>
	  </xsl:choose></xsl:variable>

	<!--* warning message *-->
	<xsl:if test="$linkTitle = ''">
	  <xsl:message>

 WARNING: The "<xsl:value-of select="title"/>" section will be
   missing the link text since the <xsl:value-of select="@threadlink"/> thread
   has not been published.

	  </xsl:message>
	</xsl:if>

	<h2><a name="{@threadlink}"><xsl:value-of select="title"/></a></h2>
	<p>
	  Please follow the
	  "<a href="{concat('../',@threadlink,'/')}"><xsl:value-of select="$linkTitle"/></a>"
	  thread.
	</p>

	<!--* ASSUME we are not the last section (slightly dangerous) *-->
	<br/><hr/>
	
      </xsl:when>
      <xsl:otherwise>

	<h2><a name="{@id}"><xsl:value-of select="title"/></a></h2>
	<xsl:apply-templates>
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>

	<!--* we only add a hr if we are NOT the last section *-->
	<xsl:if test="@id != $last-section-id">
	  <br/><hr/>
	</xsl:if>

      </xsl:otherwise>
    </xsl:choose>
      
    
  </xsl:template> <!--* match=section *-->

  <!--*
      * ensure that no title blocks ever cause any direct output
      * - could be a bit dangerous to do it globally
      *   perhaps should be more targeted?
      *-->
  <xsl:template match="title"/>

  <!--*
      * list a subsection in the "table of contents"
      *-->
  <xsl:template match="subsectionlist" mode="toc">
    <xsl:param name="depth" select="$depth"/>

    <xsl:choose>
      <xsl:when test='@type="A"'>
	<ol type="A">
	  <xsl:apply-templates select="subsection" mode="toc">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</ol>
      </xsl:when>
      <xsl:when test='@type="1"'>
	<ol type="1">
	  <xsl:apply-templates select="subsection" mode="toc">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</ol>
      </xsl:when>
      <xsl:otherwise>
	<ul>
	  <xsl:apply-templates select="subsection" mode="toc">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</ul>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* match=subsectionlist mode=toc *-->

  <xsl:template match="subsection" mode="toc">
    <li>
      <a href="index.html#{@id}"><xsl:value-of select="title"/></a>
    </li>
  </xsl:template> <!--* subsection mode=toc *-->

  <!--*
      * process a subsectionlist
      * - we draw HR's after each list item (except the last one)
      * 
      * Parameters:
      *   depth - standard meaning
      * 
      *-->
  <xsl:template match="subsectionlist">
    <xsl:param name="depth" select="$depth"/>

    <xsl:call-template name="start-list"/>

    <!--* use a pull-style approach *-->
    <xsl:for-each select="subsection">

      <!--* process each subsection *-->
      <li>
	<a name="{@id}"><strong><xsl:value-of select="title"/></strong></a>
	<br/>
	<xsl:apply-templates>
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      
	<!--* we only add a hr if we are NOT the last subsection *-->
	<xsl:if test="position() != last()">
<!--*	  <br/> *-->
	  <xsl:call-template name="add-mid-sep"/>
	</xsl:if>
      
<!--*	<br/> *--> <!--* can not have anything outside the li.../li tag pairs in a list *-->
      </li>
    </xsl:for-each>

    <xsl:call-template name="end-list"/>

  </xsl:template> <!--* match=subsectionlist *-->

  <!--*
      * handle the history block
      *-->
  <xsl:template match="history">
    <xsl:param name="depth" select="$depth"/>

    <!--* if no parameter block then we need a HR 

or do we, as this case is already caught in add-parameters?

    <xsl:if test="boolean(//thread/parameters) = false()">
      <xsl:call-template name="add-hr-strong"/>
    </xsl:if>
*-->

    <h2><a name="history">History</a></h2>
    <p>
      <xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </p>
    <br/>
  </xsl:template> <!--* match=history *-->
  
  <!--*
      * handle history/entry tags
      *
      * note: 
      *   we enforce the presence of the who attribute, even
      *   if we don't actually use it.
      *-->
  <xsl:template match="entry">
    <xsl:param name="depth" select="$depth"/>

    <xsl:if test="boolean(@who)=false()">
      <xsl:message terminate="yes">
	Please add who attribute to &lt;entry&gt; tag
	<xsl:number value="@day" format="01"/>/<xsl:value-of select="@month"/>/<xsl:number value="@year" format="01"/>
	<xsl:call-template name="newline"/>
      </xsl:message>
    </xsl:if>
    
    <br/>
    <xsl:number value="@day" format="01"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="substring(@month,1,3)"/>
    <xsl:text> </xsl:text>
    <xsl:choose>
      <xsl:when test="@year >= 2000"><xsl:number value="@year"/></xsl:when>
      <xsl:otherwise><xsl:number value="@year+2000"/></xsl:otherwise>
    </xsl:choose>
    <xsl:text> - </xsl:text>
    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>

  </xsl:template> <!--* match=entry *-->

  <!--* used to create overview section *-->
  <xsl:template match="entry" mode="most-recent">
    <xsl:param name="depth" select="$depth"/>

    <p>
      <strong>Last Update:</strong>
      <xsl:value-of select="concat(' ',@day,' ',substring(@month,1,3),' ')"/>
      <xsl:choose>
	<xsl:when test="@year >= 2000"><xsl:number value="@year"/></xsl:when>
	<xsl:otherwise><xsl:number value="2000+@year"/></xsl:otherwise>
      </xsl:choose><xsl:text> - </xsl:text>
      <xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </p>

  </xsl:template> <!--* match=entry mode=most-recent *-->

  <!--*
      * handle screen tags 
      *
      * they either have an attribute of file, 
      * which means load the text from @file.xml,
      * or use their content
      *-->

  <xsl:template match="screen">
    <xsl:param name="depth" select="$depth"/>

    <!--* a check since we've changed name to file *-->
    <xsl:if test="boolean(@name)">
      <xsl:message terminate="yes">
  Error:
    a screen tag has been found with a name attribute
    (with value '<xsl:value-of select="@name"/>')
  --  name must be changed to file
      </xsl:message>
    </xsl:if>

    <xsl:choose>
      
      <!--* supplied text *-->
      <xsl:when test='. != ""'>
	<br/>
<xsl:call-template name="add-highlight-start"/><pre class="screenoutput"><xsl:apply-templates>
	    <xsl:with-param name="depth" select="$depth"/>
</xsl:apply-templates></pre><xsl:call-template name="add-highlight-end"/>
	<br/>
      </xsl:when>

      <!--* supplied a filename *-->
      <xsl:when test='boolean(@file)'>
	<br/>
<xsl:call-template name="add-highlight-start"/><pre class="screenoutput"><xsl:apply-templates
	    select="document(concat($sourcedir,@file,'.xml'))" mode="include">
	    <xsl:with-param name="depth" select="$depth"/>
</xsl:apply-templates></pre><xsl:call-template name="add-highlight-end"/>
	<br/>
      </xsl:when>

    </xsl:choose>
  
  </xsl:template> <!--* screen *-->

  <!--*
      * include a thread fragment:
      * the value of the tag is the name of the file to load
      *  <include>foo</include>
      * looks for
      *  ../include/foo.xml
      *
      * perhaps there should be a way of looking for a file in
      * the current working directory?
      *
      * see also the dummy tag (in helper.xsl)
      *
      * -->

  <xsl:template match="include">
    <xsl:param name="depth" select="$depth"/>

    <xsl:apply-templates select="document(concat($includeDir,.,'.xml'))" mode="include">
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>

  </xsl:template> <!--* include *-->

  <!--*
      * handle the root node of the included file
      * used by:
      * - include
      * - screen
      * - paramfile
      *-->
  <xsl:template match="/" mode="include">
    <xsl:param name="depth" select="$depth"/>

    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template> <!--* match=/ mode=include *-->

  <!--* 
      * used in header/footer to provide links to thread pages:
      * include "Top", "All", and all sections from the index which
      * contain this thread
      *
      * Uses the $threadDir variable to find the location of the
      * thread index (published copy)
      *
      * Uses the $threadName variable - the name of the thread
      *
      * Parameters:
      *   depth, optional, default=1
      *
      * *****CIAO SPECIFIC*****
      *
      *-->
  <xsl:template name="add-thread-qlinks">
    <xsl:param name="depth" select="'1'"/>

    <!--* read in the thread index *-->
    <xsl:variable name="threadIndex" select="document(concat($threadDir,'index.xml'))"/>

    Return to Threads Page: 
    <xsl:call-template name="mylink">
      <xsl:with-param name="depth" select="$depth"/>
      <xsl:with-param name="dir">../</xsl:with-param>
      <xsl:with-param name="filename"></xsl:with-param>
      <xsl:with-param name="text">Top</xsl:with-param>
    </xsl:call-template> | 
    <xsl:call-template name="mylink">
      <xsl:with-param name="depth" select="$depth"/>
      <xsl:with-param name="dir">../</xsl:with-param>
      <xsl:with-param name="filename">all.html</xsl:with-param>
      <xsl:with-param name="text">All</xsl:with-param>
    </xsl:call-template>

    <!--*
        * we want to process all the id nodes of the sections 
        * which contain this thread 
        *-->
    <xsl:for-each select="$threadIndex//item[@name=$threadName]/ancestor::section/id">
      | 
      <xsl:call-template name="mylink">
	<xsl:with-param name="depth" select="$depth"/>
	<xsl:with-param name="dir">../</xsl:with-param>
	<xsl:with-param name="filename"><xsl:value-of select="name"/>.html</xsl:with-param>
	<xsl:with-param name="text" select="text"/>
      </xsl:call-template>
    </xsl:for-each>

  </xsl:template> <!--* name=add-thread-qlinks *-->

  <!--*** handle images ***-->

  <!--*
      * list the images in the table of contents
      *
      * Parameters:
      *   depth - standard meaning
      *
      *   hardcopy, 0|1, optional
      *     - is this for the hardcopy version of the HTML page?
      *       (default is 0)
      *
      *-->

  <xsl:template match="images" mode="toc">
    <xsl:param name="depth" select="1"/>
    <xsl:param name="hardcopy" select="0"/>

    <li>
      <strong>Images</strong>
      <ul>
	<xsl:apply-templates select="image" mode="toc">
	  <xsl:with-param name="depth" select="$depth"/>
	  <xsl:with-param name="hardcopy" select="$hardcopy"/>
	</xsl:apply-templates>
      </ul>
    </li>
  </xsl:template> <!--* match=images mode=toc *-->

  <!--*
      * Link to an image in the TOC
      *
      * Parameters:
      *   depth - standard meaning
      *
      *   hardcopy, 0|1, optional
      *     - is this for the hardcopy version of the HTML page?
      *       (default is 0)
      *
      *-->
  <xsl:template match="image" mode="toc">
    <xsl:param name="depth" select="1"/>
    <xsl:param name="hardcopy" select="0"/>

    <xsl:variable name="thispos" select="position()"/>
    <xsl:variable name="id" select="../image[position()=$thispos]/@id"/>

    <li>
      <a>
	<xsl:attribute name="href"><xsl:choose>
	    <xsl:when test="$hardcopy = 1">#img-<xsl:value-of select="$id"/></xsl:when>
	    <xsl:otherwise>img<xsl:value-of select="$thispos"/>.html</xsl:otherwise>
	  </xsl:choose></xsl:attribute>
	<xsl:value-of select='title'/>
      </a>
    </li>
  </xsl:template> <!--* match=image mode=toc *-->

  <!--*
      * add a separator between "sections"
      *-->
  <xsl:template name="add-mid-sep">
    <hr width="80%" align="center"/>
  </xsl:template>

  <!--*
      * return the number of the node (in the set of
      * input nodes) that has an id attribute matching
      * an input value. It is used to find the name of the
      * image HTML file corresponding to a particular image id
      * [so that we can link to it].
      *
      * I'm sure it can be done a better way (eg key()?), but
      * for know this works and the nodesets we are querying
      * aren't too large.
      *
      * Parameters:
      *   pos - number, required
      *     current position of iteration: start at *LAST* node
      *     ie count($nodes) since we loop downwards
      *   matchID - string, required
      *     the value to match against the id attribute
      *   nodes - nodeset, required
      *     the set of nodes to query
      *
      *-->
  <xsl:template name="find-pos">
    <xsl:param name="pos"    select="1"/>
    <xsl:param name="matchID" select="''"/>

    <!--* note: we start the loop at the last node and loop down *-->
    <xsl:if test="$pos=0">
      <xsl:message terminate="yes">
  Error: id=<xsl:value-of select="$matchID"/> does
    not refer to any known image node.

      </xsl:message>
    </xsl:if>

    <xsl:variable name="node" select="$nodes[position()=$pos]"/>
    <xsl:choose>
      <xsl:when test="$node[@id=$matchID]">
	<xsl:value-of select="$pos"/>
      </xsl:when>

      <xsl:otherwise>
	<xsl:call-template name="find-pos">
	  <xsl:with-param name="matchID" select="$matchID"/>
	  <xsl:with-param name="pos"     select="$pos - 1"/>
	  <xsl:with-param name="nodes"   select="$nodes"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* name=find-pos *-->

  <!--*** handle parameters ***-->

  <!--*
      * parameter blocks:
      * either have with a mode of "toc" (meaning we're making the table of contents)
      * or no mode (we want the actual parameter list)
      *
      * toc: probably should have some way of picking out text used in link?
      *-->

  <xsl:template match="parameters" mode="toc">
    <xsl:param name="depth" select="1"/>

    <li>
      <strong>Parameter files:</strong>
      <ul>
	<xsl:for-each select="paramfile">
	  <li>
	    <a>
	      <xsl:attribute name="href">index.html#<xsl:value-of select="@name"/>.par<xsl:if
		  test="boolean(@id)">_<xsl:value-of select="@id"/></xsl:if></xsl:attribute>
	      <xsl:value-of select="@name"/>
	    </a>
	  </li>
	</xsl:for-each>
      </ul>
    </li>
  </xsl:template> <!--* match=parameters mode=toc *-->

  <xsl:template match="parameters">
    <xsl:param name="depth" select="1"/>

    <xsl:call-template name="add-hr-strong"/>
    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
    
  </xsl:template> <!--* match=parameters *-->

  <!--*
      * Create the plist output
      *
      *-->
  <xsl:template match="paramfile">
    <xsl:param name="depth" select="1"/>

    <a>
      <xsl:attribute name="name"><xsl:value-of select="@name"/>.par<xsl:if
	  test="boolean(@id)">_<xsl:value-of select="@id"/></xsl:if></xsl:attribute>
      <xsl:text> </xsl:text>
    </a>

    <table border="0" width="100%"><tr><td><pre class="paramlist">

Parameters for /home/username/cxcds_param/<xsl:value-of select="@name"/>.par

<xsl:choose>
	      <xsl:when test="boolean(@file)"><xsl:apply-templates 
		  select="document(concat($sourcedir,@file,'.xml'))" mode="include">
		  <xsl:with-param name="depth" select="$depth"/>
		</xsl:apply-templates><br/></xsl:when>
	      <xsl:otherwise><xsl:apply-templates>
		  <xsl:with-param name="depth" select="$depth"/>
		</xsl:apply-templates></xsl:otherwise>
</xsl:choose>
</pre></td></tr></table>

    <xsl:call-template name="add-hr-strong"/>

  </xsl:template> <!--* match=paramfile *-->

  <!--*
      * handle plist tags:
      * attributes are:
      *   name - required
      *   id - optional 
      *
      * if no value is supplied, use "plist name" as the link text
      *
      * accepts same style parameters as ahelp
      *-->

  <xsl:template match="plist">
    <xsl:param name="depth" select="1"/>

    <!--* start attributes for link text *-->
    <xsl:call-template name="start-styles"/>

    <a>
      <xsl:attribute name="href">#<xsl:value-of select="@name"/>.par<xsl:if 
	  test="boolean(@id)">_<xsl:value-of select="@id"/></xsl:if></xsl:attribute>
      <xsl:choose>
	<xsl:when test=".=''">plist <xsl:value-of select="@name"/></xsl:when>
	<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </a>
    
    <!--* end attributes for link text *-->
    <xsl:call-template name="end-styles"/>

  </xsl:template> <!--* match=plist *-->

  <!--*
      * add links to the hardcopy versions of the page
      * thread-specific - other pages use add-standard-banner
      *
      * Parameters:
      *   name - string, required
      *     name of page (excluding .html).
      *     PDF files are assumed to be called $name.[size].pdf
      *
      *-->
  <xsl:template name="add-hardcopy-links">
    <xsl:param name="name" select="''"/>

    <!--* safety check *-->
    <xsl:if test="$name = ''">
      <xsl:message terminate="yes">
  Error: add-hardcopy-links called with an empty name parameter
      </xsl:message>
    </xsl:if>

    <td align="right"><font size="-1">
        Hardcopy (PDF): 
        <a title="PDF (A4 format) version of the page" href="{$name}.a4.pdf">A4</a>
	<xsl:text> | </xsl:text>
        <a title="PDF (US Letter format) version of the page" href="{$name}.letter.pdf">Letter</a>
      </font></td>
  </xsl:template> <!--* name=add-hardcopy-links *-->

  <!--*
      * create img<n>.html files
      *
      * image tag: create the HTML files
      *  attributes:
      *    src - string, required
      *          name of image in gif/jpeg format
      *    id  - string, required
      *          used to tie in with imglink, and 
      *          allow "back to thread" link
      *
      *    ps  - string, optional
      *          name of postscript (ps/eps) image
      *
      * The output HTML file is called img<n>.html,
      * where <n> is the position of this image tag
      * in the list of image tags.
      *
      * The output name is ***UNRELATED*** to the value of the
      * id parameter.
      *
      *-->

  <xsl:template match="image" mode="list">
    <xsl:param name="depth" select="1"/>

    <xsl:variable name="pos" select="position()"/>
    <xsl:variable name="filename" select='concat($install,"img",$pos,".html")'/>
    <xsl:variable name="imgname" select='concat("Image ",$pos)'/>

    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <!--* get the start of the document over with *-->
      <xsl:call-template name="add-start-html"/>

      <!--* make the HTML head node *-->
      <xsl:call-template name="add-htmlhead">
	<xsl:with-param name="title" select="$imgname"/>
      </xsl:call-template>
      
      <!--* add disclaimer about editing the HTML file *-->
      <xsl:call-template name="add-disclaimer"/>
      
      <!--* make the header *-->
      <xsl:call-template name="add-header">
	<xsl:with-param name="depth" select="$depth"/>
	<xsl:with-param name="name"  select="//thread/info/name"/>
      </xsl:call-template>

      <!--* link back to thread *-->
      <div class="topbar">
	<div class="qlinkbar">
	  <a href="index.html#{@id}">Return to thread</a>
	</div>
      </div>

      <div class="mainbar">
	  
	<!-- set up the title block of the page -->
	<h2><xsl:value-of select="$imgname"/>: <xsl:value-of select="title"/></h2>
	<hr/>
	<br/>

	<!--* "pre-image" text *-->
	<xsl:if test="boolean(before)">
	  <xsl:apply-templates select="before">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</xsl:if>
	  
	<!--* image *-->
	<img src="{@src}" alt="[{$imgname}]"/>
	<xsl:if test="boolean(@ps)">
	  <br/>
	  <p>
	    <a href="{@ps}">Postscript version of image</a>
	  </p>
	</xsl:if>

	<!--* "post-image" text *-->
	<xsl:if test="boolean(after)">
	  <xsl:apply-templates select="after">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</xsl:if>

      </div>

      <!--* link back to thread *-->
      <div class="bottombar">
	<a href="index.html#{@id}">Return to thread</a>
      </div>

      <!--* add the footer text *-->
      <xsl:call-template name="add-footer">
        <xsl:with-param name="depth" select="$depth"/>
	<xsl:with-param name="name"  select="//thread/info/name"/>
      </xsl:call-template>

      <!--* add </body> tag [the <body> is included in a SSI] *-->
      <xsl:call-template name="add-end-body"/>
      <xsl:call-template name="add-end-html"/>

    </xsl:document>

  </xsl:template> <!--* match=image mode=list *-->

  <!--* handle before/after tags in image blocks *-->
  <xsl:template match="before|after">
    <xsl:param name="depth" select="1"/>
    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template>

  <!--*
      * Used in a section block to indicate file types
      * - would be niver in the overview section (say)
      *   since it's meta-information about the thread but
      *   no time to work out how to work out where to
      *   place this info in the thread
      * - if we have a unique name then XPATH can find it
      *   anyway, no matter where it is (an ugly solution)
      *
      * obsidlist/obsid       = number
      * obsidlist/obsid/@desc = description
      *
      * filetypelist/filetype = name
      *-->
  <xsl:template match="obsidlist">
    <xsl:if test="boolean(ancestor::p)">
      <xsl:message terminate="yes">
  ERROR: You have an &lt;obsidlist> block within a &lt;p> block
      </xsl:message>
    </xsl:if>

    <xsl:variable name="count" select="count(obsid)"/>
    <p>
      <strong>Sample ObsID<xsl:if test="$count != 1">s</xsl:if> used:</strong><xsl:text> </xsl:text>
      <xsl:for-each select="obsid">
	<xsl:value-of select="."/>
	<xsl:if test="boolean(@desc)"><xsl:value-of select="concat(' (',@desc,')')"/></xsl:if>
	<xsl:if test="position() != $count"><xsl:text>; </xsl:text></xsl:if>
      </xsl:for-each>
    </p>
  </xsl:template> <!--* match=obsidlist *-->

  <xsl:template match="filetypelist">
    <xsl:if test="boolean(ancestor::p)">
      <xsl:message terminate="yes">
  ERROR: You have a &lt;filetypelist> block within a &lt;p> block
      </xsl:message>
    </xsl:if>

    <xsl:variable name="count" select="count(filetype)"/>
    <p>
      <strong>File types needed:</strong><xsl:text> </xsl:text>
      <xsl:for-each select="filetype">
	<xsl:value-of select="."/>
	<xsl:if test="position() != $count"><xsl:text>; </xsl:text></xsl:if>
      </xsl:for-each>
    </p>
  </xsl:template> <!--* match=filetypelist *-->

</xsl:stylesheet>
