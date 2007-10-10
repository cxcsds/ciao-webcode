<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!-- $Id: myhtml.xsl,v 1.22 2003/07/16 01:26:11 dburke Exp $ -->

<!--* 
    * Recent changes:
    *  v1.22 - new/updated dates now in bold/normal size if in a thread index
    *  v1.21 - ensure $depth is used by templates called from scriptlist
    *          [really need to sort out this issue]
    *  v1.20 - added in Chris' scriptlist support
    *  v1.19 - (re v1.18: unless it's in the thread index page)
    *  v1.18 - list's now complain if contain anything but li tags or in p blocks
    *  v1.17 - add-date template now uses the first 3 letters of the month name
    *  v1.16 - added a "year 4000" problem to the date handling
    *  v1.15 - added bugnum tag as a stop-gap measure
    *  v1.14 - added ssi tag: flastmod
    *  v1.13 - beginning support for the math tag
    *  v1.12 - dates for new/updated tags now font size -1
    *  v1.11 - added support for lists of type "a"
    *  v1.10 - cleaned up highlight code slightly (more modular)
    *   v1.9 - amalgamated xhtml.xsl templates (thread code)
    *   v1.8 - bug fix for v1.7
    *   v1.7 - images are now looked for in imgs/ not gifs/
    *
    * support for xHTML-like tags
    * - link tags/support can be found in links.xsl
    *
    * Note there's some pretty ugly use of XSLT here.
    * Some of this can be removed once we use CSS (since handling
    * the style info can be done by that) but that requires
    * CSS support in htmldoc (currently not available)
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--*
      * unwanted HTML tags
      *-->

  <!--* i to em *-->
  <xsl:template match="i|I">
    <xsl:message terminate="yes">
      Please convert all &lt;<xsl:value-of select="name()"/>&gt; tags to &lt;em&gt;
      <xsl:call-template name="newline"/>
    </xsl:message>
  </xsl:template>

  <!--* b to strong *-->
  <xsl:template match="b|B">
    <xsl:message terminate="yes">
      Please convert all &lt;<xsl:value-of select="name()"/>&gt; tags to &lt;strong&gt;
      <xsl:call-template name="newline"/>
    </xsl:message>
  </xsl:template>

  <!--* uppercase tags *-->
  <xsl:template match="CAPTION|CENTER|DIV|HR|P|SUB|SUP|TABLE|TR|TD|IMG">
    <xsl:message terminate="yes">
      Please convert &lt;<xsl:value-of select="name()"/>&gt; tags to lowercase
      <xsl:call-template name="newline"/>
    </xsl:message>
  </xsl:template> <!--* UPPERCASE tags *-->

  <!--*
      * used to add em, strong, ul to link text 
      * - used by start|end-em|strong|tt templates
      *   and by start/end-list templates (for which the quote is added)
      *-->

  <xsl:template name="start-tag">
    <xsl:text disable-output-escaping="yes">&lt;</xsl:text>
  </xsl:template>
  <xsl:template name="end-tag">
    <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
  </xsl:template>
  
  <xsl:template name="add-quote">
    <xsl:text disable-output-escaping="yes">&quot;</xsl:text>
  </xsl:template>
  <xsl:template name="add-nbsp">
    <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
  </xsl:template>

  <!--* add "</body>" *-->
  <xsl:template name="add-end-body">
    <xsl:call-template name="start-tag"/>/body<xsl:call-template name="end-tag"/>
  </xsl:template> <!--* name=add-end-body *-->

  <!--* add "<html>" *-->
  <xsl:template name="add-start-html">
    <xsl:call-template name="start-tag"/>html<xsl:call-template name="end-tag"/>
  </xsl:template> <!--* name=add-start-html *-->
  <xsl:template name="add-end-html">
    <xsl:call-template name="start-tag"/>/html<xsl:call-template name="end-tag"/>
  </xsl:template> <!--* name=add-end-html *-->

  <!--* add "<p>..</p>" *-->
  <xsl:template name="add-start-para">
    <xsl:call-template name="start-tag"/>p<xsl:call-template name="end-tag"/>
  </xsl:template>
  <xsl:template name="add-end-para">
    <xsl:call-template name="start-tag"/>/p<xsl:call-template name="end-tag"/>
  </xsl:template>

  <!--*
      * templates to make starting/ending lists easier
      *-->
  <xsl:template name="start-list">

    <!--* what sort of a list is this? *-->
    <xsl:choose>
      <xsl:when test="string(@type)='A'"><xsl:call-template name="start-ol-A"/></xsl:when>
      <xsl:when test="string(@type)='1'"><xsl:call-template name="start-ol-1"/></xsl:when>
      <xsl:otherwise><xsl:call-template name="start-ul"/></xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* start-list *-->

  <xsl:template name="end-list">

    <!--* what sort of a list is this? *-->
    <xsl:choose>
      <!--* do not rely on type being defined, since it could be set to an incorrect value *-->
      <!--* (repeat the "start-list" code to reduce chances of error) *-->
      <xsl:when test="string(@type)='A'"><xsl:call-template name="end-ol"/></xsl:when>
      <xsl:when test="string(@type)='1'"><xsl:call-template name="end-ol"/></xsl:when>
      <xsl:otherwise><xsl:call-template name="end-ul"/></xsl:otherwise>
    </xsl:choose>
    
  </xsl:template> <!--* end-list *-->

  <xsl:template name="start-ul">
    <xsl:call-template name="start-tag"/>ul<xsl:call-template name="end-tag"/>
  </xsl:template>
  <xsl:template name="end-ul">
    <xsl:call-template name="start-tag"/>/ul<xsl:call-template name="end-tag"/>
  </xsl:template>

  <xsl:template name="start-ol-A">
    <xsl:call-template name="start-tag"/>ol type=<xsl:call-template name="add-quote"/>A<xsl:call-template name="add-quote"/><xsl:call-template name="end-tag"/>
  </xsl:template>
  <xsl:template name="start-ol-1">
    <xsl:call-template name="start-tag"/>ol type=<xsl:call-template name="add-quote"/>1<xsl:call-template name="add-quote"/><xsl:call-template name="end-tag"/>
  </xsl:template>
  <xsl:template name="end-ol">
    <xsl:call-template name="start-tag"/>/ol<xsl:call-template name="end-tag"/>
  </xsl:template>


  <!--*
      * In order to automatically add/end "style" tags
      * - ie em, strong, tt, ... - we have to go through this
      * hassle (well, there's almost certainly other ways to do it)
      *-->
  <xsl:template name="start-em">
    <xsl:call-template name="start-tag"/>em<xsl:call-template name="end-tag"/>
  </xsl:template>
  <xsl:template name="end-em">
    <xsl:call-template name="start-tag"/>/em<xsl:call-template name="end-tag"/>
  </xsl:template>

  <xsl:template name="start-strong">
    <xsl:call-template name="start-tag"/>strong<xsl:call-template name="end-tag"/>
  </xsl:template>
  <xsl:template name="end-strong">
    <xsl:call-template name="start-tag"/>/strong<xsl:call-template name="end-tag"/>
  </xsl:template>

  <xsl:template name="start-tt">
    <xsl:call-template name="start-tag"/>tt<xsl:call-template name="end-tag"/>
  </xsl:template>
  <xsl:template name="end-tt">
    <xsl:call-template name="start-tag"/>/tt<xsl:call-template name="end-tag"/>
  </xsl:template>

  <!--*
      * requires a number of boolean attributes:
      *   tt, strong, em
      *
      * since these 2 templates are processed via call-templates, 
      * the values of these attributes are taken from the node
      * being processed when these templates are called. Which is
      * good, as it means we don't need to create parameters/variables
      * to pass across the options
      *-->
  <xsl:template name="start-styles">

    <xsl:if test="@em=1"><xsl:call-template name="start-em"/></xsl:if>
    <xsl:if test="@tt=1"><xsl:call-template name="start-tt"/></xsl:if>
    <xsl:if test="@strong=1"><xsl:call-template name="start-strong"/></xsl:if>

  </xsl:template> <!--* start-styles *-->

  <xsl:template name="end-styles">

    <!--* must be in reverse order to start-styles *-->
    <xsl:if test="@strong=1"><xsl:call-template name="end-strong"/></xsl:if>
    <xsl:if test="@tt=1"><xsl:call-template name="end-tt"/></xsl:if>
    <xsl:if test="@em=1"><xsl:call-template name="end-em"/></xsl:if>
    
  </xsl:template> <!--* end-styles *-->

  <!--*
      * lists: 
      * we allow ul and ol (type=A, a, or 1)
      * and introduce <list> with an
      * attribute of type (undef => ul, otherwise ol type A, a, or 1)
      *
      * Since we don't have a DTD we explicitly look for non li tags (other
      * than empty text nodes) within it [unless in a threadindex],
      * and if we are within a p block
      *
      *-->
  <xsl:template match="list">
    <xsl:param name="depth" select="1"/>

    <!--* should be in DTD *-->
    <xsl:if test="name(//*) != 'threadindex' and
            (count(child::*[name()!='li']) != 0 or count(text()[normalize-space(.)!='']) != 0)">
      <xsl:message>

 WARNING: this document contains a list element that contains tags other than li
          (or text other than whitespace)

      </xsl:message>
    </xsl:if>

    <xsl:if test="boolean(ancestor::p)">
      <xsl:message>

 WARNING: this document contains a list element within a p block, please change
          as it will soon cause the publishing to fail

      </xsl:message>
      <xsl:call-template name="add-start-para"/>
    </xsl:if>

    <!--* this could be cleverer *-->
    <xsl:choose>
      <xsl:when test="string(@type)='A' or string(@type)='a'">
	<ol type="{@type}">
	  <xsl:apply-templates><xsl:with-param name="depth" select="$depth"/></xsl:apply-templates>
	</ol>
      </xsl:when>
      <xsl:when test="string(@type)='1'">
	<ol type="1">
	  <xsl:apply-templates><xsl:with-param name="depth" select="$depth"/></xsl:apply-templates>
	</ol>
      </xsl:when>
      <xsl:otherwise>
	<ul>
	  <xsl:apply-templates><xsl:with-param name="depth" select="$depth"/></xsl:apply-templates>
	</ul>
      </xsl:otherwise>  
    </xsl:choose>

    <xsl:if test="boolean(ancestor::p)">
      <xsl:call-template name="add-end-para"/>
    </xsl:if>

  </xsl:template> <!--* list *-->

  <xsl:template match="li">
    <xsl:param name="depth" select="1"/>
    <li>
      <xsl:apply-templates><xsl:with-param name="depth" select="$depth"/></xsl:apply-templates>
    </li>
  </xsl:template> <!--* li *-->

  <!--* do not allow ul, use list instead *-->
  <xsl:template match="ul|UL">
    <xsl:message terminate="yes">
      Please convert all &lt;<xsl:value-of select="name()"/>&gt; tags to list (no type attribute)
      <xsl:call-template name="newline"/>
    </xsl:message>
  </xsl:template> <!--* ul|UL *-->
  
  <!--* do not allow ol, use list instead *-->
  <xsl:template match="ol|OL">
    <xsl:message terminate="yes">
      Please convert all &lt;<xsl:value-of select="name()"/>&gt; tags to list
      <xsl:choose>
	<xsl:when test="boolean(@type)">
	  - use the attribute type="<xsl:value-of select="@type"/>" for this tag
	</xsl:when>
	<xsl:otherwise>
	  - add add the attribute type="1" or type="A" for this tag
	</xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="newline"/>
    </xsl:message>
  </xsl:template> <!--* ol *-->
  
  <!--*
      * add a "new" icon
      * - see also the updated template
      * - uses the "package" variable depth to work
      *   out where the gif actually is
      * - if the day attribute is supplied also adds in the date
      *   using (29 June 2002) format where
      *    day=29 month=June year=2
      *   actual output format depends on where the tag is being
      *   used: thread index => big, bold
      *          otherwise   => small
      *-->
  <xsl:template match="new">
    <xsl:param name="depth" select="1"/>

    <xsl:call-template name="add-image">
      <xsl:with-param name="depth" select="$depth"/>
      <xsl:with-param name="src"   select="'imgs/new.gif'"/>
      <xsl:with-param name="alt"   select="'New'"/>
    </xsl:call-template>
    <xsl:if test="boolean(@day)"><xsl:call-template name="add-date"/></xsl:if>
  </xsl:template>
                                                                               
  <!--*
      * add an "updated" icon
      * - see the new template for usage/comments
      *-->
  <xsl:template match="updated">
    <xsl:param name="depth" select="1"/>

    <xsl:call-template name="add-image">
      <xsl:with-param name="depth" select="$depth"/>
      <xsl:with-param name="src"   select="'imgs/updated.gif'"/>
      <xsl:with-param name="alt"   select="'Updated'"/>
    </xsl:call-template>
    <xsl:if test="boolean(@day)"><xsl:call-template name="add-date"/></xsl:if>
  </xsl:template>

  <!--*
      * add the supplied date within brackets, at a font size of -1
      * It uses the day, month, and year attributes of the context node.
      * @day and @month are printed out as-is whereas @year is:
      *   if @year < 2000,  add 2000 to it
      *   if @year >= 2000, leave as is
      *
      * This introduces a "year 4000" problem, but does allow legacy doucments
      * to work, plus I'd be really worried if this code was still being used
      * in the year 4000 *;)
      *
      * actual output format depends on where the tag is being used:
      *   thread index => big, bold
      *    otherwise   => small
      *
      *-->
  <xsl:template name="add-date">
    <xsl:variable name="year"><xsl:choose>
	<xsl:when test="@year >= 2000"><xsl:value-of select="@year"/></xsl:when>
	<xsl:otherwise><xsl:value-of select="2000+@year"/></xsl:otherwise>
      </xsl:choose></xsl:variable>
    <xsl:variable name="text"><xsl:value-of select="concat(@day,' ',substring(@month,1,3),' ',$year)"/></xsl:variable>

    <!--* add a spacer *-->
    <xsl:text> </xsl:text>
    <xsl:choose>
      <xsl:when test="name(//*)='threadindex'">(<strong><xsl:value-of select="$text"/></strong>)</xsl:when>
      <xsl:otherwise><font size="-1">(<xsl:value-of select="$text"/>)</font></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--*
      * handle p tags: we have to handle possible text attributes
      * which are a not-well-thought-out system for associating
      * styles/short-cuts to some block elements.
      *
      * This IS a mess - would be much easier with CSS!
      *
      * also want to allow align attribute to be copied over
      *
      *-->
  <xsl:template match="p">
    <xsl:param name="depth" select="1"/>
    <p>
      <xsl:if test="boolean(@align)"><xsl:attribute name="align"><xsl:value-of select="@align"/></xsl:attribute></xsl:if>
      <xsl:call-template name="text-styles-start"/>
      <xsl:apply-templates><xsl:with-param name="depth" select="$depth"/></xsl:apply-templates>
      <xsl:call-template name="text-styles-end"/></p>
  </xsl:template> <!--* match= p *-->

  <!--* handle the text attributes
      * - this feels like an ugly way to do it
      *-->
  <xsl:template name="text-styles-start">
    <xsl:choose>
      <xsl:when test="boolean(@text)">
        <xsl:call-template name="process-text-styles-start"/>
      </xsl:when>
