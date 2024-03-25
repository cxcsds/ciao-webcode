<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * support for xHTML-like tags
    * - link tags/support can be found in links.xsl
    *
    * Note there's some pretty ugly use of XSLT here.
    * Some of this can be removed once we use CSS (since handling
    * the style info can be done by that)
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:func="http://exslt.org/functions"
  xmlns:djb="http://hea-www.harvard.edu/~dburke/xsl/"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="exsl func djb extfuncs">

  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-myhtml" select="extfuncs:register-import-dependency('myhtml.xsl')"/>

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

  <!--*
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
	<span class="tt">
	  <xsl:call-template name="add-text-styles-strong">
	    <xsl:with-param name="contents" select="$contents"/>
	  </xsl:call-template>
	</span>
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
      * we allow ul and ol (type=A, a, I, i, or 1)
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
      <xsl:when test="string(@type)='A' or string(@type)='a' or
		      string(@type)='I' or string(@type)='i' or
		      string(@type)='1'">
	<ol type="{@type}">
	  <xsl:apply-templates/>
	</ol>
      </xsl:when>
      <xsl:when test="boolean(@type)">
	<xsl:message terminate="yes">
 ERROR list tag with unknown type='<xsl:value-of select="@type"/>'
	</xsl:message>
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
      *   out where the image actually is
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
      <xsl:otherwise><span class="date">(<xsl:value-of select="$text"/>)</span></xsl:otherwise>
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
      <xsl:if test="boolean(@class)"><xsl:attribute name="class"><xsl:value-of select="@class"/></xsl:attribute></xsl:if>
      <xsl:if test="boolean(@id)"><xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute></xsl:if>
      <xsl:if test="boolean(@style)"><xsl:attribute name="style"><xsl:value-of select="@style"/></xsl:attribute></xsl:if>
      <xsl:choose>
	<xsl:when test="@text='header'"><span class="pheader"><xsl:copy-of select="$contents"/></span></xsl:when>
	<xsl:when test="@text='note'"><span class="qlinkbar"><xsl:copy-of select="$contents"/></span></xsl:when>
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
      * or use their content.
      *
      *-->
  <xsl:template name="add-highlight">
    <xsl:param name="contents" select="''"/>
    <xsl:param name="language" select="'none'"/>

    <!--* yay CSS (although highlight is a poor class name)
	*
	* So, we have an issue here with the processed text here
	* - if there's no processing then we can just copy over
	*   the text and things like '&amp; <foo>xx</foo>' will
	*   get converted.
	* - if styling is added (i.e. language is not 'none') then
	*   we need to disable the output escaping, since we want
	*   tags to be tags (and hope that the actual text will
	*   have been converted correctly, which it should be...)
	*-->
<pre class="highlight"><xsl:choose>
  <xsl:when test="$language='none'"><xsl:copy-of select="$contents"/></xsl:when>
  <xsl:otherwise><xsl:value-of
  select="extfuncs:add-language-styles($language, $contents)"
  disable-output-escaping="yes"/></xsl:otherwise>
</xsl:choose></pre>
  </xsl:template> <!--* name=add-highlight *-->

  <!--*
      * The optional attribute wrap is used to select
      * the text-wrapping behavior. By default it does not
      * wrap (wrap="no") but it can be changed to wrap by setting
      * wrap="yes".
      *
      * Added support for the lang tag. This is used to
      * set up the pygmentize call.
      *-->
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

    <!-- when @lang is used we add both 'screen' and 'screen-<lang>',
         perhaps we should just use the latter but it would mean
         more work with the stylesheets? -->
    <xsl:variable name="classes"><xsl:choose>
      <xsl:when test="boolean(@wrap) and @wrap='yes'">screenwrap</xsl:when>
    <xsl:when test="(boolean(@wrap) and @wrap='no') or not(boolean(@wrap))">screen<xsl:if test="boolean(@lang)"> screen-<xsl:value-of select="@lang"/></xsl:if></xsl:when>
    <xsl:otherwise>
      <xsl:message terminate="yes">
 ERROR: invaling wrap attribute in screen tag: wrap=<xsl:value-of select="@wrap"/>
      </xsl:message>
    </xsl:otherwise></xsl:choose></xsl:variable>

    <!-- what is the language -->
    <xsl:variable name="language"><xsl:choose>
      <xsl:when test="boolean(@lang)"><xsl:value-of select="@lang"/></xsl:when>
      <xsl:otherwise>none</xsl:otherwise>
      </xsl:choose></xsl:variable>

    <div class="{$classes}">
      <xsl:call-template name="add-highlight">
	<xsl:with-param name="contents" select="$contents"/>
	<xsl:with-param name="language" select="$language"/>
      </xsl:call-template>
    </div>
    <!--* <br/> *-->
  
  </xsl:template> <!--* screen *-->

  <!--*
      * add highlighting around the contents of the
      * contents parameter (which can be a node-list)
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

    <!--* yay CSS (although highlight is a poor class name) *-->
<pre class="highlight"><xsl:copy-of select="$contents"/></pre>
  </xsl:template> <!--* name=add-highlight-pre *-->

  <xsl:template name="add-highlight-block">
    <xsl:param name="contents" select="''"/>

    <!--* yay CSS (although highlighttext is a poor class name) *-->
