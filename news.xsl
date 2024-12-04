<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the news page
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:str="http://exslt.org/strings"
  xmlns:date="http://exslt.org/dates-and-times"
  xmlns:func="http://exslt.org/functions"
  xmlns:exsl="http://exslt.org/common"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="date str func exsl extfuncs"> 

  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-news" select="extfuncs:register-import-dependency('news.xsl')"/>

  <xsl:output method="text"/>

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
      *   news.html
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
    <xsl:apply-templates select="news" mode="main"/>
    <xsl:apply-templates select="news" mode="feed"/>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: news.html
      *-->

  <xsl:template match="news" mode="main">

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$pagename"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
                  doctype-system="about:legacy-compat"
		  version="5.0">

      <!--* we start processing the XML file here *-->
      <html lang="en-US">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-standard"/>

	<xsl:call-template name="add-contents"/>

      </html>

    </xsl:document>
  </xsl:template> <!--* match=news *-->


  <xsl:template name="add-contents">

    <xsl:call-template name="add-body-withnavbar">
      <xsl:with-param name="contents">
	<h1 class="pagetitle">What's New for CIAO <xsl:value-of select="$siteversion"/></h1>

	<p class="feed"><a href="http://cxc.harvard.edu/ciao/feed.xml">Subscribe to the CIAO&#160;News RSS&#160;feed</a></p>

	<hr/>

	<xsl:apply-templates select="//text/item" mode="main"/>
      </xsl:with-param>

      <xsl:with-param name="navbar">
	<xsl:call-template name="add-navbar">
	  <xsl:with-param name="name" select="info/navbar"/>
	</xsl:call-template>
      </xsl:with-param>

    </xsl:call-template>

  </xsl:template>


  <xsl:template match="news" mode="feed">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>feed.xml</xsl:variable>

    <!--* create document *-->
    <xsl:document href="{$filename}"
		  method="xml" version="1.0" omit-xml-declaration="no">

      <!-- See
	https://github.com/genmon/aboutfeeds/blob/main/tools/pretty-feed-v3.xsl
        for styling info
	-->

      <xsl:processing-instruction name="xml-stylesheet">
	<!-- TODO: the href value could be configurable -->
	<xsl:text>href="pretty-feed-v3.xsl" type="text/xsl"</xsl:text>
      </xsl:processing-instruction>
      <xsl:call-template name="newline"/>

      <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/">
	<channel><xsl:call-template name="newline"/> 
	  <title>CIAO Software News</title><xsl:call-template name="newline"/>     
	  <link>http://cxc.harvard.edu/ciao/news.html</link><xsl:call-template name="newline"/>
	  <description>What's New in the CIAO Software</description><xsl:call-template name="newline"/> 

	  <atom:link xmlns:atom="http://www.w3.org/2005/Atom"  href="http://cxc.harvard.edu/ciao/feed.xml" rel="self" type="application/rss+xml" />

	  <xsl:apply-templates select="//text/item" mode="feed"/>
	</channel>	
      </rss>

    </xsl:document>
  </xsl:template> <!--* match=news *-->
	    

  <!--* note: we process the text so we can handle our `helper' tags *-->
  <xsl:template match="text">
   <xsl:apply-templates/>
  </xsl:template> <!--* text *-->

  <!-- news items template / HTML -->
  <xsl:template match="item" mode="main">

    <xsl:for-each select=".">

    <!-- create summary and id -->
    <article class="newsitem">
      <h3>
	<xsl:attribute name="id">
	  <xsl:text>item-</xsl:text>
	  <xsl:value-of select="pubdate"/>
	</xsl:attribute>
	<xsl:value-of select="title"/>
      </h3>
      <p class="newsdate"><xsl:call-template name="calculate-pubdate-html"/></p>

      <div>
      <xsl:apply-templates select="desc/*"/>
      </div>
    </article>
    </xsl:for-each> 
  </xsl:template> 
  <!-- end main bug content template -->

  <!-- news items template / feed -->
  <xsl:template match="item" mode="feed">
    <xsl:for-each select=".">
     
      <item>
	<title><xsl:value-of select="title"/></title>
	<pubDate><xsl:call-template name="calculate-pubdate-feed"/></pubDate>	
	
	<link><xsl:value-of select="$outurl"/><xsl:text>news.html#item-</xsl:text><xsl:value-of select="pubdate"/></link>
	<guid><xsl:value-of select="$outurl"/><xsl:text>news.html#item-</xsl:text><xsl:value-of select="pubdate"/></guid>

	<description>
          <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
          <xsl:apply-templates select="desc/*"/>
	  <xsl:text disable-output-escaping="yes">]]</xsl:text>
	  <xsl:text disable-output-escaping="yes">></xsl:text>
	</description>
      </item>
    </xsl:for-each> 
  </xsl:template> 
  <!-- end feed bug content template -->

  <xsl:template name="calculate-pubdate-html">    
    <xsl:variable name="daynum"  select="date:day-in-month(pubdate)"/>
    <xsl:variable name="month" select="substring(date:month-name(pubdate),1,3)"/>
    <xsl:variable name="year"  select="date:year(pubdate)"/>
      <xsl:if test="number($year)&lt;2010">
      <xsl:message terminate="yes">
  Error: year is set to '<xsl:value-of select="$year"/>'; 
         must be 2010 or later
      </xsl:message>
    </xsl:if>

    <time>
      <xsl:attribute name="datetime">
	<xsl:value-of select="pubdate"/>
      </xsl:attribute>
      <xsl:value-of select="concat($daynum,' ',$month,' ',$year)"/>
    </time>
  </xsl:template>

  <xsl:template name="calculate-pubdate-feed">
    <xsl:variable name="dayname" select="substring(date:day-name(pubdate),1,3)"/>
    <xsl:variable name="dayn"  select="date:day-in-month(pubdate)"/>
    <xsl:variable name="daynum"><xsl:choose>
	<xsl:when test="number($dayn)>9"><xsl:value-of select="$dayn"></xsl:value-of></xsl:when>
	<xsl:otherwise><xsl:value-of select="concat('0',$dayn)"></xsl:value-of></xsl:otherwise>
    </xsl:choose></xsl:variable>
    <xsl:variable name="month" select="substring(date:month-name(pubdate),1,3)"/>
    <xsl:variable name="year"  select="date:year(pubdate)"/>

    <xsl:value-of select="concat($dayname,', ',$daynum,' ',$month,' ',$year,' 00:00 EST')"/>
  </xsl:template>

</xsl:stylesheet>
