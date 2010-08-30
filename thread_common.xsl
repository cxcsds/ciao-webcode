<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Useful templates for creating the CIAO threads
    *
    * Recent changes:
    * 2008 Sep 16 ECG
    *    don't include siteversion in header of CSC threads
    * 2008 May 14 DJB
    *    support new "figure" markup as an alternative to the images version
    * 2007 Dec 18 ECG
    *    parentheses are added to endstr at different point in 
    *	 "add-htmlhead-site-thread"
    * 2007 Oct 29 DJB
    *    updating to support proglang; fix for newer libxslt/xml (need to
    *    explicitly list params to stylesheet with xsl:param ?)
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *
    * User-defineable parameters:
    *  - defined in including stylesheets
    *
    * Notes:
    *
    *  - the number attribute on the text tag should probably be removed
    *    and become a type attribute on the sectionlist
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:func="http://exslt.org/functions"
  xmlns:djb="http://hea-www.harvard.edu/~dburke/xsl/"
  extension-element-prefixes="exsl func djb">

  <!--* we create the HTML files using xsl:document statements *-->
  <xsl:output method="text"/>

  <!--* This is used to map from @id to figure number *-->
  <xsl:variable name="figlist">
    <xsl:for-each select="//figure">
      <figure id="{@id}" pos="{position()}"/>
    </xsl:for-each>
  </xsl:variable>

  <!--*
      * set up the "top level" links for the HTML page
      * [links to processing/names threads, thread index,
      *  and hardcopy versions]
      *
      * Parameters:
      *
      * Updated for CIAO 3.0 to remove some 'excess' baggage
      *
      * As many of these templates do the same thing we could refactor here
      *-->
  <xsl:template name="add-top-links-site-html">
    <xsl:choose>
      <xsl:when test="$site = 'ciao'"><xsl:call-template name="add-top-links-ciao-html"/></xsl:when>
      <xsl:when test="$site = 'chart'"><xsl:call-template name="add-top-links-chart-html"/></xsl:when>
      <xsl:when test="$site = 'chips'"><xsl:call-template name="add-top-links-chips-html"/></xsl:when>
      <xsl:when test="$site = 'sherpa'"><xsl:call-template name="add-top-links-sherpa-html"/></xsl:when>
      <xsl:when test="$site = 'csc'"><xsl:call-template name="add-top-links-csc-html"/></xsl:when>
      <xsl:when test="$site = 'pog'"><xsl:call-template name="add-top-links-pog-html"/></xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
 Internal error - add-top-links-site-html sent site='<xsl:value-of select="$site"/>'
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* name=add-top-links-site-html *-->

  <xsl:template name="add-top-links-ciao-html">

    <!--* safety check *-->
    <xsl:if test="$site != 'ciao'">
      <xsl:message terminate="yes">
  Error: template add-top-links-ciao-html called but not for a CIAO thread
      </xsl:message>
    </xsl:if>

    <div class="topbar">
      <div class="qlinkbar">
	<!--* create links to threads *-->
	<xsl:call-template name="add-thread-qlinks"/>
      </div>
    </div>

  </xsl:template> <!--* name=add-top-links-ciao-html *-->

  <!--*
      * set up the "top level" links for the HTML page (ChaRT)
      * [links to processing/names threads, thread index,
      *  and hardcopy versions]
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-top-links-chart-html">

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
      *
      *-->
  <xsl:template name="add-top-links-sherpa-html">

    <!--* safety check *-->
    <xsl:if test="$site != 'sherpa'">
      <xsl:message terminate="yes">
  Error: template add-top-links-sherpa-html called but not for a Sherpa thread
      </xsl:message>
    </xsl:if>

    <div class="topbar">
      <div class="qlinkbar">
      <!--* create links to threads *-->
	<xsl:call-template name="add-thread-qlinks"/>
      </div>
    </div>

  </xsl:template> <!--* name=add-top-links-sherpa-html *-->

  <!--*
      * set up the "top level" links for the HTML page (ChIPS)
      * [links to processing/names threads, thread index,
      *  and hardcopy versions]
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-top-links-chips-html">

    <!--* safety check *-->
    <xsl:if test="$site != 'chips'">
      <xsl:message terminate="yes">
  Error: template add-top-links-chips-html called but not for a ChIPS thread
      </xsl:message>
    </xsl:if>

    <div class="topbar">
      <div class="qlinkbar">
      <!--* create links to threads *-->
	<xsl:call-template name="add-thread-qlinks"/>
      </div>
    </div>

  </xsl:template> <!--* name=add-top-links-chips-html *-->

  <!--*
      * set up the "top level" links for the HTML page (CSC)
      * [links to processing/names threads, thread index,
      *  and hardcopy versions]
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-top-links-csc-html">

    <!--* safety check *-->
    <xsl:if test="$site != 'csc'">
      <xsl:message terminate="yes">
  Error: template add-top-links-csc-html called but not for a CSC thread
      </xsl:message>
    </xsl:if>

    <div class="topbar">
      <div class="qlinkbar">
      <!--* create links to threads *-->
	<xsl:call-template name="add-thread-qlinks"/>
      </div>
    </div>

  </xsl:template> <!--* name=add-top-links-csc-html *-->

  <!--*
      * set up the "top level" links for the HTML page (POG)
      * [links to processing/names threads, thread index,
      *  and hardcopy versions]
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-top-links-pog-html">

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
      *
      *-->
  <xsl:template name="add-bottom-links-site-html">
    <xsl:choose>
      <xsl:when test="$site = 'ciao'"><xsl:call-template name="add-bottom-links-ciao-html"/></xsl:when>
      <xsl:when test="$site = 'chart'"><xsl:call-template name="add-bottom-links-chart-html"/></xsl:when>
      <xsl:when test="$site = 'chips'"><xsl:call-template name="add-bottom-links-chips-html"/></xsl:when>
      <xsl:when test="$site = 'sherpa'"><xsl:call-template name="add-bottom-links-sherpa-html"/></xsl:when>
      <xsl:when test="$site = 'csc'"><xsl:call-template name="add-bottom-links-csc-html"/></xsl:when>
      <xsl:when test="$site = 'pog'"><xsl:call-template name="add-bottom-links-pog-html"/></xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
 Internal error - add-bottom-links-site-html sent site='<xsl:value-of select="$site"/>'
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* name=add-bottom-links-site-html *-->

  <xsl:template name="add-bottom-links-ciao-html">

    <!--* safety check *-->
    <xsl:if test="$site != 'ciao'">
      <xsl:message terminate="yes">
  Error: template add-bottom-links-html called but not for a CIAO thread
      </xsl:message>
    </xsl:if>

    <!--* create the trailing links to threads *-->
    <div class="bottombar">
      <!--* create links to threads *-->
      <xsl:call-template name="add-thread-qlinks"/>
    </div>

  </xsl:template> <!--* name=add-bottom-links-html *-->

  <!--*
      * set up the "trailing" links for the HTML page (ChaRT)
      * [links to thread indexes and hardcopy versions]
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-bottom-links-chart-html">

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
      *
      *-->
  <xsl:template name="add-bottom-links-sherpa-html">

    <!--* safety check *-->
    <xsl:if test="$site != 'sherpa'">
      <xsl:message terminate="yes">
  Error: template add-bottom-links-sherpa-html called but not for a Sherpa thread
      </xsl:message>
    </xsl:if>

    <!--* create the trailing links to threads *-->
    <div class="bottombar">
      <!--* create links to threads *-->
      <xsl:call-template name="add-thread-qlinks"/>
    </div>

  </xsl:template> <!--* name=add-bottom-links-sherpa-html *-->

  <!--*
      * set up the "trailing" links for the HTML page (ChIPS)
      * [links to thread indexes and hardcopy versions]
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-bottom-links-chips-html">

    <!--* safety check *-->
    <xsl:if test="$site != 'chips'">
      <xsl:message terminate="yes">
  Error: template add-bottom-links-chips-html called but not for a ChIPS thread
      </xsl:message>
    </xsl:if>

    <!--* create the trailing links to threads *-->
    <div class="bottombar">
      <!--* create links to threads *-->
      <xsl:call-template name="add-thread-qlinks"/>
    </div>

  </xsl:template> <!--* name=add-bottom-links-chips-html *-->

  <!--*
      * set up the "trailing" links for the HTML page (CSC)
      * [links to thread indexes and hardcopy versions]
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-bottom-links-csc-html">

    <!--* safety check *-->
    <xsl:if test="$site != 'csc'">
      <xsl:message terminate="yes">
  Error: template add-bottom-links-csc-html called but not for a CSC thread
      </xsl:message>
    </xsl:if>

    <!--* create the trailing links to threads *-->
    <div class="bottombar">
      <!--* create links to threads *-->
      <xsl:call-template name="add-thread-qlinks"/>
    </div>

  </xsl:template> <!--* name=add-bottom-links-csc-html *-->

  <!--*
      * set up the "trailing" links for the HTML page (POG)
      * [links to thread indexes and hardcopy versions]
      *
      * Parameters:
      *
      * At the moment this is the same as the ChaRT version
      *
      *-->
  <xsl:template name="add-bottom-links-pog-html">

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
      *-->
  <xsl:template name="add-introduction">

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
	<xsl:apply-templates select="text/introduction"/>
	<br/><hr/><br/>
      </xsl:when> <!--* text/introduction *-->

      <!--*
          * try and make the overview stand out
          * We use a table to get the background colour and
          * width (since we can't use CSS for it due to the
          * use of htmldoc).
	  *
	  * DJB woders why he didn't use CSS for the HTML
	  * version and fall back to the table for the HTMLDOC/hardcopy
	  * version - e.g. the add-highlight-block template in myhtml.xsl
          *-->
      <xsl:when test="boolean(text/overview)">
	<br/>
	<div id="overview">

	  <h2><a name="overview">Overview</a></h2>
	  
