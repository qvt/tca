/**
 * 
 */
package edu.kit.ipd.sdq.mdsd.xtend2mdg;

import static com.google.common.collect.Lists.newArrayList;

import java.util.List;

import org.apache.log4j.Logger;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.mwe2.runtime.workflow.IWorkflowComponent;
import org.eclipse.emf.mwe2.runtime.workflow.IWorkflowContext;

/**
 * @author Andreas Rentschler
 * 
 * Merge multiple resource sets into a single one
 */
public class MergeResourcesComponent implements IWorkflowComponent {

	protected final static Logger log = Logger.getLogger(MergeResourcesComponent.class.getName());

	private List<String> inputSlotNames = newArrayList();
	private String outputSlotName = null;
	private String outputUri = "dummy"; 

	/**
	 * adds a slot name to look for {@link Resource}s (the slot's contents might be a Resource or an Iterable of Resources).
	 */
	public void setUri(String uri) {
		this.outputUri = uri;
	}

	/**
	 * adds a slot name to look for {@link Resource}s (the slot's contents might be a Resource or an Iterable of Resources).
	 */
	public void addInputSlot(String slot) {
		this.inputSlotNames.add(slot);
	}

	/**
	 * adds a slot name to write the {@link Resource} to that contains the input resources.
	 */
	public void setOutputSlot(String slot) {
		this.outputSlotName = slot;
	}

	public void preInvoke() {
		if (inputSlotNames.isEmpty())
			throw new IllegalStateException("no 'inlet' has been configured.");
		if (outputSlotName == null)
			throw new IllegalStateException("the 'outlet' has not been configured.");
	}
	
	
	public void invoke(IWorkflowContext ctx) {
		ResourceSet rs = new ResourceSetImpl();
		URI uri = URI.createFileURI(outputUri);
		rs.createResource(uri);
		
		for (String slot : inputSlotNames) {
			Object object = ctx.get(slot);
			if (object == null) {
				log.debug("Slot '" + slot + "' was empty!");
				continue;
			}
			if (object instanceof Iterable) {
				Iterable<?> iterable = (Iterable<?>) object;
				for (Object object2 : iterable) {
					if (object2 instanceof Resource) {
						rs.getResources().add((Resource) object2);
					} else if (object2 instanceof EPackage) {
						rs.getResources().add(((EPackage) object2).eResource());
					} else { 
						throw new IllegalStateException("Slot '" + slot + "' contained not a Resource/EPackage but a '"+object.getClass().getSimpleName()+"'!");
					}
				}
			} else if (object instanceof Resource) {
				rs.getResources().add((Resource) object);
			} else if (object instanceof EPackage) {
				rs.getResources().add(((EPackage) object).eResource());
			} else { 
				throw new IllegalStateException("Slot '" + slot + "' contained not a Resource/EPackage but a '"+object.getClass().getSimpleName()+"'!");
			}
		}
		ctx.put(outputSlotName, rs.getResources().get(0));
	}

	public void postInvoke() {
		
	}
}
