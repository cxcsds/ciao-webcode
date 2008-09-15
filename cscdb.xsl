<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Convert an XML web page into an HTML one
    *
    * Recent changes:
    *
    * 2008 May 30 DJB Removed generation of PDF version
    *
    * 2008 Mar/Feb ECG
    *	 new stylesheet for cscdb page type
    *
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
    <xsl:document href="{$filename}" method="html" media-type="text/html" version="4.0" encoding="us-ascii">

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
	  <xsl:with-param name="name" select="$pagename"/>
	</xsl:call-template>

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
	      <xsl:if test="intro">
	        <xsl:apply-templates select="intro"/>
		
		<!--// add links //-->
		<font size="-1">Go to:
		  <a href="index.html">Catalog Columns Index</a> |
		  <a>
		    <xsl:attribute name="href">
		    <xsl:value-of select="concat($pagename,'_alpha.html')"/>
		  </xsl:attribute>
		  Alphabetical List</a>
		</font>
		<hr/>
	      </xsl:if>


	 <!--// start database column table //-->
	 <table id="dbtable" width="100%" border="0" cellspacing="2" cellpadding="4">
	 <tr>
	   <th>Context</th>
	   <th>Column Name</th>
	   <th>Type</th>
	   <th>Units</th>
	   <th>Description</th>
	 </tr>

	 <xsl:for-each select="//objgrp">

	   <xsl:for-each select="group">
	   <xsl:variable name="rowcount"><xsl:value-of select="count(cols/col)"/></xsl:variable>
	   <tr>
	      <td valign="top" rowspan="{$rowcount}">

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
	        <tr><td colspan="5"><hr/></td></tr>
	      </xsl:if>

	   </xsl:for-each>  <!--// end select="group" //-->

	 </xsl:for-each>  <!--// end select="objgroup" //-->

	 </table>
	 <!--// end database column table //-->


	    </td>
	  </tr>
	</table>  <!--// end page layout table //-->
	    
	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="name"  select="$pagename"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
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
    <xsl:document href="{$filename}" method="html" media-type="text/html" version="4.0" encoding="us-ascii">

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
	  <xsl:with-param name="name" select="$alphapagename"/>
	</xsl:call-template>

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
	      <xsl:if test="intro">
	        <xsl:apply-templates select="intro"/>

		<!--// add links //-->
		<font size="-1">Go to:
		  <a href="index.html">Catalog Columns Index</a> |
		  <a>
		    <xsl:attribute name="href">
		    <xsl:value-of select="concat($pagename,'.html')"/>
		  </xsl:attribute>
		  Context List</a>
		</font>
		<hr/>
	      </xsl:if>


	 <!--// start database column table //-->
	 <table id="dbtable" width="100%" border="0" cellspacing="2" cellpadding="4">
	 <tr>
	   <th>Column Name</th>
	   <th>Type</th>
	   <th>Units</th>
	   <th>Description</th>
	 </tr>

	    <xsl:for-each select="//objgrp/group/cols/col">
	     <xsl:sort select="@name"/>

	     <!--// don't include anything marked as '@hide="abc"' //-->     
	     <xsl:if test="(contains(@hide,'abc') != true()) or (@hide != 'abc')">
	      <tr>
	        <xsl:call-template name="add-dbcols"/>
	      </tr>
	     </xsl:if>
	    </xsl:for-each>

	 </table>
	 <!--// end database column table //-->


	    </td>
	  </tr>
	</table>  <!--// end page layout table //-->
	    
	<!--* add the footer text *-->
	<xsl:call-template name="add-footer">
	  <xsl:with-param name="name"  select="$alphapagename"/>
	</xsl:call-template>

	<!--* add </body> tag [the <body> is included in a SSI] *-->
	<xsl:call-template name="add-end-body"/>
      </html>

    </xsl:document>
  </xsl:template> <!--* match=cscdb mode=alphabet *-->


  <xsl:template name="add-dbcols">
	<td>
	  <xsl:call-template name="add-table-bg-color"/>
	  <xsl:variable name="aname">
	    <xsl:value-of select="@name"/>
	  </xsl:variable>

	  <a class="nohovername" name="{$aname}">
	  <xsl:value-of select="@name"/>
	  </a>
	</td>

	<td>
	  <xsl:if test="@type">
	    <xsl:call-template name="add-table-bg-color"/>	        
	    <xsl:value-of select="@type"/>
	  </xsl:if>
	</td>

	<td>      
	  <xsl:call-template name="add-table-bg-color"/>	        

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
	  <xsl:call-template name="add-table-bg-color"/>	        
	  <xsl:apply-templates/>
	</td>

  </xsl:template> <!--* name:add-cols *-->


  <!--* remove the 'whatever' tag, process the contents *-->
  <xsl:template match="intro|desc">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template name="add-table-bg-color">
    <xsl:if test="position() mod 2 = 0">
      <xsl:attribute name="class">oddrow</xsl:attribute>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
