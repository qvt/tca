package edu.kit.ipd.sdq.mdsd.xtend2mdg;

import org.eclipse.xtext.ISetup;

import com.google.inject.Guice;
import com.google.inject.Injector;

public class Xtend2MdgGeneratorSetup implements ISetup {

    @Override
    public Injector createInjectorAndDoEMFRegistration() {
        return Guice.createInjector(new Xtend2MdgGeneratorModule());
    }

}
