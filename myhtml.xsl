<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Recent changes:
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *  v1.35 - moved "screen" code from thread_common.xsl to myhtml.xsl
    *  v1.34 - add-start-html now includes lang="en" attribute in tag following
    *            http://www.w3.org/TR/2005/WD-i18n-html-tech-lang-20050224/
    *  v1.33 - removed tab character to make testing easier. no functional change
    *  v1.32 - bug fixes in scriptlist handling: had missed converting an id tag to
    *          <a name=...> and had missed setting the scripts mode for processing desc
    *  v1.31 - changed to using &#160; for nbsp rather than the disable-encoding hack
    *  v1.30 - cleaned up un-needed add-start/end templates from list code (~v1.25)
    *          We now make it an error for a list block to appear within a p block
    *  v1.29 - added the calculate-date-from-attributes template (perhaps should
    *          be in helper.xsl) and used it in "add-date"
    *  v1.28 - bug-fix to 1.27: need to use copy-of to preserve tags/attributes
    *  v1.27 - clean up to handling of p tags (similar, but simpler, than v1.25)
    *  v1.26 - removed empty-content check in add-text-styles as we seem to need
    *          to do this in the calling template (ie in links.xsl)
    *  v1.25 - major revamp of adding 'styles' to links: remove start/end-styles
    *          and just have a add-text-styles template
    *  v1.24 - pre/@header now uses add-highlight template (ie CSS if hardcopy!=1)
    *  v1.23 - updated to account for scripts all now in one package (i.e.
    *          not available separately)
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
      * trying to remove the use of these templates, but it is not fully possible
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
  <!--*
      * for some reason I used to want the output to contain &nbsp;
      * rather than &#160; - I believe that I saw differences with
      * certain browsers. I have just tried netscape4.76s and it
      * deals with &#160; correctly. So I am changing to use the
      * code point for the nbsp rather than the entity (or whatever
      * the terminology is)
      *
  <xsl:template name="add-nbsp">
    <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
  </xsl:template>
      *
      *-->
  <xsl:template name="add-nbsp">&#160;</xsl:template>

  <!--* add "</body>" *-->
  <xsl:template name="add-end-body">
    <xsl:text disable-output-escaping="yes">&lt;/body&gt;</xsl:text>
  </xsl:template> <!--* name=add-end-body *-->

  <!--* add '<html lang="en">' *-->
  <xsl:template name="add-start-html">
    <xsl:text disable-output-escaping="yes">&lt;html lang="en"&gt;</xsl:text>
  </xsl:template> <!--* name=add-start-html *-->
  <xsl:template name="add-end-html">
    <xsl:text disable-output-escaping="yes">&lt;/html&gt;</xsl:text>
  </xsl:template> <!--* name=add-end-html *-->

  <!--*
      * From v1.25 of myhtml.xsl (CIAO 3.1) we no longer have
      *   start-styles/end-styles
      * but
      *   add-text-styles
      *
      * Parameters:
      *   contents, node set, required
      *     this is the processed content of the link
      *
      * processes the following attributes of the context node:
      *   em, tt, strong
      * in that order
      *
      *-->
  <xsl:template name="add-text-styles">
    <xsl:param name="contents" select="''"/>

    <!--*
        * removed this check since it is better done in the context
        * of the parent node (I could not easily see how to handle
        * cases like <cxclink href='...'><img src='...'/></cxclink>
        * here, whereas you can in the cxclink tag
        *
    <xsl:if test="$contents = '' and count($contents) = 0">
      <xsl:message terminate="yes">
 ERROR: add-text-styles called with contents=""
   context node=<xsl:value-of select="name()"/>
      </xsl:message>
    </xsl:if>
        *
        *-->

    <!--*
        * loop through the recognised attributes
        * (it strikes me there may be a better way of doing this)
        *-->

    <xsl:call-template name="add-text-styles-em">
      <xsl:with-param name="contents" select="$contents"/>
    </xsl:call-template>

  </xsl:template> <!--* add-text-styles *-->

  <xsl:template name="add-text-styles-em">
    <xsl:param name="contents" select="''"/>
    <xsl:choose>
      <xsl:when test="@em=1">
	<em>
	  <xsl:call-template name="add-text-styles-tt">
	    <xsl:with-param name="contents" select="$contents"/>
	  </xsl:call-template>
	</em>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="add-text-styles-tt">
	  <xsl:with-param name="contents" select="$contents"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* add-text-styles-em *-->

  <xsl:template name="add-text-styles-tt">
    <xsl:param name="contents" select="''"/>
    <xsl:choose>
      <xsl:when test="@tt=1">
	<tt>
	  <xsl:call-template name="add-text-styles-strong">
	    <xsl:with-param name="contents" select="$contents"/>
	  </xsl:call-template>
	</tt>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="add-text-styles-strong">
	  <xsl:with-param name="contents" select="$contents"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* add-text-styles-tt *-->

  <xsl:template name="add-text-styles-strong">
    <xsl:param name="contents" select="''"/>
    <xsl:choose>
      <xsl:when test="@strong=1">
	<strong>
	  <xsl:copy-of select="$contents"/>
	</strong>
      </xsl:when>
      <xsl:otherwise>
	<xsl:copy-of select="$contents"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* add-text-styles-strong *-->

  <!--*
      * lists: 
      * we allow ul and ol (type=A, a, or 1)
      * and introduce <list> with an
      * attribute of type (undef => ul, otherwise ol type A, a, or 1)
      *
      * Since we don't have a DTD we explicitly look for non li tags (other
      * than empty text nodes) within it [unless in a threadindex],
      * and if we are within a p block (which, as of CIAO 3.1, is a fatal
      * error)
      *
      *-->
  <xsl:template match="list">

    <!--* should be in DTD *-->
    <xsl:if test="boolean(ancestor::p)">
      <xsl:message terminate="yes">
 ERROR: this document contains a list element within a p block,
        which is not allowed
      </xsl:message>
    </xsl:if>

    <xsl:if test="name(//*) != 'threadindex' and
            (count(child::*[name()!='li']) != 0 or count(text()[normalize-space(.)!='']) != 0)">
      <xsl:message terminate="yes">
 ERROR: this document contains a list element that contains tags other than li
        (or text other than whitespace),
        which is not allowed

      </xsl:message>
    </xsl:if>

    <!--* this could be cleverer *-->
    <xsl:choose>
      <xsl:when test="string(@type)='A' or string(@type)='a'">
	<ol type="{@type}">
	  <xsl:apply-templates/>
	</ol>
      </xsl:when>
      <xsl:when test="string(@type)='1'">
	<ol type="1">
	  <xsl:apply-templates/>
	</ol>
      </xsl:when>
      <xsl:otherwise>
	<ul>
	  <xsl:apply-templates/>
	</ul>
      </xsl:otherwise>  
    </xsl:choose>

  </xsl:template> <!--* list *-->

  <xsl:template match="li">
    <li>
      <xsl:apply-templates/>
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

    <xsl:call-template name="add-image">
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

    <xsl:call-template name="add-image">
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
      * - I'm beginning to think that the 'smarts' built into this
      *   routine should be removed - i.e. make the template that calls
      *   this one do the extra work (since it knows the context).
      *   Have separated out the logic so that we can do this better
      *   (added the calculate-date-from-attributes template, which I think
      *    should be in helper.xsl but leave in here for now)
      *-->
  <xsl:template name="calculate-date-from-attributes">
    <xsl:variable name="year"><xsl:choose>
	<xsl:when test="@year >= 2000"><xsl:value-of select="@year"/></xsl:when>
	<xsl:otherwise><xsl:value-of select="2000+@year"/></xsl:otherwise>
      </xsl:choose></xsl:variable>
    <xsl:value-of select="concat(@day,' ',substring(@month,1,3),' ',$year)"/>
  </xsl:template> <!--* name=calculate-date-from-attributes *-->

  <xsl:template name="add-date">
    <xsl:variable name="text"><xsl:call-template name="calculate-date-from-attributes"/></xsl:variable>
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
    <xsl:variable name="contents"><xsl:apply-templates/></xsl:variable>

    <p>
      <xsl:if test="boolean(@align)"><xsl:attribute name="align"><xsl:value-of select="@align"/></xsl:attribute></xsl:if>
      <xsl:choose>
	<xsl:when test="@text='header'"><font size="+1"><xsl:copy-of select="$contents"/></font></xsl:when>
	<xsl:when test="@text='note'"><font size="-1"><xsl:copy-of select="$contents"/></font></xsl:when>
	<xsl:otherwise><xsl:copy-of select="$contents"/></xsl:otherwise>
      </xsl:choose>
    </p>
  </xsl:template> <!--* match=p *-->

  <!--* 
      * allow img tags:
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
      * handle screen tags 
      *
      * they either have an attribute of file, 
      * which means load the text from @file.xml,
      * or use their content
      *
      * As of CIAO 3.1 we use CSS to define the 'look' of the
      * blocks (apart from the hardcopy version)
      *
      *-->
  <xsl:template name="add-highlight">
    <xsl:param name="contents" select="''"/>

    <!--* ugh! *-->
    <xsl:param name="bgcolor">cccccc</xsl:param>
    <xsl:param name="bocolor">000000</xsl:param>

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<!--* hack for htmldoc *-->
	<table border="0" cellspacing="0" bgcolor="#{$bocolor}"><tr><td><table border="0" cellspacing="0" bgcolor="#{$bgcolor}"><tr><td>
