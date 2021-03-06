It is vital to decompose large model transformation programs into manageable modules in order to keep them in a maintainable state. *Transformation Cluster Analysis* (TCA) is our endeavor to alleviate the effort that is required to reengineer the modular structure of model transformation programs. It does so by automatically extracting dependence information from transformation programs that can be automatically clustered with the [Bunch](https://www.cs.drexel.edu/~spiros/bunch/) tool. The approach currently supports the model-to-model transformation language [QVT-Operational](http://www.eclipse.org/mmt/?project=qvto), and the [Xtend](http://www.xtend-lang.org) language employable as an Ecore-based model-to-text transformation language.

### Description
 
In model-driven engineering, model transformations play a critical role as they transform models into other models and finally into executable code. Whereas models are typically structured into packages, transformation programs can be structured into modules to cope with their inherent code complexity. As the models evolve, the structure of transformations steadily deteriorates, and eventually leads to adverse effects on the productivity during maintenance. At the present time, discovering concern\-/based structures of transformation programs to help in understanding and refactoring them remains a manual process.

This approach makes it possible to apply clustering algorithms to find decompositions of transformation programs at the method level. In contrast to clustering techniques for general-purpose languages, we integrate not only method calls but also class and package dependencies of the models into the process. The approach relies on the Bunch tool for finding decompositions with minimal coupling and maximal cohesion.

Our approach had been validated in two case studies, one model-to-model and one model-to-code transformation, where we compare an expert clustering with automatically derived clusterings. We are able to demonstrate that by incorporating model dependencies we gain results that reflect the intended structure significantly better than when incorporating call dependencies alone.

### Installing

*TCA* runs on the Eclipse Modeling Tools. The following steps assume a fresh installation of Eclipse. 

* Download Eclipse [Modeling Tools 4.3 (Kepler)](http://www.eclipse.org/downloads/packages/eclipse-modeling-tools/keplersr1) (Kepler) and launch it;
* Install through menu **Help > Install Modeling Components...** [Eclipse Xtext 2.5+](http://www.eclipse.org/modeling/tmf/downloads/?project=xtext) of the Model Development Tools (MDT) project; further install [Eclipse QVTo 3.3.0+](http://www.eclipse.org/mmt/?project=qvto)  of the Model to Model Transformation (MMT) project
* Download [TCA](https://github.com/qvt/tca/zipball/master) and import contained projects through **File > Import > Existing Projects into Workspace…** into your Eclipse workspace. 

You are ready to use the code-to-model transformations to produce Bunch-compatible module dependence graphs (MDG) from QVT-O and Xtend programs. The extant module configuration is extracted as well from the sources and stored as a SIL definition. To do so, configure the workflow definition (either [Qvto2Mdg.mwe](https://github.com/qvt/tca/blob/master/edu.kit.ipd.sdq.mdsd.qvto2mdg/src/Qvto2Mdg.mwe2) or [Xtend2Mdg.mwe](https://github.com/qvt/tca/blob/master/edu.kit.ipd.sdq.mdsd.xtend2mdg/src/Xtend2Mdg.mwe2)) to refer to the transformation code and the models involved. Additionally, setup the weight configuration ([Constants.xtend](https://github.com/qvt/tca/blob/master/edu.kit.ipd.sdq.mdsd.qvto2mdg/src/edu/kit/ipd/sdq/mdsd/qvto2mdg/Constants.xtend) or [Constants.xtend](https://github.com/qvt/tca/blob/master/edu.kit.ipd.sdq.mdsd.xtend2mdg/src/edu/kit/ipd/sdq/mdsd/xtend2mdg/Constants.xtend)). Use the run configuration **Generate QVTo Dependency Graph**, or **Generate Xtend Dependency Graph**. Resulting MDG and SIL file are placed into the **src-gen** folder of the respective Eclipse project. 

The MDG file can serve as input to the Bunch tool built at Drexel University, and the output can be compared with the preexisting partition stored in the SIL file using Bunch's built-in metrics.

### Case Studies
We already used the approach to extract dependence information from two larger transformations from the [Palladio](http://www.palladio-simulator.com) project, 

* [PCMEvents2PCM](https://svnserver.informatik.kit.edu/i43/svn/code/Palladio/Core/trunk/MetaModels/de.uka.ipd.sdq.pcm.resources/transformations/events/) (revision 16944) implemented in QVT-O, and
* [PCM2SimuCom](https://svnserver.informatik.kit.edu/i43/svn/code/Palladio/Core/branches/SimuComXtendTransformation/) (revision 19044) implemented in Xtend.

Results of these studies are stored in a separate Eclipse project, [edu.kit.ipd.sdq.mdsd.bunch-casestudy](https://github.com/qvt/tca/tree/master/edu.kit.ipd.sdq.mdsd.bunch-casestudy).

### See Also
* [Modular Model Transformations](https://sdqweb.ipd.kit.edu/wiki/Modular_Model_Transformations), the overall approach behind this project, as well as information for developers.
* [Xtend2m](http://qvt.github.io/xtend2m/), a modular extension for Xtend2 (hosted at Github).
* [QVTom](http://qvt.github.io/qvtom/), a modular extension of QVTo (hosted at Github).

<!--### Publication
* A. Rentschler, D. Werle, Q. Noorshams, L. Happe, R. Reussner. [*Remodularizing Legacy Model Transformations with Automatic Clustering Techniques*](http://could.finally.lead.to/paper.pdf).-->

### Contributors
* [Andreas Rentschler] (http://sdq.ipd.kit.edu/people/andreas_rentschler/) from Karlsruhe Institute of Technology
* [Dominik Werle](emailto:dominik.werle_AtSignGoesHere_student.kit.edu) from Karlsruhe Institute of Technology, Germany
* [Joakim von Kistowski](http://se.informatik.uni-wuerzburg.de/staff/v_kistowski_joakim/) from University of Würzburg, Germany
* [Michael Junker](emailto:michael.junker_AtSignGoesHere_student.kit.edu) from Karlsruhe Institute of Technology, Germany

Work has partly been funded by the German Research Foundation (DFG) under under the Priority Programme SPP 1593: [Design For Future -- Managed Software Evolution](http://www.dfg-spp1593.de).

<img src="http://qvt.github.io/qvtr2coq/images/Logo_KIT.png" alt="KIT" height="70px"/>&nbsp;&nbsp;&nbsp;&nbsp;
<img src="http://qvt.github.io/qvtr2coq/images/Logo_PPADVERT.png" alt="ADVERT" height="70px"/>
