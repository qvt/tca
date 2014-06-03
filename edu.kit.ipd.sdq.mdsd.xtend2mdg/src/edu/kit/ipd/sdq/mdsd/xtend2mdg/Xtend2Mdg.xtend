package edu.kit.ipd.sdq.mdsd.xtend2mdg

import java.util.ArrayList
import javax.inject.Inject
import org.apache.log4j.Logger
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EEnum
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtend.core.xtend.XtendClass
import org.eclipse.xtend.core.xtend.XtendField
import org.eclipse.xtend.core.xtend.XtendFile
import org.eclipse.xtend.core.xtend.XtendFunction
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.common.types.JvmTypeReference
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator

///////////////////////////////////////////////////////////////////////////////////////////////////
// This transformation parses an Xtend model-to-text transformation script and extracts call and model dependencies as 
// MDG file for use in the Bunch clustering tool. We ignore the current module structure, which is output separately 
// as a SIL file for later comparison.
//
// @author Andreas Rentschler, Michael Junker
///////////////////////////////////////////////////////////////////////////////////////////////////
@SuppressWarnings("restriction")		// Xtend BUG: cannot suppress warnings, cf. https://bugs.eclipse.org/bugs/show_bug.cgi?id=363685
class Xtend2Mdg implements IGenerator {
	@Inject extension XtendExpressionHelper
	@Inject extension XtendNameBuilder

	private var mappedModules = new ArrayList<XtendClass>
										// Keep list of modules that have been already mapped 
										// A module may be imported by multiple modules
	private var mappedModelElements = new ArrayList<EObject>
										// Keep list of model elements that have been already mapped
										// A class may be referenced multiple times from code, 
										// or references may be bidirectional)
										
	private final val matrix = new DependencyMatrix()

	private final static val log = Logger.getLogger(Xtend2Mdg.name)

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Entry point: extract call and use dependencies between operations and model elements of a transformations
	