<!--	  <p>
	    <strong>The threads are in the process of being reviewed
	    for CIAO 4.2. This message will be removed after the
	    thread has been updated.</strong>
	  </p>
-->
	  <xsl:apply-templates select="text/overview"/>
	</div>
	<br/><xsl:call-template name="add-hr-strong"/><br/>
      </xsl:when> <!--* text/overview *-->

    </xsl:choose>
  </xsl:template> <!--* name=add-introduction *-->

  <!--* process the contents of the introduction tag *-->
  <xsl:template match="introduction">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * process the contents of the overview tag:
      * use a pull-style approach since don't have a DTD to
      * enforce the correct order
      *
      * Really should be using stylesheets
      *
      *-->
  <xsl:template match="overview">

    <!--* safety checks (oh we need a DTD) *-->
    <xsl:if test="boolean(synopsis)=false()">
      <xsl:message terminate="yes">

 ERROR: overview block is missing a synopsis block

      </xsl:message>
    </xsl:if>

    <xsl:apply-templates
      select="/thread/info/history/entry[position()=count(/thread/info/history/entry)]" mode="most-recent"/>

    <!--*
        * br/ at end of div block this is needed for konqueror but apparently
        * not other browsers; must be a better way of doing it - CSS?
        *
        * adding a p tag around the sections is horrible...
        *-->
    <xsl:call-template name="process-overview-section">
      <xsl:with-param name="title"   select="'Synopsis:'"/>
      <xsl:with-param name="section"><xsl:apply-templates select="synopsis" mode="overview"/></xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="process-overview-section">
      <xsl:with-param name="title"   select="'Purpose:'"/>
      <xsl:with-param name="section"><xsl:apply-templates select="why" mode="overview"/></xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="process-overview-section">
      <xsl:with-param name="title"   select="'Read this thread if:'"/>
      <xsl:with-param name="section"><xsl:apply-templates select="when" mode="overview"/></xsl:with-param>
    </xsl:call-template>

    <xsl:if test="boolean(calinfo)">
      <xsl:apply-templates select="calinfo"/>
    </xsl:if>

    <!--* umm, not sure about this *-->
    <xsl:if test="boolean(seealso)">
      <p><strong>Related Links:</strong></p>
      <ul>
	<xsl:for-each select="seealso/item">
	  <li>
	    <xsl:apply-templates/>
	  </li>
	</xsl:for-each>
      </ul>
    </xsl:if> <!--* if: seealso *-->

    <div class="noprint">
      <p><strong>
	  Proceed to the <a href="{djb:get-index-page-name()}#start-thread">HTML</a> or
	  hardcopy (PDF:
	  <a title="PDF (A4 format) version of the page" href="{djb:get-pdf-head()}.a4.pdf">A4</a>
	  <xsl:text> | </xsl:text>
	  <a title="PDF (US Letter format) version of the page" href="{djb:get-pdf-head()}.letter.pdf">letter</a>)
	  version of the thread.
	</strong></p></div>

  </xsl:template> <!--* match=overview *-->

  <!--*
      * The template name is long to suggest this is rather a hack.
      * If the context node contains a p tag then we process as is
      * otherwise we surround by a div block. It used to be a p
      * block but this could cause validation problems
      *
      * We should instead clean up the document format and process
      * properly.
      *-->
  <xsl:template name="add-surrounding-block-if-necessary">
    <xsl:choose>
      <xsl:when test="count(descendant::p)=0">
	<div>
	  <xsl:apply-templates/>
	</div>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=add-surrounding-block-if-necessary *-->

  <!--*
      * process a section in the overview section
      * - split off into its own template so we can try and
      *   rationalise the behavior
      * 
      * To do:
      *   a better way to do the title
      *-->
  <xsl:template name="process-overview-section">
    <xsl:param name="title" select="''"/>
    <xsl:param name="section" select="''"/>

    <!--* is this check robust enough and correct? *-->
    <xsl:if test="$section != '' and count($section) != 0">
      <!--* should use a header for the 'title' *-->
      <p><strong><xsl:value-of select="$title"/></strong></p>
      <xsl:copy-of select="$section"/>
    </xsl:if>
  </xsl:template> <!--* name=process-overview-section *-->

  <!--*
      * process the contents of an overview section.
      * this is where we try and sort out the current
      * mess that is "do we add a "p" around the
      * contents
      *-->
  <xsl:template match="synopsis|why|when" mode="overview">
    <xsl:call-template name="add-surrounding-block-if-necessary"/>
  </xsl:template>

  <!--* process the contents of the calinfo tag *-->
  <xsl:template match="calinfo">

    <p><strong><a name="calnotes">Calibration Updates:</a></strong></p>

    <xsl:apply-templates select="caltext"/>
      
    <xsl:if test="boolean(calupdates)">
      <ul>
	<xsl:apply-templates select="calupdates/calupdate"/>
      </ul>
    </xsl:if>
    
  </xsl:template> <!--* match=calinfo *-->
  
  <!--* process the contents of the caltext tag *-->
  <xsl:template match="caltext">
    <xsl:call-template name="add-surrounding-block-if-necessary"/>
  </xsl:template>

  <!--* process the contents of the calupdate tag *-->

  <!--// pre-3.2.2 release notes are are .txt files, then 
	 Dale switched to HTML.  
      //-->

   <xsl:variable name="caldb-txt">
     <value>1.0</value>
     <value>1.1</value>
     <value>1.2</value>
     <value>1.3</value>
     <value>1.4</value>
     <value>1.5</value>
     <value>1.6</value>
     <value>1.7</value>
     <value>1.8</value>
     <value>2.0</value>
     <value>2.1</value>
     <value>2.2</value>
     <value>2.3</value>
     <value>2.4</value>
     <value>2.5</value>
     <value>2.6</value>
     <value>2.7</value>
     <value>2.8</value>
     <value>2.9</value>
     <value>2.10</value>
     <value>2.11</value>
     <value>2.12</value>
     <value>2.13</value>
     <value>2.14</value>
     <value>2.15</value>
     <value>2.16</value>
     <value>2.17</value>
     <value>2.18</value>
     <value>2.19</value>
     <value>2.20</value>
     <value>2.21</value>
     <value>2.22</value>
     <value>2.23</value>
     <value>2.24</value>
     <value>2.25</value>
     <value>2.26</value>
     <value>2.27</value>
     <value>2.28</value>
     <value>2.29</value>
     <value>3.0.0</value>
     <value>3.0.1</value>
     <value>3.0.2</value>
     <value>3.0.3</value>
     <value>3.0.4</value>
     <value>3.1.0</value>
     <value>3.2.0</value>
     <value>3.2.1</value>
   </xsl:variable>

  <xsl:template match="calupdate">

    <!--// need this variable because the count function doesn't
	   appear to "see" the attribute we want it to use
	//-->

    <xsl:param name="calver" select="@version"/>

    <li>
      <strong>

      <xsl:choose>
        <!--// txt files //-->
       <xsl:when test="count(exsl:node-set($caldb-txt)/value[.=$calver])=1">
	  <a href="/caldb/downloads/Release_notes/CALDB_v{@version}.txt">CALDB v<xsl:value-of select="@version"/></a>
        </xsl:when>

        <!--// html files //-->
	<xsl:otherwise>
	  <a href="/caldb/downloads/Release_notes/CALDB_v{@version}.html">CALDB v<xsl:value-of select="@version"/></a>
        </xsl:otherwise>
      </xsl:choose>

	<xsl:text> </xsl:text>
	<xsl:call-template name="add-date"/>:</strong>
      <xsl:apply-templates/>
    </li>
  </xsl:template> <!--* match=calupdate *-->

  <!--*
      * add the summary text
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-summary">

    <xsl:if test="boolean(text/summary)">
      <hr/><br/>
      <h2><a name="summary">Summary</a></h2>

      <xsl:apply-templates select="text/summary"/>
      <br/>
    </xsl:if>

  </xsl:template> <!--* name-add-summary *-->

  <!--* process the contents of the summary tag *-->
  <xsl:template match="summary">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * do we create a table of contents? 
      * We do *IF* there is more than one section block
      * (perhaps should also check for any parameter files or images
      *  but that logic can be added if needed)
      *
      * Parameters:
      *
      * Prior to CIAO 3.0 we included links to the introduction
      * but we don't anymore (the introduction now can also be overview)
      * We leave in the summary link
      *
      * If /thread/text/@number=1 then we add numbers to the
      * labels (if we can). We do *NOT* label intro/summary sections
      * [it complicates things a lot for one] I think this should be
      * changed to look at /thread/text/sectionlist/@type
      *
      *-->

  <xsl:template name="add-toc">

    <xsl:if test="count(text/sectionlist/section) > 1">
      <!--* Table of contents, list of parameter files, history *-->

      <!--* should this be sent in to the stylesheet ? *-->
      <xsl:variable name="pageName" select="djb:get-index-page-name()"/>

      <!--* sort out the header: depends on hardcopy *-->
      <xsl:choose>
	<xsl:when test="$hardcopy = 0"><h2><a name="toc">Contents</a></h2></xsl:when>
	<xsl:when test="$hardcopy = 1"><h1><a name="toc">Table of Contents</a></h1></xsl:when>
      </xsl:choose>

      <ul>
	<!--* Sections & Subsections *-->
	<xsl:apply-templates select="text/sectionlist/section" mode="toc">
	  <xsl:with-param name="pageName" select="$pageName"/>
	</xsl:apply-templates>
	      
	<!--* do we have a summary? *-->
	<xsl:if test="boolean(text/summary)">
	  <li><a href="{$pageName}#summary"><strong>Summary</strong></a></li>
	</xsl:if>
	      
	<!--* Parameter files (if any) *-->
	<xsl:if test="boolean(parameters)">
	  <xsl:apply-templates select="parameters" mode="toc">
	    <xsl:with-param name="pageName" select="$pageName"/>
	  </xsl:apply-templates>
	</xsl:if>
	      
	<!--* History *-->
	<li><strong><a href="{$pageName}#history">History</a></strong></li>

	<!--* safety check to make sure we do not mix up old and new figure styles (really needed?) *-->
	<xsl:if test="boolean(images) and boolean(//figure)">
	  <xsl:message terminate="yes">
 ERROR: thread contains an images block and at least one figure block!
	  </xsl:message>
	</xsl:if>
	
	<!--* Images (if any) *-->
	<xsl:if test="boolean(images)">
	  <xsl:apply-templates select="images" mode="toc"/>
	</xsl:if>
	<xsl:if test="boolean(//figure)">
	  <li>
	    <strong>Images</strong>
	    <ul>
	      <xsl:apply-templates select="//figure" mode="toc"/>
	    </ul>
	  </li>
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

    <xsl:choose>
      <xsl:when test="boolean(parameters)">
	<xsl:apply-templates select="parameters"/>
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
      *
      * We add numbers to the labels IF /thread/text/@number=1
      * THIS SHOULD PROBABLY BE DEPRECATED AND ADDED TO THE
      * sectionlist TAG AS A TYPE ATTRIBUTE (as done for
      * subsectionlist), unless there's some reason why
      * we can not do it?
      *-->
  <xsl:template name="find-section-label">
    <xsl:if test="/thread/text/@number=1"><xsl:value-of select="position()"/><xsl:text> - </xsl:text></xsl:if>
    <xsl:value-of select="title"/>
  </xsl:template> <!--* name=find-section-label *-->

  <!--* what use is @threadlink here over id? *-->
  <xsl:template match="section" mode="toc">
    <xsl:param name="pageName" select="'index.html'"/>

    <xsl:variable name="titlestring"><xsl:call-template name="find-section-label"/></xsl:variable>

    <li>
      <!--* could use CSS here - do we really need this TOC in hardcopy version? *-->
      <strong>
	<xsl:choose>
	  <xsl:when test="boolean(@threadlink)">
	    <a href="{concat($pageName,'#',@threadlink)}"><xsl:value-of select="$titlestring"/></a>
	  </xsl:when>
	  <xsl:otherwise>
	    <a href="{concat($pageName,'#',@id)}"><xsl:value-of select="$titlestring"/></a>
	  </xsl:otherwise>
	</xsl:choose>
      </strong>
      
      <!--* do we have to bother with any subsection's for this section? *-->
      <xsl:if test="boolean(subsectionlist)">
	<xsl:apply-templates select="subsectionlist" mode="toc">
	  <xsl:with-param name="pageName" select="$pageName"/>
	</xsl:apply-templates>
      </xsl:if> 
    </li>

  </xsl:template> <!--* match=section mode=toc *-->

  <!--*
      * Create the text from the sectionlist contents
      * Sections are given a H2 title - ie not included
      * in a list. As of CIAO 3.1 (v1.28 of thread_common.xsl)
      * we no longer use a UL to process sub-sections AND
      * we add a div around elements
      *
      * see the amazing hack to find out when we're in the last
      * section, and so do not draw a HR...
      * It works like this: we define a parameter whose name matches
      * the id of the last section. This is passed to the
      * section template, which only prints out a HR if the id's
      * don't match.
      *
      * We add numbers to the labels IF /thread/text/@number=1
      * the "thing" used to denote separation between the sections is controlled
      * by /thread/text/@separator: default = "bar", can be "none"
      *
      * See the note at the top of the file: the text/@number
      * attribute should be removed and handled by @type attribute
      * on the sectionlist
      *-->

  <xsl:template match="sectionlist">

    <!--* XXX to do: POG threads *-->
    <xsl:if test="boolean(@type)">
      <xsl:message>
 WARNING: sectionlist has type attribute set to <xsl:value-of select="@type"/>
    WE NEED TO UPDATE THE CODE TO HANDLE THIS
      </xsl:message>
    </xsl:if>

    <br/>

    <div class="sectionlist">
      <!--* anchor linked to from the overview section *-->
      <xsl:if test="boolean(/thread/text/overview)"><a name="start-thread"/></xsl:if>

      <xsl:variable name="last" select="section[position()=count(../section)]/@id"/>
      <xsl:call-template name="add-sections">
	<xsl:with-param name="last-section-id" select="$last"/>
      </xsl:call-template>
    </div>

    <br/>

  </xsl:template> <!--* match=sectionlist *-->

  <!--*
      * if threadlink attribute exists then we create a little
      * section
      *
      * we only draw a horizontal bar after the last section
      * if there's a summary. This is getting hacky/complicated
      * and needs a redesign. It's really complicated since
      * we only now draw HR's if
      *   /thread/text/@separator = "bar" (the default value),
      *   it can also be "none"
      *
      * We add numbers to the labels IF /thread/text/@number=1
      *
      *-->
  <xsl:template name="add-sections">
    <xsl:param name="last-section-id" select='""'/>

    <!--*
        * need to store as a variable since we have changed
        * context node by the time we come to use it
        *
        * DOES THIS WORK
        *
        *-->
