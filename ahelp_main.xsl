<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!-- AHELP XML to HTML convertor using XSL Transformations -->

<!--* 
    * Recent changes:
    *  2008 May 30 DJB Remove support for PDF generation
    *  2007 Oct 17 DJB 
    *    Try and handle TABLE's the same way that ahelp does; if all rows (but the first)
    *    of a column are empty then do not display that column.
    *    Removed support for type=dist
    *
    * These are the routines that actually transfrom the ahelp document
    * - broken out of ahelp.xsl to make it easier to test
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:str="http://exslt.org/strings"
  xmlns:date="http://exslt.org/dates-and-times"
  xmlns:func="http://exslt.org/functions"
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="date str func exsl">

  <!--* load in templates *-->
  <xsl:include href="ahelp_common.xsl"/>

  <!--* parameters to be set by stylesheet processor *-->
  <xsl:param name="headtitlepostfix"  select='""'/>
  <xsl:param name="texttitlepostfix"  select='""'/>

  <!--* 
      * create: $outname.html
      * We now no-longer need to use the xsl:document trick
      * as we only create a single file now, but leave that
      * change for later as it requires re-jigging the entire
      * publishing setup, not just this stylesheet.
      *-->
  <xsl:template match="cxchelptopics">

    <xsl:variable name="filename"><xsl:value-of select="$outdir"/><xsl:value-of select="$outname"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">
      
      <html lang="en">
	<head>
	  <title>Ahelp: <xsl:value-of select="ENTRY/@key"/> - <xsl:value-of select="$headtitlepostfix"/></title>

	  <!--* use CSS for the navbar *-->
	  <link rel="stylesheet" title="Default stylesheet for CIAO-related pages" href="{$cssfile}"/>
	  <link rel="stylesheet" title="Default stylesheet for CIAO-related pages" media="print" href="{$cssprintfile}"/>