<pre><xsl:copy-of select="$contents"/></pre>
</td></tr></table></td></tr></table>
      </xsl:when>
      <xsl:otherwise>
	<!--* yay CSS (although highlight is a poor class name) *-->
<pre class="highlight"><xsl:copy-of select="$contents"/></pre>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=add-highlight *-->

  <xsl:template match="screen">

    <!--* a check since we've changed name to file *-->
    <xsl:if test="boolean(@name)">
      <xsl:message terminate="yes">
  Error:
    a screen tag has been found with a name attribute
    (with value '<xsl:value-of select="@name"/>')
  --  name must be changed to file
      </xsl:message>
    </xsl:if>

    <!--*
        * process the contents of the screen tag into the
        * variable contents, which we then send to the
        * add-highlight template
        *-->
    <xsl:variable name="contents"><xsl:choose>
	<xsl:when test='. != ""'>
	  <xsl:apply-templates/>
	</xsl:when>
	<xsl:when test='boolean(@file)'>
	  <xsl:apply-templates
	    select="document(concat($sourcedir,@file,'.xml'))" mode="include"/>
	</xsl:when>
      </xsl:choose></xsl:variable>

    <!--* <br/> *-->
    <div class="screen">
      <xsl:call-template name="add-highlight">
	<xsl:with-param name="contents" select="$contents"/>
      </xsl:call-template>
    </div>
    <!--* <br/> *-->
  
  </xsl:template> <!--* screen *-->

  <!--*
      * add highlighting around the contents of the
      * contents parameter (which can be a node-list)
      *
      * As of CIAO 3.1 we use CSS to define the 'look' of the
      * blocks (apart from the hardcopy version)
      *
      * need to think about what we want highlighting
      * - ie how we handle the non-pre-block cases
      * - at the moment should be able to place in a
      *   div (since the old version put them into a table)
      *
      * NOTE:
      *   div structure/class names are rather chaotic at the moment
      *
      *-->
  <xsl:template name="add-highlight-pre">
    <xsl:param name="contents" select="''"/>

    <!--* ugh! *-->
    <xsl:param name="bgcolor">cccccc</xsl:param>
    <xsl:param name="bocolor">000000</xsl:param>

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<!--* hack for htmldoc *-->
	<table border="0" cellspacing="0" bgcolor="#{$bocolor}"><tr><td><table border="0" cellspacing="0" bgcolor="#{$bgcolor}"><tr><td>
