<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Useful templates for creating the CIAO threads
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
  xmlns:func="http://exslt.org/functions"
  xmlns:djb="http://hea-www.harvard.edu/~dburke/xsl/"
  extension-element-prefixes="func djb">

  <!--* we create the HTML files using xsl:document statements *-->
  <xsl:output method="text"/>

  <!--*
      * set up the "top level" links for the HTML page
      * [links to processing/names threads, thread index]
      *
      * Parameters:
      *
      * Updated for CIAO 3.0 to remove some 'excess' baggage
      *
      *-->
  <xsl:template name="add-top-links-site-html">
    <xsl:choose>
      <xsl:when test="$site = 'chart'">
	<xsl:call-template name="add-thread-qlinks-basic"/>
      </xsl:when>

      <xsl:when test="$site = 'pog'">
	<xsl:call-template name="add-thread-qlinks-basic">
	  <xsl:with-param name="text" select="'Proposer Threads Page'"/>
	</xsl:call-template>
      </xsl:when>

      <xsl:when test="$site = 'ciao' or $site = 'sherpa' or $site = 'chips' or $site = 'csc' or $site = 'iris'">
	<xsl:call-template name="add-thread-qlinks"/>
      </xsl:when>

      <xsl:otherwise>
	<xsl:message terminate="yes">
 Internal error - add-top-links-site-html sent site='<xsl:value-of select="$site"/>'
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* name=add-top-links-site-html *-->

  <!--*
      * set up the "trailing" links for the HTML page
      * [links to thread indexes]
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-bottom-links-site-html">
    <xsl:choose>
      <xsl:when test="$site = 'chart'">
	<xsl:call-template name="add-thread-qlinks-basic"/>
      </xsl:when>

      <xsl:when test="$site = 'pog'">
	<xsl:call-template name="add-thread-qlinks-basic">
	  <xsl:with-param name="text" select="'Proposer Threads Page'"/>
	</xsl:call-template>
      </xsl:when>

      <xsl:when test="$site = 'ciao' or $site = 'sherpa' or $site = 'chips' or $site = 'csc' or $site = 'iris'">
	<xsl:call-template name="add-thread-qlinks"/>
      </xsl:when>

      <xsl:otherwise>
	<xsl:message terminate="yes">
 Internal error - add-bottom-links-site-html sent site='<xsl:value-of select="$site"/>'
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* name=add-bottom-links-site-html *-->

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
	<h2><a name="introduction">Introduction</a></h2>
	<xsl:apply-templates select="text/introduction"/>
	<hr/>
      </xsl:when> <!--* text/introduction *-->

      <xsl:when test="boolean(text/overview)">
	<div id="overview">

	  <h2><a name="overview">Overview</a></h2>
	  
<!--
	  <p>
	    <strong>&#187; The threads are in the process of being reviewed
	    for CIAO 4.3. This message will be removed after the
	    thread has been updated.</strong>
	  </p>