<style type="text/css">
/* highlight only the link to this page in the navbar */
.navbar a[href='<xsl:value-of select="$outname"/>.html'] {
  background: #CCCCCC;
}
</style>

	</head>

	<!--* add header and banner *-->
	<xsl:call-template name="add-cxc-header"/>
	<xsl:call-template name="add-standard-banner-header">
	  <xsl:with-param name="lastmod"  select="//LASTMODIFIED"/>
	</xsl:call-template>

	<table class="maintable" width="100%" border="0" cellspacing="2" cellpadding="2">
	  <tr>
	    <xsl:call-template name="add-navbar">
	      <xsl:with-param name="navbar" select="'ahelp_index'"/>
	    </xsl:call-template>

	    <!--* the main text *-->
	    <td class="mainbar" valign="top">

	      <!--* anchor for "skip navigation bar" link *-->
	      <a name="maintext"/>

	      <!--* parse the text *--> 
	      <xsl:apply-templates select="ENTRY"/>
	    </td>
	  </tr>
	</table>
	
	<!--* add the banner *-->
	<xsl:call-template name="add-standard-banner-footer">
	  <xsl:with-param name="lastmod"  select="//LASTMODIFIED"/>
	</xsl:call-template>
	<xsl:call-template name="add-cxc-footer"/>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=cxchelptopics *-->

  <!--* begin DTD templates *-->

  <!--*
      * we use a pull-style approach here
      * 
      * DTD Entry:
      *   <!ELEMENT ENTRY (SYNOPSIS?, SYNTAX?, ADDRESS*, DESC?,
      *                    QEXAMPLELIST?, PARAMLIST?, ADESC*,BUGS?,
      *                    VERSION?, LASTMODIFIED? )>
      *
      * If PARAMLIST is included and no initial SYNTAX block then
      * we generate the syntax line automatically
      * 
      *-->
  <xsl:template match="ENTRY">

    <xsl:call-template name="add-ahelp-qlinks"/>
    <xsl:call-template name="add-page-header"/>
    <br/>

    <xsl:apply-templates select="SYNOPSIS"/>

    <!--*
        * SYNTAX handling is a bit complicated in CIAO 3.0
        *-->
    <xsl:call-template name="handle-entry-syntax"/>

    <xsl:apply-templates select="DESC"/>
    <xsl:apply-templates select="QEXAMPLELIST"/>
    <xsl:apply-templates select="PARAMLIST"/>
    <xsl:apply-templates select="ADESC"/>
    <xsl:apply-templates select="BUGS"/>
    <xsl:call-template   name="add-seealso"/>

  </xsl:template>  <!--* match=ENTRY *-->

  <!--*
      * output another page "header"
      *
      *-->
  <xsl:template name="add-page-header">

    <table class="ahelpheader" width="100%">
      <tr>
	<td align="left" width="30%"><strong>AHELP for <xsl:value-of select="$headtitlepostfix"/></strong></td>
	<td align="center" width="40%"><font size="+1">
	    <strong><xsl:value-of select="@key"/></strong></font></td>
	<td align="right" width="30%">Context: 
	  <a title="Jump to context list of Ahelp pages" href="{$depth}index_context.html#{@context}"><xsl:value-of select="@context"/></a></td>
      </tr>
    </table>

  </xsl:template> <!--* name=add-page-header *-->

  <!--*
      * DTD Entry:
      *   <!ELEMENT SYNOPSIS     (#PCDATA)>
      *
      * Note:
      *  . if parent = ENTRY then this is at the top of the page
      *    so we don't really need an anchor, but let's include one
      *    anyway
      *
      *  . if parent = PARAM then just wrap in an em block
      *
      *-->
  <xsl:template match="ENTRY/SYNOPSIS">
    <div class="ahelpsynopsis">
      <h2><a name="synopsis">Synopsis</a></h2>
      <p>
	<xsl:apply-templates/>
      </p>
    </div>
  </xsl:template> <!--* match=ENTRY/SYNOPSIS *-->

  <xsl:template match="PARAM/SYNOPSIS" mode="plist">
    <p class="ahelpsynopsis">
      <em><xsl:apply-templates/></em>
    </p>
  </xsl:template> <!--* match=PARAM/SYNOPSIS *-->

  <xsl:template match="PARAM/SYNOPSIS">
    <xsl:message terminate="yes">
  Programming error:
    For some reason the stylesheet is trying to process the
    PARAM/SYNOPSIS node directly (not in mode=plist)
    </xsl:message>
  </xsl:template>

  <!--*
      * handle the SYNTAX block at the start of the file
      * - in CIAO 3.0 we complicated things by allowing
      *   the SYNTAX block to be automatically created
      *   from the PARAMLIST section if it wasn't present.
      * WE SHOULD HAVE USED AN ATTRIBUTE ON THE SYNTAX BLOCK TO
      * INDICATE THIS
      *-->
  <xsl:template name="handle-entry-syntax">
    <xsl:choose>
      <xsl:when test="boolean(SYNTAX)">
	<xsl:apply-templates select="SYNTAX"/>
      </xsl:when>
      <xsl:when test="$nparam != 0">
	<xsl:call-template name="create-entry-syntax"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template> <!--* name=handle-entry-syntax *-->

  <!--*
      * DTD Entry:
      *   <!ELEMENT SYNTAX       (LINE*)>
      *
      * We ignore any SYNTAX block which contains 1 empty LINE
      *
      * We handle separately the case of auto-creation of the ENTRY/SYNTAX block
      * from the PARAMLIST - see the create-entry-syntax template
      *
      * Since a SYNTAX block can be within a PARA block we need to
      * handle this awkward case (by hacking in start/end para tags).
      * To try and avoid artifacts we have a in-para parameter which
      * - if set to 1 by the PARA template - causes us to end/start the
      *   p block
      *
      *-->
  <xsl:template match="SYNTAX">
    <xsl:param name="in-para" select="0"/>

    <xsl:if test="
      not( count(LINE)=1 and normalize-space(LINE[1])='' )
      ">

      <xsl:if test="$in-para = 1">
	<!--* UGLY - must be cleaner ways around this *-->
	<xsl:call-template name="end-para"/>
      </xsl:if>

      <div class="ahelpsyntax">

	<xsl:if test="parent::ENTRY">
	  <h2><a name="syntax">Syntax</a></h2>
	</xsl:if>

	<xsl:call-template name="add-highlight">
	  <xsl:with-param name="contents"><xsl:apply-templates/></xsl:with-param>
	</xsl:call-template>

      </div> <!--* class=ahelpsyntax *-->

      <xsl:if test="$in-para = 1">
	<!--* UGLY - must be cleaner ways around this *-->
	<xsl:call-template name="start-para"/>
      </xsl:if>

    </xsl:if>
  </xsl:template> <!--* match=SYNTAX *-->

  <!--*
      * DTD Entry:
      *   <!ELEMENT LINE         (#PCDATA | HREF)* >
      *
      * Processing this node is complicated since we have to 
      * strip out whitespace and split the line every $maxlen
      * characters (set by XSLT processor)
      *
      * *** NOTE: ***
      *
      *  we currently don't handle HREF nodes within LINE ones
      *  - since it makes the normalising rather painful
      *  - but we do throw a wobbly if it occurs
      *
      *  - we ignore the node if it is empty AND:
      *    - the first one
      *    - the last one
      *
      *-->
  <xsl:template match="LINE">

    <!--* we don't handle HREF children since it complicates things *-->
    <xsl:if test="count(HREF) != 0">
      <xsl:message terminate="no">
  Warning: have come across at least one HREF node (first has text =
   '<xsl:value-of select="HREF[1]"/>')
  within a LINE node in document key=<xsl:value-of select="/cxchelptopics/ENTRY/@key"/> context=<xsl:value-of select="/cxchelptopics/ENTRY/@context"/>

  Output WILL BE WRONG
      </xsl:message>
    </xsl:if>

    <xsl:variable name="text" select="normalize-space(.)"/>
    <xsl:if test="
      not( $text='' and ( position()=1 or position()=last() ) ) 
      "><xsl:call-template name="normalize-line-node">
  <xsl:with-param name="text" select="$text"/>
</xsl:call-template></xsl:if>
  </xsl:template> <!--* match=LINE *-->

  <!--*
      * return - as one line - the command-line generated from the PARAMLIST section
      * - could try and make this clever enough to work within maxlen chars and
      *   to add indentation
      *
      * Note: in the move to libxml2.6.x from 2.5.x, this routine broke because
      * missing attributes no longer default to a value of ''. This means that
      * the check @reqd != 'yes' does not succeed if reqd is not present.
      *
      *-->
  <xsl:template name="create-syntax-from-paramlist">
    <xsl:value-of select="//ENTRY/@key"/><xsl:text>  </xsl:text>
    <xsl:for-each select="PARAMLIST/PARAM">
      <xsl:if test="position() != 1"><xsl:text> </xsl:text></xsl:if>
      <xsl:choose>
	<xsl:when test="@reqd = 'yes'"><xsl:value-of select="@name"/></xsl:when>
	<xsl:otherwise>[<xsl:value-of select="@name"/>]</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template> <!--* name=create-syntax-from-paramlist *-->

  <!--*
      * We need to create the SYNTAX section from the PARAMLIST section
      * Note: we don't match ahelp's format (which is better)
      *       of indenting lines after the first one
      *-->
  <xsl:template name="create-entry-syntax">

    <div class="ahelpsyntax">
      <h2><a name="syntax">Syntax</a></h2>

      <xsl:call-template name="add-highlight">
	<xsl:with-param name="contents"><xsl:call-template name="normalize-line-node">
	    <xsl:with-param name="text"><xsl:call-template name="create-syntax-from-paramlist"/></xsl:with-param>
	  </xsl:call-template></xsl:with-param>
      </xsl:call-template>

    </div> <!--* class=ahelpsyntax *-->
  </xsl:template> <!--* name=create-entry-syntax *-->

  <!--*
      * Given a piece of string, output the first $maxlen characters
      * (or as near as we can make it) without breaking a word
      * - breaks within strings are allowed.
      *
      * A recursive template
      *
      * Parameters:
      *  text - string, required
      *    the string to split up
      *  currpos - integer
      *    the current position in the string (defaults to 1)
      *  lastpos - integer
      *    the position of the last space (defaults to 0)
      *
      *  nlines - integer
      *    number of lines created - should only be set by itself
      *    [used to determine whether to output a new line before the string]
      *    defaults to 1
      *-->
  <xsl:template name="normalize-line-node">
    <xsl:param name="text"    select="''"/>
    <xsl:param name="currpos" select="1"/>
    <xsl:param name="lastpos" select="0"/>
    <xsl:param name="nlines"  select="1"/>

    <xsl:variable name="slen" select="string-length($text)"/>
    <xsl:choose>
      <!--*
          * stop if there's nothing left: may get a range error on substring calling this case!
          * - actually, if nlines = 1 then we have a blank input line, which we want to
          *   allow [start/end blank lines have been filtered by the SYNTAX templates
          *-->
      <xsl:when test="$slen = 0">
	<xsl:if test="$nlines = 1"><xsl:text>
</xsl:text></xsl:if>
      </xsl:when>

      <!--*
          * if currpos >= length of string we can stop
          * (do we need the new-line before it?, we seem to)
          *-->
      <xsl:when test="$currpos >= $slen">
<xsl:text>
</xsl:text><xsl:value-of select="$text"/>
</xsl:when>
      
      <!--*
          * if we've encountered a space, use up to that, otherwise use
          * the first $maxlen characters. We repeat again.
          *
          * Note that, to stop the pre blocks extending over too wide an
          * area (at least in konqueror) we do not want to end the line on
          * a space. So, that's why we have 2 slightly different
          * bits of code. And then add a third to account for the case
          * when the $maxlen character is the first space...
          *
          *-->
      <xsl:when test="$currpos = $maxlen">

	<xsl:choose>
	  <xsl:when test="substring($text,$maxlen,1) = ' '">
	    <!--* the $maxlen character is actually a space *-->
<xsl:text>
</xsl:text><xsl:value-of select="substring($text,1,$maxlen - 1)"/>

	    <xsl:call-template name="normalize-line-node">
	      <xsl:with-param name="text"   select="substring($text,$maxlen + 1)"/>
	      <xsl:with-param name="nlines" select="$nlines + 1"/>
	    </xsl:call-template>
	  </xsl:when>
	    
	  <xsl:when test="$lastpos = 0">
	    <!--* there is no space, so use the first $maxlen characters *-->
<xsl:text>
</xsl:text><xsl:value-of select="substring($text,1,$maxlen)"/>

	    <xsl:call-template name="normalize-line-node">
	      <xsl:with-param name="text"   select="substring($text,$maxlen + 1)"/>
	      <xsl:with-param name="nlines" select="$nlines + 1"/>
	    </xsl:call-template>
	  </xsl:when>

	  <xsl:otherwise>
	    <!--* use the position of the last space *-->
<xsl:text>
</xsl:text><xsl:value-of select="substring($text,1,$lastpos - 1)"/>

	    <xsl:call-template name="normalize-line-node">
	      <xsl:with-param name="text"   select="substring($text,$lastpos + 1)"/>
	      <xsl:with-param name="nlines" select="$nlines + 1"/>
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>

      </xsl:when>

      <xsl:when test="substring($text,$currpos,1) = ' '">
	<!--* found a space, so update and repeat the recursion *-->
	<xsl:call-template name="normalize-line-node">
	  <xsl:with-param name="text"    select="$text"/>
	  <xsl:with-param name="lastpos" select="$currpos"/>
	  <xsl:with-param name="currpos" select="$currpos + 1"/>
	  <xsl:with-param name="nlines"  select="$nlines"/>
	</xsl:call-template>
      </xsl:when>
      
      <xsl:otherwise>
	<!--*
	    * no space, update and repeat the recursion
	    * - different from the space case above (lastpos is not
            *   updated in this case)
	    *-->
	<xsl:call-template name="normalize-line-node">
	  <xsl:with-param name="text"    select="$text"/>
	  <xsl:with-param name="lastpos" select="$lastpos"/>
	  <xsl:with-param name="currpos" select="$currpos + 1"/>
	  <xsl:with-param name="nlines"  select="$nlines"/>
	</xsl:call-template>
      </xsl:otherwise>
	
    </xsl:choose>
  </xsl:template> <!--* name=normalize-line-node *-->

  <!--*
      * DTD Entry:
      *   <!ELEMENT HREF         (#PCDATA)>
      *   <!ATTLIST HREF
      *           link            NMTOKENS        #IMPLIED
      *   >
      *
      * perhaps we need to rationalise the stylesheet...
      *
      * We hack the URL and text to convert asc.harvard.edu to cxc.harvard.edu
      *
      *-->
  <!--* HREF block in a PARA element *--> 
  <xsl:template match="HREF">

    <!--* ugh: replace should be done as a function... *-->
    <a><xsl:attribute name="href"><xsl:call-template name="hack-href">
	<xsl:with-param name="input" select="@link"/>
      </xsl:call-template></xsl:attribute><xsl:call-template name="hack-href">
	<xsl:with-param name="input" select="normalize-space(string(.))"/>
      </xsl:call-template></a>

  </xsl:template>

  <!--* 
      * hack a href (or the link contents) to change to the 'new' scheme:
      *   asc.harvard.edu         -> cxc.harvard.edu
      *   documents_ahelp.html    -> ahelp/
      *   documents_threads.html  -> threads/
      *   documents_manuals.html  -> manuals.html
      *
      *   advanced_documents.html -> manuals.html
      *   http://hea-www.harvard.edu/APEC/ -> http://cxc.harvard.edu/atomdb/
      *
      * should be done as a function rather than a template
      *-->
  <xsl:template name="hack-href">
    <xsl:param name="input" select="''"/>

    <xsl:value-of select="
      str:replace( 
        str:replace( 
          str:replace( 
            str:replace( 
              str:replace( 
                str:replace( $input, 'asc.harvard.edu', 'cxc.harvard.edu' ),
              'http://hea-www.harvard.edu/APEC/', 'http://cxc.harvard.edu/atomdb/' ),
            'documents_ahelp.html', 'ahelp/' ),
          'documents_threads.html', 'threads/' ),
        'documents_manuals.html', 'manuals.html' ),
      'advanced_documents.html', 'manuals.html' )
      "/>
  </xsl:template> <!--* name=hack-href *-->

  <!--*
      * DTD Entry:
      *   <!ELEMENT DESC         ((PARA | TABLE | LIST | VERBATIM)*)>
      *
      * DESC can be a child of ENTRY, PARAM, QEXAMPLE
      *
      *-->
  <xsl:template match="ENTRY/DESC">
    <div class="ahelpdesc">
      <h2><a name="description">Description</a></h2>

      <xsl:apply-templates/>
    </div>
  </xsl:template> <!-- match=ENTRY/DESC -->

  <xsl:template match="QEXAMPLE/DESC">
    <div class="ahelpdesc">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!--* don't do anything unless we're in a special mode *-->
  <xsl:template match="PARAM/DESC"/>

  <xsl:template match="PARAM/DESC" mode="plist">
    <div class="ahelpdesc">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!--*
      * DTD Entry:
      *   <!ELEMENT PARA         (#PCDATA | SYNTAX | EQUATION | PASSTHRU
      *   | XMLONLY | HREF)*>
      *   <!ATTLIST PARA
      *           title           NMTOKENS        #IMPLIED
      *   >
      * 
      * - add an anchor equal to the anchor (with spaces turned 
      *   into underscores)
      *
      * We trap the cases of a PARA block containing only a single
      * SYNTAX or EQUATION block [should try and catch multiple
      * copies as well]
      *
      * The in-para parameters are only of interest to the SYNTAX
      * and EQUATION templates
      *-->
  <xsl:template match="PARA">
    
    <xsl:choose>
      <xsl:when test="count(node()) = 1 and ( name(node()) = 'SYNTAX' or name(node()) = 'EQUATION' )">
	<xsl:apply-templates>
	  <xsl:with-param name="in-para" select="0"/>
	</xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
	<!--* normal processing *-->
	<xsl:if test="boolean(@title)">
	  <xsl:call-template name="add-title-anchor">
	    <xsl:with-param name="title" select="@title"/>
	  </xsl:call-template>
	</xsl:if>
	<p>
	  <xsl:apply-templates>
	    <xsl:with-param name="in-para" select="1"/>
	  </xsl:apply-templates>
	</p>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* match=PARA *-->

  <!--*
      * DTD Entry:
      *   <!ELEMENT EQUATION     (#PCDATA | PASSTHRU|XMLONLY)*>
      *
      * This can only appear within PARA blocks, which means we have
      * to jump through a few hoops
      *
      * I also want consecutive EQUATION blocks to look nice (ie combine
      * them), which really complicate things. In fact, I am not convinced
      * it is possible. I was hoping to use the preceding-sibling/following-sibling
      * axes to see when the set of EQUATION commands starts and ends, but
      * it appears that the text nodes in between are not included in this list
      * This means I do not know how to reliably determine the start/end
      * point of the sets (in particular if there are multiple EQUATION
      * blocks, separated by text, within a single PARA block)
      *
      *-->
  <xsl:template match="EQUATION">
    <xsl:param name="in-para" select="0"/>

    <xsl:if test="$in-para = 1">
      <xsl:call-template name="end-para"/>
    </xsl:if>

    <div class="ahelpequation">
      <xsl:call-template name="add-highlight">
	<xsl:with-param name="contents" select="normalize-space(.)"/>
      </xsl:call-template>
    </div>

    <xsl:if test="$in-para = 1">
      <xsl:call-template name="start-para"/>
    </xsl:if>
  </xsl:template> <!--* match=EQUATION *-->

  <!--*
      * DTD Entry:
      *   <!ELEMENT XMLONLY      (#PCDATA)>
      * 
      * we process the XMLONLY block since this is for
      * XML text!
      * 
      *-->
  <xsl:template match="XMLONLY">

    <!--* just to flag any instances *-->
    <xsl:message terminate="no">
 Note: have encountered an XMLONLY block
    </xsl:message>

    <xsl:value-of select="."/>
  </xsl:template>

  <!--*
      * DTD Entry:
      *   <!ELEMENT PASSTHRU     (#PCDATA) >
      * 
      * we skip the PASSTHRU block since this is for LaTeX-only
      * text
      * 
      *-->
  <xsl:template match="PASSTHRU"/>

  <!--*
      * DTD Entry:
      *   <!ELEMENT TABLE        ( CAPTION?, ROW*)>
      *
      * For CIAO 3.0 changed to have a border of 1 - previously had border = 0
      *   and added frame="void". Should be done by CSS.
      *
      * Note: the 'hidden' rule is that the first row of the
      * table is taken to be a header row, even there is no
      * mark up to suggest  this (and it is not always required)
      * We follow this 'rule' here.
      * Also, if all rows of a column EXCEPT the first are empty
      * then we do not display that column.
      *-->
  <xsl:template match="TABLE">

    <!-- true if the column contains data after the first row, false otherwise -->
    <xsl:variable name="colflags">
      <xsl:for-each select="ROW[1]/DATA">
	<xsl:variable name="pos" select="position()"/>
	<flag><xsl:value-of select="count(../../ROW[position()!=1]/DATA[position()=$pos and . != ''])!=0"/></flag>
      </xsl:for-each>
    </xsl:variable>

    <!--*
        * There is the possibility of an empty table, but more likely one
	* with only one row, which we would then consider as empty.
	*-->
    <xsl:if test="count(exsl:node-set($colflags)/flag[.='true']) = 0">
      <xsl:message terminate="yes">
 Found a TABLE that is either empty or only contains 1 row!
      </xsl:message>
    </xsl:if>

    <xsl:apply-templates select="CAPTION"/>
    <table border="1" frame="void">
      <xsl:apply-templates select="ROW">
	<xsl:with-param name="colflags" select="exsl:node-set($colflags)"/>
      </xsl:apply-templates>
    </table>

  </xsl:template>

  <!--*
      * DTD Entry:
      *   <!ELEMENT CAPTION      (#PCDATA)>
      *
      * The size of the caption depends on wheter this is within a
      * PARAM block or not (h5 if it is, h4 otherwise)
      *
      *-->
  <xsl:template match="CAPTION">
    <xsl:variable name="type"><xsl:choose>
	<xsl:when test="ancestor::PARAM">h5</xsl:when>
	<xsl:otherwise>h4</xsl:otherwise>
      </xsl:choose></xsl:variable>
    <xsl:element name="{$type}"><xsl:apply-templates/></xsl:element>
  </xsl:template>

  <!--*
      * DTD Entry:
      *   <!ELEMENT ROW          (DATA*)>
      *
      * If this is the first row then we make it a header row
      * through some chicanery. We also use a pull approach so that
      * we can select which columns to process, given the
      * colflags input (a set of <flag>true/false</flag> values,
      * one for each column in the header). Note that there could be more or less
      * columns than in the header, which we warn about.
      *
      * I am sure there are far-more elegant methods than the this.
      *-->
  <xsl:template match="ROW">
    <xsl:param name="colflags"/>
    <xsl:variable name="expected_ncols" select="count($colflags/flag)"/>
    <xsl:variable name="found_ncols" select="count(DATA)"/>

    <!--* only warn once per file *-->
    <xsl:if test="$found_ncols != $expected_ncols">
      <xsl:message>
	<xsl:value-of select="concat('WARNING: ROW contains ',$found_ncols,
	  ' DATA elements but expected to find ',$expected_ncols,' of them ',
	  '(key=',//ENTRY/@key,' context=',//ENTRY/@context,' table caption=',../CAPTION,')')"/>
      </xsl:message>
    </xsl:if>

    <tr>
      <xsl:choose>
	<xsl:when test="position() = 1">
	  <xsl:attribute name="class">headerrow</xsl:attribute>
	  <xsl:for-each select="DATA">
	    <xsl:variable name="pos" select="position()"/>
	    <xsl:if test="$colflags/flag[$pos]='true'">
	      <xsl:apply-templates mode="headerrow" select="."/>
	    </xsl:if>
	  </xsl:for-each>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:for-each select="DATA">
	    <xsl:variable name="pos" select="position()"/>
	    <xsl:if test="$colflags/flag[$pos]='true'">
	      <xsl:apply-templates select="."/>
	    </xsl:if>
	  </xsl:for-each>
	</xsl:otherwise>
      </xsl:choose>
    </tr>
  </xsl:template>

  <!--*
      * DTD Entry:
      *   <!ELEMENT DATA         (#PCDATA)>
      *
      *  since we do not have borders around these tables we 
      *  do not have to ensure that empty cells contain some 
      *  printable text (ie &nbsp; == unicode &#160;) unlike 
      *  the parameter tables 
      * 
      * There really should be something in the mark-up to
      * indicate a header element rather than this hack
      *-->
  <xsl:template match="DATA">
    <td><xsl:apply-templates/></td>
  </xsl:template>

  <xsl:template match="DATA" mode="headerrow">
    <th><xsl:apply-templates/></th>
  </xsl:template>

  <!--*
      * DTD Entry:
      *   <!ELEMENT LIST         ( CAPTION?, ITEM* )>
      *
      *-->
  <xsl:template match="LIST">
    <xsl:apply-templates select="CAPTION"/> 
    <ul>
      <xsl:apply-templates select="ITEM"/> 
    </ul>
    <br/> <!--* TODO need to be clever with this br *-->
  </xsl:template>

  <!--*
      * DTD Entry:
      *   <!ELEMENT ITEM         (#PCDATA)>
      *
      * should we add <p>/</p> around the contents?
      *-->
  <xsl:template match="ITEM">
    <li><xsl:apply-templates/></li>
  </xsl:template>

  <!--*
      * DTD Entry:
      *   <!ELEMENT VERBATIM     (#PCDATA)>
      *
      * Unlike EQUATION this can not appear within a PARA
      *-->
  <xsl:template match="VERBATIM">
    <div class="ahelpverbatim">
      <xsl:call-template name="add-highlight">
	<xsl:with-param name="contents"><xsl:apply-templates/></xsl:with-param>
      </xsl:call-template>
    </div>
  </xsl:template>

  <!--*
      * process the examples section
      *
      * DTD Entry:
      *   <!ELEMENT QEXAMPLELIST (QEXAMPLE)*>
      *   <!ELEMENT QEXAMPLE     (SYNTAX?, DESC?)>
      *
      * as with PARAMLIST we do not complain about an empty list
      *-->
  <xsl:template match="QEXAMPLELIST">

    <!--* we number each example *-->
    <xsl:for-each select="QEXAMPLE">

      <div class="ahelpexample">
	<!--* add anchor *-->
	<!--* if the first example, we have to add an "examples" anchor too *-->
	<xsl:if test="position()=1"><a name="examples"/></xsl:if>

	<!--* anchor rules are slightly different to add-title-anchor template *-->
	<h2><xsl:choose>
	  <xsl:when test="$nexample=1">
	    <a name="example1">Example</a>
	  </xsl:when>
	  <xsl:otherwise>
	    <a name="example{position()}">Example <xsl:value-of select="position()"/></a>
	  </xsl:otherwise>
	</xsl:choose></h2>

	<xsl:apply-templates select="SYNTAX"/>
	<xsl:apply-templates select="DESC"/>

      </div> <!--* class=ahelpexample *-->
    </xsl:for-each>

  </xsl:template> <!--* QEXAMPLELIST *-->

  <!--*
      * process the parameters section
      *
      * DTD Entry:
      *   <!ELEMENT PARAMLIST    (PARAM*)>
      *   <!ELEMENT PARAM        ( SYNOPSIS?, DESC? )>
      *
      * Processing is complicated:
      *  create the table of parameters
      *  then the individual list of parameters
      *
      * note: makes use of the 'global' have-XXX variables defined above
      *
      *-->
  <xsl:template match="PARAMLIST">

    <!--* if the paramlist is empty then let it be empty *-->
    <div class="ahelpparameters">
      <h2><a name="ptable">Parameters</a></h2>

      <table class="ahelpparamlist" border="1" cellspacing="1" cellpadding="2">
	<tr class="headerrow">
	  <th>name</th> <th>type</th> 
	  <xsl:if test="$have-ftype"><th>ftype</th></xsl:if>
	  <xsl:if test="$have-def"><th>def</th></xsl:if>
	  <xsl:if test="$have-min"><th>min</th></xsl:if>
	  <xsl:if test="$have-max"><th>max</th></xsl:if>
	  <xsl:if test="$have-units"><th>units</th></xsl:if>
	  <xsl:if test="$have-reqd"><th>reqd</th></xsl:if>
	  <xsl:if test="$have-stcks"><th>stacks</th></xsl:if>
	  <xsl:if test="$have-aname"><th>autoname</th></xsl:if>
	</tr>
	<xsl:apply-templates select="PARAM" mode="ptable"/>
      </table>
      <br/>
      
      <h2><a name="plist">Detailed Parameter Descriptions</a></h2>
    
      <xsl:apply-templates select="PARAM" mode="plist"/>

    </div> <!--* class=ahelpparameters *-->

  </xsl:template> <!--* PARAMLIST *-->

  <!--*
      * list the parameters as a table
      * we add in an &nbsp; to ensure that empty cells
      * end up with some content, and so will be
      * displayed by netscape.
      *
      * for almost all columns we only output data if the corresponding
      * $have-<name> variable is true
      *-->
  <xsl:template match="PARAM" mode="ptable">
    <tr>

      <!--* add a class attribute odd/even *-->
      <xsl:attribute name="class"><xsl:choose>
	  <xsl:when test="position() mod 2 = 1">oddrow</xsl:when>
	  <xsl:otherwise>evenrow</xsl:otherwise>
	</xsl:choose></xsl:attribute>

      <!--* name - always included *-->
      <td><a title="Jump to parameter description" href="#plist.{@name}"><xsl:value-of select="@name"/></a></td>
      <!--* type - always included *-->
      <xsl:call-template name="add-param-to-table"><xsl:with-param name="value" select="@type"/></xsl:call-template>
      <!--* ftype *-->
      <xsl:if test="$have-ftype"><xsl:call-template name="add-param-to-table"><xsl:with-param name="value" select="@filetype"/></xsl:call-template></xsl:if>
      <!--* def *-->
      <xsl:if test="$have-def"><xsl:call-template name="add-param-to-table"><xsl:with-param name="value" select="@def"/></xsl:call-template></xsl:if>
      <!--* min *-->
      <xsl:if test="$have-min"><xsl:call-template name="add-param-to-table"><xsl:with-param name="value" select="@min"/></xsl:call-template></xsl:if>
      <!--* max *-->
      <xsl:if test="$have-max"><xsl:call-template name="add-param-to-table"><xsl:with-param name="value" select="@max"/></xsl:call-template></xsl:if>
      <!--* units *-->
      <xsl:if test="$have-units"><xsl:call-template name="add-param-to-table"><xsl:with-param name="value" select="@units"/></xsl:call-template></xsl:if>
      <!--* reqd *-->
      <xsl:if test="$have-reqd"><xsl:call-template name="add-param-to-table"><xsl:with-param name="value" select="@reqd"/></xsl:call-template></xsl:if>
      <!--* stacks *-->
      <xsl:if test="$have-stcks"><xsl:call-template name="add-param-to-table"><xsl:with-param name="value" select="@stacks"/></xsl:call-template></xsl:if>
      <!--* autoname *-->
      <xsl:if test="$have-aname"><xsl:call-template name="add-param-to-table"><xsl:with-param name="value" select="@autoname"/></xsl:call-template></xsl:if>
    </tr>
  </xsl:template> <!--* match=PARAM mode=ptable *-->

  <!--*
      * Parameters:
      *   value - string
      *
      * Value of the string to display in the table. Outputs
      * &nbsp; if $value is empty/undefined
      *-->
  <xsl:template name="add-param-to-table">
    <xsl:param name="value" select="''"/>

    <td>
      <xsl:choose>
	<xsl:when test="not($value) or $value = ''"><xsl:call-template name="add-nbsp"/></xsl:when>
	<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
      </xsl:choose>
    </td>

  </xsl:template> <!--* name=add-param-to-table *-->
  
  <!--* show the parameters in a list *-->
  <xsl:template match="PARAM" mode="plist">

    <div class="ahelpparam">
      <!--* follow the parameter name with a list of attributes *-->
      <h4><a name="plist.{@name}">Parameter=<xsl:value-of select="@name"/></a>
	<tt><xsl:text> (</xsl:text><xsl:value-of select="@type"/>
	  <xsl:if test="boolean(@reqd)"><xsl:text> </xsl:text><xsl:choose>
	      <xsl:when test="@reqd='yes'">required</xsl:when>
	      <xsl:when test="@reqd='no'">not required</xsl:when>
	    </xsl:choose></xsl:if>
	  <xsl:if test="boolean(@filetype)"><xsl:text> </xsl:text>filetype=<xsl:value-of select="@filetype"/></xsl:if>
	  <xsl:if test="boolean(@def)"><xsl:text> </xsl:text>default=<xsl:value-of select="@def"/></xsl:if>
	  <xsl:if test="boolean(@min)"><xsl:text> </xsl:text>min=<xsl:value-of select="@min"/></xsl:if>
	  <xsl:if test="boolean(@max)"><xsl:text> </xsl:text>max=<xsl:value-of select="@max"/></xsl:if>
	  <xsl:if test="boolean(@units)"><xsl:text> </xsl:text>units=<xsl:value-of select="@units"/></xsl:if>
	  <xsl:if test="boolean(@stacks)"><xsl:text> </xsl:text>stacks=<xsl:value-of select="@stacks"/></xsl:if>
	  <xsl:if test="boolean(@autoname)"><xsl:text> </xsl:text>autoname=<xsl:value-of select="@autoname"/></xsl:if>
	  <xsl:text>)</xsl:text></tt></h4>

      <!--* perhaps we shouldn't do a select here - ie just process everything? *-->
      <xsl:apply-templates select="SYNOPSIS|DESC" mode="plist"/>
      <!--* <br/> *-->

    </div> <!--* class=ahelpparam *-->

  </xsl:template> <!--* PARAM mode=plist *-->

  <!--*
      * DTD Entry:
      *   <!ELEMENT ADESC        (PARA|TABLE|LIST|VERBATIM)*>
      *   <!ATTLIST ADESC
      *           title           NMTOKENS        #IMPLIED
      *   >
      *
      *-->
  <xsl:template match="ADESC">
    <div class="ahelpadesc">
      <xsl:if test="boolean(@title)">
	<xsl:call-template name="add-title-anchor">
	  <xsl:with-param name="title" select="@title"/>
	</xsl:call-template>
      </xsl:if>

      <xsl:apply-templates/>
    </div>
  </xsl:template> <!--* match=ADESC *-->

  <!--*
      * DTD Entry:
      *   <!ELEMENT BUGS         ( #PCDATA |PARA | TABLE | LIST | VERBATIM)*>
      * 
      * NOTE:
      *   Prior to CIAO 3.0 the BUGS section used to accept #PCDATA only.
      *   We used to have a hard-coded value for the bugs section but
      *   we no longer support this
      *
      *-->
  <xsl:template match="BUGS">

    <div class="ahelpbugs">
      <h2><a name="bugs">Bugs</a></h2>
      <xsl:apply-templates/>
    </div>
  </xsl:template> <!--* match=BUGS *-->

  <!--*
      * DTD Entry:
      *   <!ELEMENT LASTMODIFIED (#PCDATA)>
      * 
      *-->
  <xsl:template match="LASTMODIFIED">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * DTD Entry:
      *   <!ELEMENT VERSION      (#PCDATA)>
      * 
      * we skip the version block, since we include this info
      * in the page header
      * 
  <xsl:template match="VERSION"/>
      *-->
  <xsl:template match="VERSION">
    <xsl:message terminate="yes">
  Programming error:
    For some reason the stylesheet is trying to process the
    VERSION node directly.
    </xsl:message>
  </xsl:template>

  <!--*
      * DTD Entry:
      *   <!ELEMENT ADDRESS      (URL, LABEL)>
      * 
  <xsl:template match="ADDRESS"/>
      *-->
  <xsl:template match="ADDRESS">
    <xsl:message terminate="yes">
  Programming error:
    For some reason the stylesheet is trying to process the
    ADDRESS node directly.
    </xsl:message>
  </xsl:template>
  
  <!--* end of DTD templates *-->

  <!--*
      * add the "See Also" section if $seealsofile was supplied
      * - need to make sure that "seealso" doesn't appear in
      *   the output
      *-->
  <xsl:template name="add-seealso">
    
    <xsl:if test="$have-seealso">
      <div class="ahelpseealso">
	<h2><a name="seealso">See Also</a></h2>

<!--*	<xsl:copy-of select="document($seealsofile)/seealso"/> *-->
	<!--*
            * we want to copy everything within seealso but not
            * seealso itself. it appears that $seealso/* works
            * (I was worried that, since * doesn't match attributes, 
            *  text nodes, comments, or PI's then things like href='...'
            * wouldn't get copied. It seems okay because seealso itself
            * doesn't have any attributes/comments/text nodes - it just
            * has dl as it's child [at least in the current design]).
            *-->
	<xsl:copy-of select="$seealso/*"/>
      </div>
    </xsl:if>

  </xsl:template> <!--* name=add-seealso *-->

  <!--*
      * Adds the "jump to" section to allow quick navigation
      *
      * Takes advantage of variables defined in top-level style sheet
      *   eg format, have-desc, have-bugs, ...
      *
      *-->
  <xsl:template name="add-ahelp-qlinks">

    <!--* do we warrant a "quick links" bar? *-->
    <xsl:if test="$have-desc or $have-example or $have-param or $have-seealso or $have-bugs">
      <div class="noprint">
      <table border="0" width="100%">
	<tr>
	  <td align="left">
	    <strong>Jump to:</strong>
	    <xsl:if test="$have-desc"><xsl:text> </xsl:text><a title="Jump to the description" href="#description">Description</a></xsl:if>
	    <xsl:if test="$have-example"><xsl:text> </xsl:text><a title="Jump to the Example section" href="#examples">Example<xsl:if test="$nexample!=1">s</xsl:if></a></xsl:if>
	    <xsl:if test="$have-param"><xsl:text> </xsl:text><a title="Jump to the parameter description" href="#ptable">Parameters</a></xsl:if>
	    <!--* see how linking to the ADESC blocks looks *-->
	    <xsl:for-each select="//ENTRY/ADESC">
	      <!--* could put in XPath expression above but can't be bothered *-->
	      <xsl:if test="boolean(@title)">
		<xsl:text> </xsl:text><a>
		  <xsl:attribute name="href"><xsl:value-of select="concat('#',translate(@title,' ','_'))"/></xsl:attribute>
		  <xsl:value-of select="@title"/></a>
	      </xsl:if>
	    </xsl:for-each>
	    <xsl:if test="$have-bugs"><xsl:text> </xsl:text><a title="Jump to the Bugs section" href="#bugs">Bugs</a></xsl:if>
	    <xsl:if test="$have-seealso"><xsl:text> </xsl:text><a title="Jump to the 'See Also' section" href="#seealso">See Also</a></xsl:if>
	  </td>
	</tr>
      </table>
      <hr/><br/>
      </div> <!--* class=noprint *-->
    </xsl:if>
  </xsl:template> <!--* name=add-ahelp-qlinks *-->

  <!--* taken from helper.xsl *-->

  <xsl:template name="newline">
<xsl:text>
</xsl:text>
  </xsl:template>

</xsl:stylesheet> <!--* FIN *-->
