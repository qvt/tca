package edu.kit.ipd.sdq.mdsd.qvto2mdg

import java.util.ArrayList
import javax.inject.Inject
import org.apache.log4j.Logger
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EEnum
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.m2m.internal.qvt.oml.expressions.ImperativeCallExp
import org.eclipse.m2m.internal.qvt.oml.expressions.ImperativeOperation
import org.eclipse.m2m.internal.qvt.oml.expressions.MappingOperation
import org.eclipse.m2m.internal.qvt.oml.expressions.Module
import org.eclipse.m2m.internal.qvt.oml.expressions.ObjectExp
import org.eclipse.m2m.internal.qvt.oml.expressions.OperationalTransformation

// This transformation parses a QVTo script and extracts call and model dependencies as 
// MDG file for use in the Bunch clustering tool. We ignore the current module structure, 
// which is output separately as a SIL file for later comparison.
//
// Algorithm:
// * For current module: recurse into imported modules 
//   * For all methods in module:
//     * Extract implicit/explicit read/write dependencies
//     * Extract package dependencies 
//     * Extract call/inherit/merge/disjuncts dependencies
// * For involved models: recurse into structure
//   * Extract package structure  
//   * Extract inheritance dependencies
//   * Extract reference dependencies (single direction only)
//   * Extract containment reference dependencies
// Please note the weight parameters below; a zero weight leads to dependencies being ignored!

// To use the bunch comparison utilities:
// * You must remove class and package nodes in .bunch SIL file, 
//   e.g. using regex find/replace "class\_\w+\_\w+, " and ""package\_\w+, "
// * You must create an MDG file without model elements using "noModelDependencies = true"

// Structure of a QVTo transformation's AST:
//	OperationalTransformation
//		modelParameter(ModelParameter[])
//			name
//			kind(DirectionKind)
//			metamodel(EPackage[])
//		eAllOperations(EntryOperation,Helper,MappingOperation)
//			name
//			body(OperationBody).content(OCLOperation[])
//				... OperationCallExp.referredOperation(EOperation)
//						.eContainer(EClass) = 
//			eParameters(VarParameter[])
//			eType(EClass) = result(VarParameter[])[0]
//		moduleImport(ModuleImport[]).importedModule(Library,...)

//@SuppressWarnings("restricted")  // Still doesn't work in latest Xtend version
class Qvto2Mdg {
	
	@Inject extension QvtoNameBuilder
	@Inject extension QvtoExpressionHelper
	
	private final static val log = Logger.getLogger(Qvto2Mdg.name);
	private final val matrix = new DependencyMatrix();

