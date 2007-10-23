<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * Convert navbar.xml into the SSI pages
    * 
    * Recent changes:
    *  Oct 19 2007 DJB
    *    Re-written so that we only process a single depth at a time
    *   v1.6 - use CSS for news section of navbar
    *   v1.2 - code is now split between navbar.xsl and navbar_main.xsl
    *   v1.1 - copy of v1.35 of navbar.xsl
    *
    * To do:
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--*
      * Write the navbar. Context node should be the section/dirs/dir node,
      * which appears only to be important in the setting of the matchid parameter
      * for the call to the section[mode=create] template.
      *
      * We include a logo image IF the logomimage and logotext parameters
      * are set. We have just text if logoimage is unset but logotext is set.
      *
      * The navbar is surrounded by a pair of htdig_noindex /htdig_noindex
      * comments to hide the contents from the search engine used by the
      * CXC. This *includes* the news section (since it would appear on
      * every page + the news should be listed in the news page anyway)
      *
      * Parameters:
      *   filename - string, required
      *     name of file (including directory)
      *
      *-->
  <xsl:template name="write-navbar">
    <xsl:param name="filename" select="''"/>
    
    <xsl:if test="$filename = ''">
      <xsl:message terminate="yes">
  Error: write-navbar called with an empty filename parameter
      </xsl:message>
    </xsl:if>

    <xsl:if test="$logoimage != '' and $logotext = ''">
      <xsl:message terminate="yes">
  Error: logotext is unset but logoimage is set to '<xsl:value-of select="$logoimage"/>'
      </xsl:message>
    </xsl:if>

    <!--* process the page *-->
    <xsl:document href="{$filename}" method="html">
      <xsl:call-template name="navbar-contents"/>
    </xsl:document> <!--* end of a navbar *-->

  </xsl:template> <!--* name=write-navbar *-->

  <!--*
      * Create the contents of a navbar. This
      * has been separated out of write-navbar to
      * make it easier to test.
      *-->
  <xsl:template name="navbar-contents">

    <xsl:variable name="matchid" select="../../@id"/>

    <!--* add disclaimer about editing this HTML file *-->
    <xsl:call-template name="add-disclaimer"/>
    <xsl:comment>htdig_noindex</xsl:comment><xsl:text>
</xsl:text>

    <div>
	
      <!--* add the logo/link if required *-->
      <xsl:call-template name="add-logo-section"/>
      
      <!--* create the various sections *-->
      <dl>
	<xsl:apply-templates select="//section" mode="create">
	  <xsl:with-param name="matchid" select="$matchid"/>
	</xsl:apply-templates>
      </dl>
      <br/>

      <!--*
	  * anything else? (site-specific)
	  * Perhaps we should just go by what is in the navbar rather
	  * than having site-specific code?
	  *
	  * - if links section exists (any site), create it
	  *	BEFORE creating the news items
	  * - if CIAO and there are news items, write out the 
	  *   news bar (for all pages)
	  * - if Sherpa, as CIAO
	  * - if CALDB, as CIAO
	  *-->

      <xsl:choose>
	<xsl:when test="boolean(//links)">
	  <!--* add the links section *-->
	  <xsl:apply-templates select="//links" mode="create"/>
	</xsl:when>
      </xsl:choose>

      <xsl:choose>
	<xsl:when test="$site='ciao' and count(//news/item)!=0">
	  <!--* add the News table *-->
	  <xsl:apply-templates select="//news" mode="create"/>
	</xsl:when>
	
	<xsl:when test="$site='sherpa' and count(//news/item)!=0">
	  <xsl:apply-templates select="//news" mode="create"/>
	</xsl:when>
	
	<xsl:when test="$site='caldb' and count(//news/item)!=0">
	  <xsl:apply-templates select="//news" mode="create"/>
	</xsl:when>
      </xsl:choose>

    </div>

    <!--* re-start the indexing *-->
    <xsl:text>
</xsl:text>
    <xsl:comment>/htdig_noindex</xsl:comment><xsl:text>
