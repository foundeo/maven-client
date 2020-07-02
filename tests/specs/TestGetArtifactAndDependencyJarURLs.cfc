component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Artifact Dependencies Jar File: getArtifactAndDependencyJarURLs()", function() {
			
			var maven = new root.models.Maven();
			var groupId = "org.apache.logging.log4j";
			var artifactId = "log4j-core";
			var version = "2.13.3";

			
			var jars = maven.getArtifactAndDependencyJarURLs(groupId, artifactId, version);

			debug(jars);
			
			it( "should be a array", function() {
				expect( jars ).toBeArray();
			} );
			
			it( "should have multiple jars", function() {
				expect( arrayLen(jars) ).toBeGT(0);
			} );

			it( "should have log4j-core jar", function() {
				local.found = false;
				for (local.j in jars) {
					if (local.j.download contains "log4j-core") {
						local.found = true;
						break;
					}
				}
				expect( local.found ).toBeTrue();
			} );

			it( "should have log4j-api jar", function() {
				local.found = false;
				for (local.j in jars) {
					if (local.j.download contains "log4j-api") {
						local.found = true;
						break;
					}
				}
				expect( local.found ).toBeTrue();
			} );

			it( "should not have test jars", function() {
				local.found = false;
				for (local.j in jars) {
					if (local.j.download contains "junit") {
						local.found = true;
						break;
					}
				}
				expect( local.found ).toBeFalse();
			} );
			
			
			it( "should not have optional jars", function() {
				local.found = false;
				for (local.j in jars) {
					if (local.j.download contains "jackson-databind") {
						local.found = true;
						break;
					}
				}
				expect( local.found ).toBeFalse();
			} );
			


			
		} );
	}

}