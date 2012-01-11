package dml.runtime.matrix;

import java.io.PrintWriter;
import java.util.Random;

import org.apache.hadoop.fs.FSDataOutputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.mapred.JobClient;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.RunningJob;
import org.apache.hadoop.mapred.Counters.Group;

import dml.lops.compile.JobType;
import dml.lops.runtime.RunMRJobs;
import dml.lops.runtime.RunMRJobs.ExecMode;
import dml.runtime.instructions.MRInstructions.RandInstruction;
import dml.runtime.matrix.io.InputInfo;
import dml.runtime.matrix.io.MatrixIndexes;
import dml.runtime.matrix.io.OutputInfo;
import dml.runtime.matrix.io.TaggedMatrixBlock;
import dml.runtime.matrix.mapred.GMRCombiner;
import dml.runtime.matrix.mapred.GMRReducer;
import dml.runtime.matrix.mapred.MRJobConfiguration;
import dml.runtime.matrix.mapred.RandMapper;
import dml.runtime.util.MapReduceTool;
import dml.utils.DMLRuntimeException;

/**
 * <p>Rand MapReduce job which creates random objects.</p>
 * 
 */
public class RandMR
{
	/**
	 * <p>Starts a Rand MapReduce job which will produce one or more random objects.</p>
	 * 
	 * @param numRows number of rows for each random object
	 * @param numCols number of columns for each random object
	 * @param blockRowSize number of rows in a block for each random object
	 * @param blockColSize number of columns in a block for each random object
	 * @param minValue minimum of the random values for each random object
	 * @param maxValue maximum of the random values for each random object
	 * @param sparsity sparsity for each random object
	 * @param pdf probability density function for each random object
	 * @param replication file replication
	 * @param inputs input file for each random object
	 * @param outputs output file for each random object
	 * @param outputInfos output information for each random object
	 * @param instructionsInMapper instruction for each random object
	 * @param resultIndexes result indexes for each random object
	 * @return matrix characteristics for each random object
	 * @throws Exception if an error occurres in the MapReduce phase
	 */
	
	
	public static JobReturn runJob(long[] numRows, long[] numCols, int[] blockRowSize, int[] blockColSize,
			double[] minValue, double[] maxValue, double[] sparsity, String[] pdf, int replication,
			String[] inputs, String[] outputs, OutputInfo[] outputInfos,
			String instructionsInMapper, byte[] resultIndexes, byte[] resultDimsUnknown)
	throws Exception
	{
		return runJob(instructionsInMapper.split(","), blockRowSize, blockColSize, "", "", "", 0, replication, 
				resultIndexes, resultDimsUnknown, outputs, outputInfos);
	}
	