<!-- need to handle s/thing like boolean(ancestor::@text)
     have a for-each loop over each of these? *-->
    </xsl:choose>
  </xsl:template>

  <xsl:template name="text-styles-end">
    <xsl:choose>
      <xsl:when test="boolean(@text)">
        <xsl:call-template name="process-text-styles-end"/>
      </xsl:when>
<!-- need to handle s/thing like boolean(ancestor::@text)
     have a for-each loop over each of these? *-->
    </xsl:choose>
  </xsl:template>

  <xsl:template name="process-text-styles-start">
    <xsl:choose>
      <xsl:when test="@text='header'"><xsl:call-template name="start-fontp1"/></xsl:when>
      <xsl:when test="@text='note'"><xsl:call-template name="start-fontm1"/></xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="process-text-styles-end">
    <xsl:choose>
      <xsl:when test="@text='header'"><xsl:call-template name="end-font"/></xsl:when>
      <xsl:when test="@text='note'"><xsl:call-template name="end-font"/></xsl:when>
    </xsl:choose>
  </xsl:template>

<!--* font size +1 *-->
<xsl:template name="start-fontp1">
  <xsl:call-template name="start-tag"/>font size='+1'<xsl:call-template name="end-tag"/>
</xsl:template>

<!--* font size -1 *-->
<xsl:template name="start-fontm1">
  <xsl:call-template name="start-tag"/>font size='-1'<xsl:call-template name="end-tag"/>
