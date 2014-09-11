<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
                exclude-result-prefixes="exslt msxsl"
>

  <xsl:template name="reify-any">
    <xsl:choose>
      <xsl:when test="self::*">
        <xsl:call-template name="reify-element-node" />
      </xsl:when>
      <xsl:when test="self::text()">
        <xsl:copy/>
      </xsl:when>
      <xsl:when test="self::comment()">
        <xsl:copy/>
      </xsl:when>
      <xsl:when test="self::processing-instruction()">
        <xsl:copy/>
      </xsl:when>
      <xsl:when test="count(.|../@*)=count(../@*)">
        <xsl:copy/>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="reify-element-node">
    <xsl:choose>
      <xsl:when test="name()='object'">
        <module>
          <xsl:attribute name="id">
            <xsl:for-each select="ancestor::object">
              <xsl:value-of select="concat(@name,'.')"/>
            </xsl:for-each>
            <xsl:value-of select="@name"/>
          </xsl:attribute>
          <xsl:copy-of select="@name"/>
          <signature>
            <xsl:element name="{concat('ORIGIN-',@originId)}">
              <xsl:element name="{concat('MODULE-',@moduleId)}">
              </xsl:element>
            </xsl:element>
          </signature>
          <endpoints>
            <xsl:for-each select="attribute">
              <xsl:call-template name="reify-any" />
            </xsl:for-each>
          </endpoints>
          <xsl:if test="object">
            <modules>
              <xsl:for-each select="object">
                <xsl:call-template name="reify-any" />
              </xsl:for-each>
            </modules>
          </xsl:if>
        </module>
      </xsl:when>
      <xsl:when test="name()='attribute'">
        <xsl:call-template name="reify-attribute-node" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{name()}">
          <xsl:for-each select="node()|@*">
            <xsl:call-template name="reify-any" />
          </xsl:for-each>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="reify-attribute-node">
    <xsl:element name="{@name}">
      <xsl:choose>
        <xsl:when test="@typeCode=1">
          <int>
            <xsl:value-of select="." />
          </int>
        </xsl:when>
        <xsl:when test="@typeCode=2">
          <float>
            <xsl:value-of select="." />
          </float>
        </xsl:when>
        <xsl:when test="@typeCode=3">
          <string>
            <xsl:value-of select="." />
          </string>
        </xsl:when>
        <xsl:otherwise>
          <xml>
            <xsl:value-of select="." />
          </xml>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>