<div class="highlighttext">
<xsl:copy-of select="$contents"/>
</div>
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
<!-- manually copy over the attributes; ugly that special casing this node -->
<xsl:copy-of select="@*" />
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
    <xsl:message terminate="yes">
      Please convert all &lt;center&gt; tags to use CSS.
      <xsl:call-template name="newline"/>
    </xsl:message>
  </xsl:template> <!--* match=center *-->

  <!--*
      * Support math tags:
      *
      * *) "equation"
      *
      *   <math>
      *     <name>...</name>
      *     <latex>...</latex> (latex formula with NO being/end math values)
      *     <text>...</text>   (plain text representation;
      *        if not given then we re-use the latex block)
      * {   <mathml>...</mathml>   (MathML version)   NOT YET IMPLEMENTED    }
      *   </math>
      *
      * *) "inline"
      *
      *    <inlinemath>...</inlinemath>
      *       - at the moment the contents are assumed to be LaTeX format
      *
      * If $use-mathjax = 1:
      *   use the MathJax javascript system - http://www.mathjax.org/ -
      *   for rendering LaTeX, rather than calling out to LaTeX to create
      *   an image (although this may be required to support users who
      *   have JavaScript turned off).
      * otherwise:
      *   PNG files are created by the publishing code
      *
      * Notes:
      * - may want to add attributes that are used to control the created formula
      *
      *-->
  <xsl:template match="math">

    <!--* DTD-style checks *-->
    <xsl:if test="boolean(name)=false() and boolean(latex)=false()">
      <xsl:message terminate="yes">
 Error: math tag is missing at least one of name or latex
 <xsl:value-of select="."/>
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

    <!-- remove spaces from the name; should really clean up other characters
         as it is being used as an id (and possibly a file name) -->
    <xsl:variable name="mathname" select="translate(name, ' ', '')"/>

    <xsl:choose>
      <xsl:when test="$use-mathjax = 1">
	<!--*
	    * We used to (MathJax 2) have a separate preview section but I am
	    * removing this for now.
	    *
	    * TODO: worried about &lt; being converted to <, as seen in the example
	    * thread (possibly some oddities in how expansion happens, since libXSLT
	    * seems to have expanded it in x&lt;y but not x &lt; y ...
	    * Unfortunately, if stick in CDATA then it gets interpreted by the script
	    * tag. From simple tests it doesn't seem to be a problem.
	    *
            * I did try changing the script to just being a div, adding \[ and \]
            * around the value-of select, to turn on the LaTeX support in MathJax,
            * but then it did not hide the MathJax_Preview section, so have
            * decided to leave this as is for now.
	    *-->
	<xsl:choose>
	  <xsl:when test="$mathname = ''">
	    <span class="MathJax-span">\[
<xsl:value-of select="latex"/>
	    \]</span>
	  </xsl:when>
	    <xsl:otherwise>
	    <span id="{$mathname}" class="MathJax-span">\[
<xsl:value-of select="latex"/>
	    \]</span>
	    </xsl:otherwise>
	  </xsl:choose>

	  <!--
          <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
	  <xsl:value-of select="latex"/>
	  <xsl:text disable-output-escaping="yes">]]</xsl:text>
	  <xsl:text disable-output-escaping="yes">></xsl:text>
	  -->
      </xsl:when>

      <xsl:otherwise>
	<!--*
	    * create the latex document
	    * - could allow the fg/bg colors to be set with attributes
	    * - apparently xsl:document will nest
	    * - need to remove leading/trailing whitespace so that
	    *   latex doesn't complain
	    *-->
	<xsl:document href="{concat($sourcedir,$mathname,'.tex')}" method="text">
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
	<img id="{$mathname}" src="{$mathname}.png"><xsl:attribute name="alt"><xsl:choose>
	  <xsl:when test="boolean(text)"><xsl:value-of select="text"/></xsl:when>
	  <xsl:otherwise><xsl:value-of select="normalize-space(latex)"/></xsl:otherwise>
	</xsl:choose></xsl:attribute></img>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template> <!--* match=math *-->

  <!-- There is no attempt to expand the contents; they are just passed straight through -->
  <xsl:template match="inlinemath">
    <xsl:value-of select="concat('\(', ., '\)')"/>
  </xsl:template> <!--* match=inlinemath *-->

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

  <!-- strip out the intro tag -->
  <xsl:template match="intro">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * from Chris Stawarz's download-script code
      * - mangled since we now have to interpret all
      *   the tags that Chris was able to use
      *
      * The styleing for this now uses CSS grids to layout the
      * sections.
      *-->
  <xsl:template match="scriptlist">

    <!-- make the navigation links -->
    <div style="text-align: center;">
      <p>
	<xsl:for-each select="category">
	  <a href="{concat('#',translate(@name,' ',''))}"><xsl:value-of select="@name"/></a>
	  <xsl:if test="position() != last()"><xsl:text> | </xsl:text></xsl:if>
	</xsl:for-each> <!-- select="category" -->
      </p>
    </div>

    <xsl:for-each select="category">
      
      <h3 class="scriptsection"
	  id="{translate(@name,' ','')}"><xsl:value-of select="@name"/></h3>

      <xsl:if test="boolean(intro)">
        <div class="scriptintro">
          <xsl:apply-templates select="intro"/>
        </div>
      </xsl:if>

      <xsl:for-each select="script">

	<xsl:variable name="classname">scriptitem<xsl:choose>
	    <xsl:when test="thread">3</xsl:when>
	    <xsl:otherwise>2</xsl:otherwise>
	</xsl:choose></xsl:variable>
	<div class="{$classname}">

	  <div class="scriptname"><strong><xsl:apply-templates select="name" mode="scripts"/></strong></div>
	  <div class="scriptinfo"><xsl:apply-templates select="desc" mode="scripts"/></div>
	  
	  <xsl:if test="thread">
	    <div class="scriptthread">
	      <xsl:text>Thread: </xsl:text> <xsl:apply-templates select="thread" mode="scripts"/>
	    </div>
	  </xsl:if>
	</div>

      </xsl:for-each>
    </xsl:for-each>
    
  </xsl:template> <!-- match=scriptlist -->

  <xsl:template match="name|desc|thread" mode="scripts">
    <xsl:apply-templates/>
  </xsl:template> <!-- match=name|desc|thread mode=scripts -->

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
        for script=<xsl:value-of select="@name"/>

	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!-- name="get-month" -->

  <!-- * Docbook-like admonitions; rather than have separate tags use a single
       * tag and use an attribute to determine the type of admonition.
       *
       * Valid values for @type are
       *     caution important note tip warning
       * or the type attribute can be left out.
       *
       * I had originally followed the docbook style sheet and used
       * the background-image CSS attribute on the div.*-inner block
       * to set the icon. However, this is likely ignored by the
       * media print (browser option), so explicitly adding the
       * image.
       *-->

  <xsl:variable name="allowed-annotations" select="' caution important note tip warning  '"/>

  <xsl:template match="admonition[@type]">
    <xsl:if test="not(contains($allowed-annotations, concat(' ', @type, ' ')))">
      <xsl:message terminate="yes">
 ERROR: admonition found with unsupported type=<xsl:value-of select="@type"/>
   allowed values: <xsl:value-of select="$allowed-annotations" />
      </xsl:message>
    </xsl:if>

    <div>
      <xsl:attribute name="class">admonition <xsl:value-of select="@type"/></xsl:attribute>
      <div>
	<xsl:attribute name="class"><xsl:value-of select="concat(@type, '-inner')"/></xsl:attribute>
	<xsl:call-template name="add-admonition-image"/>

	<!-- Title handling should be cleaned up -->
	<xsl:choose>
	  <xsl:when test="boolean(title)">
	    <xsl:apply-templates select="title" mode="admonition"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <div class="title">
	      <span class="title">
		<xsl:choose>
		  <xsl:when test="@type='caution'">Caution</xsl:when>
		  <xsl:when test="@type='important'">Important</xsl:when>
		  <xsl:when test="@type='note'">Note</xsl:when>
		  <xsl:when test="@type='tip'">Tip</xsl:when>
		  <xsl:when test="@type='warning'">Warning</xsl:when>
		  <xsl:otherwise>
		    <xsl:message terminate="yes">
 Internal error: unexpected type=<xsl:value-of select="@type"/> when processing
   admonition block with no title.
		    </xsl:message>
		  </xsl:otherwise>
		</xsl:choose>
	      </span>
	    </div>
	  </xsl:otherwise>
	</xsl:choose>
	<xsl:apply-templates select="*[name()!='title']"/>
      </div>
    </div>

  </xsl:template> <!-- match=admonition/@type -->

  <xsl:template match="admonition">
    <div class="admonition">
	<xsl:apply-templates select="title" mode="admonition"/>
	<xsl:apply-templates select="*[name()!='title']"/>
    </div>
  </xsl:template> <!-- match=admonition -->

  <xsl:template match="title" mode="admonition">
    <div class="title">
      <span class="title"><xsl:apply-templates/></span>
    </div>
  </xsl:template> <!-- match=title mode=admonition -->

  <!--* Add an an image tag for the admonition -->
  <xsl:template name="add-admonition-image">
    <xsl:if test="boolean(@type)">
      <!--*
	  * TODO: do we want to add a class to this?
	  *-->
      <xsl:call-template name="add-image">
	<xsl:with-param name="src" select="concat('imgs/', @type,'.png')"/>
	<xsl:with-param name="alt" select="translate(@type, 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template> <!-- name=add-admonition-image -->

  <!--* 
      * The figure environment, moved from threads.
      *
      * Since there is no support for auto-generating a table-of-contents
      * for the general-purpose pages, the TOC code is left in thread_common.xsl.
      *-->

  <!--*
      * Handle figlink tags.
      *   - no contents -> use "Figure <num>" (even if have @nonumber tag)
      *   - contents and no @nonumber attribute -> append " (Figure <num>)"
      *   - otherwise -> contents
      *
      *   Actually, only include the figure number for threads, even if
      *   the @nonumber tag is not given.
      *
      * NOTE:
      *    check on empty contents as normalize-space(.)='' is not ideal
      *    but should work (would probably only fail if we used an empty tag like
      *     <figlink><foo/></figlink> which is unlikely to happen)
      *-->
  <xsl:template match="figlink[boolean(@id)=false]">
    <xsl:message terminate="yes">
 ERROR: figlink tag found with no id attribute
    contents=<xsl:value-of select="."/>
    </xsl:message>
  </xsl:template>

  <xsl:template match="figlink[(boolean(@nonumber) or name(//*) != 'thread') and normalize-space(.)!='']">
    <xsl:call-template name="check-fig-id-exists">
      <xsl:with-param name="id" select="@id"/>
    </xsl:call-template>
    <a href="{concat('#',@id)}"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="figlink[normalize-space(.)='']">
    <xsl:call-template name="check-fig-id-exists">
      <xsl:with-param name="id" select="@id"/>
    </xsl:call-template>
    <xsl:if test="name(//*) != 'thread'">
      <xsl:message terminate="yes">
 ERROR: figlink element can not be empty in a non-thread page.
      </xsl:message>
    </xsl:if>
    <xsl:variable name="pos" select="djb:get-figure-number(@id)"/>
    <a href="{concat('#',@id)}"><xsl:value-of select="concat('Figure ',$pos)"/></a>
  </xsl:template>

  <xsl:template match="figlink">
    <xsl:call-template name="check-fig-id-exists">
      <xsl:with-param name="id" select="@id"/>
    </xsl:call-template>
    <xsl:variable name="pos" select="djb:get-figure-number(@id)"/>
    <a href="{concat('#',@id)}"><xsl:apply-templates/><xsl:value-of select="concat(' (Figure ',$pos,')')"/></a>
  </xsl:template>

  <!--*
      * This is called when processing figlink tags.
      *-->
  <xsl:template name="check-fig-id-exists">
    <xsl:param name="id" select="''"/>
    <xsl:if test="$id = ''">
      <xsl:message terminate="yes">
 ERROR: check-fig-id-exists called with an empty id argument.
      </xsl:message>
    </xsl:if>

    <xsl:variable name="nmatches" select="count(//figure[@id=$id])"/>
    <xsl:choose>
      <xsl:when test="$nmatches=1"/>
      <xsl:when test="$nmatches=0">
	<xsl:message terminate="yes">
 ERROR: there is no figure with an id of '<xsl:value-of select="$id"/>'.
	</xsl:message>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
 ERROR: there are multiple (<xsl:value-of select="$nmatches"/>) figures with an id of '<xsl:value-of select="$id"/>'.
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=check-fig-id-exists *-->

  <!--*
      * helper routine to get the number of the figure.
      * TODO: this only really works for single-page
      * documents, like the thread environment where it
      * originated, and not multi-page ones like
      * dictionaries
      *-->
  <func:function name="djb:get-figure-number">
    <xsl:param name="id" select="''"/>
    <xsl:if test="$id=''">
      <xsl:message terminate="yes">
 ERROR: djb:get-figure-number called with no argument
      </xsl:message>
    </xsl:if>
    <func:result><xsl:value-of select="exsl:node-set($figlist)/figure[@id=$id]/@pos"/></func:result>
  </func:function>

  <!--* This is used to map from @id to figure number *-->
  <xsl:variable name="figlist">
    <xsl:for-each select="//figure">
      <figure id="{@id}" pos="{position()}"/>
    </xsl:for-each>
  </xsl:variable>

  <!--*
      * helper routine to create the figure title. It must be
      * called with the figure block as the context node.
      *
      * NOTE:
      *   automatic figure numbering only happens for threads.
      *-->
  <func:function name="djb:make-figure-title">
    <xsl:param name="pos" select="''"/>
    <xsl:if test="$pos=''">
      <xsl:message terminate="yes">
 ERROR: djb:make-figure-title called with no argument
      </xsl:message>
    </xsl:if>
    <xsl:if test="name()!='figure'">
      <xsl:message terminate="yes">
 ERROR: djb:make-figure-title must be called with a figure node as the context node
      </xsl:message>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="name(//*) = 'thread'">
	<func:result><xsl:value-of select="concat('Figure ',$pos)"/><xsl:if test="boolean(title)">
	<xsl:text>: </xsl:text>
	<xsl:apply-templates select="title" mode="title-parsing"/>
	</xsl:if></func:result>
      </xsl:when>
      <xsl:when test="boolean(title)">
	<func:result><xsl:apply-templates select="title" mode="title-parsing"/></func:result>
      </xsl:when>
      <xsl:otherwise/> <!-- just return nothing -->
    </xsl:choose>
  </func:function>

  <!--*
      * Warn if any other element in the document has an id element that
      * matches. This is intended to catch those cases where a figure
      * environment has inadvertently used the same id as a section,
      * but could be made more general.
      *
      * At present this is not an error because
      *   - it is being added at releasre time and so I do not
      *     want to slow down the documentation effort
      *   - it may have unintended consequences (i.e. false positives)
      *     so it needs to be evaluated first
      *
      * Aha, one probelm with this approach is that the system uses id
      * as an attribute both to name an anchor and to refer to it - e.g.
      *   figure id=... and then figlink id=...
      * which means that this has to become specialized to only those
      * elements for which it is used as an anchor. This is not ideal
      * since I don't have such a list easily at hand!
      *-->
  <xsl:template name="ensure-unique-id">
    <xsl:param name="id" select="''"/>
    <xsl:if test="$id = ''">
      <xsl:message terminate="yes">
 ERROR: check-fig-id-exists called with an empty id argument.
      </xsl:message>
    </xsl:if>

    <!-- <xsl:variable name="nmatches" select="count(//*[@id=$id])"/> -->
    <xsl:variable name="nfig" select="count(//figure[@id=$id])"/>
    <xsl:variable name="nsec" select="count(//section[@id=$id])"/>
    <xsl:variable name="nsub" select="count(//subsection[@id=$id])"/>
    <xsl:variable name="nsubsub" select="count(//subsubsection[@id=$id])"/>
    <xsl:variable name="nmatches" select="$nfig + $nsec + $nsub + $nsubsub"/>
    <xsl:choose>
      <xsl:when test="$nmatches=1"/>
      <xsl:when test="$nmatches>1">
        <xsl:message terminate="no">
 WARNING: there are <xsl:value-of select="$nmatches"/> elements with id=<xsl:value-of select="$id"/>
   Please check, since Doug believes they should be unique (or this check is wrong)
        </xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="no">
 WARNING: ensure-unique-id has found no matches for elements with id=<xsl:value-of select="$id"/>
   which suggests Doug's code is wrong. Please tell him.
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=ensure-unique-id *-->

  <!--*
      * This is ugly; do we handle this better in other parts of the system?
      * (we need a different mode since there must be an explicit title template
      * somewhere that ignores the content, presumably to handle
      * section/subsection/subsubsection title elements).
      *
      * I added this so that we could include some mark up in the title element of
      * figures, but so far it does not seem to actually do this.
      *-->
  <xsl:template match="title" mode="title-parsing">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * Figure support
      *
      *  
      *  <figure id="foo">
      *    <title>blah blah blah</title>
      *    <caption>
      *      <p>Yay a caption.</p>
      *      <p>With more text.</p>
      *    </caption>
      *  
      *    <description>Short alt text</description>
      *    <bitmap format="png">foo.grab.png</bitmap>
      *    <bitmap format="png" thumbnail="1">foo.grab.png</bitmap>
      *    <bitmap format="png" hardcopy="1">foo.png</bitmap>
      *    <vector format="pdf">foo.pdf</bitmap>
      *  </figure> 
      *
      *
      * In the XPath expressions below I am not 100% convinced I need
      *    a[boolean(@b)]
      * rather than
      *    a[@b]
      * but I think I have seen issues with this in libxslt (ie changes in
      * behavior) so trying to be more explicit.
      *
      * NOTE:
      *   automatic numbering of figures, and inclusion in the TOC, is only
      *   for threads (i.e. documents with a root node of 'thread').
      *-->
  <xsl:template match="figure">

    <!--* simple validation *-->
    <xsl:if test="boolean(@id)=false()">
      <xsl:message terminate="yes">
 ERROR: figure block does not contain an id attribute
      </xsl:message>
    </xsl:if>

    <xsl:call-template name="ensure-unique-id">
      <xsl:with-param name="id" select="@id"/>
    </xsl:call-template>   

    <xsl:if test="boolean(description)=false()">
      <xsl:message terminate="yes">
 ERROR: figure (id=<xsl:value-of select="@id"/>) does not contain a description tag
      </xsl:message>
    </xsl:if>

    <xsl:variable name="bmap-simple" select="bitmap[(boolean(@thumbnail)=false() or @thumbnail='0')
					     and (boolean(@hardcopy)=false() or @hardcopy='0')]"/>
    <xsl:variable name="bmap-thumb"  select="bitmap[boolean(@thumbnail)=true() and @thumbnail='1']"/>
    <xsl:variable name="bmap-hard"   select="bitmap[boolean(@hardcopy)=true() and @hardcopy='1']"/>

    <xsl:variable name="num-bmap-simple" select="count($bmap-simple)"/>
    <xsl:variable name="num-bmap-thumb"  select="count($bmap-thumb)"/>
    <xsl:variable name="num-bmap-hard"   select="count($bmap-hard)"/>

    <!--* safety checks as do not have a scheme for this environment *-->
    <xsl:if test="$num-bmap-thumb > 1">
      <xsl:message terminate="yes">
 ERROR: expected 0 or 1 bitmap nodes with a thumbnail attribute set to 1,
   but found <xsl:value-of select="$num-bmap-thumb"/> for figure id=<xsl:value-of select="@id"/>
      </xsl:message>
    </xsl:if>
    <xsl:if test="$num-bmap-hard > 1">
      <xsl:message terminate="yes">
 ERROR: expected 0 or 1 bitmap nodes with a hardcopy attribute set to 1,
   but found <xsl:value-of select="$num-bmap-hard"/> for figure id=<xsl:value-of select="@id"/>
      </xsl:message>
    </xsl:if>
    <xsl:if test="$num-bmap-simple > 1">
      <xsl:message terminate="yes">
 ERROR: expected 0 or 1 bitmap nodes with either no thumbnail and hardcopy attributes
   or with them set to 0 but found <xsl:value-of select="$num-bmap-simple"/> for figure id=<xsl:value-of select="@id"/>
      </xsl:message>
    </xsl:if>
    <xsl:if test="$num-bmap-simple = 0 and $num-bmap-hard = 0">
      <xsl:message terminate="yes">
 ERROR: no "basic" bitmap node found for display for figure id=<xsl:value-of select="@id"/>
      </xsl:message>
    </xsl:if>

    <xsl:variable name="has-bmap-simple" select="$num-bmap-simple = 1"/>
    <xsl:variable name="has-bmap-thumb" select="$num-bmap-thumb = 1"/>
    <xsl:variable name="has-bmap-hard" select="$num-bmap-hard = 1"/>

    <xsl:variable name="num-title" select="count(title)"/>

    <!--* work out the figure number/title *-->
    <xsl:variable name="pos" select="djb:get-figure-number(@id)"/>
    <xsl:variable name="title"><xsl:value-of select="djb:make-figure-title($pos)"/></xsl:variable>

    <!--*
        * Display the HTML figure caption?
	*-->

    <div id="{@id}" class="figure">
      <xsl:if test="$num-title != 0">
	  <div class="caption screenmedia">
	    <h3><xsl:value-of select="$title"/></h3>
	  </div>
      </xsl:if>

	  <div>
	    <!--* do we need this class attribute, as it is only meaningful for screen media? *-->
	    <xsl:attribute name="class"><xsl:choose>
	      <xsl:when test="$has-bmap-thumb">thumbnail</xsl:when>
	      <xsl:otherwise>nothumbnail</xsl:otherwise>
	    </xsl:choose></xsl:attribute>

	    <xsl:variable name="img-code">
	      <img>

		<xsl:attribute name="alt"><xsl:choose>
		  <xsl:when test="$has-bmap-thumb">
		    <xsl:value-of select="concat('[Thumbnail image: ',normalize-space(description),']')"/>
		  </xsl:when>
		  <xsl:otherwise>
		    <xsl:value-of select="concat('[',normalize-space(description),']')"/>
		  </xsl:otherwise>
		</xsl:choose></xsl:attribute>

		<xsl:attribute name="src"><xsl:choose>
		  <xsl:when test="$has-bmap-thumb"><xsl:value-of select="$bmap-thumb"/></xsl:when>
		  <xsl:when test="$has-bmap-simple"><xsl:value-of select="$bmap-simple"/></xsl:when>
		  <xsl:when test="$has-bmap-hard"><xsl:value-of select="$bmap-hard"/></xsl:when>
		  <xsl:otherwise>
		    <xsl:message terminate="yes">
 ERROR: internal error choosing image; apparently no images to use (img-code)
		    </xsl:message>
		  </xsl:otherwise>
		</xsl:choose></xsl:attribute>
	      </img>
	    </xsl:variable>

	    <div class="screenmedia">
	      <xsl:choose>
		<xsl:when test="$has-bmap-thumb">
		  <a>
		    <xsl:attribute name="href"><xsl:choose>
		      <xsl:when test="$has-bmap-simple"><xsl:value-of select="$bmap-simple"/></xsl:when>
		      <xsl:when test="$has-bmap-hard"><xsl:value-of select="$bmap-hard"/></xsl:when>
		      <xsl:otherwise>
			<xsl:message terminate="yes">
 ERROR: internal error choosing image; apparently no images to use (screenmedia)
			</xsl:message>
		      </xsl:otherwise>
		    </xsl:choose></xsl:attribute>
		    <xsl:copy-of select="$img-code"/>
		  </a>
		</xsl:when>
		<xsl:otherwise>
		  <xsl:copy-of select="$img-code"/>
		</xsl:otherwise>
	      </xsl:choose>

	      <!--*
		  * Process the images to create a set of nodes that detail the
		  * available versions, then process that. Only useful in the
		  * screen media version.
		  *-->
	      <xsl:variable name="versions">
		<flinks>
		  <xsl:apply-templates select="bitmap" mode="list-figure-versions"/>
		  <xsl:apply-templates select="vector" mode="list-figure-versions"/>
		</flinks>
	      </xsl:variable>
	      <xsl:apply-templates select="exsl:node-set($versions)" mode="add-figure-versions"/>
	    </div>

	    <div class="printmedia">
	      <img alt="{concat('[Print media version: ',normalize-space(description),']')}">
		<xsl:attribute name="src"><xsl:choose>
		  <xsl:when test="$has-bmap-hard"><xsl:value-of select="$bmap-hard"/></xsl:when>
		  <xsl:otherwise><xsl:value-of select="$bmap-simple"/></xsl:otherwise>
		</xsl:choose></xsl:attribute>
	      </img>

