package edu.kit.ipd.sdq.mdsd.qvto2mdg

import java.util.List
import java.util.Set
import org.apache.log4j.Logger
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EModelElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.m2m.internal.qvt.oml.expressions.ImperativeOperation
import org.eclipse.m2m.internal.qvt.oml.expressions.MappingOperation
import org.eclipse.m2m.internal.qvt.oml.expressions.ModelType
import org.eclipse.m2m.internal.qvt.oml.expressions.Module
import org.eclipse.m2m.qvt.oml.ecore.ImperativeOCL.OrderedTupleType
import org.eclipse.ocl.ecore.CollectionType
import org.eclipse.ocl.ecore.OCLExpression
import org.eclipse.ocl.ecore.TupleType

// This class contains helper methods to operate on OCL expressions contained in QVTO scripts 
// @author Andreas Rentschler
class QvtoExpressionHelper {
	
	protected final static val log = Logger.getLogger(QvtoExpressionHelper.name);

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Resolve concrete classes and packages that are (in)directly referred to by a potentially complex OCL type 
	protected def dispatch List<EModelElement> getModelTypes(Object type) {
		log.warn("Warning occurred in getModelTypes: unsupported type " + type.class); #[]
	}
	protected def dispatch List<EModelElement> getModelTypes(ModelType type) {
		// A model type should only reference a single package, which we return
		#[(type.metamodel.get(0) as EModelElement)]
	}
	protected def dispatch List<EModelElement> getModelTypes(EClass type) {
		// First, we need to filter out references to transformation modules (which are of type EPackage/EClass)
//		// A bit too restrictive: model types in the signature may be only a subset of the referenceable model types		
//		if (!transformation.metamodels.map[eAllContents.toList].flatten.toList.contains(type)) return #[]
//		// Less restrictive: all model types that are declared in the prologue
//		if (!transformation.usedModelType.map[metamodel].flatten.toList.eAllContents.contains(type)) return #[]
		// May be too less restrictive: just sort out modules and types defined in modules like the Stdlib
		if (type instanceof Module || type.EPackage instanceof Module) return #[]
		
		if (Constants.reduceToPackageLevel) #[type.EPackage as EModelElement]
		else #[type as EModelElement]
	}
	protected def dispatch List<EModelElement> getModelTypes(CollectionType type) {
		type.elementType.getModelTypes
	}
	protected def dispatch List<EModelElement> getModelTypes(TupleType type) {
		// Ignore attribute types, only reference types refer to metamodel elements
		type.EAllStructuralFeatures.filter(typeof(EReference)).map(e|e.EType.getModelTypes).flatten.toList
	}
	protected def dispatch List<EModelElement> getModelTypes(OrderedTupleType type) {
		// Ignore attribute types, only reference types refer to metamodel elements
		type.EAllStructuralFeatures.filter(typeof(EReference)).map(e|e.EType.getModelTypes).flatten.toList
	}
	protected def dispatch List<EModelElement> getModelTypes(EClassifier type) {
		#[]  // Skip because no concrete handler exists (PrimitiveType, VoidType, AnyType, ...)
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Collect all OCL expressions that occur in a QVTo operation
	protected def dispatch List<OCLExpression> getExpressions(ImperativeOperation operation) {
		// collect all nested OCLExpressions in body
		operation.body.content.eAllContents.filter(typeof(OCLExpression)).filter(e|e != null).toList
	}
	protected def dispatch List<OCLExpression> getExpressions(MappingOperation operation) {
		// collect all nested OCLExpressions in body, when, where
		(
			operation.body.content.eAllContents.filter(typeof(OCLExpression)) +
			operation.when.eAllContents.filter(typeof(OCLExpression)) +
			#[operation.where]
		).filter(e|e != null).toList
	}
	
	// A helper function like eAllContents, but on a list of objects instead of a single one
	protected def eAllContents(List<? extends EObject> objects) {
		(objects + objects.map[eAllContents.toList].flatten).toList
	}
	
	// Recursively collect all imported modules
	protected def Set<Module> allImportedModules(Module module) {
		(#[module] + module.moduleImport.map[importedModule.allImportedModules].flatten).toSet
	}
}