	private var OperationalTransformation transformation;
	private var mappedModules = new ArrayList<Module>;
										// Keep list of modules that have been already mapped 
										// A module may be imported by multiple modules
	private var mappedModelElements = new ArrayList<EObject>;
										// Keep list of model elements that have been already mapped
										// A class may be referenced multiple times from code, 
										// or references may be bidirectional)
										
	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Entry point: extract call and use dependencies between operations and model elements of a transformations 
	def mapTransformation(OperationalTransformation transformation) {
		this.transformation = transformation
		
		// Map main module (and all modules that are imported recursively)
		transformation.mapModule
		
		// Map all models used by this transformation
		transformation.mapModels
		
		// Sanity check
		matrix.checkNonReflexivity
		
		// Return MDG format
		matrix.mapToMdg(Constants.noModelDependencies)
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Recursively extract dependencies that occur between modules of a transformation
	// For each module, extract dependencies between operations that are defined in the module
	private def void mapModule(Module module) {
		if (mappedModules.contains(module)) return 
		else mappedModules.add(module)
		//	Local operations
		for (operation : module.EAllOperations.filter(typeof(ImperativeOperation))) {
			// Module containment
			matrix.put(operation.operationName, module.moduleName, Constants.MODULE_WEIGHT)
			// Operations in this module
			operation.mapOperation
		}
		// Imported modules
		for (module2 : module.moduleImport.map[importedModule]) {
			// Module import dependency
			matrix.put(module.moduleName, module2.moduleName, Constants.MODULE_WEIGHT)
			// Recurse into module structure
			module2.mapModule
		}
	}

	// Extract dependencies that occur within an operation in a transformation
	// Types of operations supported: EntryOperation, MappingOperation, Helper
	private def mapOperation(ImperativeOperation operation) {
		// Read dependencies (context parameter + input parameters, navigated types)
		// TODO: check if parameter type is in/out/inout
		for (t : ((operation.EParameters + #{operation.context})
			.filter(e|e != null).map[EType.getModelTypes].flatten))
			matrix.put(operation.operationName, t.modelElementName, Constants.READ_WEIGHT)
		for (t : (if (operation instanceof MappingOperation) #[] else operation.result
				).map[EType.getModelTypes].flatten)
			matrix.put(operation.operationName, t.modelElementName, Constants.READ_WEIGHT)
		// Inferred and navigated types from any OCLExpression's type (which is an ETypedElement)
		for (t : operation.getExpressions.filter(e|!(e instanceof ObjectExp))
				.map[type].filter(e|e != null).map[getModelTypes].flatten)
			matrix.put(operation.operationName, t.modelElementName, Constants.READ_BODY_WEIGHT)
		// Write dependencies (mapping result parameter, instantiations)
		for (t : (if (operation instanceof MappingOperation) operation.result else #[]
				).map[EType.getModelTypes].flatten)
			matrix.put(operation.operationName, t.modelElementName, Constants.WRITE_WEIGHT)
		for (t : operation.getExpressions.filter(typeof(ObjectExp))
				.map[type.getModelTypes].flatten)
			matrix.put(operation.operationName, t.modelElementName, Constants.WRITE_WEIGHT)
		// Call dependencies (map)
		for (e : operation.getExpressions.filter(typeof(ImperativeCallExp)))
			// Only one method is referenceable, so we must scan for dispatch methods in scope
			for (o : 
				(#{operation.EContainingClass as Module} + 
				(operation.EContainingClass as Module).moduleImport.map[importedModule])
					.map[EOperations].flatten.filter(e2 | e2.name.equals(e.referredOperation.name)).toList) {
				matrix.put(operation.operationName, o.operationName, Constants.CALL_WEIGHT) }
		// TODO: InstantiationExp.name and .argument[] may specify a constructor call 
		// Reuse dependencies (disjunct, merge, map, constructor?)
		if (operation instanceof MappingOperation)
			for (o : operation.disjunct + operation.merged + operation.inherited)
				matrix.put(operation.operationName, o.operationName, Constants.CALL_WEIGHT)
		// Not all packages might be referenced in the transformation signature
		// Thus, we must add all referenced types, if they haven't been added before.
		// NB: This is no longer needed, since we parse all defined model types, not just those in the signature 
//		for (t : (
//				operation.EParameters + 
//				operation.result + 
//				operation.getExpressions
//			).map[EType])
//			t.mapModelElement
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Extract dependencies that occur between elements in a model for all models used by the given transformation
	private def mapModels(OperationalTransformation transformation) {
		// Parsing one module is enough, since imported modules must specify same model types.
		// Iterate over the domains, where each domain's model type refers to (a list of) packages (usually only one per type) 
		for (p : metamodels(transformation))
			p.mapModelElement
	}
	private def metamodels(OperationalTransformation transformation) {
		// Parse model types defined in module
		transformation.usedModelType.map[metamodel].flatten
		// Parse model types in signature
//		transformation.modelParameter.map[EType].filter(typeof(ModelType)).map[metamodel].flatten
	}

	// Recursively extract dependencies that occur between model elements from models
	private def dispatch void mapModelElement(EClass cls) {
		if (mappedModelElements.contains(cls) || Constants.reduceToPackageLevel) return 
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