-->
	  <xsl:apply-templates select="text/overview"/>
	</div>
	<xsl:call-template name="add-hr-strong"/>
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
      <xsl:with-param name="title"   select="'Run this thread if:'"/>
      <xsl:with-param name="section"><xsl:apply-templates select="when" mode="overview"/></xsl:with-param>
    </xsl:call-template>

    <xsl:if test="boolean(software)">
      <xsl:apply-templates select="software"/>
    </xsl:if>

    <xsl:if test="boolean(calinfo)">
	  <xsl:message terminate="yes">
 ERROR: the 'calinfo' tag has been replaced by the 'software' tag.
        The XML file must be updated to publish this thread.
	  </xsl:message>
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

    <xsl:apply-templates
      select="/thread/info/history/entry[position()=count(/thread/info/history/entry)]" mode="most-recent"/>

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
      <h4><xsl:value-of select="$title"/></h4>
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


  <!--* process the contents of the software tag *-->
  <xsl:template match="software">

    <h4 id="software">Software &amp; Calibration Updates:</h4>
    <p>This thread requires the following updates to the <a href="../../faq/stciao.html">standard CIAO <xsl:value-of select="$siteversion"/> installation</a></p>
      <ul>
	<xsl:for-each select="item">
	  <li>
	    <xsl:apply-templates/>
	  </li>
	</xsl:for-each>
      </ul>
  </xsl:template> <!--* match=software *-->


  <!--*
      * add the summary text
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-summary">

    <xsl:if test="boolean(text/summary)">
      <hr/>
      <h2><a name="summary">Summary</a></h2>

      <xsl:apply-templates select="text/summary"/>
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

      <h2><a name="toc">Contents</a></h2>

      <ul>
	<!--* Sections & Subsections *-->
	<xsl:apply-templates select="text/sectionlist/section" mode="toc">
	  <xsl:with-param name="pageName" select="'index.html'"/>
	</xsl:apply-templates>
	      
	<!--* do we have a summary? *-->
	<xsl:if test="boolean(text/summary)">
	  <li><a href="index.html#summary"><strong>Summary</strong></a></li>
	</xsl:if>
	      
	<!--* Parameter files (if any) *-->
	<xsl:if test="boolean(parameters)">
	  <xsl:apply-templates select="parameters" mode="toc">
	    <xsl:with-param name="pageName" select="'index.html'"/>
	  </xsl:apply-templates>
	</xsl:if>

    <xsl:if test="$site != 'pog'">	      
	<!--* History *-->
	<li><strong><a href="index.html#history">History</a></strong></li>
 	</xsl:if>

	<!--* Images (if any) *-->
	<xsl:if test="boolean(images)">
	  <xsl:message terminate="yes">

 ERROR: the thread contains an images block, which is no longer valid.  
        Please update to use a figure block instead. See Doug for help.

	  </xsl:message>	 
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

      <hr/>

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
	<xsl:if test="$site != 'pog'">
	  <!--* to separate out the text from the history *-->
	  <xsl:call-template name="add-hr-strong"/>
	</xsl:if>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* name-add-parameters *-->

  <!--* what use is @threadlink here over id? *-->
  <xsl:template match="section" mode="toc">
    <xsl:param name="pageName" select="'index.html'"/>

    <xsl:variable name="titlestring"><xsl:call-template name="find-section-label"/></xsl:variable>

    <li>
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

    <table class="history">
      <xsl:apply-templates/>
    </table>
  </xsl:template> <!--* match=history *-->
  
  <!--*
      * handle history/entry tags
      *
      * note: 
      *   we enforce the presence of the who attribute, even
      *   if we don't actually use it.
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
  </xsl:template> <!--* match=entry *-->

  <!--* used to create overview section *-->
  <xsl:template match="entry" mode="most-recent">

    <p><strong>Last Update:</strong>
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
      * NOTE/TODO:
      *   this should probably be replaced by explicit use of
      XInclude;
      * e.g. see the xinclude handling in myhtml.xsl
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
      * contain this thread. See add-thread-qlinks-basic for a
      * version that does not link to the various thread sections.
      *
      * Uses the $threadDir variable to find the location of the
      * thread index (published copy)
      *
      * Uses the $threadName variable - the name of the thread
      *
      * Parameters:
      *
      *-->
  <xsl:template name="add-thread-qlinks">

    <!--* read in the thread index *-->
    <xsl:variable name="threadIndex" select="document(concat($threadDir,'index.xml'))"/>

    <div class="qlinkbar">
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
    </div>

  </xsl:template> <!--* name=add-thread-qlinks *-->

  <!--* 
      * used in header/footer to provide links to thread pages.
      * See add-thread-qlinks for a version that also links to
      * the thread sections that contain the thread.
      *
      * Parameters:
      *    text, string, optional
      *       Text to use for the link back to the index page,
      *       defaults to 'Threads Page'.
      *
      *-->
  <xsl:template name="add-thread-qlinks-basic">
    <xsl:param name="text" select="'Threads Page'"/>
    
    <div class="qlinkbar">
      Return to 
      <xsl:call-template name="mylink">
	<xsl:with-param name="dir">../</xsl:with-param>
	<xsl:with-param name="filename"></xsl:with-param>
	<xsl:with-param name="text"><xsl:value-of select="$text"/></xsl:with-param>
      </xsl:call-template>
    </div>
  </xsl:template> <!--* name=add-thread-qlinks-basic *-->

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

    <xsl:call-template name="check-plist-name-exists">
      <xsl:with-param name="name" select="@name"/>
      <xsl:with-param name="id" select="@id"/>
    </xsl:call-template>

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

  <xsl:template name="check-plist-name-exists">
    <xsl:param name="name" select="''"/>
    <xsl:param name="id" select="''"/>
    <xsl:if test="$name = ''">
      <xsl:message terminate="yes">
	ERROR: plist tag is missing a name value
      </xsl:message>
    </xsl:if>

    <!-- make sure there is a paramfile that matches the plist tag -->
    <xsl:variable name="nmatches" select="count(//parameters/paramfile[@name=$name])"/>
    <xsl:choose>
     <xsl:when test="$nmatches=1"/>
     <xsl:when test="$nmatches=0">
	<xsl:message terminate="yes">