<!--*
    <xsl:variable name="type" select="@type"/>
*-->

    <xsl:for-each select="section">
      <xsl:variable name="titlestring"><xsl:call-template name="find-section-label"/></xsl:variable>

      <div class="section">
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

 WARNING: The "<xsl:value-of select="$titlestring"/>" section will be
   missing the link text since the <xsl:value-of select="@threadlink"/> thread
   has not been published.

	    </xsl:message>
	  </xsl:if>

	  <h2><a name="{@threadlink}"><xsl:value-of select="$titlestring"/></a></h2>
	  <p>
	    Please follow the
	    "<a href="{concat('../',@threadlink,'/')}"><xsl:value-of select="$linkTitle"/></a>"
	    thread.
	  </p>

	</xsl:when>
	<xsl:otherwise>
	  
	  <h2><a name="{@id}"><xsl:value-of select="$titlestring"/></a></h2>
	  <xsl:apply-templates/>
	  
	</xsl:otherwise>
      </xsl:choose>

      <!--* do we "separate" the sections? (note: really should enforce atribute values with DTD not here) *-->
      <xsl:choose>
	<xsl:when test="not(/thread/text/@separator) or /thread/text/@separator = 'bar'">
	  <xsl:if test="@id != $last-section-id">
	    <br/><hr/>
	  </xsl:if>
	</xsl:when>
	<xsl:when test="/thread/text/@separator = 'none'"/>
	<xsl:otherwise>
	  <xsl:message terminate="yes">

 ERROR: separator attribute of /thread/text is set to
          <xsl:value-of select="/thread/text/@separator"/>
        when it must eiher not be set or be either bar or none

	  </xsl:message>
	</xsl:otherwise>
      </xsl:choose>
      </div> <!--* class=section *-->
    </xsl:for-each>
    
  </xsl:template> <!--* name=add-sections *-->

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
    <xsl:param name="pageName" select="'index.html'"/>

    <xsl:choose>
      <xsl:when test='@type="A"'>
	<ol type="A">
	  <xsl:apply-templates select="subsection" mode="toc">
	    <xsl:with-param name="pageName" select="$pageName"/>
	  </xsl:apply-templates>
	</ol>
      </xsl:when>
      <xsl:when test='@type="1"'>
	<ol type="1">
	  <xsl:apply-templates select="subsection" mode="toc">
	    <xsl:with-param name="pageName" select="$pageName"/>
	  </xsl:apply-templates>
	</ol>
      </xsl:when>
      <xsl:otherwise>
	<ul>
	  <xsl:apply-templates select="subsection" mode="toc">
	    <xsl:with-param name="pageName" select="$pageName"/>
	  </xsl:apply-templates>
	</ul>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* match=subsectionlist mode=toc *-->

  <xsl:template match="subsection" mode="toc">
    <xsl:param name="pageName" select="'index.html'"/>
    <li>
      <a href="{$pageName}#{@id}"><xsl:value-of select="title"/></a>
    </li>
  </xsl:template> <!--* subsection mode=toc *-->

  <!--*
      * "fake" the numbered/alphabetical lists
      *
      * use the $type parameter to work out what sort of list
      * and then calculate the position
      * [we use a parameter rather than access the context node as
      *  we can not guarantee what the context node is]
      *
      * Also handles a missing @type attribute (which does nothing)
      *
      *-->
  <xsl:template name="position-to-label">
    <xsl:param name="type" select="''"/>

    <xsl:variable name="alphabet">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>

    <xsl:choose>
      <xsl:when test="not($type) or $type = ''"/> <!--* do nothing *-->
      <xsl:when test="$type = '1'">
	<xsl:value-of select="concat(position(),'. ')"/>
      </xsl:when>
      <xsl:when test="$type = 'A'">
	<xsl:if test="position() > string-length($alphabet)">
	  <xsl:message terminate="yes">
 ERROR: too many items in the list for @type=A
	  </xsl:message>
	</xsl:if>
	<xsl:value-of select="concat(substring($alphabet,position(),1),'. ')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
 ERROR:
   unrecognised @type=<xsl:value-of select="$type"/>
   in node=<xsl:value-of select="name()"/>
   contents=
