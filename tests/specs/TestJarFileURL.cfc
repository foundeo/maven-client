component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Artifact Jar File: getJarFileURL()", function() {
			
			var maven = new root.models.Maven();
			var groupId = "org.apache.logging.log4j";
			var artifactId = "log4j-core";
			var version = "2.13.3";

			var jarURL = maven.getJarFileURL(groupId, artifactId, version);

			debug(jarURL);

			it( "should be a url", function() {
				expect( len(jarURL) ).toBeGT(0);
				expect( jarURL ).toBeURL();
			} );

			it( "should have a status of 200", function() {
				cfhttp(url=jarURL, method="HEAD", result="local.result");
				expect(local.result.statusCode).toInclude("200");
			} );


			
		} );
	}

}