<!--* unfortunately neither the img tag or the object tag works for ps/pdf output,
    * at least on Firefox 2.0.0.14 on OS-X Intel
    * (seeing some bizarre issues so not 100% convinced about this, but not implementing
    *  it for now as I doubt it works reliably)
    *
	      <xsl:if test="vector[@format='ps']">
		<img alt="POSTSCRIPT HACK" src="{normalize-space(vector[@format='ps'])}"/>
		<object data="{normalize-space(vector[@format='ps'])}" type="application/ps">
		  POSTSCRIPT HACK VIA OBJECT
		</object>
	      </xsl:if>
	      <xsl:if test="vector[@format='pdf']">
		<img alt="PDF HACK" src="{normalize-space(vector[@format='pdf'])}"/>
		<object data="{normalize-space(vector[@format='pdf'])}" type="application/pdf">
		  PDF HACK VIA OBJECT
		</object>
	      </xsl:if>
*-->

	    </div>

	  </div>

	  <!--// Figure title placement depends on mediatype //-->
      <xsl:if test="$num-title != 0">
	  <h3 class="caption printmedia"><xsl:value-of select="$title"/></h3>
      </xsl:if>

	  <xsl:if test="caption">
	  <div class="caption">
	    <xsl:apply-templates select="caption" mode="figure"/>
	  </div>
	  </xsl:if>
	</div> <!--* class=figure *-->

	<!--* I want to remove the float behavior, so I add in an ugly empty div *-->
	<xsl:if test="$has-bmap-thumb">
	  <div class="clearfloat"/>
	</xsl:if>

  </xsl:template> <!--* match=figure *-->

  <!--*
      * process the contents of a figure environment to return a list
      * of versions of the figure for use in the on-screen/HTML
      * display - ie the "[versions: full-size, postscript, pdf]"
      * link.
      *
      * We want the bitmap images if:
      *   - hardcopy = 1
      *   - no hardcopy or thumbnail attributes but only when
      *     there is also a bitmap[@thumbnail=1] version
      *
      * The checks should be enforced by a schema, but we do not
      * do this yet (if we are ever going to do it). They could/should
      * be done elsewhere, but we do them here as it is easy to do
      * so.
      *
      * TODO:
      *    we should really re-order items so that we can
      *    ensure the "full-size bitmap" link is first
      *-->
  <xsl:template match="bitmap[boolean(@hard)]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: bitmap node found with attribute name of hard rather than hardcopy
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>
  <xsl:template match="bitmap[boolean(@thumb)]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: bitmap node found with attribute name of thumb rather than thumbnail
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>
  <xsl:template match="vector[boolean(@hard) or boolean(@hardcopy)]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: vector node found with hardcopy (or hard) attribute. Not needed here!
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>
  <xsl:template match="vector[boolean(@thumbnail) or boolean(@thumb)]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: vector node found with thumbnail (or thumb) attribute. Not needed here!
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>

  <xsl:template match="bitmap[@thumbnail=1 and @hardcopy=1]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: bitmap nodes must not have both thumbail and hardcopy attributes set to 1
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>
  <xsl:template match="bitmap[boolean(@format)=false()]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: bitmap nodes must contain a format attribute
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>
  <xsl:template match="vector[boolean(@format)=false()]" mode="list-figure-versions">
    <xsl:message terminate="yes">
 ERROR: vector nodes must contain a format attribute
   value=<xsl:value-of select="normalize-space(.)"/>
    </xsl:message>
  </xsl:template>

  <xsl:template match="bitmap[@thumbnail=1]" mode="list-figure-versions"/>
  <xsl:template match="bitmap[@hardcopy=1]" mode="list-figure-versions">
    <flink>
      <text><xsl:value-of select="translate(@format,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/></text>
      <image><xsl:value-of select="normalize-space(.)"/></image>
    </flink>
  </xsl:template>
  <xsl:template match="bitmap[(@thumbnail=0 or (boolean(@thumbnail)=false() and boolean(@hardcopy)=false())) and
		       (count(preceding-sibling::bitmap[@thumbnail=1]) != 0 or
		       count(following-sibling::bitmap[@thumbnail=1]) != 0)]" mode="list-figure-versions">
    <flink><text>full-size</text><image><xsl:value-of select="normalize-space(.)"/></image></flink>
  </xsl:template>
  <xsl:template match="vector[@format='ps']" mode="list-figure-versions">
    <flink><text>postscript</text><image><xsl:value-of select="normalize-space(.)"/></image></flink>
  </xsl:template>
  <xsl:template match="vector[@format='eps']" mode="list-figure-versions">
    <flink><text>encapsulated postscript</text><image><xsl:value-of select="normalize-space(.)"/></image></flink>
  </xsl:template>
  <xsl:template match="vector[@format='pdf']" mode="list-figure-versions">
    <flink><text>PDF</text><image><xsl:value-of select="normalize-space(.)"/></image></flink>
  </xsl:template>
  <xsl:template match="*|text()" mode="list-figure-versions">
