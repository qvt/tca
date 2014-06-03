package edu.kit.ipd.sdq.mdsd.qvto2mdg;


import org.eclipse.xtext.generator.IGenerator;
import org.eclipse.xtext.resource.generic.AbstractGenericResourceRuntimeModule;

import edu.kit.ipd.sdq.mdsd.qvto2mdg.Generator;

public class Qvto2MdgGeneratorModule extends AbstractGenericResourceRuntimeModule {

	@Override
	protected String getLanguageName() {
		return "QVTo transformation and imported metamodels transformed to a module dependency graph (MDF)";
	}

	@Override
	protected String getFileExtensions() {
		return "qvto";
	}
	
	public Class<? extends IGenerator> bindIGenerator() {
		return Generator.class;
	}

//	public Class<? extends ResourceSet> bindResourceSet() {
//		return ResourceSetImpl.class;
//	}
	
}
