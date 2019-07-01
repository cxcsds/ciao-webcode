<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the CSC dictionary HTML pages from one XML source file
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="extfuncs">

  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-dictionary_onepage" select="extfuncs:register-import-dependency('dictionary_onepage.xsl')"/>

  <!--*
      * this is an attempt to make some of the code below less onerous
      * by allowing looping over a nodeset
      *
      * See http://www.dpawson.co.uk/xsl/sect2/muench.html
      *
      * ACTUALLY FOR NOW HAVE GONE THE PAINFUL ROOT
      *-->

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
      *   individual pages
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

    <!--* check there's a navbar element *-->
    <xsl:if test="boolean(dictionary_onepage/info/navbar) = false()">
      <xsl:message terminate="yes">
  Error: the info block does not contain a navbar element.
      </xsl:message>
    </xsl:if>

    <xsl:apply-templates select="dictionary_onepage"/>
    <xsl:apply-templates select="//entries"/>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: index.html
      *-->

  <xsl:variable name="ucletters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  <xsl:variable name="lcletters" select="'abcdefghijklmnopqrstuvwxyz'"/>

  <xsl:template match="dictionary_onepage">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>index.html</xsl:variable>

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

	<xsl:variable name="contents">
	  <xsl:if test="boolean(//info/breadcrumbs)">
	    <xsl:call-template name="add-breadcrumbs">
	      <xsl:with-param name="location" select="$filename"/>
	    </xsl:call-template>
	  </xsl:if>

	  <!--* add the intro text *-->
	  <xsl:apply-templates select="intro"/>
	      
	  <!--* create the list of FAQ's *--> 
	  <xsl:apply-templates select="entries" mode="toc"/>

	  <xsl:if test="boolean(//info/breadcrumbs)">
	    <xsl:call-template name="add-breadcrumbs">
	      <xsl:with-param name="pos" select="'bottom'"/>
	      <xsl:with-param name="location" select="$filename"/>
	    </xsl:call-template>
	  </xsl:if>
	</xsl:variable>
	    
	<xsl:variable name="navbar">
	  <xsl:call-template name="add-navbar">
	    <xsl:with-param name="name" select="info/navbar"/>
	  </xsl:call-template>
	</xsl:variable>
	    
	<xsl:call-template name="add-body-withnavbar">
	  <xsl:with-param name="contents" select="$contents"/>
	  <xsl:with-param name="navbar" select="$navbar"/>
	</xsl:call-template>

      </html>

    </xsl:document>
  </xsl:template> <!--* match=dictionary_onepage *-->

  <!--* 
      * create: dictionary entries page
      *-->

  <xsl:template match="entries">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>entries.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
                  doctype-system="about:legacy-compat"
		  version="5.0">

      <!--* we start processing the XML file here *-->
      <html lang="en-US">

	<!--*
            * make the HTML head node
            *
            * note: need to supply the text for the page title
            *       because it's not visible to add-htmlhead-standard
            *	    from this level of the document
	    *
            *-->

	<xsl:call-template name="add-htmlhead">
	  <xsl:with-param name="title">Dictionary Entries</xsl:with-param>
	  <xsl:with-param name="page">entries.html</xsl:with-param>
	</xsl:call-template>

	<xsl:variable name="contents">
	  <h1 class="pagetitle">CSC Dictionary Entries</h1>
	  <hr/>
	  
	  <xsl:for-each select="entry">
	    <xsl:sort select="translate(title, $lcletters, $ucletters)"/>
		  
	    <!--* entry title *-->
	    <h2 id="{@id}"><xsl:apply-templates select="title"/></h2>
	    
	    <!--* add the explanation *-->
	    <xsl:apply-templates select="text"/>
	    
	    <div class="qlinkbar">
	      Return to: <a href=".">Dictionary index</a>
	    </div>
		  
	    <br/><hr/>
	  </xsl:for-each>
	</xsl:variable>

	<xsl:variable name="navbar">
	  <xsl:call-template name="add-navbar">
	    <xsl:with-param name="name" select="/dictionary_onepage/info/navbar"/>
	  </xsl:call-template>
	</xsl:variable>

	<xsl:call-template name="add-body-withnavbar">
	  <xsl:with-param name="contents" select="$contents"/>
	  <xsl:with-param name="navbar" select="$navbar"/>
	</xsl:call-template>
	
      </html>

    </xsl:document>
  </xsl:template> <!--* match=dictionary *-->

  <!--*
      * Create the list of dictionary entries
      *
      * Note: it's not pretty code (the hard-coding of all the letters)
      *
      *-->
  <xsl:template match="entries" mode="toc">

    <!--* create the nodesets we will be querying (is there a better way to do this?) *-->
    <xsl:variable name="ea" select="//entry[starts-with(@id,'a')]"/>
    <xsl:variable name="eb" select="//entry[starts-with(@id,'b')]"/>
    <xsl:variable name="ec" select="//entry[starts-with(@id,'c')]"/>
    <xsl:variable name="ed" select="//entry[starts-with(@id,'d')]"/>
    <xsl:variable name="ee" select="//entry[starts-with(@id,'e')]"/>
    <xsl:variable name="ef" select="//entry[starts-with(@id,'f')]"/>
    <xsl:variable name="eg" select="//entry[starts-with(@id,'g')]"/>
    <xsl:variable name="eh" select="//entry[starts-with(@id,'h')]"/>
    <xsl:variable name="ei" select="//entry[starts-with(@id,'i')]"/>
    <xsl:variable name="ej" select="//entry[starts-with(@id,'j')]"/>
    <xsl:variable name="ek" select="//entry[starts-with(@id,'k')]"/>
    <xsl:variable name="el" select="//entry[starts-with(@id,'l')]"/>
    <xsl:variable name="em" select="//entry[starts-with(@id,'m')]"/>
    <xsl:variable name="en" select="//entry[starts-with(@id,'n')]"/>
    <xsl:variable name="eo" select="//entry[starts-with(@id,'o')]"/>
    <xsl:variable name="ep" select="//entry[starts-with(@id,'p')]"/>
    <xsl:variable name="eq" select="//entry[starts-with(@id,'q')]"/>
    <xsl:variable name="er" select="//entry[starts-with(@id,'r')]"/>
    <xsl:variable name="es" select="//entry[starts-with(@id,'s')]"/>
    <xsl:variable name="et" select="//entry[starts-with(@id,'t')]"/>
    <xsl:variable name="eu" select="//entry[starts-with(@id,'u')]"/>
    <xsl:variable name="ev" select="//entry[starts-with(@id,'v')]"/>
    <xsl:variable name="ew" select="//entry[starts-with(@id,'w')]"/>
    <xsl:variable name="ex" select="//entry[starts-with(@id,'x')]"/>
    <xsl:variable name="ey" select="//entry[starts-with(@id,'y')]"/>
    <xsl:variable name="ez" select="//entry[starts-with(@id,'z')]"/>

    <xsl:variable name="nea" select="count($ea)"/>
    <xsl:variable name="neb" select="count($eb)"/>
    <xsl:variable name="nec" select="count($ec)"/>
    <xsl:variable name="ned" select="count($ed)"/>
    <xsl:variable name="nee" select="count($ee)"/>
    <xsl:variable name="nef" select="count($ef)"/>
    <xsl:variable name="neg" select="count($eg)"/>
    <xsl:variable name="neh" select="count($eh)"/>
    <xsl:variable name="nei" select="count($ei)"/>
    <xsl:variable name="nej" select="count($ej)"/>
    <xsl:variable name="nek" select="count($ek)"/>
    <xsl:variable name="nel" select="count($el)"/>
    <xsl:variable name="nem" select="count($em)"/>
    <xsl:variable name="nen" select="count($en)"/>
    <xsl:variable name="neo" select="count($eo)"/>
    <xsl:variable name="nep" select="count($ep)"/>
    <xsl:variable name="neq" select="count($eq)"/>
    <xsl:variable name="ner" select="count($er)"/>
    <xsl:variable name="nes" select="count($es)"/>
    <xsl:variable name="net" select="count($et)"/>
    <xsl:variable name="neu" select="count($eu)"/>
    <xsl:variable name="nev" select="count($ev)"/>
    <xsl:variable name="new" select="count($ew)"/>
    <xsl:variable name="nex" select="count($ex)"/>
    <xsl:variable name="ney" select="count($ey)"/>
    <xsl:variable name="nez" select="count($ez)"/>

    <!--* a safety check *-->
    <xsl:variable name="ntot" select="$nea+$neb+$nec+$ned+$nee+$nef+$neg+$neh+$nei+$nej+$nek+$nel+$nem+$nen+$neo+$nep+$neq+$ner+$nes+$net+$neu+$nev+$new+$nex+$ney+$nez"/>
    <xsl:variable name="delta" select="count(//entry) - $ntot"/>
    <xsl:if test="$delta != 0">
      <xsl:message terminate="yes">
 Error: it appears that <xsl:value-of select="$delta"/> entry tags
 have an id which doesn't begin with a-z (lower case)
 [debug: total=<xsl:value-of select="$delta"/>   ntot=<xsl:value-of select="$ntot"/>]
      </xsl:message>
    </xsl:if>

    <!--* create the list of topics *-->
    <hr/>
    <div class="navlinkbar">
      <xsl:if test="$nea != 0"><a href="#a">A</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$neb != 0"><a href="#b">B</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nec != 0"><a href="#c">C</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$ned != 0"><a href="#d">D</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nee != 0"><a href="#e">E</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nef != 0"><a href="#f">F</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$neg != 0"><a href="#g">G</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$neh != 0"><a href="#h">H</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nei != 0"><a href="#i">I</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nej != 0"><a href="#j">J</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nek != 0"><a href="#k">K</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nel != 0"><a href="#l">L</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nem != 0"><a href="#m">M</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nen != 0"><a href="#n">N</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$neo != 0"><a href="#o">O</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nep != 0"><a href="#p">P</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$neq != 0"><a href="#q">Q</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$ner != 0"><a href="#r">R</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nes != 0"><a href="#s">S</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$net != 0"><a href="#t">T</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$neu != 0"><a href="#u">U</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nev != 0"><a href="#v">V</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$new != 0"><a href="#w">W</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nex != 0"><a href="#x">X</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$ney != 0"><a href="#y">Y</a><xsl:text> </xsl:text></xsl:if>
      <xsl:if test="$nez != 0"><a href="#z">Z</a><xsl:text> </xsl:text></xsl:if>
    </div>
    <hr/>

    <!--* and now the alphabetic list of entries *-->
    <dl>
      <xsl:if test="$nea != 0"><dt id="a"><strong>A</strong></dt><xsl:for-each select="$ea"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neb != 0"><dt id="b"><strong>B</strong></dt><xsl:for-each select="$eb"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nec != 0"><dt id="c"><strong>C</strong></dt><xsl:for-each select="$ec"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$ned != 0"><dt id="d"><strong>D</strong></dt><xsl:for-each select="$ed"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nee != 0"><dt id="e"><strong>E</strong></dt><xsl:for-each select="$ee"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nef != 0"><dt id="f"><strong>F</strong></dt><xsl:for-each select="$ef"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neg != 0"><dt id="g"><strong>G</strong></dt><xsl:for-each select="$eg"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neh != 0"><dt id="h"><strong>H</strong></dt><xsl:for-each select="$eh"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nei != 0"><dt id="i"><strong>I</strong></dt><xsl:for-each select="$ei"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nej != 0"><dt id="j"><strong>J</strong></dt><xsl:for-each select="$ej"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nek != 0"><dt id="k"><strong>K</strong></dt><xsl:for-each select="$ek"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nel != 0"><dt id="l"><strong>L</strong></dt><xsl:for-each select="$el"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nem != 0"><dt id="m"><strong>M</strong></dt><xsl:for-each select="$em"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nen != 0"><dt id="n"><strong>N</strong></dt><xsl:for-each select="$en"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neo != 0"><dt id="o"><strong>O</strong></dt><xsl:for-each select="$eo"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nep != 0"><dt id="p"><strong>P</strong></dt><xsl:for-each select="$ep"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neq != 0"><dt id="q"><strong>Q</strong></dt><xsl:for-each select="$eq"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$ner != 0"><dt id="r"><strong>R</strong></dt><xsl:for-each select="$er"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nes != 0"><dt id="s"><strong>S</strong></dt><xsl:for-each select="$es"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$net != 0"><dt id="t"><strong>T</strong></dt><xsl:for-each select="$et"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neu != 0"><dt id="u"><strong>U</strong></dt><xsl:for-each select="$eu"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nev != 0"><dt id="v"><strong>V</strong></dt><xsl:for-each select="$ev"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$new != 0"><dt id="w"><strong>W</strong></dt><xsl:for-each select="$ew"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nex != 0"><dt id="x"><strong>X</strong></dt><xsl:for-each select="$ex"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$ney != 0"><dt id="y"><strong>Y</strong></dt><xsl:for-each select="$ey"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nez != 0"><dt id="z"><strong>Z</strong></dt><xsl:for-each select="$ez"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>

    </dl>
    
  </xsl:template> <!--* match=faqlist mode=toc *-->

  <xsl:template name="add-entry">
    <dd><a href="entries.html#{@id}"><xsl:value-of select="title"/></a></dd>
  </xsl:template> <!--* name:add-entry *-->

  <!--* remove the 'whatever' tag, process the contents *-->
  <xsl:template match="intro|name|title|text">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
