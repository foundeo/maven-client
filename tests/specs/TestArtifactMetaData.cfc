component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Artifact MetaData: getArtifactMetadata()", function() {
			
			var maven = new root.models.Maven();
			var groupId = "org.apache.logging.log4j";
			var artifactId = "log4j";

			var md = maven.getArtifactMetadata(groupId, artifactId);

			debug(md);

			it( "can get metadata", function() {
				expect( md ).toBeStruct();
			} );

			it( "populated groupId", function() {
				expect( md.groupId ).toBe(groupId);
			} );

			it( "populated artifactId", function() {
				expect( md.artifactId ).toBe(artifactId);
			} );

			it( "versions should be a non empty array", function() {
				expect( md.versioning.versions ).toBeArray();
				expect( arrayLen(md.versioning.versions) ).toBeGT(0);
			} );

			it( "should find log4j version 2.13.3", function() {
				expect( arrayFind(md.versioning.versions, "2.13.3") ).toBeTrue();
			} );

			it( "should not find log4j non existant version 2.0.9999", function() {
				expect( arrayFind(md.versioning.versions, "2.0.9999") ).toBeFalse();
			} );


			
		} );
	}

}