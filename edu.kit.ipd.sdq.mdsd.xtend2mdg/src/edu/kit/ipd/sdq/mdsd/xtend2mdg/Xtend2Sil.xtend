package edu.kit.ipd.sdq.mdsd.xtend2mdg

import java.util.ArrayList
import javax.inject.Inject
import org.apache.log4j.Logger
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtend.core.xtend.XtendClass
import org.eclipse.xtend.core.xtend.XtendField
import org.eclipse.xtend.core.xtend.XtendFile
import org.eclipse.xtend.core.xtend.XtendFunction
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator

///////////////////////////////////////////////////////////////////////////////////////////////////
// This transformation parses an Xtend script and extracts modular structure to be used
// in Bunch to compare expert modularization with automatically derived modularization.
// Bunch can output the same file for a derived clustering when target is set to "Text". 
//
// Each line in a SIL file consists of a module definition:
// SS(<clustername>.ss) = <nodename1>, <nodename2>, ..., <nodenameN>
//
// @author Andreas Rentschler
///////////////////////////////////////////////////////////////////////////////////////////////////
class Xtend2Sil implements IGenerator {
	@Inject extension XtendExpressionHelper
	@Inject extension XtendNameBuilder

	private val mappedModules = new ArrayList<XtendClass>
	private val moduleList = new ArrayList<String>

	private final static val log = Logger.getLogger(Xtend2Sil.name)

	override doGenerate(Resource input, IFileSystemAccess fsa) {
		resources = input.resourceSet.resources

		// collect main methods from all modules
		log.info("doGenerate: detected modules with root method: " + mainModules.map[name].join(", "))
		if (mainModules.empty) return;
		
		// Map main modules (and all modules that are imported recursively)
		val output = mainModules.map[mapModule].join
		// Generate output
		val outputFile = (mainModules.head.eContainer as XtendFile).package.replaceAll("\\.", "-") + ".sil"
		log.info("doGenerate: writing output to " + outputFile)
		fsa.generateFile(outputFile, output)
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Recursively extract dependencies that occur between modules of a transformation
	// For each module, extract dependencies between operations that are defined in the module
	
	def String mapModule(XtendClass clazz) {
		// Simulate the SimuComModule binding: map only the most concrete classes
		if (!clazz.subClasses.empty) return clazz.subClasses.filter[subClasses.empty].map[mapModule].join
		
		// Only map a module once
		if (mappedModules.contains(clazz)) return "" else mappedModules.add(clazz)
		
		log.info("mapModule: " + clazz.name + " imports " + clazz.selfAndSuperClasses.map[members].flatten.filter(XtendField).filter[extension].map[type.type.simpleName].toSet.join(", "))
		
		'''
			SS(«clazz.moduleName»): «FOR o : clazz.selfAndSuperClasses.map[members].flatten.filter(XtendFunction) SEPARATOR ", "»«o.operationName»«ENDFOR»
			««« Imported modules
			«FOR module2 : clazz.selfAndSuperClasses.map[members].flatten.filter(XtendField).filter[extension].map[type.type.resolveType].filterNull»
			«module2.mapModule»
			«ENDFOR»
		'''
	}
}
