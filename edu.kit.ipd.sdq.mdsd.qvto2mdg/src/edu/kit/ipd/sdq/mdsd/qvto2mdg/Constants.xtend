package edu.kit.ipd.sdq.mdsd.qvto2mdg

static class Constants {
	// Weights #4: best results on class-level	
//	final val MODULE_WEIGHT = 0;		// Not required for MDG file since Bunch must deduce this 
//	final val WRITE_WEIGHT = 15/*0*/;	// Use higher values than read weight for target-driven decomposition
//	final val READ_WEIGHT = 5;			// Use higher values than write weight for source-driven decomposition
//	final val READ_BODY_WEIGHT = 5;		// Use lower values if navigations within method body do not count as much
//	final val CALL_WEIGHT = 10;			// Should be sufficiently high to regard call structure
//	final val PACKAGE_WEIGHT = 15/*0*/;	// Only use if package structure should be respected
//	final val REFERENCE_WEIGHT = 0;		// Consider references between classes (and thus across packages)
//	final val CONTAINMENT_WEIGHT = 0;	// Consider containment references between classes
//	final val INHERITANCE_WEIGHT = 0;	// Inheritance is another form of reference

	// Weights #5: best results on package-level, makes more sense to put more weight on calls
//	final val MODULE_WEIGHT = 0;		// Not required for MDG file since Bunch must deduce this 
//	final val WRITE_WEIGHT = 15/*0*/;	// Use higher values than read weight for target-driven decomposition
//	final val READ_WEIGHT = 5;			// Use higher values than write weight for source-driven decomposition
//	final val READ_BODY_WEIGHT = 5;		// Use lower values if navigations within method body do not count as much
//	final val CALL_WEIGHT = 20;			// Should be sufficiently high to regard call structure
//	final val PACKAGE_WEIGHT = 15/*0*/;	// Only use if package structure should be respected
//	final val REFERENCE_WEIGHT = 0;		// Consider references between classes (and thus across packages)
//	final val CONTAINMENT_WEIGHT = 0;	// Consider containment references between classes
//	final val INHERITANCE_WEIGHT = 0;	// Inheritance is another form of reference

	// Weights #6 used to cluster CompositeActivity2Process
	public static final val MODULE_WEIGHT = 0;		// Not required for MDG file since Bunch must deduce this 
	public static final val WRITE_WEIGHT = 1/*0*/;	// Use higher values for target-driven decomposition
	public static final val READ_WEIGHT = 15;			// Use higher values for source-driven decomposition
	public static final val READ_BODY_WEIGHT = 0;		// Use lower values if access from within method body do not count as much
	public static final val CALL_WEIGHT = 5;			// Should be sufficiently high to regard call structure
	public static final val PACKAGE_WEIGHT = 15/*0*/;	// Only use if package structure should be respected
	public static final val REFERENCE_WEIGHT = 0;		// Consider references between classes (and thus across packages)
	public static final val CONTAINMENT_WEIGHT = 0;	// Consider containment references between classes
	public static final val INHERITANCE_WEIGHT = 0;	// Inheritance is another form of reference

	public static final val reduceToPackageLevel = false;
										// All model dependencies are considered at package level
	public static final val noModelDependencies = true;
										// No model dependencies are considered, 
										// to be used for similarity measurement tools
}