<pre><xsl:copy-of select="$contents"/></pre>
</td></tr></table></td></tr></table>
      </xsl:when>
      <xsl:otherwise>
	<!--* yay CSS (although highlight is a poor class name) *-->
<pre class="highlight"><xsl:copy-of select="$contents"/></pre>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=add-highlight-pre *-->

  <xsl:template name="add-highlight-block">
    <xsl:param name="contents" select="''"/>

    <!--* ugh! *-->
    <xsl:param name="bgcolor">cccccc</xsl:param>
    <xsl:param name="bocolor">000000</xsl:param>

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<!--* hack for htmldoc *-->
	<table border="0" cellspacing="0" bgcolor="#{$bocolor}"><tr><td><table border="0" cellspacing="0" bgcolor="#{$bgcolor}"><tr><td>
<xsl:copy-of select="$contents"/>
</td></tr></table></td></tr></table>
      </xsl:when>
      <xsl:otherwise>
	<!--* yay CSS (although highlighttext is a poor class name) *-->
<div class="highlighttext">
<xsl:copy-of select="$contents"/>
</div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=add-highlight-block *-->

  <!--*
      * handle pre blocks
      *
      * we augment them with a "highlight=1 or 0" attribute. If set to 1
      * then we create the text with a grey background
      * - need more user-control
      *
      *-->
  <xsl:template match="pre">

    <!--* safety check *-->
    <xsl:if test="ancestor::p">
      <xsl:message terminate="yes">
 ERROR: you have a pre block within a p block. This is not allowed.
   contents of pre block=
