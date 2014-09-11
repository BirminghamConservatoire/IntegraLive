<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template name="render-additional-headers">
    <xsl:comment>override XSL template 'render-additional-headers' to render additional headers here</xsl:comment>
  </xsl:template>

  <xsl:template name="render-content">
    <xsl:comment>override XSL template 'render-content' to render content here</xsl:comment>
  </xsl:template>

  <xsl:template name="render-additional-scripts">
    <xsl:comment>override XSL template 'render-additional-scripts' to render additional scripts here</xsl:comment>
  </xsl:template>

  <xsl:template name="render-page">
    <html>
      <head>
        <title>title</title>
        <!--
        <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css"/>
        -->
        <link rel="stylesheet" href="css/bootstrap.min.css"/>
        <link rel="stylesheet" href="css/default.css"/>
        <xsl:call-template name="render-additional-headers"/>
      </head>
      <body>
        <!-- main content -->
        <xsl:for-each select="*">
          <xsl:call-template name="render-content"/>
        </xsl:for-each>

        <!-- client scripts -->
        <!--
        <script src="//code.jquery.com/jquery-1.11.0.min.js"></script>
        <script src="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>
        -->
        <script src="js/jquery-1.11.0.min.js"></script>
        <script src="js/bootstrap.min.js"></script>
        <script src="js/default.js"></script>
        <xsl:call-template name="render-additional-scripts"/>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>