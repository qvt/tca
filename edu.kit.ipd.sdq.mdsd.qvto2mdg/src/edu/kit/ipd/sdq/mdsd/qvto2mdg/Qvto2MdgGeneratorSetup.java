package edu.kit.ipd.sdq.mdsd.qvto2mdg;


import org.eclipse.xtext.ISetup;

import com.google.inject.Guice;
import com.google.inject.Injector;

public class Qvto2MdgGeneratorSetup implements ISetup {

	/* (non-Javadoc)
	 * @see org.eclipse.xtext.ISetup#createInjectorAndDoEMFRegistration()
	 */
	@Override
	public Injector createInjectorAndDoEMFRegistration() {
		// setup injector
		return Guice.createInjector(new Qvto2MdgGeneratorModule());
	}
}
