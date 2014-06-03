package edu.kit.ipd.sdq.mdsd.qvto2mdg;



import org.eclipse.xtext.resource.generic.AbstractGenericResourceSupport;

import com.google.inject.Module;

public class Qvto2MdgGeneratorSupport extends AbstractGenericResourceSupport {

	/* (non-Javadoc)
	 * @see org.eclipse.xtext.resource.generic.AbstractGenericResourceSupport#createGuiceModule()
	 */
	@Override
	protected Module createGuiceModule() {
		return new Qvto2MdgGeneratorModule();
	}

}
