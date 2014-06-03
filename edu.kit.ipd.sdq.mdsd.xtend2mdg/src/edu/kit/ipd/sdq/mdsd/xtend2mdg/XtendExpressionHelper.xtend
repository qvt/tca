package edu.kit.ipd.sdq.mdsd.xtend2mdg

import java.util.HashMap
import java.util.List
import java.util.Set
import javax.inject.Singleton
import org.apache.log4j.Logger
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EModelElement
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtend.core.xtend.XtendClass
import org.eclipse.xtend.core.xtend.XtendFile
import org.eclipse.xtend.core.xtend.XtendFunction
import org.eclipse.xtend.core.xtend.XtendMember
import org.eclipse.xtend.core.xtend.XtendTypeDeclaration
import org.eclipse.xtext.common.types.JvmDeclaredType
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.common.types.JvmIdentifiableElement
import org.eclipse.xtext.common.types.JvmOperation
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.common.types.JvmVoid
import org.eclipse.xtext.xbase.XAbstractFeatureCall

///////////////////////////////////////////////////////////////////////////////////////////////////
// This class contains helper methods to operate on Xbase expressions contained in Xtend scripts.
// Resolves concrete classes and packages that are (in)directly referred to by a potentially complex Ecore type.
//
// @author Andreas Rentschler
///////////////////////////////////////////////////////////////////////////////////////////////////
@Singleton  // ...an alternative to making everything static
class XtendExpressionHelper {
	
	private final val log = Logger.getLogger(XtendExpressionHelper.name);
	
	private var List<Resource> resources
	private var Set<XtendClass> xtendClasses
	private var Set<JvmDeclaredType> jvmClasses
	private var Set<EPackage> ecorePackages
	
	protected def setResources(List<Resource> resources) { 
		this.resources = resources
		this.xtendClasses = resources.map[contents].flatten.filter(XtendFile).map[xtendTypes].flatten.filter(XtendClass).toSet
		this.jvmClasses = resources.map[contents].flatten.filter(JvmDeclaredType).toSet
		this.ecorePackages = resources.map[contents].flatten.filter(EPackage).toSet
	} 
	protected def getResources() { resources } 
	protected def getXtendClasses() { xtendClasses }
	protected def getJvmClasses() { jvmClasses }
	protected def getEcorePackages() { ecorePackages }
	