	@SuppressWarnings("deprecation")
	public static JobReturn runJob(String[] randInstructions, int[] brlens, int[] bclens, 
			String instructionsInMapper, String aggInstructionsInReducer, String otherInstructionsInReducer, 
			int numReducers, int replication, byte[] resultIndexes, byte[] resultDimsUnknown,
			String[] outputs, OutputInfo[] outputInfos) 
	throws Exception
	{
		JobConf job;
		job = new JobConf(RandMR.class);
		job.setJobName("Rand-MR");
		
		//whether use block representation or cell representation
		MRJobConfiguration.setMatrixValueClass(job, true);
		
		byte[] realIndexes=new byte[randInstructions.length];
		for(byte b=0; b<realIndexes.length; b++)
			realIndexes[b]=b;
		
		//set up the block size
		MRJobConfiguration.setBlocksSizes(job, realIndexes, brlens, bclens);
		
		String[] inputs=new String[randInstructions.length];
		InputInfo[] inputInfos = new InputInfo[randInstructions.length];
		long[] rlens=new long[randInstructions.length];
		long[] clens=new long[randInstructions.length];
		
		FileSystem fs = FileSystem.get(job);
		Random random=new Random(System.currentTimeMillis());
		String randInsStr="";
		for(int i = 0; i < randInstructions.length; i++)
		{
			randInsStr=randInsStr+","+randInstructions[i];
			inputs[i]=System.currentTimeMillis()+"."+random.nextInt();
			FSDataOutputStream fsOut = fs.create(new Path(inputs[i]));
			PrintWriter pw = new PrintWriter(fsOut);
			RandInstruction ins=(RandInstruction)RandInstruction.parseInstruction(randInstructions[i]);
			if(ins==null)
				throw new RuntimeException("bad rand instruction: "+randInstructions[i]);
			rlens[i]=ins.rows;
			clens[i]=ins.cols;
			for(long r = 0; r < ins.rows; r += brlens[i])
			{
				long curBlockRowSize = Math.min(brlens[i], (ins.rows - r));
				for(long c = 0; c < ins.cols; c += bclens[i])
				{
					long curBlockColSize = Math.min(bclens[i], (ins.cols - c));
					StringBuilder sb = new StringBuilder();
					sb.append(((r / brlens[i]) + 1) + ",");
					sb.append(((c / bclens[i]) + 1) + ",");
					sb.append(curBlockRowSize + ",");
					sb.append(curBlockColSize + ",");
					pw.println(sb.toString());
				}
			}
			pw.close();
			fsOut.close();
			inputInfos[i] = InputInfo.TextCellInputInfo;
		}
		randInsStr=randInsStr.substring(1);//remove the first ","
		RunningJob runjob;
		MatrixCharacteristics[] stats;
		InputInfo[] infos;
		
		try{
			//set up the input files and their format information
			MRJobConfiguration.setUpMultipleInputs(job, realIndexes, inputs, inputInfos, true, brlens, bclens, false);
			
			//set up the dimensions of input matrices
			MRJobConfiguration.setMatricesDimensions(job, realIndexes, rlens, clens);
			
			//set up the block size
			MRJobConfiguration.setBlocksSizes(job, realIndexes, brlens, bclens);
			
			//set up the rand Instructions
			MRJobConfiguration.setRandInstructions(job, randInsStr);
			
			//set up unary instructions that will perform in the mapper
			MRJobConfiguration.setInstructionsInMapper(job, instructionsInMapper);
			
			//set up the aggregate instructions that will happen in the combiner and reducer
			MRJobConfiguration.setAggregateInstructions(job, aggInstructionsInReducer);
			
			//set up the instructions that will happen in the reducer, after the aggregation instrucions
			MRJobConfiguration.setInstructionsInReducer(job, otherInstructionsInReducer);
			
			//set up the number of reducers
			job.setNumReduceTasks(numReducers);
			
			//set up the replication factor for the results
			job.setInt("dfs.replication", replication);
			
			//TODO: 
			int nmapers=job.getInt("mapred.map.tasks", 1);
			job.setNumMapTasks(nmapers);
			
			//set up what matrices are needed to pass from the mapper to reducer
			MRJobConfiguration.setUpOutputIndexesForMapper(job, realIndexes,  randInsStr, instructionsInMapper, null, aggInstructionsInReducer, otherInstructionsInReducer, resultIndexes);
			
			//set up the multiple output files, and their format information
			MRJobConfiguration.setUpMultipleOutputs(job, resultIndexes, resultDimsUnknown, outputs, outputInfos, true);
			
			// configure mapper and the mapper output key value pairs
			job.setMapperClass(RandMapper.class);
			if(numReducers==0)
			{
				job.setMapOutputKeyClass(Writable.class);
				job.setMapOutputValueClass(Writable.class);
			}else
			{
				job.setMapOutputKeyClass(MatrixIndexes.class);
				job.setMapOutputValueClass(TaggedMatrixBlock.class);
			}
			
			//set up combiner
			if(numReducers!=0 && aggInstructionsInReducer!=null 
					&& !aggInstructionsInReducer.isEmpty())
				job.setCombinerClass(GMRCombiner.class);
		
			//configure reducer
			job.setReducerClass(GMRReducer.class);
			//job.setReducerClass(PassThroughReducer.class);
			
			stats=MRJobConfiguration.computeMatrixCharacteristics(job, realIndexes, randInsStr,
					instructionsInMapper, null, aggInstructionsInReducer, null, otherInstructionsInReducer, resultIndexes);
			
			// Update resultDimsUnknown based on computed "stats"
			for ( int i=0; i < resultIndexes.length; i++ ) { 
				if ( stats[i].numRows == -1 || stats[i].numColumns == -1 ) {
					if ( resultDimsUnknown[i] != (byte) 1 ) {
						throw new Exception("Unexpected error while configuring GMR job.");
					}
				}
				else {
					resultDimsUnknown[i] = (byte) 0;
				}
			}
			MRJobConfiguration.updateResultDimsUnknown(job,resultDimsUnknown);

			// By default, the job executes in "cluster" mode.
			// Determine if we can optimize and run it in "local" mode.
			MatrixCharacteristics[] inputStats = new MatrixCharacteristics[inputs.length];
			for ( int i=0; i < inputs.length; i++ ) {
				inputStats[i] = new MatrixCharacteristics(rlens[i], clens[i], brlens[i], bclens[i]);
			}
			ExecMode mode = RunMRJobs.getExecMode(JobType.RAND, inputStats); 
			if ( mode == ExecMode.LOCAL ) {
				job.set("mapred.job.tracker", "local");
			}
			
			runjob=JobClient.runJob(job);
			
			/* Process different counters */
			
			Group group=runjob.getCounters().getGroup(MRJobConfiguration.NUM_NONZERO_CELLS);
			Group rowgroup, colgroup;
			infos = new InputInfo[resultIndexes.length];
			
			for(int i=0; i<resultIndexes.length; i++)
			{
				// number of non-zeros
				stats[i].nonZeros=group.getCounter(Byte.toString(resultIndexes[i]));
			//	System.out.println("result #"+resultIndexes[i]+" ===>\n"+stats[i]);
				
				// compute dimensions for output matrices whose dimensions are unknown at compilation time 
				if ( stats[i].numRows == -1 || stats[i].numColumns == -1 ) {
					if ( resultDimsUnknown[i] != (byte) 1 )
						throw new DMLRuntimeException("Unexpected error after executing Rand Job");
				
					rowgroup = runjob.getCounters().getGroup("max_rowdim_"+i);
					colgroup = runjob.getCounters().getGroup("max_coldim_"+i);
					int maxrow, maxcol;
					maxrow = maxcol = 0;
					for ( int rid=0; rid < numReducers; rid++ ) {
						if ( maxrow < (int) rowgroup.getCounter(Integer.toString(rid)) )
							maxrow = (int) rowgroup.getCounter(Integer.toString(rid));
						if ( maxcol < (int) colgroup.getCounter(Integer.toString(rid)) )
							maxcol = (int) colgroup.getCounter(Integer.toString(rid)) ;
					}
					//System.out.println("Resulting Rows = " + maxrow + ", Cols = " + maxcol );
					stats[i].numRows = maxrow;
					stats[i].numColumns = maxcol;
				}
				infos[i] = OutputInfo.getMatchingInputInfo(outputInfos[i]);
			}
			
		}finally
		{
			for(String input: inputs)
				MapReduceTool.deleteFileIfExistOnHDFS(new Path(input), job);
		}
		
		return new JobReturn(stats, infos, runjob.isSuccessful());
	}
}
