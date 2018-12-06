#!/bin/sh

env SGML_CATALOG_FILES=./catalog.xml xsltproc --catalogs harness.xsl harness.xhtml