</xsl:template>

<xsl:template name="end-font">
  <xsl:call-template name="start-tag"/>/font<xsl:call-template name="end-tag"/>
</xsl:template>

  <!--* 
      * allow img tags:
      * assume the user knows what's going on so don't handle $depth
      *-->
  <xsl:template match="img">
    <xsl:if test="boolean(@src)=false()">
      <xsl:message terminate="yes">
  Error: img tags must have a src attribute
      </xsl:message>
    </xsl:if>
    <xsl:if test="boolean(@alt)=false()">
      <xsl:message terminate="yes">
  Error: img tags must have an alt attribute
      </xsl:message>
    </xsl:if>
    <xsl:copy-of select="."/>
  </xsl:template> <!--* img *-->

  <!--*
      * handle pre blocks
      *
      * we augment them with a "highlight=1 or 0" attribute. If set to 1
      * then we create the text with a grey background
      * - need more user-control
      *
      * Note:
      *   the pre blocks are no longer placed in tables that fill
      *   the width of the page
      *
      *-->
  <xsl:template match="pre">
    <xsl:param name="depth" select="1"/>

    <!--* ugly *-->
    <xsl:choose>
      <xsl:when test="boolean(@highlight) and @highlight='1'">
<xsl:call-template name="add-highlight-start"/><pre>
<xsl:apply-templates><xsl:with-param name="depth" select="$depth"/></xsl:apply-templates>
</pre><xsl:call-template name="add-highlight-end"/>
      </xsl:when>
      <xsl:otherwise>
