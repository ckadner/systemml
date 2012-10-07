package com.ibm.bi.dml.api;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.URI;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Properties;
import java.util.Scanner;

import javax.xml.parsers.ParserConfigurationException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.security.UserGroupInformation;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.nimble.configuration.NimbleConfig;
import org.nimble.control.DAGQueue;
import org.nimble.control.PMLDriver;
import org.w3c.dom.Element;
import org.xml.sax.SAXException;

import com.ibm.bi.dml.hops.Hops;
import com.ibm.bi.dml.hops.OptimizerUtils;
import com.ibm.bi.dml.lops.Lops;
import com.ibm.bi.dml.packagesupport.PackageRuntimeException;
import com.ibm.bi.dml.parser.DMLProgram;
import com.ibm.bi.dml.parser.DMLQLParser;
import com.ibm.bi.dml.parser.DMLTranslator;
import com.ibm.bi.dml.parser.ParseException;
import com.ibm.bi.dml.runtime.controlprogram.LocalVariableMap;
import com.ibm.bi.dml.runtime.controlprogram.Program;
import com.ibm.bi.dml.runtime.controlprogram.ProgramBlock;
import com.ibm.bi.dml.runtime.controlprogram.WhileProgramBlock;
import com.ibm.bi.dml.runtime.controlprogram.caching.CacheableData;
import com.ibm.bi.dml.runtime.controlprogram.parfor.DataPartitionerLocal;
import com.ibm.bi.dml.runtime.controlprogram.parfor.ProgramConverter;
import com.ibm.bi.dml.runtime.controlprogram.parfor.ResultMergeLocalFile;
import com.ibm.bi.dml.runtime.controlprogram.parfor.stat.InfrastructureAnalyzer;
import com.ibm.bi.dml.runtime.controlprogram.parfor.util.ConfigurationManager;
import com.ibm.bi.dml.runtime.controlprogram.parfor.util.IDHandler;
import com.ibm.bi.dml.runtime.instructions.Instruction.INSTRUCTION_TYPE;
import com.ibm.bi.dml.runtime.matrix.mapred.MRJobConfiguration;
import com.ibm.bi.dml.runtime.util.MapReduceTool;
import com.ibm.bi.dml.sql.sqlcontrolprogram.ExecutionContext;
import com.ibm.bi.dml.sql.sqlcontrolprogram.NetezzaConnector;
import com.ibm.bi.dml.sql.sqlcontrolprogram.SQLProgram;
import com.ibm.bi.dml.utils.DMLException;
import com.ibm.bi.dml.utils.DMLRuntimeException;
import com.ibm.bi.dml.utils.HopsException;
import com.ibm.bi.dml.utils.LanguageException;
import com.ibm.bi.dml.utils.Statistics;
import com.ibm.bi.dml.utils.configuration.DMLConfig;
import com.ibm.bi.dml.utils.visualize.DotGraph;


public class DMLScript {
	//TODO: Change these static variables to non-static, and create corresponding access methods
	public enum EXECUTION_PROPERTIES {LOG, DEBUG, VISUALIZE, RUNTIME_PLATFORM, CONFIG};
	public static boolean DEBUG = false;
	public static boolean VISUALIZE = false;
	public static boolean LOG = false;	
	public enum RUNTIME_PLATFORM { HADOOP, SINGLE_NODE, HYBRID, NZ, INVALID };
	// We should assume the default value is HYBRID
	public static RUNTIME_PLATFORM rtplatform = RUNTIME_PLATFORM.HYBRID;
	public static String _uuid = IDHandler.createDistributedUniqueID(); 
	
	private String _dmlScriptString;
	// stores name of the OPTIONAL config file
	private String _optConfig;
	// stores optional args to parameterize DML script 
	private HashMap<String, String> _argVals;
	
	private Logger _mapredLogger;
	private Logger _mmcjLogger;
	
	public static final String DEFAULT_SYSTEMML_CONFIG_FILEPATH = "./SystemML-config.xml";
	private static final String DEFAULT_MAPRED_LOGGER = "org.apache.hadoop.mapred";
	private static final String DEFAULT_MMCJMR_LOGGER = "dml.runtime.matrix.MMCJMR";
	private static final String LOG_FILE_NAME = "SystemML.log";
	// stores the path to the source
	private static final String PATH_TO_SRC = "./";
	
	public static String USAGE = "Usage is " + DMLScript.class.getCanonicalName() 
			+ " [-f | -s] <filename>" + " -exec <mode>" +  /*" (-nz)?" + */ " [-d | -debug]?" + " [-l | -log]?" + " (-config=<config_filename>)? (-args)? <args-list>? \n" 
			+ " -f: <filename> will be interpreted as a filename path + \n"
			+ "     <filename> prefixed with hdfs: is hdfs file, otherwise it is local file + \n" 
			+ " -s: <filename> will be interpreted as a DML script string \n"
			+ " -exec: <mode> (optional) execution mode (hadoop, singlenode, hybrid)\n"
			+ " [-d | -debug]: (optional) output debug info \n"
			+ " [-v | -visualize]: (optional) use visualization of DAGs \n"
			+ " [-l | -log]: (optional) output log info \n"
			+ " -config: (optional) use config file <config_filename> (default: use parameter values in default SystemML-config.xml config file) \n" 
			+ "          <config_filename> prefixed with hdfs: is hdfs file, otherwise it is local file + \n"
			+ " -args: (optional) parameterize DML script with contents of [args list], ALL args after -args flag \n"
			+ "    1st value after -args will replace $1 in DML script, 2nd value will replace $2 in DML script, and so on."
			+ "<args-list>: (optional) args to DML script \n" ;
			
