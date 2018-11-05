#!/bin/sh

env SGML_CATALOG_FILES=./catalog.xml xsltproc --catalogs transclude.xsl harness.xhtml
