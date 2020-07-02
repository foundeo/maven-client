component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Artifact Version Data: getArtifactVersion()", function() {
			
			var maven = new root.models.Maven();
			var groupId = "org.apache.logging.log4j";
			var artifactId = "log4j";
			var version = "2.13.3";

			var md = maven.getArtifactVersion(groupId, artifactId, version);

			debug(md);

			it( "can get metadata", function() {
				expect( md ).toBeStruct();
			} );

			it( "dependencies should be an arry", function() {
				expect( md.dependencies ).toBeArray();
			} );

			it( "should have dependencies in the array", function() {
				expect( arrayLen(md.dependencies) ).toBeGT(0);
			} );

			it( "should not have property tokens in versions", function() {
				for (local.dep in md.dependencies) {
					if (len(local.dep.version)) {
						expect(local.dep.version).notToInclude("${", "Version Should not include ${}: #local.dep.version#");
					}
				}
				expect( arrayLen(md.dependencies) ).toBeGT(0);
			} );



			


			
		} );
	}

}