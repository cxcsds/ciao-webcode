<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the CSC dictionary HTML pages from one XML source file
    *
    * Recent changes:
    * 2008 Mar 13 ECG: CSC dictionary is one index page and one long 
    *		       entries page
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *  v1.16 - sort on case-insensitive titles so that index is
    *	       alphabetical
    *  v1.15 - hyphen added to (head/text)titlepostfix instances
    *  v1.14 - <html> changed to <html lang="en"> following
    *            http://www.w3.org/TR/2005/WD-i18n-html-tech-lang-20050224/
    *  v1.13 - We are now called with hardopy=0 or 1 and this determines
    *          the type of the file created (CIAO 3.1)
    *  v1.12 - support for head/texttitlepostfix parameters
    *  v1.11 - added maintext anchor
    *  v1.10 - removing tables from header/footer
    *   v1.9 - added newsfile/newsfileurl parameters + use of globalparams.xsl
    *   v1.8 - re-organisation of layout for CIAO 3.0
    *          added cssfile parameter
    *   v1.7 - ahelpindex support (CIAO 3.0)
    *   v1.6 - added support for siteversion parameter
    *   v1.5 - fixed pdf links (now to corrct version, not the index)
    *   v1.4 - introduced the external parameter updateby
    *   v1.3 - removed '[A4,L]' links from index
    *   v1.2 - initial version
    *   v1.1 - copy of v1.2 of faq.xsl
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
      *   hardcopy versions of above
      *
      *-->
  <xsl:template match="/">

    <!--* check the params are okay *-->
    <xsl:call-template name="is-site-valid"/>
    <xsl:if test="substring($install,string-length($install))!='/'">
      <xsl:message terminate="yes">
  Error: install parameter must end in a / character.
    install=<xsl:value-of select="$install"/>
      </xsl:message>
    </xsl:if>

    <!--* check there's a navbar element *-->
    <xsl:if test="boolean(dictionary_onepage/info/navbar) = false()">
      <xsl:message terminate="yes">
  Error: the info block does not contain a navbar element.
      </xsl:message>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="$hardcopy = 1">
	<!--* hardcopy *-->
	<xsl:apply-templates select="dictionary_onepage" mode="make-hardcopy"/>
	<xsl:apply-templates select="//entries" mode="make-hardcopy"/>
      </xsl:when>

      <xsl:otherwise>
	<!--* softcopy *-->
	<xsl:apply-templates select="dictionary_onepage" mode="make-viewable"/>
	<xsl:apply-templates select="//entries" mode="make-viewable"/>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: index.html
      *-->

  <xsl:variable name="ucletters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  <xsl:variable name="lcletters" select="'abcdefghijklmnopqrstuvwxyz'"/>

  <xsl:template match="dictionary_onepage" mode="make-viewable">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>index.html</xsl:variable>

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
	  <xsl:with-param name="name"  select="'index'"/>
	</xsl:call-template>
	
	<!--* use a table to provide the page layout *-->
	<table class="maintable" width="100%" border="0" cellspacing="2" cellpadding="2">
	  <tr>
	    <!--* add the navbar (we force page to have one) *-->
	    <xsl:call-template name="add-navbar">
	      <xsl:with-param name="name" select="info/navbar"/>
	    </xsl:call-template>

	    <!--* the main text *-->
	    <td class="mainbar" valign="top">

	      <a name="maintext"/>
	    
	      <!--* add the intro text *-->
	      <xsl:apply-templates select="intro"/>
	  
	      <!--* create the list of entries *--> 
	      <xsl:apply-templates select="entries" mode="toc"/>

	    </td>
	  </tr>
	</table>

	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="name"  select="'index'"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=dictionary_onepage mode=make-viewable *-->

  <!--* 
      * create: index.hard.html
      *-->

  <xsl:template match="dictionary_onepage" mode="make-hardcopy">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>index.hard.html</xsl:variable>
    <xsl:variable name="url"><xsl:value-of select="$urlhead"/></xsl:variable>

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

	  <!--* add the intro text *-->
	  <xsl:apply-templates select="intro"/>
	      
	  <!--* create the list of entries *--> 
	  <xsl:apply-templates select="entries" mode="toc"/>

	  <xsl:call-template name="add-hardcopy-banner-bottom">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	</body>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=faq mode=make-hardcopy *-->


  <!--* 
      * create: dictionary entries page (viewable)
      *-->

  <xsl:template match="entries" mode="make-viewable">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>entries.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">

      <!--* we start processing the XML file here *-->
      <html lang="en">


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
	</xsl:call-template>
	
	<!--* add disclaimer about editing this HTML file *-->
	<xsl:call-template name="add-disclaimer"/>

	<!--* make the header - it's different depending on whether this is
	    * a test version or the actual production HTML 
            *-->
	<xsl:call-template name="add-header">
	  <xsl:with-param name="name"  select="'entries'"/>
	</xsl:call-template>
	
	<!--* use a table to provide the page layout *-->
	<table class="maintable" width="100%" border="0" cellspacing="2" cellpadding="2">
	  <tr>
	    <!--* add the navbar (we force page to have one) *-->
	    <xsl:call-template name="add-navbar">
	      <xsl:with-param name="name" select="/dictionary_onepage/info/navbar"/>
	    </xsl:call-template>

	    <!--* the main text *-->
	    <td class="mainbar" valign="top">

	      <a name="maintext"/>
	    
	      <div align="center"><h1>CSC Dictionary Entries</h1></div>
	      
	      <hr/>
	  
	    <xsl:for-each select="entry">
	      <xsl:sort select="translate(title, $lcletters, $ucletters)"/>

	      <!--* entry title *-->
	      <a name="{@id}"/>
	      <h2><xsl:apply-templates select="title"/></h2>

	      <!--* add the explanation *-->
	      <xsl:apply-templates select="text"/>

	      <div class="qlinkbar">
	        Return to: <a href=".">Dictionary index</a>
	      </div>
	  
	      <br/><hr/>
	    </xsl:for-each>

	    </td>
	  </tr>
	</table>

	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="name"  select="'index'"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=dictionary mode=make-viewable *-->


  <!--* 
      * create: entries.hard.html
      *-->

  <xsl:template match="entries" mode="make-hardcopy">

    <xsl:variable name="filename"><xsl:value-of select="$install"/>entries.hard.html</xsl:variable>
    <xsl:variable name="url"><xsl:value-of select="$urlhead"/></xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html"
      version="4.0" encoding="us-ascii">

      <!--* we start processing the XML file here *-->
      <html lang="en">

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
	</xsl:call-template>

	<!--* and now the main part of the text *-->
	<body>

	  <xsl:call-template name="add-hardcopy-banner-top">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	      <div align="center"><h1>CSC Dictionary Entries</h1></div>
	      
	      <hr/>
	  
	    <xsl:for-each select="entry">
	      <xsl:sort select="translate(title, $lcletters, $ucletters)"/>

	      <!--* entry title *-->
	      <a name="{@id}"/>
	      <h2><xsl:apply-templates select="title"/></h2>

	      <!--* add the explanation *-->
	      <xsl:apply-templates select="text"/>

	      <div class="qlinkbar">
	        Return to: <a href=".">Dictionary index</a>
	      </div>
	  
	      <br/><hr/>
	    </xsl:for-each>


	  <xsl:call-template name="add-hardcopy-banner-bottom">
	    <xsl:with-param name="url" select="$url"/>
	  </xsl:call-template>

	</body>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=faq mode=make-hardcopy *-->


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
    <br/>
    <hr/>
    <div align="center">
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
    <br/>

    <!--* and now the alphabetic list of entries *-->
    <dl>
      <xsl:if test="$nea != 0"><dt><strong><a name="a">A</a></strong></dt><xsl:for-each select="$ea"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neb != 0"><dt><strong><a name="b">B</a></strong></dt><xsl:for-each select="$eb"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nec != 0"><dt><strong><a name="c">C</a></strong></dt><xsl:for-each select="$ec"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$ned != 0"><dt><strong><a name="d">D</a></strong></dt><xsl:for-each select="$ed"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nee != 0"><dt><strong><a name="e">E</a></strong></dt><xsl:for-each select="$ee"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nef != 0"><dt><strong><a name="f">F</a></strong></dt><xsl:for-each select="$ef"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neg != 0"><dt><strong><a name="g">G</a></strong></dt><xsl:for-each select="$eg"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neh != 0"><dt><strong><a name="h">H</a></strong></dt><xsl:for-each select="$eh"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nei != 0"><dt><strong><a name="i">I</a></strong></dt><xsl:for-each select="$ei"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nej != 0"><dt><strong><a name="j">J</a></strong></dt><xsl:for-each select="$ej"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nek != 0"><dt><strong><a name="k">K</a></strong></dt><xsl:for-each select="$ek"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nel != 0"><dt><strong><a name="l">L</a></strong></dt><xsl:for-each select="$el"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nem != 0"><dt><strong><a name="m">M</a></strong></dt><xsl:for-each select="$em"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nen != 0"><dt><strong><a name="n">N</a></strong></dt><xsl:for-each select="$en"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neo != 0"><dt><strong><a name="o">O</a></strong></dt><xsl:for-each select="$eo"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nep != 0"><dt><strong><a name="p">P</a></strong></dt><xsl:for-each select="$ep"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neq != 0"><dt><strong><a name="q">Q</a></strong></dt><xsl:for-each select="$eq"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$ner != 0"><dt><strong><a name="r">R</a></strong></dt><xsl:for-each select="$er"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nes != 0"><dt><strong><a name="s">S</a></strong></dt><xsl:for-each select="$es"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$net != 0"><dt><strong><a name="t">T</a></strong></dt><xsl:for-each select="$et"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$neu != 0"><dt><strong><a name="u">U</a></strong></dt><xsl:for-each select="$eu"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nev != 0"><dt><strong><a name="v">V</a></strong></dt><xsl:for-each select="$ev"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$new != 0"><dt><strong><a name="w">W</a></strong></dt><xsl:for-each select="$ew"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nex != 0"><dt><strong><a name="x">X</a></strong></dt><xsl:for-each select="$ex"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$ney != 0"><dt><strong><a name="y">Y</a></strong></dt><xsl:for-each select="$ey"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>
      <xsl:if test="$nez != 0"><dt><strong><a name="z">Z</a></strong></dt><xsl:for-each select="$ez"><xsl:sort select="translate(title, $lcletters, $ucletters)"/><xsl:call-template name="add-entry"/></xsl:for-each></xsl:if>

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