<!--
    <xsl:message terminate="yes">
 ERROR: match=*|text() mode=list-figure-versions template has been called!
        node=<xsl:value-of select="name()"/> contents=<xsl:value-of select="."/>
    </xsl:message>
-->
  </xsl:template>

  <xsl:template match="flinks[count(flink)=0]" mode="add-figure-versions"/>
  <xsl:template match="flinks" mode="add-figure-versions">
    <p class="figures"><xsl:text>[Version: </xsl:text>
    <xsl:for-each select="flink">
      <a href="{image}"><xsl:value-of select="text"/></a>
      <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
    </xsl:for-each>
    <xsl:text>]</xsl:text></p>
  </xsl:template>

  <!--*
      * Create the caption for a figure; may not need the mode, but leave in for now
      *-->
  <xsl:template match="caption" mode="figure">
    <xsl:apply-templates/>
  </xsl:template> <!--* match=caption mode=figure *-->

  <!--*
         * Handle section/subsections/subsubsections (getting a little
	 * crazy)
	 *
	 * This used to be in threads, but has now been moved here so
	 * that it can be used in any document.
	 *
	 *-->

  <!--*
      * Create the text from the sectionlist contents
      * Sections are given a H2 title - ie not included
      * in a list.
      *
      * see the amazing hack to find out when we're in the last
      * section, and so do not draw a HR...
      * It works like this: we define a parameter whose name matches
      * the id of the last section. This is passed to the
      * section template, which only prints out a HR if the id's
      * don't match.
      *
      * We add numbers to the labels IF /*/text/@number=1
      * the "thing" used to denote separation between the sections is controlled
      * by /*/text/@separator: default = "bar", can be "none"
      *
      * See the note at the top of the file: the text/@number
      * attribute should be removed and handled by @type attribute
      * on the sectionlist
      *-->

  <xsl:template match="sectionlist">

    <xsl:if test="boolean(@type)">
      <xsl:message>
 WARNING: sectionlist has type attribute set to <xsl:value-of select="@type"/>
    WE NEED TO UPDATE THE CODE TO HANDLE THIS
      </xsl:message>
    </xsl:if>

    <div class="sectionlist">
      <!--* anchor linked to from the overview section *-->
      <xsl:if test="boolean(/thread/text/overview)">
	<xsl:attribute name="id">start-thread</xsl:attribute>
      </xsl:if>

      <xsl:variable name="last" select="section[position()=count(../section)]/@id"/>
      <xsl:call-template name="add-sections">
	<xsl:with-param name="last-section-id" select="$last"/>
      </xsl:call-template>
    </div>

  </xsl:template> <!--* match=sectionlist *-->

  <!--*
      * Find the label for each section: used by both the TOC
      * and main part of the context.
      *-->
  <xsl:template name="find-section-label">
    <xsl:if test="/*/text/@number=1"><xsl:value-of select="position()"/><xsl:text> - </xsl:text></xsl:if>
    <xsl:value-of select="title"/>
  </xsl:template>

  <!--*
      * Process all the sections: being updated to be generic rather
      * than assume that the page is a thread.
      *
      * if threadlink attribute exists then we create a little
      * section
      *
      * we only draw a horizontal bar after the last section
      * if there's a summary. This is getting hacky/complicated
      * and needs a redesign. It's really complicated since
      * we only now draw HR's if
      *   /*/text/@separator = "bar" (the default value),
      *   it can also be "none"
      *
      * We add numbers to the labels IF /*/text/@number=1
      *
      *-->
  <xsl:template name="add-sections">
    <xsl:param name="last-section-id" select='""'/>

    <xsl:for-each select="section">
      <xsl:variable name="titlestring"><xsl:call-template name="find-section-label"/></xsl:variable>

      <section class="section">
      <xsl:choose>
	<xsl:when test="boolean(@threadlink)">
	  <xsl:call-template name="add-section-threadlink">
	    <xsl:with-param name="threadlink" select="@threadlink"/>
	    <xsl:with-param name="titlestring" select="$titlestring"/>
	  </xsl:call-template>
	</xsl:when>
	<xsl:otherwise>
	  <!-- should this look for not(boolean(@id))?> if so, many
	       pages will fail -->
	  <xsl:if test="@id = ''">
	    <xsl:message terminate="yes">
