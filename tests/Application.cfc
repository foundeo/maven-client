component {

    this.name = "MavenTestingSuite" & hash(getCurrentTemplatePath());
    this.sessionManagement  = false;
    this.applicationTimeout = createTimeSpan( 0, 0, 15, 0 );

    testsPath = getDirectoryFromPath( getCurrentTemplatePath() );
    this.mappings[ "/tests" ] = testsPath;
    rootPath = REReplaceNoCase( this.mappings[ "/tests" ], "tests(\\|/)", "" );
    this.mappings[ "/root" ] = rootPath;
    this.mappings[ "/testbox" ] = rootPath & "/testbox";
}
