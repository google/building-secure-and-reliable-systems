<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="h">

  <!-- Add title heading elements for different admonition types that do not already have headings in markup -->
  <xsl:param name="add.title.heading.for.admonitions" select="1"/>

  <!-- Drop @width attributes from table headers if present -->
  <xsl:template match="h:th/@width"/>
  
      <!-- Admonition handling -->
  <xsl:template match="h:div[@data-type='note' and @class='dive']">
    <xsl:param name="add.title.heading.for.admonitions" select="$add.title.heading.for.admonitions"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <!-- Add admonition heading title if $add.title.heading.for.admonitions is enabled AND there is not a heading first child already -->
      <xsl:if test="($add.title.heading.for.admonitions = 1) and
		    not(*[1][self::h:h1|self::h:h2|self::h:h3|self::h:h4|self::h:h5|self::h:h6])">
	<h6>DEEP DIVE</h6>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
    
     <xsl:template match="h:h5[@class='dive']">
    <h5>DEEP DIVE: <xsl:value-of select="node()"/></h5>
    </xsl:template>
    
     <xsl:template match="h:h1[@class='dive']">
    <h1>DEEP DIVE: <xsl:value-of select="node()"/></h1>
    </xsl:template>
    
    <xsl:template match="h:h2[@class='dive']">
    <h2>DEEP DIVE: <xsl:value-of select="node()"/></h2>
    </xsl:template>

</xsl:stylesheet>
