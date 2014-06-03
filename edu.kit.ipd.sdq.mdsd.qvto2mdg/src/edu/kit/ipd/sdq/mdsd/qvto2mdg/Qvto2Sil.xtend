package edu.kit.ipd.sdq.mdsd.qvto2mdg

import java.util.ArrayList
import javax.inject.Inject
import org.eclipse.m2m.internal.qvt.oml.expressions.ImperativeOperation
import org.eclipse.m2m.internal.qvt.oml.expressions.Module
import org.eclipse.m2m.internal.qvt.oml.expressions.OperationalTransformation

///////////////////////////////////////////////////////////////////////////////////////////////////
// This transformation parses a QVTo script and extracts modular structure to be used
// in Bunch to compare expert modularization with automatically derived modularization.
// Bunch can output the same file for a derived clustering when target is set to "Text". 
//
// Each line in a SIL file consists of a module definition:
// SS(<clustername>.ss) = <nodename1>, <nodename2>, ..., <nodenameN>
//
// @author Andreas Rentschler
///////////////////////////////////////////////////////////////////////////////////////////////////

//@SuppressWarnings("restricted")  // Still doesn't work in latest Xtend version
class Qvto2Sil {
	@Inject extension QvtoNameBuilder			// reuse methods moduleName, operationName

	private var mappedModules = new ArrayList<Module>;
										// Keep list of modules that have been already mapped 
										// A module may be imported by multiple modules

	// Entry point: extract call and use dependencies between operations and model elements of a transformations 
	def mapTransformation(OperationalTransformation transformation) {
		// Map main module (and all modules that are imported recursively)
		transformation.mapModule
		// Return SIL format
	}
	
	// Recursively extract dependencies that occur between modules of a transformation
	// For each module, extract dependencies between operations that are defined in the module
	def String mapModule(Module module) '''
		«if (mappedModules.contains(module)) return ""
		else {mappedModules.add(module); ""}»
		SS(«module.moduleName»): «FOR o : module.EAllOperations.filter(typeof(ImperativeOperation)) SEPARATOR ", "»«o.operationName»«ENDFOR»
		««« Imported modules
		«FOR module2 : module.moduleImport.map[importedModule]»
			«module2.mapModule»
		«ENDFOR»
	'''
}