ERROR: section tag has an empty id attribute.
	    </xsl:message>
	  </xsl:if>

	  <xsl:choose>
	    <xsl:when test="$titlestring = ''">
	      <xsl:message terminate="no">WARNING: missing title for section. Probably do not want this</xsl:message>
	    </xsl:when>
	    <xsl:otherwise>
	      <h2>
		<xsl:if test="boolean(@id)">
		  <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
		</xsl:if>
	        <xsl:value-of select="$titlestring"/>
	      </h2>
	    </xsl:otherwise>
	  </xsl:choose>

	  <!-- need to hide the title block; as I am not sure if I depend on
	       the title block being processed in other cases, I don't want
	       to add a template to just ignore title blocks. Similarly,
	       I don't want to add a mode here since the contents are
	       generic.
	    -->
	  <xsl:apply-templates select="*[name() != 'title']"/>
	  
	</xsl:otherwise>
      </xsl:choose>

      <xsl:call-template name="add-section-separator">
	<xsl:with-param name="titlestring" select="$titlestring"/>
	<xsl:with-param name="last-section-id" select="$last-section-id"/>
      </xsl:call-template>
      
    </section> <!--* class=section *-->
    </xsl:for-each>
    
  </xsl:template> <!--* name=add-sections *-->

  <!-- add in a section that links to the given thread -->
  <xsl:template name="add-section-threadlink">
    <xsl:param name="threadlink"/>
    <xsl:param name="titlestring" select="''"/>

    <xsl:variable name="linkThread" select="document(concat($threadDir,'/',$threadlink,'/thread.xml'))"/>
    <xsl:variable name="linkTitle"><xsl:choose>
      <xsl:when test="boolean($linkThread//thread/info/title/long)">
	<xsl:value-of select="$linkThread//thread/info/title/long"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$linkThread//thread/info/title/short"/>
      </xsl:otherwise>
    </xsl:choose></xsl:variable>

    <!--* warning message *-->
    <!--* TODO: dependency tracking should be used here -->
    <xsl:if test="$linkTitle = ''">
      <xsl:message>

 WARNING: The "<xsl:value-of select="$titlestring"/>" section will be
   missing the link text since the <xsl:value-of select="$threadlink"/> thread
   has not been published.

      </xsl:message>
    </xsl:if>

    <h2 id="{$threadlink}"><xsl:value-of select="$titlestring"/></h2>
    <p>
      Please follow the
      "<a href="{concat('../',@threadlink,'/')}"><xsl:value-of select="$linkTitle"/></a>"
      thread.
    </p>
  </xsl:template> <!--* add-section-threadlink *-->

  <!--*
         * Are the sections separated by a horizontal rule/other
	 * separator?
	 *
	 * Requires:
	 *   the context node to have an id attribute.
	 *-->
  <xsl:template name="add-section-separator">
    <xsl:param name="last-section-id" select='""'/>

    <xsl:param name="titlestring" select="''"/>

    <xsl:choose>
      <xsl:when test="not(/*/text/@separator) or /*/text/@separator = 'bar'">
	<xsl:if test="@id != $last-section-id">
	  <hr/>
	</xsl:if>
      </xsl:when>
      <xsl:when test="/*/text/@separator = 'none'"/>
      <xsl:otherwise>
	<xsl:message terminate="yes">

 ERROR: separator attribute of /*/text is set to
          <xsl:value-of select="/*/text/@separator"/>
        when it must either not be set or be either bar or none

	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:template> <!--* name=add-section-seaparator *-->

  <!--*
      * "fake" the numbered/alphabetical lists
      *
      * use the $type parameter to work out what sort of list
      * and then calculate the position
      * [we use a parameter rather than access the context node as
      *  we can not guarantee what the context node is]
      *
      * Also handles a missing @type attribute (which does nothing)
      *
      *-->
  <xsl:template name="position-to-label">
    <xsl:param name="type" select="''"/>

    <xsl:variable name="alphabet">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>

    <xsl:choose>
      <xsl:when test="not($type) or $type = ''"/> <!--* do nothing *-->
      <xsl:when test="$type = '1'">
	<xsl:value-of select="concat(position(),'. ')"/>
      </xsl:when>
      <xsl:when test="$type = 'A'">
	<xsl:if test="position() > string-length($alphabet)">
	  <xsl:message terminate="yes">
 ERROR: too many items in the list for @type=A
	  </xsl:message>
	</xsl:if>
	<xsl:value-of select="concat(substring($alphabet,position(),1),'. ')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
 ERROR:
   unrecognised @type=<xsl:value-of select="$type"/>
   in node=<xsl:value-of select="name()"/>
   contents=
