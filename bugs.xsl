<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the bugs HTML page from XML source file
    *
    * $Id: bugs.xsl,v 1.5 2007/04/20 19:57:09 egalle Exp $ 
    *-->

<!--* 
    * Recent changes:
    *   v1.4 - fixlist takes "ver" and "vername" b.c of Beta releases
    *   v1.3 - now uses "add-image" template to add an image, changed
    *	       date tag to have day/month/year attributes
    *   v1.2 - fixed summary to allow for updated and new tags added
    *	       manually; added "date" information to summary
    *   v1.1 - copy of v1.16 of faq.xsl
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="exsl">

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

    <!--* what do we create *-->
    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<xsl:if test="$site = 'icxc'">
	  <xsl:message terminate="yes">
PROGRAMMING ERROR: site=icxc and hardcopy=1
	  </xsl:message>
	</xsl:if>
	<xsl:apply-templates name="bugs" mode="make-hardcopy">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </xsl:when>
      
      <xsl:otherwise>
	<xsl:apply-templates name="bugs" mode="make-viewable">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: <bugs>.html
      *-->

  <xsl:template match="bugs" mode="make-viewable">
    <xsl:param name="depth" select="1"/>

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$pagename"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">

      <!--* we start processing the XML file here *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-standard"/>

	<!--* add disclaimer about editing this HTML file *-->
	<xsl:call-template name="add-disclaimer"/>

	<!--* make the header - it's different depending on whether this is
	    * a test version or the actual production HTML 
            *-->
	<xsl:call-template name="add-header">
	  <xsl:with-param name="depth" select="$depth"/>
	  <xsl:with-param name="name" select="$pagename"/>
	</xsl:call-template>


        <!--* use a table to provide the page layout *-->
	<table class="maintable" width="100%" border="0" cellspacing="2" cellpadding="2">
	    <tr>
	      <xsl:call-template name="add-navbar">
	        <xsl:with-param name="name" select="info/navbar"/>
	      </xsl:call-template>

	      <td class="mainbar" valign="top">
	      <!--* the main text *-->
	      <a name="maintext"/>

	      <div align="center">
	        <h1>
		  <xsl:value-of select="/bugs/info/title/short"/>
		</h1>
	      </div>

	      <div class="topbar">
	        <div class="qlinkbar">
		  Return to: <a href=".">Bug List Index</a>

		  <xsl:if test="intro/altlink">
		    <br/>
		      <xsl:text>Related pages: </xsl:text>
		      <xsl:apply-templates select="intro/altlink"/>
		  </xsl:if>		  
		</div>
	      </div>

	      <hr/>

	      <!--* add any intro text (often used for scripts) *-->
	      <xsl:if test="intro/note">
	        <xsl:apply-templates select="intro/note">
		  <xsl:with-param name="depth" select="$depth"/>
	        </xsl:apply-templates>
	      </xsl:if>

	      <xsl:if test="not(//buglist)">

		<p>
		  There are currently no known bugs.
		</p>

	      </xsl:if>

	      <xsl:if test="//fixlist">
		  <p>
		    A list of 
		      <a>
		        <xsl:attribute name="href">
			  <xsl:text>#</xsl:text>
			  <xsl:value-of select="concat('ciao',//fixlist/@ver)"/>
			</xsl:attribute>

			<xsl:text>bugs fixed in CIAO </xsl:text>
			  <xsl:value-of select="//fixlist/@vername"/>
		      </a>

		    is available.
		  </p>
		  
	      </xsl:if>

	      <xsl:if test="//scriptlist">
		  <p>
		    A list of 
		      <a>
		        <xsl:attribute name="href">
			  <xsl:text>#</xsl:text>
			  <xsl:value-of select="concat('ciao',//scriptlist/@ver)"/>
			</xsl:attribute>

			<xsl:text>bugs fixed in version </xsl:text>
			  <xsl:value-of select="//scriptlist/@ver"/>
			<xsl:text> of this script</xsl:text>
		      </a>

		    is available.
		  </p>
		  
	      </xsl:if>

              <xsl:if test="(intro/note) or (//fixlist) or (//scriptlist) or not(//buglist)">
                <hr/>
              </xsl:if>
	      <!--// end front materials //-->


	      <!--// create TOC //-->
	      <xsl:if test="//buglist/entry[@cav]">
	        <h2>Caveats</h2>

		<ol>
		  <xsl:apply-templates select="//buglist/entry[@cav]" mode="toc"/>
		</ol>
	      </xsl:if>

	      <xsl:if test="(//buglist/entry[not(@cav)]) or (//buglist/subbuglist)">
	        <h2>Bugs</h2>

	      <!--// 
		     allows for subsections of the bug list
		     (mainly used for the Data Model page)
	      //-->

	      <xsl:choose>
	        <xsl:when test="//buglist/subbuglist">
		  <xsl:apply-templates select="//buglist/subbuglist" mode="toc"/>
	        </xsl:when>

		<xsl:otherwise>
		  <ol>
		    <xsl:apply-templates select="//buglist/entry[not(@cav)]" mode="toc"/>
		  </ol>
		</xsl:otherwise>
	      </xsl:choose>
	      
	      </xsl:if>
	      <!--// end TOC //-->


	      <!-- create body //-->

	      <xsl:if test="//buglist/entry[@cav]">
	        <hr/>

	        <h2>Caveats</h2>

		<ol>
		  <xsl:apply-templates select="//buglist/entry[@cav]" mode="main"/>
		</ol>
	      </xsl:if>

	      <xsl:if test="(//buglist/entry[not(@cav)]) or (//buglist/subbuglist)">
	        <hr/>

	        <h2>Bugs</h2>

	      <xsl:choose>
	        <xsl:when test="//buglist/subbuglist">
		  <xsl:apply-templates select="//buglist/subbuglist" mode="main"/>
	        </xsl:when>

		<xsl:otherwise>
		  <ol>
		    <xsl:apply-templates select="//buglist/entry[not(@cav)]" mode="main"/>
		  </ol>
		</xsl:otherwise>
	      </xsl:choose>
	      </xsl:if>
	      
	      <!--// add "fixed in CIAO x.x" section if applicable //-->
	      <xsl:if test="//fixlist">

	        <xsl:if test="//buglist">
	          <hr/>
		</xsl:if>

		<h2>
		  <a>
		    <xsl:attribute name="name">
		      <xsl:value-of select="concat('ciao',//fixlist/@ver)"/>
		    </xsl:attribute>
		    
		    <xsl:text>Bugs fixed in CIAO </xsl:text>
		      <xsl:value-of select="//fixlist/@vername"/>
		  </a>
		</h2>

		<p>
		  The following is a list of bugs that were fixed
		  in the CIAO <xsl:value-of select="//fixlist/@vername"/>
		  software release.
		</p>

		<ol>
		  <xsl:apply-templates select="//fixlist/entry" mode="main"/>
		</ol>
	      </xsl:if>
	      <!--// end "fixed in CIAO x.x" section //-->

	      
	      <!--// add "fixed in version x.x of this script" section if applicable //-->
	      <xsl:if test="//scriptlist">

	        <xsl:if test="(//buglist) or (//fixlist)">
	          <hr/>
		</xsl:if>

		<h2>
		  <a>
		    <xsl:attribute name="name">
		      <xsl:value-of select="concat('ciao',//scriptlist/@ver)"/>
		    </xsl:attribute>
		    
		    <xsl:text>Bugs fixed in version </xsl:text>
		      <xsl:value-of select="//scriptlist/@ver"/>
		    <xsl:text> of this script</xsl:text>

		  </a>
		</h2>

		<p>
		  The following is a list of bugs that were fixed
		  in version <xsl:value-of select="//scriptlist/@ver"/>
		  of this script.
		</p>

		<ol>
		  <xsl:apply-templates select="//scriptlist/entry" mode="main"/>
		</ol>
	      </xsl:if>
	      <!--// end "fixed in version x.x" section //-->
	      <!--// end body //-->

	      </td>
	    </tr>
	  </table>
	    
	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="depth" select="$depth"/>
	  <xsl:with-param name="name"  select="$pagename"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=bugs mode=make-viewable *-->

  <!--* 
      * create: <bugs>.hard.html
      *-->

  <xsl:template match="bugs" mode="make-hardcopy">
    <xsl:param name="depth" select="1"/>

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$pagename"/>.hard.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">

      <!--* we start processing the XML file here *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-standard"/>

	<!--* and now the main part of the text *-->
	<body>

	  <xsl:call-template name="add-hardcopy-banner-top">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	  <!--* do not need to bother with navbar's here as the hardcopy version *-->

	      <div align="center">
	        <h2>
		  <xsl:value-of select="/bugs/info/title/short"/>
		</h2>
	      </div>

	      <!--* add any intro text (often used for scripts) *-->
	      <xsl:if test="intro/note">
	        <xsl:apply-templates select="intro/note">
		  <xsl:with-param name="depth" select="$depth"/>
	        </xsl:apply-templates>
	      </xsl:if>

	      <xsl:if test="not(//buglist)">

		<p>
		  There are currently no known bugs.
		</p>

	      </xsl:if>

	      <xsl:if test="//fixlist">
		  <p>
		    A list of bugs fixed in CIAO <xsl:value-of
		    select="//fixlist/@vername"/> is included at the end
		    of this document.
		  </p>		  
	      </xsl:if>

	      <xsl:if test="//scriptlist">
		  <p>
		    A list of bugs fixed in version <xsl:value-of
		    select="//scriptlist/@ver"/> of this script is
		    available. 
		  </p>		  
	      </xsl:if>

              <xsl:if test="(intro/note) or (//fixlist) or (//scriptlist)">
                <hr/>
              </xsl:if>

	      <!--// end front materials //-->

	      <xsl:if test="//buglist/entry[@cav]">

	        <h2>Caveats</h2>

		<ol>
		  <xsl:apply-templates select="//buglist/entry[@cav]" mode="main"/>
		</ol>

		<hr/>
	      </xsl:if>

	      <xsl:if test="(//buglist/entry[not(@cav)]) or (//buglist/subbuglist)">

	        <h2>Bugs</h2>

	      <xsl:choose>
	        <xsl:when test="//buglist/subbuglist">
		  <xsl:apply-templates select="//buglist/subbuglist" mode="main"/>
	        </xsl:when>

		<xsl:otherwise>
		  <ol>
		    <xsl:apply-templates select="//buglist/entry[not(@cav)]" mode="main"/>
		  </ol>
		</xsl:otherwise>
	      </xsl:choose>

	      </xsl:if>


	      <!--// add "fixed in CIAO x.x" section if applicable //-->
	      <xsl:if test="//fixlist">

	        <xsl:if test="(//buglist/entry[not(@cav)]) or (//buglist/subbuglist)">
	          <hr/>
		</xsl:if>

		<h2>
		  <a>
		    <xsl:attribute name="name">
		      <xsl:value-of select="concat('ciao',//fixlist/@ver)"/>
		    </xsl:attribute>
		    
		    <xsl:text>Bugs fixed in CIAO </xsl:text>
		      <xsl:value-of select="//fixlist/@vername"/>
		  </a>
		</h2>

		<p>
		  The following is a list of bugs that were fixed
		  in the CIAO <xsl:value-of select="//fixlist/@vername"/>
		  software release.
		</p>

		<ol>
		  <xsl:apply-templates select="//fixlist/entry" mode="main"/>
		</ol>
	      </xsl:if>
	      <!--// end "fixed in CIAO x.x" section //-->

	      <!--// add "fixed in version x.x of the script" section if applicable //-->
	      <xsl:if test="//scriptlist">

	        <xsl:if test="(//buglist/entry[not(@cav)]) or (//buglist/subbuglist) or (//fixlist)">
	          <hr/>
		</xsl:if>

		<h2>
		  <a>
		    <xsl:attribute name="name">
		      <xsl:value-of select="concat('ciao',//scriptlist/@ver)"/>
		    </xsl:attribute>
		    
		    <xsl:text>Bugs fixed in version </xsl:text>
		      <xsl:value-of select="//scriptlist/@ver"/>
		    <xsl:text> of this script</xsl:text>

		  </a>
		</h2>

		<p>
		  The following is a list of bugs that were fixed
		  in version <xsl:value-of select="//scriptlist/@ver"/>
		  of this script.
		</p>

		<ol>
		  <xsl:apply-templates select="//scriptlist/entry" mode="main"/>
		</ol>
	      </xsl:if>
	      <!--// end "fixed in version x.x" section //-->


	  <xsl:call-template name="add-hardcopy-banner-bottom">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	</body>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=bugs mode=make-hardcopy *-->

  <!--* note: we process the text so we can handle our `helper' tags *-->
  <xsl:template match="text">
   <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template> <!--* text *-->


  <!-- subbuglist table of contents template -->
  <xsl:template match="subbuglist" mode="toc">
    
    <xsl:for-each select=".">

    <h3>
       <a>
         <xsl:attribute name="href">
	   <xsl:text>#</xsl:text>
	   <xsl:value-of select="@ref"/>
	 </xsl:attribute>

	 <strong><xsl:value-of select="@title"/></strong>
       </a>
    </h3>

      <ol>
	<xsl:apply-templates select="./entry" mode="toc"/>
      </ol>

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
	   <xsl:text>#</xsl:text>
	   <xsl:value-of select="@ref"/>
	 </xsl:attribute>

	 <xsl:apply-templates select="summary/*|summary/text()">
	   <xsl:with-param name="depth" select="$depth"/>
	 </xsl:apply-templates>


	 <!--// add new/updated icon if the entry has a type attribute //-->
	 <xsl:if test="@type">
	   <xsl:choose>
	     <xsl:when test="@type = 'new'">
	       <xsl:call-template name="add-image">
	         <xsl:with-param name="depth" select="$depth"/>
		 <xsl:with-param name="src"   select="'imgs/new.gif'"/>
		 <xsl:with-param name="alt"   select="'New'"/>
	       </xsl:call-template>
	     </xsl:when>

	     <xsl:when test="@type = 'updated'">
	       <xsl:call-template name="add-image">
	         <xsl:with-param name="depth" select="$depth"/>
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
      <xsl:attribute name="name">
        <xsl:value-of select="@ref"/>
      </xsl:attribute>

      <strong><xsl:value-of select="@title"/></strong>
      </a>
    </h3>

    <ol>
      <xsl:apply-templates select="entry" mode="main"/>
    </ol>

    </xsl:for-each>
  </xsl:template> 
  <!-- end subbuglist content template -->

  <!-- main bug content template -->
  <xsl:template match="entry" mode="main">

    <xsl:for-each select=".">

    <!-- create summary and id -->
    <li>
      <p>
      <a>
      <xsl:attribute name="name">
        <xsl:value-of select="@ref"/>
      </xsl:attribute>

        <strong>
	<xsl:apply-templates select="summary/*|summary/text()">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>

	 <!--// add new/updated icon if the entry has a type attribute //-->
	 <xsl:if test="@type">
	   <xsl:choose>
	     <xsl:when test="@type = 'new'">
	       <xsl:call-template name="add-image">
	         <xsl:with-param name="depth" select="$depth"/>
		 <xsl:with-param name="src"   select="'imgs/new.gif'"/>
		 <xsl:with-param name="alt"   select="'New'"/>
	       </xsl:call-template>
	     </xsl:when>

	     <xsl:when test="@type = 'updated'">
	       <xsl:call-template name="add-image">
	         <xsl:with-param name="depth" select="$depth"/>
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

	</strong>
      </a>
      </p>
    <!-- done with summary and id -->

      <xsl:if test="./desc">
        <xsl:apply-templates select="desc/*">
	  <xsl:with-param name="depth" select="$depth"/>
	</xsl:apply-templates>
      </xsl:if> 

      <xsl:if test="./work">
        <xsl:if test="count(work) > 1">
          <h4>Workarounds:</h4>

	  <ol>
	    <xsl:for-each select="work">	
	    <li>
	      <xsl:apply-templates select="./*">
	        <xsl:with-param name="depth" select="$depth"/>
	      </xsl:apply-templates>
	    </li>
	    </xsl:for-each>
	  </ol>
	</xsl:if> 
	        
        <xsl:if test="count(work) = 1">
          <h4>Workaround:</h4>

	  <xsl:apply-templates select="work/*">
	    <xsl:with-param name="depth" select="$depth"/>
	  </xsl:apply-templates>
	</xsl:if> 

	</xsl:if> 
    </li>
    </xsl:for-each>
  </xsl:template> 
  <!-- end main bug content template -->


  <!--* altlinks template *-->
  <xsl:template match="intro/altlink">
    <xsl:for-each select=".">
       <a>
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
    <xsl:param name="depth" select="1"/>

    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template> 
  <!--* end intro template *-->


  <!--* date template *-->
  <xsl:template match="date">
    <xsl:param name="depth" select="1"/>

  <font size="-1">(<xsl:number value="@day" format="01"/>
    <xsl:text>&#160;</xsl:text>
    <xsl:value-of select="substring(@month,1,3)"/>
    <xsl:text>&#160;</xsl:text>
    <xsl:choose>
      <xsl:when test="@year >= 2000"><xsl:number value="@year"/></xsl:when>
      <xsl:otherwise><xsl:number value="@year+2000"/></xsl:otherwise>
    </xsl:choose>)</font>
  </xsl:template> 
  <!--* end date template *-->

</xsl:stylesheet>