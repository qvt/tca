package edu.kit.ipd.sdq.mdsd.qvto2mdg;
/**
 * 
 */


import java.util.Map;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
//import org.eclipse.core.resources.IProject;
//import org.eclipse.core.resources.IWorkspaceRoot;
//import org.eclipse.core.resources.ResourcesPlugin;
//import org.eclipse.core.runtime.CoreException;
import org.eclipse.emf.common.util.Diagnostic;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EcorePackage;
import org.eclipse.emf.ecore.EPackage.Registry;
import org.eclipse.emf.ecore.impl.EPackageRegistryImpl;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceImpl;
import org.eclipse.emf.ecore.resource.impl.URIMappingRegistryImpl;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.emf.mwe.core.WorkflowContext;
import org.eclipse.emf.mwe.core.issues.Issues;
import org.eclipse.emf.mwe.core.monitor.ProgressMonitor;
import org.eclipse.emf.mwe.utils.AbstractEMFWorkflowComponent;
import org.eclipse.m2m.internal.qvt.oml.InternalTransformationExecutor;
//import org.eclipse.m2m.internal.qvt.oml.emf.util.EmfUtilPlugin;
//import org.eclipse.m2m.internal.qvt.oml.emf.util.urimap.MetamodelURIMappingHelper;
//import org.eclipse.m2m.internal.qvt.oml.emf.util.urimap.URIMapping;
import org.eclipse.m2m.internal.qvt.oml.expressions.OperationalTransformation;

//import org.eclipse.ui.PlatformUI;

/**
 * @author Andreas Rentschler
 * 
 * Parses a QVTo transformation and stores the AST model to the model slot.
 * Note that URI mappings need to be registered manually using StandAloneSetup.
 * The AST parser and AST model are both hidden, thus we get some warnings.
 * 
 * Took org.eclipse.emf.mwe.utils.Writer component for inspiration.
 */
public class QvtoReader extends AbstractEMFWorkflowComponent {

	private static final String COMPONENT_NAME = "Eclipse QVTo Reader";
	private static final Log LOG = LogFactory.getLog(QvtoReader.class);

	// private String projectName;
	//
	// public static IProject getExistingProject(String name) throws
	// CoreException {
	// System.out.println(PlatformUI.getWorkbench().toString());
	// IWorkspaceRoot root = ResourcesPlugin.getWorkspace().getRoot();
	// IProject project = root.getProject(name);
	//
	// return project;
	// }
	//
	// public EPackage.Registry getMetamodelResolutionRegistry(IProject project,
	// ResourceSet resSet) {
	// if (!ecoreFileMetamodels.isEmpty()) {
	// myEcoreFilePackageRegistry = new EPackageRegistryImpl(
	// EPackage.Registry.INSTANCE);
	// Registry reg = MetamodelURIMappingHelper
	// .mappingsToEPackageRegistry(project.getProject(), resSet);
	// myEcoreFilePackageRegistry.putAll(reg);
	// }
	// return myEcoreFilePackageRegistry;
	// }
	//
	// public void setProject(String project) {
	// this.projectName = project;
	// }

	// Method copied from:
	// org.eclipse.m2m.internal.qvt.oml.emf.util.urimap.MetamodelURIMappingHelper
	private static EPackage loadEPackage(URI uri, ResourceSet rs) {
		try {
			if (uri.fragment() != null) {
				EObject eObject = rs.getEObject(uri, true);
				return (eObject instanceof EPackage) ? (EPackage) eObject
						: null;
			}

			Resource resource = rs.getResource(uri.trimFragment(), true);
			return (EPackage) EcoreUtil.getObjectByType(resource.getContents(),
					EcorePackage.eINSTANCE.getEPackage());
		} catch (Exception e) {
			LOG.fatal(e);
		}
		return null;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * org.eclipse.emf.mwe.core.lib.AbstractWorkflowComponent#invokeInternal
	 * (org.eclipse.emf.mwe.core.WorkflowContext,
	 * org.eclipse.emf.mwe.core.monitor.ProgressMonitor,
	 * org.eclipse.emf.mwe.core.issues.Issues)
	 */
	@Override
	protected void invokeInternal(WorkflowContext context,
			ProgressMonitor monitor, Issues issues) {
		// Sadly, this does not work that easily, because MWE workflows are executed in a plain Java instance
		// => We need to register the metamodel mappings manually via StandAloneSetup
		// Registry registry = getMetamodelResolutionRegistry(project, resourceSet);

		LOG.info("Importing global URI mappings from StandaloneSetup");
		// QVTo seems to require its own registry, can't see how to directly use
		// the global mappings registered via StandaloneSetup; 
		// We copy these over to an own QVTo compatible URI map.
		Registry registry = new EPackageRegistryImpl(EPackage.Registry.INSTANCE);
		for (Map.Entry<URI, URI> entry : URIMappingRegistryImpl.INSTANCE) {
			URI fromUri = entry.getKey();
			URI toUri = entry.getValue();

			if (fromUri != null) {
				EPackage toModel = loadEPackage(toUri, resourceSet);
				if (toModel != null) {
					LOG.info("Importing URI mapping from '" + fromUri
							+ "' to '" + toUri + "'");
					registry.put(fromUri.toString(), toModel);
				}
			}
		}
		if (URIMappingRegistryImpl.INSTANCE.isEmpty()) {
			LOG.warn("No URI mappings found in StandaloneSetup, which must substitute the QVTo project's mapping registry.");
			LOG.warn("Use entries 'uriMap = Mapping { from = \"http://some/uri\" to = \"platform:/resource/plugin/some/model.ecore\" }'");
		}

		LOG.info(getLogMessage());
		URI uri = URI.createURI(getUri());
		InternalTransformationExecutor executor = new InternalTransformationExecutor(uri, registry);
		Diagnostic diagnostic = executor.loadTransformation();
		logDiagnostic(diagnostic);

		// Place the AST model in an artificial resource and store it to the
		// model slot
		OperationalTransformation transformation = executor.getTransformation();
		Resource resource = new ResourceImpl(URI.createURI("temp.xmi"));
		resource.getContents().add(transformation);
		context.set(getModelSlot(), resource);//transformation);
	}

	// Print QVTo Logging information; actual error/warning messages are nested inside
	private void logDiagnostic(Diagnostic diagnostic) {
		if (diagnostic.getSeverity() == Diagnostic.CANCEL)
			LOG.fatal(diagnostic.getMessage(), diagnostic.getException());
		else if (diagnostic.getSeverity() == Diagnostic.ERROR)
			LOG.error(diagnostic.getMessage(), diagnostic.getException());
		else
			LOG.info(diagnostic.getMessage(), diagnostic.getException());
		for (Diagnostic child : diagnostic.getChildren())
			logDiagnostic(child);
	}

	public String getLogMessage() {
		return "Parsing QVTo script from " + this.uri;
	}

	public String getComponentName() {
		return COMPONENT_NAME;
	}

}
