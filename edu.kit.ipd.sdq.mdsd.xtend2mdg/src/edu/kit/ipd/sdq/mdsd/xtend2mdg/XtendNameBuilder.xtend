package edu.kit.ipd.sdq.mdsd.xtend2mdg

import org.apache.log4j.Logger
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EModelElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.xtend.core.xtend.XtendClass
import org.eclipse.xtend.core.xtend.XtendFunction
import org.eclipse.xtext.xbase.XFeatureCall
import javax.inject.Inject

///////////////////////////////////////////////////////////////////////////////////////////////////
// This class is used for generating unique names for QVTO concepts.
//
// @author Andreas Rentschler
///////////////////////////////////////////////////////////////////////////////////////////////////
class XtendNameBuilder {
	@Inject extension XtendExpressionHelper

	private final static val log = Logger.getLogger(XtendNameBuilder.name);

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Create a unique name for an Xtend module
	
	protected def dispatch String moduleName(XtendClass clazz) {
		switch clazz {
			case clazz.selfAndSuperClasses.map[members].flatten.filter(XtendFunction)
				.exists[f | f.name == Constants.ENTRY_METHOD_NAME]: "mainmodule_"
			default: "module_"
		} + clazz.name
	} 
	protected def dispatch String moduleName(EObject classifier) {
		log.warn("Warning occurred in moduleName: unsupported type " + classifier.class)
		"unsupported type " + classifier.class
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Create a unique name for an Xtend operation
	
	protected def dispatch operationName(XtendFunction function) {
		val moduleNamePrefix = (function.eContainer as XtendClass).name + "_"
		val indexOfOperation = (function.eContainer as XtendClass).members.filter(XtendFunction)
			.filter(o | o.name == function.name).toList.indexOf(function)
		val moduleNameSuffix = "" + if (indexOfOperation > 0) (indexOfOperation + 1) else ""
		switch function {
			case function.name == Constants.ENTRY_METHOD_NAME: "entry_"
			default: "def_"
		} +
		switch function {
			case function.generatesFile: "out_" 
			default: ""
		} +
			(if (!function.name.startsWith(moduleNamePrefix)) moduleNamePrefix else "") +
			function.name + 
			moduleNameSuffix
	}
	protected def dispatch operationName(EObject function) {
		log.warn("Warning occurred in operationName: unsupported type " + function.class)
		"unsupported type " + function.class
	}
	
	protected def generatorName(XtendFunction function) {
		"file_" + function.operationName
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Create a unique name for a model element
	
	protected def dispatch String modelElementName(EClass cls) {
		if (cls.EPackage == null) {
			log.error("modelElementName: Error, class " + cls + " is null, is it loaded in the workflow?")
		}
		"class_" + 
			cls.EPackage.name + "_" + 
			cls.name
	} 
	protected def dispatch String modelElementName(EPackage pkg) {
		"package_" + 
			pkg.name
	} 
	protected def dispatch String modelElementName(EModelElement element) {
		log.error("modelElementName: Error, " + element + " is not supported!")
		"unsupported type " + element.class
	}
}