<pre>
<xsl:apply-templates><xsl:with-param name="depth" select="$depth"/></xsl:apply-templates>
</pre>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* pre *-->

  <!--*
      * handle highlight 'blocks'
      *
      * currently we just wrap the contents in a table
      * and set the background. A hack.
      *
      *-->
  <xsl:template match="highlight">
    <xsl:param name="depth" select="1"/>

    <xsl:call-template name="add-highlight-start"/>
    <xsl:apply-templates><xsl:with-param name="depth" select="$depth"/></xsl:apply-templates>
    <xsl:call-template name="add-highlight-end"/>

  </xsl:template> <!--* match=highlight *-->

  <!--*
      * convert center tags to div ones
      * - should we include a warning?
      *-->
  <xsl:template match="center">
    <xsl:param name="depth" select="1"/>

    <div align="center"><xsl:apply-templates>
	<xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates></div>
  </xsl:template> <!--* match=center *-->

  <!--*
      * start the "highlighted" section of text
      * - should be done with CSS
      *-->
  <xsl:template name="add-highlight-start">
<xsl:call-template name="start-tag"/>table border=<xsl:call-template name="add-quote"/>0<xsl:call-template name="add-quote"/> bgcolor=<xsl:call-template name="add-quote"/>#cccccc<xsl:call-template name="add-quote"/><xsl:call-template name="end-tag"/>
<xsl:call-template name="start-tag"/>tr<xsl:call-template name="end-tag"/>
<xsl:call-template name="start-tag"/>td<xsl:call-template name="end-tag"/>
  </xsl:template> <!--* name=add-highlight-start *-->

  <!--*
      * end the "highlighted" section of text
      * - should be done with CSS
      *-->
  <xsl:template name="add-highlight-end">