	override doGenerate(Resource input, IFileSystemAccess fsa) {
		resources = input.resourceSet.resources

		// collect main methods from all modules
		log.info("doGenerate: detected modules with root method: " + mainModules.map[name].join(", "))
		if (mainModules.empty) return;
		
		// Map main modules (and all modules that are imported recursively)
		for (XtendClass c : mainModules)
			c.mapModule

		// Map all models used by this transformation
		// TODO: Only map elements actually used by the given transformation
		for (p : ecorePackages)
			p.mapModelElement

		// Generate sanitized output
		val outputFile = (mainModules.head.eContainer as XtendFile).package.replaceAll("\\.", "-") + ".mdg"
		log.info("doGenerate: writing output to " + outputFile)
		matrix.checkNonReflexivity
		fsa.generateFile(outputFile, matrix.mapToMdg(Constants.noModelDependencies))
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Recursively extract dependencies that occur between modules of a transformation
	// For each module, extract dependencies between operations that are defined in the module
	
	private dispatch def void mapModule(XtendClass clazz) {
		if (mappedModules.contains(clazz)) return 
		else mappedModules.add(clazz)
		//	Local operations
		for (function : clazz.members.filter(XtendFunction)) {
			// Module containment
			matrix.put(function.operationName, clazz.moduleName, Constants.MODULE_WEIGHT)
			// Operations in this module
			function.mapOperation
		}
		// Imported modules
		log.info("mapModule: " + clazz.name + " imports " + clazz.members.filter(XtendField).filter[extension].map[type.type.simpleName].join(", "))
		for (module2 : clazz.members.filter(XtendField).filter[extension].map[type.type.resolveType].filterNull) {
			// Module import dependency
			matrix.put(clazz.moduleName, module2.moduleName, Constants.MODULE_WEIGHT)
			// Recurse into module structure
			module2.mapModule
		}
		// Reused modules (inheritance)
		log.info("mapModule: " + clazz.name + " inherits " + clazz.extends?.type?.resolveType?.name)
		for (module2 : #[clazz.extends?.type?.resolveType].filterNull) {
			// Module inheritance dependency
			matrix.put(clazz.moduleName, module2.moduleName, Constants.MODULE_WEIGHT)
			// Recurse into module structure
			module2.mapModule
		}
	}

	private dispatch def void mapModule(JvmType type) {
		// we need to look up the JVM types manually based on our list of modules
		resources.map[contents].flatten.filter(XtendFile).map[xtendTypes].flatten.filter(XtendClass).findFirst[c |
			(c.eContainer as XtendFile).package + c.name == type.identifier
		]?.mapModule
	}	

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Extract dependencies that occur within an operation in a transformation
	// Types of operations supported: EntryOperation, MappingOperation, Helper

	private def mapOperation(XtendFunction function) {
		// Read dependencies (result parameter + input parameters)
		for (t : ((function.parameters?.map[parameterType] + #{function.returnType})
				.filterNull.map[type].map[getModelTypes].flatten))
			matrix.put(function.operationName, t.modelElementName, Constants.READ_WEIGHT)
		// TODO: we could check @create annotation by Dominik's Xtend2m M2M transformation extension
//		for (t : (if (operation instanceof MappingOperation) #[] else operation.result
//				).map[EType.getModelTypes].flatten)
//			matrix.put(operation.operationName, t.modelElementName, READ_WEIGHT)
		// Inferred and navigated types from any expression's type in the body (which is an JvmType)
		val types = (function.expression?.eAllContents?.filter(JvmTypeReference)?.toIterable
			?.filterNull?.map[type]?.map[getModelTypes]?.flatten)
		for (t : if (types == null) #{} else types)
			matrix.put(function.operationName, t.modelElementName, Constants.READ_BODY_WEIGHT)
		// Write dependencies (mapping result parameter, instantiations)
		// TODO: we could check @create annotation by Dominik's Xtend2m M2M transformation extension
		val generator = function.callerFunctionThatGeneratesFile
		if (generator != null)
			matrix.put(function.operationName, generator.generatorName, Constants.WRITE_WEIGHT)
		// Call dependencies (map)
		for (e : function.calleeFunctions)
			matrix.put(function.operationName, e.operationName, Constants.CALL_WEIGHT)
		// TODO: constructor calls via new()
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Recursively extract dependencies that occur between model elements from models

	private def dispatch void mapModelElement(EClass cls) {
		if ((cls.eContainer as EPackage).name == "ecore") return
		else if (mappedModelElements.contains(cls) || Constants.reduceToPackageLevel) return 
		else mappedModelElements.add(cls)
		// Inheritance dependencies
		for (c : cls.ESuperTypes) {
			c.mapModelElement
			matrix.put(cls.modelElementName, c.modelElementName, Constants.INHERITANCE_WEIGHT)
		}
		// Reference type dependencies (only in one direction, reflexive edges are not supported by Bunch)
		for (r : cls./*EReferences*/EStructuralFeatures.filter(typeof(EReference))) {
			val c = r.EReferenceType
			c.mapModelElement
			matrix.put(cls.modelElementName, c.modelElementName, if (r.containment) Constants.CONTAINMENT_WEIGHT else Constants.REFERENCE_WEIGHT)
		}
		// Reference container package
		if (cls.eContainer instanceof EPackage)
			(cls.eContainer as EPackage).mapModelElement
	}

	private def dispatch void mapModelElement(EPackage pkg) {
		if (mappedModelElements.contains(pkg)) return 
		else mappedModelElements.add(pkg)
		// Package and class dependencies
		for (e : pkg.ESubpackages + (if (Constants.reduceToPackageLevel) #[] else pkg.EClassifiers.filter(e|!(e instanceof EEnum)))) {
			e.mapModelElement
			matrix.put(e.modelElementName, pkg.modelElementName, Constants.PACKAGE_WEIGHT)
		}
	}

	private def dispatch void mapModelElement(EClassifier classifier) {
		log.warn("mapModelElement: unsupported type " + classifier.class)
	}
}
