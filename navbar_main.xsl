<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * Convert navbar.xml into the SSI pages
    *
    * $Id: navbar_main.xsl,v 1.7 2007/05/04 19:36:31 egalle Exp $ 
    *-->

<!--* 
    * NEEDS to be re-written to not do multiple depths since this
    * leads to horrible templates everywhere (since the depth parameter needs 
    * to be passed through to every template)
    * 
    * Recent changes:
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
      * process each section with an id attribute
      * (the id constraint is made in selecting the nodes to
      *  send to this template)
      *-->
  <xsl:template match="section" mode="with-id">
    <xsl:param name="depth" select="1"/>

    <xsl:if test="boolean(@id)=false()">
      <xsl:message terminate="yes">
 ERROR: match=section mode=with-id called but node has
   no id attribute
      </xsl:message>
    </xsl:if>

    <!--*
        * are there any dirs?
        * - we process the empty dir tag separately from the other tags
        *-->
    <xsl:for-each select="dirs/dir[.='']">
      <!--* there really should be only one of these at most *-->
      <xsl:apply-templates select="ancestor::section" mode="process">
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>

    </xsl:for-each>

    <!--* now the remaining dir tags *-->
    <xsl:for-each select="dirs/dir[.!='']">
      <!--* messy way to find the number of / in the name of dir
          * - strip trailing / but then we add it back when calling the template
          *-->
      <xsl:variable name="dlen" select="string-length(.)"/>
      <xsl:variable name="dir" select="concat(substring(.,1,$dlen -1),translate(substring(.,$dlen),'/',''))"/>
      <xsl:variable name="ndepth" select="1 + $depth + string-length($dir) - string-length(translate($dir,'/',''))"/>

      <!--* call the template on each of the dirs *-->
      <xsl:apply-templates select="ancestor::section" mode="process">
	<xsl:with-param name="dir"   select="concat($dir,'/')"/>
	<xsl:with-param name="depth" select="$ndepth"/>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template> <!--* match=section mode=with-id *-->

  <!--* process each section that has an output page *-->
  <xsl:template match="section" mode="process">
    <xsl:param name="dir"   select="''"/>
    <xsl:param name="depth" select="1"/>

    <!--* create the page *-->
    <xsl:call-template name="write-navbar">
      <xsl:with-param name="filename" select="concat($install,$dir,'navbar_',@id,'.incl')"/>
      <xsl:with-param name="depth"    select="$depth"/>
    </xsl:call-template>

  </xsl:template> <!--* match=section mode=process *-->

  <!--*
      * Write the navbar. Context node should be the section node
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
      *   depth - integer, defaults to 1
      *     depth of current page
      *
      *-->
  <xsl:template name="write-navbar">
    <xsl:param name="filename" select="''"/>
    <xsl:param name="depth"    select="'1'"/>
    
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

      <!--* add disclaimer about editing this HTML file *-->
      <xsl:call-template name="add-disclaimer"/>
      <xsl:comment>htdig_noindex</xsl:comment><xsl:text>
