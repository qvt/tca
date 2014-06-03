package edu.kit.ipd.sdq.mdsd.xtend2mdg;

import org.eclipse.xtext.resource.generic.AbstractGenericResourceSupport;

import com.google.inject.Module;

public class Xtend2MdgGeneratorSupport extends AbstractGenericResourceSupport {

    @Override
    protected Module createGuiceModule() { 
        return new Xtend2MdgGeneratorModule();
    }

}