<xsl:value-of select="."/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=position-to-label *-->

  <!--*
      * process a subsectionlist
      * - we draw HR's after each list item (except the last one)
      * - as of CIAO 3.1 (v1.28 of thread_common.xsl) we do not use a
      *   UL/LI for the subsectionlist, and we surround things in div
      *   blocks
      * 
      * Parameters:
      * 
      *-->
  <xsl:template match="subsectionlist">

    <!--*
        * need to store as a variable since we have changed
        * context node by the time we come to use it
        *-->
    <xsl:variable name="type" select="@type"/>

    <div class="subsectionlist">

      <!--* use a pull-style approach *-->
      <xsl:for-each select="subsection">

	<!--* process each subsection *-->
	<div class="subsection">
	  <h3><a name="{@id}"><xsl:call-template name="position-to-label">
		<xsl:with-param name="type" select="$type"/>
	      </xsl:call-template><xsl:value-of select="title"/></a></h3>
	  <xsl:apply-templates/>
      
	  <!--* we only add a hr if we are NOT the last subsection (and hr's are allowed) *-->
	  <xsl:if test="(not(/thread/text/@separator) or /thread/text/@separator = 'bar')
	    and (position() != last())">
	    <!--*	<br/> *-->
	    <xsl:call-template name="add-mid-sep"/>
	  </xsl:if>
      
	</div> <!--* class=subsection *-->
      </xsl:for-each>

    </div> <!--* class=subsectionlist *-->

  </xsl:template> <!--* match=subsectionlist *-->

  <!--*
      * handle the history block
      *-->
  <xsl:template match="history">

    <!--* if no parameter block then we need a HR 

or do we, as this case is already caught in add-parameters?

    <xsl:if test="boolean(//thread/parameters) = false()">
      <xsl:call-template name="add-hr-strong"/>
    </xsl:if>
*-->

    <h2><a name="history">History</a></h2>

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<!--// ugly for htmldoc //-->    
	<table cellpadding="3" cellspacing="1">
	  <xsl:apply-templates/>
	</table>
      </xsl:when>

      <xsl:otherwise>
        <!--// CSS-alicious //-->
	  <table class="history">
	    <xsl:apply-templates/>
	  </table>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* match=history *-->
  
  <!--*
      * handle history/entry tags
      *
      * note: 
      *   we enforce the presence of the who attribute, even
      *   if we don't actually use it.
      *
      *  Liz's note:  I don't feel like so much of the code should
      *	 have to be repeated within the hardcopy or not "xsl:choose",
      *	 but I can't make it work any other way right now.
      *
      *-->

  <xsl:template match="entry">

    <xsl:if test="boolean(@who)=false()">
      <xsl:message terminate="yes">
	Please add who attribute to &lt;entry&gt; tag for <xsl:number value="@day" format="01"/>-<xsl:value-of select="@month"/>-<xsl:number value="@year" format="01"/>
	<xsl:call-template name="newline"/>
      </xsl:message>
    </xsl:if>

    <xsl:if test="not(number(@day))">
      <xsl:message terminate="yes">
	Value of @day must be numerical: @year="<xsl:value-of select="@day"/>"
	<xsl:call-template name="newline"/>
      </xsl:message>
    </xsl:if>

    <xsl:if test="not(number(@year))">
      <xsl:message terminate="yes">
	Value of @year must be numerical: @day="<xsl:value-of select="@year"/>"
	<xsl:call-template name="newline"/>
      </xsl:message>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<!--// ugly for htmldoc //-->    
	<tr valign="top">
	  <td align="right">

    <xsl:number value="@day" format="01"/>
    <xsl:text>&#160;</xsl:text>
    <xsl:value-of select="substring(@month,1,3)"/>
    <xsl:text>&#160;</xsl:text>
    <xsl:choose>
      <xsl:when test="@year >= 2000"><xsl:number value="@year"/></xsl:when>
      <xsl:otherwise><xsl:number value="@year+2000"/></xsl:otherwise>
    </xsl:choose>
      </td>

      <td>
    <xsl:apply-templates/>
      </td>
    </tr>
      </xsl:when>

      <xsl:otherwise>
        <!--// CSS-alicious //-->
	<tr>
	  <td class="historydate">

    <xsl:number value="@day" format="01"/>
    <xsl:text>&#160;</xsl:text>
    <xsl:value-of select="substring(@month,1,3)"/>
    <xsl:text>&#160;</xsl:text>
    <xsl:choose>
      <xsl:when test="@year >= 2000"><xsl:number value="@year"/></xsl:when>
      <xsl:otherwise><xsl:number value="@year+2000"/></xsl:otherwise>
    </xsl:choose>
      </td>

      <td>
    <xsl:apply-templates/>
      </td>
    </tr>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* match=entry *-->

  <!--* used to create overview section *-->
  <xsl:template match="entry" mode="most-recent">

    <p>
      <strong>Last Update:</strong>
      <xsl:value-of select="concat(' ',@day,' ',substring(@month,1,3),' ')"/>
      <xsl:choose>
	<xsl:when test="@year >= 2000"><xsl:number value="@year"/></xsl:when>
	<xsl:otherwise><xsl:number value="2000+@year"/></xsl:otherwise>
      </xsl:choose><xsl:text> - </xsl:text>
      <xsl:apply-templates/>
    </p>

  </xsl:template> <!--* match=entry mode=most-recent *-->

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

    <xsl:apply-templates select="document(concat($includeDir,.,'.xml'))" mode="include"/>

  </xsl:template>

  <!--*
      * handle the root node of the included file
      * used by:
      * - include
      * - screen
      * - paramfile
      *-->
  <xsl:template match="/" mode="include">
    <xsl:apply-templates/>
  </xsl:template>

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
      *
      * *****CIAO SPECIFIC*****
      *
      *-->
  <xsl:template name="add-thread-qlinks">

    <!--* read in the thread index *-->
    <xsl:variable name="threadIndex" select="document(concat($threadDir,'index.xml'))"/>

    Return to Threads Page: 
    <xsl:call-template name="mylink">
      <xsl:with-param name="dir">../</xsl:with-param>
      <xsl:with-param name="filename"></xsl:with-param>
      <xsl:with-param name="text">Top</xsl:with-param>
    </xsl:call-template> | 
    <xsl:call-template name="mylink">
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
      *
      *-->

  <xsl:template match="images" mode="toc">

    <li>
      <strong>Images</strong>
      <ul>
	<xsl:apply-templates select="image" mode="toc"/>
      </ul>
    </li>
  </xsl:template> <!--* match=images mode=toc *-->

  <!--*
      * Link to an image in the TOC
      *
      * Parameters:
      *
      *-->
  <xsl:template match="image" mode="toc">

    <xsl:variable name="thispos" select="position()"/>
    <xsl:variable name="id" select="../image[position()=$thispos]/@id"/>

    <xsl:variable name="langid"><xsl:choose>
      <xsl:when test="$proglang=''"/>
      <xsl:otherwise><xsl:value-of select="concat('.',$proglang)"/></xsl:otherwise>
    </xsl:choose></xsl:variable>

    <li>
      <a>
	<xsl:attribute name="href"><xsl:choose>
	    <xsl:when test="$hardcopy = 1">#img-<xsl:value-of select="$id"/></xsl:when>
	    <xsl:otherwise><xsl:value-of select="concat('img',$thispos,$langid,'.html')"/></xsl:otherwise>
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
    <xsl:param name="nodes"/>

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
    <xsl:param name="pageName" select="'index.html'"/>

    <li>
      <strong>Parameter files:</strong>
      <ul>
	<xsl:for-each select="paramfile">
	  <li>
	    <a>
	      <xsl:attribute name="href"><xsl:value-of select="concat($pageName,'#',@name,'.par')"/><xsl:if
		  test="boolean(@id)">_<xsl:value-of select="@id"/></xsl:if></xsl:attribute>
	      <xsl:value-of select="@name"/>
	    </a>
	  </li>
	</xsl:for-each>
      </ul>
    </li>
  </xsl:template> <!--* match=parameters mode=toc *-->

  <xsl:template match="parameters">

    <xsl:call-template name="add-hr-strong"/>
    <xsl:apply-templates/>
    
  </xsl:template> <!--* match=parameters *-->

  <!--*
      * Create the plist output
      *
      *-->
  <xsl:template match="paramfile">

    <a>
      <xsl:attribute name="name"><xsl:value-of select="@name"/>.par<xsl:if
	  test="boolean(@id)">_<xsl:value-of select="@id"/></xsl:if></xsl:attribute>
      <xsl:text> </xsl:text>
    </a>

    <div><pre class="paramlist">

Parameters for /home/username/cxcds_param/<xsl:value-of select="@name"/>.par

<xsl:choose>
	      <xsl:when test="boolean(@file)"><xsl:apply-templates 
		  select="document(concat($sourcedir,@file,'.xml'))" mode="include"/><br/></xsl:when>
	      <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
</xsl:choose>
</pre></div>

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

    <!--* process the contents, surrounded by styles *-->
    <xsl:call-template name="add-text-styles">
      <xsl:with-param name="contents">
	<a>
	  <xsl:attribute name="href">#<xsl:value-of select="@name"/>.par<xsl:if 
	      test="boolean(@id)">_<xsl:value-of select="@id"/></xsl:if></xsl:attribute>
	  <xsl:choose>
	    <xsl:when test=".=''">plist <xsl:value-of select="@name"/></xsl:when>
	    <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
	  </xsl:choose>
	</a>
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template> <!--* match=plist *-->

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

    <xsl:variable name="langid"><xsl:choose>
      <xsl:when test="$proglang=''"/>
      <xsl:otherwise><xsl:value-of select="concat('.',$proglang)"/></xsl:otherwise>
    </xsl:choose></xsl:variable>

    <xsl:variable name="pos" select="position()"/>
    <xsl:variable name="filename" select='concat($install,"img",$pos,$langid,".html")'/>
    <xsl:variable name="imgname" select='concat("Image ",$pos)'/>
    <xsl:variable name="imgtitle" select="title"/>

    <xsl:variable name="endstr"><xsl:if test="$proglang != ''"><xsl:value-of select="concat(' (',djb:get-proglang-string(),')')"/></xsl:if></xsl:variable>

    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <!--* get the start of the document over with *-->
      <xsl:call-template name="add-start-html"/>

      <!--* make the HTML head node *-->
      <xsl:call-template name="add-htmlhead">
	<xsl:with-param name="title"><xsl:value-of select="concat($imgname,$endstr)"/></xsl:with-param>
      </xsl:call-template>
      
      <!--* add disclaimer about editing the HTML file *-->
      <xsl:call-template name="add-disclaimer"/>
      
      <!--* make the header *-->
      <xsl:call-template name="add-header">
	<xsl:with-param name="name"  select="djb:get-pdf-head()"/>
      </xsl:call-template>

      <!--* link back to thread *-->
      <div class="topbar">
	<div class="qlinkbar">
	  <a href="{djb:get-index-page-name()}#{@id}">Return to thread</a>
	</div>
      </div>

      <div class="mainbar">
	  
	<!-- set up the title block of the page -->
	<h2><xsl:value-of select="concat($imgname,': ',title,$endstr)"/></h2>
	<hr/>
	<br/>

	<!--* "pre-image" text *-->
	<xsl:if test="boolean(before)">
	  <xsl:apply-templates select="before"/>
	</xsl:if>
	  
	<!--* image *-->
	<img src="{@src}" alt="[{$imgname}: {$imgtitle}]"/>
	<xsl:if test="boolean(@ps)">
	  <br/>
	  <p>
	    <a href="{@ps}">Postscript version of image</a>
	  </p>
	</xsl:if>

	<!--* "post-image" text *-->
	<xsl:if test="boolean(after)">
	  <xsl:apply-templates select="after"/>
	</xsl:if>

      </div>

      <!--* link back to thread *-->
      <div class="bottombar">
	<a href="{djb:get-index-page-name()}#{@id}">Return to thread</a>
      </div>

      <!--* add the footer text *-->
      <xsl:call-template name="add-footer">
	<xsl:with-param name="name"  select="//thread/info/name"/>
      </xsl:call-template>

      <!--* add </body> tag [the <body> is added by the add-htmlhead template] *-->
      <xsl:call-template name="add-end-body"/>
      <xsl:call-template name="add-end-html"/>

    </xsl:document>

  </xsl:template> <!--* match=image mode=list *-->

  <!--* handle before/after tags in image blocks *-->
  <xsl:template match="before|after">
    <xsl:apply-templates/>
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
        <a>
          <xsl:attribute name="href">
	    <xsl:choose>
	      <xsl:when test="$site='ciao'">../intro_data/</xsl:when>
	      <xsl:otherwise>/ciao/threads/intro_data</xsl:otherwise>
	    </xsl:choose>
	  </xsl:attribute>

	  <strong>File types needed:</strong><xsl:text> </xsl:text>
	</a>

      <xsl:for-each select="filetype">
	<xsl:value-of select="."/>
	<xsl:if test="position() != $count"><xsl:text>; </xsl:text></xsl:if>
      </xsl:for-each>
    </p>
  </xsl:template> <!--* match=filetypelist *-->

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
      * In fact, it's made even less elegant by the fact that
      * imglink can be used in included files, which don't have
      * the same structure as the thread, and so we have to
      * explicitly process the thread.xml document...
      *
      * We may decide that the 'separate page per image' approach
      * for the "non hardcopy" cases is OTT [I certainly am leaning this way].
      *
      * We now take the location/width/height of the icon to use
      * from the imglinkicon[width/height] parameters which are
      * set by the calling process [user-defined in the config file]
      *
      *-->

  <xsl:template match="imglink">

    <!--*
        * get the name of the file that this link links to
        * - must be a better way of doing this
        * - since can't guarantee we'll be called with the thread
        *   as the 'context document', due to include files, we
        *   have to get the image nodes from the thread using document()
        *-->
    <xsl:variable name="nodes" select="document(concat($sourcedir,'thread.xml'))//thread/images/image"/>

    <xsl:variable name="pos">
      <xsl:call-template name="find-pos">
	<xsl:with-param name="matchID" select="@id"/>
	<xsl:with-param name="pos"     select="count($nodes)"/>
	<xsl:with-param name="nodes"   select="$nodes"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="langid"><xsl:choose>
      <xsl:when test="$proglang=''"/>
      <xsl:otherwise><xsl:value-of select="concat('.',$proglang)"/></xsl:otherwise>
    </xsl:choose></xsl:variable>

    <xsl:variable name="href">
      <xsl:choose>
	<xsl:when test="$hardcopy = 1">#img-<xsl:value-of select="@id"/></xsl:when>
	<xsl:otherwise><xsl:value-of select="concat('img',$pos,$langid,'.html')"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!--* need an anchor so that we can link back to the text *-->
    <a name="{@id}" href="{$href}">

      <xsl:apply-templates/>

      <xsl:variable name="getID" select="@id"/>
      <xsl:variable name="alttext" select="document(concat($sourcedir,'thread.xml'))//thread/images/image[@id=$getID]/title"/>

      <xsl:call-template name="add-nbsp"/>
      <xsl:call-template name="add-image">
	<xsl:with-param name="src"    select="$imglinkicon"/>
	<xsl:with-param name="alt">Link to Image <xsl:value-of select="$pos"/>: <xsl:value-of select="$alttext"/></xsl:with-param>
	<xsl:with-param name="width"  select="$imglinkiconwidth"/>
	<xsl:with-param name="height" select="$imglinkiconheight"/>
	<xsl:with-param name="border" select="0"/>
      </xsl:call-template>
    </a>

  </xsl:template> <!--* match=imglink *-->

  <!--*
      * add a "new page" comment to be read by HTMLDOC
      * - only needed/used when $hardcopy=1
      *
      *-->
  <xsl:template name="add-new-page">
    <xsl:comment> NEW PAGE </xsl:comment><xsl:text>
</xsl:text>
  </xsl:template> <!--* name=add-new-page *-->

  <!--*
      * Intended for use after displaying the thread title
      *-->
  <xsl:template name="add-proglang-sub-header">
    <xsl:choose>
      <xsl:when test="$proglang = ''"/>
      <xsl:otherwise><h3>[<xsl:value-of select="djb:get-proglang-string()"/> Syntax]</h3></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--*
      * Display the thread title in its own block,
      * with ancillary information (at present what language this is for)
      *
      * We also include the CXC logo so that it is included in print
      * media output, and explicitly excluded from screen media versions.
      *-->
  <xsl:template name="add-thread-title">
    <div align="center">
      <h1><xsl:value-of select="$threadInfo/title/long"/></h1>

      <div class="printmedia">
	<img class="cxclogo" alt="[CXC Logo]">
	  <xsl:attribute name="src"><xsl:choose>
	    <xsl:when test="$site = 'pog'">../cxc-logo.gif</xsl:when>
	    <xsl:when test="$site = 'ciao'">../../imgs/cxc-logo.gif</xsl:when>
	    <xsl:otherwise>/ciao/imgs/cxc-logo.gif</xsl:otherwise>
	  </xsl:choose></xsl:attribute>
	</img>
      </div>

      <h3><xsl:choose>
	<xsl:when test="$site = 'ciao'">CIAO <xsl:value-of select="$siteversion"/> Science Threads</xsl:when>
	<xsl:when test="$site = 'chips'">ChIPS Threads (<xsl:value-of select="$headtitlepostfix"/>)</xsl:when>
	<xsl:when test="$site = 'sherpa'">Sherpa Threads (<xsl:value-of select="$headtitlepostfix"/>)</xsl:when>
	<xsl:when test="$site = 'csc'">CSC Threads</xsl:when>
	<xsl:when test="$site = 'pog'">POG Threads (<xsl:value-of select="$siteversion"/>)</xsl:when>
      </xsl:choose></h3>
	  
      <xsl:call-template name="add-proglang-sub-header"/>
    </div>
    <xsl:call-template name="add-hr-strong"/>
  </xsl:template>

  <!--*
      * Adds the thread title, along with the site name and optional
      * language support, to the HTML header. Should it use the
      * headtitlepostfix parameter (see add-htmlhead-standard in
      * helper.xsl)
      *-->
  <xsl:template name="add-htmlhead-site-thread">

    <xsl:variable name="start"><xsl:choose>
      <xsl:when test="boolean($threadInfo/title/short)"><xsl:value-of select="$threadInfo/title/short"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$threadInfo/title/long"/></xsl:otherwise>
    </xsl:choose></xsl:variable>

    <xsl:variable name="endstr"><xsl:if test="$proglang != ''">
      <xsl:value-of select="concat(' (',djb:get-proglang-string(),')')"/>
    </xsl:if></xsl:variable>

      <xsl:choose>
	<!--// don't put siteversion in head of CSC threads //-->
	<xsl:when test="$site = 'csc'">
	  <xsl:call-template name="add-htmlhead">
            <xsl:with-param name="title" select="concat($start,' - ',djb:get-sitename-string(),' ',$endstr)"/>
	  </xsl:call-template>
	</xsl:when>

	<xsl:otherwise>
	  <xsl:call-template name="add-htmlhead">
            <xsl:with-param name="title" select="concat($start,' - ',$headtitlepostfix,$endstr)"/>
	  </xsl:call-template>
	</xsl:otherwise>
      </xsl:choose>

  </xsl:template> <!--* name=add-htmlhead-site-thread *-->

  <!--*
      * Adds the thread title, along with the site name and optional
      * language support, to the start of the hardcopy documentation
      * (the main text, not the front page).
      *-->
  <xsl:template name="add-threadtitle-main-hard">

    <div align="center">
      <h1><xsl:value-of select="$threadInfo/title/long"/></h1>

      <h2><xsl:choose>
	<xsl:when test="$site = 'ciao'">CIAO <xsl:value-of select="$siteversion"/> Science Threads</xsl:when>
	<xsl:when test="$site = 'chips'">ChIPS Threads (<xsl:value-of select="$headtitlepostfix"/>)</xsl:when>
	<xsl:when test="$site = 'sherpa'">Sherpa Threads (<xsl:value-of select="$headtitlepostfix"/>)</xsl:when>
	<xsl:when test="$site = 'chart'">ChaRT Threads</xsl:when>
	<xsl:when test="$site = 'csc'">CSC Threads</xsl:when>
	<xsl:when test="$site = 'pog'">Proposal Threads for <xsl:value-of select="$siteversion"/></xsl:when>
      </xsl:choose></h2>

      <xsl:call-template name="add-proglang-sub-header"/>
    </div>

  </xsl:template> <!--* name=add-threadtitle-main-hard *-->


  <!--* contents of the thread frontpage, hardcopy mode *-->

  <xsl:template name="add-thread-title-frontpage-hardcopy">
    <div align="center">
      <h1><xsl:value-of select="$threadInfo/title/long"/></h1>

      <!--*
	  * just add the logo directly
	  * don't use any templates, since this is a bit of a fudge
	  * It doesn't seem to work for ChIPS threads and can not be bothered
	  * to work out why
	  *-->
      <img alt="[CXC Logo]">
	<xsl:attribute name="src"><xsl:choose>
	  <xsl:when test="$site = 'pog'">../cxc-logo.gif</xsl:when>
	  <xsl:when test="$site = 'ciao'">../../imgs/cxc-logo.gif</xsl:when>
	  <xsl:otherwise>/proj/web-cxc/htdocs/ciao/imgs/cxc-logo.gif</xsl:otherwise>
	</xsl:choose></xsl:attribute>
      </img>

      <h2><xsl:choose>
	<xsl:when test="$site = 'ciao'">CIAO <xsl:value-of select="$siteversion"/> Science Threads</xsl:when>
	<xsl:when test="$site = 'chips'">ChIPS Threads (<xsl:value-of select="$headtitlepostfix"/>)</xsl:when>
	<xsl:when test="$site = 'sherpa'">Sherpa Threads (<xsl:value-of select="$headtitlepostfix"/>)</xsl:when>
	<xsl:when test="$site = 'chart'">ChaRT Threads</xsl:when>
	<xsl:when test="$site = 'csc'">CSC Threads</xsl:when>
	<xsl:when test="$site = 'pog'">Proposal Threads for <xsl:value-of select="$siteversion"/></xsl:when>
      </xsl:choose></h2>
      <xsl:call-template name="add-proglang-sub-header"/>

    </div>
  </xsl:template>

  <!--*
      * returns a human-readable version of the site name
      *-->
  <func:function name="djb:get-sitename-string">
    <func:result><xsl:choose>
      <xsl:when test="$site = 'ciao'">CIAO</xsl:when>
      <xsl:when test="$site = 'chips'">ChIPS</xsl:when>
      <xsl:when test="$site = 'sherpa'">Sherpa</xsl:when>
      <xsl:when test="$site = 'chart'">ChaRT</xsl:when>
      <xsl:when test="$site = 'csc'">CSC</xsl:when>
      <xsl:when test="$site = 'pog'">POG</xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
 Internal error: djb:get-sitename-string() unable to deal with site=<xsl:value-of select="$site"/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose></func:result>
  </func:function>

  <!--*
      * Returns the name of the page - index.html, index.sl.html, or index.py.html
      * Only expected to be used when hardcopy=0
      *-->
  <func:function name="djb:get-index-page-name">
    <func:result>index<xsl:if test="$proglang != ''">.<xsl:value-of select="$proglang"/></xsl:if>.html</func:result>
  </func:function>

  <!--*
      * Returns the head of the PDF version of the page, ie up to
      * but excluding the paper size,
      * Only expected to be used when hardcopy=0
      *-->
  <func:function name="djb:get-pdf-head">
    <func:result><xsl:value-of select="/thread/info/name"/><xsl:if test="$proglang != ''">.<xsl:value-of select="$proglang"/></xsl:if></func:result>
  </func:function>

  <!--*
      * For those threads that want a common look and feel, use
      * these templates.
      *-->

  <!--*
      * create:
      *    $install/index.hard.html
      * or
      *    $install/index.hard.<proglang>.html
      *-->
  <xsl:template match="thread" mode="html-hardcopy-standard">

    <xsl:variable name="langid"><xsl:choose>
      <xsl:when test="$proglang=''"/>
      <xsl:otherwise><xsl:value-of select="concat('.',$proglang)"/></xsl:otherwise>
    </xsl:choose></xsl:variable>

    <xsl:variable name="filename"
		  select="concat($install,'index',$langid,'.hard.html')"/>

    <xsl:variable name="urlfrag">
      <xsl:value-of select="concat('threads/',$threadName,'/')"/>
      <xsl:if test="$proglang != ''">
	<xsl:value-of select="concat('index',$langid,'.html')"/>
      </xsl:if>
    </xsl:variable>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <!--* get the start of the document over with *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-site-thread"/>

	<!--* and now the main part of the text *-->
	<body>

	  <!--* set up the title page *-->
	  <xsl:call-template name="add-thread-title-frontpage-hardcopy"/>
	  <xsl:call-template name="add-new-page"/>

	  <!--* table of contents page *-->
	  <xsl:call-template name="add-toc">
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>

	  <xsl:call-template name="add-new-page"/>

	  <!--* start the thread *-->

	  <!--* Make the header. *-->
	  <xsl:call-template name="add-id-hardcopy">
	    <xsl:with-param name="urlfrag" select="$urlfrag"/>
	    <xsl:with-param name="lastmod" select="$lastmodified"/>
	  </xsl:call-template>
	  <xsl:call-template name="add-hr-strong"/>
	  <br/>

	  <!--* set up the title block of the page *-->
	  <xsl:call-template name="add-threadtitle-main-hard"/>

	  <!--* Introductory text *-->
	  <xsl:call-template name="add-introduction">
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>

	  <!--* Main thread *-->
	  <xsl:apply-templates select="text/sectionlist"/>
	
	  <!--* Summary text *-->
	  <xsl:call-template name="add-summary">
	    <xsl:with-param name="hardcopy" select="1"/>
	  </xsl:call-template>
	
	  <!--* Parameter files *-->
	  <xsl:call-template name="add-parameters"/>

	  <!-- History -->
	  <xsl:apply-templates select="info/history"/>

	  <!--* add the footer text *-->
	  <br/>
	  <xsl:call-template name="add-hr-strong"/>
	  <xsl:call-template name="add-id-hardcopy">
	    <xsl:with-param name="urlfrag" select="$urlfrag"/>
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
	      <xsl:apply-templates select="before"/>
	    </xsl:if>

	    <!--* image:
                *   would like to use the PS version if available
                *   BUT htmldoc doesn't support this
                *-->
	    <img alt="[{$imgname}]" src="{@src}"/>
		
	    <!--* "post-image" text *-->
	    <xsl:if test="boolean(after)">
	      <xsl:apply-templates select="after"/>
	    </xsl:if>

	  </xsl:for-each>
	  
	</body>
      </html>

    </xsl:document>

  </xsl:template> <!--* match=thread mode=html-hardcopy-standard *-->

  <!--*
      * create:
      *    $install/index.html
      * or
      *    $install/index.<proglang>.html
      *-->
  <xsl:template match="thread" mode="html-viewable-standard">
    
    <xsl:variable name="filename"
		  select="concat($install,djb:get-index-page-name())"/>

    <xsl:variable name="hardcopyName" select="djb:get-pdf-head()"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="us-ascii">

      <!--* get the start of the document over with *-->
      <xsl:call-template name="add-start-html"/>

      <!--* make the HTML head node *-->
      <xsl:call-template name="add-htmlhead-site-thread"/>
      
      <!--* add disclaimer about editing the HTML file *-->
      <xsl:call-template name="add-disclaimer"/>
      
      <!--* make the header *-->
      <xsl:call-template name="add-header">
	<xsl:with-param name="name"  select="$hardcopyName"/>
      </xsl:call-template>

      <!--* set up the standard links before the page starts *-->
      <xsl:call-template name="add-top-links-site-html"/>

      <div class="mainbar">

	<!--* set up the title block of the page *-->
	<xsl:call-template name="add-thread-title"/>

	<!--* Introductory text *-->
	<xsl:call-template name="add-introduction"/>
	
	<!--* table of contents *-->
	<xsl:call-template name="add-toc"/>

	<!--* Main thread *-->
	<xsl:apply-templates select="text/sectionlist"/>
	  
	<!--* Summary text *-->
	<xsl:call-template name="add-summary"/>
	
	<!--* Parameter files *-->
	<xsl:call-template name="add-parameters"/>

	<!-- History -->
	<xsl:apply-templates select="info/history"/>

	<!--* set up the trailing links to threads/harcdopy *-->
	<xsl:call-template name="add-hr-strong"/>

      </div> <!--* calss=mainbar *-->

      <!--* set up the trailing links to threads/harcdopy *-->
      <xsl:call-template name="add-bottom-links-site-html"/>

      <!--* add the footer text *-->
      <xsl:call-template name="add-footer">
	<xsl:with-param name="name"  select="$hardcopyName"/>
      </xsl:call-template>

      <!--* add </body> tag [the <body> is added by the add-htmlhead template] *-->
      <xsl:call-template name="add-end-body"/>
      <xsl:call-template name="add-end-html"/>

    </xsl:document>

  </xsl:template> <!--* match=thread mode=html-viewable-standard *-->

  <!--*
      * Figure support
      *
      *  
      *  <figure id="foo">
      *    <title>blah blah blah</title>
      *    <caption>
      *      <p>Yay a caption.</p>
      *      <p>With more text.</p>
      *    </caption>
      *  
      *    <description>Short alt text</description>
      *    <bitmap format="png">foo.grab.png</bitmap>
      *    <bitmap format="png" thumbnail="1">foo.grab.png</bitmap>
      *    <bitmap format="png" hardcopy="1">foo.png</bitmap>
      *    <vector format="pdf">foo.pdf</bitmap>
      *  </figure> 
      *
      *
      * In the XPath expressions below I am not 100% convinced I need
      *    a[boolean(@b)]
      * rather than
      *    a[@b]
      * but I think I have seen issues with this in libxslt (ie changes in
      * behavior) so trying to be more explicit.
      *
      * Notes:
      *    htmldoc does not support ps/pdf images, so they are only useful
      *    for the HTML version.
      *
      *-->
  <xsl:template match="figure">

    <!--* simple validation *-->
    <xsl:if test="boolean(@id)=false()">
      <xsl:message terminate="yes">
 ERROR: figure block does not contain an id attribute
      </xsl:message>
    </xsl:if>
    <xsl:if test="boolean(description)=false()">
      <xsl:message terminate="yes">
 ERROR: figure (id=<xsl:value-of select="@id"/>) does not contain a description tag
      </xsl:message>
    </xsl:if>
    <xsl:if test="boolean(title)=false()">
      <xsl:message terminate="yes">
 ERROR: figure (id=<xsl:value-of select="@id"/>) does not contain a title tag
      </xsl:message>
    </xsl:if>

    <xsl:variable name="bmap-simple" select="bitmap[(boolean(@thumbnail)=false() or @thumbnail='0')
					     and (boolean(@hardcopy)=false() or @hardcopy='0')]"/>
    <xsl:variable name="bmap-thumb"  select="bitmap[boolean(@thumbnail)=true() and @thumbnail='1']"/>
    <xsl:variable name="bmap-hard"   select="bitmap[boolean(@hardcopy)=true() and @hardcopy='1']"/>

    <xsl:variable name="num-bmap-simple" select="count($bmap-simple)"/>
    <xsl:variable name="num-bmap-thumb"  select="count($bmap-thumb)"/>
    <xsl:variable name="num-bmap-hard"   select="count($bmap-hard)"/>

    <!--* safety checks as do not have a scheme for this environment *-->
    <xsl:if test="$num-bmap-thumb > 1">
      <xsl:message terminate="yes">
 ERROR: expected 0 or 1 bitmap nodes with a thumbnail attribute set to 1,
   but found <xsl:value-of select="$num-bmap-thumb"/> for figure id=<xsl:value-of select="@id"/>
      </xsl:message>
    </xsl:if>
    <xsl:if test="$num-bmap-hard > 1">
      <xsl:message terminate="yes">
 ERROR: expected 0 or 1 bitmap nodes with a hardcopy attribute set to 1,
   but found <xsl:value-of select="$num-bmap-hard"/> for figure id=<xsl:value-of select="@id"/>
      </xsl:message>
    </xsl:if>
    <xsl:if test="$num-bmap-simple > 1">
      <xsl:message terminate="yes">
 ERROR: expected 0 or 1 bitmap nodes with either no thumbnail and hardcopy attributes
   or with them set to 0 but found <xsl:value-of select="$num-bmap-simple"/> for figure id=<xsl:value-of select="@id"/>
      </xsl:message>
    </xsl:if>
    <xsl:if test="$num-bmap-simple = 0 and $num-bmap-hard = 0">
      <xsl:message terminate="yes">
 ERROR: no "basic" bitmap node found for display for figure id=<xsl:value-of select="@id"/>
      </xsl:message>
    </xsl:if>

    <xsl:variable name="has-bmap-simple" select="$num-bmap-simple = 1"/>
    <xsl:variable name="has-bmap-thumb" select="$num-bmap-thumb = 1"/>
    <xsl:variable name="has-bmap-hard" select="$num-bmap-hard = 1"/>

    <!--* work out the figure number/title *-->
    <xsl:variable name="pos" select="djb:get-figure-number(@id)"/>
    <xsl:variable name="title" select="djb:make-figure-title($pos)"/>

    <!--*
        * How do we display the HTML figure caption?
	*-->
    <xsl:choose>
      <xsl:when test="$hardcopy = 0">
	<div class="figure">
	  <div class="caption screenmedia">
	    <h3><a name="{@id}"><xsl:value-of select="$title"/></a></h3>
	  </div>

	  <div>
	    <!--* do we need this class attribute, as it is only meaningful for screen media? *-->
	    <xsl:attribute name="class"><xsl:choose>
	      <xsl:when test="$has-bmap-thumb">thumbnail</xsl:when>
	      <xsl:otherwise>nothumbnail</xsl:otherwise>
	    </xsl:choose></xsl:attribute>

	    <xsl:variable name="img-code">
	      <img>

		<xsl:attribute name="alt"><xsl:choose>
		  <xsl:when test="$has-bmap-thumb">
		    <xsl:value-of select="concat('[Thumbnail image: ',normalize-space(description),']')"/>
		  </xsl:when>
		  <xsl:otherwise>
		    <xsl:value-of select="concat('[',normalize-space(description),']')"/>
		  </xsl:otherwise>
		</xsl:choose></xsl:attribute>

		<xsl:attribute name="src"><xsl:choose>
		  <xsl:when test="$has-bmap-thumb"><xsl:value-of select="$bmap-thumb"/></xsl:when>
		  <xsl:when test="$has-bmap-simple"><xsl:value-of select="$bmap-simple"/></xsl:when>
		  <xsl:when test="$has-bmap-hard"><xsl:value-of select="$bmap-hard"/></xsl:when>
		  <xsl:otherwise>
		    <xsl:message terminate="yes">
 ERROR: internal error choosing image; apparently no images to use (img-code)
		    </xsl:message>
		  </xsl:otherwise>
		</xsl:choose></xsl:attribute>
	      </img>
	    </xsl:variable>

	    <div class="screenmedia">
	      <xsl:choose>
		<xsl:when test="$has-bmap-thumb">
		  <a>
		    <xsl:attribute name="href"><xsl:choose>
		      <xsl:when test="$has-bmap-simple"><xsl:value-of select="$bmap-simple"/></xsl:when>
		      <xsl:when test="$has-bmap-hard"><xsl:value-of select="$bmap-hard"/></xsl:when>
		      <xsl:otherwise>
			<xsl:message terminate="yes">
 ERROR: internal error choosing image; apparently no images to use (screenmedia)
			</xsl:message>
		      </xsl:otherwise>
		    </xsl:choose></xsl:attribute>
		    <xsl:copy-of select="$img-code"/>
		  </a>
		</xsl:when>
		<xsl:otherwise>
		  <xsl:copy-of select="$img-code"/>
		</xsl:otherwise>
	      </xsl:choose>

	      <!--*
		  * Process the images to create a set of nodes that detail the
		  * available versions, then process that. Only useful in the
		  * screen media version.
		  *-->
	      <xsl:variable name="versions">
		<flinks>
		  <xsl:apply-templates select="bitmap" mode="list-figure-versions"/>
		  <xsl:apply-templates select="vector" mode="list-figure-versions"/>
		</flinks>
	      </xsl:variable>
	      <xsl:apply-templates select="exsl:node-set($versions)" mode="add-figure-versions"/>
	    </div>

	    <div class="printmedia">
	      <img alt="{concat('[Print media version: ',normalize-space(description),']')}">
		<xsl:attribute name="src"><xsl:choose>
		  <xsl:when test="$has-bmap-hard"><xsl:value-of select="$bmap-hard"/></xsl:when>
		  <xsl:otherwise><xsl:value-of select="$bmap-simple"/></xsl:otherwise>
		</xsl:choose></xsl:attribute>
	      </img>