</xsl:text>

      <!--* 
          * td element we are in has class="navbar"
          * (for netscape4 & backgrounds)
          *
          * htdig_noindex comment added to hide contents from
          * search index.
          *-->
      <div>
	
	<!--* add the logo/link if required *-->
	<xsl:choose>
	  <xsl:when test="$logoimage != '' and $logotext != ''">
	    <p align="center">
	      <xsl:call-template name="add-image">
		<xsl:with-param name="depth" select="$depth"/>
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
	    <!--* just add some white space *-->
	    <!--* <br/> *-->
	  </xsl:otherwise>
	</xsl:choose>

	<!--* create the various sections *-->
	<dl>
	  <xsl:apply-templates select="//section" mode="create">
	    <xsl:with-param name="depth"   select="$depth"/>
	    <xsl:with-param name="matchid" select="@id"/>
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
	    <xsl:apply-templates select="//links" mode="create">
	      <xsl:with-param name="depth"   select="$depth"/>
	    </xsl:apply-templates>
	  </xsl:when>
	</xsl:choose>

	<xsl:choose>
	  <xsl:when test="$site='ciao' and count(//news/item)!=0">
	    <!--* add the News table *-->
	    <xsl:apply-templates select="//news" mode="create">
	      <xsl:with-param name="depth"   select="$depth"/>
	    </xsl:apply-templates>
	  </xsl:when>

	  <xsl:when test="$site='sherpa' and count(//news/item)!=0">
	    <xsl:apply-templates select="//news" mode="create">
	      <xsl:with-param name="depth"   select="$depth"/>
	    </xsl:apply-templates>
	  </xsl:when>

	  <xsl:when test="$site='caldb' and count(//news/item)!=0">
	    <xsl:apply-templates select="//news" mode="create">
	      <xsl:with-param name="depth"   select="$depth"/>
	    </xsl:apply-templates>
	  </xsl:when>
	</xsl:choose>

      </div>

      <xsl:comment>/htdig_noindex</xsl:comment><xsl:text>
</xsl:text>

    </xsl:document> <!--* end of a navbar *-->

  </xsl:template> <!--* name=write-navbar *-->

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
      *   font size is controlled by CSS which doesn't work in netscape 4
      *   - or at least not how I've done it here. I don't want to add lots
      *   of font statements to the text so we leave it like this for now.
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
    <xsl:param name="depth" select="1"/>

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
		  <xsl:with-param name="depth" select="$depth"/>
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
    <xsl:apply-templates select="list" mode="navbar">
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
    <!--* <br clear="all"/> *-->

  </xsl:template> <!--* match=section mode="create" *-->

  <!--* 
      * create the news section
      * - having a mode of create may be important here in case there's a valid
      *   item attribute elsewhere
      *-->
  <xsl:template match="news" mode="create">
    <xsl:param name="depth" select="1"/>
    <hr/>

    <div>

      <div class="newsbar">
        <h2>News</h2>

	  <a href="{$newsfileurl}">Previous Items</a>
      </div>

      <!--* now do the individual items *-->
      <xsl:apply-templates select="item" mode="create">
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>

      <!--* and finish with the link to the "old news" section *-->
<!--*
      <p align="center">
	<a>
	  <xsl:call-template name="add-attribute">
	    <xsl:with-param name="depth" select="$depth"/>
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
    <xsl:param name="depth" select="1"/>

    <div>
      <p align="left">
	<strong><xsl:call-template name="calculate-date-from-attributes"/></strong>
	<xsl:text> </xsl:text> <!--* only really necessary if we follow with an image *-->
	<xsl:choose>
	  <xsl:when test="boolean(@type) = false()"/>
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
      </p>
      <xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
      <!--* since have a "old news" item at the end we always put in a hr *-->
      <hr width="80%" align="center"/>
    </div>
  </xsl:template> <!--* match=item mode=create *-->

  <!--* 
      * create the links section for Sherpa/ChaRT/iCXC pages
      * - have a mode of create to replicate "news" template for CIAO pages
      *-->
  <xsl:template match="links" mode="create">
    <xsl:param name="depth" select="1"/>

    <!--* add a separator *-->
    <hr/>

    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
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
    <xsl:param name="depth" select="1"/>
    <xsl:apply-templates mode="navbar">
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template> <!--* match=list mode=navbar *-->

  <xsl:template match="li" mode="navbar">
    <xsl:param name="depth" select="1"/>
    <dd>
      <xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </dd>
  </xsl:template> <!--* match=li mode=navbar *-->

  <!--*
      * This is needed by helper.xsl for some reason
      * that I am too lazy to track down
      *-->
  <xsl:template name="newline"><xsl:text>
</xsl:text></xsl:template>

</xsl:stylesheet>