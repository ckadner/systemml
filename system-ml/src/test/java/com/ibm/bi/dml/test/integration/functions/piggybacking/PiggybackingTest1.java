/**
 * (C) Copyright IBM Corp. 2010, 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 */

package com.ibm.bi.dml.test.integration.functions.piggybacking;

import org.junit.Assert;
import org.junit.Test;

import com.ibm.bi.dml.api.DMLScript.RUNTIME_PLATFORM;
import com.ibm.bi.dml.runtime.matrix.MatrixCharacteristics;
import com.ibm.bi.dml.runtime.matrix.data.MatrixValue.CellIndex;
import com.ibm.bi.dml.test.integration.AutomatedTestBase;
import com.ibm.bi.dml.test.integration.TestConfiguration;
import com.ibm.bi.dml.test.utils.TestUtils;

public class PiggybackingTest1 extends AutomatedTestBase 
{
	
	private final static String TEST_NAME = "Piggybacking1";
	private final static String TEST_DIR = "functions/piggybacking/";

	private final static int rows = 500;
	private final static int cols = 500;
	private final static double sparsity = 0.3;
	
	/**
	 * Main method for running one test at a time.
	 */
	public static void main(String[] args) {
		long startMsec = System.currentTimeMillis();

		PiggybackingTest1 t = new PiggybackingTest1();
		t.setUpBase();
		t.setUp();
		t.testDistCacheBug_append();
		t.tearDown();

		long elapsedMsec = System.currentTimeMillis() - startMsec;
		System.err.printf("Finished in %1.3f sec\n", elapsedMsec / 1000.0);

	}
	
	@Override
	public void setUp() 
	{
		TestUtils.clearAssertionInformation();
		addTestConfiguration(
				TEST_NAME, 
				new TestConfiguration(TEST_DIR, TEST_NAME, 
				new String[] { "z", "appendTestOut.scalar" })   ); 
	}
	
	/**
	 * Tests for a bug resulting from "aggressive" piggybacking.
	 * 
	 * Specific issue occurs in the context of map-only instructions that use
	 * distributed cache (e.g., mvmult and VRIX) -- i.e., when the number of
	 * columns is smaller than block size. If the result of such a map-only
	 * operation is immediately used in an another operation that also uses distributed
	 * cache, then both operations used to get piggybacked together (BUG!). In such a
	 * scenario, the second operation can not obtain one of its input from
	 * distributed cache since it is still being computed by the first operation
	 * in the same job. The fix is to ensure that the distributed cache input is
	 * produced in a job prior to the job in which it is used.
	 */
	@Test
	public void testDistCacheBug_mvmult()
	{		
		RUNTIME_PLATFORM rtold = rtplatform;
		rtplatform = RUNTIME_PLATFORM.HADOOP;
		
		try
		{
			TestConfiguration config = getTestConfiguration(TEST_NAME);
			
			String HOME = SCRIPT_DIR + TEST_DIR;
			fullDMLScriptName = HOME + TEST_NAME + "_mvmult.dml";
			programArgs = new String[]{"-args", HOME + INPUT_DIR + "A" , 
												HOME + INPUT_DIR + "x", 
												HOME + OUTPUT_DIR + config.getOutputFiles()[0] };
	
			fullRScriptName = HOME + TEST_NAME + "_mvmult.R";
			rCmd = "Rscript" + " " + fullRScriptName + " " + 
				       HOME + INPUT_DIR + "A.mtx" + " " + 
				       HOME + INPUT_DIR + "x.mtx" + " " + 
				       HOME + EXPECTED_DIR + config.getOutputFiles()[0];
	
			loadTestConfiguration(config);
			
			double[][] A = getRandomMatrix(rows, cols, 0, 1, sparsity, 10);
			MatrixCharacteristics mc = new MatrixCharacteristics(rows, cols, -1, -1, -1);
			writeInputMatrixWithMTD("A", A, true, mc);
			
			double[][] x = getRandomMatrix(cols, 1, 0, 1, 1.0, 11);
			mc.set(cols, 1, -1, -1);
			writeInputMatrixWithMTD("x", x, true, mc);
			
			boolean exceptionExpected = false;
			runTest(true, exceptionExpected, null, -1);
			runRScript(true);
		
			TestUtils.compareDMLHDFSFileWithRFile(comparisonFiles[0], outputDirectories[0], 1e-10);
		}
		finally
		{
			rtplatform = rtold;
		}
	}
	
	@Test
	public void testDistCacheBug_append()
	{		

		RUNTIME_PLATFORM rtold = rtplatform;
		rtplatform = RUNTIME_PLATFORM.HADOOP;
		
		TestConfiguration config = getTestConfiguration(TEST_NAME);
		
		String HOME = SCRIPT_DIR + TEST_DIR;
		fullDMLScriptName = HOME + TEST_NAME + "_append.dml";
		String OUT_FILE = HOME + OUTPUT_DIR + config.getOutputFiles()[1];
		programArgs = new String[]{"-args", OUT_FILE };

		loadTestConfiguration(config);
		
		boolean exceptionExpected = false;
		int numMRJobs = 4;
		runTest(true, exceptionExpected, null, numMRJobs);
	
		Double expected = 1120.0;
		Double output = TestUtils.readDMLScalarFromHDFS(OUT_FILE).get(new CellIndex(1,1));
		Assert.assertEquals("Values not equal: " + output + "!=" + expected, output, expected);
		
		rtplatform = rtold;
	}
	

	
}