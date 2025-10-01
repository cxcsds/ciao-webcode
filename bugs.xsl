<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the bugs HTML page from XML source file
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="exsl extfuncs">

  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-bugs" select="extfuncs:register-import-dependency('bugs.xsl')"/>

  <xsl:output method="text"/>

  <!--* we place this here to see if it works (was in header.xsl and wasn't working
      * - and it seems to
      *-->
  <!--* a template to output a new line (useful after a comment)  *-->
  <xsl:template name="newline">
<xsl:text> 
</xsl:text>
  </xsl:template>

  <!--* load in the set of "global" parameters *-->
  <xsl:include href="globalparams.xsl"/>

  <!--* include the stylesheets AFTER defining the variables *-->
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <!--*
      * top level: create
      *   index.html
      *
      *-->
  <xsl:template match="/">

    <!--* check the params are okay *-->
    <xsl:call-template name="is-site-valid"/>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'install'"/>
      <xsl:with-param name="pvalue" select="$install"/>
    </xsl:call-template>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'canonicalbase'"/>
      <xsl:with-param name="pvalue" select="$canonicalbase"/>
    </xsl:call-template>

    <!--* what do we create *-->
    <xsl:apply-templates select="bugs" mode="page"/>

    <xsl:if test="$site = 'ciao'">
      <xsl:apply-templates select="bugs" mode="include"/>
    </xsl:if>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create bugs page: <bugs>.html
      *-->

  <xsl:template match="bugs" mode="page">

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$pagename"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
                  doctype-system="about:legacy-compat"
		  version="5.0">

      <!--* we start processing the XML file here *-->
      <html lang="en-US">

	<xsl:call-template name="add-htmlhead-standard"/>

	<xsl:call-template name="add-body-withnavbar">
	  <xsl:with-param name="contents">
	    <h1 class="pagetitle">
	      <xsl:value-of select="/bugs/info/title/short"/>
	    </h1>

	    <div class="qlinkbar">
	      <xsl:if test="intro/altlink">
		<p>
		  <xsl:text>Related pages: </xsl:text>
		  <xsl:apply-templates select="intro/altlink"/>
		</p>
	      </xsl:if>		  
		
	      <xsl:if test="$site='ciao' and not(/bugs/info/noahelp)">
		<xsl:variable name="ahelpname"><xsl:choose>
		  <xsl:when test="/bugs/info/ahelpname"><xsl:value-of select="/bugs/info/ahelpname"/></xsl:when>
		  <xsl:otherwise><xsl:value-of select="$pagename"/></xsl:otherwise>
		</xsl:choose></xsl:variable>
		<xsl:variable name="hrefval"
			      select="concat('../ahelp/', $ahelpname, '.html')"/>
		<p>
		  For detailed information and examples of running this tool,
		  refer to
		  <a href="{$hrefval}"><xsl:value-of
		  select="concat('the ', $pagename, ' ahelp file')"/></a>.
		  <xsl:if test="$site='ciao' and (/bugs/info/scripts)">
		    This script is part of
		    the <a href="../download/scripts/index.html">CIAO Scripts Package</a>.
		  </xsl:if> 
		</p>
	      </xsl:if>
	    </div>

	    <xsl:if test="intro/note">
	      <xsl:apply-templates select="intro/note"/>
	    </xsl:if>
	    
	    <xsl:variable name="ctbuglist" select="count(//buglist/entry[not(@cav)])"/>
	    <xsl:variable name="ctcavlist" select="count(//buglist/entry[@cav])"/>
	    
	    <xsl:variable name="isbuglist">
	      <xsl:choose>
		<xsl:when test="$ctbuglist > 0">1</xsl:when>
		<xsl:otherwise>0</xsl:otherwise>
	      </xsl:choose>
	    </xsl:variable>
	    
	    <xsl:variable name="iscavlist">
	      <xsl:choose>
		<xsl:when test="$ctcavlist > 0">1</xsl:when>
		<xsl:otherwise>0</xsl:otherwise>
	      </xsl:choose>
	    </xsl:variable>
	    
	    <xsl:variable name="isfixlist" select="count(//fixlist)"/>
	    <xsl:variable name="isscriptlist" select="count(//scriptlist)"/>
	    <xsl:variable name="istotal" select="$isbuglist + $iscavlist + $isfixlist + $isscriptlist"/>
	    
	    <xsl:if test="($istotal > 1) or (//buglist/subbuglist)">
	      
	      <ul class="inlinenav">
		
		<xsl:if test="//buglist/entry[@cav]">
		  <li>
		    <a>
		      <xsl:attribute name="href">
			<xsl:text>#caveats</xsl:text>
		      </xsl:attribute>
		      
		      <xsl:text>Caveats</xsl:text>
		    </a>
		  </li>		     
		</xsl:if>

		<xsl:if test="(//buglist/entry[not(@cav)]) or (//buglist/subbuglist)">
		  
		  <xsl:choose>
		    <xsl:when test="(//buglist/subbuglist)">
		      <xsl:for-each select="//buglist/subbuglist">
			<xsl:choose>
			  <xsl:when test="position()=1">
			    
			    <li>
			      <xsl:text>Bugs: </xsl:text>
			      <a>
				<xsl:attribute name="href">
				  <xsl:text>#</xsl:text>
				  <xsl:value-of select="@ref"/>
				</xsl:attribute>
				
				<xsl:value-of select="@title"/>
			      </a>
			    </li>
			  </xsl:when>
			  
			  <xsl:otherwise>
			    <li>
			      <a>
				<xsl:attribute name="href">
				  <xsl:text>#</xsl:text>
				  <xsl:value-of select="@ref"/>
				</xsl:attribute>
				
				<xsl:value-of select="@title"/>
			      </a>
			    </li>
			  </xsl:otherwise>
			</xsl:choose>
		      </xsl:for-each>
		    </xsl:when>

		    <xsl:otherwise>
		      <li>
			<a href="#bugs">Bugs</a>
		      </li>		     
		    </xsl:otherwise>
		  </xsl:choose>
		</xsl:if>

		<xsl:if test="//fixlist">		
		  <xsl:for-each select="//fixlist">
		    <li>
		      <a>
			<xsl:attribute name="href">
			  <xsl:text>#</xsl:text>
			  <xsl:value-of select="concat('ciao',./@ver)"/>
			</xsl:attribute>
			
			<xsl:text>Bugs fixed in CIAO </xsl:text>
			<xsl:value-of select="./@vername"/>
		      </a>
		    </li>
		  </xsl:for-each>
		</xsl:if>

		<xsl:if test="//scriptlist">
		  <xsl:for-each select="//scriptlist">
		    <li>
		      <a>
		        <xsl:attribute name="href">
			  <xsl:text>#</xsl:text>
			  <xsl:value-of select="@ver"/>
			</xsl:attribute>
			
			<xsl:value-of select="@vername"/>
			<xsl:text> Bug Fixes</xsl:text>
		      </a>
		    </li>
		  </xsl:for-each>
		</xsl:if>
		
	      </ul> <!-- end inlinenav -->
	    </xsl:if>

	    <xsl:if test="(//buglist/entry and count(//buglist/entry)>1) or (//buglist/subbuglist)">
	      <hr/>
	    </xsl:if>
	    <!--// end front materials //-->
	    

	    <!--// any known bugs? -->
	    <xsl:if test="not(//buglist)">

	      <hr/>
	      <p>
		There are currently no known bugs.
	      </p>
	      <hr/>

	    </xsl:if>


	    <!--// create TOC if there is more than one bug entry //-->
	    <xsl:if test="//buglist/subbuglist or (//buglist/entry and count(//buglist/entry)>1)">
	      <h2 class="toc">Table of Contents</h2>
	      
	      <xsl:if test="//buglist/entry[@cav]">
	        <h3 id="caveats">Caveats</h3>
		
		<ul>
		  <xsl:apply-templates select="//buglist/entry[@cav]" mode="toc"/>
		</ul>
	      </xsl:if>
	      
	      <xsl:if test="(//buglist/entry[not(@cav)]) or (//buglist/subbuglist)">
		
		<xsl:choose>
	          <xsl:when test="//buglist/subbuglist">
		    <xsl:apply-templates select="//buglist/subbuglist" mode="toc"/>
	          </xsl:when>
		  
		  <xsl:otherwise>
	            <h3 id="bugs">Bugs</h3>
		    
		    <ul>
		      <xsl:apply-templates select="//buglist/entry[not(@cav)]" mode="toc"/>
		    </ul>
		  </xsl:otherwise>
		</xsl:choose>	      
	      </xsl:if>
	    </xsl:if>
	    <!--// end TOC //-->

	    <!-- create body //-->
	    
	    <xsl:if test="//buglist/entry[@cav]">
	      <hr/>

	      <section>
		<h2>Caveats</h2>
		<xsl:apply-templates select="//buglist/entry[@cav]" mode="main"/>
	      </section>
	      
	    </xsl:if>
	    
	    <xsl:if test="(//buglist/entry[not(@cav)]) or (//buglist/subbuglist)">
	      <hr/>

	      <section>
		<h2>Bugs</h2>
	      
		<xsl:choose>
	          <xsl:when test="//buglist/subbuglist">
		    <xsl:apply-templates select="//buglist/subbuglist" mode="main"/>
	          </xsl:when>
		
		  <xsl:otherwise>
		    <xsl:apply-templates select="//buglist/entry[not(@cav)]" mode="main"/>
		  </xsl:otherwise>
		</xsl:choose>
	      </section>
	    </xsl:if>
	    
	    <!--// add "fixed in CIAO x.x" section if applicable //-->
	    <xsl:if test="//fixlist">
	      
	      <xsl:if test="//buglist">
	        <hr/>
	      </xsl:if>

	      <xsl:for-each select="//fixlist">
		<section>
		  <h2>
		    <xsl:attribute name="id">
		      <xsl:value-of select="concat('ciao',./@ver)"/>
		    </xsl:attribute>
		  
		    <xsl:text>Bugs fixed in CIAO </xsl:text>
		    <xsl:value-of select="./@vername"/>
		  </h2>
		
		  <p>
		    The following is a list of bugs that were fixed
		    in the CIAO <xsl:value-of select="./@vername"/>
		    software release.
		  </p>
		
		  <xsl:apply-templates select="./entry" mode="main"/>
		</section>
	      </xsl:for-each>
	    </xsl:if>
	    <!--// end "fixed in CIAO x.x" section //-->

	    
	    <!--// add "fixed in version x.x of this script" section if applicable //-->
	    <xsl:if test="//scriptlist">
	      
	      <xsl:if test="(//buglist) or (//fixlist)">
	        <hr/>
	      </xsl:if>
	      
	      <xsl:for-each select="//scriptlist">
		<section>
		  <h2>
		    <a>
		      <xsl:attribute name="id">
			<xsl:value-of select="@ver"/>
		      </xsl:attribute>
		    
		      <xsl:value-of select="@vername"/>
		      <xsl:text> Bug Fixes</xsl:text>
		    </a>
		  </h2>
		
		  <p>
		    The following is a list of bugs that were fixed
		    in version <xsl:value-of select="@vername"/>.
		  </p>
		
		  <xsl:apply-templates select="entry" mode="main"/>
		</section>
	      </xsl:for-each>
	    </xsl:if>
	    <!--// end "fixed in version x.x" section //-->
	    <!--// end body //-->
	  </xsl:with-param>

	  <xsl:with-param name="navbar">
	    <xsl:call-template name="add-navbar">
	      <xsl:with-param name="name" select="info/navbar"/>
	    </xsl:call-template>
	  </xsl:with-param>

	  <!-- TODO: do we want to make this optional? -->
	  <xsl:with-param name="breadcrumbs" select="true()"/>
	  <xsl:with-param name="location" select="$filename"/>
	</xsl:call-template>

      </html>

    </xsl:document>
  </xsl:template> <!--* match=bugs *-->


  <!--* 
      * create the file that ahelp processing will pick up to
      * include this information in the ahelp page.
      *
      * TODO: do not write out if
      *   just contains 'no known bugs' statement.
      *
      *-->
  <xsl:template match="bugs" mode="include">

    <!-- write the slug to the storage area -->
    <xsl:variable name="outloc" select="$storageInfo//dir[@site=$site]"/>
    <xsl:variable name="filename"
		  select="concat($outloc, 'bugs/', $pagename, '.slug.xml')"/>
    
    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>
    <xsl:variable name="should-not-be-a-function"
		  select="extfuncs:delete-file-if-exists($filename)"/>
    
    <xsl:document href="{$filename}" method="xml" encoding="UTF-8">
      <!--* add disclaimer about editing this HTML file *-->
      <xsl:call-template name="add-disclaimer"/>
      <slug>
	<xsl:if test="not(//buglist)">
	  <p>There are no known bugs for this tool.</p>
	</xsl:if>
	
	<xsl:if test="(//buglist/entry[not(@cav)]) or (//buglist/subbuglist)">
	  <xsl:choose>
	    <xsl:when test="//buglist/subbuglist">
	      <xsl:apply-templates select="//buglist/subbuglist" mode="ahelp-buglist"/>
	    </xsl:when>
	    
	    <xsl:otherwise>
	      <dl>
		<xsl:apply-templates select="//buglist/entry[not(@cav)]" mode="ahelp-buglist"/>
	      </dl>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:if>
	
	<xsl:if test="//buglist/entry[@cav]">
	  <h2 id="caveats">Caveats</h2>
	  
	  <dl>
	    <xsl:apply-templates select="//buglist/entry[@cav]" mode="ahelp-buglist"/>
	  </dl>
	</xsl:if>
      </slug>
    </xsl:document>
  </xsl:template> <!--* match=bugs mode=include *-->


  <!--* note: we process the text so we can handle our `helper' tags *-->
  <xsl:template match="text">
   <xsl:apply-templates/>
  </xsl:template>

  <!-- subbuglist table of contents template -->
  <xsl:template match="subbuglist" mode="toc">
    
    <xsl:for-each select=".">

    <h3>
       <a>
         <xsl:attribute name="href">
	   <xsl:text>#</xsl:text>
	   <xsl:value-of select="@ref"/>
	 </xsl:attribute>

	 <xsl:value-of select="@title"/>
       </a>
    </h3>

      <ul>
	<xsl:apply-templates select="./entry" mode="toc"/>
      </ul>

    </xsl:for-each>
  </xsl:template> 
  <!-- end subbuglist table of contents template -->


  <!-- table of contents template -->
  <xsl:template match="entry" mode="toc">
    <xsl:for-each select=".">

    <!-- create summary and id -->
      <li>
        <p>
       <a>
         <xsl:attribute name="href">
	   
	   <xsl:choose>
	     <xsl:when test="@ref"><xsl:text>#</xsl:text><xsl:value-of select="@ref"/></xsl:when>
	     <xsl:when test="@bugnum"><xsl:text>#bug-</xsl:text><xsl:value-of select="@bugnum"/></xsl:when>
	     <xsl:otherwise>
      <xsl:message terminate="yes">

 ERROR: you must have either a ref or a bugnum attribute on the entry

      </xsl:message>
	     </xsl:otherwise>
	   </xsl:choose>
	 </xsl:attribute>

	 <xsl:apply-templates select="summary/*|summary/text()"/>

	 <!--// add new/updated icon if the entry has a type attribute //-->
	 <xsl:if test="@type">
	   <xsl:choose>
	     <xsl:when test="@type = 'new'">
	       <xsl:call-template name="add-image">
		 <xsl:with-param name="src"   select="'imgs/new.gif'"/>
		 <xsl:with-param name="alt"   select="'New'"/>
	       </xsl:call-template>
	     </xsl:when>

	     <xsl:when test="@type = 'updated'">
	       <xsl:call-template name="add-image">
		 <xsl:with-param name="src"   select="'imgs/updated.gif'"/>
		 <xsl:with-param name="alt"   select="'Updated'"/>
	       </xsl:call-template>
	     </xsl:when>

	     <xsl:otherwise>
	       <xsl:message terminate="yes">
 ERROR: item tag found in navbar with unrecognised type attribute
   of type=<xsl:value-of select="@type"/>
	       </xsl:message>
	     </xsl:otherwise>
	   </xsl:choose>	  
	 </xsl:if>

	 <xsl:if test="./date">
	   <xsl:apply-templates select="./date"/>
	 </xsl:if>

	 <xsl:if test="./platform">
	 <br/>
	     <xsl:text>(</xsl:text>
	       <xsl:apply-templates select="platform/text()"/>
	     <xsl:text>) </xsl:text>  
	 </xsl:if>

       </a>
       </p>
      </li>
    </xsl:for-each>
  </xsl:template> 
  <!-- table of contents template -->


  <!-- subbuglist content template -->
  <xsl:template match="subbuglist" mode="main">
    
    <xsl:for-each select=".">

      <h3>
	<a>
	  <xsl:attribute name="id">
            <xsl:value-of select="@ref"/>
	  </xsl:attribute>

	  <xsl:value-of select="@title"/>
	</a>
      </h3>

      <xsl:apply-templates select="entry" mode="main"/>

    </xsl:for-each>
  </xsl:template> 
  <!-- end subbuglist content template -->

  <!-- main bug content template -->
  <xsl:template match="entry" mode="main">

    <xsl:for-each select=".">

    <!-- create summary and id -->
    <article class="bugitem">
      <!-- should we auto-generate the heading level? -->
      <h3 class="bugsummary">
	<xsl:attribute name="id">

	  <xsl:choose>
	    <xsl:when test="@ref"><xsl:value-of select="@ref"/></xsl:when>
	    <xsl:when test="@bugnum"><xsl:text>bug-</xsl:text><xsl:value-of select="@bugnum"/></xsl:when>
	    <xsl:otherwise>
	      <xsl:message terminate="yes">

 ERROR: you must have either a ref or a bugnum attribute on the entry

	      </xsl:message>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:attribute>

	<xsl:apply-templates select="summary/*|summary/text()"/>

	<!--// add new/updated icon if the entry has a type attribute //-->
	<xsl:if test="@type">
	  <xsl:choose>
	    <xsl:when test="@type = 'new'">
	      <xsl:call-template name="add-image">
		<xsl:with-param name="src"   select="'imgs/new.gif'"/>
		<xsl:with-param name="alt"   select="'New'"/>
	      </xsl:call-template>
	    </xsl:when>

	    <xsl:when test="@type = 'updated'">
	      <xsl:call-template name="add-image">
		<xsl:with-param name="src"   select="'imgs/updated.gif'"/>
		<xsl:with-param name="alt"   select="'Updated'"/>
	      </xsl:call-template>
	    </xsl:when>

	    <xsl:otherwise>
	      <xsl:message terminate="yes">
 ERROR: item tag found in navbar with unrecognised type attribute
   of type=<xsl:value-of select="@type"/>
	      </xsl:message>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:if>

	<xsl:if test="./date">
	  <!-- TODO: could use time tag -->
	  <xsl:apply-templates select="./date"/>
	</xsl:if>
      </h3>

      <xsl:if test="./platform">
	<!-- TODO: check styling -->
	<p class="platforms">
          <xsl:text>Platforms: </xsl:text>
          <xsl:apply-templates select="platform/text()"/>
	</p>
      </xsl:if>
      <!-- done with summary and id -->

      <xsl:if test="./desc">
	<div class="buganswer">
          <xsl:apply-templates select="desc/*"/>
	</div>
      </xsl:if> 

      <xsl:if test="./work">
	<div class="buganswer">
        <xsl:if test="count(work) > 1">
          <h4>Workarounds:</h4>

	  <ol>
	    <xsl:for-each select="work">	
	      <li>
		<xsl:apply-templates select="./*"/>
	      </li>
	    </xsl:for-each>
	  </ol>
	</xsl:if> 
	        
        <xsl:if test="count(work) = 1">
          <h4>Workaround:</h4>

	  <xsl:apply-templates select="work/*"/>
	</xsl:if> 
	</div>
      </xsl:if>

      <!-- should we always warn if desc is not given? -->
      <xsl:if test="not(./desc) and not(./work)">
	<xsl:message terminate="no">
  NOTE: entry <xsl:choose>
  <xsl:when test="@ref">ref=<xsl:value-of select="@ref"/></xsl:when>
  <xsl:when test="@bugnum">bugnum=<xsl:value-of select="@bugnum"/></xsl:when>
  <xsl:otherwise>{{THIS SHOULD NOT HAPPEN}}</xsl:otherwise>
</xsl:choose> has no desc or work elements.
	</xsl:message>
      </xsl:if>
    </article>
    </xsl:for-each>
  </xsl:template> 
  <!-- end main bug content template -->



  <!-- subbuglist ahelp content template -->
  <xsl:template match="subbuglist" mode="ahelp-buglist">
    
    <xsl:for-each select=".">

    <h3><xsl:value-of select="@title"/></h3>

      <xsl:apply-templates select="entry" mode="ahelp-buglist"/>

    </xsl:for-each>
  </xsl:template> 
  <!-- end subbuglist ahelp content template -->


  <!-- ahelp bug content template -->
  <xsl:template match="entry" mode="ahelp-buglist">

    <xsl:for-each select=".">

    <!-- create summary and id -->
    <dt class="ahelp">
	<xsl:apply-templates select="summary/*|summary/text()"/>
	
	 <!--// add new/updated icon if the entry has a type attribute //-->
	 <xsl:if test="@type">
	   <xsl:choose>
	     <xsl:when test="@type = 'new'">
	       <xsl:call-template name="add-image">
		 <xsl:with-param name="src"   select="'imgs/new.gif'"/>
		 <xsl:with-param name="alt"   select="'New'"/>
	       </xsl:call-template>
	     </xsl:when>

	     <xsl:when test="@type = 'updated'">
	       <xsl:call-template name="add-image">
		 <xsl:with-param name="src"   select="'imgs/updated.gif'"/>
		 <xsl:with-param name="alt"   select="'Updated'"/>
	       </xsl:call-template>
	     </xsl:when>

	     <xsl:otherwise>
	       <xsl:message terminate="yes">
 ERROR: item tag found with unrecognised type attribute
   of type=<xsl:value-of select="@type"/>
	       </xsl:message>
	     </xsl:otherwise>
	   </xsl:choose>	  
	 </xsl:if>

	 <xsl:if test="./date">
	   <xsl:apply-templates select="./date"/>
	 </xsl:if>

        <xsl:if test="./platform">
	  <br/>
          <xsl:text>(</xsl:text>
            <xsl:apply-templates select="platform/text()"/>
          <xsl:text>) </xsl:text>  
        </xsl:if>
	</dt>
    <!-- done with summary and id -->

      <xsl:if test="./desc">
		<dd>
        <xsl:apply-templates select="desc/*"/>
		</dd>
      </xsl:if> 

      <xsl:if test="./work">
		<dd>
        <xsl:if test="count(work) > 1">
          <h4>Workarounds:</h4>

	  <ol>
	    <xsl:for-each select="work">	
	      <li>
		<xsl:apply-templates select="./*"/>
	      </li>
	    </xsl:for-each>
	  </ol>
	</xsl:if> 
	        
        <xsl:if test="count(work) = 1">
          <h4>Workaround:</h4>

	  <xsl:apply-templates select="work/*"/>
	</xsl:if> 
	</dd>
	</xsl:if> 
    </xsl:for-each>
  </xsl:template> 
  <!-- end ahelp bug content template -->


  <!--* altlinks template *-->
  <xsl:template match="intro/altlink">
    <xsl:for-each select=".">
      <a>
	<!-- should this check that @ref ends in index.html if a directory? -->
         <xsl:attribute name="href">
	   <xsl:value-of select="@ref"/>
	 </xsl:attribute>
	   <xsl:value-of select="text()"/>
       </a>
    </xsl:for-each>

    <xsl:if test="position() != last()">
      <xsl:text> | </xsl:text>
    </xsl:if>
  </xsl:template> 
  <!--* end altlinks template *-->


  <!--* intro/note template *-->
  <xsl:template match="intro/note">
    <xsl:apply-templates/>
  </xsl:template> 


  <!--* date template *-->
  <xsl:template match="date">

  <span class="date">&#160;(<xsl:number value="@day" format="01"/>
    <xsl:text>&#160;</xsl:text>
    <xsl:value-of select="substring(@month,1,3)"/>
    <xsl:text>&#160;</xsl:text>
    <xsl:choose>
      <xsl:when test="@year >= 2000"><xsl:number value="@year"/></xsl:when>
      <xsl:otherwise><xsl:number value="@year+2000"/></xsl:otherwise>
    </xsl:choose>)</span>
  </xsl:template> 
  <!--* end date template *-->

</xsl:stylesheet>
