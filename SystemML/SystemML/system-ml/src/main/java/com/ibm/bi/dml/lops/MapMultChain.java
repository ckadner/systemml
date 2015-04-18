/**
 * IBM Confidential
 * OCO Source Materials
 * (C) Copyright IBM Corp. 2010, 2015
 * The source code for this program is not published or otherwise divested of its trade secrets, irrespective of what has been deposited with the U.S. Copyright Office.
 */

package com.ibm.bi.dml.lops;

import com.ibm.bi.dml.lops.LopProperties.ExecLocation;
import com.ibm.bi.dml.lops.LopProperties.ExecType;
import com.ibm.bi.dml.lops.compile.JobType;
import com.ibm.bi.dml.parser.Expression.DataType;
import com.ibm.bi.dml.parser.Expression.ValueType;


public class MapMultChain extends Lop 
{
	@SuppressWarnings("unused")
	private static final String _COPYRIGHT = "Licensed Materials - Property of IBM\n(C) Copyright IBM Corp. 2010, 2015\n" +
                                             "US Government Users Restricted Rights - Use, duplication  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.";
	
	public static final String OPCODE = "mapmmchain";
	public static final String OPCODE_CP = "mmchain";

	public enum ChainType {
		XtXv,  //(t(X) %*% (X %*% v))
		XtwXv, //(t(X) %*% (w * (X %*% v)))
		NONE,
	}
	
	private ChainType _chainType = null;
	
	/**
	 * Constructor to setup a map mult chain without weights
	 * 
	 * @param input
	 * @param op
	 * @return 
	 * @throws LopsException
	 */	
	public MapMultChain(Lop input1, Lop input2, DataType dt, ValueType vt, ExecType et) 
		throws LopsException 
	{
		super(Lop.Type.MapMultChain, dt, vt);		
		addInput(input1); //X
		addInput(input2); //v
		input1.addOutput(this); 
		input2.addOutput(this); 
		
		//setup mapmult parameters
		_chainType = ChainType.XtXv;
		setupLopProperties(et);
	}
	
	/**
	 * Constructor to setup a map mult chain with weights
	 * 
	 * @param input
	 * @param op
	 * @return 
	 * @throws LopsException
	 */	
	public MapMultChain(Lop input1, Lop input2, Lop input3, DataType dt, ValueType vt, ExecType et) 
		throws LopsException 
	{
		super(Lop.Type.MapMultChain, dt, vt);		
		addInput(input1); //X
		addInput(input2); //w
		addInput(input3); //v
		input1.addOutput(this);
		input2.addOutput(this);
		input3.addOutput(this);
		
		//setup mapmult parameters
		_chainType = ChainType.XtwXv;
		setupLopProperties(et);
	}

	/**
	 * 
	 * @param et
	 */
	private void setupLopProperties( ExecType et )
	{
		if( et == ExecType.MR )
		{
			//setup MR parameters 
			boolean breaksAlignment = true;
			boolean aligner = false;
			boolean definesMRJob = false;
			lps.addCompatibility(JobType.GMR);
			lps.addCompatibility(JobType.DATAGEN);
			lps.setProperties( inputs, ExecType.MR, ExecLocation.Map, breaksAlignment, aligner, definesMRJob );
		}
		else //Spark/CP
		{
			//setup Spark parameters 
			boolean breaksAlignment = false;
			boolean aligner = false;
			boolean definesMRJob = false;
			lps.addCompatibility(JobType.INVALID);
			lps.setProperties( inputs, et, ExecLocation.ControlProgram, breaksAlignment, aligner, definesMRJob );
		}
	}
	
	public String toString() {
		return "Operation = MapMMChain";
	}
	
	@Override
	public String getInstructions(int input_index1, int input_index2, int output_index)
	{
		//MR instruction XtXv
		StringBuilder sb = new StringBuilder();
		
		sb.append(getExecType());
		sb.append(Lop.OPERAND_DELIMITOR);
		
		sb.append(OPCODE);
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( getInputs().get(0).prepInputOperand(input_index1));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( getInputs().get(1).prepInputOperand(input_index2));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( this.prepOutputOperand(output_index));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append(_chainType);
		
		return sb.toString();
	}
	
	@Override
	public String getInstructions(int input_index1, int input_index2, int input_index3, int output_index)
	{
		//MR instruction XtwXv
		StringBuilder sb = new StringBuilder();
		
		sb.append(getExecType());
		sb.append(Lop.OPERAND_DELIMITOR);
		
		sb.append(OPCODE);
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( getInputs().get(0).prepInputOperand(input_index1));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( getInputs().get(1).prepInputOperand(input_index2));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( getInputs().get(2).prepInputOperand(input_index3));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( this.prepOutputOperand(output_index));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append(_chainType);
		
		return sb.toString();
	}

	@Override
	public String getInstructions(String input1, String input2, String output)
	{
		//Spark instruction XtXv
		StringBuilder sb = new StringBuilder();
		
		sb.append(getExecType());
		sb.append(Lop.OPERAND_DELIMITOR);
		
		if( getExecType()==ExecType.CP )
			sb.append(OPCODE_CP);
		else
			sb.append(OPCODE);
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( getInputs().get(0).prepInputOperand(input1));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( getInputs().get(1).prepInputOperand(input2));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( this.prepOutputOperand(output));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append(_chainType);
		
		return sb.toString();
	}
	
	@Override
	public String getInstructions(String input1, String input2, String input3, String output)
	{
		//Spark instruction XtwXv
		StringBuilder sb = new StringBuilder();
		
		sb.append(getExecType());
		sb.append(Lop.OPERAND_DELIMITOR);
		
		if( getExecType()==ExecType.CP )
			sb.append(OPCODE_CP);
		else
			sb.append(OPCODE);
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( getInputs().get(0).prepInputOperand(input1));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( getInputs().get(1).prepInputOperand(input2));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( getInputs().get(2).prepInputOperand(input3));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append( this.prepOutputOperand(output));
		
		sb.append(Lop.OPERAND_DELIMITOR);
		sb.append(_chainType);
		
		return sb.toString();
	}
	
	@Override
	public boolean usesDistributedCache() 
	{
		return true;
	}
	
	@Override
	public int[] distributedCacheInputIndex() 
	{
		if( _chainType == ChainType.XtXv )
			return new int[]{2};
		else if( _chainType == ChainType.XtwXv )
			return new int[]{2,3};
		
		//error
		return new int[]{-1};
	}
}
