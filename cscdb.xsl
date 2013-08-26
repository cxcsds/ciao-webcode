<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Convert an XML web page into an HTML one
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
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname"  select="'canonicalbase'"/>
      <xsl:with-param name="pvalue" select="$canonicalbase"/>
    </xsl:call-template>

    <!--* what do we create *-->
    <xsl:apply-templates select="cscdb"/>
    <xsl:apply-templates select="cscdb" mode="alphabet"/>

  </xsl:template> <!--* match=/ *-->

  <!--* 
      * create: <page>.html
      *-->

  <xsl:template match="cscdb">

    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$pagename"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" version="4.0" encoding="utf-8">

      <!--* we start processing the XML file here *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-standard"/>

	<!--* add disclaimer about editing this HTML file *-->
	<xsl:call-template name="add-disclaimer"/>

	<xsl:call-template name="add-header"/>

	  <!--// main div begins page layout //-->
	    <div id="main">

		<!--* the main text *-->
		<div id="content">
		  <div class="wrap">

	      <!--* add the intro text *-->
	      <xsl:if test="intro">
	        <xsl:apply-templates select="intro"/>
		
		<!--// add links //-->
		<span class="qlinkbar">Go to:
		  <a href="index.html">Catalog Columns Index</a> |
		  <a>
		    <xsl:attribute name="href">
		    <xsl:value-of select="concat($pagename,'_alpha.html')"/>
		  </xsl:attribute>
		  Alphabetical List</a>
		</span>
		<hr/>
	      </xsl:if>


	 <!--// start database column table //-->
	 <table id="dbtable" class="csctable">
	   <thead>
	     <tr>
	       <th>Context</th>
	       <th>Column Name</th>
	       <th>Type</th>
	       <th>Units</th>
	       <th>Description</th>
	     </tr>
	   </thead>

	   <tbody>
	     <xsl:for-each select="//objgrp">

	       <xsl:for-each select="group">
		 <xsl:variable name="rowcount"><xsl:value-of select="count(cols/col)"/></xsl:variable>
		 <tr>
		   <td valign="top" rowspan="{$rowcount}" class="context">

		     <xsl:variable name="grpname">
		       <xsl:value-of select="@id"/>
		     </xsl:variable>
	      
		     <!--// make an anchor for TOC //-->
		     <a name="{$grpname}"></a>
		     
		     <xsl:choose>
		       
		       <xsl:when test="@link">
			 <xsl:variable name="grplink">
			   <xsl:value-of select="@link"/>
			 </xsl:variable>
			 
			 <a class="grouptitle" href="{$grplink}.html">
			   <strong><xsl:value-of select="title"/></strong>
			 </a>
		       </xsl:when>
		       
		       <xsl:otherwise>
			 <span class="grouptitle"><strong><xsl:value-of select="title"/></strong></span>
		       </xsl:otherwise>
		     </xsl:choose>
		   </td>
		   
		   <!--// if first row, don't include open "tr" tag //-->
		   <xsl:for-each select="cols/col">
		     <xsl:if test="position() = 1">
		       <xsl:call-template name="add-dbcols"/>
		     </xsl:if>
		   </xsl:for-each>
		 </tr>
		 
		 <xsl:for-each select="cols/col">
		   <xsl:if test="position() != 1">
		     <tr>
		       <xsl:call-template name="add-dbcols"/>
		     </tr>
		   </xsl:if>
		 </xsl:for-each>
		 
		 <xsl:if test="last()">
		   <tr><td colspan="5" class="separator"><hr/></td></tr>
		 </xsl:if>
		 
	       </xsl:for-each>  <!--// end select="group" //-->

	     </xsl:for-each>  <!--// end select="objgroup" //-->
	   </tbody>
	 </table>
	 <!--// end database column table //-->
	 

		  </div>
		</div> <!--// close id=content //-->

		<div id="navbar">
		  <div class="wrap">
		    <a name="navtext"/>

		  <xsl:call-template name="add-navbar">
		    <xsl:with-param name="name" select="info/navbar"/>
		  </xsl:call-template>
		  </div>
		</div> <!--// close id=navbar //-->
		
	    </div> <!--// close id=main  //-->
	    
	<xsl:call-template name="add-footer"/>
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=cscdb *-->

  <!--* 
      * create: <page>_alpha.html
      *-->

  <xsl:template match="cscdb" mode="alphabet">

    <xsl:variable name="alphapagename"><xsl:value-of select="$pagename"/>_alpha</xsl:variable>
    <xsl:variable name="filename"><xsl:value-of select="$install"/><xsl:value-of select="$alphapagename"/>.html</xsl:variable>

    <!--* output filename to stdout *-->
    <xsl:value-of select="$filename"/><xsl:call-template name="newline"/>

    <!--* create document *-->
    <xsl:document href="{$filename}" method="html" media-type="text/html" version="4.0" encoding="utf-8">

      <!--* we start processing the XML file here *-->
      <html lang="en">

	<!--* make the HTML head node *-->
	<xsl:call-template name="add-htmlhead-standard">
	  <xsl:with-param name="page" select="concat($alphapagename, '.html')"/>
	</xsl:call-template>

	<!--* add disclaimer about editing this HTML file *-->
	<xsl:call-template name="add-disclaimer"/>

	<xsl:call-template name="add-header"/>

	  <!--// main div begins page layout //-->
	    <div id="main">

		<!--* the main text *-->
		<div id="content">
		  <div class="wrap">

	      <!--* add the intro text *-->
	      <xsl:if test="intro">
	        <xsl:apply-templates select="intro"/>

		<!--// add links //-->
		<span class="qlinkbar">Go to:
		  <a href="index.html">Catalog Columns Index</a> |
		  <a>
		    <xsl:attribute name="href">
		    <xsl:value-of select="concat($pagename,'.html')"/>
		  </xsl:attribute>
		  Context List</a>
		</span>
		<hr/>
	      </xsl:if>


	 <!--// start database column table //-->
	 <table id="dbtable" class="csctable">
	   <thead>
	     <tr>
	       <th>Column Name</th>
	       <th>Type</th>
	       <th>Units</th>
	       <th>Description</th>
	     </tr>
	   </thead>

	   <tbody>
	     <xsl:for-each select="//objgrp/group/cols/col">
	       <xsl:sort select="@name"/>

	       <!--// don't include anything marked as '@hide="abc"' //-->     
	       <xsl:if test="(contains(@hide,'abc') != true()) or (@hide != 'abc')">
		 <tr>
		   <xsl:call-template name="add-dbcols"/>
		 </tr>
	       </xsl:if>
	     </xsl:for-each>
	   </tbody>

	 </table>
	 <!--// end database column table //-->


		  </div>
		</div> <!--// close id=content //-->

		<div id="navbar">
		  <div class="wrap">
		    <a name="navtext"/>

		  <xsl:call-template name="add-navbar">
		    <xsl:with-param name="name" select="info/navbar"/>
		  </xsl:call-template>
		  </div>
		</div> <!--// close id=navbar //-->
		
	    </div> <!--// close id=main  //-->
	    
	<xsl:call-template name="add-footer"/>
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=cscdb mode=alphabet *-->


  <xsl:template name="add-dbcols">
    <td>
      <xsl:variable name="aname">
	<xsl:value-of select="@name"/>
      </xsl:variable>

      <a class="nohovername" name="{$aname}">
	<xsl:value-of select="@name"/>
      </a>
    </td>

    <td>
      <xsl:if test="@type">
	<xsl:value-of select="@type"/>
      </xsl:if>
    </td>
    
    <td>      
      <xsl:if test="@units">
	<xsl:choose>
	  <xsl:when test="@units='counts-s'">
	    counts&#160;s<sup>-1</sup>
	  </xsl:when>
	  
	  <xsl:when test="@units='ergs-s-cm'">
	    ergs&#160;s<sup>-1</sup>&#160;cm<sup>-2</sup>
	  </xsl:when>
	  
	  <xsl:when test="@units='photons-s-cm'">
	    photons&#160;s<sup>-1</sup>&#160;cm<sup>-2</sup>
	  </xsl:when>
	  
	  <xsl:when test="@units='n-hi-cm'">
	    N&#160;<sub>HI&#160;atoms</sub>&#160;10<sup>20</sup>&#160;cm<sup>-2</sup>
	  </xsl:when>
	  
	  <xsl:otherwise>
	    <xsl:value-of select="@units"/>
	  </xsl:otherwise>
	</xsl:choose>
	
      </xsl:if>
    </td>
    
    <td>
      <xsl:apply-templates/>
    </td>
    
  </xsl:template> <!--* name:add-cols *-->
  

  <!--* remove the 'whatever' tag, process the contents *-->
  <xsl:template match="intro|desc">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
