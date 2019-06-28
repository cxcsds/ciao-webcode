<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * process the sections of the thread index for the CIAO, ChIPS, and Sherpa pages
    *
    * Parameters set in threadindex.xsl
    *  . threadDir - location of input thread XML files
    *              defaults to /data/da/Docs/<site>web/published/<type>/threads/
    *
    *  . site=one of: ciao sherpa
    *    tells the stylesheet what site we are working with
    *    [no support for chart thread index at the moment]
    *
    * Notes:
    *  - FOR CIAO 3.1 we need to sort out the way that new/updated threads
    *    are reported on the index pages (the move to using h3/4 tags has
    *    probably messed-up the current system)
    *
    *  - some templates may collide with those in other stylesheets
    *    (primarily myhtml.xsl) - needs looking at
    *
    *  - one improvement would be for the thread-processing code to
    *    create a slimmed-down XML version of the thread which contains
    *    the information needed to create the index. This would then
    *    be read in rather than the thread itself, reducing time/memory
    *    requirements.
    *
    *  - For CIAO 4 we need to deal with language-specific versions of
    *    some threads; for CIAO 4.3 this is no-longer needed.
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="extfuncs">
  
  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-threadindex_common" select="extfuncs:register-import-dependency('threadindex_common.xsl')"/>

  <!--*
      * handle the sublist element
      *
      * We add a "br" to the end of the list IF the following item is
      * an item tag (ie we don't if it is followed by nothing or a sublist)
      *
      *-->
  <xsl:template match="sublist" mode="threadindex">

    <li>
      <div class="threadsublist">
	<h4><xsl:apply-templates select="title" mode="show"/></h4>

	<xsl:if test="boolean(text)">
	  <xsl:apply-templates select="text"/>
	</xsl:if>

	<ul>
	  <!--* we do not want to process the title element here *-->
	  <xsl:apply-templates select="*[name() != 'title' and name() != 'text']" mode="threadindex"/>
	</ul>
	<!--* do we need a spacer? *-->
	<xsl:if test="name(following-sibling::*[1]) = 'item'">
	  <br/>
	</xsl:if>
      </div>
    </li>
  </xsl:template> <!--* match=sublist mode=threadindex *-->

  <!--* 
      * this is an important empty tag 
      * - poor design of DTD ?
      *-->
  <xsl:template match="title"/>

  <xsl:template match="title" mode="show">
    <xsl:apply-templates/>
    <xsl:call-template name="newline"/>
  </xsl:template>

  <!--*
      * process lists slightly differently to the
      * way they are handled in myhtml.xsl
      * - this means we can simpligy the list-handling
      *   in myhtml
      *-->
  <xsl:template match="list" mode="threadindex">
    <div class="threadlist">
      <ul>
	<xsl:apply-templates mode="threadindex"/>
      </ul>
    </div>
  </xsl:template> <!--* match=list mode=threadindex *-->

  <!--* 
      * handle a single thread 
      * we delegate most of the processing to templates that match
      * tags in thread.xml, as this is the easiest way I can think
      * of of importing the document into the system, without
      * having to read any actual documentation on XSLT myself...
      *
      * Actually, have a couple of different modes
      *   <item name="foo"/>
      *   <item><text>...</text></item>
      *
      *-->
  <xsl:template match="item" mode="threadindex">

    <li>
      <!--* what goes here? *-->
      <xsl:choose>
	<xsl:when test="boolean(text)">
	  <xsl:apply-templates select="text"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:call-template name="list-thread"/>
	</xsl:otherwise>
      </xsl:choose>

      <!--*
          * if the next item is a sublist then we want a br here as well 
          * - as long as we're not in a sublist ourselves
          *
          * NOTE: this is not quite right, as a sublist in a sublist
          *       will not get the br tags when it should, but I can't
          *       be bothered to sort that out just now
          *-->
      <xsl:if test='name(following::*[position()=1])="sublist" and name(..)!="sublist"'>
	<br/>
      </xsl:if>

    </li>

  </xsl:template> <!--* match=item mode=threadindex *-->

  <!--* 
      * text 
      * 
      * this may conflict with other templates
      * BUT currently the only one is in page.xsl which won't be loaded
      * with this file
      * 
      *-->
  <xsl:template match="text">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * list a thread
      *
      * List the title and any associated scripts
      * (as of CIAO 3.1 we only provide a single script package, so
      *  can not link to the individual scripts/packages; hence we no
      *  longer link to the script but just list it.)
      *
      *-->
  <xsl:template name="list-thread">

    <!--*
	* Read the thread into a variable to avoid multiple parses of the file.
	* As we are sure of the site of this thread we can use $threadDir and
	* not $storageloc
	*-->
    <xsl:variable name="thisThread" select="document(concat($threadDir,@name,'/thread.xml'))"/>
    <xsl:variable name="thisThreadInfo" select="$thisThread/thread/info"/>

    <!--*
        * create a link to the thread
        * - QUESTION: should we use the same system as the threadlink
        *   tag - ie use the handle-thread-site-link template - to get
        *   depth-handling/etc consistent???
        *   OR, do we assume that as we are in the thread index everything
        *   is in the sub-directory of this page so we needn't bother?
	*
        *-->
    <a class="threadlink" href="{$thisThreadInfo/name}/"><xsl:value-of select="$thisThreadInfo/title/long"/></a>

    <!--* Is this thread new or recently updated ? *-->
    <xsl:if test="boolean($thisThreadInfo/history/@new)">
      <xsl:text> </xsl:text>
      <xsl:call-template name="add-new-image"/>
      <xsl:apply-templates select="$thisThreadInfo/history" mode="date"/>
    </xsl:if>
    <xsl:if test="boolean($thisThreadInfo/history/@updated)">
      <xsl:text> </xsl:text>
      <xsl:call-template name="add-updated-image"/>
      <xsl:apply-templates select="$thisThreadInfo/history" mode="date"/>
    </xsl:if>
	
  </xsl:template> <!--* name=list-thread *-->

  <!--* print out the last date from the history block *-->
  <xsl:template match="history" mode="date">
    <xsl:variable name="entry" select="entry[last()]"/>
    <xsl:variable name="year"><xsl:choose>
	<xsl:when test="$entry/@year > 1999"><xsl:value-of select="$entry/@year"/></xsl:when>
	<xsl:otherwise><xsl:value-of select="2000+$entry/@year"/></xsl:otherwise>
      </xsl:choose></xsl:variable>
    (<xsl:value-of select="concat($entry/@day,' ',substring($entry/@month,1,3),' ',$year)"/>)
  </xsl:template> <!--* /thread mode=date *-->

  <!--* 
      * Note:
      *   There is the possibility for conflict since we
      *   use the script tag in more than one place with different
      *   syntax and semantics. However they shouldn't collide
      *   since in different places (eg info vs text blocks)
      *   [have a hopefully-unique mode in here just in case]
      *
      * Assumes that the stylesheet "global" parameter site is set
      *
      * was originally in helper.xsl
      *
      * AS OF CIAO 3.1 we:
      * - no longer create a link
      * - print a warning if we come across a "package" element
      *   [the following-sibling::script check below should be
      *   enhanced to ignore such elements but I can not be bothered just now]
      *-->
  <xsl:template match="script" mode="threadindex">
    <!--* TEMPORARY HACK *-->
    <xsl:if test="boolean(@package)">
      <xsl:message>

 WARNING: script element with @package attribute
 script=<xsl:value-of select="."/>
 thread=<xsl:value-of select="$thisThreadInfo/name"/>

      </xsl:message>
    </xsl:if>
    the <span class="tt"><xsl:value-of select="."/></span>>
    <xsl:if test="boolean(@slang)"> S-Lang</xsl:if>
    script<xsl:if test="count(following-sibling::script)!=0">; </xsl:if>
  </xsl:template> <!--* match=script mode=threadindex *-->

  <!--* 
      * make the data table: 
      *   called with threadindex as the context node
      *   (ie *NOT* datatable)
      *
      * Parameters:
      *
      * In CIAO 3.1 added the "threaddatatable" id to the table
      * (so that can hide the link using CSS for the print option)
      *-->
  <xsl:template name="make-datatable">

<!--//BOB//-->
    <xsl:if test="boolean(//threadindex/datatable)">

    <table style="width: 90%;" id="threaddatatable"> 
      <tr>    
        <td id="threaddatatableheader" colspan="2">
	    <h3>Data Used in Threads</h3>

	<xsl:if test="boolean(//threadindex/datatable/datasets)">
	    <br/>
	    <a class="tablehead">
	      <xsl:attribute name="href">
	        <xsl:choose>
		  <xsl:when test="$site='ciao'">archivedownload/</xsl:when>
		  <xsl:when test="$site='sherpa'">/ciao/threads/archivedownload/</xsl:when>
		  </xsl:choose>
	       </xsl:attribute>How to Download Chandra Data from the Archive</a>
	</xsl:if>
	</td>
      </tr>

      <!--* datasets *-->
      <xsl:apply-templates select="datatable/datasets"/>

      <!--* packages *--> 
      <xsl:apply-templates select="datatable/packages"/>
    </table>
  </xsl:if>
  </xsl:template> <!--* name=make-datatable *-->

  <!--* 
      * create entry for the datasets
      * - set up table structure and then process each dataset
      *-->
  <xsl:template match="datasets">

    <!--* set up the header for this section *-->

    <tr>
      <th>ObsID</th>
      <th>Object</th>
      <th>Instrument</th> 
      <th>Threads</th>
    </tr>  
    
    <!--* process the individual datasets *-->
    <xsl:apply-templates select="dataset"/>

  </xsl:template> <!--* match=datasets *-->

  <!--* 
      * create entry for a single dataset 
      *-->
  <xsl:template match="dataset">
    <tr>
      <td>
	  <xsl:value-of select="@obsid"/>
      </td>
      <td>
	<xsl:apply-templates select="object"/>
      </td>
      <td>
	<xsl:apply-templates select="instrument"/>
      </td>
      <td>
	<!--* loop over the threads *-->
	<xsl:for-each select="thread">
	  <xsl:if test="position()>1"><br/></xsl:if>
	  <xsl:apply-templates select="."/>
	</xsl:for-each>
      </td>
    </tr> 

    <!--* add a separator *-->
    <xsl:if test="position() != last()">
    <tr>
      <th colspan="2"><hr/></th>
    </tr>
    </xsl:if>
  </xsl:template> <!--* match=dataset *-->

  <!--*
      * since we now copy over unknown nodes, we need explicit
      * rules for the items in a dataset node.
      * We just pass through the text (after processing it)
      *-->
  <xsl:template match="object|instrument|thread">
<xsl:apply-templates/>
  </xsl:template> <!--* name=object|instrument|thread *-->

  <!--* 
      * create entry for the packages
      * - set up table structure and then process each package
      *-->
  <xsl:template match="packages">

    <!--* set up the header for this section *-->
    <tr>
      <th colspan="2">Sorted by Thread</th>
    </tr>
    <tr>
      <th>File</th>
      <th>Thread</th>
    </tr>  

    <!--* process the individual packages *--> 
    <xsl:apply-templates select="package"/>
      
  </xsl:template> <!--* match=packages *-->

  <!--* 
      * create entry for a single package 
      *
      * note:
      * - assumes we are within the threads/ dir [for location of the data]
      *
      *-->
  <xsl:template match="package">

    <tr>
      <td>
	<span class="tt">
	  <a href="data/{file}"><xsl:value-of select="file"/></a>
	</span>
      </td>
      <td>
	<xsl:choose>
	  <xsl:when test="count(descendant::p)=0">
	    <p>
	      <xsl:apply-templates select="text"/>
	    </p>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:apply-templates select="text"/>
	  </xsl:otherwise>
	</xsl:choose>
      </td>
    </tr>

  </xsl:template> <!--* match=package *-->

  <!--*
      * create the "quick link" list of links
      * - somewhat of a mess since shoe-horning CIAO and Sherpa
      *   pages into the same template
      *
      *-->
  <xsl:template name="add-threadindex-quicklink">
    <div class="navlinkbar qlinkbar">
	<a href="index.html">Top</a> |
	<a href="all.html">All</a> |
	<!--* 
	    * note: use absolute xpath location here since not always
            * called with threadindex as its context node (eg datatable)
            *-->
	<xsl:for-each select="//threadindex/section/id">
	  <a href="{name}.html"><xsl:apply-templates select="text"/></a> 

	  <xsl:if test="position() != last()">
	  | 
	  </xsl:if>
	</xsl:for-each>
	<!--* do we have a data table ? *-->
	<xsl:if test="boolean(//threadindex/datatable)">
	  | <a href="table.html">Datasets</a>
	</xsl:if>
	<!--* sort out the separator: | if no external links, || if there are *-->
	<xsl:choose>
	  <xsl:when test="count(//threadindex/qlinks/qlink)!=0">
	    <xsl:text> || </xsl:text>
	    <!--* and now the "external" links *-->
	    <xsl:for-each select="//threadindex/qlinks/qlink">

	    <xsl:choose>
	      <xsl:when test="position() = last()">
	        <a href="{@href}"><xsl:value-of select="normalize-space(.)"/></a> 
	      </xsl:when>
	      <xsl:otherwise>
	        <a href="{@href}"><xsl:value-of select="normalize-space(.)"/></a> | 
	      </xsl:otherwise>
	    </xsl:choose>
	    </xsl:for-each>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:text> |</xsl:text>
	  </xsl:otherwise>
	</xsl:choose>
      </div>
    <hr/>
  </xsl:template> <!--* name=add-threadindex-quicklink *-->

  <!--* 
      * create the individual section pages
      *
      * requires:
      *   $install variable/parameter
      *-->
  <xsl:template match="section" mode="make-section">

    <xsl:if test="normalize-space(id/name)=''">
      <xsl:message terminate="yes">
 name attribute of section is missing or empty!
      </xsl:message>
    </xsl:if>

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select='id/name'/>.html</xsl:variable>
    <xsl:variable name="version" select="/threadindex/version"/>
    
    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>
    
    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
                  doctype-system="about:legacy-compat"
		  version="5.0">

      <!--* get the start of the document over with *-->
      <html lang="en-US">

	<xsl:call-template name="add-threadindex-start">
	  <xsl:with-param name="title"><xsl:value-of select="id/title"/> Threads<xsl:value-of select="concat(' - ',$headtitlepostfix)"/></xsl:with-param>
	  <xsl:with-param name="name" select="id/name"/>
	</xsl:call-template>

	<xsl:call-template name="add-body-withnavbar">
	  <xsl:with-param name="contents">
	    <xsl:if test="boolean(//threadindex/breadcrumbs)">
	      <xsl:call-template name="add-breadcrumbs">
		<xsl:with-param name="location" select="$filename"/>
	      </xsl:call-template>
	    </xsl:if>

	    <!--* set up the title block of the page *-->
	    <xsl:call-template name="add-threadindex-title">
	      <xsl:with-param name="title" select="id/title"/>
	    </xsl:call-template>
		
	    <!--* do we have a synopsis? *-->
	    <xsl:apply-templates select="synopsis" mode="section-page"/>
	    
	    <!--* process the section *-->
	    <xsl:apply-templates select="." mode="section-page"/>

	    <xsl:if test="boolean(//threadindex/breadcrumbs)">
	      <xsl:call-template name="add-breadcrumbs">
		<xsl:with-param name="pos" select="'bottom'"/>
		<xsl:with-param name="location" select="$filename"/>
	      </xsl:call-template>
	    </xsl:if>
	  </xsl:with-param>

	  <xsl:with-param name="navbar">
	    <xsl:call-template name="add-navbar">
	      <xsl:with-param name="name" select="//threadindex/navbar"/>
	    </xsl:call-template>
	  </xsl:with-param>

	</xsl:call-template>

      </html>

    </xsl:document>
  </xsl:template> <!--* match=section mode=make-section *-->

  <!--*
      * create: table.html (the data table page)
      **-->
  <xsl:template match="threadindex" mode="make-table">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>table.html</xsl:variable>
    <xsl:variable name="version" select="/threadindex/version"/>
    
    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>
    
    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
                  doctype-system="about:legacy-compat"
		  version="5.0">

      <!--* get the start of the document over with *-->
      <html lang="en-US">

	<xsl:call-template name="add-threadindex-start">
	  <xsl:with-param name="title">Data for Threads<xsl:value-of select="concat(' - ',$headtitlepostfix)"/></xsl:with-param>
	  <xsl:with-param name="name">table</xsl:with-param>
	</xsl:call-template>

	<xsl:call-template name="add-body-withnavbar">
	  <xsl:with-param name="contents">
	    <xsl:if test="boolean(//threadindex/breadcrumbs)">
	      <xsl:call-template name="add-breadcrumbs">
		<xsl:with-param name="location" select="$filename"/>
	      </xsl:call-template>
	    </xsl:if>
	    
	    <!-- set up the title block of the page -->
	    <xsl:call-template name="add-threadindex-title">
	      <xsl:with-param name="title"><xsl:choose>
		<xsl:when test="$site='ciao'">Data for CIAO <xsl:value-of select="$siteversion"/> Threads</xsl:when>
		<xsl:otherwise>Data for Threads</xsl:otherwise>
	      </xsl:choose></xsl:with-param>
	    </xsl:call-template>
	    
	    <!--* add the data table *-->
	    <xsl:call-template name="make-datatable"/>
	
	    <xsl:if test="boolean(//threadindex/breadcrumbs)">
	      <xsl:call-template name="add-breadcrumbs">
		<xsl:with-param name="pos" select="'bottom'"/>
		<xsl:with-param name="location" select="$filename"/>
	      </xsl:call-template>
	    </xsl:if>
	  </xsl:with-param>

	  <xsl:with-param name="navbar">
	    <xsl:call-template name="add-navbar">
	      <xsl:with-param name="name" select="//threadindex/navbar"/>
	    </xsl:call-template>
	  </xsl:with-param>

	</xsl:call-template>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=threadindex mode=make-table *-->

  <!--* 
      * create: index.html 
      *-->
  <xsl:template match="threadindex" mode="make-index">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>index.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>
    
    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
                  doctype-system="about:legacy-compat"
		  version="5.0">

      <!--* get the start of the document over with *-->
      <html lang="en-US">

	<xsl:call-template name="add-threadindex-start">
	  <xsl:with-param name="title"><xsl:if test="$site='sherpa'">Sherpa </xsl:if>Threads<xsl:value-of select="concat(' - ',$headtitlepostfix)"/></xsl:with-param>
	  <xsl:with-param name="name">index</xsl:with-param>
	</xsl:call-template>

	<xsl:call-template name="add-body-withnavbar">

	  <xsl:with-param name="contents">
	    <xsl:if test="boolean(//threadindex/breadcrumbs)">
	      <xsl:call-template name="add-breadcrumbs">
		<xsl:with-param name="location" select="$filename"/>
	      </xsl:call-template>
	    </xsl:if>

	    <!-- set up the title block of the page -->
	    <xsl:call-template name="add-threadindex-title"/>
		
	    <!--* include the header text *-->
	    <xsl:apply-templates select="header"/>
	    
	    <div class="threadindex">

	      <div class="threadsection">
		<h3><a href="all.html"><em>All</em> threads</a></h3>
		<div class="threadsnopsis">
		  <p>A list of all the threads on one page.</p>
		</div>
	      </div>
		  
	      <!--* process the sections in the index *-->
	      <xsl:apply-templates select="section" mode="index-page"/>
              
	      <!--* do we have a data table? *-->
	      <xsl:if test="boolean(//threadindex/datatable)">
		<div class="threadsection">
		  <h3><a href="table.html">Datasets</a></h3>
		  <div class="threadsynopsis">
		    <p>Links to the datasets used in the threads.</p>
		  </div>
		</div>
	      </xsl:if>
	      
	    </div>

	    <xsl:if test="boolean(//threadindex/breadcrumbs)">
	      <xsl:call-template name="add-breadcrumbs">
		<xsl:with-param name="pos" select="'bottom'"/>
		<xsl:with-param name="location" select="$filename"/>
	      </xsl:call-template>
	    </xsl:if>
	  </xsl:with-param>

	  <xsl:with-param name="navbar">
	    <xsl:call-template name="add-navbar">
	      <xsl:with-param name="name" select="//threadindex/navbar"/>
	    </xsl:call-template>
	  </xsl:with-param>

	</xsl:call-template>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=threadindex mode=make-index *-->

  <!--* 
      * create: all.html 
      *-->
  <xsl:template match="threadindex" mode="make-all">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>all.html</xsl:variable>
    <xsl:variable name="version" select="/threadindex/version"/>
    
    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>
    
    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" 
                  doctype-system="about:legacy-compat"
		  version="5.0">

      <!--* get the start of the document over with *-->
      <html lang="en-US">

	<xsl:call-template name="add-threadindex-start">
	  <xsl:with-param name="title">All Threads<xsl:value-of select="concat(' - ',$headtitlepostfix)"/></xsl:with-param>
	  <xsl:with-param name="name">all</xsl:with-param>
	</xsl:call-template>

	<xsl:call-template name="add-body-withnavbar">
	  <xsl:with-param name="contents">
	    <xsl:if test="boolean(//threadindex/breadcrumbs)">
	      <xsl:call-template name="add-breadcrumbs">
		<xsl:with-param name="location" select="$filename"/>
	      </xsl:call-template>
	    </xsl:if>

	    <!-- set up the title block of the page -->
	    <xsl:call-template name="add-threadindex-title"/>
		
	    <!--* process the sections in the index *-->
	    <div class="threadindex">
	      <xsl:apply-templates select="section" mode="all-page"/>
	    </div>
		
	    <br/><br/> <!-- TODO: replace these with CSS -->
		
	    <!--* add the data table *-->
	    <xsl:call-template name="make-datatable"/>
	
	    <xsl:if test="boolean(//threadindex/breadcrumbs)">
	      <xsl:call-template name="add-breadcrumbs">
		<xsl:with-param name="pos" select="'bottom'"/>
		<xsl:with-param name="location" select="$filename"/>
	      </xsl:call-template>
	    </xsl:if>
	  </xsl:with-param>

	  <xsl:with-param name="navbar">
	    <xsl:call-template name="add-navbar">
	      <xsl:with-param name="name" select="//threadindex/navbar"/>
	    </xsl:call-template>
	  </xsl:with-param>

	</xsl:call-template>
      </html>
      
    </xsl:document>
  </xsl:template> <!--* match=threadindex mode=make-all *-->

  <!--*
      * create the start of an index page
      *
      * Parameters:
      *   title - title of page (appears in head block so should be concise)
      *   name  - name of page (w/out .html), used for the canonical block
      *
      *-->
  <xsl:template name="add-threadindex-start">
    <xsl:param name="title" select="'Threads'"/>
    <xsl:param name="name"  select="''"/>

    <xsl:if test="$name=''">
      <xsl:message terminate="yes">
 Error: add-threadindex-start called with no name attribute
      </xsl:message>
    </xsl:if>

    <!--* make the HTML head node *-->
    <xsl:call-template name="add-htmlhead">
      <xsl:with-param name="title" select="$title"/>
      <xsl:with-param name="page" select="concat($name, '.html')"/>
    </xsl:call-template>

  </xsl:template> <!--* name=add-threadindex-start *-->

  <!--* 
      * handle a section - for the index page
      * - we output the contents of the synopsis section here
      * - up to CIAO 3.0 we used to explicitly list the new/changed threads
      *   but we now (due to all the extra text) just indicate that some threads
      *   have changed in the section
      *-->
  <xsl:template match="section" mode="index-page">

    <div class="threadsection">
      <h3><a href="{id/name}.html"><xsl:apply-templates select="title" mode="show"/></a><xsl:call-template name="report-if-new-or-updated-threads-icons"/></h3>

      <xsl:apply-templates select="synopsis" mode="index-page"/>

    </div> <!--* class=threadsection *-->

  </xsl:template> <!--* match=section mode=index-page *-->

  <!--*
      * report if any new or updated threads are in this section
      * 
      * Prior to CIAO 3.1 we included the number of threads and
      * icons to flag the sections. The new CIAO 3.1 layout makes
      * this a bit more cumbersome (due to the use of actual header
      * elements). We could probably come up with a scheme using CSS
      * but it is easier just to drop the reporting of the number of
      * threads (just leave the icons)
      * 
      * - all we say is "6 new, 4 updated"
      * - would like to include a date but that looks like it's
      *   going to be hard to do in this system
      *
      *-->
  <xsl:template name="report-if-new-or-updated-threads">
    <xsl:variable name="threads" select=".//item[boolean(@name)]"/>

    <!--* return a string of u and n's for updated and new threads *-->
    <xsl:variable name="state"><xsl:apply-templates select="$threads" mode="report-if-new-or-updated-threads"/></xsl:variable>
    <xsl:variable name="nnew"><xsl:value-of select="string-length(normalize-space(translate($state,'u','')))"/></xsl:variable>
    <xsl:variable name="nupd"><xsl:value-of select="string-length(normalize-space(translate($state,'n','')))"/></xsl:variable>

    <xsl:if test="$nnew != 0 or $nupd != 0">
      <!--* add a header with the info *-->
      <h4><xsl:choose>
	  <xsl:when test="$nnew != 0 and $nupd != 0">
	    <xsl:value-of select="concat($nnew,' New &amp; ',$nupd,' Updated threads ')"/>
	  </xsl:when>
	  <xsl:when test="$nnew &gt; 1">
	    <xsl:value-of select="concat($nnew,' New threads ')"/>
	  </xsl:when>
	  <xsl:when test="$nnew = 1">
	    <xsl:value-of select="concat($nnew,' New thread ')"/>
	  </xsl:when>
	  <xsl:when test="$nupd &gt; 1">
	    <xsl:value-of select="concat($nupd,' Updated threads')"/>
	  </xsl:when>
	  <xsl:when test="$nupd = 1">
	    <xsl:value-of select="concat($nupd,' Updated thread')"/>
	  </xsl:when>
	</xsl:choose></h4>
    </xsl:if>
  </xsl:template> <!--* name=report-if-new-or-updated-threads *-->

  <xsl:template name="report-if-new-or-updated-threads-icons">
    <xsl:variable name="threads" select=".//item[boolean(@name)]"/>

    <!--* return a string of u and n's for updated and new threads *-->
    <xsl:variable name="state"><xsl:apply-templates select="$threads" mode="report-if-new-or-updated-threads"/></xsl:variable>
    <xsl:variable name="nnew"><xsl:value-of select="string-length(normalize-space(translate($state,'u','')))"/></xsl:variable>
    <xsl:variable name="nupd"><xsl:value-of select="string-length(normalize-space(translate($state,'n','')))"/></xsl:variable>

    <!--* do we add the images? *-->
    <xsl:if test="$nnew != 0">
      <xsl:call-template name="add-new-image"/>
    </xsl:if>

    <xsl:if test="$nupd != 0">
      <xsl:call-template name="add-updated-image"/>
    </xsl:if>

  </xsl:template> <!--* name=report-if-new-or-updated-threads-icons *-->

  <!--*
      * "returns" a u if the thread is updated, n if it is new, nothing otherwise
      *
      *-->
  <xsl:template match="item" mode="report-if-new-or-updated-threads">
    <xsl:variable name="ThreadInfo" select="document(concat($threadDir,@name,'/thread.xml'))/thread/info"/>

    <xsl:choose>
      <xsl:when test="$ThreadInfo/history[@new=1]"><xsl:text>n</xsl:text></xsl:when>
      <xsl:when test="$ThreadInfo/history[@updated=1]"><xsl:text>u</xsl:text></xsl:when>
    </xsl:choose>
  </xsl:template> <!--* match=item mode=report-if-new-or-updated-threads *-->

  <!--* a new thread *-->
  <xsl:template match="item" mode="list-new">

    <xsl:variable name="ThreadInfo" select="document(concat($threadDir,@name,'/thread.xml'))/thread/info"/>

    <xsl:if test="$ThreadInfo/history[@new=1]">
      <li>
	<a href="{$ThreadInfo/name}/"><xsl:value-of select="$ThreadInfo/title/long"/></a>
	<xsl:apply-templates select="$ThreadInfo/history" mode="date"/>
	<xsl:call-template name="add-new-image"/>
      </li>
    </xsl:if>
  </xsl:template> <!--* item mode=list-new *-->

  <!--* an updated thread *-->
  <xsl:template match="item" mode="list-updated">
    <xsl:variable name="ThreadInfo" select="document(concat($threadDir,@name,'/thread.xml'))/thread/info"/>
    <xsl:if test="$ThreadInfo/history[@updated=1]">
      <li>
	<a href="{$ThreadInfo/name}/"><xsl:value-of select="$ThreadInfo/title/long"/></a>
	<xsl:apply-templates select="$ThreadInfo/history" mode="date"/>
	<xsl:call-template name="add-updated-image"/>
      </li>
    </xsl:if>
  </xsl:template> <!--* item mode=list-updated *-->

  <!--*
      * handle a section: for all-in-one page
      * 
      *-->
  <xsl:template match="section" mode="all-page">

    <div class="threadsection">
      <h3 id="{@name}"><xsl:apply-templates select="title" mode="show"/></h3>

      <!--* synopsis? *-->
      <xsl:apply-templates select="synopsis" mode="section-page"/>
	
      <!--* list the threads *-->
      <xsl:apply-templates select="list" mode="threadindex"/>
      <br/>
    </div> <!--* class=threadsection *-->

  </xsl:template> <!--* match=section mode=all-page *-->

  <!--*
      * handle a section: for individual section pages
      * 
      *-->
  <xsl:template match="section" mode="section-page">
    <xsl:apply-templates select="list" mode="threadindex"/>
  </xsl:template>

  <!--*
      * process the header block
      *-->
  <xsl:template match="header">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * adds a "title" which depends on the site
      * 
      * Params:
      *   title, string, optional
      *     title to use, otherwise guesses one bnased on the site
      * 
      *-->
  <xsl:template name="add-threadindex-title">
    <xsl:param name="title" select="''"/>

    <h1 class="pagetitle"><xsl:choose>
	<xsl:when test="$title = ''">
	  <xsl:choose>
	    <xsl:when test="$site = 'ciao'">Science</xsl:when>
	    <xsl:when test="$site = 'sherpa'">Sherpa</xsl:when>
	    <xsl:when test="$site = 'chips'">ChIPS</xsl:when>
	    <xsl:when test="$site = 'csc'">CSC</xsl:when>
	    <xsl:when test="$site = 'iris'">Iris</xsl:when>
	  </xsl:choose>

	  <!--// don't include "Threads for CIAO version" in CSC //-->
	  <xsl:if test="$site='ciao' or $site='chips' or $site='sherpa'">
	    <xsl:value-of select="concat(' ',$ciaothreadver)"/>
	  </xsl:if>
	  <xsl:if test="$site='csc' or $site='iris'">
	    <xsl:text> Threads</xsl:text>
	  </xsl:if>
	</xsl:when>


	<xsl:otherwise><xsl:value-of select="$title"/></xsl:otherwise>
      </xsl:choose></h1>

    <!--* create the list of section links *-->

    <xsl:if test="$site != 'csc' and $site != 'iris'">
      <xsl:call-template name="add-whatsnew-link"/>
    </xsl:if>

    <xsl:call-template name="add-threadindex-quicklink"/>

  </xsl:template> <!--* name=add-threadindex-title *-->

  <!--*
      * display the synopsis section from the thread index
      * we use modes to disambiguate from the other occurences
      * of a synopsis tag
      *-->
  <xsl:template match="synopsis" mode="index-page">
    <div class="threadsynopsis">
      <xsl:apply-templates/>
    </div>
  </xsl:template> <!--* match=synopsis mode=index-page *-->
  
  <xsl:template match="synopsis" mode="section-page">
    <div class="threadsynopsis">
      <xsl:apply-templates/>
    </div>
  </xsl:template> <!--* match=synopsis mode=section-page *-->
  
</xsl:stylesheet>