<xsl:value-of select="."/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> <!--* name=position-to-label *-->

  <!--*
      * process a subsectionlist
      * 
      * Parameters:
      * 
      *-->
  <xsl:template match="subsectionlist">

    <!--*
        * need to store as a variable since we have changed
        * context node by the time we come to use it
        *-->
    <xsl:variable name="type" select="@type"/>

    <div class="subsectionlist">

      <!--* use a pull-style approach *-->
      <xsl:for-each select="subsection">

	<xsl:variable name="titlestr">
	  <xsl:call-template name="position-to-label">
	    <xsl:with-param name="type" select="$type"/>
	    </xsl:call-template><xsl:value-of select="title"/>
	</xsl:variable>

	<!--* process each subsection *-->
	<xsl:call-template name="internal-subsection">
	  <xsl:with-param name="classname">subsection</xsl:with-param>
	  <xsl:with-param name="title" select="$titlestr"/>
	  <xsl:with-param name="header">h3</xsl:with-param>
	</xsl:call-template>

      </xsl:for-each>

    </div> <!--* class=subsectionlist *-->

  </xsl:template> <!--* match=subsectionlist *-->

  <xsl:template name="internal-subsection">
    <xsl:param name="classname"/>
    <xsl:param name="title"/>
    <xsl:param name="header"/>

    <!--*
	* process each "section"
	* - if there is a title block then we use a section element,
	*   otherwise it's a plain div.
	*-->
    <xsl:variable name="element"><xsl:choose>
      <xsl:when test="count(child::title) = 0">div</xsl:when>
      <xsl:otherwise>section</xsl:otherwise>
    </xsl:choose></xsl:variable>

    <xsl:element name="{$element}">
      <xsl:attribute name="class"><xsl:value-of select="$classname"/></xsl:attribute>
      <xsl:element name="{$header}">
	<xsl:if test="boolean(@id)">
	  <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
	</xsl:if>
	<xsl:value-of select="$title"/>
      </xsl:element>

      <!-- need to hide the title block; as I am not sure if I depend on
	   the title block being processed in other cases, I don't want
	   to add a template to just ignore title blocks. Similarly,
	   I don't want to add a mode here since the contents are
	   generic.
      -->
      <xsl:apply-templates select="*[name() != 'title']"/>

      <!--* we only add a hr if we are NOT the last subsection
	  (and hr's are allowed) *-->
      <xsl:if test="position() != last() and (not(/*/text/@separator) or /*/text/@separator = 'bar')">
	<xsl:call-template name="add-mid-sep"/>
      </xsl:if>

    </xsl:element>

  </xsl:template> <!--* name=internal-subsection *-->

  <!--*
      * process a subsubsectionlist
      *
      * Parameters:
      *
      *-->
  <xsl:template match="subsubsectionlist">

    <!--*
        * need to store as a variable since we have changed
        * context node by the time we come to use it
        *-->
    <xsl:variable name="type" select="@type"/>

    <div class="subsubsectionlist">

      <!--* use a pull-style approach *-->
      <xsl:for-each select="subsubsection">

	<xsl:variable name="titlestr">
	  <xsl:call-template name="position-to-label">
	    <xsl:with-param name="type" select="$type"/>
	    </xsl:call-template><xsl:value-of select="title"/>
	</xsl:variable>

	<!--* process each subsection *-->
	<xsl:call-template name="internal-subsection">
	  <xsl:with-param name="classname">subsubsection</xsl:with-param>
	  <xsl:with-param name="title" select="$titlestr"/>
	  <xsl:with-param name="header">h4</xsl:with-param>
	</xsl:call-template>
      </xsl:for-each>

    </div> <!--* class=subsubsectionlist *-->

  </xsl:template> <!--* match=subsubsectionlist *-->

  <!--*
      * add a separator between "sections"
      *-->
  <xsl:template name="add-mid-sep">
    <hr class="midsep"/>
  </xsl:template>

  <!--*
      * allow us to add a TODO marker that gets displayed
      * *and* stops the page being published to the live
      * site.
      *-->
  <xsl:template match="TODO|todo|Todo|ToDo">
    <xsl:if test="$type='live'">
      <xsl:message terminate="yes">
 ERROR: found &lt;<xsl:value-of select="name()"/>&gt; tag with contents
 <xsl:value-of select="."/>
      </xsl:message>
    </xsl:if>
    <xsl:message terminate="no">
 NOTE: found &lt;<xsl:value-of select="name()"/>&gt; tag with contents
 <xsl:value-of select="."/>
    </xsl:message>
    <!-- we could decide to change the wrapper depending on the contents -->
    <span style="font-weight: bold; color: red;">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!--*
      * just in case...
      *-->
  <xsl:template match="subsubsubsection|subsubsubsectionlist">
    <xsl:message terminate="yes">
 ERROR: found &lt;<xsl:value-of select="name()"/>&gt; tag - see Doug!
    </xsl:message>
  </xsl:template>

  <!--*
      * I keep on doing this...
      *-->
  <xsl:template match="annotation">
    <xsl:message terminate="yes">
 ERROR: found &lt;annotation&gt; tag which should probably be &lt;admonition&gt;
    </xsl:message>
  </xsl:template>

  <!--*
      * argh; using xi:include is too easy to mess up and
      * include the wrapper, so let's catch the tag and process
      * the contents.
      *-->
  <xsl:template match="item">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * some typos I have been known to make; with the validation
      * now done this is less important, as we should get told
      * about it, but still...
      *-->
  <xsl:template match="extling|extlinl|exclink|cxcling|cxclinl">
    <xsl:message terminate="yes">
 ERROR: found &lt;<xsl:value-of select="name()"/>&gt; tag
    </xsl:message>
  </xsl:template>

</xsl:stylesheet>
