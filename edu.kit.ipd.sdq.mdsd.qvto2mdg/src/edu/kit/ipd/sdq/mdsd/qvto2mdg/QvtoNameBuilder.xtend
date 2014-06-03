package edu.kit.ipd.sdq.mdsd.qvto2mdg

import org.apache.log4j.Logger
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EModelElement
import org.eclipse.emf.ecore.EOperation
import org.eclipse.emf.ecore.EPackage
import org.eclipse.m2m.internal.qvt.oml.expressions.Constructor
import org.eclipse.m2m.internal.qvt.oml.expressions.EntryOperation
import org.eclipse.m2m.internal.qvt.oml.expressions.Helper
import org.eclipse.m2m.internal.qvt.oml.expressions.ImperativeOperation
import org.eclipse.m2m.internal.qvt.oml.expressions.Library
import org.eclipse.m2m.internal.qvt.oml.expressions.MappingOperation
import org.eclipse.m2m.internal.qvt.oml.expressions.Module
import org.eclipse.m2m.internal.qvt.oml.expressions.OperationalTransformation

// This class is used for generating unique names for QVTO concepts
// @author Andreas Rentschler
class QvtoNameBuilder {
	
	private final static val log = Logger.getLogger(QvtoNameBuilder.name);

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Create a unique name for a QVTo module
	protected def dispatch String moduleName(Module module) {
		"module_" + 
			module.name
	} 
	protected def dispatch String moduleName(Library library) {
		"library_" + 
			library.name
	} 
	protected def dispatch String moduleName(OperationalTransformation transformation) {
		"mainmodule_" + 
			transformation.name
	} 
	protected def dispatch String moduleName(EClassifier classifier) {
		log.warn("Warning occurred in moduleName: unsupported type " + classifier.class); "unsupported type " + classifier.class
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Create a unique name for a QVTo operation
	protected def dispatch operationName(ImperativeOperation operation) {
		val moduleNamePrefix = operation.EContainingClass.name + "_"
		val indexOfOperation = operation.EContainingClass.EOperations.filter(o | o.name == operation.name).toList.indexOf(operation)
		val moduleNameSuffix = "" + if (indexOfOperation > 0) (indexOfOperation + 1) else ""
		switch operation {
			EntryOperation: "entry"
			MappingOperation: "mapping" 
			// BUG: isQuery should be set in QVTOParser.gi by calling setIsQuery, but obviously isn't set
			Helper case operation.isQuery: "query"
			Helper case !operation.isQuery: "helper"
			Constructor: "constructor"
			default: "unknown"
		} + "_" +
			(if (!operation.name.startsWith(moduleNamePrefix)) moduleNamePrefix else "") +
			operation.name + 
			moduleNameSuffix
	}
	protected def dispatch operationName(EOperation operation) {
		"unsupported type " + operation.class
	}

	// Create a unique name for a model element
	protected def dispatch String modelElementName(EClass cls) {
		"class_" + 
			cls.EPackage.name + "_" + 
			cls.name
	} 
	protected def dispatch String modelElementName(EPackage pkg) {
		"package_" + 
			pkg.name
	} 
	protected def dispatch String modelElementName(EModelElement element) {
		"unsupported type " + element.class
	}
}
