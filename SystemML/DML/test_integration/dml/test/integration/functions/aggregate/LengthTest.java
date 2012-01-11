package dml.test.integration.functions.aggregate;

import org.junit.Test;

import dml.test.integration.AutomatedTestBase;
import dml.test.integration.TestConfiguration;
import dml.utils.LanguageException;

/**
 * <p><b>Positive tests:</b></p>
 * <ul>
 *  <li>general test</li>
 * </ul>
 * <p><b>Negative tests:</b></p>
 * <ul>
 *  <li>scalar test</li>
 * </ul>
 * 
 * @author schnetter
 */
public class LengthTest extends AutomatedTestBase {

    private final static String TEST_DIR = "functions/aggregate/";
    private final static String TEST_GENERAL = "General";
    private final static String TEST_SCALAR = "Scalar";


    @Override
    public void setUp() {
        // positive tests
        addTestConfiguration(TEST_GENERAL, new TestConfiguration(TEST_DIR, "LengthTest", new String[] {
                "vector_length", "matrix_length" }));
        
        // negative tests
        addTestConfiguration(TEST_SCALAR, new TestConfiguration(TEST_DIR, "LengthScalarTest",
                new String[] { "computed" }));
    }

    @Test
    public void testGeneral() {
        int rows = 10;
        int cols = 10;

        TestConfiguration config = getTestConfiguration(TEST_GENERAL);
        config.addVariable("rows", rows);
        config.addVariable("cols", cols);

        loadTestConfiguration(TEST_GENERAL);

        createHelperMatrix();
        double[][] vector = getRandomMatrix(rows, 1, 0, 1, 1, -1);
        writeInputMatrix("vector", vector);
        writeExpectedHelperMatrix("vector_length", rows);

        double[][] matrix = getRandomMatrix(rows, cols, 0, 1, 1, -1);
        writeInputMatrix("matrix", matrix);
        writeExpectedHelperMatrix("matrix_length", (rows * cols));

        runTest();

        compareResults();
    }

    @Test
    public void testScalar() {
        int scalar = 12;

        TestConfiguration config = getTestConfiguration(TEST_SCALAR);
        config.addVariable("scalar", scalar);

        createHelperMatrix();

        loadTestConfiguration(TEST_SCALAR);

        runTest(true, LanguageException.class);
    }

}