<!--* unfortunately neither the img tag or the object tag works for ps/pdf output,
    * at least on Firefox 2.0.0.14 on OS-X Intel
    * (seeing some bizarre issues so not 100% convinced about this, but not implementing
    *  it for now as I doubt it works reliably)
    *
	      <xsl:if test="vector[@format='ps']">
		<img alt="POSTSCRIPT HACK" src="{normalize-space(vector[@format='ps'])}"/>
		<object data="{normalize-space(vector[@format='ps'])}" type="application/ps">
		  POSTSCRIPT HACK VIA OBJECT
		</object>
	      </xsl:if>
	      <xsl:if test="vector[@format='pdf']">
		<img alt="PDF HACK" src="{normalize-space(vector[@format='pdf'])}"/>
		<object data="{normalize-space(vector[@format='pdf'])}" type="application/pdf">
		  PDF HACK VIA OBJECT
		</object>
	      </xsl:if>
*-->

	    </div>

	  </div>

	  <!--// Figure title placement depends on mediatype //-->
	  <h3 class="caption printmedia"><a name="{@id}"><xsl:value-of select="$title"/></a></h3>

	  <xsl:if test="caption">
	  <div class="caption">
	    <xsl:apply-templates select="caption" mode="figure"/>
	  </div>
	  </xsl:if>
	</div> <!--* class=figure *-->

	<!--* I want to remove the float behavior, so I add in an ugly empty div *-->
	<xsl:if test="$has-bmap-thumb">
	  <div class="clearfloat"/>
	</xsl:if>

      </xsl:when>
      <xsl:otherwise>
	<br/>
        <center>
	  <div>
	    <img align="center" alt="{concat('[',normalize-space(description),']')}">
	      <xsl:attribute name="src"><xsl:choose>
		<xsl:when test="$has-bmap-hard"><xsl:value-of select="$bmap-hard"/></xsl:when>
		<xsl:otherwise><xsl:value-of select="$bmap-simple"/></xsl:otherwise>
	      </xsl:choose></xsl:attribute>
	    </img>
	    <!-- QUS: does htmldoc honor the @size attribute? It does not appear to -->
	    <font size="-1">
	      <table border="0" cellspacing="0" bgcolor="#eeeeee"><tr><td>
		<h3 align="center"><a name="{@id}"><xsl:value-of select="$title"/></a></h3>
		<xsl:apply-templates select="caption" mode="figure"/>
	      </td></tr></table>
	    </font>
	  </div>
	</center>
	<br/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* match=figure *-->

  <!--*
      * process the contents of a figure environment to return a list
      * of versions of the figure for use in the on-screen/HTML
      * display - ie the "[versions: full-size, postscript, pdf]"
      * link.
      *
      * We want the bitmap images if:
      *   - hardcopy = 1
      *   - no hardcopy or thumbnail attributes but only when
      *     there is also a bitmap[@thumbnail=1] version
      *
      * The checks should be enforced by a schema, but we do not
      * do this yet (if we are ever going to do it). They could/should
      * be done elsewhere, but we do them here as it is easy to do
      * so.
      *
      * TODO:
      *    we should really re-order items so that we can
      *    ensure the "full-size bitmap" link is first
      *-->
  <xsl:template match="bitmap[boolean(@hard)]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: bitmap node found with attribute name of hard rather than hardcopy
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>
  <xsl:template match="bitmap[boolean(@thumb)]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: bitmap node found with attribute name of thumb rather than thumbnail
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>
  <xsl:template match="vector[boolean(@hard) or boolean(@hardcopy)]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: vector node found with hardcopy (or hard) attribute. Not needed here!
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>
  <xsl:template match="vector[boolean(@thumbnail) or boolean(@thumb)]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: vector node found with thumbnail (or thumb) attribute. Not needed here!
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>

  <xsl:template match="bitmap[@thumbnail=1 and @hardcopy=1]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: bitmap nodes must not have both thumbail and hardcopy attributes set to 1
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>
  <xsl:template match="bitmap[boolean(@format)=false()]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: bitmap nodes must contain a format attribute
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>
  <xsl:template match="vector[boolean(@format)=false()]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: vector nodes must contain a format attribute
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>

  <xsl:template match="bitmap[@thumbnail=1]" mode="list-figure-versions"/>
  <xsl:template match="bitmap[@hardcopy=1]" mode="list-figure-versions">
    <flink>
      <text><xsl:value-of select="translate(@format,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/></text>
      <image><xsl:value-of select="normalize-space(.)"/></image>
    </flink>
  </xsl:template>
  <xsl:template match="bitmap[(@thumbnail=0 or (boolean(@thumbnail)=false() and boolean(@hardcopy)=false())) and
		       (count(preceding-sibling::bitmap[@thumbnail=1]) != 0 or
		       count(following-sibling::bitmap[@thumbnail=1]) != 0)]" mode="list-figure-versions">
    <flink><text>full-size</text><image><xsl:value-of select="normalize-space(.)"/></image></flink>
  </xsl:template>
  <xsl:template match="vector[@format='ps']" mode="list-figure-versions">
    <flink><text>postscript</text><image><xsl:value-of select="normalize-space(.)"/></image></flink>
  </xsl:template>
  <xsl:template match="vector[@format='eps']" mode="list-figure-versions">
    <flink><text>encapsulated postscript</text><image><xsl:value-of select="normalize-space(.)"/></image></flink>
  </xsl:template>
  <xsl:template match="vector[@format='pdf']" mode="list-figure-versions">
    <flink><text>PDF</text><image><xsl:value-of select="normalize-space(.)"/></image></flink>
  </xsl:template>
  <xsl:template match="*|text()" mode="list-figure-versions">
