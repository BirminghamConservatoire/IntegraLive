<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
                exclude-result-prefixes="exslt msxsl"
>
  <xsl:import href="lib.string.join.xsl"/>

  <xsl:template name="embed-module-declarations">
    <xsl:param name="modules"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:for-each select="node()">
        <xsl:choose>
          <xsl:when test="self::module">
            <xsl:call-template name="embed-module-declaration">
              <xsl:with-param name="modules" select="$modules"/>
              <xsl:with-param name="originGuid" select="substring-after(name(signature/*),'ORIGIN-')"/>
              <xsl:with-param name="moduleGuid" select="substring-after(name(signature/*/*),'MODULE-')"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="parent::endpoints">
            <xsl:call-template name="embed-module-declaration">
              <xsl:with-param name="modules" select="$modules"/>
              <xsl:with-param name="originGuid" select="substring-after(name(../../signature/*),'ORIGIN-')"/>
              <xsl:with-param name="moduleGuid" select="substring-after(name(../../signature/*/*),'MODULE-')"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="embed-module-declarations">
              <xsl:with-param name="modules" select="$modules"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="embed-module-declaration">
    <xsl:param name="modules"/>
    <xsl:param name="originGuid"/>
    <xsl:param name="moduleGuid"/>

    <!-- interface declarations with matching originGuid -->
    <xsl:variable name="originGuidMatches" select="exslt:node-set($modules)//InterfaceDeclaration[@originGuid=$originGuid]"/>
    <!-- interface declarations with matching originGuid and moduleGuid -->
    <xsl:variable name="moduleGuidMatches" select="exslt:node-set($originGuidMatches)[@moduleGuid=$moduleGuid]"/>

    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:if test="self::module">
        <xsl:call-template name="embed-module-type">
          <xsl:with-param name="originGuidMatches" select="$originGuidMatches"/>
          <xsl:with-param name="moduleGuidMatches" select="$moduleGuidMatches"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:if test="parent::endpoints">
        <xsl:variable name="endpointName" select="name()"/>
        <xsl:copy-of select="exslt:node-set($moduleGuidMatches)/EndpointInfo/Endpoint[@Name=$endpointName]/@*"/>
        <xsl:copy-of select="exslt:node-set($moduleGuidMatches)/EndpointInfo/Endpoint[@Name=$endpointName]/node()"/>
      </xsl:if>
      <xsl:for-each select="node()">
        <xsl:call-template name="embed-module-declarations">
          <xsl:with-param name="modules" select="$modules"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:copy>

  </xsl:template>

  <xsl:template name="embed-module-type">
    <xsl:param name="originGuidMatches"/>
    <xsl:param name="moduleGuidMatches"/>

    <xsl:variable name="originGuidMatchCount" select="count(exslt:node-set($originGuidMatches))"/>
    <xsl:variable name="moduleGuidMatchCount" select="count(exslt:node-set($moduleGuidMatches))"/>

    <xsl:choose>
      <xsl:when test="$moduleGuidMatchCount=1">
        <!-- case when originGuid and moduleGuid both match uniquely -->
        <xsl:attribute name="type">
          <xsl:value-of select="exslt:node-set($moduleGuidMatches)/InterfaceInfo/@Name"/>
        </xsl:attribute>
        <!--
        <xsl:copy-of select="exslt:node-set($moduleGuidMatches)/@*"/>
        -->
      </xsl:when>
      <xsl:when test="$moduleGuidMatchCount>1">
        <!-- case when originGuid and moduleGuid both match non-uniquely -->
        <xsl:attribute name="error">
          <xsl:value-of select="concat($moduleGuidMatchCount,' module declarations found with matching OriginID and ModuleID')"/>
        </xsl:attribute>
      </xsl:when>
      <xsl:when test="$originGuidMatchCount=1">
        <!-- case when originGuid and moduleGuid don't match uniquely, but originGuid matches uniquely -->
        <xsl:attribute name="error">
          <xsl:value-of select="'1 module declaration found with matching OriginID, but none with matching ModuleID'"/>
        </xsl:attribute>
      </xsl:when>
      <xsl:when test="$originGuidMatchCount>1">
        <!-- case when originGuid and moduleGuid don't match uniquely, but originGuid matches non-uniquely -->
        <xsl:attribute name="error">
          <xsl:value-of select="count($originGuidMatchCount,' module declarations found with matching OriginID, but none with matching ModuleID')"/>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <!-- case when originGuid doesn't match anything -->
        <xsl:attribute name="error">
          <xsl:value-of select="'No modules found with matching OriginID'"/>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="embed-module-endpoint">
    <xsl:param name="endpointDeclaration"/>

    <!-- append all text-only declaration elements as attributes -->
    <xsl:for-each select="exslt:node-set($endpointDeclaration)/*">
      <xsl:choose>
        <!-- skip elements containing other elements -->
        <xsl:when test="*"></xsl:when>
        <!-- skip the Name element (already used as name of the parent element) -->
        <xsl:when test="self::Name"></xsl:when>
        <!-- render attribute if the element contains text content -->
        <xsl:when test="text()">
          <xsl:attribute name="{name()}">
            <xsl:value-of select="text()"/>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>

    <!-- append all tag elements as pipe-separated text attribute 'tags' -->
    <xsl:if test="Tags">
      <xsl:attribute name="Tags">
        <xsl:call-template name="join">
         <xsl:with-param name="src" select="Tags/*"/>
         <xsl:with-param name="sep" select="'|'"/>
        </xsl:call-template>
      </xsl:attribute>
    </xsl:if>

  </xsl:template>

</xsl:stylesheet>