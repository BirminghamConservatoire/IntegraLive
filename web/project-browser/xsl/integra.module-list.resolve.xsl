<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
                exclude-result-prefixes="exslt msxsl"
>

  <!-- retrieves a module list from the specified path and decorates/filters it based on the specified ixd fragment -->
  <xsl:template name="get-module-list-decorated-filtered">
    <xsl:param name="path" />
    <xsl:param name="ixd" />

    <!-- retrieve the raw module list from the specified path -->
    <xsl:variable name="module-list" select="document($path)"/>

    <!-- decorate with reference counts based on usage within the main IXD file -->
    <xsl:variable name="module-list-decorated">
      <xsl:for-each select="exslt:node-set($module-list)">
        <xsl:call-template name="modules-decorated">
          <xsl:with-param name="ixd" select="$ixd"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <!-- process entries to ensure that originGuid/moduleGuid are unique, and latest versions are flagged as such -->
    <xsl:variable name="module-list-decorated-filtered">
      <xsl:for-each select="exslt:node-set($module-list-decorated)">
        <xsl:call-template name="modules-filtered"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:copy-of select="$module-list-decorated-filtered"/>

  </xsl:template>

  <xsl:template name="get-module">
    <xsl:variable name="path">
      <xsl:call-template name="get-module-path"/>
    </xsl:variable>
    <xsl:variable name="src" select="concat($path,'/integra_module_data/interface_definition.iid')" />
    <xsl:copy-of select="document($src)/InterfaceDeclaration" />
  </xsl:template>

  <xsl:template name="get-module-path">
    <xsl:variable name="is-native" select="contains(../@src,'Integra%20Live')"/>
    <xsl:if test="$is-native">
      <xsl:value-of select="concat('../data/',../@src,'/',@name)" />
    </xsl:if>
    <xsl:if test="not($is-native)">
      <xsl:value-of select="concat('../data/',../@src,'/integra_data/implementation/',@name)" />
    </xsl:if>
  </xsl:template>

  <!-- recursive template that appends content to each module element -->
  <xsl:template name="modules-decorated">
    <xsl:param name="ixd" />
    <xsl:copy>
      <xsl:for-each select="@*">
        <xsl:call-template name="modules-decorated">
          <xsl:with-param name="ixd" select="$ixd"/>
        </xsl:call-template>
      </xsl:for-each>
      <xsl:if test="self::module">
        <!-- get module declaration from relevant IID file -->
        <xsl:variable name="module">
          <xsl:call-template name="get-module"/>
        </xsl:variable>
        <!-- append 'refs' attribute, indicating number of references in IXD -->
        <xsl:variable name="originGuid" select="exslt:node-set($module)//@originGuid"/>
        <xsl:variable name="moduleGuid" select="exslt:node-set($module)//@moduleGuid"/>
        <xsl:attribute name="refs">
          <xsl:value-of select="count($ixd//object[@originId=$originGuid][@moduleId=$moduleGuid])"/>
        </xsl:attribute>
        <!-- append module declaration -->
        <xsl:copy-of select="$module"/>
      </xsl:if>
      <xsl:for-each select="node()">
        <xsl:call-template name="modules-decorated">
          <xsl:with-param name="ixd" select="$ixd"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>
  
  <!-- sort entries by originGuid and modification date (ensuring most recent appears first for each originGuid) -->
  <xsl:template name="modules-filtered">

    <!-- compile list of core module details in order of origin and modified date -->
    <xsl:variable name="module-list">
      <xsl:for-each select="//module">
        <xsl:sort select="InterfaceDeclaration/@originGuid"/>
        <xsl:sort select="InterfaceDeclaration/InterfaceInfo/ModifiedDate" order="descending"/>
        <module originGuid="{InterfaceDeclaration/@originGuid}"
                moduleGuid="{InterfaceDeclaration/@moduleGuid}" 
                modifiedDate="{InterfaceDeclaration/InterfaceInfo/ModifiedDate}" />
      </xsl:for-each>
    </xsl:variable>

    <!-- process sorted list to remove modules with duplicate origin/module IDs -->
    <xsl:variable name="module-list-distinct">
      <xsl:for-each select="exslt:node-set($module-list)/*">
        <!-- store a composite ID for the current module -->
        <xsl:variable name="this-id">
          <xsl:value-of select="@originGuid"/>
          <xsl:value-of select="@moduleGuid"/>
        </xsl:variable>
        <!-- store a composite ID for the preceding module -->
        <xsl:variable name="last-id">
          <xsl:if test="preceding-sibling::module">
            <xsl:value-of select="preceding-sibling::module[1]/@originGuid"/>
            <xsl:value-of select="preceding-sibling::module[1]/@moduleGuid"/>
          </xsl:if>
        </xsl:variable>
        <!-- render only if they don't match -->
        <xsl:if test="not($this-id=$last-id)">
          <xsl:copy-of select="."/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <!-- process sorted list again to flag module status as latest/legacy -->
    <xsl:variable name="module-list-distinct-with-status">
      <xsl:for-each select="exslt:node-set($module-list-distinct)/*">
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:attribute name="status">
            <xsl:choose>
              <xsl:when test="preceding-sibling::module and @originGuid=preceding-sibling::module[1]/@originGuid">
                <!-- this module has a preceding-sibling with the same origin, so we flag as an old version  -->
                <xsl:text>legacy</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <!-- flag this module as the latest version -->
                <xsl:text>latest</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:copy-of select="node()"/>
        </xsl:copy>
      </xsl:for-each>
    </xsl:variable>

    <!--
    <xsl:copy-of select="$module-list-distinct-with-status"/>
    -->

    <xsl:call-template name="modules-filtered-inner">
      <xsl:with-param name="module-list" select="$module-list-distinct-with-status"/>
    </xsl:call-template>

  </xsl:template>

  <xsl:template name="modules-filtered-inner">
    <xsl:param name="module-list"/>

    <xsl:variable name="status">
      <xsl:if test="InterfaceDeclaration">
        <xsl:call-template name="get-module-status">
          <xsl:with-param name="module-list" select="$module-list"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$status='duplicate'">
        <!-- do nothing, thus excluding duplicates from further processing -->
      </xsl:when>
      <xsl:when test="self::ControlInfo1">
        <!-- do nothing, to see if this helps limit the tree depth -->
        <!--
        <xsl:copy>
          <xsl:for-each select="*">
            <xsl:if test="not(*)">
              <xsl:attribute name="{name()}">
                <xsl:value-of select="."/>
              </xsl:attribute>
            </xsl:if>
          </xsl:for-each>
        </xsl:copy>
        -->
      </xsl:when>
      <xsl:when test="self::StreamInfo">
        <!-- do nothing, to see if this helps limit the tree depth -->
      </xsl:when>
      <xsl:when test="InterfaceDeclaration">
        <!-- copy and decorate with status -->
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:attribute name="status">
            <xsl:value-of select="$status"/>
          </xsl:attribute>
          <xsl:for-each select="node()">
            <xsl:call-template name="modules-filtered-inner">
              <xsl:with-param name="module-list" select="$module-list"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <!-- copy and recurse -->
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:for-each select="node()[not(*)][not(name()='')]">
            <!-- convert empty/text child nodes to attributes -->
            <xsl:attribute name="{name()}">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </xsl:for-each>
          <!-- handle Tags/Tag branches separately, as they require concatenation -->
          <xsl:for-each select="Tags[Tag]">
            <xsl:attribute name="Tags">
              <xsl:for-each select="Tag">
                <xsl:if test="position()>1">|</xsl:if>
                <xsl:value-of select="."/>
              </xsl:for-each>
            </xsl:attribute>
          </xsl:for-each>
          <!-- any other nodes with child elements -->
          <xsl:for-each select="node()[*][not(Tag)]">
            <xsl:call-template name="modules-filtered-inner">
              <xsl:with-param name="module-list" select="$module-list"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="get-module-status">
    <xsl:param name="module-list"/>

    <!-- store IDs in variables to avoid test scope issues -->
    <xsl:variable name="originGuid" select="InterfaceDeclaration/@originGuid"/>
    <xsl:variable name="moduleGuid" select="InterfaceDeclaration/@moduleGuid"/>

    <!-- get a unique XPath to the first module declared with this signature -->
    <xsl:variable name="first-path">
      <xsl:for-each select="(//InterfaceDeclaration[@originGuid=$originGuid][@moduleGuid=$moduleGuid]/..)[1]">
        <xsl:call-template name="get-path"/>
      </xsl:for-each>
    </xsl:variable>

    <!-- get a unique XPath to the current module -->
    <xsl:variable name="this-path">
      <xsl:call-template name="get-path"/>
    </xsl:variable>

    <!-- calculate status for this module based on whether these paths match -->
    <xsl:choose>
      <xsl:when test="$first-path=$this-path">
        <!-- if both paths match, find the relevant entry in the filtered list -->
        <xsl:variable name="match" select="exslt:node-set($module-list)//module[@originGuid=$originGuid][@moduleGuid=$moduleGuid]"/>
        <!-- decorate this module with its status (legacy/latest) as taken from the list entry  -->
        <xsl:value-of select="exslt:node-set($match)/@status"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- if not, it's a duplicate -->
        <xsl:text>duplicate</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="get-path">
    <xsl:for-each select="ancestor-or-self::*[not(.=/)]">
      <xsl:variable name="name" select="name()"/>
      <xsl:value-of select="concat('/',$name,'[',1+count(preceding-sibling::*[name()=$name]),']')"/>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>