<xsl:call-template name="start-tag"/>/td<xsl:call-template name="end-tag"/>
<xsl:call-template name="start-tag"/>/tr<xsl:call-template name="end-tag"/>
<xsl:call-template name="start-tag"/>/table<xsl:call-template name="end-tag"/>
  </xsl:template> <!--* name=add-highlight-end *-->

  <!--*
      * Support math tags:
      *
      *   <math>
      *     <name>...</name>
      *     <latex>...</latex> (latex formula with NO being/end math values)
      *     <text>...</text>   (plain text representation)
      * {   <mathml>...</mathml>   (MathML version)   NOT YET IMPLEMENTED    }
      *   </math>
      *
      * Creates a gif (name.gif) which is included in the text
      * (with alt attribute = [text]). name is also used to set the
      * anchor of the equation
      *
      * A lot of the processing is actually done external to the stylesheet
      * - eg list_math.xsl is called and the perl script does the actual
      *   conversion to GIF
      *
      * Notes:
      * - may want to add attributes that are used to control the created formula
      *
      *-->
  <xsl:template match="math">

    <!--* DTD-style checks *-->
    <xsl:if test="boolean(name)=false() or boolean(latex)=false() or boolean(text)=false()">
      <xsl:message terminate="yes">
 Error: a match tag is missing at least one of the following
   nodes - name, latex, text
      </xsl:message>
    </xsl:if>

    <!--* don't allow in p blocks *-->
    <xsl:if test="ancestor::p">
      <xsl:message terminate="yes">
 Error: a math tag is within a p block. This is
   not allowed - try a div node if you need
   centering/some control.
      </xsl:message>
    </xsl:if>

    <!--*
        * create the latex document
        * - could allow the fg/bg colors to be set with attributes
        * - apparently xsl:document will nest
        * - need to remove leading/trailing whitespace so that
        *   latex doesn't complain
        *-->
    <xsl:document href="{concat($sourcedir,name,'.tex')}" method="text">