	protected def getMainModules() {
		xtendClasses.filter[
			selfAndSuperClasses.map[members].flatten.filter(XtendFunction).exists[name == Constants.ENTRY_METHOD_NAME]
		].filter[subClasses.empty].toSet
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Reasoning about the call structure (using cache maps for better speed)

	// Which closest nested caller generates a file? Algorithm uses breadth-first search
	protected dispatch def XtendFunction callerFunctionThatGeneratesFile(XtendFunction function) {
		#{function}.callerFunctionThatGeneratesFile(#{}/*, 0*/)
	}
	protected dispatch def XtendFunction callerFunctionThatGeneratesFile(Set<XtendFunction> functions, Set<XtendFunction> visitedFunctions/*, int n*/) {
		/*println("callerFunctionThatGeneratesFile[" + n + "]: " + functions.map[name].join(", "))*/
		val visitedFunctions2 = (visitedFunctions + functions).toSet
		if (functions.empty)
			null
		else if (!functions.filter[generatesFile].empty)
			functions.findFirst[generatesFile]
		else functions.map[callerFunctions].flatten
			.filter(f | !visitedFunctions2.contains(f))
			.toSet.callerFunctionThatGeneratesFile(visitedFunctions2/*, n+1*/)
	}

	// Does the method call the file system access method 'generateFile'?
	private var generatesFileCache = new HashMap<XtendFunction, Boolean> 
	protected def generatesFile(XtendFunction function) {
		if (generatesFileCache.get(function) == null) {
			val ret = function?.expression?.eAllContents?.filter(XAbstractFeatureCall)?.toIterable
				?.exists[feature.simpleName == Constants.GENERATE_FILE_METHOD]
			generatesFileCache.put(function, ret)
			ret
		} else generatesFileCache.get(function)
	}
	
	// Functions called by the given function
	private var calleeFunctionsCache = new HashMap<XtendFunction, Set<XtendFunction>> 
	protected def calleeFunctions(XtendFunction function) {
		if (calleeFunctionsCache.get(function) == null) {
			var ret = function?.expression?.eAllContents?.filter(XAbstractFeatureCall)?.toIterable
				?.map[feature.resolveOperation]?.flatten?.filterNull?.toSet
			ret = if (ret == null) #{} else ret
			calleeFunctionsCache.put(function, ret)
			ret
		} else calleeFunctionsCache.get(function)
	}
	
	// Functions that call the given function
	private var callerFunctionsCache = new HashMap<XtendFunction, Set<XtendFunction>> 
	protected def callerFunctions(XtendFunction function) {
		if (callerFunctionsCache.get(function) == null) {
			val ret = xtendClasses.map[members].flatten.filter(XtendFunction).filter[calleeFunctions?.contains(function)].toSet
			callerFunctionsCache.put(function, ret)
			ret
		} else callerFunctionsCache.get(function)
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Inferring the super and sub classes for an Xtend class 

	protected dispatch def Set<XtendClass> getSelfAndSuperClasses(XtendClass clazz) {
		(#{clazz} + #{clazz.extends?.type}.filterNull.map[selfAndSuperClasses].flatten).toSet
	}
	
	protected dispatch def Set<XtendClass> getSelfAndSuperClasses(JvmDeclaredType clazz) {
		// Java classes are not supported
		val clazz2 = clazz.resolveType
		if (clazz2 != null) clazz2.selfAndSuperClasses else #{}
	}
	
	// Is there a class defined that extends this class?
	def getSubClasses(XtendClass clazz) {
		xtendClasses.filter(c | c != clazz).filter(c | c.selfAndSuperClasses.contains(clazz)).toSet
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Inferring the Xtend class for a JVM class

	protected dispatch def XtendClass resolveType(JvmDeclaredType type) {
		val ret = xtendClasses.filter(e | e.name == type.simpleName && (e.eContainer as XtendFile).package == type.packageName).head
//		log.info("resolveType: resolved " + type.simpleName + " to " + ret.name)
		ret
	}
	protected dispatch def XtendClass resolveType(JvmType type) {
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Inferring the Xtend class for a JVM class

	// resolve JVM operation to Xtend function, return multiple if dispatch method
	protected dispatch def Set<XtendFunction> resolveOperation(JvmOperation type) {
		val xtendFunctions = xtendClasses.map[members].flatten.filter(XtendFunction)
		val ret = xtendFunctions.filter(e | 
			type.identifier.startsWith(
				(e.eContainer.eContainer as XtendFile).package + "." +
				(e.eContainer as XtendTypeDeclaration).name + "." +
				e.name + "(")
		).toSet
//		log.info("resolveOperation: resolved " + type.simpleName + " to " + ret.map[name].join(", "))
		ret
	}
	
	protected dispatch def Set<XtendFunction> resolveOperation(JvmIdentifiableElement type) {
//		log.warn("resolveOperation: " + type.simpleName + " is not an operation.")
		#{}
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Retrieving the actually referenced model elements 

	protected def dispatch List<EModelElement> getModelTypes(Object type) {
//		log.warn("getModelTypes: unsupported type " + type.class + ".")
		#[]
	}
	
	// Not supported by Xtend, only by QVT-O: model types
//	protected def dispatch List<EModelElement> getModelTypes(ModelType type) {
//		// A model type should only reference a single package, which we return
//		#[(type.metamodel.get(0) as EModelElement)]
//	}

	protected def dispatch List<EModelElement> getModelTypes(EClass type) {
		// First, we need to filter out references to transformation modules (which are of type EPackage/EClass)
//		// A bit too restrictive: model types in the signature may be only a subset of the referenceable model types		
//		if (!transformation.metamodels.map[eAllContents.toList].flatten.toList.contains(type)) return #[]
//		// Less restrictive: all model types that are declared in the prologue
//		if (!transformation.usedModelType.map[metamodel].flatten.toList.eAllContents.contains(type)) return #[]
		// May be too less restrictive: just sort out modules and types defined in modules like the Stdlib
		if (type instanceof XtendMember) #[]
//		else if (type.blacklisted) #[]
		else if (Constants.reduceToPackageLevel) #[type.EPackage as EModelElement]
		else #[type as EModelElement]
	}
	
	protected def dispatch List<EModelElement> getModelTypes(JvmGenericType type) {
//		val type2 = class.classLoader.loadClass(type.identifier)
//		log.info("getModelTypes: " + type.simpleName + " resolves to " + type2 + " in " + type2.package)
//		val type2 = type.resolveClass
//		log.info("getModelTypes: " + type.simpleName + " resolves to " + type3)
		(#[type.resolveClass].filterNull.map[modelTypes].flatten + 
			type.typeParameters.filterNull.map[modelTypes].flatten
		).filterNull.toList
	}
	
	protected def dispatch List<EModelElement> getModelTypes(JvmVoid type) {
		#[]
	}
	
	protected def dispatch List<EModelElement> getModelTypes(EClassifier type) {
		#[]  // Skip because no concrete handler exists (PrimitiveType, VoidType, AnyType, ...)
	}
	
	// Ecore classes are resolved based on their EMF/Java class name and container package name
	// Note, that this is kind of an unsecure hack, but works in most cases!
	protected def EClass resolveClass(JvmGenericType type) {
		ecorePackages.map[eAllContents.toIterable].flatten.filter(EClass).filter[
				it.name == type.simpleName && 
				(it.eContainer as EPackage).name == type.packageName.split("\\.").last
		].head
	}
	
//	protected def EClass resolveClass(JvmGenericType type) {
//		resolveClass(type.packageName.split("\\."), type.simpleName, ecorePackages)
//	}
//
//	protected def EClass resolveClass(List<String> packageHierarchy, String className, List<EPackage> ecorePackages) {
//		if (packageHierarchy.empty) {
//			val ecoreClass = ecorePackages.map[eContents].flatten.filter(EClass).findFirst[it.name == className]
//			return ecoreClass
//		} else {
//			val ecorePackages2 = ecorePackages.filter[name == packageHierarchy.head]
//			if (ecorePackages2.empty) return null
//			resolveClass(packageHierarchy.drop(1).toList, className, ecorePackages2.toList)
//		}
//	}
//
//	protected def boolean isBlacklisted(JvmType type) {
//		for (String item : packageBlackList) {
//			if (type.identifier.contains(item)) {
//				return true
//			}
//		}
//		false
//	}
}