	public DMLScript (){
		
	}
	
	public DMLScript(String dmlScript, boolean debug, boolean log, boolean visualize, RUNTIME_PLATFORM rt, String config, HashMap<String, String> argVals){
		_dmlScriptString = dmlScript;
		DEBUG = debug;
		LOG = log;
		VISUALIZE = visualize;
		rtplatform = rt;
		
		_optConfig = config;
		_argVals = argVals;
		
		_mapredLogger = Logger.getLogger(DEFAULT_MAPRED_LOGGER);
		_mmcjLogger = Logger.getLogger(DEFAULT_MMCJMR_LOGGER);
	}
	
	
	/**
	 * run: The running body of DMLScript execution. This method should be called after execution properties have been correctly set,
	 * and customized parameters have been put into _argVals
	 * @throws ParseException 
	 * @throws IOException 
	 * @throws DMLException 
	 */
	private boolean run()throws IOException, ParseException, DMLException {
		boolean success = false;
		/////////////// set logger level //////////////////////////////////////
		if (rtplatform == RUNTIME_PLATFORM.HADOOP || rtplatform == RUNTIME_PLATFORM.HYBRID){
			if (DEBUG)
				_mapredLogger.setLevel(Level.WARN);
			else {
				_mapredLogger.setLevel(Level.WARN);
				_mmcjLogger.setLevel(Level.WARN);
			}
		}
		////////////// handle log output //////////////////////////
		BufferedWriter out = null;
		if (LOG && (rtplatform == RUNTIME_PLATFORM.HADOOP || rtplatform == RUNTIME_PLATFORM.HYBRID)) {
			// copy the input DML script to ./log folder
			// TODO: define the default path to store SystemML.log
			String hadoop_home = System.getenv("HADOOP_HOME");
			System.out.println("HADOOP_HOME: " + hadoop_home);
			File logfile = new File(hadoop_home + "/" + LOG_FILE_NAME);
			if (!logfile.exists()) {
				success = logfile.createNewFile(); // creates the file
				if (success == false) 
					System.err.println("ERROR: Failed to create log file: " + hadoop_home + "/" + LOG_FILE_NAME);	
					return success;
			}

			out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(logfile, true)));
			out.write("BEGIN DMLRun " + getDateTime() + "\n");
			out.write("BEGIN DMLScript\n");
			// No need to reopen the dml script, just print out dmlScriptString
			out.write(_dmlScriptString);
			out.write("END DMLScript\n");
		}
		
		// optional config specified overwrites/merge into the default config
		DMLConfig defaultConfig = null;
		DMLConfig optionalConfig = null;
		
		if (_optConfig != null) { // the optional config is specified
			try { // try to get the default config first 
				defaultConfig = new DMLConfig(DEFAULT_SYSTEMML_CONFIG_FILEPATH);
			} catch (Exception e) { // it is ok to not have the default
				defaultConfig = null;
				System.err.println("INFO: default config file " + DEFAULT_SYSTEMML_CONFIG_FILEPATH + " not provided ");
			}
			try { // try to get the optional config next
				optionalConfig = new DMLConfig(_optConfig);	
			} 
			catch (Exception e) { // it is not ok as the specification is wrong
				optionalConfig = null;
				System.err.println("ERROR:  Optional config file " +  _optConfig + " not found ");
				//return false;
			}
			if (defaultConfig != null) {
				try {
					defaultConfig.merge(optionalConfig);
				}
				catch(Exception e){
					System.err.println("ERROR: failed to merge default ");
					//return false;
				}
			}
			else {
				defaultConfig = optionalConfig;
			}
		}
		else { // the optional config is not specified
			try { // try to get the default config 
				defaultConfig = new DMLConfig(DEFAULT_SYSTEMML_CONFIG_FILEPATH);
			} catch (Exception e) { // it is not OK to not have the default
				defaultConfig = null;
				System.out.println("ERROR: Error parsing default configuration file: " + DEFAULT_SYSTEMML_CONFIG_FILEPATH);
				//System.exit(1);
			}
		}
		ConfigurationManager.setConfig(defaultConfig);
		
		
		////////////////print config file parameters /////////////////////////////
		if (DEBUG){
			System.out.println("INFO: ****** DMLConfig parameters *****");	
			defaultConfig.printConfigInfo();
		}
		
		
		///////////////////////////////////// parse script ////////////////////////////////////////////
		DMLProgram prog = null;
		DMLQLParser parser = new DMLQLParser(_dmlScriptString, _argVals);
		prog = parser.parse();

		if (prog == null){
			System.err.println("ERROR: Parsing failed");
			success = false;
			return success;
		}

		if (DEBUG) {
			System.out.println("********************** PARSER *******************");
			System.out.println(prog.toString());
		}
		///////////////////////////////////// construct HOPS ///////////////////////////////
		
		DMLTranslator dmlt = new DMLTranslator(prog);
		dmlt.validateParseTree(prog);
		dmlt.liveVariableAnalysis(prog);

		if (DEBUG) {
			System.out.println("********************** COMPILER *******************");
			System.out.println(prog.toString());
		}
		dmlt.constructHops(prog);

		if (DEBUG) {
			System.out.println("********************** HOPS DAG (Before Rewrite) *******************");
			// print
			dmlt.printHops(prog);
			dmlt.resetHopsDAGVisitStatus(prog);

			// visualize
			DotGraph gt = new DotGraph();
			//
			// last parameter: the path of DML source directory. If dml source
			// is at /path/to/dml/src then it should be /path/to/dml.
			//
			gt.drawHopsDAG(prog, "HopsDAG Before Rewrite", 50, 50, PATH_TO_SRC, VISUALIZE);
			dmlt.resetHopsDAGVisitStatus(prog);
		}

		// rewrite HOPs DAGs
		if (DEBUG) {
			System.out.println("********************** Rewriting HOPS DAG *******************");
		}

		// defaultConfig contains reconciled information for config
		dmlt.rewriteHopsDAG(prog, defaultConfig);
		dmlt.resetHopsDAGVisitStatus(prog);

		if (DEBUG) {
			System.out.println("********************** HOPS DAG (After Rewrite) *******************");
			// print
			dmlt.printHops(prog);
			dmlt.resetHopsDAGVisitStatus(prog);

			// visualize
			DotGraph gt = new DotGraph();
			gt.drawHopsDAG(prog, "HopsDAG After Rewrite", 100, 100, PATH_TO_SRC, VISUALIZE);
			dmlt.resetHopsDAGVisitStatus(prog);
		}

		executeHadoop(dmlt, prog, defaultConfig, out);
		
		success = true;
		return success;

	}
	
	
	/**
	 * executeScript: Execute a DML script, which is provided by the user as a file path to the script file.
	 * @param scriptPathName Path to the DML script file
	 * @param scriptArguments Variant arguments provided by the user to run with the DML Script
	 * @throws ParseException 
	 * @throws IOException 
	 * @throws DMLException 
	 */
	public boolean executeScript (String scriptPathName, String... scriptArguments) throws IOException, ParseException, DMLException{
		boolean success = false;
		success = executeScript(scriptPathName, (Properties)null, scriptArguments);
		return success;
		
	}
	/**
	 * executeScript: Execute a DML script, which is provided by the user as a file path to the script file.
	 * @param scriptPathName Path to the DML script file
	 * @param executionProperties DMLScript runtime and debug settings
	 * @param scriptArguments Variant arguments provided by the user to run with the DML Script
	 * @throws ParseException 
	 * @throws IOException 
	 * @throws DMLException 
	 */
	public boolean executeScript (String scriptPathName, Properties executionProperties, String... scriptArguments) throws IOException, ParseException, DMLException{
		boolean success = false;
		DEBUG = false;
		VISUALIZE = false;
		LOG = false;	
		
		_dmlScriptString = null;
		_optConfig = null;
		_argVals = new HashMap<String, String>();
		
		_mapredLogger = Logger.getLogger(DEFAULT_MAPRED_LOGGER);
		_mmcjLogger = Logger.getLogger(DEFAULT_MMCJMR_LOGGER);
		
		//Process the script path, get the content of the script
		StringBuilder dmlScriptString = new StringBuilder();
		
		if (scriptPathName == null){
			System.err.println("ERROR: script path must be provided!");
			success = false;
			return success;
		}
		else {
			String s1 = null;
			BufferedReader in = null;
			//TODO: update this hard coded line
			if (scriptPathName.startsWith("hdfs:")){ 
              FileSystem hdfs = FileSystem.get(new Configuration());
              Path scriptPath = new Path(scriptPathName);
              in = new BufferedReader(new InputStreamReader(hdfs.open(scriptPath)));
			}
			else { // from local file system
				in = new BufferedReader(new FileReader(scriptPathName));
			}
			while ((s1 = in.readLine()) != null)
				dmlScriptString.append(s1 + "\n");
			in.close();	
		}
		_dmlScriptString=dmlScriptString.toString();
		
		success = processExecutionProperties(executionProperties);
		
		if (!success){
			System.err.println("ERROR: There are invalid execution properties!");
			return success;
		}
		
		success = processOptionalScriptArgs(scriptArguments);
		if (!success){
			System.err.println("ERROR: There are invalid script arguments!");
			return success;
		}
		
		if (DEBUG)
		{
			System.out.println("INFO: ****** args to DML Script ****** ");
			System.out.println("INFO: UUID: " + getUUID());
			System.out.println("INFO: SCRIPT PATH: " + scriptPathName);
			System.out.println("INFO: DEBUG: "  + DEBUG);
			System.out.println("INFO: LOG: "  + LOG);
			System.out.println("INFO: VISUALIZE: "  + VISUALIZE);
			System.out.println("INFO: RUNTIME: " + rtplatform);
			System.out.println("INFO: BUILTIN CONFIG: " + DEFAULT_SYSTEMML_CONFIG_FILEPATH);
			System.out.println("INFO: OPTIONAL CONFIG: " + _optConfig);

			if (_argVals.size() > 0)
				System.out.println("INFO: Value for script parameter args: ");
			for (int i=1; i<= _argVals.size(); i++)
				System.out.println("INFO: $" + i + " = " + _argVals.get("$" + i) );
		}

		
		success = run();
		resetExecutionOptions();
		return success;
	}
	
	
	/**
	 * executeScript: Execute a DML script. The content of the script is provided by the user as an input stream.
	 * @param script InputStream as the DML script
	 * @param executionProperties DMLScript runtime and debug settings
	 * @param scriptArguments Variant arguments provided by the user to run with the DML Script
	 * @throws ParseException 
	 * @throws IOException 
	 * @throws DMLException 
	 */
	public boolean executeScript (InputStream script, Properties executionProperties, String... scriptArguments) throws IOException, ParseException, DMLException{
		boolean success = false;
		DEBUG = false;
		VISUALIZE = false;
		LOG = false;	
		
		_dmlScriptString = null;
		_optConfig = null;
		_argVals = new HashMap<String, String>();
		
		_mapredLogger = Logger.getLogger(DEFAULT_MAPRED_LOGGER);
		_mmcjLogger = Logger.getLogger(DEFAULT_MMCJMR_LOGGER);
		
		if (script == null){
			System.err.println("ERROR: Script string must be provided!");
			success = false;
			return success;
		}
		else {		
			_dmlScriptString = new Scanner(script).useDelimiter("\\A").next();
		}
		
		success = processExecutionProperties(executionProperties);
		if (!success){
			System.err.println("ERROR: There are invalid execution properties!");
			//System.err.println(USAGE);
			return success;
		}
		
		success = processOptionalScriptArgs(scriptArguments);
		if (!success){
			System.err.println("ERROR: There are invalid script arguments!");
			return success;
		}
		
		if (DEBUG)
		{
			System.out.println("INFO: ****** args to DML Script ****** ");
			System.out.println("INFO: UUID: " + getUUID());
			System.out.println("INFO: SCRIPT: " + _dmlScriptString);
			System.out.println("INFO: DEBUG: "  + DEBUG);
			System.out.println("INFO: LOG: "  + LOG);
			System.out.println("INFO: VISUALIZE: "  + VISUALIZE);
			System.out.println("INFO: RUNTIME: " + rtplatform);
			System.out.println("INFO: BUILTIN CONFIG: " + DEFAULT_SYSTEMML_CONFIG_FILEPATH);
			System.out.println("INFO: OPTIONAL CONFIG: " + _optConfig);

			if (_argVals.size() > 0)
				System.out.println("INFO: Value for script parameter args: ");
			for (int i=1; i<= _argVals.size(); i++)
				System.out.println("INFO: $" + i + " = " + _argVals.get("$" + i) );
		}

		success = run();
		resetExecutionOptions();
		return success;
	}
	
	private void resetExecutionOptions(){
		DEBUG = false;
		VISUALIZE = false;
		LOG = false;	
		rtplatform = RUNTIME_PLATFORM.HYBRID;
		_optConfig = null;
	}
	
	//Process execution properties
	private boolean processExecutionProperties(Properties executionProperties){
		boolean success = false;
		
		if (executionProperties != null){
			//Make sure that the properties are in the defined property list that can be handled
			@SuppressWarnings("unchecked")
			Enumeration<String> e = (Enumeration<String>) executionProperties.propertyNames();

			while (e.hasMoreElements()){
				String key = e.nextElement();
				boolean validProperty = false;
				for (EXECUTION_PROPERTIES p : EXECUTION_PROPERTIES.values()){
					if (p.name().equals(key)){
						validProperty = true;
						break;
					}
				}
				if (!validProperty){
					System.err.println("ERROR: Unknown execution property: " + key);
					resetExecutionOptions();
					success = false;
					return success;

				}

			}

			LOG = Boolean.valueOf(executionProperties.getProperty(EXECUTION_PROPERTIES.LOG.toString(), "false"));
			DEBUG = Boolean.valueOf(executionProperties.getProperty(EXECUTION_PROPERTIES.DEBUG.toString(), "false"));
			VISUALIZE = Boolean.valueOf(executionProperties.getProperty(EXECUTION_PROPERTIES.VISUALIZE.toString(), "false"));

			String runtime_pt = executionProperties.getProperty(EXECUTION_PROPERTIES.RUNTIME_PLATFORM.toString(), "hybrid");
			if (runtime_pt.equalsIgnoreCase("hadoop"))
				rtplatform = RUNTIME_PLATFORM.HADOOP;
			else if ( runtime_pt.equalsIgnoreCase("singlenode"))
				rtplatform = RUNTIME_PLATFORM.SINGLE_NODE;
			else if ( runtime_pt.equalsIgnoreCase("hybrid"))
				rtplatform = RUNTIME_PLATFORM.HYBRID;
			else if ( runtime_pt.equalsIgnoreCase("nz"))
				rtplatform = RUNTIME_PLATFORM.NZ;

			_optConfig = executionProperties.getProperty(EXECUTION_PROPERTIES.CONFIG.toString(), null);
		}
		else {
			resetExecutionOptions();
		}
		success = true;
		return success;
	}
	
	//Process the optional script arguments provided by the user to run with the DML script
	private boolean processOptionalScriptArgs(String... scriptArguments){
		boolean success = false;
		if (scriptArguments != null){
			int index = 1;
			for (String arg : scriptArguments){
				if (arg.equalsIgnoreCase("-d") || arg.equalsIgnoreCase("-debug")||
						arg.equalsIgnoreCase("-l") || arg.equalsIgnoreCase("-log") ||
						arg.equalsIgnoreCase("-v") || arg.equalsIgnoreCase("-visualize")||
						arg.equalsIgnoreCase("-exec") ||
						arg.startsWith("-config=")){
						System.err.println("ERROR: -args must be the final argument for DMLScript!");
						resetExecutionOptions();
						success = false;
						return success;
				}
						
				_argVals.put("$"+index ,arg);
				index++;
			}

		}
		success = true;
		return success;
	}
	
	
	/**
	 * @param args
	 * @throws ParseException
	 * @throws IOException
	 * @throws SAXException
	 * @throws ParserConfigurationException
	 */
	public static void main(String[] args) throws IOException, ParseException, DMLException {
		// This is a show case how to create a DMLScript object to accept a DML script provided by the user,
		// and how to run it.
		
		/////////// if the args is incorrect, print usage /////////////
		if (args.length < 2){
			//System.err.println(USAGE);
			return;
		}
		////////////process -f | -s to set dmlScriptString ////////////////
		else if (!(args[0].equals("-f") || args[0].equals("-s"))){
			System.err.println("ERROR: First argument must be either -f or -s");
			//System.err.println(USAGE);
			return;
		}
		
		DMLScript d = new DMLScript();
		boolean fromFile = (args[0].equals("-f")) ? true : false;
		boolean success = false;
		String script = args[1];	
		Properties executionProperties = new Properties();
		String[] scriptArgs = null;
		int i = 2;
		while (i<args.length){
			if (args[i].equalsIgnoreCase("-d") || args[i].equalsIgnoreCase("-debug")) {
				executionProperties.put(EXECUTION_PROPERTIES.DEBUG.toString(), "true");
			} else if (args[i].equalsIgnoreCase("-l") || args[i].equalsIgnoreCase("-log")) {
				executionProperties.put(EXECUTION_PROPERTIES.LOG.toString(), "true");
			} else if (args[i].equalsIgnoreCase("-v") || args[i].equalsIgnoreCase("-visualize")) {
				executionProperties.put(EXECUTION_PROPERTIES.VISUALIZE.toString(), "true");
			} else if ( args[i].equalsIgnoreCase("-exec")) {
				i++;
				if ( args[i].equalsIgnoreCase("hadoop")) 
					executionProperties.put(EXECUTION_PROPERTIES.RUNTIME_PLATFORM.toString(), "hadoop");
				else if ( args[i].equalsIgnoreCase("singlenode"))
					executionProperties.put(EXECUTION_PROPERTIES.RUNTIME_PLATFORM.toString(), "singlenode");
				else if ( args[i].equalsIgnoreCase("hybrid"))
					executionProperties.put(EXECUTION_PROPERTIES.RUNTIME_PLATFORM.toString(), "hybrid");
				else if ( args[i].equalsIgnoreCase("nz"))
					executionProperties.put(EXECUTION_PROPERTIES.RUNTIME_PLATFORM.toString(), "nz");
				else {
					System.err.println("ERROR: Unknown runtime platform: " + args[i]);
					return;
				}
			// handle config file
			} else if (args[i].startsWith("-config=")){
				executionProperties.put(EXECUTION_PROPERTIES.CONFIG.toString(), args[i].substring(8).replaceAll("\"", "")); 
			}
			// handle the args to DML Script -- rest of args will be passed here to 
			else if (args[i].startsWith("-args")) {
				i++;
				scriptArgs = new String[args.length - i];
				int j = 0;
				while( i < args.length){
					scriptArgs[j++]=args[i++];
				}
			} 
			else {
				System.err.println("ERROR: Unknown argument: " + args[i]);
				//System.err.println(USAGE);
				return;
			}
			i++;
		}
		if (fromFile){
			success = d.executeScript(script, executionProperties, scriptArgs);
		}
		else {
			InputStream is = new ByteArrayInputStream(script.getBytes());
			success = d.executeScript(is, executionProperties, scriptArgs);
		}
		
		if (!success){
			System.err.println("ERROR: Script cannot be executed!");
			return;
		}
	} ///~ end main

	
	/**
	 * executeHadoop: Handles execution on the Hadoop Map-reduce runtime
	 * @param dmlt DML Translator 
	 * @param prog DML Program object from parsed DML script
	 * @param config read from provided configuration file (e.g., config.xml)
	 * @param out writer for log output 
	 * @throws ParseException 
	 * @throws IOException 
	 * @throws DMLException 
	 */
	private static void executeHadoop(DMLTranslator dmlt, DMLProgram prog, DMLConfig config, BufferedWriter out) throws ParseException, IOException, DMLException{
		
		if (DEBUG) {
			System.out.println("********************** OPTIMIZER *******************");
			System.out.println("Type = " + OptimizerUtils.getOptType());
			System.out.println("Mode = " + OptimizerUtils.getOptMode());
			System.out.println("Available Memory = " + ((double)InfrastructureAnalyzer.getLocalMaxMemory()/1024/1024) + " MB");
			System.out.println("Memory Budget = " + ((double)Hops.getMemBudget(true)/1024/1024) + " MB");
			System.out.println("Defaults: mem util " + OptimizerUtils.MEM_UTIL_FACTOR + ", sparsity " + OptimizerUtils.DEF_SPARSITY + ", def mem " +  + OptimizerUtils.DEF_MEM_FACTOR );
		}
		
		/////////////////////// construct the lops ///////////////////////////////////
		dmlt.constructLops(prog);

		if (DEBUG) {
			System.out.println("***************************************************");
			System.out.println("********************** LOPS DAG *******************");
			dmlt.printLops(prog);
			dmlt.resetLopsDAGVisitStatus(prog);

			DotGraph gt = new DotGraph();
			gt.drawLopsDAG(prog, "LopsDAG", 150, 150, PATH_TO_SRC, VISUALIZE);
			dmlt.resetLopsDAGVisitStatus(prog);
		}

		////////////////////// generate runtime program ///////////////////////////////
		Program rtprog = prog.getRuntimeProgram(DEBUG, config);
		DAGQueue dagQueue = setupNIMBLEQueue(config);
		if (DEBUG && config == null){
			System.out.println("INFO: config is null -- you may need to verify config file path");
		}
		if (DEBUG && dagQueue == null){
			System.out.println("INFO: dagQueue is not set");
		}
		
		/*
		if (DEBUG) {
			System.out.println("********************** PIGGYBACKING DAG *******************");
			dmlt.printLops(prog);
			dmlt.resetLopsDAGVisitStatus(prog);

			DotGraph gt = new DotGraph();
			gt.drawLopsDAG(prog, "PiggybackingDAG", 200, 200, path_to_src, VISUALIZE);
			dmlt.resetLopsDAGVisitStatus(prog);
		}
		*/
		
		rtprog.setDAGQueue(dagQueue);

		
		// Count number compiled MR jobs
		int jobCount = 0;
		for (ProgramBlock blk : rtprog.getProgramBlocks()) 
			jobCount += countCompiledJobs(blk); 		
		Statistics.setNoOfCompiledMRJobs(jobCount);

		
		// TODO: DRB --- graph is definitely broken; printMe() is okay
		if (DEBUG) {
			System.out.println("********************** Instructions *******************");
			System.out.println(rtprog.toString());
			rtprog.printMe();

			// visualize
			//DotGraph gt = new DotGraph();
			//gt.drawInstructionsDAG(rtprog, "InstructionsDAG", 200, 200, path_to_src);

			System.out.println("********************** Execute *******************");
		}

		if (LOG) 
			out.write("Compile Status OK\n");
		

		/////////////////////////// execute program //////////////////////////////////////
		Statistics.startRunTimer();		
		try 
		{   
			initHadoopExecution( config );
			
			//run execute (w/ exception handling to ensure proper shutdown)
			rtprog.execute (new LocalVariableMap (), null);  
		}
		catch(DMLException ex)
		{
			System.out.println(ex.toString());
			throw ex;
		}
		finally //ensure cleanup/shutdown
		{			
			Statistics.stopRunTimer();
	
			//if (DEBUG) 
				System.out.println(Statistics.display());
			
			if (LOG) {
				out.write("END DMLRun " + getDateTime() + "\n");
				out.close();
			}
	
			//cleanup all nimble threads
			if(rtprog.getDAGQueue() != null)
		  	    rtprog.getDAGQueue().forceShutDown();
			
			//cleanup scratch_space and all working dirs
			cleanupHadoopExecution( config );
		}
	} // end executeHadoop

	
	/**
	 * executeNetezza: handles execution on Netezza runtime
	 * @param dmlt DML Translator
	 * @param prog DML program from parsed DML script
	 * @param config from parsed config file (e.g., config.xml)
	 * @throws ParseException 
	 * @throws HopsException 
	 * @throws DMLRuntimeException 
	 */
	private static void executeNetezza(DMLTranslator dmlt, DMLProgram prog, DMLConfig config, String fileName)
	throws HopsException, LanguageException, ParseException, DMLRuntimeException
	{
	
		dmlt.constructSQLLops(prog);
	
		SQLProgram sqlprog = dmlt.getSQLProgram(prog);
		String[] split = fileName.split("/");
		String name = split[split.length-1].split("\\.")[0];
		sqlprog.set_name(name);
	
		dmlt.resetSQLLopsDAGVisitStatus(prog);
		DotGraph g = new DotGraph();
		g.drawSQLLopsDAG(prog, "SQLLops DAG", 100, 100, PATH_TO_SRC, VISUALIZE);
		dmlt.resetSQLLopsDAGVisitStatus(prog);
	
		String sql = sqlprog.generateSQLString();
	
		Program pr = sqlprog.getProgram();
		pr.printMe();
	
		if (true) {
			System.out.println(sql);
		}
	
		NetezzaConnector con = new NetezzaConnector();
		try
		{
			ExecutionContext ec = new ExecutionContext(con);
			ec.setDebug(false);
	
			LocalVariableMap vm = new LocalVariableMap ();
			ec.set_variables (vm);
			con.connect();
			long time = System.currentTimeMillis();
			pr.execute (vm, ec);
			long end = System.currentTimeMillis() - time;
			System.out.println("Control program took " + ((double)end / 1000) + " seconds");
			con.disconnect();
			System.out.println("Done");
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		/*
		// Code to execute the stored procedure version of the DML script
		try
		{
			con.connect();
			con.executeSQL(sql);
			long time = System.currentTimeMillis();
			con.callProcedure(name);
			long end = System.currentTimeMillis() - time;
			System.out.println("Stored procedure took " + ((double)end / 1000) + " seconds");
			System.out.println(String.format("Procedure %s was executed on Netezza", name));
			con.disconnect();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}*/

	} // end executeNetezza
	
	
	
	/**
	 * Method to setup the NIMBLE task queue. 
	 * This will be used in future external function invocations
	 * @param dmlCfg DMLConfig object
	 * @return NIMBLE task queue
	 */
	static DAGQueue setupNIMBLEQueue(DMLConfig dmlCfg) {

		//config not provided
		if (dmlCfg == null) 
			return null;
		
		// read in configuration files
		NimbleConfig config = new NimbleConfig();

		try {
			config.parseSystemDocuments(dmlCfg.getConfig_file_name());
			
			//ensure unique working directory for nimble output
			StringBuffer sb = new StringBuffer();
			sb.append( dmlCfg.getTextValue(DMLConfig.SCRATCH_SPACE) );
			sb.append( Lops.FILE_SEPARATOR );
			sb.append( Lops.PROCESS_PREFIX );
			sb.append( getUUID() );
			sb.append( Lops.FILE_SEPARATOR  );
			sb.append( dmlCfg.getTextValue(DMLConfig.NIMBLE_SCRATCH) );			
			((Element)config.getSystemConfig().getParameters().getElementsByTagName(DMLConfig.NIMBLE_SCRATCH).item(0))
			                .setTextContent( sb.toString() );						
		} catch (Exception e) {
			e.printStackTrace();
			throw new PackageRuntimeException ("Error parsing Nimble configuration files");
		}

		// get threads configuration and validate
		int numSowThreads = 1;
		int numReapThreads = 1;

		numSowThreads = Integer.parseInt
				(NimbleConfig.getTextValue(config.getSystemConfig().getParameters(), DMLConfig.NUM_SOW_THREADS));
		numReapThreads = Integer.parseInt
				(NimbleConfig.getTextValue(config.getSystemConfig().getParameters(), DMLConfig.NUM_REAP_THREADS));
		
		if (numSowThreads < 1 || numReapThreads < 1){
			throw new PackageRuntimeException("Illegal values for thread count (must be > 0)");
		}

		// Initialize an instance of the driver.
		PMLDriver driver = null;
		try {
			driver = new PMLDriver(numSowThreads, numReapThreads, config);
			driver.startEmptyDriver(config);
		} catch (Exception e) {
			e.printStackTrace();
			throw new PackageRuntimeException("Problem starting nimble driver");
		} 

		return driver.getDAGQueue();
	}


	/**
	 * @throws ParseException 
	 * @throws IOException 
	 * 
	 */
	private static void initHadoopExecution( DMLConfig config ) 
		throws IOException, ParseException
	{
		//check security aspects
		checkSecuritySetup();
		
		//create scratch space with appropriate permissions
		String scratch = config.getTextValue(DMLConfig.SCRATCH_SPACE);
		MapReduceTool.createDirIfNotExistOnHDFS(scratch, DMLConfig.DEFAULT_SHARED_DIR_PERMISSION);
		
		//cleanup working dirs from previous aborted runs with same pid in order to prevent conflicts
		cleanupHadoopExecution(config); 
		
		//init caching (incl set active)
		CacheableData.initCaching();
		
		//reset statistics (required if multiple scripts executed in one JVM)
		Statistics.setNoOfExecutedMRJobs( 0 );
	}
	
	/**
	 * 
	 * @throws IOException
	 */
	private static void checkSecuritySetup() 
		throws IOException
	{
		//analyze local configuration
		String userName = System.getProperty( "user.name" );
		HashSet<String> groupNames = new HashSet<String>();
		try{
			//check existence, for backwards compatibility to < hadoop 0.21
			if( UserGroupInformation.class.getMethod("getCurrentUser") != null ){
				String[] groups = UserGroupInformation.getCurrentUser().getGroupNames();
				for( String g : groups )
					groupNames.add( g );
			}
		}catch(Exception ex){}
		
		//analyze hadoop configuration
		JobConf job = new JobConf();
		String jobTracker     = job.get("mapred.job.tracker", "local");
		String taskController = job.get("mapred.task.tracker.task-controller", "org.apache.hadoop.mapred.DefaultTaskController");
		String ttGroupName    = job.get("mapreduce.tasktracker.group","null");
		String perm           = job.get("dfs.permissions","null"); //note: job.get("dfs.permissions.supergroup",null);
		URI fsURI             = FileSystem.getDefaultUri(job);

		//determine security states
		boolean flagDiffUser = !(   taskController.equals("org.apache.hadoop.mapred.LinuxTaskController") //runs map/reduce tasks as the current user
							     || jobTracker.equals("local")  // run in the same JVM anyway
							     || groupNames.contains( ttGroupName) ); //user in task tracker group 
		boolean flagLocalFS = fsURI==null || fsURI.getScheme().equals("file");
		boolean flagSecurity = perm.equals("yes"); 
		
		//print debug output
		if( DEBUG )
		{
			System.out.println("SystemML security check:");
			System.out.println(" local.user.name                     = " + userName );
			System.out.println(" local.user.groups                   = " + ProgramConverter.serializeStringHashSet(groupNames) );		
			System.out.println(" mapred.job.tracker                  = " + jobTracker ); 
			System.out.println(" mapred.task.tracker.task-controller = " + taskController );
			System.out.println(" mapreduce.tasktracker.group         = " + ttGroupName );		
			System.out.println(" fs.default.name                     = " + fsURI.getScheme() );
			System.out.println(" dfs.permissions                     = " + perm );
		} 

		//print warning if permission issues possible
		if( flagDiffUser && ( flagLocalFS || flagSecurity ) )
		{
			System.out.println("Warning: Cannot run map/reduce tasks as user '"+userName+"'. Using tasktracker group '"+ttGroupName+"'."); 		 
		}
	}
	
	/**
	 * 
	 * @param config
	 * @throws IOException
	 * @throws ParseException
	 */
	private static void cleanupHadoopExecution( DMLConfig config ) 
		throws IOException, ParseException
	{
		//create dml-script-specific suffix
		StringBuilder sb = new StringBuilder();
		sb.append(Lops.FILE_SEPARATOR);
		sb.append(Lops.PROCESS_PREFIX);
		sb.append(DMLScript.getUUID());
		String dirSuffix = sb.toString();
		
		//cleanup scratch space (everything for current uuid) 
		//(required otherwise export to hdfs would skip assumed unnecessary writes if same name)
		MapReduceTool.deleteFileIfExistOnHDFS( config.getTextValue(DMLConfig.SCRATCH_SPACE) + dirSuffix );
		//cleanup working dirs (hadoop, cache)
		MapReduceTool.deleteFileIfExistOnHDFS( DMLConfig.LOCAL_MR_MODE_STAGING_DIR + //staging dir (for local mode only) 
			                                   dirSuffix  );
		MapReduceTool.deleteFileIfExistOnHDFS( MRJobConfiguration.getStagingWorkingDirPrefix() + //staging dir
				                               dirSuffix  );
		MapReduceTool.deleteFileIfExistOnHDFS( MRJobConfiguration.getLocalWorkingDirPrefix() + //local dir
                                               dirSuffix );
		MapReduceTool.deleteFileIfExistOnHDFS( MRJobConfiguration.getSystemWorkingDirPrefix() + //system dir
											   dirSuffix  );
		CacheableData.cleanupCacheDir();
		DataPartitionerLocal.cleanupWorkingDirectory();
		ResultMergeLocalFile.cleanupWorkingDirectory();
	}
	
	
	private static String getDateTime() {
		DateFormat dateFormat = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");
		Date date = new Date();
		return dateFormat.format(date);
	}

	private static int countCompiledJobs(ProgramBlock blk) {

		int jobCount = 0;

		if (blk instanceof WhileProgramBlock){	
			ArrayList<ProgramBlock> childBlocks = ((WhileProgramBlock) blk).getChildBlocks();
			for (ProgramBlock pb : childBlocks){
				jobCount += countCompiledJobs(pb);
			}

			if (blk.getNumInstructions() > 0){
				System.out.println("error:  while programBlock should not have instructions ");
			}
		}
		else {

			for (int i = 0; i < blk.getNumInstructions(); i++)
				if (blk.getInstruction(i).getType() == INSTRUCTION_TYPE.MAPREDUCE_JOB)
					jobCount++;
		}
		return jobCount;
	}
	
	public void setDMLScriptString(String dmlScriptString){
		_dmlScriptString = dmlScriptString;
	}
	
	public String getDMLScriptString (){
		return _dmlScriptString;
	}
	
	public void setOptConfig (String optConfig){
		_optConfig = optConfig;
	}
	
	public String getOptConfig (){
		return _optConfig;
	}
	
	public void setArgVals (HashMap<String, String> argVals){
		_argVals = argVals;
	}
	
	public HashMap<String, String> getArgVals() {
		return _argVals;
	}
	
	public static String getUUID()
	{
		return _uuid;
	}

	
	/**
	 * Used to set master UUID on all nodes (in parfor remote_mr, where DMLScript passed) 
	 * in order to simplify cleanup of scratch_space and local working dirs.
	 * 
	 * @param uuid
	 */
	public static void setUUID(String uuid) 
	{
		_uuid = uuid;
	}
	
	
}  ///~ end class