<!--
    <xsl:message terminate="yes">
 ERROR: match=*|text() mode=list-figure-versions template has been called!
        node=<xsl:value-of select="name()"/> contents=<xsl:value-of select="."/>
    </xsl:message>
-->
  </xsl:template>

  <xsl:template match="flinks[count(flink)=0]" mode="add-figure-versions"/>
  <xsl:template match="flinks" mode="add-figure-versions">
    <p class="figures"><xsl:text>[Version: </xsl:text>
    <xsl:for-each select="flink">
      <a href="{image}"><xsl:value-of select="text"/></a>
      <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
    </xsl:for-each>
    <xsl:text>]</xsl:text></p>
  </xsl:template>

  <!--*
      * Create the caption for a figure; may not need the mode, but leave in for now
      *-->
  <xsl:template match="caption" mode="figure">
    <xsl:apply-templates/>
  </xsl:template> <!--* match=caption mode=figure *-->

  <!--*
      * Handle figlink tags.
      *   - no contents -> use "Figure <num>" (even if have @nonumber tag)
      *   - contents and no @nonumber attribute -> append " (Figure <num>)"
      *   - otherwise -> contents
      *
      * NOTE:
      *    check on empty contents as normalize-space(.)='' is not ideal
      *    but should work (would probably only fail if we used an empty tag like
      *     <figlink><foo/></figlink> which is unlikely to happen)
      *-->
  <xsl:template match="figlink[boolean(@id)=false]">
    <xsl:message terminate="yes">
 ERROR: figlink tag found with no id attribute
    contents=<xsl:value-of select="."/>
    </xsl:message>
  </xsl:template>

  <xsl:template match="figlink[boolean(@nonumber) and normalize-space(.)!='']">
    <xsl:call-template name="check-fig-id-exists">
      <xsl:with-param name="id" select="@id"/>
    </xsl:call-template>
    <a href="{concat('#',@id)}"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="figlink[normalize-space(.)='']">
    <xsl:call-template name="check-fig-id-exists">
      <xsl:with-param name="id" select="@id"/>
    </xsl:call-template>
    <xsl:variable name="pos" select="djb:get-figure-number(@id)"/>
    <a href="{concat('#',@id)}"><xsl:value-of select="concat('Figure ',$pos)"/></a>
  </xsl:template>

  <xsl:template match="figlink">
    <xsl:call-template name="check-fig-id-exists">
      <xsl:with-param name="id" select="@id"/>
    </xsl:call-template>
    <xsl:variable name="pos" select="djb:get-figure-number(@id)"/>
    <a href="{concat('#',@id)}"><xsl:apply-templates/><xsl:value-of select="concat(' (Figure ',$pos,')')"/></a>
  </xsl:template>

  <!--*
      * This is called when processing both figlink and figure tags,
      * which results in excess checks, but we will live with the
      * extra work.
      *-->
  <xsl:template name="check-fig-id-exists">
    <xsl:param name="id" select="''"/>
    <xsl:if test="$id = ''">
      <xsl:message terminate="yes">
 ERROR: check-fig-id-exists called with an empty id argument.
      </xsl:message>
    </xsl:if>

    <xsl:variable name="nmatches" select="count(//figure[@id=$id])"/>
    <xsl:choose>
      <xsl:when test="$nmatches=1"/>
      <xsl:when test="$nmatches=0">
	<xsl:message terminate="yes">
 ERROR: there is no figure with an id of '<xsl:value-of select="$id"/>'.
	</xsl:message>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
 ERROR: there are multiple (<xsl:value-of select="$nmatches"/>) figures with an id of '<xsl:value-of select="$id"/>'.
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=check-fig-id-exists *-->

  <!--*
      * Link to a figure in the TOC
      *
      * Parameters:
      *
      *-->
  <xsl:template match="figure" mode="toc">

    <xsl:call-template name="check-fig-id-exists">
      <xsl:with-param name="id" select="@id"/>
    </xsl:call-template>

    <xsl:variable name="pos" select="djb:get-figure-number(@id)"/>
    <li><a href="{concat('#',@id)}"><xsl:value-of select="djb:make-figure-title($pos)"/></a></li>
  </xsl:template> <!--* match=figure mode=toc *-->

  <!--*
      * helper routine to get the number of the figure
      *-->
  <func:function name="djb:get-figure-number">
    <xsl:param name="id" select="''"/>
    <xsl:if test="$id=''">
      <xsl:message terminate="yes">
 ERROR: djb:get-figure-number called with no argument
      </xsl:message>
    </xsl:if>
    <func:result><xsl:value-of select="exsl:node-set($figlist)/figure[@id=$id]/@pos"/></func:result>
  </func:function>

  <!--*
      * helper routine to create the figure title. It must be
      * called with the figure block as the context node.
      *-->
  <func:function name="djb:make-figure-title">
    <xsl:param name="pos" select="''"/>
    <xsl:if test="$pos=''">
      <xsl:message terminate="yes">
 ERROR: djb:make-figure-title called with no argument
      </xsl:message>
    </xsl:if>
    <xsl:if test="name()!='figure'">
      <xsl:message terminate="yes">
 ERROR: djb:make-figure-title must be called with a figure node as the context node
      </xsl:message>
    </xsl:if>
    <func:result><xsl:value-of select="concat('Figure ',$pos)"/><xsl:if test="boolean(title)">
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="title" mode="title-parsing"/>
    </xsl:if></func:result>
  </func:function>

  <!--*
`     * This is ugly; do we handle this better in other parts of the system?
      * (we need a different mode since there must be an explicit title template
      * somewhere that ignores the content, presumably to handle section/subsection
      * title elements).
      *
      * I added this so that we could include some mark up in the title element of
      * figures, but so far it does not seem to actually do this.
      *-->
  <xsl:template match="title" mode="title-parsing">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