</xsl:text>
  </xsl:template> <!--* name=navbar-contents *-->

  <!--*
      * create a section in the current navbar
      * IF we are in the section matching the current navbar's id then we
      * add a marker to the section 'title' link to indicate this is the
      * selected page
      *
      * NOTE: prior to CIAO 3.0 we only listed list contents if it was
      *       the selected section
      *
      *       we now allow sections with no link attribute (as a trial/test)
      *
      * NOTE:
      *   for now we ignore the highlight attribute
      *
      * NOTE:
      *   now 'year 2000' friendly - years can be specified as < 2000
      *   - in which case 2000 is added to them - or displayed as is
      *
      *-->
  <xsl:template match="section" mode="create">
    <xsl:param name="matchid" select='""'/>

    <xsl:variable name="classname"><xsl:choose>
	<xsl:when test="$matchid=@id">selectedheading</xsl:when>
	<xsl:otherwise>heading</xsl:otherwise>
      </xsl:choose></xsl:variable>

    <dt>
      <xsl:choose>
	<xsl:when test="boolean(@link)">
	  <!--* section has a link attribute *-->
	  <a class="{$classname}"><xsl:choose>
	      <xsl:when test="starts-with(@link,'/')">
		<xsl:attribute name="href"><xsl:value-of select="@link"/></xsl:attribute>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:call-template name="add-attribute">
		  <xsl:with-param name="name"  select="'href'"/>
		  <xsl:with-param name="value" select="@link"/>
		</xsl:call-template>
	      </xsl:otherwise></xsl:choose><xsl:value-of select="title"/></a>
	</xsl:when>
	<xsl:otherwise>
	  <!--* no link, so just a title *-->
	  <span class="{$classname}"><xsl:value-of select="title"/></span>
	</xsl:otherwise>
      </xsl:choose>
    </dt>
	
    <!--* any contents? *-->
    <xsl:apply-templates select="list" mode="navbar"/>
    <!--* <br clear="all"/> *-->

  </xsl:template> <!--* match=section mode="create" *-->

  <!--* 
      * create the news section
      * - having a mode of create may be important here in case there's a valid
      *   item attribute elsewhere
      *-->
  <xsl:template match="news" mode="create">
    <hr/>

    <div>

      <div class="newsbar">
        <h2>News</h2>

	  <a href="{$newsfileurl}">Previous Items</a>
      </div>

      <!--* now do the individual items *-->
      <xsl:apply-templates select="item" mode="create"/>

      <!--* and finish with the link to the "old news" section *-->
<!--*
      <p align="center">
	<a>
	  <xsl:call-template name="add-attribute">
	    <xsl:with-param name="name"  select="'href'"/>
	    <xsl:with-param name="value" select="'news.html'"/>
	  </xsl:call-template>Old News Items</a>
      </p>
      *-->

    </div>
  </xsl:template> <!--* match=news mode=create *-->

  <!--*
      * create the news item
      *
      * CIAO 3.1 changes:
      * - added the type attribute, valid values are new or updated
      *   (so you do not use the new or updated tag any more)
      * - each item is placed within a div (no class)
      * - the text now has to be wrapped in <p> tags where
      *   necessary
      *
      *-->
  <xsl:template match="item" mode="create">

    <div>
      <p align="left">
	<strong><xsl:call-template name="calculate-date-from-attributes"/></strong>
	<xsl:text> </xsl:text> <!--* only really necessary if we follow with an image *-->
	<xsl:choose>
	  <xsl:when test="boolean(@type) = false()"/>
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
      </p>
      <xsl:apply-templates/>

      <!--* since have a "old news" item at the end we always put in a hr *-->
      <hr width="80%" align="center"/>
    </div>
  </xsl:template> <!--* match=item mode=create *-->

  <!--* 
      * create the links section for Sherpa/ChaRT/iCXC pages
      * - have a mode of create to replicate "news" template for CIAO pages
      *-->
  <xsl:template match="links" mode="create">

    <!--* add a separator *-->
    <hr/>
    <xsl:apply-templates/>

  </xsl:template> <!--* match=links mode=create *-->

  <!--*
      * we use a mode to disambiguate ourselves from the
      * standard list-handling code in myhtml.xsl so that
      * lists as elements of this main list will be processed as
      * a list, and not as a section list in the navbar
      *
      * css code is made available via add-htmlhead (helper.xsl)
      *-->
  <xsl:template match="list" mode="navbar">
    <xsl:apply-templates mode="navbar"/>
  </xsl:template> <!--* match=list mode=navbar *-->

  <xsl:template match="li" mode="navbar">
    <dd>
      <xsl:apply-templates/>
    </dd>
  </xsl:template> <!--* match=li mode=navbar *-->

  <xsl:template name="add-logo-section">
    <xsl:choose>
      <xsl:when test="$logoimage != '' and $logotext != ''">
	<p align="center">
	  <xsl:call-template name="add-image">
	    <xsl:with-param name="alt"   select="$logotext"/>
	    <xsl:with-param name="src"   select="$logoimage"/>
	  </xsl:call-template>
	</p>
      </xsl:when>
	      
      <xsl:when test="$logotext != ''">
	<p align="center"><xsl:value-of select="$logotext"/></p>
      </xsl:when>

      <!--*
	  * decided to not have any white space as doesn't look
	  * good to me with the re-designed layout
	  *-->
      <xsl:otherwise>
	<!--* <br/> *-->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=add-logo-section *-->

  <!--*
      * This is needed by helper.xsl for some reason
      * that I am too lazy to track down
      *-->
  <xsl:template name="newline"><xsl:text>
</xsl:text></xsl:template>

</xsl:stylesheet>
