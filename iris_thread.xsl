<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Create the HTML version of the CIAO thread
    *
    * Recent changes:
    * 2007 Oct 29 DJB
    *    start work on supporting proglang (=sl or py)
    * 2007 Oct 19 DJB
    *    depth parameter is now a global, no need to send around
    *  v1.27 - add version under thread title
    *  v1.26 - <html> changed to <html lang="en"> following
    *            http://www.w3.org/TR/2005/WD-i18n-html-tech-lang-20050224/
    *  v1.25 - moved add-new-page to thread_common.xsl
    *  v1.24 - moved imglink to thread_common.xsl
    *  v1.23 - Big change for CIAO 3.1: moved ciao_thread_hard.xsl
    *          into this stylesheet and made the templates aware of
    *          the 'global' hardcopy variable
    *  v1.22 - added an anchor for the 'skip nav. bar' link
    *  v1.21 - imglinkicon[width/height] parameters now define icon for
    *          imglink tag (so user can change them via config file)
    *  v1.20 - updated to handle head/texttitlepostfix
    *  v1.19 - fixes to HTML plus more table-related changes (add-header/footer)
    *          imglink now uses a single a tag with name and href attributes
    *  v1.18 - added newsfile/newsfileurl parameters + use of globalparams_thread.xsl
    *  v1.17 - use of tables for the main text has changed.
    *  v1.16 - call add-header/footer so that the PDF links are created correctly
    *  v1.15 - change format for CIAO 3.0; added cssfile parameter
    *  v1.14 - @year can now handle values > 2000 sensibly; changes to layout
    *  v1.13 - ahelpindex (CIAO 3.0)
    *  v1.12 - added support for siteversion parameter
    *  v1.11 - threadDir is now set by the processor, not by the stylesheet
    *  v1.10 - re-introduced the external parameter updateby
    *   v1.9 - added pagename parameter, imglink can now be called from include files
    *   v1.8 - cleaned up (image generation code moved to thread_common.xsl)
    *   v1.7 - fixes to recent change in helper.xsl (add-last-modified)
    *   v1.6 - use thread_common.xsl rather than ciao_thread_common.xsl
    *   v1.5 - moved templates into ciao_thread_common.xsl and ciao_thread_hard.xsl
    *   v1.4 - added imglink template (from links.xsl), have a hacky way to link to id
    *
    * To do:
    *
    * Parameters:
    *   imglinkicon, string, required
    *     location of the image, relative to the top-level for this site,
    *     for the image to use at the end of "image" links
    *     e.g. imgs/imageicon.gif
    *
    *   imglinkiconwidth, integer, required
    *     width of imglinkicon in pixels
    *
    *   imglinkiconheight, integer, required
    *     height of imglinkicon in pixels
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--* we create the HTML files using xsl:document statements *-->
  <xsl:output method="text"/>

  <!--* load in the set of "global" parameters *-->
  <xsl:include href="globalparams_thread.xsl"/>

  <!--*
      * NOTE:
      *   currently the default values for these parameters are set
      *   by the calling process, which in this case is publish.pl
      *-->
  <xsl:param name="imglinkicon" select='""'/>
  <xsl:param name="imglinkiconwidth" select='0'/>
  <xsl:param name="imglinkiconheight" select='0'/>

  <!--* include the stylesheets *-->
  <xsl:include href="thread_common.xsl"/>
  <xsl:include href="helper.xsl"/>
  <xsl:include href="links.xsl"/>
  <xsl:include href="myhtml.xsl"/>

  <!--* really need to sort out the newline template issue *-->
  <xsl:template name="newline">
<xsl:text> 
</xsl:text>
  </xsl:template>

  <!--* 
      * top level
      * if proglang == '' then create
      *   index.html               
      *   img<n>.html              
      * else create
      *   index.<proglang>.html                
      *   img<n>.<proglang>.html               
      *   in this case no index.html case is created
      *
      *-->

  <xsl:template match="/">

    <!--* check the params are okay *-->
    <xsl:call-template name="is-site-valid"/>
    <xsl:call-template name="check-param-ends-in-a-slash">
      <xsl:with-param name="pname" select="'install'"/>
      <xsl:with-param name="pvalue" select="$install"/>
    </xsl:call-template>
    <xsl:call-template name="is-proglang-valid"/>

    <xsl:apply-templates select="thread" mode="html-viewable-standard"/>
    <xsl:apply-templates select="thread/images/image" mode="list"/>

  </xsl:template> <!-- match="/" *-->

</xsl:stylesheet>