ERROR: there is no paramfile entry with a name of '<xsl:value-of select="$name"/>'.
	</xsl:message>
     </xsl:when>

     <xsl:otherwise>
       <!-- look for the same tool name with different ids -->
       <xsl:variable name="idmatches" select="count(//parameters/paramfile[@name=$name][@id=$id])"/>

       <xsl:choose>
	 <xsl:when test="$idmatches=1"/>
	 <xsl:when test="$idmatches=0">
	   <xsl:message terminate="yes">
	     ERROR: there is no paramfile entry with a name of '<xsl:value-of select="$name"/>' and id of '<xsl:value-of select="$id"/>'.
	   </xsl:message>
	 </xsl:when>
	 <xsl:otherwise>
	   <xsl:message terminate="yes">
	     ERROR: there are multiple (<xsl:value-of select="$nmatches"/>) paramfile entries with a name of '<xsl:value-of select="$name"/>' and id of '<xsl:value-of select="$id"/>'.
	   </xsl:message>
	 </xsl:otherwise>
       </xsl:choose>
     </xsl:otherwise>

   </xsl:choose>
 </xsl:template> <!--* name=check-plist-name-exists *-->

  <!--*
      * handle before/after tags in image blocks;
      * This can probably be removed now we use figure blocks
      * instead.
      *-->
  <xsl:template match="before|after">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * Used in a section block to indicate file types
      * - would be nicer in the overview section (say)
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
  <xsl:template match="dataset">
    <xsl:variable name="ocount" select="count(obsidlist/obsid)"/>
    <p>
      <strong>Download the sample data:</strong><xsl:text> </xsl:text>
      <xsl:for-each select="obsidlist/obsid">
	<xsl:value-of select="."/>
	<xsl:if test="boolean(@desc)"><xsl:value-of select="concat(' (',@desc,')')"/></xsl:if>
	<xsl:if test="position() != $ocount"><xsl:text>; </xsl:text></xsl:if>
      </xsl:for-each>
    </p>

    <!-- Trying to get the behavior right here; we want
         the download_chandra_obsid section to appear even when no filetype is
         present, but I am unclear at present what we have in the system.
     -->
    <xsl:variable name="fcount" select="count(filetypelist/filetype)"/>

    <!-- only add this section if a filetypelist is present -->
    <xsl:choose>
      <xsl:when test="@download = 'no'">
        <xsl:if test="$fcount > 0">
	  <p>
	    <strong>File types needed:</strong>
	    <xsl:text> </xsl:text>

	    <xsl:for-each select="filetypelist/filetype">
	      <xsl:value-of select="."/>
	      <xsl:if test="position() != $fcount"><xsl:text>, </xsl:text></xsl:if>
	    </xsl:for-each>
	  </p>
        </xsl:if>
      </xsl:when>

      <xsl:otherwise>
            <div class="screen"><pre class="highlight"><xsl:text>unix% </xsl:text><a><xsl:attribute name="href">/ciao/ahelp/download_chandra_obsid.html</xsl:attribute>download_chandra_obsid</a>
	    <xsl:text> </xsl:text>

	    <xsl:for-each select="obsidlist/obsid">
	      <xsl:value-of select="."/>
	      	<xsl:if test="position() != $ocount"><xsl:text>,</xsl:text></xsl:if>
	    </xsl:for-each>
	    <xsl:text> </xsl:text> 
	    <xsl:for-each select="filetypelist/filetype">
	      <xsl:value-of select="."/>
	      <xsl:if test="position() != $fcount"><xsl:text>,</xsl:text></xsl:if>
	    </xsl:for-each></pre></div>
	  
	</xsl:otherwise>
     </xsl:choose>
  </xsl:template> <!--* match=dataset *-->

  <!--* INVALID *-->
  <xsl:template match="imglink">
    <xsl:message terminate="yes">

 ERROR: The thread contains an imglink tag; you should be using the
   figure environment/figlink instead. See Doug for help.

    </xsl:message>
  </xsl:template> <!--* match=imglink -->

  <!--*
      * Display the thread title in its own block,
      * with ancillary information (at present what language this is for)
      *
      * We also include the CXC logo so that it is included in print
      * media output, and explicitly excluded from screen media versions.
      *-->
  <xsl:template name="add-thread-title">
    <div class="pagetitle">
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

      <p><xsl:choose>
	<xsl:when test="$site = 'ciao'">CIAO <xsl:value-of select="$siteversion"/> Science Threads</xsl:when>
	<xsl:when test="$site = 'chips'">ChIPS Threads (<xsl:value-of select="$headtitlepostfix"/>)</xsl:when>
	<xsl:when test="$site = 'sherpa'">Sherpa Threads (<xsl:value-of select="$headtitlepostfix"/>)</xsl:when>
	<xsl:when test="$site = 'csc'">CSC Threads</xsl:when>
	<xsl:when test="$site = 'iris'">Iris Threads</xsl:when>
	<xsl:when test="$site = 'pog'">Proposer Threads (<xsl:value-of select="$siteversion"/>)</xsl:when>
      </xsl:choose></p>
	  
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
    
    <xsl:choose>
      <!--// don't put siteversion in head of CSC threads //-->
      <xsl:when test="$site = 'csc' or $site = 'chart'">
	<xsl:call-template name="add-htmlhead">
	  <xsl:with-param name="title" select="concat($start,' - ',djb:get-sitename-string())"/>
	</xsl:call-template>
      </xsl:when>
      
      <xsl:otherwise>
	<xsl:call-template name="add-htmlhead">
	  <xsl:with-param name="title" select="concat($start,' - ',$headtitlepostfix)"/>
	  <xsl:with-param name="page" select="'index.html'"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template> <!--* name=add-htmlhead-site-thread *-->

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
      * For those threads that want a common look and feel, use
      * these templates.
      *-->

  <!--*
      * create:
      *    $install/index.html
      *-->
  <xsl:template match="thread" mode="html-viewable-standard">
    
    <xsl:variable name="filename"
		  select="concat($install,'index.html')"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
      version="4.0" encoding="utf-8">

      <!--* get the start of the document over with *-->
      <xsl:call-template name="add-start-html"/>

      <!--* make the HTML head node *-->
      <xsl:call-template name="add-htmlhead-site-thread"/>
      
      <!--* add disclaimer about editing the HTML file *-->
      <xsl:call-template name="add-disclaimer"/>
      
      <!--* make the header *-->
      <xsl:call-template name="add-header"/>

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
	<xsl:if test="$site != 'pog'">
	<xsl:apply-templates select="info/history"/>
	</xsl:if>

	<!--* set up the trailing links to threads/harcdopy *-->
	<xsl:call-template name="add-hr-strong"/>

      </div> <!--* class=mainbar *-->

      <!--* set up the trailing links to threads/harcdopy *-->
      <xsl:call-template name="add-bottom-links-site-html"/>

      <!--* add the footer text *-->
      <xsl:call-template name="add-footer"/>

      <!--* add </body> tag [the <body> is added by the add-htmlhead template] *-->
      <xsl:call-template name="add-end-body"/>
      <xsl:call-template name="add-end-html"/>

    </xsl:document>

  </xsl:template> <!--* match=thread mode=html-viewable-standard *-->

  <!--*
      * Link to a figure in the TOC. The other figure-handling code is in
      * myhtml.xsl.
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

</xsl:stylesheet>