<xsl:apply-templates/>
 
      </xsl:message>
    </xsl:if>

    <!--* ugly *-->
    <xsl:choose>
      <xsl:when test="boolean(@highlight) and @highlight='1'">
	<xsl:call-template name="add-highlight-pre">
	  <xsl:with-param name="contents"><xsl:apply-templates/></xsl:with-param>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
<pre>
<xsl:apply-templates/>
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

    <!--* safety check *-->
    <xsl:if test="ancestor::p">
      <xsl:message terminate="yes">
 ERROR: you have a highlight block within a p block. This is not allowed.
   contents of highlight block=
<xsl:apply-templates/>
 
      </xsl:message>
    </xsl:if>

    <xsl:call-template name="add-highlight-block">
      <xsl:with-param name="contents"><xsl:apply-templates/></xsl:with-param>
    </xsl:call-template>

  </xsl:template> <!--* match=highlight *-->

  <!--*
      * convert center tags to div ones
      * - should we include a warning?
      *-->
  <xsl:template match="center">
    <div align="center"><xsl:apply-templates/></div>
  </xsl:template> <!--* match=center *-->

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

    <h2><a name="scripts">Scripts and Modules (by category)</a></h2>
    
    <ul>
      <xsl:for-each select="category">
	<li>
	  <a href="{concat('#',translate(@name,' ',''))}"><xsl:value-of select="@name"/></a>
	</li>
      </xsl:for-each> <!-- select="category" -->
    </ul>

    <table class="scripts" border="0" cellpadding="5" width="100%">
      <xsl:for-each select="category">

	<tr>
	  <th align="left" colspan="4">
	    <a name="{translate(@name,' ','')}"><xsl:value-of select="@name"/></a>
	  </th>
	</tr>

	<xsl:if test="boolean(intro)">
          <tr>
	    <td colspan="4">
	      <xsl:apply-templates select="intro/."/>
	    </td>
	  </tr>
	</xsl:if>

	<xsl:if test="boolean(script)">
	<tr>
	  <td>Name</td>
	  <td>Associated thread(s)</td>
	  <td>Language</td>
	  <td>Last update</td>
	</tr>
        <xsl:for-each select="script">
          <tr class="scriptrow">
	    <td align="center" rowspan="2">
	      <strong><xsl:value-of select="@name"/></strong>
	    </td>
	    <td>
	      <xsl:apply-templates select="thread" mode="scripts"/>
	    </td>
	    <td align="center"><xsl:value-of select="@lang"/></td>
	    <td align="center">
	      <xsl:value-of select="@day"/>-<xsl:call-template name="get-month"><xsl:with-param name="month" select="@month"/></xsl:call-template>-<xsl:value-of select="@year"/>
	      <xsl:if test="@updated = 'yes'">
	        <br/>
		<xsl:call-template name="add-image">
		  <xsl:with-param name="src"   select="'imgs/updated.gif'"/>
		  <xsl:with-param name="alt"   select="'Updated'"/>
		</xsl:call-template>
	      </xsl:if>
	      <xsl:if test="@new = 'yes'">
	        <br/>
		<xsl:call-template name="add-image">
		  <xsl:with-param name="src"   select="'imgs/new.gif'"/>
		  <xsl:with-param name="alt"   select="'New'"/>
		</xsl:call-template>
	      </xsl:if>
	    </td>
          </tr>
          <tr class="scriptrow">
	    <td align="left" colspan="3">
	      <xsl:apply-templates select="desc" mode="scripts"/>
	    </td>
	  </tr>
	  <tr>
	    <td colspan="4"/>
	  </tr>
        </xsl:for-each> <!-- select="script" -->
	</xsl:if>

      </xsl:for-each> <!-- select="category" -->
    </table>
  </xsl:template> <!-- match=scriptlist -->

  <xsl:template match="desc|thread" mode="scripts">
    <xsl:apply-templates/>
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
