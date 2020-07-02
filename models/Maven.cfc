component {
	
	variables.repositoryBaseURL = "https://maven-central.storage.googleapis.com/maven2/";

	public function getRepositoryBaseURL() {
		return variables.repositoryBaseURL;
	}

	public function setRepositoryBaseURL(string baseURL) {
		variables.repositoryBaseURL = arguments.baseURL;
	}

	public function getArtifactMetadata(groupId, artifactId) {
		var addr = getRepositoryBaseURL() & replace(groupId, ".", "/", "ALL") & "/" & artifactId & "/";
		var httpResult = "";
		var metaData = "";
		var md = {"groupId":"", "artifactId":"", "versioning": {"latest":"", "release":"", "versions":[], "lastUpdated":""}};
		cfhttp(url="#addr#maven-metadata.xml", method="get", redirect=true, result="httpResult");
		if (httpResult.statusCode contains "200"){
			if (isSafeXML(httpResult.fileContent)) {
				metaData = xmlParse(httpResult.fileContent);
				md.groupId = metaData.xmlRoot.groupId.XmlText;
				md.artifactId = metaData.xmlRoot.artifactId.XmlText;
				if (structKeyExists(metaData.xmlRoot, "versioning")) {
					md.versioning.latest = metaData.xmlRoot.versioning.latest.XmlText;
					md.versioning.release = metaData.xmlRoot.versioning.release.XmlText;
					for (local.version in metaData.xmlRoot.versioning.versions.XmlChildren) {
						arrayAppend(md.versioning.versions, local.version.XmlText);
					}
				}
			} else {
				throw(message="Metadata XML Contained Potentially Unsafe Directives");
			}
			
		} else {
			throw(message="Repository Request to #addr# returned status: #httpResult.statusCode#");
		}
		return md;
	}

	public function getArtifactVersion(groupId, artifactId, version) {
		var addr = getRepositoryBaseURL() & replace(groupId, ".", "/", "ALL") & "/" & artifactId & "/" & version & "/" & artifactId & "-" & version & ".pom";
		var httpResult = "";
		
		cfhttp(url="#addr#", method="get", redirect=true, result="httpResult");
		if (httpResult.statusCode contains "200"){
			return parsePOM(httpResult.fileContent);
		} else {
			throw(message="Repository Request to #addr# returned status: #httpResult.statusCode#");
		}
	}

	public function getJarFileURL(groupId, artifactId, version) {
		var addr = getRepositoryBaseURL() & replace(groupId, ".", "/", "ALL") & "/" & artifactId & "/" & version & "/" & artifactId & "-" & version & ".jar";
		return addr;
	}

	public function getArtifactAndDependencyJarURLs(groupId, artifactId, version, scopes="runtime,compile", depth=0) {
		var meta = getArtifactVersion(groupId, artifactId, version);
		var cache = {};
		var result = [];
		var dep = "";
		var d = "";
		var v = "";
		if (meta.packaging IS "jar") {
			result = [{"download":getJarFileURL(groupId, artifactId, version), "groupId":arguments.groupId, "artifactId":arguments.artifactId, "version":arguments.version}];
		}
		for (dep in meta.dependencies) {
			if (!listFindNoCase(arguments.scopes, dep.scope)) {
				//skip
				continue;
			}
			if (dep.optional) {
				continue;
			}
			if (!cache.keyExists(dep.groupId & "/" & dep.artifactId)) {
				d = getArtifactMetadata(dep.groupId, dep.artifactId);
				if (len(dep.version)) {
					d.wantedVersion = [dep.version];
				}
				cache[dep.groupId & "/" & dep.artifactId] = d;
			} else if (len(dep.version)) {
				//add as a wanted version
				arrayAppend(cache[dep.groupId & "/" & dep.artifactId].wantedVersion, dep.version);
			}
		}
		
		for (dep in cache) {
			dep = cache[dep];
			if (!dep.keyExists("wantedVersion")) {
				v = dep.versioning.release;
			} else {
				//todo pick highest version
				v = dep.wantedVersion[1];
			}
			if (dep.artifactId == arguments.artifactId && dep.groupId == arguments.groupId) {
				continue;
			}
			if (meta.packaging IS "pom" && dep.scope IS "import") {
				if (depth > 10) {
					throw(message="Maximum depth of 10 reached");
				}
				d = getArtifactAndDependencyJarURLs(dep.groupId, dep.artifactId, v, scopes, depth++);
				for (v in d) {
					if (!arrayFind(result, v)) {
						arrayAppend(result, v);	
					}
				}
			} else {
				arrayAppend(result,{"download":getJarFileURL(dep.groupId, dep.artifactId, v), "groupId":dep.groupId, "artifactId":dep.artifactId, "version":v});
			}
		}
		return result;
	}

	public function parsePOM(xmlString) {
		var pom = {"name":"", "packaging"="", "dependencies":[], "xml"={}};
		var xml = "";
		var dep = "";
		var d = "";
		if (isSafeXML(xmlString)) {
			xml = xmlParse(xmlString);
			if (xml.xmlRoot.keyExists("name")) {
				pom.name = xml.xmlRoot.name.xmlText;
			}
			if (xml.xmlRoot.keyExists("packaging")) {
				pom.packaging = xml.xmlRoot.packaging.xmlText;
			}
			pom.xml = xml;
			if (xml.xmlRoot.keyExists("dependencies")) {
				pom.dependencies = parseDependencies(xml, xml.xmlRoot.dependencies);
			}
			if (xml.xmlRoot.keyExists("dependencyManagement")) {
				dep = parseDependencies(xml, xml.xmlRoot.dependencyManagement.dependencies);
				if (arrayIsEmpty(pom.dependencies)) {
					pom.dependencies = dep;
				} else {
					for (d in dep) {
						arrayAppend(pom.dependencies, d);
					}
				}
			}
		} else {
			throw(message="POM XML Contained Potentially Unsafe Directives");
		}
		return pom;
	}

	private function parseDependencies(rootXml, node) {
		var dep = "";
		var d = "";
		var deps = [];
		var prop = "";
		var p = "";
		//Default scope is compile: https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html
		for (dep in node.XmlChildren) {
			d = {"groupId":"", "artifactId":"", "scope":"compile", "type":"", "version":"", "optional":false};
			d.groupId = dep.groupId.XmlText;
			d.artifactId = dep.artifactId.xmlText;
			if (dep.keyExists("version")) {
				d.version = dep.version.xmlText;
				if (d.version == "${project.version}") {
					d.version = rootXml.XmlRoot.version.xmlText;
				} else if (d.version contains "${" && rootXml.XmlRoot.keyExists("properties")) {
					//check properties ${prop.name}
					for (prop in rootXml.XmlRoot.properties.XmlChildren) {
						if (find("${" & prop.XmlName & "}", d.version)) {
							d.version = replace(d.version, "${" & prop.XmlName & "}", prop.xmlText);
						}
					}
				}
			}
			if (dep.keyExists("scope")) {
				d.scope = dep.scope.xmlText;
			}
			if (dep.keyExists("type")) {
				d.type = dep.type.xmlText;
			}
			if (dep.keyExists("optional")) {
				d.optional = dep.optional.xmlText;
			}
			arrayAppend(deps, d);
		}
		return deps;
	}

	private function isSafeXML(xml) {
		if (findNoCase("!doctype", arguments.xml)) {
			return false;
		}
		if (findNoCase("!entity", arguments.xml)) {
			return false;
		}
		if (findNoCase("!element", arguments.xml)) {
			return false;
		}
		if (find("XInclude", arguments.xml)) {
			return false;
		}
		//may be safe
		return true;
	}
	
	


}