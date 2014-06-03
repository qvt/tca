package edu.kit.ipd.sdq.mdsd.qvto2mdg

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import javax.inject.Inject
import org.eclipse.m2m.internal.qvt.oml.expressions.OperationalTransformation

class Generator implements IGenerator {
	
	@Inject extension edu.kit.ipd.sdq.mdsd.qvto2mdg.Qvto2Mdg
	@Inject extension edu.kit.ipd.sdq.mdsd.qvto2mdg.Qvto2Sil
	
	override void doGenerate(Resource input, IFileSystemAccess fsa) {
		// Generate analysis reports from parsed .qvtr scripts
		for (EObject eObject : input.contents.filter(e | e instanceof OperationalTransformation)) {
			compile(eObject, fsa)
		}
	}
	 
	///////////////////////////////////////////////////////////////////////////
	// Catch unhandled input resources
	def dispatch void compile(EObject eObject, IFileSystemAccess fsa) {
		println("Warning, no generator defined for input resource " + eObject.toString)
	}

	///////////////////////////////////////////////////////////////////////////
	// Generate analysis reports from .qvtr scripts
	def dispatch compile(OperationalTransformation transformation, IFileSystemAccess fsa) {
		fsa.generateFile(transformation.name + ".mdg", _qvto2Mdg.mapTransformation(transformation))
		fsa.generateFile(transformation.name + ".sil", _qvto2Sil.mapTransformation(transformation))
	}

}