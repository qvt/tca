package edu.kit.ipd.sdq.mdsd.xtend2mdg;

import org.eclipse.xtext.generator.IGenerator;
import org.eclipse.xtext.resource.generic.AbstractGenericResourceRuntimeModule;

import edu.kit.ipd.sdq.mdsd.xtend2mdg.Generator;

public class Xtend2MdgGeneratorModule extends AbstractGenericResourceRuntimeModule {

    @Override
    protected String getLanguageName() {
        return "Xtend transformation and imported metamodels transformed to a MDG";
    }

    @Override
    protected String getFileExtensions() {
        return "xtend";
    }
    
    public Class<? extends IGenerator> bindIGenerator() {
        return Generator.class;
    }

}