\documentclass{article}
\usepackage{color}
\pagestyle{empty}
\pagecolor{white}
\begin{document}
\begin{eqnarray*}
{\color{black}
<xsl:value-of select="normalize-space(latex)"/>
}
\end{eqnarray*}
\end{document}
    </xsl:document>

    <!--* and add the img tag to the resulting tree, within an anchor *-->
    <a name="{name}"><img src="{name}.gif" alt="{text}"/></a>

  </xsl:template> <!--* match=math *-->

  <!--*
      * create a SSI statement in the output file
      * that gives the last-modified date of the file
      *
      * the tag contents are the name of the file
      *
      * Parameters:
      *   NONE
      *
      *-->
  <xsl:template match="flastmod">
    <xsl:comment>#flastmod file="<xsl:value-of select="."/>"</xsl:comment>
  </xsl:template> <!--* match=flastmod *-->

  <!--*
      * to indicate when a bit of text is associated with a bug:
      * this is a stop-gap measure until we come up with proper
      * markup for bugs
      *
      * It ignores the contents (which are assumed to be the bug number)
      *-->
  <xsl:template match="bugnum"/>

  <!--*
      * from Chris Stawarz's download-script code
      * - mangled since we now have to interpret all
      *   the tags that Chris was able to use
      *-->
  <xsl:template match="scriptlist">
    <xsl:param name="depth" select="1"/>

    <h2><id name="scripts">Scripts Available for Download
	(by category)</id></h2>
    
    <ul>
      <xsl:for-each select="category">
	<li>
	  <a href="{concat('#',translate(@name,' ',''))}"><xsl:value-of select="@name"/></a>
	</li>
      </xsl:for-each> <!-- select="category" -->
    </ul>

    <table border="0" cellpadding="5" width="100%">
      <xsl:for-each select="category">
	<tr>
	  <th align="left" colspan="5">
	    <a name="{translate(@name,' ','')}"><xsl:value-of select="@name"/></a>
	  </th>
	</tr>
	<tr>
	  <td>Script</td>
	  <td>Associated thread</td>
	  <td>Language</td>
	  <td>Version</td>
	  <td>Last update</td>
	</tr>
        <xsl:for-each select="script">
          <tr bgcolor="#cccccc">
	    <td align="center" rowspan="2">
	      <strong><a name="{@name}"><xsl:call-template name="create-script-link">
		    <xsl:with-param name="name"  select="@name"/>
		    <xsl:with-param name="depth" select="$depth"/>
		  </xsl:call-template></a></strong>
	    </td>
	    <td>
	      <xsl:apply-templates select="thread" mode="scripts">
		<xsl:with-param name="depth" select="$depth"/>
	      </xsl:apply-templates>
	    </td>
	    <td align="center"><xsl:value-of select="@lang"/></td>
	    <td align="center"><xsl:value-of select="@ver"/></td>
	    <td align="center">
	      <xsl:value-of select="@day"/>-<xsl:call-template name="get-month"><xsl:with-param name="month" select="@month"/></xsl:call-template>-<xsl:value-of select="@year"/>
	      <xsl:if test="@updated = 'yes'">
	        <br/>
		<xsl:call-template name="add-image">
		  <xsl:with-param name="depth" select="$depth"/>
		  <xsl:with-param name="src"   select="'imgs/updated.gif'"/>
		  <xsl:with-param name="alt"   select="'Updated'"/>
		</xsl:call-template>
	      </xsl:if>
	      <xsl:if test="@new = 'yes'">
	        <br/>
		<xsl:call-template name="add-image">
		  <xsl:with-param name="depth" select="$depth"/>
		  <xsl:with-param name="src"   select="'imgs/new.gif'"/>
		  <xsl:with-param name="alt"   select="'New'"/>
		</xsl:call-template>
	      </xsl:if>
	    </td>
          </tr>
          <tr bgcolor="#cccccc">
	    <td align="left" colspan="4">
	      <xsl:apply-templates select="desc">
		<xsl:with-param name="depth" select="$depth"/>
	      </xsl:apply-templates>
	    </td>
	  </tr>
	  <tr>
	    <td colspan="5"/>
	  </tr>
        </xsl:for-each> <!-- select="script" -->
      </xsl:for-each> <!-- select="category" -->
    </table>
  </xsl:template> <!-- match=scriptlist -->

  <xsl:template match="desc|thread" mode="scripts">
    <xsl:param name="depth" select="1"/>
    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template> <!-- match=desc|thread mode=scripts -->

  <xsl:template name="get-month">
    <xsl:param name="month"/>
    <xsl:choose>
      <xsl:when test="$month = '1'">Jan</xsl:when>
      <xsl:when test="$month = '2'">Feb</xsl:when>
      <xsl:when test="$month = '3'">Mar</xsl:when>
      <xsl:when test="$month = '4'">Apr</xsl:when>
      <xsl:when test="$month = '5'">May</xsl:when>
      <xsl:when test="$month = '6'">Jun</xsl:when>
      <xsl:when test="$month = '7'">Jul</xsl:when>
      <xsl:when test="$month = '8'">Aug</xsl:when>
      <xsl:when test="$month = '9'">Sep</xsl:when>
      <xsl:when test="$month = '10'">Oct</xsl:when>
      <xsl:when test="$month = '11'">Nov</xsl:when>
      <xsl:when test="$month = '12'">Dec</xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">

 ERROR: unable to understand month value of <xsl:value-of select="$month"/>
        for scriptlist sctipt=<xsl:value-of select="@name"/>

	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!-- name="get-month" -->

</xsl:stylesheet>
