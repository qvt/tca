package edu.kit.ipd.sdq.mdsd.xtend2mdg

import javax.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator

class Generator implements IGenerator {
	@Inject extension Xtend2Mdg mdg
	@Inject extension Xtend2Sil sil
	
	override void doGenerate(Resource input, IFileSystemAccess fsa) {
		mdg.doGenerate(input, fsa)
		sil.doGenerate(input, fsa)
	}
}