package edu.kit.ipd.sdq.mdsd.xtend2mdg

import com.google.common.collect.HashBasedTable
import com.google.common.collect.HashMultimapimport org.apache.log4j.Logger

// This class is used for bookkeeping the dependencies
// @author Andreas Rentschler
// This class is used for bookkeeping the dependencies
class DependencyMatrix {

	private val matrix = HashBasedTable.<String, String, Integer>create()
	
	private final static val log = Logger.getLogger(DependencyMatrix.name)

	// Put an entry into matrix; for multiple weights take the maximum
	def put(String from, String to, Integer weight) {
		val w = matrix.get(from, to)?: 0
		// non-cumulative, just take the largest weight
		if (w < weight)
			matrix.put(from, to, weight)
//			matrix.put(from, to, weight + w)  // weights are cumulative
	}

	// Output matrix as MDG file understood by the Bunch tool
	def mapToMdg(boolean noModelDependencies) '''
		«FOR c : matrix.cellSet»
			«IF c.value > 0 && (!noModelDependencies || 
			(
				!c.rowKey.startsWith("class_") && !c.columnKey.startsWith("class_") &&
				!c.rowKey.startsWith("package_") && !c.columnKey.startsWith("package_") &&
				!c.rowKey.startsWith("file_") && !c.columnKey.startsWith("file_")
			))»
				«c.rowKey» «c.columnKey» «c.value»
			«ENDIF»
		«ENDFOR»
	'''
	
	// Do some sanity checks: remove reflexive connections
	def checkNonReflexivity() {
		var reflexiveConnections = HashMultimap.<String, String>create();
		for (r : matrix.rowKeySet) {
			for (c : matrix.row(r).keySet) {
				if (matrix.contains(c, r) && !reflexiveConnections.containsEntry(c, r) && !reflexiveConnections.containsEntry(r, c)) {
					log.warn("Warning: reflexive connection from '" + r + "' to '" + c + "' had to be removed for Bunch.")
					reflexiveConnections.put(r, c)
				}
			}
		}
		for (e : reflexiveConnections.entries) {
			matrix.remove(e.key, e.value);
		}
	}
}
